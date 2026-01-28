//
//  SmartAlarmView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Smart Alarm View
struct SmartAlarmView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SmartAlarmViewModel()

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Next Alarm Card
                    nextAlarmCard

                    // Alarms List
                    alarmsSection
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "alarm_title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startAddingNew()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AlarmEditSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isEditing) {
                AlarmEditSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.requestNotificationPermission()
            }
        }
    }

    // MARK: - Next Alarm Card
    private var nextAlarmCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "alarm.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.sleepGradient)
            }

            // Next Alarm Info
            VStack(spacing: 4) {
                Text(String(localized: "alarm_next"))
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)

                Text(viewModel.nextAlarmText)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)
            }

            // Smart Alarm Badge
            if let alarm = viewModel.alarms.first(where: { $0.isEnabled }), alarm.isSmartAlarm {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))

                    Text(String(localized: "alarm_smart_enabled"))
                        .font(AppFonts.caption())
                }
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.accent.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
    }

    // MARK: - Alarms Section
    private var alarmsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "alarm_your_alarms"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.alarms) { alarm in
                AlarmCard(
                    alarm: alarm,
                    onToggle: { viewModel.toggleAlarm(alarm) },
                    onTap: { viewModel.startEditing(alarm) },
                    onDelete: { viewModel.deleteAlarm(alarm) }
                )
            }
        }
    }
}

// MARK: - Alarm Card
struct AlarmCard: View {
    let alarm: AlarmModel
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.timeString)
                        .font(AppFonts.title())
                        .foregroundColor(alarm.isEnabled ? AppColors.textPrimary : AppColors.textTertiary)

                    HStack(spacing: 8) {
                        if let label = alarm.label {
                            Text(label)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Text(alarm.repeatDaysString)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textTertiary)
                    }

                    if alarm.isSmartAlarm {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 10))

                            Text(String(localized: "alarm_smart_window \(alarm.smartAlarmWindow)"))
                                .font(AppFonts.caption2())
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(AppColors.primary)
            }
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "action_delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Alarm Edit Sheet
struct AlarmEditSheet: View {
    @ObservedObject var viewModel: SmartAlarmViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Picker
                    DatePicker(
                        "",
                        selection: $viewModel.editingTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                    // Smart Alarm Toggle
                    VStack(spacing: 16) {
                        Toggle(isOn: $viewModel.editingIsSmartAlarm) {
                            HStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.accent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "alarm_smart_alarm"))
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.textPrimary)

                                    Text(String(localized: "alarm_smart_description"))
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .tint(AppColors.accent)

                        if viewModel.editingIsSmartAlarm {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "alarm_wake_window"))
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.textSecondary)

                                Picker("", selection: $viewModel.editingSmartWindow) {
                                    Text("15 min").tag(15)
                                    Text("30 min").tag(30)
                                    Text("45 min").tag(45)
                                    Text("60 min").tag(60)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .cardStyle()

                    // Repeat Days
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "alarm_repeat"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)

                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                Button {
                                    HapticManager.selection()
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
                                        .foregroundColor(
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

                    // Sound Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "alarm_sound"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)

                        ForEach(AlarmSound.allCases) { sound in
                            Button {
                                HapticManager.selection()
                                viewModel.editingSound = sound
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: sound.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 32)

                                    Text(sound.displayName)
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.textPrimary)

                                    Spacer()

                                    if viewModel.editingSound == sound {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppColors.primary)
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

                    // Label
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "alarm_label"))
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)

                        TextField(String(localized: "alarm_label_placeholder"), text: $viewModel.editingLabel)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle(viewModel.selectedAlarm == nil
                ? String(localized: "alarm_add")
                : String(localized: "alarm_edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "action_cancel")) {
                        viewModel.cancelEditing()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action_save")) {
                        viewModel.saveAlarm()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SmartAlarmView()
}
