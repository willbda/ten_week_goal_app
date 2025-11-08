import Foundation
// GoalValidatorTests.swift
// Written by Claude Code on 2025-11-04
// Updated by Claude Code on 2025-11-04 (migrated to Swift Testing)
//
// PURPOSE:
// Test GoalValidator for Phase 1 (form data) and Phase 2 (entity graph) validation.
//
// TESTS TO IMPLEMENT:
//
// Phase 1: Form Data Validation
//  testAcceptsGoalWithTitle
//  testAcceptsGoalWithDescription
//  testRejectsGoalWithoutTitleOrDescription
//  testRejectsInvalidImportance
//  testRejectsInvalidUrgency
//  testRejectsStartDateAfterTargetDate
//  testRejectsNegativeTargetValue
//  testRejectsInvalidAlignmentStrength
//
// Phase 2: Entity Graph Validation
//  testAcceptsValidGoalGraph
//  testRejectsGoalWithWrongExpectationId
//  testRejectsMeasurementWithWrongExpectationId
//  testRejectsRelevanceWithWrongGoalId
//  testRejectsDuplicateMeasurements
//  testRejectsDuplicateRelevances

import Testing
@testable import Services
@testable import Models

@Suite("GoalValidator Tests")
struct GoalValidatorTests {

    // MARK: - Phase 1: Form Data Validation

    @Test("Accepts goal with title")
    func acceptsGoalWithTitle() {
        let validator = GoalValidator()
        let formData = GoalFormData(title: "Get healthy")

        #expect(throws: Never.self) {
            try validator.validateFormData(formData)
        }
        // TODO: Implement
    }

    @Test("Rejects goal without title or description")
    func rejectsGoalWithoutTitleOrDescription() {
        let validator = GoalValidator()
        let formData = GoalFormData(title: "", detailedDescription: "")

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
        // TODO: Implement
    }

    @Test("Rejects invalid importance (out of 1-10 range)")
    func rejectsInvalidImportance() {
        let validator = GoalValidator()
        let formData = GoalFormData(title: "Test", expectationImportance: 15)

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
        // TODO: Implement
    }

    @Test("Rejects start date after target date")
    func rejectsStartDateAfterTargetDate() {
        let validator = GoalValidator()
        let formData = GoalFormData(
            title: "Test",
            startDate: Date().addingTimeInterval(86400 * 10),
            targetDate: Date()
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
        // TODO: Implement
    }

    @Test("Validates importance within range", arguments: [1, 5, 10])
    func validatesImportanceWithinRange(importance: Int) {
        let validator = GoalValidator()
        let formData = GoalFormData(title: "Test", expectationImportance: importance)

        #expect(throws: Never.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("Validates urgency within range", arguments: [1, 5, 10])
    func validatesUrgencyWithinRange(urgency: Int) {
        let validator = GoalValidator()
        let formData = GoalFormData(title: "Test", expectationUrgency: urgency)

        #expect(throws: Never.self) {
            try validator.validateFormData(formData)
        }
    }

    // MARK: - Phase 2: Entity Graph Validation

    @Test("Accepts valid goal graph")
    func acceptsValidGoalGraph() {
        let validator = GoalValidator()
        let expectation = Expectation(title: "Health", expectationType: .goal)
        let goal = Goal(expectationId: expectation.id)
        let measurement = ExpectationMeasure(
            expectationId: expectation.id,
            measureId: UUID(),
            targetValue: 120.0
        )
        let relevance = GoalRelevance(goalId: goal.id, valueId: UUID())

        #expect(throws: Never.self) {
            try validator.validateComplete((expectation, goal, [measurement], [relevance]))
        }
        // TODO: Implement
    }

    @Test("Rejects goal with wrong expectation ID")
    func rejectsGoalWithWrongExpectationId() {
        let validator = GoalValidator()
        let expectation = Expectation(title: "Health", expectationType: .goal)
        let wrongGoal = Goal(expectationId: UUID())  // Different ID!

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, wrongGoal, [], []))
        }
        // TODO: Implement
    }

    @Test("Rejects measurement with wrong expectation ID")
    func rejectsMeasurementWithWrongExpectationId() {
        let validator = GoalValidator()
        let expectation = Expectation(title: "Health", expectationType: .goal)
        let goal = Goal(expectationId: expectation.id)
        let wrongMeasurement = ExpectationMeasure(
            expectationId: UUID(),  // Different ID!
            measureId: UUID(),
            targetValue: 120.0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, goal, [wrongMeasurement], []))
        }
        // TODO: Implement
    }
}

// TESTING STRATEGY:
// - Validate Eisenhower matrix bounds (importance, urgency 1-10)
// - Validate date ranges (start before target)
// - Validate measurement targets (positive values)
// - Validate alignment strengths (1-10 if provided)
// - Validate entity graph consistency (IDs match)
//
// SWIFT TESTING BENEFITS:
//  - Parameterized tests for range validation
//  - Clear test descriptions
//  - #expect(throws:) for error cases
//  - No setUp/tearDown overhead
