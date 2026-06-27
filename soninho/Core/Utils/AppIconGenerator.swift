//
//  AppIconGenerator.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - App Icon View
/// View that renders the app icon using native SF Symbols.
/// Use this view with ImageRenderer to export the icon as PNG.
struct AppIconView: View {
    // MARK: - Properties
    let size: CGFloat

    // MARK: - Init
    init(size: CGFloat = 1024) {
        self.size = size
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1E1B4B"),
                    Color(hex: "0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Stars decoration
            starsLayer

            // Main moon icon
            ZStack {
                // Glow effect (subtle)
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: size * 0.45, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "8B5CF6"),
                                Color(hex: "6366F1")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: size * 0.03)
                    .opacity(0.6)

                // Main icon
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: size * 0.45, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "A78BFA"),
                                Color(hex: "818CF8")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .offset(x: size * 0.02, y: -size * 0.02)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Subviews
    private var starsLayer: some View {
        GeometryReader { geometry in
            ZStack {
                // Small stars scattered around
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: size * starSize(for: index)))
                        .foregroundStyle(.white.opacity(starOpacity(for: index)))
                        .position(starPosition(for: index, in: geometry.size))
                }
            }
        }
    }

    // MARK: - Private Methods
    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [0.02, 0.015, 0.025, 0.018, 0.012, 0.02, 0.015, 0.022]
        return sizes[index % sizes.count]
    }

    private func starOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.8, 0.5, 0.7, 0.4, 0.6, 0.5, 0.7, 0.45]
        return opacities[index % opacities.count]
    }

    private func starPosition(for index: Int, in size: CGSize) -> CGPoint {
        let positions: [(x: CGFloat, y: CGFloat)] = [
            (0.15, 0.2),
            (0.85, 0.15),
            (0.12, 0.75),
            (0.88, 0.8),
            (0.25, 0.12),
            (0.78, 0.35),
            (0.18, 0.45),
            (0.82, 0.55)
        ]
        let pos = positions[index % positions.count]
        return CGPoint(x: size.width * pos.x, y: size.height * pos.y)
    }
}

// MARK: - Icon Generator
/// Utility to generate and save app icons.
@MainActor
enum AppIconGenerator {
    // MARK: - Public Methods
    /// Generates the app icon as a UIImage.
    /// - Parameter size: The size of the icon (default 1024x1024).
    /// - Returns: The generated UIImage.
    static func generateIcon(size: CGFloat = 1024) -> UIImage? {
        let view = AppIconView(size: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }

    /// Generates icon data as PNG.
    /// - Parameter size: The size of the icon.
    /// - Returns: PNG data of the icon.
    static func generateIconPNG(size: CGFloat = 1024) -> Data? {
        guard let image = generateIcon(size: size) else { return nil }
        return image.pngData()
    }

    /// Saves the icon to the app's documents directory.
    /// - Returns: The URL where the icon was saved, or nil if failed.
    static func saveIconToDocuments() -> URL? {
        guard let data = generateIconPNG() else { return nil }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconURL = documentsPath.appendingPathComponent("AppIcon.png")

        do {
            try data.write(to: iconURL)
            print("Icon saved to: \(iconURL.path)")
            return iconURL
        } catch {
            print("Failed to save icon: \(error)")
            return nil
        }
    }
}