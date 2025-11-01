//IosApp.swift
// iOS app entry point for Ten Week Goal Tracker
//

import App
import SwiftUI

// Use the shared TenWeekGoalApp from the App module
// This provides SQLiteData initialization with iCloud sync
@main
struct GoalTrackerAppWrapper: App {
    private let app = TenWeekGoalApp()

    var body: some Scene {
        app.body
    }
}
