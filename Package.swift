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
        .executableTarget(
            name: "Vocura",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
