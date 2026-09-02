//
//  SleepSoundMonitor.swift
//  soninho
//

import Foundation
import AVFoundation
import SoundAnalysis

// MARK: - Sleep Sound Monitor
/// Listens to the night through the microphone: a live loudness level for the
/// UI, and Apple's built-in sound classifier for what the loudness IS.
///
/// The classifier matters because sound disambiguates movement: a person who
/// is snoring is asleep, however much they toss — so snoring vetoes a wake
/// call — while sustained speech or noise corroborates one. The model ships
/// inside iOS (SoundAnalysis, ~300 classes, milliseconds per window), so this
/// costs almost nothing on top of the audio engine the app already runs to
/// stay alive overnight.
///
/// The audio engine doubles as the keep-alive: an active input session is what
/// stops iOS suspending the app mid-night.
final class SleepSoundMonitor: NSObject {

    // MARK: - Constants
    private enum Tuning {
        /// Classifier window. Longer = fewer inferences = less battery.
        static let windowSeconds: Double = 2.0
        /// Confidence below this is ignored.
        static let confidence: Double = 0.6
        /// Sounds that mean the sleeper is asleep.
        static let sleepSounds: Set<String> = ["snoring", "breathing"]
        /// Sounds that mean someone is up and about.
        static let disturbanceSounds: Set<String> = [
            "speech", "male_speech", "female_speech", "child_speech",
            "conversation", "person_walking", "door", "door_slam",
        ]
        /// Loudness floor (0-1) below which no classification runs.
        static let analysisGate: Double = 0.08
    }

    // MARK: - Properties
    /// Live loudness 0 (silence) to 1, -60 dB mapped to 0.
    private(set) var soundLevel: Double = 0
    /// Whether the engine is actually running — the keep-alive health signal.
    private(set) var isRunning = false
    /// Called on the main queue whenever the level changes meaningfully.
    var onLevel: ((Double) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.gambitstudio.soninho.soundAnalysis", qos: .utility)

    /// Per-minute accumulators, mutated on the analysis queue.
    private var sleepSoundSeconds: Double = 0
    private var disturbanceSeconds: Double = 0
    private let accumulatorLock = NSLock()

    // MARK: - Public Methods

    /// Asks for the microphone and starts listening. Reports whether the mic
    /// was granted — a denial must surface, not vanish: without the input
    /// session the app can be suspended mid-night and tracking dies with it.
    /// With `promptIfNeeded` false the system dialog never appears (a session
    /// the alarm started by itself must not wake the sleeper with a prompt);
    /// audio simply stays off unless permission already exists.
    func start(promptIfNeeded: Bool = true, completion: @escaping (Bool) -> Void) {
        let begin: (Bool) -> Void = { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else {
                    completion(false)
                    return
                }
                self?.startEngine()
                completion(self?.isRunning == true)
            }
        }

        guard promptIfNeeded else {
            begin(Self.permissionAlreadyGranted)
            return
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: begin)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(begin)
        }
    }

    /// Whether the microphone is usable without showing the system prompt.
    private static var permissionAlreadyGranted: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        }
        return AVAudioSession.sharedInstance().recordPermission == .granted
    }

    func stop() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        analyzer?.completeAnalysis()
        analyzer = nil
        isRunning = false
        soundLevel = 0
    }

    /// Drains the minute's accumulated classifications.
    func snapshotMinute() -> SoundMinute {
        accumulatorLock.lock()
        defer {
            sleepSoundSeconds = 0
            disturbanceSeconds = 0
            accumulatorLock.unlock()
        }
        return SoundMinute(
            sleepSoundSeconds: Int(sleepSoundSeconds.rounded()),
            disturbanceSeconds: Int(disturbanceSeconds.rounded())
        )
    }

    // MARK: - Private Methods

    private func startEngine() {
        guard !isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothHFP]
            )
            try session.setActive(true)

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { return }

            let streamAnalyzer = SNAudioStreamAnalyzer(format: format)
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.windowDuration = CMTimeMakeWithSeconds(
                Tuning.windowSeconds,
                preferredTimescale: 48_000
            )
            try streamAnalyzer.add(request, withObserver: self)
            analyzer = streamAnalyzer

            input.installTap(onBus: 0, bufferSize: 8192, format: format) { [weak self] buffer, when in
                self?.process(buffer: buffer, at: when)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    private func process(buffer: AVAudioPCMBuffer, at when: AVAudioTime) {
        let level = Self.level(of: buffer)

        DispatchQueue.main.async { [weak self] in
            self?.soundLevel = level
            self?.onLevel?(level)
        }

        // Silence needs no classifier — the gate saves the battery for the
        // hours nothing is happening.
        guard level >= Tuning.analysisGate, let analyzer else { return }
        analysisQueue.async {
            analyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
        }
    }

    /// RMS loudness mapped like the old metering: -60 dB → 0, 0 dB → 1.
    private static func level(of buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for index in 0..<frames {
            let sample = data[index]
            sum += sample * sample
        }
        let rms = (sum / Float(frames)).squareRoot()
        let decibels = 20 * log10(max(Double(rms), 1e-6))
        return max(0, (decibels + 60) / 60)
    }
}

// MARK: - SNResultsObserving
extension SleepSoundMonitor: SNResultsObserving {

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }

        let confident = classification.classifications.filter {
            $0.confidence >= Tuning.confidence
        }
        guard !confident.isEmpty else { return }

        var sleepy = 0.0
        var disturbed = 0.0
        for item in confident {
            if Tuning.sleepSounds.contains(item.identifier) {
                sleepy = Tuning.windowSeconds
            } else if Tuning.disturbanceSounds.contains(item.identifier) {
                disturbed = Tuning.windowSeconds
            }
        }
        guard sleepy > 0 || disturbed > 0 else { return }

        accumulatorLock.lock()
        sleepSoundSeconds += sleepy
        disturbanceSeconds += disturbed
        accumulatorLock.unlock()
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {}
}
