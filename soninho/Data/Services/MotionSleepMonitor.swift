//
//  MotionSleepMonitor.swift
//  soninho
//
//  Created by João Flores on 22/02/26.
//

import Foundation
import CoreMotion
import Combine

// MARK: - Motion Pipeline
/// Owns the extractor on the motion queue. Every raw sample is processed off
/// the main thread; only finished minutes and once-a-second live readings hop
/// to the main actor. (The previous design hopped per sample — 36,000 main
/// thread hops an hour, all night.)
private final class MotionPipeline {
    private var extractor: MovementFeatureExtractor
    private var lastSecondReport = Date.distantPast

    /// Called on the motion queue with (minute, liveActivity, noiseVariance).
    var onMinute: ((MovementFeatures, Double, Double) -> Void)?
    /// Called on the motion queue about once a second with the live activity.
    var onSecond: ((Double) -> Void)?

    init(noiseVariance: Double?) {
        if let noiseVariance {
            extractor = MovementFeatureExtractor(noiseVariance: noiseVariance)
        } else {
            extractor = MovementFeatureExtractor()
        }
    }

    func process(x: Double, y: Double, z: Double) {
        let now = Date()
        if let minute = extractor.add(x: x, y: y, z: z, at: now) {
            onMinute?(minute, extractor.liveActivity, extractor.noiseVariance)
        }
        if now.timeIntervalSince(lastSecondReport) >= 1 {
            lastSecondReport = now
            onSecond?(extractor.liveActivity)
        }
    }

    func flush() -> MovementFeatures? {
        extractor.flush(at: Date())
    }
}

// MARK: - Motion Sleep Monitor
/// Runs the night: accelerometer → features → staging engine → smart alarm.
/// The phone lies on the mattress; the microphone both keeps the process
/// alive overnight and tells snoring from disturbance.
///
/// Everything that matters survives a relaunch: the engine, the smart-wake
/// decider and the noise calibration persist once a minute, minutes the
/// process was dead come back as explicit gaps, and the system's own sensor
/// recorder (which outlives the app) refills those gaps with real data.
@MainActor
final class MotionSleepMonitor: ObservableObject {
    // MARK: - Singleton
    static let shared = MotionSleepMonitor()

    // MARK: - Constants
    private enum Constants {
        static let sampleRate: Double = 50
        /// No epoch for this long while monitoring = the pipeline stalled.
        static let watchdogStallSeconds: TimeInterval = 180
        static let watchdogInterval: TimeInterval = 60
        /// A persisted session older than this is a different night.
        static let sessionResumeLimit: TimeInterval = 12 * 3600
    }

    // MARK: - Published Properties
    @Published private(set) var currentPhase: SleepPhase = .light
    @Published private(set) var isMonitoring = false
    @Published private(set) var movementIntensity: Double = 0
    @Published private(set) var soundLevel: Double = 0
    @Published private(set) var smartAlarmTriggered = false
    /// Whether the microphone keep-alive is actually running. False overnight
    /// means iOS may suspend the app; the keep-alive player must cover for it.
    @Published private(set) var isAudioKeepAliveActive = false
    /// The user declined the microphone — tracking can silently die overnight.
    @Published private(set) var microphoneDenied = false
    /// A session the smart alarm started by itself (no user-tracked night):
    /// it exists only to find the light-sleep wake moment and saves no sleep
    /// record; it ends when the alarm is dismissed.
    private(set) var isAlarmOnlySession = false

    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    private let soundMonitor = SleepSoundMonitor()

    private var pipeline: MotionPipeline?
    private var engine: SleepStagingEngine?
    private var decider: SmartWakeDecider?
    private var noiseVariance: Double?
    private var lastEpochAt: Date?
    private var releasedForAlarm = false

    private var watchdogTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.gambitstudio.soninho.motionTimer", qos: .utility)

