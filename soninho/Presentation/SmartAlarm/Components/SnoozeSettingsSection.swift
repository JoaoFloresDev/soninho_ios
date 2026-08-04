//
//  SnoozeSettingsSection.swift
//  soninho
//
//  Edit-sheet controls for snooze behavior: how many snoozes are allowed per
//  ring (off / 1 / 3 / unlimited) and how long each snooze lasts.
//

import SwiftUI

// MARK: - Snooze Settings Section
struct SnoozeSettingsSection: View {
    // MARK: - Bindings
    @Binding var snoozeLimit: Int
    @Binding var snoozeDuration: Int

    // MARK: - Constants
    private let durations = [5, 9, 10, 15]
    private let limits = [0, 1, 3, AlarmModel.unlimitedSnoozes]

    // MARK: - View Body
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "alarm_snooze_section"))
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textPrimary)
                    Text(String(localized: "alarm_snooze_section_description"))
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // How many snoozes are allowed
            Picker("", selection: $snoozeLimit) {
                ForEach(limits, id: \.self) { limit in
                    Text(limitLabel(limit)).tag(limit)
                }
            }
            .pickerStyle(.segmented)

            // Snooze length
            if snoozeLimit > 0 {
                Text(String(localized: "alarm_snooze_duration"))
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)

                Picker("", selection: $snoozeDuration) {
                    ForEach(durations, id: \.self) { minutes in
                        Text(String(localized: "alarm_snooze_min_option \(minutes)")).tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
        .animation(.easeInOut(duration: 0.2), value: snoozeLimit)
    }

    // MARK: - Private Methods
    private func limitLabel(_ limit: Int) -> String {
        switch limit {
        case 0: return String(localized: "alarm_snooze_off")
        case AlarmModel.unlimitedSnoozes: return "∞"
        default: return "\(limit)×"
        }
    }
}
