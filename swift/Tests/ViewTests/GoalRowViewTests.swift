// GoalRowViewTests.swift
// Tests for GoalRowView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21
// Updated by Claude Code on 2025-10-23 (removed Motivating properties - Goals no longer have priority/lifeDomain)

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for GoalRowView component
///
/// Verifies the display of goal data including measurement targets and dates.
@Suite("GoalRowView Tests")
struct GoalRowViewTests {

    // MARK: - Display Tests

    @Test("Displays title correctly")
    func displaysTitle() {
        let goal = Goal(
            title: "Run 100km"
        )

        #expect(goal.title == "Run 100km")
    }

    @Test("Shows fallback for untitled goal")
    func showsUntitledFallback() {
        let goal = Goal(
            title: nil,
            detailedDescription: "Some description"
        )

        #expect(goal.title == nil)
    }

    @Test("Displays measurement target with unit")
    func displaysMeasurementTarget() {
        let goal = Goal(
            title: "Running goal",
            measurementUnit: "km",
            measurementTarget: 100.0
        )

        #expect(goal.measurementUnit == "km")
        #expect(goal.measurementTarget == 100.0)
    }

    @Test("Displays target date")
    func displaysTargetDate() {
        let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date())!
        let goal = Goal(
            title: "Complete by deadline",
            targetDate: targetDate
        )

        #expect(goal.targetDate == targetDate)
    }

    // MARK: - Date Display Tests

    @Test("Shows clock icon for future target date")
    func showsClockForFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let goal = Goal(
            title: "Future goal",
            targetDate: futureDate
        )

        #expect(goal.targetDate! > Date())
    }

    @Test("Shows warning icon for overdue target date")
    func showsWarningForOverdueDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let goal = Goal(
            title: "Overdue goal",
            targetDate: pastDate
        )

        #expect(goal.targetDate! < Date())
    }

    @Test("Handles goal without target date")
    func handlesNoTargetDate() {
        let goal = Goal(
            title: "Open-ended goal",
            targetDate: nil
        )

        #expect(goal.targetDate == nil)
    }

    @Test("Handles today as target date")
    func handlesTodayAsTargetDate() {
        let today = Date()
        let goal = Goal(
            title: "Due today",
            targetDate: today
        )

        #expect(goal.targetDate == today)
    }

    // MARK: - Combined Features Tests

    @Test("Displays goal with all features")
    func displaysGoalWithAllFeatures() {
        let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date())!

        let goal = Goal(
            title: "Complete marathon training",
            detailedDescription: "Train for upcoming marathon",
            measurementUnit: "km",
            measurementTarget: 500.0,
            targetDate: targetDate,
            howGoalIsRelevant: "Improve health",
            howGoalIsActionable: "Run 3x per week"
        )

        #expect(goal.title == "Complete marathon training")
        #expect(goal.measurementUnit == "km")
        #expect(goal.measurementTarget == 500.0)
        #expect(goal.targetDate == targetDate)
    }

    @Test("Displays goal with partial features")
    func displaysGoalPartialFeatures() {
        let goal = Goal(
            title: "Learn Swift",
            measurementUnit: "hours",
            measurementTarget: 100.0
        )

        #expect(goal.title == "Learn Swift")
        #expect(goal.measurementUnit == "hours")
        #expect(goal.measurementTarget == 100.0)
        #expect(goal.targetDate == nil)
    }

    @Test("Displays minimal goal with only name")
    func displaysMinimalGoal() {
        let goal = Goal(
            title: "Simple goal"
        )

        #expect(goal.title == "Simple goal")
        #expect(goal.measurementUnit == nil)
        #expect(goal.measurementTarget == nil)
        #expect(goal.targetDate == nil)
    }

    // MARK: - Measurement Display Tests

    @Test("Displays measurement with decimal precision")
    func displaysDecimalMeasurement() {
        let goal = Goal(
            title: "Running goal",
            measurementUnit: "km",
            measurementTarget: 123.45
        )

        #expect(goal.measurementTarget == 123.45)
    }

    @Test("Handles whole number measurements")
    func handlesWholeNumberMeasurement() {
        let goal = Goal(
            title: "Reading goal",
            measurementUnit: "books",
            measurementTarget: 12.0
        )

        #expect(goal.measurementTarget == 12.0)
    }

    @Test("Handles unit without target")
    func handlesUnitWithoutTarget() {
        let goal = Goal(
            title: "Goal",
            measurementUnit: "km",
            measurementTarget: nil
        )

        #expect(goal.measurementUnit == "km")
        #expect(goal.measurementTarget == nil)
    }

    @Test("Handles target without unit")
    func handlesTargetWithoutUnit() {
        let goal = Goal(
            title: "Goal",
            measurementUnit: nil,
            measurementTarget: 100.0
        )

        #expect(goal.measurementUnit == nil)
        #expect(goal.measurementTarget == 100.0)
    }

    // MARK: - Edge Cases

    @Test("Handles very long goal name")
    func handlesLongGoalName() {
        let longName = String(repeating: "Very long goal name ", count: 10)
        let goal = Goal(
            title: longName
        )

        #expect(goal.title == longName)
        #expect(goal.title!.count > 100)
    }

    @Test("Handles very large target value")
    func handlesLargeTargetValue() {
        let goal = Goal(
            title: "Huge goal",
            measurementUnit: "steps",
            measurementTarget: 1_000_000.0
        )

        #expect(goal.measurementTarget == 1_000_000.0)
    }

    @Test("Handles very small target value")
    func handlesSmallTargetValue() {
        let goal = Goal(
            title: "Small goal",
            measurementUnit: "kg",
            measurementTarget: 0.5
        )

        #expect(goal.measurementTarget == 0.5)
    }

    @Test("Handles far future target date")
    func handlesFarFutureDate() {
        let farFuture = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        let goal = Goal(
            title: "Long-term goal",
            targetDate: farFuture
        )

        #expect(goal.targetDate! > Date())
    }

    @Test("Handles long overdue target date")
    func handlesLongOverdueDate() {
        let longPast = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let goal = Goal(
            title: "Very overdue goal",
            targetDate: longPast
        )

        #expect(goal.targetDate! < Date())
    }
}
