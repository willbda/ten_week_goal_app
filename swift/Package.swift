// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Package manifest for Ten Week Goal App
// Written by Claude Code on 2025-10-31
//
// ARCHITECTURE:
// - Single product: App (includes Models, Services, Logic transitively)
// - Multi-platform: iOS 26+, macOS 26+, visionOS 26+
// - Swift 6.2 with full concurrency support

import PackageDescription

let package = Package(
    name: "GoalTrackerApp",

    // MARK: - Platforms

    platforms: [
        .macOS(.v26),       // macOS Tahoe 26+
        .iOS(.v26),         // iOS 26+
        .visionOS(.v26),    // visionOS 26+
    ],

    // MARK: - Products

    products: [
        // Single library product - import this in your Xcode app
        .library(
            name: "App",
            targets: ["App"]
        ),
    ],

    // MARK: - Dependencies

    dependencies: [
        // Database: SQLiteData for type-safe database operations
        .package(
            url: "https://github.com/pointfreeco/sqlite-data.git",
            from: "1.2.0"
        ),
    ],

    // MARK: - Targets

    targets: [
        // =========================================================================
        // MODELS
        // =========================================================================
        // Domain models: Abstractions/ Basics/ Composits/

        .target(
            name: "Models",
            dependencies: [
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            path: "Sources/Models"
        ),

        // =========================================================================
        // SERVICES
        // =========================================================================
        // Platform services: HealthKitManager, MetricRepository

        .target(
            name: "Services",
            dependencies: [
                "Models",
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            path: "Sources/Services"
        ),

        // =========================================================================
        // LOGIC
        // =========================================================================
        // Business logic: GoalValidation, LLM/

        .target(
            name: "Logic",
            dependencies: [
                "Models",
            ],
            path: "Sources/Logic"
        ),

        // =========================================================================
        // APP
        // =========================================================================
        // SwiftUI views: App.swift, Views/
        // This is the product - depends on all other modules

        .target(
            name: "App",
            dependencies: [
                "Models",
                "Services",
                "Logic",
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            path: "Sources/App"
        ),

        // =========================================================================
        // TESTS
        // =========================================================================

        // Model Tests
        .testTarget(
            name: "ModelTests",
            dependencies: [
                "Models",
            ],
            path: "Tests/ModelTests"
        ),

        // View Tests
        .testTarget(
            name: "ViewTests",
            dependencies: [
                "App",
                "Models",
            ],
            path: "Tests/ViewTests"
        ),

        // Business Logic Tests (empty directory)
        .testTarget(
            name: "BusinessLogicTests",
            dependencies: [
                "Logic",
                "Models",
            ],
            path: "Tests/BusinessLogicTests"
        ),

        // Integration Tests (empty directory)
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "Models",
                "Services",
                "Logic",
                "App",
            ],
            path: "Tests/IntegrationTests"
        ),
    ],

    // MARK: - Swift Language Settings

    swiftLanguageModes: [.v6]
)
