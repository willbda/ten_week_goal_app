// GoalRowViewTests.swift
// Tests for GoalRowView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for GoalRowView component
///
/// Verifies the display of goal data including priority badges,
/// measurement targets, dates, and life domains.
@Suite("GoalRowView Tests")
struct GoalRowViewTests {

    // MARK: - Display Tests

    @Test("Displays friendly name correctly")
    func displaysFriendlyName() {
        let goal = Goal(
            friendlyName: "Run 100km",
            priority: 50
        )

        #expect(goal.friendlyName == "Run 100km")
    }

    @Test("Shows fallback for untitled goal")
    func showsUntitledFallback() {
        let goal = Goal(
            friendlyName: nil,
            detailedDescription: "Some description",
            priority: 50
        )

        #expect(goal.friendlyName == nil)
    }

    @Test("Displays measurement target with unit")
    func displaysMeasurementTarget() {
        let goal = Goal(
            friendlyName: "Running goal",
            measurementUnit: "km",
            measurementTarget: 100.0,
            priority: 50
        )

        #expect(goal.measurementUnit == "km")
        #expect(goal.measurementTarget == 100.0)
    }

    @Test("Displays target date")
    func displaysTargetDate() {
        let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date())!
        let goal = Goal(
            friendlyName: "Complete by deadline",
            targetDate: targetDate,
            priority: 50
        )

