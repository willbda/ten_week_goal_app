// GoalTests.swift
// Tests for Goal domain entity (consolidated Goal + SMART validation)
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (consolidated Goal/SmartGoal)
// Ported from Python implementation (python/tests/test_goals.py)

import XCTest
@testable import Models

final class GoalTests: XCTestCase {

    // MARK: - Basic Goal Creation & Defaults

    func testMinimalGoalCreation() {
        let goal = Goal(friendlyName: "Run more often")

        XCTAssertEqual(goal.friendlyName, "Run more often")
        XCTAssertNotNil(goal.id) // UUID auto-generated
        XCTAssertNotNil(goal.logTime) // Defaults to Date()
        XCTAssertEqual(goal.polymorphicSubtype, "goal")

        // All goal-specific fields should be nil
        XCTAssertNil(goal.measurementUnit)
        XCTAssertNil(goal.measurementTarget)
        XCTAssertNil(goal.startDate)
        XCTAssertNil(goal.targetDate)

        // Minimal goal is valid but not SMART
        XCTAssertTrue(goal.isValid())
        XCTAssertFalse(goal.isSmart())
    }

    func testFullyPopulatedGoal() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later

        let goal = Goal(
            friendlyName: "Complete training program",
            detailedDescription: "Build endurance for marathon",
            freeformNotes: "Focus on consistency",
            measurementUnit: "km",
            measurementTarget: 120.0,
            startDate: start,
            targetDate: end,
            howGoalIsRelevant: "Improve overall fitness",
            howGoalIsActionable: "Run 3x per week, gradually increase distance",
            expectedTermLength: 10
        )

        XCTAssertTrue(goal.isValid())
        XCTAssertTrue(goal.isMeasurable())
        XCTAssertTrue(goal.isTimeBound())
        XCTAssertTrue(goal.isSmart())  // All SMART fields present
        XCTAssertEqual(goal.expectedTermLength, 10)
    }

    // MARK: - SMART Validation Tests

    func testSmartGoalValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later

        // Fully SMART-compliant goal
        let smartGoal = Goal(
            friendlyName: "Run 120km in 10 weeks",
            measurementUnit: "km",
            measurementTarget: 120.0,
            startDate: start,
            targetDate: end,
            howGoalIsRelevant: "Build marathon endurance",
            howGoalIsActionable: "Run 3x per week, progressive overload"
        )

        XCTAssertTrue(smartGoal.isSmart())
        XCTAssertTrue(smartGoal.isValid())
        XCTAssertTrue(smartGoal.isMeasurable())
        XCTAssertTrue(smartGoal.isTimeBound())
    }

    func testPartialGoalNotSmart() {
        // Missing SMART fields = not SMART compliant
        let partialGoal = Goal(
            friendlyName: "Run more",
            measurementUnit: "km",
            measurementTarget: 100.0
            // Missing: dates and SMART enhancement fields
        )

        XCTAssertTrue(partialGoal.isValid())  // Still structurally valid
        XCTAssertTrue(partialGoal.isMeasurable())  // Has measurement
        XCTAssertFalse(partialGoal.isTimeBound())  // No dates
        XCTAssertFalse(partialGoal.isSmart())  // Not SMART compliant
    }

    // MARK: - Goal Validation Rules

    func testGoalMeasurementValidation() {
        // Valid: positive target
        let validGoal = Goal(
            measurementUnit: "km",
            measurementTarget: 50.0
        )
        XCTAssertTrue(validGoal.isValid())
        XCTAssertTrue(validGoal.isMeasurable())

        // Invalid: negative target
        let invalidGoal = Goal(
            measurementUnit: "km",
            measurementTarget: -10.0
        )
        XCTAssertFalse(invalidGoal.isValid())

        // Invalid: zero target
        let zeroGoal = Goal(
            measurementUnit: "km",
            measurementTarget: 0.0
        )
        XCTAssertFalse(zeroGoal.isValid())
    }

    func testGoalDateValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*10) // 10 days later

        // Valid: start before end
        let validGoal = Goal(startDate: start, targetDate: end)
        XCTAssertTrue(validGoal.isValid())
        XCTAssertTrue(validGoal.isTimeBound())

        // Invalid: start after end
        let invalidGoal = Goal(startDate: end, targetDate: start)
        XCTAssertFalse(invalidGoal.isValid())

        // Invalid: start equals end
        let sameDate = Date()
        let equalGoal = Goal(startDate: sameDate, targetDate: sameDate)
        XCTAssertFalse(equalGoal.isValid())
    }


    // MARK: - Milestone Tests

    func testMilestoneCreation() {
        let target = Date().addingTimeInterval(60*60*24*35) // 5 weeks from now

        let milestone = Milestone(
            friendlyName: "Reach 50km by week 5",
            targetDate: target
        )

        XCTAssertEqual(milestone.polymorphicSubtype, "milestone")
        XCTAssertNotNil(milestone.targetDate)
        XCTAssertNil(milestone.startDate) // Milestones can optionally have start dates
        XCTAssertTrue(milestone.isValid())
    }

    func testMilestoneValidation() {
        let target = Date().addingTimeInterval(60*60*24*35)

        // Valid: has required target date
        let validMilestone = Milestone(
            friendlyName: "Complete chapter 3",
            targetDate: target
        )
        XCTAssertTrue(validMilestone.isValid())

        // Invalid: missing target date (required for milestones)
        let invalidMilestone = Milestone(
            friendlyName: "No target date"
            // targetDate is nil
        )
        XCTAssertFalse(invalidMilestone.isValid())
    }

    func testMilestoneWithMeasurement() {
        let target = Date().addingTimeInterval(60*60*24*35)

        let milestone = Milestone(
            friendlyName: "Hit 50km by week 5",
            measurementUnit: "km",
            measurementTarget: 50.0,
            targetDate: target
        )

        XCTAssertTrue(milestone.isValid())
        XCTAssertNotNil(milestone.measurementTarget)
        XCTAssertNotNil(milestone.measurementUnit)
    }
}
