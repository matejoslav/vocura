// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VocuraKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VocuraKit", targets: ["VocuraKit"]),
    ],
    targets: [
        .target(name: "VocuraKit"),
        .testTarget(name: "VocuraKitTests", dependencies: ["VocuraKit"]),
    ]
)
