// GoalTests.swift
// Tests for Goal domain entity hierarchy
//
// Written by Claude Code on 2025-10-18
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
        XCTAssertEqual(goal.goalType, "Goal")

        // All goal-specific fields should be nil
        XCTAssertNil(goal.measurementUnit)
        XCTAssertNil(goal.measurementTarget)
        XCTAssertNil(goal.startDate)
        XCTAssertNil(goal.targetDate)
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
        XCTAssertEqual(goal.expectedTermLength, 10)
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

    // MARK: - SmartGoal Tests

    func testSmartGoalCreation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later

        let smartGoal = SmartGoal(
            friendlyName: "Run 120km in 10 weeks",
            measurementUnit: "km",
            measurementTarget: 120.0,
            startDate: start,
            targetDate: end,
            howGoalIsRelevant: "Build marathon endurance",
            howGoalIsActionable: "Run 3x per week, progressive overload"
        )

        XCTAssertEqual(smartGoal.goalType, "SmartGoal")
        XCTAssertTrue(smartGoal.isValid())
        XCTAssertTrue(smartGoal.isMeasurable())
        XCTAssertTrue(smartGoal.isTimeBound())
    }

    func testSmartGoalInheritance() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        let smartGoal = SmartGoal(
            measurementUnit: "hours",
            measurementTarget: 40.0,
            startDate: start,
            targetDate: end,
            howGoalIsRelevant: "Career development",
            howGoalIsActionable: "Study 1 hour daily"
        )

        // SmartGoal inherits from Goal, verify type hierarchy
        XCTAssertTrue(type(of: smartGoal) == SmartGoal.self)

        // Can access parent's methods
        XCTAssertTrue(smartGoal.isTimeBound())
        XCTAssertTrue(smartGoal.isMeasurable())

        // But has its own goalType
        XCTAssertEqual(smartGoal.goalType, "SmartGoal")
    }

    // MARK: - Milestone Tests

    func testMilestoneCreation() {
        let target = Date().addingTimeInterval(60*60*24*35) // 5 weeks from now

        let milestone = Milestone(
            friendlyName: "Reach 50km by week 5",
            targetDate: target
        )

        XCTAssertEqual(milestone.goalType, "Milestone")
        XCTAssertNotNil(milestone.targetDate)
        XCTAssertNil(milestone.startDate) // Milestones don't have start dates
        XCTAssertTrue(milestone.isValid())
    }

    func testMilestoneValidation() {
        let target = Date().addingTimeInterval(60*60*24*35)

        let milestone = Milestone(
            friendlyName: "Complete chapter 3",
            targetDate: target
        )

        // Valid: has target date, no start date
        XCTAssertTrue(milestone.isValid())

        // Milestone is NOT time-bound (no start date)
        XCTAssertFalse(milestone.isTimeBound())

        // But has target date
        XCTAssertNotNil(milestone.targetDate)
    }

    // MARK: - Polymorphism Tests

    func testGoalPolymorphism() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        // Create different goal types
        let basicGoal: Goal = Goal(friendlyName: "Exercise more")
        let smartGoal: Goal = SmartGoal(
            measurementUnit: "km",
            measurementTarget: 100.0,
            startDate: start,
            targetDate: end,
            howGoalIsRelevant: "Health",
            howGoalIsActionable: "Run regularly"
        )
        let milestone: Goal = Milestone(
            friendlyName: "Hit 50km",
            targetDate: end
        )

        // All are Goals
        let goals: [Goal] = [basicGoal, smartGoal, milestone]
        XCTAssertEqual(goals.count, 3)

        // But have different goalTypes
        XCTAssertEqual(basicGoal.goalType, "Goal")
        XCTAssertEqual(smartGoal.goalType, "SmartGoal")
        XCTAssertEqual(milestone.goalType, "Milestone")

        // All can call parent methods
        for goal in goals {
            XCTAssertNotNil(goal.id)
            _ = goal.isValid() // All can validate
        }
    }
}
