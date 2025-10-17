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
            targets: ["Categoriae", "Ethica", "Rhetorica", "Politica"]
        ),
        .executable(
            name: "TenWeekGoalCLI",
            targets: ["TenWeekGoalCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
    ],
    targets: [
        // Domain layer
        .target(
            name: "Categoriae",
            dependencies: [],
            path: "Sources/Categoriae"
        ),
        // Business logic layer
        .target(
            name: "Ethica",
            dependencies: ["Categoriae"],
            path: "Sources/Ethica"
        ),
        // Translation layer
        .target(
            name: "Rhetorica",
            dependencies: ["Categoriae", "Politica"],
            path: "Sources/Rhetorica"
        ),
        // Infrastructure layer
        .target(
            name: "Politica",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/Politica"
        ),
        // CLI executable
        .executableTarget(
            name: "TenWeekGoalCLI",
            dependencies: ["Categoriae", "Ethica", "Rhetorica", "Politica"]
        ),
        // Tests
        .testTarget(
            name: "TenWeekGoalAppTests",
            dependencies: ["Categoriae", "Ethica", "Rhetorica", "Politica"],
            path: "Tests"
        ),
    ]
)