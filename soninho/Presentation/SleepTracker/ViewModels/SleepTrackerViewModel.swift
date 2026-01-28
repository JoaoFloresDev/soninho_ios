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

    // MARK: - Published Properties
    @Published var isTracking = false
    @Published var trackingStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentPhase: SleepPhase = .light
    @Published var estimatedWakeTime: Date?

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
        storageService: StorageService = .shared
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        loadTrackingState()
    }

    // MARK: - Public Methods
    func startTracking() {
        HapticManager.success()
        isTracking = true
        trackingStartTime = Date()
        elapsedTime = 0

        // Save state
        UserDefaults.standard.set(true, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.set(trackingStartTime, forKey: StorageKeys.trackingStartTime)

        startTimer()
    }

    func stopTracking() async {
        HapticManager.success()
        stopTimer()

        guard let startTime = trackingStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Generate simulated sleep phases
        let phases = generateSleepPhases(from: startTime, to: endTime)
        let qualityScore = calculateQualityScore(phases: phases, duration: duration)

        let record = SleepRecord(
            startTime: startTime,
            endTime: endTime,
            phases: phases,
            qualityScore: qualityScore
        )

        // Try to save to HealthKit
        if healthKitService.isAuthorized {
            do {
                try await healthKitService.saveSleepRecord(record)
            } catch {
                print("Failed to save to HealthKit: \(error)")
            }
        }

        // Save locally
        var records = storageService.loadCachedSleepRecords()
        records.insert(record, at: 0)
        storageService.saveSleepRecords(records)

        // Reset state
        isTracking = false
        trackingStartTime = nil
        elapsedTime = 0

        UserDefaults.standard.set(false, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.removeObject(forKey: StorageKeys.trackingStartTime)
    }

    func cancelTracking() {
        HapticManager.mediumImpact()
        stopTimer()
        isTracking = false
        trackingStartTime = nil
        elapsedTime = 0

        UserDefaults.standard.set(false, forKey: StorageKeys.isCurrentlyTracking)
        UserDefaults.standard.removeObject(forKey: StorageKeys.trackingStartTime)
    }

    // MARK: - Private Methods
    private func loadTrackingState() {
        isTracking = UserDefaults.standard.bool(forKey: StorageKeys.isCurrentlyTracking)
        trackingStartTime = UserDefaults.standard.object(forKey: StorageKeys.trackingStartTime) as? Date

        if isTracking, let startTime = trackingStartTime {
            elapsedTime = Date().timeIntervalSince(startTime)
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

        // Update current phase simulation
        updateCurrentPhase()
    }

    private func updateCurrentPhase() {
        // Simulate phase changes based on elapsed time
        let minutes = Int(elapsedTime / 60)
        let cyclePosition = minutes % 90 // 90 minute sleep cycle

        switch cyclePosition {
        case 0..<20:
            currentPhase = .light
        case 20..<50:
            currentPhase = .deep
        case 50..<70:
            currentPhase = .light
        case 70..<90:
            currentPhase = .rem
        default:
            currentPhase = .light
        }
    }

    private func generateSleepPhases(from start: Date, to end: Date) -> [SleepPhaseData] {
        var phases: [SleepPhaseData] = []
        var currentTime = start
        let totalDuration = end.timeIntervalSince(start)
        let cycleCount = max(1, Int(totalDuration / 5400)) // 90 min cycles

        for cycle in 0..<cycleCount {
            // Light sleep
            let lightDuration = Double.random(in: 15...25) * 60
            let lightEnd = min(currentTime.addingTimeInterval(lightDuration), end)
            phases.append(SleepPhaseData(phase: .light, startTime: currentTime, endTime: lightEnd))
            currentTime = lightEnd

            guard currentTime < end else { break }

            // Deep sleep (more in first half)
            let deepMultiplier = cycle < cycleCount / 2 ? 1.5 : 0.5
            let deepDuration = Double.random(in: 15...30) * 60 * deepMultiplier
            let deepEnd = min(currentTime.addingTimeInterval(deepDuration), end)
            phases.append(SleepPhaseData(phase: .deep, startTime: currentTime, endTime: deepEnd))
            currentTime = deepEnd

            guard currentTime < end else { break }

            // REM sleep (more in second half)
            let remMultiplier = cycle >= cycleCount / 2 ? 1.5 : 0.5
            let remDuration = Double.random(in: 10...25) * 60 * remMultiplier
            let remEnd = min(currentTime.addingTimeInterval(remDuration), end)
            phases.append(SleepPhaseData(phase: .rem, startTime: currentTime, endTime: remEnd))
            currentTime = remEnd

            // Brief awake
            if Bool.random() && currentTime < end {
                let awakeDuration = Double.random(in: 1...5) * 60
                let awakeEnd = min(currentTime.addingTimeInterval(awakeDuration), end)
                phases.append(SleepPhaseData(phase: .awake, startTime: currentTime, endTime: awakeEnd))
                currentTime = awakeEnd
            }
        }

        // Fill remaining time
        if currentTime < end {
            phases.append(SleepPhaseData(phase: .light, startTime: currentTime, endTime: end))
        }

        return phases
    }

    private func calculateQualityScore(phases: [SleepPhaseData], duration: TimeInterval) -> Int {
        var score = 50

        // Duration score
        let hours = duration / 3600
        if hours >= 7 && hours <= 9 {
            score += 25
        } else if hours >= 6 && hours <= 10 {
            score += 15
        } else if hours < 5 {
            score -= 15
        }

        // Deep sleep score
        let deepDuration = phases.filter { $0.phase == .deep }.reduce(0) { $0 + $1.duration }
        let deepPercentage = (deepDuration / duration) * 100
        if deepPercentage >= 15 && deepPercentage <= 25 {
            score += 15
        } else if deepPercentage >= 10 {
            score += 8
        }

        // REM score
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
