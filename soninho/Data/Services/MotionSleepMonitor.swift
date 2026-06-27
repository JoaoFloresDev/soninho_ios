//
//  MotionSleepMonitor.swift
//  soninho
//
//  Created by João Flores on 22/02/26.
//

import Foundation
import CoreMotion
import AVFoundation
import Combine

// MARK: - Motion Sleep Monitor
/// Uses CoreMotion accelerometer to detect sleep phases based on device movement.
/// The phone should be placed on the mattress (face-down or on a nightstand)
/// so the accelerometer picks up the user's movement during sleep.
///
/// Sleep phase detection logic:
/// - Very low movement (< 0.005g)  → Deep Sleep
/// - Low movement (< 0.015g)       → REM or Light Sleep (REM has micro-twitches)
/// - Medium movement (< 0.05g)     → Light Sleep (transitions)
/// - High movement (> 0.05g)       → Awake
@MainActor
final class MotionSleepMonitor: ObservableObject {
    // MARK: - Singleton
    static let shared = MotionSleepMonitor()

    // MARK: - Constants
    private enum Constants {
        static let accelerometerUpdateInterval: TimeInterval = 1.0 / 10.0 // 10 Hz sampling
        static let phaseWindowSeconds: TimeInterval = 60 // Aggregate movement over 1 minute
        static let awakeThreshold: Double = 0.04 // Significant movement = awake
        static let deepSleepThreshold: Double = 0.012 // Low movement = deep sleep (accounts for breathing)
        static let remUpperThreshold: Double = 0.025 // Moderate movement with variance = REM
        static let smartAlarmMovementThreshold: Double = 0.025
        static let sleepCycleDurationMinutes: Double = 90 // One full sleep cycle
    }

    // MARK: - Published Properties
    @Published private(set) var currentPhase: SleepPhase = .light
    @Published private(set) var isMonitoring = false
    @Published private(set) var movementIntensity: Double = 0
    @Published private(set) var soundLevel: Double = 0
    @Published private(set) var smartAlarmTriggered = false

    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    private var movementSamples: [Double] = []
    private var phaseHistory: [(date: Date, phase: SleepPhase, movement: Double)] = []
    private var lastPhaseChangeTime = Date()
    private var monitoringStartTime: Date?
    private var smartAlarmWindow: (start: Date, end: Date)?
    private var smartAlarmCallback: (() -> Void)?
    private var phaseAggregationTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.gambitstudio.soninho.motionTimer", qos: .utility)

    // Audio metering
    private var audioRecorder: AVAudioRecorder?
    private var audioMeterTimer: DispatchSourceTimer?

    // MARK: - Init
    private init() {
        motionQueue.name = "com.gambitstudio.soninho.motion"
        motionQueue.maxConcurrentOperationCount = 1
    }

    // MARK: - Public Methods

    /// Starts monitoring motion for sleep phase detection.
    /// Call this when the user starts sleep tracking.
    func startMonitoring() {
        guard !isMonitoring else { return }
        guard motionManager.isAccelerometerAvailable else {
            return
        }

        isMonitoring = true
        monitoringStartTime = Date()
        lastPhaseChangeTime = Date()
        movementSamples = []
        phaseHistory = []
        currentPhase = .light
        smartAlarmTriggered = false
        soundLevel = 0

        startAudioMetering()

        motionManager.accelerometerUpdateInterval = Constants.accelerometerUpdateInterval

        // Use dedicated OperationQueue (works in background, unlike .main)
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, error in
            guard let data else { return }

            Task { @MainActor in
                self?.processAccelerometerData(data)
            }
        }

