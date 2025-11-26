// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "smith-tca-trace",
    platforms: [.macOS(.v14)],  // macOS 14+ for modern Swift 6 features
    products: [
        .executable(name: "smith-tca-trace", targets: ["TCATrace"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "TCATrace",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                // Temporarily disable experimental features to test ArgumentParser
                // .enableExperimentalFeature("StrictConcurrency"),
                // .enableUpcomingFeature("ExistentialAny")
            ]
        )
    ]
)
