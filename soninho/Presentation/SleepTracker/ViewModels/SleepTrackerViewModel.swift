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
    @Published var movementIntensity: Double = 0
    @Published var soundLevel: Double = 0
    /// Whether the engine has staged anything yet — before this the phase is
    /// a placeholder and the UI must say "calibrating", not "Light Sleep".
    @Published var isCalibrated = false
    /// Minutes observed so far, for the calibration progress label — a bare
    /// "Calibrating…" with no movement reads as the app hanging.
    @Published var calibrationMinutesObserved = 0

    // MARK: - Constants
    let calibrationMinutesNeeded = SleepStagingEngine.Tuning.minimumEpochsForCalibration
    /// This night's typical turn — the unit the movement bar scales against.
    @Published var movementScale: Double = SleepStagingEngine.Tuning.fallbackTurnScale

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

        // If the monitor could not actually start (no accelerometer, start
        // guard), showing the tracking UI would leave "calibrating" on screen
        // forever with nothing behind it.
        guard motionMonitor.isMonitoring else {
            cancelTracking()
            return
        }

        startTimer()
    }

    func stopTracking(greet: Bool = true) async {
        stopTimer()

        // The recorder owns saving (it also runs from the alarm-completion
        // path when this ViewModel does not exist); a second finisher just
        // gets nil back. In-app tracked sleep stays local — never written to
        // Apple Health.
        let record = SleepNightRecorder.finishTrackedNight()

        // Reset state
        isTracking = false
        trackingStartTime = nil
        elapsedTime = 0
        movementIntensity = 0

        // Greet the user — the night is over. Skipped when the alarm screen
        // already showed its own good-morning, and when nothing was actually
        // saved ("your night was saved" over an empty stats tab reads as a lie).
        if greet, record != nil {
            WakeGreetingManager.shared.show()
        }
    }

    func cancelTracking() {
        stopTimer()
        // The monitor may be serving the SMART ALARM (alarm-only session) —
        // discarding a stale tracked night must not disarm this morning's
        // wake-up with it.
        if !motionMonitor.isAlarmOnlySession {
            motionMonitor.stopMonitoring()
        }
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

        motionMonitor.$isCalibrated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] calibrated in
                self?.isCalibrated = calibrated
            }
            .store(in: &cancellables)

        motionMonitor.$movementScale
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scale in
                self?.movementScale = scale
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

        if !isCalibrated {
            calibrationMinutesObserved = min(motionMonitor.observedMinutes, calibrationMinutesNeeded)
        }

        if elapsedTime >= AppConstants.autoCancelSleepSessionHours * 3600 {
            cancelTracking()
        }
    }
}
