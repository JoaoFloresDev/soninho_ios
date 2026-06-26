//
//  WakeUpSettingsSection.swift
//  soninho
//
//  Edit-sheet controls for the Pacote Despertar: dismiss mission + difficulty,
//  gradual wake duration, and the anti-relapse confirmation toggle.
//

import SwiftUI

// MARK: - Wake Up Settings Section
struct WakeUpSettingsSection: View {
    // MARK: - Bindings
    @Binding var mission: WakeMission
    @Binding var difficulty: MissionDifficulty
    @Binding var gradualWake: Bool
    @Binding var gradualDuration: Int
    @Binding var antiRelapse: Bool

    // MARK: - Constants
    private let durations = [1, 2, 3, 5]

    // MARK: - View Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "wake_section_title"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            missionCard
            gradualCard
            antiRelapseCard
        }
    }

    // MARK: - Mission Card
    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(icon: "checklist", title: String(localized: "wake_mission_label"),
                         subtitle: String(localized: "wake_mission_description"))

            HStack(spacing: 8) {
                ForEach(WakeMission.allCases) { option in
                    chip(
                        title: option.displayName,
                        icon: option.icon,
                        selected: mission == option
                    ) { mission = option }
                }
            }

            if mission.requiresMission {
                Text(String(localized: "wake_difficulty_label"))
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)

                Picker("", selection: $difficulty) {
                    ForEach(MissionDifficulty.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
    }

    // MARK: - Gradual Card
    private var gradualCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $gradualWake) {
                sectionLabel(icon: "sunrise.fill", title: String(localized: "wake_gradual_label"),
                             subtitle: String(localized: "wake_gradual_description"))
            }
            .tint(AppColors.accent)

            if gradualWake {
                Picker("", selection: $gradualDuration) {
                    ForEach(durations, id: \.self) { minutes in
                        Text(String(localized: "wake_gradual_minutes \(minutes)")).tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
    }

    // MARK: - Anti-Relapse Card
    private var antiRelapseCard: some View {
        Toggle(isOn: $antiRelapse) {
            sectionLabel(icon: "figure.walk.motion", title: String(localized: "wake_antirelapse_label"),
                         subtitle: String(localized: "wake_antirelapse_description"))
        }
        .tint(AppColors.accent)
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
    }

    // MARK: - Subviews
    private func sectionLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func chip(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(AppFonts.caption())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(selected ? .white : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(selected ? AppColors.accent : AppColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
