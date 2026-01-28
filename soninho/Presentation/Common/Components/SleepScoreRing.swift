//
//  SleepScoreRing.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Sleep Score Ring
struct SleepScoreRing: View {
    // MARK: - Properties
    let score: Int
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool

    // MARK: - State
    @State private var animatedProgress: Double = 0

    // MARK: - Computed Properties
    private var progress: Double {
        Double(score) / 100.0
    }

    private var quality: SleepQuality {
        SleepQuality(score: score)
    }

    private var gradientColors: [Color] {
        switch quality {
        case .excellent:
            return [AppColors.success, AppColors.success.opacity(0.7)]
        case .good:
            return [AppColors.primary, AppColors.primaryLight]
        case .fair:
            return [AppColors.warning, AppColors.warning.opacity(0.7)]
        case .poor:
            return [AppColors.error, AppColors.error.opacity(0.7)]
        }
    }

    // MARK: - Init
    init(score: Int, size: CGFloat = 150, lineWidth: CGFloat = 12, showLabel: Bool = true) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
        self.showLabel = showLabel
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(AppColors.surfaceSecondary, lineWidth: lineWidth)

            // Progress Circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedProgress)

            // Center Content
            if showLabel {
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(AppFonts.number(size * 0.3))
                        .foregroundColor(AppColors.textPrimary)

                    Text(quality.localizedName)
                        .font(AppFonts.caption())
                        .foregroundColor(quality.color)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) { _, newScore in
            animatedProgress = Double(newScore) / 100.0
        }
    }
}

// MARK: - Mini Score Badge
struct SleepScoreBadge: View {
    // MARK: - Properties
    let score: Int

    // MARK: - Computed Properties
    private var quality: SleepQuality {
        SleepQuality(score: score)
    }

    // MARK: - View Body
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: quality.icon)
                .font(.system(size: 10))

            Text("\(score)")
                .font(AppFonts.caption())
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(quality.color)
        .background(quality.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        SleepScoreRing(score: 92)
        SleepScoreRing(score: 75)
        SleepScoreRing(score: 58)
        SleepScoreRing(score: 35)

        HStack {
            SleepScoreBadge(score: 92)
            SleepScoreBadge(score: 75)
            SleepScoreBadge(score: 58)
            SleepScoreBadge(score: 35)
        }
    }
    .padding()
    .background(AppColors.background)
}
