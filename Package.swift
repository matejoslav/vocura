// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vocura",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Vocura", targets: ["Vocura"])
    ],
    dependencies: [],
    targets: [
        // Library containing core logic (testable)
        .target(
            name: "VocuraCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        // Main executable
        .executableTarget(
            name: "Vocura",
            dependencies: ["VocuraCore"],
            path: "Sources",
            exclude: ["Core"],
            resources: [
                .process("Resources")
            ]
        ),
        // Test target
        .testTarget(
            name: "VocuraTests",
            dependencies: ["VocuraCore"],
            path: "Tests"
        )
    ]
)
