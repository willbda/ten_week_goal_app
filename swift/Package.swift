// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TenWeekGoalApp",
    platforms: [
        .macOS(.v14)  // macOS-native for rapid development
    ],
    products: [
        .library(
            name: "TenWeekGoalApp",
            targets: ["Models"]
        ),
        .executable(
            name: "TenWeekGoalDemo",
            targets: ["Demo"]
        )
    ],
    dependencies: [],
    targets: [
        // Domain layer
        .target(
            name: "Models",
            dependencies: [],
            path: "Sources/Models"
        ),
        // Demo app
        .executableTarget(
            name: "Demo",
            dependencies: ["Models"],
            path: "Sources/Demo"
        ),
        // Tests
        .testTarget(
            name: "TenWeekGoalAppTests",
            dependencies: ["Models"],
            path: "Tests"
        ),
    ]
)
