import SwiftUI
import GambitScreenshotKit

// MARK: - Feature 2 Screen (Slot 3 — Smart Alarm: the killer differentiator)
//
// Faithful recreation of soninho's SmartAlarmView. Mirrors the real app:
//   - Custom header with title + add button
//   - Hero "Next alarm" card: brain icon, big countdown time, smart badge
//   - Wake-up window card with sleep-cycle wave + trigger dot at lightest
//     moment + window range labels
//   - Weekday repeat selector (S M T W T F S chips, sleepGradient fill)
//   - Your-alarms list with 2 AlarmCard-style rows (time, label, days,
//     smart window indicator, toggle)
//
// Sized for iPhone 6.5" canvas (414×896pt). NO ScrollView.

struct Feature2Screen: View {
    let locale: String

    // MARK: - Sample Data
    private var alarm: MockAlarmConfig { MockAlarm.demo }

    // MARK: - View Body
    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                customHeader

                VStack(spacing: 14) {
                    nextAlarmCard
                    windowCard
                    weekdayRow
                    alarmsList
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Header
    private var customHeader: some View {
        HStack {
            Text(LocalizedLabels.smartAlarmTitle[locale] ?? "Smart Alarm")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            Spacer()

            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MockTheme.primary)
                .frame(width: 36, height: 36)
                .background(MockTheme.primary.opacity(0.15))
                .clipShape(Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Next Alarm Card (hero)
    //
    // Mirrors the real `nextAlarmCard` in SmartAlarmView but built around
    // a big 06:30 time so the screenshot reads immediately.
    private var nextAlarmCard: some View {
        HStack(spacing: 18) {
            // Brain/alarm icon in a soft circle
            ZStack {
                Circle()
                    .fill(MockTheme.primary.opacity(0.15))
                    .frame(width: 76, height: 76)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(MockTheme.sleepGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedLabels.smartAlarmNext[locale] ?? "NEXT ALARM")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(MockTheme.textSecondary)
                    .tracking(1.2)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(alarm.scheduledTime)
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(MockTheme.textPrimary)
                    Text(alarm.scheduledTimeLabel)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(MockTheme.textSecondary)
                }

                Text(LocalizedLabels.smartAlarmInHours[locale] ?? "in 7h 42m")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MockTheme.textTertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) {
            // Smart-alarm badge ("Wakes you during light sleep")
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                Text(LocalizedLabels.smartAlarmEnabled[locale] ?? "Smart")
                    .font(.system(size: 10, weight: .heavy))
            }
            .foregroundStyle(MockTheme.accentSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(MockTheme.accent.opacity(0.20)))
            .padding(.top, 14)
            .padding(.trailing, 16)
        }
    }

    // MARK: - Wake-up Window Card
    private var windowCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedLabels.smartAlarmWindow[locale] ?? "Wake-up window")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(MockTheme.textPrimary)
                    Text(LocalizedLabels.smartAlarmLightestMoment[locale] ?? "at your lightest moment")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MockTheme.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(alarm.windowMinutes)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    Text(LocalizedLabels.smartAlarmMinutes[locale] ?? "min")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(MockTheme.accentSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(MockTheme.accent.opacity(0.18)))
            }

            sleepCycleWave
                .frame(height: 100)

            windowMarkers
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var sleepCycleWave: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                // Highlighted "wake-up window" segment (last 22%)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MockTheme.accent.opacity(0.30), MockTheme.accent.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.22, height: h)
                    .offset(x: w * 0.78, y: 0)

