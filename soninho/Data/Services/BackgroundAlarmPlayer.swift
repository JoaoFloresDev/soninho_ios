//
//  BackgroundAlarmPlayer.swift
//  soninho
//
//  Created by João Flores on 22/02/26.
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Background Alarm Player
/// Keeps the app alive in background by playing near-silent audio,
/// then switches to the real alarm sound when the scheduled time arrives.
/// This is the standard technique used by professional alarm apps (Sleep Cycle, Alarmy, etc.)
/// to bypass iOS notification sound limitations.
@MainActor
final class BackgroundAlarmPlayer: ObservableObject {
    // MARK: - Singleton
    static let shared = BackgroundAlarmPlayer()

    // MARK: - Published Properties
    @Published private(set) var isBackgroundActive = false

    // MARK: - Private Properties
    private var silentPlayer: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private var alarmCheckTimer: DispatchSourceTimer?
    private var vibrationTimer: DispatchSourceTimer?
    private var systemAlarmTimer: DispatchSourceTimer?
    private let audioSession = AVAudioSession.sharedInstance()
    private let timerQueue = DispatchQueue(label: "com.gambitstudio.soninho.alarmtimer", qos: .userInteractive)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var silentAudioData: Data?
    private var hasFiredAlarmIds: Set<String> = []

    // MARK: - Init
    private init() {
        // Pre-generate silent audio data so it's ready instantly
        silentAudioData = generateSilentAudioData()
        // Configure audio session early
        configureAudioSession()
        registerAudioSessionObservers()
    }

    // MARK: - Audio Session Resilience

