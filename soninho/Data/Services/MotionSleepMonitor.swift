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
        static let sleepCycleDurationMinutes: Double = 90 // One full sleep cycle
    }

    /// Tuning for the smart wake search.
    ///
    /// The window is a budget, not a green light: waking someone at minute one
    /// of a 30-minute window throws away 29 minutes of sleep for a moment that
    /// is probably no better than the next one. So the monitor demands strong
    /// evidence early and settles for less as the alarm time approaches.
    private enum SmartWake {
        /// How long a qualifying reading must hold — one good minute can just be
        /// a turn in bed.
        static let confirmationMinutes = 2
        /// Nothing fires in the first slice of the window unless the sleeper is
        /// plainly awake.
        static let earliestProgress: Double = 0.15
        /// Score demanded at the start of the window (essentially: awake).
        static let startingBar: Double = 0.92
        /// Score demanded at the very end (light or REM is good enough).
        static let endingBar: Double = 0.40
        /// At or above this the sleeper is treated as already awake.
        static let awakeScore: Double = 0.92
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
    /// Decides the stages from the movement data. See SleepStagingEngine for
    /// what actigraphy can and cannot tell us.
    private var staging: SleepStagingEngine?
    /// Consecutive one-minute windows whose wake score cleared the bar.
    private var qualifyingMinutes = 0
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
        staging = SleepStagingEngine(sessionStart: Date())
        lastPhaseChangeTime = Date()
        movementSamples = []
        phaseHistory = []
        currentPhase = .light
        smartAlarmTriggered = false
        qualifyingMinutes = 0
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

    /// Releases the sensors the alarm/its missions need: the microphone (so the
    /// alarm can own the `.playback` audio session) AND the accelerometer (so
    /// the shake mission's own CMMotionManager isn't starved by this monitor's
    /// — two accelerometer consumers conflict). Call when an alarm fires.
    /// Sleep is over at that point, so dropping these sensors is fine.
    func releaseForAlarm() {
        stopAudioMetering()
        motionManager.stopAccelerometerUpdates()
    }

    /// Configures the smart alarm wake window.
    /// During this window, the monitor will watch for light sleep and call the callback.
    func configureSmartAlarm(windowStart: Date, windowEnd: Date, onLightSleep: @escaping () -> Void) {
        smartAlarmWindow = (start: windowStart, end: windowEnd)
        smartAlarmCallback = onLightSleep
        smartAlarmTriggered = false
        qualifyingMinutes = 0
    }

    /// The night's stages, merged into contiguous spans.
    func getRecordedPhases() -> [SleepPhaseData] {
        let now = Date()
        guard let staging, !staging.epochs.isEmpty else {
            let start = monitoringStartTime ?? now
            return [SleepPhaseData(phase: .light, startTime: start, endTime: now)]
        }
        return staging.phaseSpans(now: now)
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
        guard monitoringStartTime != nil else {
            movementSamples = []
            return
        }

        let avgMovement = movementSamples.reduce(0, +) / Double(movementSamples.count)
        movementSamples = []

        // The engine owns the staging: it smooths this minute against its
        // neighbours and calibrates against the night's own movement, rather
        // than guessing the stage from the clock.
        let settled = staging?.record(activity: avgMovement) ?? .light

        // Stages only move after a couple of minutes, so no extra damping here.
        if settled != currentPhase {
            currentPhase = settled
            lastPhaseChangeTime = Date()
        }

        phaseHistory.append((date: Date(), phase: settled, movement: avgMovement))

        checkSmartAlarmCondition(avgMovement: avgMovement)
    }

    private func checkSmartAlarmCondition(avgMovement: Double) {
        guard !smartAlarmTriggered else { return }
        guard let window = smartAlarmWindow else { return }

        let now = Date()
        guard now >= window.start, now <= window.end else { return }

        let total = window.end.timeIntervalSince(window.start)
        guard total > 0 else { return }
        let progress = min(1, max(0, now.timeIntervalSince(window.start) / total))

        // Judging on a single minute is what made this fire the moment the
        // window opened; wait until the engine has calibrated on the night.
        guard staging?.isCalibrated == true else { return }

        let score = staging?.wakeReadiness() ?? 0
        let isAwake = score >= SmartWake.awakeScore

        // Early in the window only a sleeper who is plainly awake is worth
        // ringing for — everyone else still has sleep to gain.
        guard progress >= SmartWake.earliestProgress || isAwake else {
            qualifyingMinutes = 0
            return
        }

        let bar = SmartWake.startingBar - (SmartWake.startingBar - SmartWake.endingBar) * progress
        qualifyingMinutes = score >= bar ? qualifyingMinutes + 1 : 0

        let needed = isAwake ? 1 : SmartWake.confirmationMinutes
        guard qualifyingMinutes >= needed else { return }

        smartAlarmTriggered = true
        smartAlarmCallback?()
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
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP])
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