    // MARK: - Init
    private init() {
        motionQueue.name = "com.gambitstudio.soninho.motion"
        motionQueue.maxConcurrentOperationCount = 1

        // An alarm-only session has no ViewModel watching over it — it ends
        // itself when the alarm is fully dismissed.
        NotificationCenter.default.addObserver(
            forName: .didCompleteAlarm, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isAlarmOnlySession else { return }
                self.stopMonitoring()
            }
        }
    }

    // MARK: - Public Methods

    /// Starts (or resumes) the user's tracked night. A persisted session from
    /// a relaunch is restored with its gap recorded and backfilled; a fresh
    /// night starts a new engine anchored at the tracked start time.
    func startMonitoring() {
        // The smart alarm may already be running an alarm-only session; the
        // user starting a real night ADOPTS it — the staging context is worth
        // more than a fresh engine.
        if isMonitoring, isAlarmOnlySession {
            isAlarmOnlySession = false
            startAudio(promptIfNeeded: true)
            persist()
            return
        }
        start(alarmOnly: false)
    }

    /// Starts monitoring for the smart alarm alone — no user-tracked night,
    /// no sleep record. Never prompts for the microphone (it fires while the
    /// user sleeps); audio joins only if permission already exists.
    func startAlarmOnlyMonitoring() {
        guard !isMonitoring else { return }
        Analytics.featureUsed("smart_wake_autoarm", source: "keepalive")
        start(alarmOnly: true)
    }

    private func start(alarmOnly: Bool) {
        guard !isMonitoring else { return }
        guard motionManager.isAccelerometerAvailable else { return }

        isMonitoring = true
        isAlarmOnlySession = alarmOnly
        releasedForAlarm = false
        currentPhase = .light
        movementIntensity = 0
        soundLevel = 0

        restoreOrStartSession()
        armSmartAlarm()
        startAccelerometer()
        startAudio(promptIfNeeded: !alarmOnly)
        startWatchdog()
        persist()

        // The system recorder keeps logging even if this process dies — the
        // backstop that lets a relaunch refill the dead minutes with data.
        SleepSessionStore.startSystemRecorder()
    }

    /// Stops the night for good and discards the persisted session.
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        watchdogTimer?.cancel()
        watchdogTimer = nil
        soundMonitor.stop()
        pipeline = nil
        isAudioKeepAliveActive = false
        isMonitoring = false
        isAlarmOnlySession = false
        engine = nil
        decider = nil
        noiseVariance = nil
        lastEpochAt = nil
        SleepSessionStore.clear()
    }

    /// Releases the sensors the alarm and its missions need: the microphone
    /// (so the alarm can own the audio session) and the accelerometer (the
    /// shake mission runs its own CMMotionManager). Sleep is over at that
    /// point; the staged night is flushed and persisted first.
    func releaseForAlarm() {
        guard !releasedForAlarm else { return }
        releasedForAlarm = true

        if let final = pipeline?.flush(), final.hasEnoughData {
            recordMinute(final, liveActivity: 0, noiseVariance: noiseVariance)
        }

        motionManager.stopAccelerometerUpdates()
        watchdogTimer?.cancel()
        watchdogTimer = nil
        soundMonitor.stop()
        isAudioKeepAliveActive = false
        persist()
    }

    /// The night's stages, merged into contiguous spans.
    func getRecordedPhases() -> [SleepPhaseData] {
        let now = Date()
        guard let engine, !engine.epochs.isEmpty else {
            let start = engine?.sessionStart
                ?? UserDefaults.standard.object(forKey: StorageKeys.trackingStartTime) as? Date
                ?? now
            return [SleepPhaseData(phase: .light, startTime: start, endTime: now)]
        }
        return engine.phaseSpans(now: now)
    }

    func calculateQualityScore(phases: [SleepPhaseData], totalDuration: TimeInterval) -> Int {
        SleepQualityScorer.score(phases: phases, totalDuration: totalDuration)
    }

    // MARK: - Session Lifecycle

    private func restoreOrStartSession() {
        let trackedStart = UserDefaults.standard.object(forKey: StorageKeys.trackingStartTime) as? Date

        // A tracked night must match the tracked start time; an alarm-only
        // session has none, so recency is the whole test.
        let matchesSession: (SleepSessionState) -> Bool = { state in
            if state.isAlarmOnly { return true }
            guard let trackedStart else { return false }
            return abs(state.engine.sessionStart.timeIntervalSince(trackedStart)) < 120
        }

        if let state = SleepSessionStore.load(),
           Date().timeIntervalSince(state.engine.sessionStart) < Constants.sessionResumeLimit,
           matchesSession(state) {
            // Same night, back from a relaunch: the dead minutes become a gap,
            // then the system recorder refills them with what really happened.
            var restored = state.engine
            let deadFrom = state.lastAliveAt
            let now = Date()
            if now.timeIntervalSince(deadFrom) > 120 {
                restored.recordGap(from: deadFrom, to: now)
                Analytics.featureUsed("sleep_monitor_gap", source: "restore")
                backfillGap(from: deadFrom, to: now, noiseVariance: state.noiseVariance)
            }
            engine = restored
            decider = state.decider
            noiseVariance = state.noiseVariance
            smartAlarmTriggered = state.smartAlarmTriggered
            currentPhase = restored.currentPhase
            if state.isAlarmOnly, !isAlarmOnlySession {
                // A user-tracked start adopts the restored alarm-only night.
                isAlarmOnlySession = false
            }
        } else {
            engine = SleepStagingEngine(
                sessionStart: isAlarmOnlySession ? Date() : (trackedStart ?? Date())
            )
            decider = nil
            noiseVariance = nil
            smartAlarmTriggered = false
        }
        lastEpochAt = Date()
    }

    private func backfillGap(from start: Date, to end: Date, noiseVariance: Double) {
        SleepSessionStore.recoverGap(from: start, to: end, noiseVariance: noiseVariance) { [weak self] minutes in
            guard let self, !minutes.isEmpty else { return }
            self.engine?.fillGaps(with: minutes)
            self.persist()
            Analytics.featureUsed("sleep_gap_recovered", source: "sensor_recorder")
        }
    }

    private func persist() {
        guard let engine else { return }
        SleepSessionStore.save(SleepSessionState(
            engine: engine,
            decider: decider,
            noiseVariance: noiseVariance ?? MovementFeatureExtractor.Tuning.initialNoiseVariance,
            smartAlarmTriggered: smartAlarmTriggered,
            lastAliveAt: Date(),
            isAlarmOnly: isAlarmOnlySession
        ))
    }

    // MARK: - Sensors

    private func startAccelerometer() {
        let pipeline = MotionPipeline(noiseVariance: noiseVariance)
        pipeline.onMinute = { [weak self] minute, live, noise in
            Task { @MainActor in
                self?.recordMinute(minute, liveActivity: live, noiseVariance: noise)
            }
        }
        pipeline.onSecond = { [weak self] live in
            Task { @MainActor in
                self?.movementIntensity = live
            }
        }
        self.pipeline = pipeline

        motionManager.accelerometerUpdateInterval = 1 / Constants.sampleRate
        motionManager.startAccelerometerUpdates(to: motionQueue) { data, _ in
            guard let data else { return }
            pipeline.process(
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z
            )
        }
    }

    private func startAudio(promptIfNeeded: Bool = true) {
        soundMonitor.onLevel = { [weak self] level in
            self?.soundLevel = level
        }
        soundMonitor.start(promptIfNeeded: promptIfNeeded) { [weak self] granted in
            guard let self else { return }
            self.microphoneDenied = !granted
            self.isAudioKeepAliveActive = self.soundMonitor.isRunning
            if promptIfNeeded {
                Analytics.permissionResult("microphone", granted: granted)
            }
        }
    }

    /// If no epoch lands for a few minutes while we believe we are monitoring,
    /// the pipeline stalled (session interruption, sensor hiccup). Record the
    /// hole honestly and restart the sensors — silence must never look like a
    /// night of stillness.
    private func startWatchdog() {
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(
            deadline: .now() + Constants.watchdogInterval,
            repeating: Constants.watchdogInterval
        )
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.watchdogTick()
            }
        }
        timer.resume()
        watchdogTimer = timer
    }

    private func watchdogTick() {
        guard isMonitoring else { return }

        // An alarm-only session whose window is long gone was orphaned (the
        // alarm never completed through the app) — release the sensors.
        if isAlarmOnlySession {
            let horizon = (decider?.windowEnd ?? (engine?.sessionStart ?? Date()).addingTimeInterval(12 * 3600))
                .addingTimeInterval(2 * 3600)
            if Date() > horizon {
                stopMonitoring()
                return
            }
        }

        guard !releasedForAlarm else { return }

        // Keep the persisted heartbeat fresh even between epochs, so a
        // relaunch measures the gap from when the process actually died.
        persist()

        if let last = lastEpochAt, Date().timeIntervalSince(last) > Constants.watchdogStallSeconds {
            engine?.recordGap(from: last.addingTimeInterval(60), to: Date())
            lastEpochAt = Date()
            Analytics.featureUsed("sleep_monitor_gap", source: "watchdog")

            motionManager.stopAccelerometerUpdates()
            startAccelerometer()
        }

        if !soundMonitor.isRunning, !microphoneDenied {
            // The audio session dropped (interruption, route change). Restart —
            // it is both the keep-alive and the snore channel. Never prompt
            // from an alarm-only session: its user is asleep.
            startAudio(promptIfNeeded: !isAlarmOnlySession)
        }
        isAudioKeepAliveActive = soundMonitor.isRunning
    }

    // MARK: - Staging

    private func recordMinute(_ minute: MovementFeatures, liveActivity: Double, noiseVariance: Double?) {
        guard isMonitoring else { return }

        self.noiseVariance = noiseVariance
        lastEpochAt = Date()

        let sound = soundMonitor.snapshotMinute()
        let settled = engine?.record(minute, sound: sound) ?? .light
        if settled != currentPhase {
            currentPhase = settled
        }

        // No smart check once the alarm rang: the ringing phone's own sound
        // and vibration read as movement and would re-trigger the wake.
        if !releasedForAlarm {
            checkSmartAlarm(liveActivity: liveActivity)
        }
        persist()
    }

    // MARK: - Smart Alarm

    /// Resolves the wake window from storage. Runs at start AND every minute,
    /// so an alarm created or edited after the night began still gets its
    /// window — before, only the alarm present at tracking start counted.
    private func armSmartAlarm() {
        guard !smartAlarmTriggered else { return }

        let alarms = StorageService.shared.loadAlarms()
        guard let alarm = alarms.first(where: { $0.isEnabled && $0.isSmartAlarm }),
              let occurrence = AlarmOccurrenceLedger.scheduledDate(for: alarm)?.date else {
            decider = nil
            return
        }

        let windowStart = occurrence.addingTimeInterval(-Double(alarm.smartAlarmWindow * 60))

        // Keep the current decider only if it still describes this window —
        // its confirmation count and fired state are per-window.
        if let decider,
           decider.alarmId == alarm.id.uuidString,
           abs(decider.windowEnd.timeIntervalSince(occurrence)) < 60 {
            return
        }
        decider = SmartWakeDecider(
            windowStart: windowStart,
            windowEnd: occurrence,
            alarmId: alarm.id.uuidString
        )
    }

    private func checkSmartAlarm(liveActivity: Double) {
        armSmartAlarm()

        guard var decider, !decider.hasFired, let engine else { return }

        let score = engine.wakeReadiness(liveActivity: liveActivity)
        let fired = decider.evaluate(score: score, calibrated: engine.isCalibrated, at: Date())
        self.decider = decider

        guard fired else { return }
        triggerSmartWake(alarmId: decider.alarmId, occurrence: decider.windowEnd)
    }

    /// Rings the early wake. On iOS 26 the pending fixed-time system alarm is
    /// replaced by one a few seconds out, so the REAL alarm rings on the lock
    /// screen; elsewhere the in-app audio rings and a notification gives the
    /// locked phone a face. Either way the fixed-time occurrence is marked
    /// handled so no path rings it a second time.
    private func triggerSmartWake(alarmId: String, occurrence: Date) {
        smartAlarmTriggered = true
        persist()

        guard let uuid = UUID(uuidString: alarmId),
              let alarm = StorageService.shared.loadAlarms().first(where: { $0.id == uuid }) else { return }

        AlarmOccurrenceLedger.markHandled(alarmId: alarmId, occurrence: occurrence)
        NotificationService.shared.suppressFixedOccurrence(for: alarm)
        Analytics.featureUsed("smart_wake_early", source: "motion")

        Task { @MainActor in
            if await SystemAlarmScheduler.fireNow(alarm, originalOccurrence: occurrence) {
                // The system alert will ring and hand control back through the
                // stop intent — the app then resumes into the mission flow.
                return
            }
            NotificationService.shared.postSmartWakeNotification(for: alarm)
            NotificationService.shared.handleForegroundAlarm(
                alarmId: alarm.id.uuidString,
                soundName: alarm.sound.rawValue,
                volume: Float(alarm.volume),
                vibration: alarm.vibrationEnabled
            )
        }
    }
}
