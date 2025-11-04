// GoalValidatorTests.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Test GoalValidator for Phase 1 (form data) and Phase 2 (entity graph) validation.
//
// TESTS TO IMPLEMENT:
//
// Phase 1: Form Data Validation
//  testAcceptsGoalWithTitle
//  testAcceptsGoalWithDescription
//  testRejectsGoalWithoutTitleOrDescription
//  testRejectsInvalidImportance
//  testRejectsInvalidUrgency
//  testRejectsStartDateAfterTargetDate
//  testRejectsNegativeTargetValue
//  testRejectsInvalidAlignmentStrength
//
// Phase 2: Entity Graph Validation
//  testAcceptsValidGoalGraph
//  testRejectsGoalWithWrongExpectationId
//  testRejectsMeasurementWithWrongExpectationId
//  testRejectsRelevanceWithWrongGoalId
//  testRejectsDuplicateMeasurements
//  testRejectsDuplicateRelevances

import XCTest
@testable import Services
@testable import Models

final class GoalValidatorTests: XCTestCase {

    var validator: GoalValidator!

    override func setUp() {
        super.setUp()
        validator = GoalValidator()
    }

    // MARK: - Phase 1: Form Data Validation

    func testAcceptsGoalWithTitle() {
        let formData = GoalFormData(title: "Get healthy")

        XCTAssertNoThrow(try validator.validateFormData(formData))
        // TODO: Implement
    }

    func testRejectsGoalWithoutTitleOrDescription() {
        let formData = GoalFormData(title: nil, description: nil)

        XCTAssertThrowsError(try validator.validateFormData(formData))
        // TODO: Implement
    }

    func testRejectsInvalidImportance() {
        let formData = GoalFormData(title: "Test", importance: 15)

        XCTAssertThrowsError(try validator.validateFormData(formData))
        // TODO: Implement
    }

    func testRejectsStartDateAfterTargetDate() {
        let formData = GoalFormData(
            title: "Test",
            startDate: Date().addingTimeInterval(86400 * 10),
            targetDate: Date()
        )

        XCTAssertThrowsError(try validator.validateFormData(formData))
        // TODO: Implement
    }

    // MARK: - Phase 2: Entity Graph Validation

    func testAcceptsValidGoalGraph() {
        let expectation = Expectation(title: "Health", expectationType: .goal)
        let goal = Goal(expectationId: expectation.id)
        let measurement = ExpectationMeasure(
            expectationId: expectation.id,
            measureId: UUID(),
            targetValue: 120.0
        )
        let relevance = GoalRelevance(goalId: goal.id, valueId: UUID())

        XCTAssertNoThrow(
            try validator.validateComplete((expectation, goal, [measurement], [relevance]))
        )
        // TODO: Implement
    }

    func testRejectsGoalWithWrongExpectationId() {
        let expectation = Expectation(title: "Health", expectationType: .goal)
        let wrongGoal = Goal(expectationId: UUID())  // Different ID!

        XCTAssertThrowsError(
            try validator.validateComplete((expectation, wrongGoal, [], []))
        )
        // TODO: Implement
    }
}

// TESTING STRATEGY:
// - Validate Eisenhower matrix bounds (importance, urgency 1-10)
// - Validate date ranges (start before target)
// - Validate measurement targets (positive values)
// - Validate alignment strengths (1-10 if provided)
// - Validate entity graph consistency (IDs match)