        #expect(goal.targetDate == targetDate)
    }

    @Test("Displays life domain tag")
    func displaysLifeDomain() {
        let goal = Goal(
            friendlyName: "Fitness goal",
            priority: 50,
            lifeDomain: "Health"
        )

        #expect(goal.lifeDomain == "Health")
    }

    // MARK: - Priority Badge Tests

    @Test("Shows HIGH priority badge for priority <= 10")
    func showsHighPriorityBadge() {
        let highPriorityGoal = Goal(
            friendlyName: "Critical goal",
            priority: 5
        )

        #expect(highPriorityGoal.priority <= 10)
    }

    @Test("Shows MED priority badge for priority 11-30")
    func showsMediumPriorityBadge() {
        let mediumPriorityGoal = Goal(
            friendlyName: "Important goal",
            priority: 20
        )

        #expect(mediumPriorityGoal.priority > 10)
        #expect(mediumPriorityGoal.priority <= 30)
    }

    @Test("Shows no badge for priority > 30")
    func showsNoBadgeForLowPriority() {
        let lowPriorityGoal = Goal(
            friendlyName: "Low priority goal",
            priority: 50
        )

        #expect(lowPriorityGoal.priority > 30)
    }

    @Test("Priority 10 boundary shows HIGH badge")
    func priority10ShowsHighBadge() {
        let goal = Goal(
            friendlyName: "Boundary test",
            priority: 10
        )

        #expect(goal.priority <= 10)
    }

    @Test("Priority 11 shows MED badge")
    func priority11ShowsMediumBadge() {
        let goal = Goal(
            friendlyName: "Boundary test",
            priority: 11
        )

        #expect(goal.priority > 10)
        #expect(goal.priority <= 30)
    }

    @Test("Priority 30 boundary shows MED badge")
    func priority30ShowsMediumBadge() {
        let goal = Goal(
            friendlyName: "Boundary test",
            priority: 30
        )

        #expect(goal.priority <= 30)
    }

    @Test("Priority 31 shows no badge")
    func priority31ShowsNoBadge() {
        let goal = Goal(
            friendlyName: "Boundary test",
            priority: 31
        )

        #expect(goal.priority > 30)
    }

    // MARK: - Date Display Tests

    @Test("Shows clock icon for future target date")
    func showsClockForFutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let goal = Goal(
            friendlyName: "Future goal",
            targetDate: futureDate,
            priority: 50
        )

        #expect(goal.targetDate! > Date())
    }

    @Test("Shows warning icon for overdue target date")
    func showsWarningForOverdueDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let goal = Goal(
            friendlyName: "Overdue goal",
            targetDate: pastDate,
            priority: 50
        )

        #expect(goal.targetDate! < Date())
    }

    @Test("Handles goal without target date")
    func handlesNoTargetDate() {
        let goal = Goal(
            friendlyName: "Open-ended goal",
            targetDate: nil,
            priority: 50
        )

        #expect(goal.targetDate == nil)
    }

    @Test("Handles today as target date")
    func handlesTodayAsTargetDate() {
        let today = Date()
        let goal = Goal(
            friendlyName: "Due today",
            targetDate: today,
            priority: 50
        )

        #expect(goal.targetDate == today)
    }

    // MARK: - Combined Features Tests

    @Test("Displays high priority goal with all features")
    func displaysHighPriorityGoalWithAllFeatures() {
        let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date())!

        let goal = Goal(
            friendlyName: "Complete marathon training",
            detailedDescription: "Train for upcoming marathon",
            measurementUnit: "km",
            measurementTarget: 500.0,
            targetDate: targetDate,
            priority: 5,
            lifeDomain: "Health"
        )

        #expect(goal.friendlyName == "Complete marathon training")
        #expect(goal.measurementUnit == "km")
        #expect(goal.measurementTarget == 500.0)
        #expect(goal.targetDate == targetDate)
        #expect(goal.priority == 5)
        #expect(goal.lifeDomain == "Health")
    }

    @Test("Displays medium priority goal with partial features")
    func displaysMediumPriorityGoalPartialFeatures() {
        let goal = Goal(
            friendlyName: "Learn Swift",
            measurementUnit: "hours",
            measurementTarget: 100.0,
            priority: 20,
            lifeDomain: "Career"
        )

        #expect(goal.friendlyName == "Learn Swift")
        #expect(goal.measurementUnit == "hours")
        #expect(goal.measurementTarget == 100.0)
        #expect(goal.priority == 20)
        #expect(goal.lifeDomain == "Career")
        #expect(goal.targetDate == nil)
    }

    @Test("Displays minimal goal with only name")
    func displaysMinimalGoal() {
        let goal = Goal(
            friendlyName: "Simple goal",
            priority: 50
        )

        #expect(goal.friendlyName == "Simple goal")
        #expect(goal.measurementUnit == nil)
        #expect(goal.measurementTarget == nil)
        #expect(goal.targetDate == nil)
        #expect(goal.lifeDomain == nil)
    }

    // MARK: - Measurement Display Tests

    @Test("Displays measurement with decimal precision")
    func displaysDecimalMeasurement() {
        let goal = Goal(
            friendlyName: "Running goal",
            measurementUnit: "km",
            measurementTarget: 123.45,
            priority: 50
        )

        #expect(goal.measurementTarget == 123.45)
    }

    @Test("Handles whole number measurements")
    func handlesWholeNumberMeasurement() {
        let goal = Goal(
            friendlyName: "Reading goal",
            measurementUnit: "books",
            measurementTarget: 12.0,
            priority: 50
        )

        #expect(goal.measurementTarget == 12.0)
    }

    @Test("Handles unit without target")
    func handlesUnitWithoutTarget() {
        let goal = Goal(
            friendlyName: "Goal",
            measurementUnit: "km",
            measurementTarget: nil,
            priority: 50
        )

        #expect(goal.measurementUnit == "km")
        #expect(goal.measurementTarget == nil)
    }

    @Test("Handles target without unit")
    func handlesTargetWithoutUnit() {
        let goal = Goal(
            friendlyName: "Goal",
            measurementUnit: nil,
            measurementTarget: 100.0,
            priority: 50
        )

        #expect(goal.measurementUnit == nil)
        #expect(goal.measurementTarget == 100.0)
    }

    // MARK: - Life Domain Tests

    @Test("Displays various life domains")
    func displaysVariousLifeDomains() {
        let domains = ["Health", "Career", "Relationships", "Finance", "Personal Growth"]

        for domain in domains {
            let goal = Goal(
                friendlyName: "Goal in \(domain)",
                priority: 50,
                lifeDomain: domain
            )

            #expect(goal.lifeDomain == domain)
        }
    }

    @Test("Handles custom life domain")
    func handlesCustomLifeDomain() {
        let goal = Goal(
            friendlyName: "Custom goal",
            priority: 50,
            lifeDomain: "My Custom Domain"
        )

        #expect(goal.lifeDomain == "My Custom Domain")
    }

    @Test("Handles empty life domain")
    func handlesEmptyLifeDomain() {
        let goal = Goal(
            friendlyName: "No domain",
            priority: 50,
            lifeDomain: nil
        )

        #expect(goal.lifeDomain == nil)
    }

    // MARK: - Edge Cases

    @Test("Handles very long goal name")
    func handlesLongGoalName() {
        let longName = String(repeating: "Very long goal name ", count: 10)
        let goal = Goal(
            friendlyName: longName,
            priority: 50
        )

        #expect(goal.friendlyName == longName)
        #expect(goal.friendlyName!.count > 100)
    }

    @Test("Handles very large target value")
    func handlesLargeTargetValue() {
        let goal = Goal(
            friendlyName: "Huge goal",
            measurementUnit: "steps",
            measurementTarget: 1_000_000.0,
            priority: 50
        )

        #expect(goal.measurementTarget == 1_000_000.0)
    }

    @Test("Handles very small target value")
    func handlesSmallTargetValue() {
        let goal = Goal(
            friendlyName: "Small goal",
            measurementUnit: "kg",
            measurementTarget: 0.5,
            priority: 50
        )

        #expect(goal.measurementTarget == 0.5)
    }

    @Test("Handles far future target date")
    func handlesFarFutureDate() {
        let farFuture = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        let goal = Goal(
            friendlyName: "Long-term goal",
            targetDate: farFuture,
            priority: 50
        )

        #expect(goal.targetDate! > Date())
    }

    @Test("Handles long overdue target date")
    func handlesLongOverdueDate() {
        let longPast = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let goal = Goal(
            friendlyName: "Very overdue goal",
            targetDate: longPast,
            priority: 50
        )

        #expect(goal.targetDate! < Date())
    }
}
