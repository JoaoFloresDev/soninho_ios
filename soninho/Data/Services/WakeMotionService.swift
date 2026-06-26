//
//  WakeMotionService.swift
//  soninho
//
//  CoreMotion helpers for the Pacote Despertar: a shake counter for the
//  shake mission and a step counter for the anti-relapse confirmation.
//

import Foundation
import CoreMotion

// MARK: - Shake Detector
/// Counts distinct shakes via the accelerometer. Used by the shake mission.
@MainActor
final class ShakeDetector: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var shakeCount = 0

    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private let threshold: Double = 2.2          // g-force peak to register a shake
    private let debounce: TimeInterval = 0.18    // min spacing between shakes
    private var lastShakeAt: TimeInterval = 0
    private var armed = true

    // MARK: - Public Methods
    func start() {
        shakeCount = 0
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            // Delivered on the main queue, so we're already on the main actor.
            MainActor.assumeIsolated {
                guard let self else { return }
                let a = data.acceleration
                let magnitude = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
                self.process(magnitude: magnitude, at: data.timestamp)
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Private Methods
    private func process(magnitude: Double, at timestamp: TimeInterval) {
        if magnitude > threshold, armed, timestamp - lastShakeAt > debounce {
            shakeCount += 1
            lastShakeAt = timestamp
            armed = false
        } else if magnitude < 1.3 {
            // Returned near rest — ready to count the next shake.
            armed = true
        }
    }
}

// MARK: - Step Wake Monitor
/// Counts steps after the alarm is dismissed to confirm the user got out of
/// bed. Falls back to accelerometer "active motion" when pedometer data is
/// unavailable (e.g. simulator) so the confirmation can still complete.
@MainActor
final class StepWakeMonitor: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var steps = 0

    // MARK: - Private Properties
    private let pedometer = CMPedometer()
    private let motionManager = CMMotionManager()
    private var usesPedometer = false
    private var motionSeconds: Double = 0

    // MARK: - Public Methods
    func start() {
        steps = 0
        motionSeconds = 0

        if CMPedometer.isStepCountingAvailable() {
            usesPedometer = true
            pedometer.startUpdates(from: Date()) { [weak self] data, _ in
                guard let self, let data else { return }
                Task { @MainActor in
                    self.steps = data.numberOfSteps.intValue
                }
            }
        } else {
            startMotionFallback()
        }
    }

    func stop() {
        if usesPedometer {
            pedometer.stopUpdates()
        }
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Private Methods
    private func startMotionFallback() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                let a = data.acceleration
                let magnitude = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
                // Treat each ~0.1s of meaningful movement as roughly one "step".
                if abs(magnitude - 1.0) > 0.25 {
                    self.motionSeconds += 0.1
                    self.steps = Int(self.motionSeconds * 2)
                }
            }
        }
    }
}
