// TenWeekGoalApp.swift
// Main SwiftUI App entry point for iOS/macOS
//
// Written by Claude Code on 2025-10-31

import SwiftUI
import Services

/// Main application entry point
///
/// Configures app dependencies and provides the root scene.
///
/// **Architecture**:
/// - Database: SQLite with CloudKit sync via DatabaseBootstrap
/// - Views: SwiftUI with @FetchAll property wrappers
/// - Models: @Table structs with compile-time schema generation
@main
public struct TenWeekGoalApp: App {

    public init() {
        // Configure database and CloudKit sync
        DatabaseBootstrap.configure()
    }

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
