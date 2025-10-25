// GoalTrackerApp.swift
// iOS app entry point for Ten Week Goal Tracker
//
// Written by Claude Code on 2025-10-24

import SwiftUI
import App


@main
struct GoalTrackerApp: App {

    // MARK: - State

    @State private var appViewModel = AppViewModel()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .task {
                    // Initialize database on app launch (uses .app config for iOS sandbox)
                    await appViewModel.initializeForApp()
                }
        }
    }
}
