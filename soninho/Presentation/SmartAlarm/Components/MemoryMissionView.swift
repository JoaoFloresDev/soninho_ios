//
//  MemoryMissionView.swift
//  soninho
//
//  Dismiss mission: watch a sequence of tiles light up on a 3×3 grid, then
//  repeat it from memory. Difficulty scales the sequence length.
//

import SwiftUI
import UIKit

// MARK: - Memory Mission View
struct MemoryMissionView: View {
    // MARK: - Phase
    private enum Phase {
        case showing, repeating
    }

    // MARK: - Properties
    let difficulty: MissionDifficulty
    let onComplete: () -> Void

    @State private var phase: Phase = .showing
    @State private var sequence: [Int] = []
    @State private var progress = 0
    @State private var highlightedTile: Int?
    @State private var wrongTile: Int?
    @State private var playbackTask: Task<Void, Never>?

    // MARK: - Constants
    private let gridSize = 3
    private let showInterval: TimeInterval = 0.55

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 28) {
            // Progress dots — one per sequence step, filled as the user repeats it.
            HStack(spacing: 8) {
                ForEach(0..<sequence.count, id: \.self) { index in
                    Circle()
                        .fill(index < progress ? AppColors.accent : AppColors.surfaceSecondary)
                        .frame(width: 9, height: 9)
                }
            }

            Text(phase == .showing
                 ? String(localized: "wake_memory_watch")
                 : String(localized: "wake_memory_repeat"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)
                .animation(.easeInOut, value: phase)

            // Tile grid
            VStack(spacing: 12) {
                ForEach(0..<gridSize, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            tile(index: row * gridSize + col)
                        }
                    }
                }
            }
            .padding(20)
            .glassSurface(cornerRadius: 20)

            // Replay
            Button {
                playSequence()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text(String(localized: "wake_memory_replay"))
                        .font(AppFonts.subheadline())
                }
                .foregroundStyle(AppColors.textSecondary)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 28)
        .onAppear { setup() }
        .onDisappear { playbackTask?.cancel() }
    }

    // MARK: - Subviews
    private func tile(index: Int) -> some View {
        Button {
            handleTap(index)
        } label: {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tileColor(index))
                .frame(width: 74, height: 74)
                .scaleEffect(highlightedTile == index ? 1.08 : 1.0)
                .animation(.spring(response: 0.25), value: highlightedTile)
        }
        .disabled(phase == .showing)
    }

    private func tileColor(_ index: Int) -> Color {
        if wrongTile == index { return AppColors.error }
        if highlightedTile == index { return AppColors.accent }
        return AppColors.surfaceSecondary
    }

    // MARK: - Private Methods
    private func setup() {
        let tileCount = gridSize * gridSize
        sequence = (0..<difficulty.memorySequenceLength).map { _ in Int.random(in: 0..<tileCount) }
        progress = 0
        playSequence()
    }

    private func playSequence() {
        playbackTask?.cancel()
        phase = .showing
        progress = 0
        playbackTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            for tileIndex in sequence {
                guard !Task.isCancelled else { return }
                highlightedTile = tileIndex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                try? await Task.sleep(nanoseconds: UInt64(showInterval * 1_000_000_000))
                highlightedTile = nil
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
            guard !Task.isCancelled else { return }
            phase = .repeating
        }
    }

    private func handleTap(_ index: Int) {
        guard phase == .repeating else { return }

        if sequence[safe: progress] == index {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            highlightedTile = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                if highlightedTile == index { highlightedTile = nil }
            }
            progress += 1
            if progress >= sequence.count {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete()
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            wrongTile = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongTile = nil
                playSequence()
            }
        }
    }
}
