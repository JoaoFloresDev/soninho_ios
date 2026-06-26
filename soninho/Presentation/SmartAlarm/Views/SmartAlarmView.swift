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
                .padding(.bottom, AppSpacing.lg)
            }
            .background(AppColors.background)
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
                    .foregroundStyle(AppColors.textSecondary)

                Text(viewModel.nextAlarmText)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Smart Alarm Badge
            if let alarm = viewModel.alarms.first(where: { $0.isEnabled }), alarm.isSmartAlarm {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))

                    Text(String(localized: "alarm_smart_enabled"))
                        .font(AppFonts.caption())
                }
                .foregroundStyle(AppColors.accent)
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
                .foregroundStyle(AppColors.textPrimary)

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

                if alarm.isSmartAlarm {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 10))

                        Text(String(localized: "alarm_smart_window \(alarm.smartAlarmWindow)"))
                            .font(AppFonts.caption2())
                    }
                    .foregroundStyle(AppColors.accent)
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
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "action_delete"), systemImage: "trash")
            }
        }
    }
}