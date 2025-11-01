// TenWeekGoalApp.swift
// Main SwiftUI App entry point for iOS/macOS
//
// Written by Claude Code on 2025-10-31

import SwiftUI

/// Main application entry point
///
/// Configures app dependencies and provides the root scene.
public struct TenWeekGoalApp: App {

    public init() {
        DatabaseBootstrap.configure()
    }

    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
