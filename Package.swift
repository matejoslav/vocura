// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceText",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoiceText", targets: ["VoiceText"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VoiceText",
            dependencies: [],
            path: "Sources"
        )
    ]
)