    private func registerAudioSessionObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            Task { @MainActor in self?.recoverPlayback() }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.recoverPlayback() }
        }
        nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.recoverPlayback() }
        }
    }

    /// Re-activates the session and resumes whatever should be playing. An
    /// interruption (call, Siri, another app) can silently kill the silent
    /// keep-alive — without this the app suspends and the alarm never fires.
    private func recoverPlayback() {
        print("[FIRE] recover bgActive=\(isBackgroundActive) alarmPlayer=\(alarmPlayer != nil)")
        guard isBackgroundActive else { return }
        if alarmPlayer != nil {
            try? audioSession.setActive(true)
            alarmPlayer?.play()
        } else {
            configureAudioSession()
            startSilentAudio()
        }
    }

    // MARK: - Public Methods

    /// Prepares the audio session. Call on app launch.
    func prepare() {
        configureAudioSession()
    }

    /// Starts background audio to keep the app alive.
    /// Call this when the app is about to enter background (inactive or background phase).
    func startBackgroundKeepAlive() {
        guard !isBackgroundActive else { return }

        // Check if there's an upcoming alarm within the next 12 hours
        let alarms = StorageService.shared.loadAlarms()
        let hasUpcomingAlarm = alarms.contains { alarm in
            guard alarm.isEnabled else { return false }
            if let nextDate = alarm.nextAlarmDate {
                return nextDate.timeIntervalSinceNow < 12 * 3600 && nextDate.timeIntervalSinceNow > 0
            }
            return !alarm.repeatDays.isEmpty
        }

        // Also check if sleep tracking is active
        let isTrackingSleep = MotionSleepMonitor.shared.isMonitoring

        guard hasUpcomingAlarm || isTrackingSleep else {
            return
        }

        // Begin background task for extra safety
        beginBackgroundTask()

        // Ensure audio session is active
        configureAudioSession()

        // Start silent audio loop
        startSilentAudio()

        // Start alarm check timer using GCD (reliable in background)
        startAlarmCheckTimer()

        isBackgroundActive = true
        hasFiredAlarmIds = []
    }

    /// Stops background audio. Call when app comes to foreground.
    func stopBackgroundKeepAlive() {
        stopAlarmCheckTimer()
        silentPlayer?.stop()
        silentPlayer = nil
        isBackgroundActive = false
        hasFiredAlarmIds = []
        endBackgroundTask()
    }

    /// Triggers the alarm sound with vibration. When `gradualSeconds > 0`, the
    /// volume fades in and the vibration ramps up over that window.
    func triggerAlarm(soundName: String = "sunrise", volume: Float = 1.0, vibrationEnabled: Bool = true, gradualSeconds: TimeInterval = 0) {
        // Release the sleep-tracking microphone session so it can't block the
        // alarm from owning the .playback session (recorder vs player conflict).
        MotionSleepMonitor.shared.releaseForAlarm()

        // Push the system volume to max — a .playback alarm uses the media
        // volume, so this is what makes it as loud as the native alarm.
        SystemVolume.setMax()

        // Stop silent audio first
        silentPlayer?.stop()
        silentPlayer = nil

        // Reconfigure for loud playback (not mixing)
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
        }

        // Play the selected alarm sound
        let alarmSound = AlarmSound(rawValue: soundName) ?? .sunrise
        if let alarmURL = AlarmSoundGenerator.alarmSoundURL(for: alarmSound) {
            do {
                alarmPlayer = try AVAudioPlayer(contentsOf: alarmURL)
                alarmPlayer?.numberOfLoops = -1
                alarmPlayer?.prepareToPlay()
                if gradualSeconds > 0 {
                    alarmPlayer?.volume = max(0.4, volume * 0.45)
                    alarmPlayer?.play()
                    alarmPlayer?.setVolume(1.0, fadeDuration: gradualSeconds)
                } else {
                    alarmPlayer?.volume = 1.0
                    alarmPlayer?.play()
                }
            } catch {
                playSystemAlarm()
            }
        } else {
            playSystemAlarm()
        }

        print("[FIRE] BG isPlaying=\(alarmPlayer?.isPlaying ?? false) vol=\(alarmPlayer?.volume ?? -1) grad=\(gradualSeconds) out=\(audioSession.outputVolume) cat=\(audioSession.category.rawValue)")

        // Start vibration
        if vibrationEnabled {
            startVibrationLoop(gradualSeconds: gradualSeconds)
        }
    }

    /// Stops the alarm sound and vibration.
    func stopAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
        systemAlarmTimer?.cancel()
        systemAlarmTimer = nil
        stopVibrationTimer()

        // If still in background mode, restart silent audio for next alarm
        if isBackgroundActive {
            configureAudioSession()
            startSilentAudio()
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            // .playback (solo, no .mixWithOthers): owns the audio session so iOS
            // keeps the app alive in the background. Mixable/ambient audio is
            // treated as secondary and gets suspended, which froze the alarm
            // check timer and stopped the alarm from ever firing in background.
            // Only set the category here; activation happens when we actually
            // start playing (silent keep-alive or the alarm) so opening the app
            // doesn't needlessly grab the session from the user's music.
            try audioSession.setCategory(.playback, mode: .default, options: [])
        } catch {
        }
    }

    // MARK: - Silent Audio

    private func startSilentAudio() {
        silentPlayer?.stop()

        guard let data = silentAudioData else {
            return
        }

        do {
            try audioSession.setActive(true)
            silentPlayer = try AVAudioPlayer(data: data)
            silentPlayer?.numberOfLoops = -1 // Loop forever
            silentPlayer?.volume = 0.02
            silentPlayer?.prepareToPlay()
            silentPlayer?.play()
        } catch {
        }
    }

    private func generateSilentAudioData() -> Data {
        // 1 second of near-silent audio at low sample rate
        let sampleRate: Double = 8000
        let numSamples = Int(sampleRate)
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let sampleRateInt = UInt32(sampleRate)
        let byteRate = sampleRateInt * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)
        let dataSize = UInt32(numSamples * Int(bitsPerSample / 8))
        let fileSize = 36 + dataSize

        var data = Data(capacity: Int(44 + dataSize))

        // WAV header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sampleRateInt.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })

        // A tiny-amplitude low tone (NOT a constant/zero). iOS suspends an app
        // that plays true silence ("playing silence"), so the keep-alive needs
        // real, oscillating audio energy — just far too quiet to hear.
        let amplitude = 24.0   // out of 32767 → inaudible, but real signal
        let frequency = 50.0   // low, sub-perceptible tone
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let value = Int16(amplitude * sin(2.0 * Double.pi * frequency * t))
            data.append(contentsOf: withUnsafeBytes(of: value.littleEndian) { Array($0) })
        }

        return data
    }

    // MARK: - GCD Timer (reliable in background)

    private func startAlarmCheckTimer() {
        stopAlarmCheckTimer()

        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now() + 10, repeating: .seconds(15)) // Check every 15 seconds
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.checkAlarmTimes()
            }
        }
        timer.resume()
        alarmCheckTimer = timer
    }

    private func stopAlarmCheckTimer() {
        alarmCheckTimer?.cancel()
        alarmCheckTimer = nil
    }

    // MARK: - Alarm Check

    private func checkAlarmTimes() {
        // Keep the silent keep-alive playing (restart if it stopped for any
        // reason) so the app stays alive until the alarm fires.
        if isBackgroundActive, alarmPlayer == nil, silentPlayer?.isPlaying != true {
            startSilentAudio()
        }
        print("[HEARTBEAT] bgActive=\(isBackgroundActive) silent=\(silentPlayer?.isPlaying ?? false)")

        let alarms = StorageService.shared.loadAlarms()
        let now = Date()
        let calendar = Calendar.current

        for alarm in alarms where alarm.isEnabled {
            // Fire off the MOST RECENT occurrence of the alarm's hour:minute, not
            // `nextAlarmDate` (which always points to the FUTURE — today before the
            // time, tomorrow right after — so a repeating alarm never lands in the
            // catch-up window). Compute today's occurrence and step back a day if
            // the time hasn't happened yet today.
            let hm = calendar.dateComponents([.hour, .minute], from: alarm.time)
            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.hour = hm.hour
            comps.minute = hm.minute
            comps.second = 0
            guard let todayAtTime = calendar.date(from: comps) else { continue }
            let recent = now >= todayAtTime
                ? todayAtTime
                : (calendar.date(byAdding: .day, value: -1, to: todayAtTime) ?? todayAtTime)

            // Only ring if that occurrence is within the last 90s (catch-up window).
            let sinceFire = now.timeIntervalSince(recent)
            guard sinceFire >= 0, sinceFire <= 90 else { continue }

            // For repeating alarms, the occurrence's weekday must be selected.
            if !alarm.repeatDays.isEmpty {
                let wd = calendar.component(.weekday, from: recent)
                guard let weekday = Weekday(calendarWeekday: wd), alarm.repeatDays.contains(weekday) else { continue }
            }

            // Fire once per occurrence (key includes the occurrence timestamp).
            let fireKey = "\(alarm.id.uuidString)@\(Int(recent.timeIntervalSince1970))"
            guard !hasFiredAlarmIds.contains(fireKey) else { continue }

            // If a smart alarm already rang early in its light-sleep window, don't
            // ring again at the hard deadline.
            let isSmartActive = alarm.isSmartAlarm && MotionSleepMonitor.shared.isMonitoring
            if isSmartActive && MotionSleepMonitor.shared.smartAlarmTriggered { continue }

            hasFiredAlarmIds.insert(fireKey)
            fireAlarm(alarm)
        }
    }

    private func fireAlarm(_ alarm: AlarmModel) {
        hasFiredAlarmIds.insert(alarm.id.uuidString)

        let gradualSeconds: TimeInterval = alarm.gradualWakeEnabled ? TimeInterval(alarm.gradualWakeDuration * 60) : 0
        triggerAlarm(soundName: alarm.sound.rawValue, volume: Float(alarm.volume), vibrationEnabled: alarm.vibrationEnabled, gradualSeconds: gradualSeconds)

        // The app is alive and ringing via audio — drop the fallback burst so we
        // don't get a doubled notification sound on top.
        NotificationService.shared.cancelBurst(alarmId: alarm.id.uuidString)

        // Update NotificationService to show alarm UI
        NotificationService.shared.ringingAlarmId = alarm.id.uuidString
        NotificationService.shared.ringingAlarmTime = alarm.time
        NotificationService.shared.isAlarmRinging = true
    }

    // MARK: - System Alarm Fallback

    private func playSystemAlarm() {
        AudioServicesPlayAlertSound(SystemSoundID(1304))
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        systemAlarmTimer?.cancel()
        let repeatTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        repeatTimer.schedule(deadline: .now() + 2, repeating: .seconds(2))
        repeatTimer.setEventHandler {
            AudioServicesPlayAlertSound(SystemSoundID(1304))
        }
        repeatTimer.resume()
        systemAlarmTimer = repeatTimer
    }

    // MARK: - Vibration

    private func startVibrationLoop(gradualSeconds: TimeInterval = 0) {
        stopVibrationTimer()

        guard gradualSeconds > 0 else {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            let timer = DispatchSource.makeTimerSource(queue: timerQueue)
            timer.schedule(deadline: .now() + 1.5, repeating: .seconds(1))
            timer.setEventHandler {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            timer.resume()
            vibrationTimer = timer
            return
        }

        // Crescent vibration: pulses tighten from ~5s apart to ~1.2s.
        let start = Date()
        var lastFire = Date(timeIntervalSince1970: 0)
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now() + 0.4, repeating: .milliseconds(400))
        timer.setEventHandler {
            let progress = min(Date().timeIntervalSince(start) / gradualSeconds, 1.0)
            let period = 5.0 - 3.8 * progress
            if Date().timeIntervalSince(lastFire) >= period {
                lastFire = Date()
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
        timer.resume()
        vibrationTimer = timer
    }

    private func stopVibrationTimer() {
        vibrationTimer?.cancel()
        vibrationTimer = nil
    }

    // MARK: - Background Task

    private func beginBackgroundTask() {
        endBackgroundTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}
