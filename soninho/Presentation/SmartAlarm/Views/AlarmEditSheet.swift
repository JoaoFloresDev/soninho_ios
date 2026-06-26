//
//  AlarmEditSheet.swift
//  soninho
//
//  Create / edit an alarm, including the Pacote Despertar wake-up settings.
//

import SwiftUI

// MARK: - Alarm Edit Sheet
struct AlarmEditSheet: View {
    // MARK: - Properties
    @ObservedObject var viewModel: SmartAlarmViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - View Body
    var body: some View {
        NavigationStack {
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
                    repeatSection
                    soundSection
                    labelSection
                }
                .padding()
                .padding(.bottom, 50)
            }
            .background(AppColors.background)
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

            HStack(spacing: 8) {
                ForEach(Weekday.allCases) { day in
                    Button {
                        if viewModel.editingRepeatDays.contains(day) {
                            viewModel.editingRepeatDays.remove(day)
                        } else {
                            viewModel.editingRepeatDays.insert(day)
                        }
                    } label: {
                        Text(day.letter)
                            .font(AppFonts.caption())
                            .fontWeight(.semibold)
                            .frame(width: 36, height: 36)
                            .foregroundStyle(
                                viewModel.editingRepeatDays.contains(day)
                                    ? .white
                                    : AppColors.textSecondary
                            )
                            .background(
                                viewModel.editingRepeatDays.contains(day)
                                    ? AppColors.primary
                                    : AppColors.surfaceSecondary
                            )
                            .clipShape(Circle())
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

            ForEach(AlarmSound.allCases) { sound in
                Button {
                    viewModel.editingSound = sound
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

                        if viewModel.editingSound == sound {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    .padding()
                    .background(
                        viewModel.editingSound == sound
                            ? AppColors.primary.opacity(0.1)
                            : AppColors.surface
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Label Section
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "alarm_label"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            TextField(String(localized: "alarm_label_placeholder"), text: $viewModel.editingLabel)
                .textFieldStyle(.plain)
                .padding()
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
