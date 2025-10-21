// swift-tools-version: 6.0
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
            targets: ["Models", "Database", "App"]
        )
        // No executable needed - iOS/macOS apps import the library
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0")
    ],
    targets: [
        // Domain layer (pure, no infrastructure dependencies)
        .target(
            name: "Models",
            dependencies: [],
            path: "Sources/Models"
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
        // Translation layer (Storage services)
        .target(
            name: "Services",
            dependencies: [
                "Models",
                "Database",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Services"
        ),
        // SwiftUI App Views (iOS/macOS library)
        .target(
            name: "App",
            dependencies: [
                "Models",
                "Database",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/App"
        ),
        // Tests
        .testTarget(
            name: "GoalTrackerTests",
            dependencies: ["Models", "Database"],
            path: "Tests",
            exclude: [
                "TestingStrategy.md"
            ]
        ),
    ]
)
