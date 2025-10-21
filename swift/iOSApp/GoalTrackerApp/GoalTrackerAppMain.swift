// GoalTrackerAppMain.swift
// iOS App entry point
//
// Written by Claude Code on 2025-10-19
// Updated 2025-10-20 to use GoalTrackerKit library
//
// This is the minimal iOS app wrapper that imports the shared GoalTrackerKit library.

import SwiftUI
import GoalTrackerKit

@main
struct GoalTrackerAppMain: App {
    var body: some Scene {
        // Use the TenWeekGoalApp SwiftUI views from our library
        TenWeekGoalApp().body
    }
}
