// GoalTests.swift
// Tests for Goal domain entity (consolidated Goal + SMART validation)
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (consolidated Goal/SmartGoal)
// Updated 2025-10-21: Converted to modern Swift Testing framework
// Ported from Python implementation (python/tests/test_goals.py)

import Foundation
import Testing
@testable import Models

/// Test suite for Goal domain entity
///
/// Verifies goal creation, SMART validation, and polymorphic subtypes (Goal, Milestone).
@Suite("Goal Tests")
struct GoalTests {

    // MARK: - Basic Goal Creation & Defaults

    @Test("Creates minimal goal with defaults")
    func minimalGoalCreation() {
        let goal = Goal(title: "Run more often")

        #expect(goal.title == "Run more often")
        #expect(goal.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(goal.logTime != nil)
        #expect(goal.polymorphicSubtype == "goal")

        // All goal-specific fields should be nil
        #expect(goal.measurementUnit == nil)
        #expect(goal.measurementTarget == nil)
        #expect(goal.startDate == nil)
        #expect(goal.targetDate == nil)

        // Minimal goal is valid but not SMART
        #expect(goal.isValid())
        #expect(!goal.isSmart())
    }

    @Test("Creates fully populated goal")
    func fullyPopulatedGoal() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later

        let goal = Goal(
            title: "Complete training program",
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

        #expect(goal.isValid())
        #expect(goal.isMeasurable())
        #expect(goal.isTimeBound())
        #expect(goal.isSmart())  // All SMART fields present
        #expect(goal.expectedTermLength == 10)
    }

    // MARK: - SMART Validation Tests

    @Test("Validates SMART-compliant goal")
    func smartGoalValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later

        // Fully SMART-compliant goal
        let smartGoal = Goal(
            title: "Run 120km in 10 weeks",
            measurementUnit: "km",
            measurementTarget: 120.0,
            startDate: start,
            targetDate: end,
            howGoalIsRelevant: "Build marathon endurance",
            howGoalIsActionable: "Run 3x per week, progressive overload"
        )

        #expect(smartGoal.isSmart())
        #expect(smartGoal.isValid())
        #expect(smartGoal.isMeasurable())
        #expect(smartGoal.isTimeBound())
    }

    @Test("Partial goal is not SMART-compliant")
    func partialGoalNotSmart() {
        // Missing SMART fields = not SMART compliant
        let partialGoal = Goal(
            title: "Run more",
            measurementUnit: "km",
            measurementTarget: 100.0
            // Missing: dates and SMART enhancement fields
        )

        #expect(partialGoal.isValid())  // Still structurally valid
        #expect(partialGoal.isMeasurable())  // Has measurement
        #expect(!partialGoal.isTimeBound())  // No dates
        #expect(!partialGoal.isSmart())  // Not SMART compliant
    }

    // MARK: - Goal Validation Rules

    @Test("Validates positive measurement target")
    func goalMeasurementValidationPositive() {
        let validGoal = Goal(
            measurementUnit: "km",
            measurementTarget: 50.0
        )
        #expect(validGoal.isValid())
        #expect(validGoal.isMeasurable())
    }

    @Test("Rejects negative measurement target")
    func goalMeasurementValidationNegative() {
        let invalidGoal = Goal(
            measurementUnit: "km",
            measurementTarget: -10.0
        )
        #expect(!invalidGoal.isValid())
    }

    @Test("Rejects zero measurement target")
    func goalMeasurementValidationZero() {
        let zeroGoal = Goal(
            measurementUnit: "km",
            measurementTarget: 0.0
        )
        #expect(!zeroGoal.isValid())
    }

    @Test("Validates start date before end date")
    func goalDateValidationValid() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*10) // 10 days later

        let validGoal = Goal(startDate: start, targetDate: end)
        #expect(validGoal.isValid())
        #expect(validGoal.isTimeBound())
    }

    @Test("Rejects start date after end date")
    func goalDateValidationInvalidOrder() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*10) // 10 days later

        let invalidGoal = Goal(startDate: end, targetDate: start)
        #expect(!invalidGoal.isValid())
    }

    @Test("Rejects start date equal to end date")
    func goalDateValidationEqual() {
        let sameDate = Date()
        let equalGoal = Goal(startDate: sameDate, targetDate: sameDate)
        #expect(!equalGoal.isValid())
    }

    // MARK: - Milestone Tests

    @Test("Creates milestone with target date")
    func milestoneCreation() {
        let target = Date().addingTimeInterval(60*60*24*35) // 5 weeks from now

        let milestone = Milestone(
            title: "Reach 50km by week 5",
            targetDate: target
        )

        #expect(milestone.polymorphicSubtype == "milestone")
        #expect(milestone.targetDate != nil)
        #expect(milestone.startDate == nil) // Milestones can optionally have start dates
        #expect(milestone.isValid())
    }

    @Test("Validates milestone with target date")
    func milestoneValidationValid() {
        let target = Date().addingTimeInterval(60*60*24*35)

        let validMilestone = Milestone(
            title: "Complete chapter 3",
            targetDate: target
        )
        #expect(validMilestone.isValid())
    }

    @Test("Rejects milestone without target date")
    func milestoneValidationMissingTarget() {
        let invalidMilestone = Milestone(
            title: "No target date"
            // targetDate is nil
        )
        #expect(!invalidMilestone.isValid())
    }

    @Test("Creates milestone with measurement")
    func milestoneWithMeasurement() {
        let target = Date().addingTimeInterval(60*60*24*35)

        let milestone = Milestone(
            title: "Hit 50km by week 5",
            measurementUnit: "km",
            measurementTarget: 50.0,
            targetDate: target
        )

        #expect(milestone.isValid())
        #expect(milestone.measurementTarget != nil)
        #expect(milestone.measurementUnit != nil)
    }
}
