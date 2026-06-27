// swift-tools-version: 6.0
import PackageDescription

// IMPORTANT: keep `swift-tools-version: 6.0` and `.macOS(.v15)` — they are
// required by `MeshGradient` and other modern SwiftUI APIs the kit may use.
// Downgrading either will fail to compile.

let package = Package(
    name: "SoninhoScreenshots",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "SoninhoScreenshots",
            targets: ["SoninhoScreenshots"]
        )
    ],
    dependencies: [
        // Path resolves from <App>/<App>/screenshots-tool to the shared kit.
        // If your nesting is different, adjust the number of `..` segments.
        .package(path: "/Users/joaoflores/Documents/GambitStudio/_GambitStudio/packages/GambitScreenshotKit")
    ],
    targets: [
        .executableTarget(
            name: "SoninhoScreenshots",
            dependencies: [
                .product(name: "GambitScreenshotKit", package: "GambitScreenshotKit")
            ],
            path: "Sources/SoninhoScreenshots",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
