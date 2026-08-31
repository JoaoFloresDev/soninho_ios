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
            ZStack {
                GlassBackdrop()

                ScrollView {
                    VStack(spacing: 24) {
                        // Next Alarm Card
                        nextAlarmCard

                        // Alarms List
                        alarmsSection
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.lg)
                }
                .softScrollEdge()
            }
            .onAppear { Analytics.screen("alarm") }
            .navigationTitle(String(localized: "alarm_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startAddingNew()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                    }
                    .accessibilityIdentifier("alarm.add")
                    .accessibilityLabel(Text(String(localized: "alarm_add")))
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AlarmEditSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isEditing) {
                AlarmEditSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Next Alarm Card
    private var nextAlarmCard: some View {
        VStack(spacing: 12) {
            // Mascot hugging its alarm clock (carries its own baked halo glow)
            Image("heroAlarm")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            // Next Alarm Info
            VStack(spacing: 4) {
                Text(String(localized: "alarm_next"))
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)

                Text(viewModel.nextAlarmText)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Smart Alarm Badge
            if let alarm = viewModel.nextEnabledAlarm, alarm.isSmartAlarm {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))

                    Text(String(localized: "alarm_smart_enabled"))
                        .font(AppFonts.caption())
                }
                .foregroundStyle(AppColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCapsule(tint: AppColors.accent.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassSurface(cornerRadius: 20, tint: AppColors.primary.opacity(0.12))
    }

    // MARK: - Alarms Section
    private var alarmsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "alarm_your_alarms"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            GlassContainer(spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(viewModel.alarms) { alarm in
                        AlarmCard(
                            alarm: alarm,
                            onToggle: { viewModel.toggleAlarm(alarm) },
                            onTap: { viewModel.startEditing(alarm) },
                            onDuplicate: { viewModel.duplicateAlarm(alarm) },
                            onDelete: { viewModel.deleteAlarm(alarm) }
                        )
                    }
                }
            }
            // Switching an alarm on can raise the notification prompt; keep the
            // list inert until the system call comes back.
            .disabled(viewModel.isRequestingNotificationPermission)
        }
    }
}

// MARK: - Alarm Card
struct AlarmCard: View {
    let alarm: AlarmModel
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Time and Info
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(AppFonts.title())
                    .foregroundStyle(alarm.isEnabled ? AppColors.textPrimary : AppColors.textTertiary)

                HStack(spacing: 8) {
                    if let label = alarm.label {
                        Text(label)
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(alarm.repeatDaysString)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textTertiary)
                }

                HStack(spacing: 10) {
                    if alarm.isSmartAlarm {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 10))

                            Text(String(localized: "alarm_smart_window \(alarm.smartAlarmWindow)"))
                                .font(AppFonts.caption2())
                        }
                        .foregroundStyle(AppColors.accent)
                    }

                    if alarm.mission.requiresMission {
                        HStack(spacing: 4) {
                            Image(systemName: alarm.mission.icon)
                                .font(.system(size: 10))

                            Text(alarm.mission.displayName)
                                .font(AppFonts.caption2())
                        }
                        .foregroundStyle(AppColors.primary)
                    }
                }
            }

            Spacer()

            // Toggle (separate interactive area)
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(AppColors.primary)
            .accessibilityIdentifier("alarm.toggle.\(alarm.id.uuidString)")
            .accessibilityLabel(Text(alarm.timeString))
        }
        .padding()
        .contentShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .onTapGesture {
            onTap()
        }
        .glassSurface(cornerRadius: AppSpacing.cardCornerRadius, interactive: true)
        .contextMenu {
            Button {
                onDuplicate()
            } label: {
                Label(String(localized: "action_duplicate"), systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "action_delete"), systemImage: "trash")
            }
        }
    }
}
