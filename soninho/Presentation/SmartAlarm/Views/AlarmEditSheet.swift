//
//  AlarmEditSheet.swift
//  soninho
//
//  Create / edit an alarm, including the Pacote Despertar wake-up settings.
//

import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Alarm Edit Sheet
struct AlarmEditSheet: View {
    // MARK: - Properties
    @ObservedObject var viewModel: SmartAlarmViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var previewPlayer: AVAudioPlayer?

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackdrop()

                ScrollView {
                    VStack(spacing: 24) {
                        timePicker
                        smartAlarmCard
                        WakeUpSettingsSection(
                            mission: $viewModel.editingMission,
                            difficulty: $viewModel.editingMissionDifficulty,
                            gradualWake: $viewModel.editingGradualWake,
                            gradualDuration: $viewModel.editingGradualDuration,
                            antiRelapse: $viewModel.editingAntiRelapse
                        )
                        SnoozeSettingsSection(
                            snoozeLimit: $viewModel.editingSnoozeLimit,
                            snoozeDuration: $viewModel.editingSnoozeDuration
                        )
                        repeatSection
                        soundSection
                        labelSection

                        if viewModel.selectedAlarm != nil {
                            deleteButton
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
                .softScrollEdge()
            }
            .onDisappear { stopPreview() }
            .navigationTitle(viewModel.selectedAlarm == nil
                ? String(localized: "alarm_add")
                : String(localized: "alarm_edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        dismiss()
                        viewModel.cancelEditing()
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action_save")) {
                        viewModel.saveAlarm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
    }

    // MARK: - Time Picker
    private var timePicker: some View {
        DatePicker(
            "",
            selection: $viewModel.editingTime,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
    }

    // MARK: - Smart Alarm Card
    private var smartAlarmCard: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $viewModel.editingIsSmartAlarm) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "alarm_smart_alarm"))
                            .font(AppFonts.body())
                            .foregroundStyle(AppColors.textPrimary)

                        Text(String(localized: "alarm_smart_description"))
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .tint(AppColors.accent)

            if viewModel.editingIsSmartAlarm {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "alarm_wake_window"))
                        .font(AppFonts.subheadline())
                        .foregroundStyle(AppColors.textSecondary)

                    Picker("", selection: $viewModel.editingSmartWindow) {
                        Text(String(localized: "alarm_window_15")).tag(15)
                        Text(String(localized: "alarm_window_30")).tag(30)
                        Text(String(localized: "alarm_window_45")).tag(45)
                        Text(String(localized: "alarm_window_60")).tag(60)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Repeat Section
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "alarm_repeat"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            GlassContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        let selected = viewModel.editingRepeatDays.contains(day)
                        Button {
                            if selected {
                                viewModel.editingRepeatDays.remove(day)
                            } else {
                                viewModel.editingRepeatDays.insert(day)
                            }
                        } label: {
                            Text(day.letter)
                                .font(AppFonts.caption())
                                .fontWeight(.semibold)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(selected ? .white : AppColors.textSecondary)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .glassCapsule(tint: selected ? AppColors.primary : nil, interactive: true)
                    }
                }
            }
        }
    }

    // MARK: - Sound Section
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "alarm_sound"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            GlassContainer(spacing: 8) {
                VStack(spacing: 8) {
                    ForEach(AlarmSound.allCases) { sound in
                        let selected = viewModel.editingSound == sound
                        Button {
                            viewModel.editingSound = sound
                            playPreview(sound)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: sound.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 32)

                                Text(sound.displayName)
                                    .font(AppFonts.body())
                                    .foregroundStyle(AppColors.textPrimary)

                                Spacer()

                                if selected {
                                    Image(systemName: isPreviewingSelected ? "speaker.wave.2.fill" : "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.primary)
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .glassSurface(cornerRadius: 12, tint: selected ? AppColors.primary.opacity(0.3) : nil, interactive: true)
                    }
                }
            }

            volumeCard
        }
    }

    // MARK: - Volume & Vibration Card
    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "alarm_volume"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textTertiary)

                // Plays the sound the moment the slider moves and tracks the
                // volume live, so the user hears exactly what they're setting.
                Slider(value: $viewModel.editingVolume, in: 0.3...1.0)
                    .tint(AppColors.primary)
                    .onChange(of: viewModel.editingVolume) { _, newValue in
                        if previewPlayer?.isPlaying == true {
                            previewPlayer?.volume = Float(newValue)
                        } else {
                            playPreview(viewModel.editingSound, restart: true)
                        }
                    }

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Toggle(isOn: $viewModel.editingVibration) {
                HStack(spacing: 12) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 28)

                    Text(String(localized: "alarm_vibration"))
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            .tint(AppColors.primary)
            .onChange(of: viewModel.editingVibration) { _, enabled in
                // Buzz so the user feels what they just turned on. Haptic
                // engine first (reliable in foreground), plus the system
                // vibrator — the same one the ringing alarm uses.
                if enabled {
                    HapticManager.heavyImpact()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        HapticManager.heavyImpact()
                    }
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
            }
        }
        .padding()
        .glassSurface(cornerRadius: 12)
    }

    // MARK: - Sound Preview
    private var isPreviewingSelected: Bool {
        previewPlayer?.isPlaying ?? false
    }

    /// Plays a short sample of the tapped sound. Tapping the sound that's
    /// already previewing stops it; `restart: true` always plays from the top
    /// (used when the volume slider is released).
    private func playPreview(_ sound: AlarmSound, restart: Bool = false) {
        if isPreviewingSelected && !restart {
            stopPreview()
            return
        }
        stopPreview()
        guard let url = AlarmSoundGenerator.alarmSoundURL(for: sound) else { return }
        // While a sleep night is being tracked the monitor owns a record
        // session — switching the category would kill its microphone meter.
        if !MotionSleepMonitor.shared.isMonitoring {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        previewPlayer = try? AVAudioPlayer(contentsOf: url)
        previewPlayer?.volume = Float(viewModel.editingVolume)
        previewPlayer?.play()
        // Sample only — stop after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if previewPlayer?.isPlaying == true { stopPreview() }
        }
    }

    private func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        if !MotionSleepMonitor.shared.isMonitoring, !BackgroundAlarmPlayer.shared.isBackgroundActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(role: .destructive) {
            if let alarm = viewModel.selectedAlarm {
                viewModel.deleteAlarm(alarm)
            }
            dismiss()
            viewModel.cancelEditing()
        } label: {
            Text(String(localized: "alarm_delete"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.error)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassSurface(cornerRadius: 12, tint: AppColors.error.opacity(0.25), interactive: true)
    }

    // MARK: - Label Section
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "alarm_label"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            TextField(String(localized: "alarm_label_placeholder"), text: $viewModel.editingLabel)
                .textFieldStyle(.plain)
                .foregroundStyle(AppColors.textPrimary)
                .padding()
                .glassSurface(cornerRadius: 12)
        }
    }
}
