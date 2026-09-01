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
        storageService: StorageService = .shared,
        motionMonitor: MotionSleepMonitor = .shared
    ) {
        self.storageService = storageService
        self.motionMonitor = motionMonitor
        loadTrackingState()
        observeMotionMonitor()
        observeAlarmCompletion()
    }

    // MARK: - Public Methods
    func startTracking() {
        Analytics.featureUsed("sleep_tracking", source: "tab")
        guard !isTracking else { return }

        isTracking = true

        trackingStartTime = Date()
        elapsedTime = 0

        // Save state
        UserDefaults.standard.set(true, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.set(trackingStartTime, forKey: StorageKeys.trackingStartTime)

        // Start real motion monitoring — the monitor arms the smart-alarm
        // window itself, from storage, and re-checks it every minute.
        motionMonitor.startMonitoring()

        startTimer()
    }

    func stopTracking(greet: Bool = true) async {
        stopTimer()

        guard let startTime = trackingStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Motion-detected phases (staging engine over the accelerometer data)
        let phases = motionMonitor.getRecordedPhases()
        let qualityScore = motionMonitor.calculateQualityScore(phases: phases, totalDuration: duration)

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
        // A night seen through to the morning is the other moment the app
        // delivered on its promise.
        Analytics.coreAction("night_tracked")
        _ = RatingGateService.shared.recordPositiveEvent()

        // Update the tracked-nights streak (was never being called → stuck at 0).
        storageService.updateStreak(for: record.endTime)

        // Reset state
        isTracking = false
        trackingStartTime = nil
        elapsedTime = 0
        movementIntensity = 0

        UserDefaults.standard.set(false, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.removeObject(forKey: StorageKeys.trackingStartTime)

        // Greet the user — the night is over. Skipped when the alarm screen
        // already showed its own good-morning (avoids a double greeting).
        if greet {
            WakeGreetingManager.shared.show()
            // A saved night is an aha-moment; let the greeting finish first.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                RatingGateService.shared.recordPositiveEvent()
            }
        }
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
                // The alarm screen shows its own greeting on completion.
                Task { await self.stopTracking(greet: false) }
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

    private func loadTrackingState() {
        isTracking = UserDefaults.standard.bool(forKey: StorageKeys.isCurrentlyTracking)
        trackingStartTime = UserDefaults.standard.object(forKey: StorageKeys.trackingStartTime) as? Date

        if isTracking, let startTime = trackingStartTime {
            // Sessions past the auto-cancel limit are stale — discard instead of resuming.
            guard Date().timeIntervalSince(startTime) < AppConstants.autoCancelSleepSessionHours * 3600 else {
                cancelTracking()
                return
            }
            elapsedTime = Date().timeIntervalSince(startTime)
            // Resume motion monitoring if it was active — the monitor restores
            // the persisted night and records the dead minutes as a gap.
            if !motionMonitor.isMonitoring {
                motionMonitor.startMonitoring()
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

        if elapsedTime >= AppConstants.autoCancelSleepSessionHours * 3600 {
            cancelTracking()
        }
    }
}
