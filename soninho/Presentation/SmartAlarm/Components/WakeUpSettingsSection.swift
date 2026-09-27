//
//  WakeUpSettingsSection.swift
//  soninho
//
//  Edit-sheet controls for the Pacote Despertar: dismiss mission + difficulty,
//  gradual wake duration, and the anti-relapse confirmation toggle.
//

import SwiftUI
import PaywallKit

// MARK: - Wake Up Settings Section
struct WakeUpSettingsSection: View {
    // MARK: - Bindings
    @Binding var mission: WakeMission
    @Binding var difficulty: MissionDifficulty
    @Binding var gradualWake: Bool
    @Binding var gradualDuration: Int
    @Binding var antiRelapse: Bool

    // MARK: - Dependencies
    @ObservedObject private var store = StoreKitManager.shared

    // MARK: - State
    @State private var showPaywall = false
    @State private var pendingMission: WakeMission?

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
        .fullScreenCover(isPresented: $showPaywall, onDismiss: applyPendingMission) {
            PaywallView(isPresented: $showPaywall)
        }
    }

    // MARK: - Actions
    private func select(_ option: WakeMission) {
        // A mission already saved on the alarm keeps working, so only picking
        // a new premium one is gated.
        guard isLocked(option) else {
            mission = option
            return
        }
        pendingMission = option
        PaywallAnalytics.source = "gate_mission_\(option.rawValue)"
        showPaywall = true
    }

    private func applyPendingMission() {
        defer { pendingMission = nil }
        guard let pendingMission, store.isPremium else { return }
        mission = pendingMission
    }

    private func isLocked(_ option: WakeMission) -> Bool {
        option.isPremium && !store.isPremium && mission != option
    }

    // MARK: - Mission Card
    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(icon: "checklist", title: String(localized: "wake_mission_label"),
                         subtitle: String(localized: "wake_mission_description"))

            GlassContainer(spacing: 8) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(WakeMission.allCases) { option in
                        chip(
                            title: option.displayName,
                            icon: option.icon,
                            selected: mission == option,
                            locked: isLocked(option)
                        ) { select(option) }
                        .accessibilityIdentifier("alarm.mission.\(option.rawValue)")
                    }
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
        .glassSurface()
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
        .glassSurface()
    }

    // MARK: - Anti-Relapse Card
    private var antiRelapseCard: some View {
        Toggle(isOn: $antiRelapse) {
            sectionLabel(icon: "figure.walk.motion", title: String(localized: "wake_antirelapse_label"),
                         subtitle: String(localized: "wake_antirelapse_description"))
        }
        .tint(AppColors.accent)
        .padding()
        .glassSurface()
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

    private func chip(title: String, icon: String, selected: Bool, locked: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(AppFonts.caption())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(selected ? .white : AppColors.textSecondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 64)
            .overlay(alignment: .topTrailing) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                        .padding(6)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassSurface(cornerRadius: 12, tint: selected ? AppColors.accent : nil, interactive: true)
        .accessibilityLabel(locked ? String(localized: "wake_mission_locked \(title)") : title)
    }
}
