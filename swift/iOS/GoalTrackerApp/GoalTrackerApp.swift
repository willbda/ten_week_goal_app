// GoalTrackerApp.swift
// iOS app entry point for Ten Week Goal Tracker
//
// Written by Claude Code on 2025-10-24
// Updated 2025-10-25: Migrated to SQLiteData with shared TenWeekGoalApp

import SwiftUI
import App

// Use the shared TenWeekGoalApp from the App module
// This provides SQLiteData initialization with iCloud sync
@main
struct GoalTrackerAppWrapper: App {
    private let app = TenWeekGoalApp()

    var body: some Scene {
        app.body
    }
}
