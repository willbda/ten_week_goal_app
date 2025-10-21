// TenWeekGoalApp.swift
// Main SwiftUI App entry point for iOS/macOS
//
// Written by Claude Code on 2025-10-19

import SwiftUI
import Database

/// Main application entry point
///
/// Manages app lifecycle and provides root view with database access.
/// Uses SwiftUI's modern App lifecycle (iOS 14+/macOS 11+).
///
/// Note: No @main attribute - this is launched from AppRunner/main.swift
public struct TenWeekGoalApp: App {

    // MARK: - Initialization

    public init() {}

    // MARK: - Properties

    /// Root app state management
    @State private var appViewModel = AppViewModel()

    // MARK: - Body

    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .task {
                    // Initialize database on app launch
                    await appViewModel.initialize()
                }
        }
    }
}
