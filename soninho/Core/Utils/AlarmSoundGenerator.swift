//
//  AlarmSoundGenerator.swift
//  soninho
//
//  Created by João Flores on 22/02/26.
//

import Foundation
import AVFoundation
import UserNotifications

// MARK: - Alarm Sound Generator
/// Generates distinct alarm sound WAV files for each AlarmSound type
/// and saves them to Library/Sounds/ so iOS can play them as notification sounds.
enum AlarmSoundGenerator {
    // MARK: - Constants
    private static let sampleRate: Double = 44100
    private static let duration: Double = 29.0

    // MARK: - Public Methods

    /// Generates all alarm sound files on app launch.
    /// Bump when the sound generation changes so cached WAVs are regenerated.
    private static let soundsVersion = 2

    static func generateAlarmSoundsIfNeeded() {
        guard let soundsDir = librarySoundsDirectory() else { return }

        let upToDate = UserDefaults.standard.integer(forKey: "alarmSoundsVersion") == soundsVersion

        for sound in AlarmSound.allCases {
            let fileName = "\(sound.rawValue)_alarm.wav"
            let filePath = soundsDir.appendingPathComponent(fileName)

            if upToDate,
               FileManager.default.fileExists(atPath: filePath.path),
               let size = (try? FileManager.default.attributesOfItem(atPath: filePath.path))?[.size] as? Int,
               size > 1000 {
                continue
            }

            try? FileManager.default.removeItem(at: filePath)
            generateSound(type: sound, to: filePath)
        }

        UserDefaults.standard.set(soundsVersion, forKey: "alarmSoundsVersion")
    }

