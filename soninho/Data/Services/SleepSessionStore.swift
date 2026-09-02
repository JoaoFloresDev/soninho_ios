//
//  SleepSessionStore.swift
//  soninho
//

import Foundation
import CoreMotion

// MARK: - CMSensorDataList Iteration
/// CoreMotion still hands the recorded samples back as an NSFastEnumeration
/// list; this is the standard bridge that lets Swift for-in over it.
extension CMSensorDataList: Sequence {
    public typealias Iterator = NSFastEnumerationIterator

    public func makeIterator() -> NSFastEnumerationIterator {
        NSFastEnumerationIterator(self)
    }
}

// MARK: - Sleep Session State
/// Everything a live sleep session must not lose across a relaunch. Before
/// this existed, a mid-night relaunch built a fresh engine with zero epochs
/// and the morning report showed the whole night as one flat light block.
struct SleepSessionState: Codable {
    var engine: SleepStagingEngine
    var decider: SmartWakeDecider?
    var noiseVariance: Double
    var smartAlarmTriggered: Bool
    /// When the last epoch (or heartbeat) was written — a stale value on
    /// restore means the process was dead and the difference is a gap.
    var lastAliveAt: Date
    /// Whether the smart alarm started this session by itself (no
    /// user-tracked night, no sleep record on the way out).
    var isAlarmOnly: Bool
}

// MARK: - Sleep Session Store
/// Persists the session state to Documents once a minute and recovers the
/// minutes the process was dead from the system's accelerometer recorder.
enum SleepSessionStore {

    // MARK: - Constants
    private static let fileName = "sleep_session_state.json"
    /// The system recorder samples at a fixed 50 Hz and keeps up to 12 hours.
    private static let recorderHours: TimeInterval = 12

    private static var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[safe: 0]
            ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent(fileName)
    }

    // MARK: - Persistence

    static func save(_ state: SleepSessionState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> SleepSessionState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SleepSessionState.self, from: data)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - System Recorder Backstop

    /// Asks the motion coprocessor to keep recording the accelerometer even if
    /// this process dies. Near-zero battery; the data outlives the app.
    static func startSystemRecorder() {
        guard CMSensorRecorder.isAccelerometerRecordingAvailable() else { return }
        let recorder = CMSensorRecorder()
        DispatchQueue.global(qos: .utility).async {
            recorder.recordAccelerometer(forDuration: recorderHours * 3600)
        }
    }

    /// Recovers per-minute movement features for a window the app was dead,
    /// from the system recorder. Calls back on the main queue. `noiseVariance`
    /// seeds the extractor so the recovered minutes are judged against the
    /// same floor as the live ones.
    static func recoverGap(
        from start: Date,
        to end: Date,
        noiseVariance: Double,
        completion: @escaping ([MovementFeatures]) -> Void
    ) {
        guard CMSensorRecorder.isAccelerometerRecordingAvailable(),
              end.timeIntervalSince(start) >= 120 else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        let recorder = CMSensorRecorder()
        DispatchQueue.global(qos: .utility).async {
            var extractor = MovementFeatureExtractor(noiseVariance: noiseVariance)
            var minutes: [MovementFeatures] = []

            if let list = recorder.accelerometerData(from: start, to: end) {
                for entry in list {
                    guard let sample = entry as? CMRecordedAccelerometerData else { continue }
                    let date = sample.startDate
                    guard date >= start, date <= end else { continue }
                    if let minute = extractor.add(
                        x: sample.acceleration.x,
                        y: sample.acceleration.y,
                        z: sample.acceleration.z,
                        at: date
                    ) {
                        minutes.append(minute)
                    }
                }
                if let last = extractor.flush(at: end) {
                    minutes.append(last)
                }
            }

            DispatchQueue.main.async { completion(minutes) }
        }
    }
}
