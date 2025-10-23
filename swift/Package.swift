// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoalTracker",
    platforms: [
        .macOS(.v15),  // macOS 15 (Sequoia) with Swift 6.2
        .iOS(.v18)     // iOS 18 for latest SwiftUI features
    ],
    products: [
        // Shared library for iOS/macOS apps
        .library(
            name: "GoalTrackerKit",
            targets: ["Models", "BusinessLogic", "Database", "App"]
        ),
        // Command-line executable for testing
        .executable(
            name: "GoalTrackerCLI",
            targets: ["AppRunner"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0")
    ],
    targets: [
        // Domain layer (with GRDB for direct conformance)
        .target(
            name: "Models",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Models"
        ),
        // Business logic layer (matching, inference, progress calculations)
        .target(
            name: "BusinessLogic",
            dependencies: ["Models"],
            path: "Sources/BusinessLogic"
        ),
        // Infrastructure layer (Database operations)
        .target(
            name: "Database",
            dependencies: [
                "Models",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Database"
        ),
        // SwiftUI App Views (iOS/macOS library)
        .target(
            name: "App",
            dependencies: [
                "Models",
                "Database",
                "BusinessLogic",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/App"
        ),
        // Command-line executable target
        .executableTarget(
            name: "AppRunner",
            dependencies: [
                "Models",
                "Database",
                "App",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/AppRunner"
        ),
        // Tests
        .testTarget(
            name: "GoalTrackerTests",
            dependencies: ["Models", "BusinessLogic", "Database", "App"],
            path: "Tests",
            exclude: [
                "TestingStrategy.md"
            ]
        ),
    ]
)
