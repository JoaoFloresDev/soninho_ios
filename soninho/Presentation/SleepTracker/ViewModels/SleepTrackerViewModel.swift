//
//  SleepTrackerViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import Combine

// MARK: - Sleep Tracker ViewModel
@MainActor
final class SleepTrackerViewModel: ObservableObject {
    // MARK: - Dependencies
    private let healthKitService: HealthKitService
    private let storageService: StorageService
    private let motionMonitor: MotionSleepMonitor

    // MARK: - Published Properties
    @Published var isTracking = false
    @Published var trackingStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentPhase: SleepPhase = .light
    @Published var estimatedWakeTime: Date?
    @Published var movementIntensity: Double = 0
    @Published var soundLevel: Double = 0

    // MARK: - Private Properties
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var elapsedTimeString: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var trackingStatusMessage: String {
        if isTracking {
            return String(localized: "tracker_tracking_sleep")
        } else {
            return String(localized: "tracker_ready_to_sleep")
        }
    }

    // MARK: - Init
    init(
        healthKitService: HealthKitService = .shared,
        storageService: StorageService = .shared,
        motionMonitor: MotionSleepMonitor = .shared
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        self.motionMonitor = motionMonitor
        loadTrackingState()
        observeMotionMonitor()
        observeAlarmCompletion()
    }

    // MARK: - Public Methods
    func startTracking() {
        guard !isTracking else { return }

        isTracking = true

        trackingStartTime = Date()
        elapsedTime = 0

        // Save state
        UserDefaults.standard.set(true, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.set(trackingStartTime, forKey: StorageKeys.trackingStartTime)

        // Start real motion monitoring
        motionMonitor.startMonitoring()

        // Configure smart alarm if one is enabled
        configureSmartAlarmIfNeeded()

        startTimer()
    }

    func stopTracking() async {
        stopTimer()

        guard let startTime = trackingStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Get motion-detected phases (cycle model + accelerometer)
        let motionPhases = motionMonitor.getRecordedPhases()
        let phases: [SleepPhaseData]
        let qualityScore: Int

        if !motionPhases.isEmpty {
            phases = motionPhases
        } else {
            phases = generateFallbackPhases(from: startTime, to: endTime)
        }

        qualityScore = motionMonitor.calculateQualityScore(phases: phases, totalDuration: duration)

        // Stop motion monitoring
        motionMonitor.stopMonitoring()

        let record = SleepRecord(
            startTime: startTime,
            endTime: endTime,
            phases: phases,
            qualityScore: qualityScore
        )

        // In-app tracked sleep stays local — it is NOT written to Apple Health.
        // (Apple Health / Resumo must reflect only the device's own sleep data.)

        // Save locally
        var records = storageService.loadCachedSleepRecords()
        records.insert(record, at: 0)
        storageService.saveSleepRecords(records)

        // Update the tracked-nights streak (was never being called → stuck at 0).
        storageService.updateStreak(for: record.endTime)

        // Reset state
        isTracking = false
        trackingStartTime = nil
        elapsedTime = 0
        movementIntensity = 0

        UserDefaults.standard.set(false, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.removeObject(forKey: StorageKeys.trackingStartTime)

        // Greet the user — the night is over.
        WakeGreetingManager.shared.show()
    }

    func cancelTracking() {
        stopTimer()
        motionMonitor.stopMonitoring()
        isTracking = false
        trackingStartTime = nil
        elapsedTime = 0
        movementIntensity = 0

        UserDefaults.standard.set(false, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.removeObject(forKey: StorageKeys.trackingStartTime)
    }

    // MARK: - Private Methods

    /// When an alarm is fully dismissed (not snoozed), end the active sleep
    /// session — waking up via the alarm means the night is over.
    private func observeAlarmCompletion() {
        NotificationCenter.default.publisher(for: .didCompleteAlarm)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isTracking else { return }
                Task { await self.stopTracking() }
            }
            .store(in: &cancellables)
    }

    private func observeMotionMonitor() {
        motionMonitor.$currentPhase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                self?.currentPhase = phase
            }
            .store(in: &cancellables)

        motionMonitor.$movementIntensity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] intensity in
                self?.movementIntensity = intensity
            }
            .store(in: &cancellables)