    /// Returns UNNotificationSound for a specific alarm sound type.
    static func notificationSound(for sound: AlarmSound = .sunrise) -> UNNotificationSound {
        let fileName = "\(sound.rawValue)_alarm.wav"
        if let soundsDir = librarySoundsDirectory() {
            let soundPath = soundsDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: soundPath.path) {
                return UNNotificationSound(named: UNNotificationSoundName(fileName))
            }
        }
        generateAlarmSoundsIfNeeded()
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }

    /// Returns the URL of an alarm sound file for AVAudioPlayer playback.
    static func alarmSoundURL(for sound: AlarmSound = .sunrise) -> URL? {
        guard let soundsDir = librarySoundsDirectory() else { return nil }
        let url = soundsDir.appendingPathComponent("\(sound.rawValue)_alarm.wav")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Private Methods

    private static func librarySoundsDirectory() -> URL? {
        guard let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }
        let soundsDir = libraryDir.appendingPathComponent("Sounds")

        if !FileManager.default.fileExists(atPath: soundsDir.path) {
            do {
                try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            } catch {
                print("[AlarmSound] ERROR creating directory: \(error)")
                return nil
            }
        }

        return soundsDir
    }

    // MARK: - Sound Generation

    private static func generateSound(type: AlarmSound, to url: URL) {
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        switch type {
        case .sunrise:
            generateSunrise(&samples)
        case .birds:
            generateBirds(&samples)
        case .ocean:
            generateOcean(&samples)
        case .gentle:
            generateGentle(&samples)
        case .piano:
            generatePiano(&samples)
        case .forest:
            generateForest(&samples)
        }

        writeWAV(samples: samples, to: url)
    }

    // MARK: - Sunrise (warm ascending tones)
    private static func generateSunrise(_ samples: inout [Float]) {
        let numSamples = samples.count
        var sampleIndex = 0

        // Warm ascending chord tones: C4, E4, G4, C5
        let notes: [Float] = [261.63, 329.63, 392.0, 523.25]
        let noteDuration = 1.2
        let noteGap = 0.6
        let fadeDuration = 0.15

        while sampleIndex < numSamples {
            let progress = Float(sampleIndex) / Float(numSamples)
            let volume: Float = 0.3 + progress * 0.5

            for (_, freq) in notes.enumerated() {
                let adjustedFreq = freq * (1.0 + progress * 0.15)
                let samplesPerNote = Int(sampleRate * noteDuration)
                let fadeIn = Int(sampleRate * fadeDuration)
                let fadeOut = Int(sampleRate * fadeDuration)

                for s in 0..<samplesPerNote {
                    guard sampleIndex + s < numSamples else { break }
                    let t = Float(s) / Float(sampleRate)
                    let sine = sin(2.0 * Float.pi * adjustedFreq * t)
                    let harmonic = sin(2.0 * Float.pi * adjustedFreq * 2.0 * t) * 0.2

                    var envelope: Float = 1.0
                    if s < fadeIn { envelope = Float(s) / Float(fadeIn) }
                    else if s > samplesPerNote - fadeOut { envelope = Float(samplesPerNote - s) / Float(fadeOut) }

                    samples[sampleIndex + s] += (sine + harmonic) * envelope * volume * 0.3
                }

                sampleIndex += samplesPerNote
                sampleIndex += Int(sampleRate * 0.1)
            }

            sampleIndex += Int(sampleRate * noteGap)
        }
    }

    // MARK: - Birds (chirping patterns)
    private static func generateBirds(_ samples: inout [Float]) {
        let numSamples = samples.count
        var sampleIndex = 0

        // Chirp parameters - high-pitched short notes with frequency sweeps
        let chirpFreqs: [(start: Float, end: Float)] = [
            (2200, 3200), (1800, 2800), (2500, 3500),
            (2000, 3000), (2400, 3400), (1900, 2900)
        ]
        var chirpIndex = 0

        while sampleIndex < numSamples {
            let progress = Float(sampleIndex) / Float(numSamples)
            let volume: Float = 0.25 + progress * 0.45

            // A group of 2-4 chirps
            let chirpsInGroup = 2 + (chirpIndex % 3)

            for _ in 0..<chirpsInGroup {
                let chirp = chirpFreqs[chirpIndex % chirpFreqs.count]
                let chirpDuration = Int(sampleRate * Double.random(in: 0.06...0.12))
                let fadeLen = min(200, chirpDuration / 3)

                for s in 0..<chirpDuration {
                    guard sampleIndex + s < numSamples else { break }
                    let t = Float(s) / Float(chirpDuration)
                    let freq = chirp.start + (chirp.end - chirp.start) * t
                    let sine = sin(2.0 * Float.pi * freq * Float(s) / Float(sampleRate))

                    var envelope: Float = 1.0
                    if s < fadeLen { envelope = Float(s) / Float(fadeLen) }
                    else if s > chirpDuration - fadeLen { envelope = Float(chirpDuration - s) / Float(fadeLen) }

                    samples[sampleIndex + s] = sine * envelope * volume * 0.6
                }

                sampleIndex += chirpDuration
                // Short gap between chirps in the same group
                sampleIndex += Int(sampleRate * Double.random(in: 0.05...0.12))
                chirpIndex += 1
            }

            // Pause between groups (gets shorter over time)
            let pauseDuration = max(0.4, 1.2 - Double(progress) * 0.8)
            sampleIndex += Int(sampleRate * pauseDuration)
        }
    }

    // MARK: - Ocean (wave-like swooshing)
    private static func generateOcean(_ samples: inout [Float]) {
        let numSamples = samples.count

        // Low frequency sweep simulating waves with filtered noise
        for i in 0..<numSamples {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(numSamples)
            let volume: Float = 0.2 + progress * 0.5

            // Wave cycle: ~4 seconds per wave
            let waveCycle = sin(2.0 * Float.pi * t / 4.0) * 0.5 + 0.5

            // Low rumble (ocean base)
            let low = sin(2.0 * Float.pi * 80 * t) * 0.3
            let mid = sin(2.0 * Float.pi * 180 * t + sin(2.0 * Float.pi * 0.3 * t)) * 0.2

            // High shimmer (wave crash)
            let shimmer = sin(2.0 * Float.pi * 800 * t) * waveCycle * 0.1
            let shimmer2 = sin(2.0 * Float.pi * 1200 * t) * waveCycle * 0.05

            // Tonal bell over the waves (marking each wave peak)
            let bellFreq: Float = 523.25 // C5
            let bellPhase = sin(2.0 * Float.pi * t / 4.0)
            let bell = bellPhase > 0.9 ? sin(2.0 * Float.pi * bellFreq * t) * 0.15 * (bellPhase - 0.9) * 10 : 0

            samples[i] = (low + mid + shimmer + shimmer2 + bell) * volume
        }
    }

    // MARK: - Gentle (soft chime with reverb-like decay)
    private static func generateGentle(_ samples: inout [Float]) {
        let numSamples = samples.count
        var sampleIndex = 0

        // Soft chime: single note with long decay, repeated
        let chimeNotes: [Float] = [523.25, 659.25, 783.99, 659.25, 523.25] // C5 E5 G5 E5 C5
        var noteIndex = 0

        while sampleIndex < numSamples {
            let progress = Float(sampleIndex) / Float(numSamples)
            let volume: Float = 0.25 + progress * 0.45

            let freq = chimeNotes[noteIndex % chimeNotes.count]
            let chimeDuration = Int(sampleRate * 1.5)
            let decayTime: Float = 1.5

            for s in 0..<chimeDuration {
                guard sampleIndex + s < numSamples else { break }
                let t = Float(s) / Float(sampleRate)

                // Exponential decay envelope
                let envelope = exp(-t / (decayTime * 0.4))

                // Main tone + soft harmonics
                let fundamental = sin(2.0 * Float.pi * freq * t)
                let h2 = sin(2.0 * Float.pi * freq * 2 * t) * 0.3
                let h3 = sin(2.0 * Float.pi * freq * 3 * t) * 0.1

                samples[sampleIndex + s] = (fundamental + h2 + h3) * envelope * volume * 0.4
            }

            sampleIndex += chimeDuration

            // Pause between chimes (gets shorter)
            let pause = max(0.5, 1.5 - Double(progress) * 1.0)
            sampleIndex += Int(sampleRate * pause)
            noteIndex += 1
        }
    }

    // MARK: - Piano (musical melody)
    private static func generatePiano(_ samples: inout [Float]) {
        let numSamples = samples.count
        var sampleIndex = 0

        // Simple melody: C E G C' G E C (piano-like with harmonics and decay)
        let melodyFreqs: [Float] = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 261.63]
        var noteIndex = 0

        while sampleIndex < numSamples {
            let progress = Float(sampleIndex) / Float(numSamples)
            let volume: Float = 0.3 + progress * 0.5

            let freq = melodyFreqs[noteIndex % melodyFreqs.count]
            let noteDuration = Int(sampleRate * 0.6)
            let attack = Int(sampleRate * 0.01)

            for s in 0..<noteDuration {
                guard sampleIndex + s < numSamples else { break }
                let t = Float(s) / Float(sampleRate)

                // Piano-like: fast attack, medium decay
                var envelope: Float
                if s < attack {
                    envelope = Float(s) / Float(attack)
                } else {
                    envelope = exp(-t * 3.0) * 0.8 + 0.2 * exp(-t * 0.5)
                }

                // Rich harmonics for piano timbre
                let f1 = sin(2.0 * Float.pi * freq * t)
                let f2 = sin(2.0 * Float.pi * freq * 2 * t) * 0.5
                let f3 = sin(2.0 * Float.pi * freq * 3 * t) * 0.25
                let f4 = sin(2.0 * Float.pi * freq * 4 * t) * 0.1
                let f5 = sin(2.0 * Float.pi * freq * 5 * t) * 0.05

                samples[sampleIndex + s] = (f1 + f2 + f3 + f4 + f5) * envelope * volume * 0.25
            }

            sampleIndex += noteDuration

            // Short gap between notes
            let gap = max(0.1, 0.3 - Double(progress) * 0.15)
            sampleIndex += Int(sampleRate * gap)
            noteIndex += 1

            // Add a pause after each melody cycle
            if noteIndex % melodyFreqs.count == 0 {
                let cyclePause = max(0.3, 0.8 - Double(progress) * 0.4)
                sampleIndex += Int(sampleRate * cyclePause)
            }
        }
    }

    // MARK: - Forest (nature ambience with wind and tonal bells)
    private static func generateForest(_ samples: inout [Float]) {
        let numSamples = samples.count

        // Wind-like base with occasional bell tones
        let bellNotes: [Float] = [440.0, 554.37, 659.25] // A4 C#5 E5
        var nextBellSample = Int(sampleRate * 1.5)
        var bellIndex = 0

        for i in 0..<numSamples {
            let t = Float(i) / Float(sampleRate)
            let progress = Float(i) / Float(numSamples)
            let volume: Float = 0.2 + progress * 0.5

            // Wind: multiple low-frequency oscillations
            let wind1 = sin(2.0 * Float.pi * 120 * t + sin(2.0 * Float.pi * 0.2 * t) * 3) * 0.15
            let wind2 = sin(2.0 * Float.pi * 200 * t + sin(2.0 * Float.pi * 0.15 * t) * 2) * 0.1
            let windEnvelope = sin(2.0 * Float.pi * t / 6.0) * 0.5 + 0.5

            samples[i] = (wind1 + wind2) * windEnvelope * volume

            // Bell tones at intervals
            if i >= nextBellSample {
                let bellFreq = bellNotes[bellIndex % bellNotes.count]
                let bellDuration = Int(sampleRate * 2.0)

                for s in 0..<bellDuration {
                    guard i + s < numSamples else { break }
                    let bt = Float(s) / Float(sampleRate)
                    let bellEnvelope = exp(-bt / 0.6)
                    let bellTone = sin(2.0 * Float.pi * bellFreq * bt)
                    let bellHarmonic = sin(2.0 * Float.pi * bellFreq * 2 * bt) * 0.15

                    samples[i + s] += (bellTone + bellHarmonic) * bellEnvelope * volume * 0.35
                }

                bellIndex += 1
                let interval = max(1.0, 2.5 - Double(progress) * 1.5)
                nextBellSample = i + Int(sampleRate * interval)
            }
        }
    }

    // MARK: - WAV Writer

    private static func writeWAV(samples: [Float], to url: URL) {
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let sampleRateInt = UInt32(sampleRate)
        let byteRate = sampleRateInt * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)
        let dataSize = UInt32(samples.count * Int(bitsPerSample / 8))
        let fileSize = 36 + dataSize

        var data = Data()
        data.reserveCapacity(Int(44 + dataSize))

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)

        // fmt sub-chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sampleRateInt.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // data sub-chunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })

        // Normalize to a loud target peak so alarms are actually audible — the
        // generators scale samples conservatively (~0.3 peak), which sounds very
        // quiet even at full device volume.
        let peak = samples.reduce(Float(0)) { Swift.max($0, abs($1)) }
        let gain: Float = peak > 0.0001 ? (0.95 / peak) : 1.0

        // Convert float samples to 16-bit PCM
        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample * gain))
            let int16Value = Int16(clamped * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: int16Value.littleEndian) { Array($0) })
        }

        do {
            try data.write(to: url)
        } catch {
            print("[AlarmSound] ERROR writing WAV file: \(error)")
        }
    }
}