        // Use GCD timer for phase aggregation (reliable in background)
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now() + Constants.phaseWindowSeconds, repeating: Constants.phaseWindowSeconds)
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.aggregateAndClassifyPhase()
            }
        }
        timer.resume()
        phaseAggregationTimer = timer

    }

    /// Stops motion monitoring.
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        phaseAggregationTimer?.cancel()
        phaseAggregationTimer = nil
        stopAudioMetering()
        isMonitoring = false
        smartAlarmWindow = nil
        smartAlarmCallback = nil
    }

    /// Releases the microphone/recording audio session so the alarm can own
    /// the `.playback` session. Motion monitoring keeps running. Call this when
    /// an alarm fires — otherwise the recorder and the alarm player fight over
    /// AVAudioSession and the alarm audio can fail to start.
    func releaseAudioForAlarm() {
        stopAudioMetering()
    }

    /// Configures the smart alarm wake window.
    /// During this window, the monitor will watch for light sleep and call the callback.
    func configureSmartAlarm(windowStart: Date, windowEnd: Date, onLightSleep: @escaping () -> Void) {
        smartAlarmWindow = (start: windowStart, end: windowEnd)
        smartAlarmCallback = onLightSleep
        smartAlarmTriggered = false
    }

    /// Returns all recorded phases since monitoring started.
    func getRecordedPhases() -> [SleepPhaseData] {
        // If no phases recorded (session < 60 seconds), create a single light sleep phase
        if phaseHistory.isEmpty, let startTime = monitoringStartTime {
            return [SleepPhaseData(phase: .light, startTime: startTime, endTime: Date())]
        }
        guard phaseHistory.count >= 2 else {
            // Single phase entry - return it as a phase from its time to now
            if let single = phaseHistory.first {
                return [SleepPhaseData(phase: single.phase, startTime: single.date, endTime: Date())]
            }
            return []
        }

        var phases: [SleepPhaseData] = []

        for i in 0..<(phaseHistory.count - 1) {
            let current = phaseHistory[i]
            let next = phaseHistory[i + 1]

            phases.append(SleepPhaseData(
                phase: current.phase,
                startTime: current.date,
                endTime: next.date
            ))
        }

        // Add the last phase extending to now
        if let last = phaseHistory.last {
            phases.append(SleepPhaseData(
                phase: last.phase,
                startTime: last.date,
                endTime: Date()
            ))
        }

        return phases
    }

    /// Calculates a quality score based on actual motion data and phase distribution.
    func calculateQualityScore(phases: [SleepPhaseData], totalDuration: TimeInterval) -> Int {
        guard totalDuration > 0 else { return 50 }

        var score = 40

        let hours = totalDuration / 3600
        let deepDuration = phases.filter { $0.phase == .deep }.reduce(0.0) { $0 + $1.duration }
        let remDuration = phases.filter { $0.phase == .rem }.reduce(0.0) { $0 + $1.duration }
        let awakeDuration = phases.filter { $0.phase == .awake }.reduce(0.0) { $0 + $1.duration }
        let deepPct = (deepDuration / totalDuration) * 100
        let remPct = (remDuration / totalDuration) * 100
        let awakePct = (awakeDuration / totalDuration) * 100

        // Duration score (7-9 hours ideal) — max +15
        if hours >= 7 && hours <= 9 {
            score += 15
        } else if hours >= 6 && hours <= 10 {
            score += 10
        } else if hours >= 5 {
            score += 5
        }

        // Deep sleep (15-25% ideal) — max +20, penalty for missing
        if deepPct >= 15 && deepPct <= 25 {
            score += 20
        } else if deepPct >= 10 {
            score += 12
        } else if deepPct >= 5 {
            score += 5
        } else {
            // Less than 5% deep sleep is poor
            score -= 10
        }

        // REM sleep (15-25% ideal) — max +15, penalty for missing
        if remPct >= 15 && remPct <= 25 {
            score += 15
        } else if remPct >= 10 {
            score += 8
        } else if remPct >= 5 {
            score += 3
        } else {
            // Less than 5% REM is poor
            score -= 10
        }

        // Low awake time (<5% ideal) — max +10
        if awakePct < 3 {
            score += 10
        } else if awakePct < 8 {
            score += 5
        } else if awakePct > 15 {
            score -= 10
        }

        // Phase diversity bonus — having all phases present is healthy
        let hasDeep = deepPct > 3
        let hasRem = remPct > 3
        let phasesPresent = [hasDeep, hasRem].filter { $0 }.count
        if phasesPresent == 2 {
            score += 10 // All meaningful phases present
        } else if phasesPresent == 1 {
            score += 3
        }

        return min(100, max(0, score))
    }

    // MARK: - Private Methods

    private func processAccelerometerData(_ data: CMAccelerometerData) {
        // Calculate total acceleration magnitude (removing gravity ~1.0g)
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        let totalAcceleration = sqrt(x * x + y * y + z * z)

        // Movement is deviation from resting (gravity = ~1.0g)
        let movement = abs(totalAcceleration - 1.0)
        movementSamples.append(movement)

        // Update real-time movement intensity (smoothed)
        let recentCount = min(movementSamples.count, 30)
        let recentSamples = movementSamples.suffix(recentCount)
        movementIntensity = recentSamples.reduce(0, +) / Double(recentCount)
    }

    private func aggregateAndClassifyPhase() {
        guard !movementSamples.isEmpty else { return }

        // Calculate statistics over the window
        let avgMovement = movementSamples.reduce(0, +) / Double(movementSamples.count)
        let maxMovement = movementSamples.max() ?? 0
        let variance = movementSamples.map { pow($0 - avgMovement, 2) }.reduce(0, +) / Double(movementSamples.count)
        let stdDev = sqrt(variance)

        guard let startTime = monitoringStartTime else {
            movementSamples = []
            return
        }

        let elapsedMinutes = Date().timeIntervalSince(startTime) / 60

        // Determine phase using hybrid approach:
        // 1. Movement data from accelerometer
        // 2. Sleep cycle model (90-min cycles: light → deep → light → REM)
        let newPhase: SleepPhase

        if avgMovement > Constants.awakeThreshold || maxMovement > 0.10 {
            // Significant movement = awake or restless
            newPhase = .awake
        } else if elapsedMinutes < 10 {
            // Sleep onset: always light sleep (falling asleep phase)
            newPhase = .light
        } else {
            // Sleep cycle model is the PRIMARY driver.
            // Movement can only OVERRIDE to awake (handled above) or
            // shift between deep/light within the cycle window.
            newPhase = classifyWithSleepCycle(
                elapsedMinutes: elapsedMinutes,
                avgMovement: avgMovement,
                stdDev: stdDev
            )
        }

        // Prevent rapid phase oscillation (minimum 2 minutes per phase)
        let timeSinceLastChange = Date().timeIntervalSince(lastPhaseChangeTime)
        if newPhase != currentPhase && timeSinceLastChange > 120 {
            currentPhase = newPhase
            lastPhaseChangeTime = Date()
        }

        phaseHistory.append((date: Date(), phase: currentPhase, movement: avgMovement))

        // Check smart alarm condition
        checkSmartAlarmCondition(avgMovement: avgMovement)

        // Clear samples for next window
        movementSamples = []
    }

    /// Classifies sleep phase using a 90-minute sleep cycle model.
    /// The cycle model is the PRIMARY driver — phone accelerometer on a mattress
    /// cannot reliably distinguish deep/REM/light from movement alone.
    ///
    /// Real sleep follows repeating ~90-min cycles:
    ///   Light → Deep → Light → REM → (brief wake) → repeat
    /// - Early night (cycles 0-1): longer deep sleep, shorter/no REM
    /// - Late night (cycles 2+): shorter deep sleep, longer REM
    ///
    /// Movement data can only OVERRIDE the cycle model upward (toward lighter sleep):
    /// - High movement during deep window → light sleep instead
    /// - Very still during light window → could be deep extension
    private func classifyWithSleepCycle(elapsedMinutes: Double, avgMovement: Double, stdDev: Double) -> SleepPhase {
        let cycleDuration = Constants.sleepCycleDurationMinutes
        let cyclePosition = (elapsedMinutes.truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
        let cycleNumber = Int(elapsedMinutes / cycleDuration)

        // Determine the expected phase from the cycle model.
        // Cycle structure (percentages of 90 min):
        //   0.00–0.12  (0–11 min):  Light sleep — falling into cycle
        //   0.12–0.45  (11–40 min): Deep sleep — restorative phase
        //   0.45–0.55  (40–50 min): Light sleep — transition
        //   0.55–0.90  (50–81 min): REM sleep — dreaming phase
        //   0.90–1.00  (81–90 min): Light/brief wake — between cycles

        // Deep sleep gets shorter in later cycles
        let deepEnd: Double
        switch cycleNumber {
        case 0: deepEnd = 0.50  // First cycle: longest deep
        case 1: deepEnd = 0.42
        case 2: deepEnd = 0.30
        default: deepEnd = 0.20 // Later cycles: very short deep
        }

        // REM gets longer in later cycles
        let remStart: Double
        switch cycleNumber {
        case 0: remStart = 0.70  // First cycle: short REM, starts late
        case 1: remStart = 0.58
        default: remStart = 0.50 // Later cycles: REM starts earlier, lasts longer
        }

        let expectedPhase: SleepPhase
        if cyclePosition < 0.12 {
            expectedPhase = .light
        } else if cyclePosition < deepEnd {
            expectedPhase = .deep
        } else if cyclePosition < remStart {
            expectedPhase = .light
        } else if cyclePosition < 0.92 {
            expectedPhase = .rem
        } else {
            // Brief awakening between cycles (natural)
            expectedPhase = cycleNumber > 0 ? .awake : .light
        }

        // Movement can override the cycle model:
        // High movement during any sleep window → upgrade to lighter phase
        let isRestless = avgMovement > Constants.remUpperThreshold

        switch expectedPhase {
        case .deep:
            if isRestless {
                return .light // Too much movement for deep sleep
            }
            return .deep

        case .rem:
            if isRestless {
                return .light // Too much movement for REM
            }
            return .rem

        case .awake:
            // Brief inter-cycle awakening
            return .awake

        case .light:
            return .light
        }
    }

    private func checkSmartAlarmCondition(avgMovement: Double) {
        guard !smartAlarmTriggered else { return }
        guard let window = smartAlarmWindow else { return }

        let now = Date()
        guard now >= window.start && now <= window.end else { return }

        // Trigger smart alarm when user shows signs of light sleep / transitioning to wakefulness:
        // - Movement above deep sleep threshold (user is in lighter phase)
        // - OR a recent spike in movement (user shifted position)
        if avgMovement > Constants.smartAlarmMovementThreshold {
            smartAlarmTriggered = true
            smartAlarmCallback?()
        }

        // Also check if the user has been in light sleep for at least 2 consecutive minutes
        let recentPhases = phaseHistory.suffix(2)
        if recentPhases.count >= 2 && recentPhases.allSatisfy({ $0.phase == .light }) {
            smartAlarmTriggered = true
            smartAlarmCallback?()
        }
    }

    // MARK: - Audio Metering

    private func startAudioMetering() {
        // Request microphone permission first
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    guard granted else {
                        return
                    }
                    self?.setupAudioRecorder()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    guard granted else {
                        return
                    }
                    self?.setupAudioRecorder()
                }
            }
        }
    }

    private func setupAudioRecorder() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sleep_meter.caf")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            // Configure audio session for recording alongside playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            // Poll audio levels every 0.5 seconds using GCD timer (background-safe)
            let timer = DispatchSource.makeTimerSource(queue: timerQueue)
            timer.schedule(deadline: .now() + 0.5, repeating: 0.5)
            timer.setEventHandler { [weak self] in
                Task { @MainActor in
                    self?.updateSoundLevel()
                }
            }
            timer.resume()
            audioMeterTimer = timer

        } catch {
        }
    }

    private func stopAudioMetering() {
        audioMeterTimer?.cancel()
        audioMeterTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        soundLevel = 0

        // Clean up temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sleep_meter.caf")
        try? FileManager.default.removeItem(at: tempURL)
    }

    private func updateSoundLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()

        // averagePower returns dB: -160 (silence) to 0 (max)
        let dB = recorder.averagePower(forChannel: 0)

        // Normalize to 0-1 range: -60dB = silence, 0dB = max
        let normalized = max(0, (dB + 60) / 60)
        soundLevel = Double(normalized)
    }
}