                // Cycle wave fill (subtle area under the curve)
                cycleAreaPath(width: w, height: h)
                    .fill(
                        LinearGradient(
                            colors: [MockTheme.primary.opacity(0.22), MockTheme.primary.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Cycle wave stroke (deep → light → REM)
                cyclePath(width: w, height: h)
                    .stroke(
                        LinearGradient(
                            colors: [MockTheme.deepSleep, MockTheme.lightSleep, MockTheme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                    )

                // Trigger dot at the lightest point inside the window
                ZStack {
                    Circle()
                        .fill(MockTheme.accent.opacity(0.30))
                        .frame(width: 26, height: 26)
                    Circle()
                        .fill(MockTheme.accent)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
                .position(x: w * 0.88, y: h * 0.22)
            }
        }
    }

    private func cyclePath(width: CGFloat, height: CGFloat) -> Path {
        Path { p in
            let steps = 80
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = t * width
                // Three cycles, rising envelope toward wake (shallower sleep)
                let phase = sin(t * .pi * 6.0 - .pi / 2)
                let envelope: CGFloat = 0.35 + 0.45 * (1 - t * 0.7)
                let y = height * (0.55 + envelope * phase * 0.42)
                if i == 0 {
                    p.move(to: CGPoint(x: x, y: y))
                } else {
                    p.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }

    private func cycleAreaPath(width: CGFloat, height: CGFloat) -> Path {
        Path { p in
            let steps = 80
            p.move(to: CGPoint(x: 0, y: height))
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = t * width
                let phase = sin(t * .pi * 6.0 - .pi / 2)
                let envelope: CGFloat = 0.35 + 0.45 * (1 - t * 0.7)
                let y = height * (0.55 + envelope * phase * 0.42)
                if i == 0 {
                    p.addLine(to: CGPoint(x: x, y: y))
                } else {
                    p.addLine(to: CGPoint(x: x, y: y))
                }
            }
            p.addLine(to: CGPoint(x: width, y: height))
            p.closeSubpath()
        }
    }

    private var windowMarkers: some View {
        HStack {
            Text(startLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MockTheme.textTertiary)
            Spacer()
            HStack(spacing: 5) {
                Circle().fill(MockTheme.accent).frame(width: 7, height: 7)
                Text(LocalizedLabels.smartAlarmWakeBetween[locale] ?? "Wakes between")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MockTheme.accentSecondary)
            }
            Spacer()
            Text(endLabel)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MockTheme.accentSecondary)
        }
    }

    private var startLabel: String {
        switch locale {
        case "en-US": return "6:00 AM"
        default: return "06:00"
        }
    }
    private var endLabel: String {
        switch locale {
        case "en-US": return "6:30 AM"
        default: return "06:30"
        }
    }

    // MARK: - Weekday Selector
    private var weekdayRow: some View {
        HStack(spacing: 0) {
            let letters = LocalizedLabels.smartAlarmWeekdaysShort[locale] ?? ["M","T","W","T","F","S","S"]
            ForEach(0..<7, id: \.self) { i in
                let selected = alarm.weekdaysSelected.contains(i + 1)
                Text(letters[i])
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(selected ? .white : MockTheme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(
                            selected
                                ? AnyShapeStyle(MockTheme.sleepGradient)
                                : AnyShapeStyle(MockTheme.surfaceSecondary)
                        )
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Alarms List
    //
    // Mirrors AlarmCard from the real SmartAlarmView: time on the left,
    // label + days underneath, smart-window pill, and an iOS-style toggle.
    private var alarmsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedLabels.smartAlarmYourAlarms[locale] ?? "Your alarms")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)
                .padding(.leading, 4)

            alarmRow(
                time: alarm.scheduledTime,
                label: LocalizedLabels.smartAlarmLabelWork[locale] ?? "Workdays",
                days: LocalizedLabels.smartAlarmWeekdays[locale] ?? "Weekdays",
                window: alarm.windowMinutes,
                enabled: true
            )
            alarmRow(
                time: "07:15",
                label: LocalizedLabels.smartAlarmLabelGym[locale] ?? "Morning run",
                days: LocalizedLabels.smartAlarmWeekends[locale] ?? "Weekends",
                window: 15,
                enabled: true
            )
            alarmRow(
                time: "08:30",
                label: weekendLabel,
                days: LocalizedLabels.smartAlarmWeekends[locale] ?? "Weekends",
                window: 45,
                enabled: false
            )
        }
    }

    private var weekendLabel: String {
        switch locale {
        case "pt-BR": return "Fim de semana"
        case "es-ES", "es-MX": return "Fin de semana"
        default: return "Lazy weekend"
        }
    }

    private func alarmRow(
        time: String,
        label: String,
        days: String,
        window: Int,
        enabled: Bool
    ) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(time)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(enabled ? MockTheme.textPrimary : MockTheme.textTertiary)

                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MockTheme.textSecondary)

                    Text("•")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MockTheme.textTertiary)

                    Text(days)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MockTheme.textTertiary)
                }

                // Smart window indicator
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(window) \(LocalizedLabels.smartAlarmMinutes[locale] ?? "min")")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(enabled ? MockTheme.accentSecondary : MockTheme.textTertiary)
            }

            Spacer()

            iosToggle(isOn: enabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func iosToggle(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? MockTheme.primary : MockTheme.surfaceTertiary)
                .frame(width: 50, height: 30)
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .padding(.horizontal, 2)
        }
    }
}
