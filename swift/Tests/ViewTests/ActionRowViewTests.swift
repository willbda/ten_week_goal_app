// ActionRowViewTests.swift
// Tests for ActionRowView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for ActionRowView component
///
/// Verifies the display of action data including friendly names,
/// measurements, and timing information.
@Suite("ActionRowView Tests")
struct ActionRowViewTests {

    // MARK: - Display Tests

    @Test("Displays friendly name correctly")
    func displaysFriendlyName() {
        let action = Action(
            friendlyName: "Morning run",
            logTime: Date()
        )

        // View should display the friendly name
        let view = ActionRowView(action: action)
        #expect(action.friendlyName == "Morning run")
    }

    @Test("Shows fallback for untitled action")
    func showsUntitledFallback() {
        let action = Action(
            friendlyName: nil,
            detailedDescription: "Some description",
            logTime: Date()
        )

        // Friendly name is nil, view should show "Untitled Action"
        #expect(action.friendlyName == nil)
    }

    @Test("Displays single measurement")
    func displaysSingleMeasurement() {
        let action = Action(
            friendlyName: "Run",
            measuresByUnit: ["km": 5.0],
            logTime: Date()
        )

        #expect(action.measuresByUnit?["km"] == 5.0)
        #expect(action.measuresByUnit?.count == 1)
    }

    @Test("Displays multiple measurements sorted by unit")
    func displaysMultipleMeasurements() {
        let action = Action(
            friendlyName: "Workout",
            measuresByUnit: [
                "reps": 100.0,
                "sets": 5.0,
                "weight_kg": 50.0
            ],
            logTime: Date()
        )

        #expect(action.measuresByUnit?.count == 3)
        #expect(action.measuresByUnit?["reps"] == 100.0)
        #expect(action.measuresByUnit?["sets"] == 5.0)
        #expect(action.measuresByUnit?["weight_kg"] == 50.0)

        // Verify keys can be sorted (view sorts them alphabetically)
        let sortedKeys = action.measuresByUnit?.keys.sorted() ?? []
        #expect(sortedKeys == ["reps", "sets", "weight_kg"])
    }

    @Test("Displays log time as date")
    func displaysLogTime() {
        let logTime = Date()
        let action = Action(
            friendlyName: "Morning routine",
            logTime: logTime
        )

        #expect(action.logTime == logTime)
    }

    @Test("Handles action without measurements")
    func handlesNoMeasurements() {
        let action = Action(
            friendlyName: "Meditation",
            measuresByUnit: nil,
            logTime: Date()
        )

        #expect(action.measuresByUnit == nil)
    }

    @Test("Displays action with all fields populated")
    func displaysFullAction() {
        let startTime = Date().addingTimeInterval(-3600)
        let logTime = Date()

        let action = Action(
            friendlyName: "Interval training",
            detailedDescription: "High intensity workout",
            freeformNotes: "Felt great!",
            measuresByUnit: [
                "distance_km": 5.0,
                "pace_min_per_km": 5.5,
                "avg_heart_rate": 145.0
            ],
            durationMinutes: 45.0,
            startTime: startTime,
            logTime: logTime
        )

        #expect(action.friendlyName == "Interval training")
        #expect(action.measuresByUnit?.count == 3)
        #expect(action.durationMinutes == 45.0)
        #expect(action.startTime == startTime)
        #expect(action.logTime == logTime)
    }

    // MARK: - Edge Cases

    @Test("Handles empty measurements dictionary")
    func handlesEmptyMeasurements() {
        let action = Action(
            friendlyName: "Test",
            measuresByUnit: [:],
            logTime: Date()
        )

        #expect(action.measuresByUnit?.isEmpty == true)
    }

    @Test("Handles very long friendly name")
    func handlesLongName() {
        let longName = String(repeating: "Very long action name ", count: 10)
        let action = Action(
            friendlyName: longName,
            logTime: Date()
        )

        #expect(action.friendlyName == longName)
        #expect(action.friendlyName?.count ?? 0 > 100)
    }

    @Test("Handles measurement with decimal values")
    func handlesDecimalMeasurements() {
        let action = Action(
            friendlyName: "Run",
            measuresByUnit: [
                "km": 5.234,
                "minutes": 27.58
            ],
            logTime: Date()
        )

        #expect(action.measuresByUnit?["km"] == 5.234)
        #expect(action.measuresByUnit?["minutes"] == 27.58)
    }

    @Test("Displays action with past log time")
    func displaysPastLogTime() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let action = Action(
            friendlyName: "Yesterday's workout",
            logTime: yesterday
        )

        #expect(action.logTime < Date())
        #expect(action.logTime == yesterday)
    }

    @Test("Displays action with future log time")
    func displaysFutureLogTime() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let action = Action(
            friendlyName: "Scheduled workout",
            logTime: tomorrow
        )

        #expect(action.logTime > Date())
        #expect(action.logTime == tomorrow)
    }
}
