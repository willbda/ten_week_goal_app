// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TenWeekGoalApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TenWeekGoalApp",
            targets: ["Categoriae"]
        )
    ],
    dependencies: [],
    targets: [
        // Domain layer
        .target(
            name: "Categoriae",
            dependencies: [],
            path: "Sources/Categoriae"
        ),
        // Tests
        .testTarget(
            name: "TenWeekGoalAppTests",
            dependencies: ["Categoriae"],
            path: "Tests"
        ),
    ]
)