// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Package manifest for Happy to Have Lived
// Written by Claude Code on 2025-10-31
//
// ARCHITECTURE:
// - Library products: Models, Database, Services, App (for Xcode project consumption)
// - Targets: Models, Database, Services, App
// - Multi-platform: iOS 26+, macOS 26+, visionOS 26+
// - Swift 6.2 with full concurrency support

import PackageDescription

let package = Package(
    name: "HappyToHaveLived",

    // MARK: - Platforms

    platforms: [
        .macOS(.v26),  // macOS Tahoe 26+
        .iOS(.v26),  // iOS 26+
        .visionOS(.v26),  // visionOS 26+
    ],

    // MARK: - Products

    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Database", targets: ["Database"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "App", targets: ["App"]),
    ],

    // MARK: - Dependencies

    dependencies: [
        // Database: SQLiteData for type-safe database operations
        .package(
            url: "https://github.com/pointfreeco/sqlite-data.git",
            from: "1.2.0"
        )
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
                .product(name: "SQLiteData", package: "sqlite-data")
            ],
            path: "Sources/Models"
        ),

        // =========================================================================
        // DATABASE
        // =========================================================================
        // Database layer: Schema, Bootstrap, SyncConfiguration
        // Handles SQLite initialization, CloudKit sync registration

        .target(
            name: "Database",
            dependencies: [
                "Models",
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            path: "Sources/Database",
            resources: [
                .copy("Schemas/schema_current.sql")
            ]
        ),

        // =========================================================================
        // SERVICES
        // =========================================================================
        // Platform services: Coordinators, Validators, Repositories, HealthKit, FoundationModels

        .target(
            name: "Services",
            dependencies: [
                "Models",
                "Database",
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            path: "Sources/Services"
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
                "Database",
                "Services",
                .product(name: "SQLiteData", package: "sqlite-data"),
            ],
            path: "Sources/App"
        ),

        // =========================================================================
        // TESTS
        // =========================================================================
        // Tests moved to Xcode test target: GoalTracker/Happy to Have Lived Tests/
        // This is an app project, not a distributable package
    ],

    // MARK: - Swift Language Settings

    swiftLanguageModes: [.v6]
)