        motionMonitor.$soundLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.soundLevel = level
            }
            .store(in: &cancellables)
    }

    private func configureSmartAlarmIfNeeded() {
        let alarms = storageService.loadAlarms()
        guard let smartAlarm = alarms.first(where: { $0.isEnabled && $0.isSmartAlarm }) else { return }
        guard let nextAlarmDate = smartAlarm.nextAlarmDate else { return }

        let windowStart = nextAlarmDate.addingTimeInterval(-Double(smartAlarm.smartAlarmWindow * 60))

        motionMonitor.configureSmartAlarm(windowStart: windowStart, windowEnd: nextAlarmDate) {
            Task { @MainActor in
                // Smart alarm detected light sleep - trigger alarm
                let notificationService = NotificationService.shared
                notificationService.handleForegroundAlarm(
                    alarmId: smartAlarm.id.uuidString,
                    soundName: smartAlarm.sound.rawValue,
                    volume: Float(smartAlarm.volume),
                    vibration: smartAlarm.vibrationEnabled
                )
            }
        }
    }

    private func loadTrackingState() {
        isTracking = UserDefaults.standard.bool(forKey: StorageKeys.isCurrentlyTracking)
        trackingStartTime = UserDefaults.standard.object(forKey: StorageKeys.trackingStartTime) as? Date

        if isTracking, let startTime = trackingStartTime {
            elapsedTime = Date().timeIntervalSince(startTime)
            // Resume motion monitoring if it was active
            if !motionMonitor.isMonitoring {
                motionMonitor.startMonitoring()
                configureSmartAlarmIfNeeded()
            }
            startTimer()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let startTime = trackingStartTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }

    // MARK: - Fallback Phase Generation
    /// Used when accelerometer is not available (simulator, older devices)
    private func generateFallbackPhases(from start: Date, to end: Date) -> [SleepPhaseData] {
        var phases: [SleepPhaseData] = []
        var currentTime = start
        let totalDuration = end.timeIntervalSince(start)
        let cycleCount = max(1, Int(totalDuration / 5400))

        for cycle in 0..<cycleCount {
            let lightDuration = Double.random(in: 15...25) * 60
            let lightEnd = min(currentTime.addingTimeInterval(lightDuration), end)
            phases.append(SleepPhaseData(phase: .light, startTime: currentTime, endTime: lightEnd))
            currentTime = lightEnd

            guard currentTime < end else { break }

            let deepMultiplier = cycle < cycleCount / 2 ? 1.5 : 0.5
            let deepDuration = Double.random(in: 15...30) * 60 * deepMultiplier
            let deepEnd = min(currentTime.addingTimeInterval(deepDuration), end)
            phases.append(SleepPhaseData(phase: .deep, startTime: currentTime, endTime: deepEnd))
            currentTime = deepEnd

            guard currentTime < end else { break }

            let remMultiplier = cycle >= cycleCount / 2 ? 1.5 : 0.5
            let remDuration = Double.random(in: 10...25) * 60 * remMultiplier
            let remEnd = min(currentTime.addingTimeInterval(remDuration), end)
            phases.append(SleepPhaseData(phase: .rem, startTime: currentTime, endTime: remEnd))
            currentTime = remEnd

            if Bool.random() && currentTime < end {
                let awakeDuration = Double.random(in: 1...5) * 60
                let awakeEnd = min(currentTime.addingTimeInterval(awakeDuration), end)
                phases.append(SleepPhaseData(phase: .awake, startTime: currentTime, endTime: awakeEnd))
                currentTime = awakeEnd
            }
        }

        if currentTime < end {
            phases.append(SleepPhaseData(phase: .light, startTime: currentTime, endTime: end))
        }

        return phases
    }

    private func calculateFallbackQualityScore(phases: [SleepPhaseData], duration: TimeInterval) -> Int {
        var score = 50

        let hours = duration / 3600
        if hours >= 7 && hours <= 9 {
            score += 25
        } else if hours >= 6 && hours <= 10 {
            score += 15
        } else if hours < 5 {
            score -= 15
        }

        let deepDuration = phases.filter { $0.phase == .deep }.reduce(0) { $0 + $1.duration }
        let deepPercentage = (deepDuration / duration) * 100
        if deepPercentage >= 15 && deepPercentage <= 25 {
            score += 15
        } else if deepPercentage >= 10 {
            score += 8
        }

        let remDuration = phases.filter { $0.phase == .rem }.reduce(0) { $0 + $1.duration }
        let remPercentage = (remDuration / duration) * 100
        if remPercentage >= 20 && remPercentage <= 25 {
            score += 10
        } else if remPercentage >= 15 {
            score += 5
        }

        return min(100, max(0, score + Int.random(in: -5...5)))
    }
}
