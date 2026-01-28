//
//  SleepPhaseChart.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import Charts

// MARK: - Sleep Phase Chart
struct SleepPhaseChart: View {
    // MARK: - Properties
    let phases: [SleepPhaseData]
    let startTime: Date
    let endTime: Date

    // MARK: - View Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time Labels
            HStack {
                Text(startTime.timeString)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text(endTime.timeString)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }

            // Chart
            if #available(iOS 17.0, *) {
                modernChart
            } else {
                legacyChart
            }

            // Legend
            legendView
        }
    }

    // MARK: - Modern Chart (iOS 17+)
    @available(iOS 17.0, *)
    private var modernChart: some View {
        Chart {
            ForEach(phases) { phase in
                RectangleMark(
                    xStart: .value("Start", phase.startTime),
                    xEnd: .value("End", phase.endTime),
                    y: .value("Phase", phaseYValue(phase.phase))
                )
                .foregroundStyle(phase.phase.color)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                AxisValueLabel(format: .dateTime.hour())
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 1, 2, 3]) { value in
                let phase = phaseFromYValue(value.as(Int.self) ?? 0)
                AxisValueLabel {
                    Text(phase.displayName)
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .frame(height: 150)
    }

    // MARK: - Legacy Chart (Pre iOS 17)
    private var legacyChart: some View {
        GeometryReader { geometry in
            let totalDuration = endTime.timeIntervalSince(startTime)
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceSecondary)
                    .frame(height: 120)

                // Phase bars
                ForEach(phases) { phase in
                    let startOffset = phase.startTime.timeIntervalSince(startTime) / totalDuration * width
                    let phaseWidth = phase.duration / totalDuration * width
                    let yOffset = phaseYOffset(phase.phase)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(phase.phase.color)
                        .frame(width: max(phaseWidth, 2), height: 24)
                        .offset(x: startOffset, y: yOffset)
                }
            }
        }
        .frame(height: 120)
    }

    // MARK: - Legend
    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(SleepPhase.allCases, id: \.self) { phase in
                HStack(spacing: 4) {
                    Circle()
                        .fill(phase.color)
                        .frame(width: 8, height: 8)

                    Text(phase.displayName)
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func phaseYValue(_ phase: SleepPhase) -> Int {
        switch phase {
        case .awake: return 3
        case .rem: return 2
        case .light: return 1
        case .deep: return 0
        }
    }

    private func phaseFromYValue(_ value: Int) -> SleepPhase {
        switch value {
        case 3: return .awake
        case 2: return .rem
        case 1: return .light
        default: return .deep
        }
    }

    private func phaseYOffset(_ phase: SleepPhase) -> CGFloat {
        switch phase {
        case .awake: return -36
        case .rem: return -12
        case .light: return 12
        case .deep: return 36
        }
    }
}

// MARK: - Sleep Phase Distribution
struct SleepPhaseDistribution: View {
    // MARK: - Properties
    let deepSleep: TimeInterval
    let lightSleep: TimeInterval
    let remSleep: TimeInterval
    let awakeDuration: TimeInterval

    // MARK: - Computed Properties
    private var total: TimeInterval {
        deepSleep + lightSleep + remSleep + awakeDuration
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 16) {
            // Bar Chart
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    phaseBar(duration: deepSleep, color: AppColors.deepSleep, width: geometry.size.width)
                    phaseBar(duration: lightSleep, color: AppColors.lightSleep, width: geometry.size.width)
                    phaseBar(duration: remSleep, color: AppColors.remSleep, width: geometry.size.width)
                    phaseBar(duration: awakeDuration, color: AppColors.awake, width: geometry.size.width)
                }
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Details
            HStack(spacing: 16) {
                phaseDetail(phase: .deep, duration: deepSleep)
                phaseDetail(phase: .light, duration: lightSleep)
                phaseDetail(phase: .rem, duration: remSleep)
                phaseDetail(phase: .awake, duration: awakeDuration)
            }
        }
    }

    // MARK: - Subviews
    private func phaseBar(duration: TimeInterval, color: Color, width: CGFloat) -> some View {
        let percentage = total > 0 ? duration / total : 0
        return Rectangle()
            .fill(color)
            .frame(width: max(width * percentage, 2))
    }

    private func phaseDetail(phase: SleepPhase, duration: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(phase.color)
                    .frame(width: 6, height: 6)

                Text(phase.displayName)
                    .font(AppFonts.caption2())
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(duration.hoursMinutesString)
                .font(AppFonts.footnote())
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)

            Text("\(Int((duration / total) * 100))%")
                .font(AppFonts.caption2())
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        SleepPhaseChart(
            phases: SleepRecord.sampleRecords.first?.phases ?? [],
            startTime: Date().addingTimeInterval(-8 * 3600),
            endTime: Date()
        )
        .padding()

        SleepPhaseDistribution(
            deepSleep: 1.5 * 3600,
            lightSleep: 4 * 3600,
            remSleep: 1.5 * 3600,
            awakeDuration: 0.5 * 3600
        )
        .padding()
    }
    .background(AppColors.background)
}
