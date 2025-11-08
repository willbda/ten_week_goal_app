//
// ValidatorComprehensiveTests.swift
// Written by Claude Code on 2025-11-05
//
// PURPOSE:
// Comprehensive validation tests to prove validators work BEFORE wiring to coordinators.
// Tests every validation rule documented in each validator.
//
// STRATEGY:
// For each validator, test:
// 1. Every rule that should PASS
// 2. Every rule that should FAIL
// 3. Boundary conditions
// 4. Error messages are meaningful
//
// NO DATABASE - Pure validation logic only

import Testing
@testable import Services
@testable import Models

// MARK: - ActionValidator Comprehensive Tests

@Suite("ActionValidator - Comprehensive Validation")
struct ActionValidatorComprehensiveTests {

    let validator = ActionValidator()

    // MARK: Phase 1 - Form Data Validation

    @Test("PASS: Action with only title")
    func actionWithOnlyTitle() throws {
        let formData = ActionFormData(title: "Morning run")

        try validator.validateFormData(formData)  // Should not throw
    }

    @Test("PASS: Action with only description")
    func actionWithOnlyDescription() throws {
        let formData = ActionFormData(detailedDescription: "Went for a run")

        try validator.validateFormData(formData)
    }

    @Test("PASS: Action with only notes")
    func actionWithOnlyNotes() throws {
        let formData = ActionFormData(freeformNotes: "Great weather today")

        try validator.validateFormData(formData)
    }

    @Test("PASS: Action with only measurements")
    func actionWithOnlyMeasurements() throws {
        let formData = ActionFormData(
            title: "",
            measurements: [MeasurementInput(measureId: UUID(), value: 5.0)]
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Action with only goal contributions")
    func actionWithOnlyGoalContributions() throws {
        let formData = ActionFormData(
            title: "",
            goalContributions: [UUID()]
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Action with zero duration (not provided)")
    func actionWithZeroDuration() throws {
        let formData = ActionFormData(
            title: "Test",
            durationMinutes: 0
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Action with positive duration")
    func actionWithPositiveDuration() throws {
        let formData = ActionFormData(
            title: "Test",
            durationMinutes: 30.5
        )

        try validator.validateFormData(formData)
    }

    @Test("FAIL: Completely empty action")
    func completelyEmptyAction() {
        let formData = ActionFormData(
            title: "",
            detailedDescription: "",
            freeformNotes: "",
            measurements: [],
            goalContributions: []
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }

        // Verify specific error type
        do {
            try validator.validateFormData(formData)
            Issue.record("Expected ValidationError.emptyAction")
        } catch let error as ValidationError {
            if case .emptyAction(let message) = error {
                #expect(message.contains("title") || message.contains("description"))
            } else {
                Issue.record("Expected .emptyAction, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("FAIL: Negative duration")
    func negativeDuration() {
        let formData = ActionFormData(
            title: "Test",
            durationMinutes: -10.0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }

        do {
            try validator.validateFormData(formData)
            Issue.record("Expected ValidationError.invalidExpectation")
        } catch let error as ValidationError {
            if case .invalidExpectation(let message) = error {
                #expect(message.contains("negative") || message.contains("Duration"))
            } else {
                Issue.record("Expected .invalidExpectation, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("FAIL: Start time in future")
    func startTimeInFuture() {
        let futureDate = Date().addingTimeInterval(3600)  // 1 hour from now
        let formData = ActionFormData(
            title: "Test",
            startTime: futureDate
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }

        do {
            try validator.validateFormData(formData)
            Issue.record("Expected ValidationError.invalidDateRange")
        } catch let error as ValidationError {
            if case .invalidDateRange(let message) = error {
                #expect(message.contains("future") || message.contains("Start"))
            } else {
                Issue.record("Expected .invalidDateRange, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: Phase 2 - Complete Entity Validation

    @Test("PASS: Valid entity graph")
    func validEntityGraph() throws {
        let action = Action(title: "Run")
        let measurement = MeasuredAction(
            actionId: action.id,
            measureId: UUID(),
            value: 5.0
        )
        let contribution = ActionGoalContribution(
            actionId: action.id,
            goalId: UUID()
        )

        try validator.validateComplete((action, [measurement], [contribution]))
    }

    @Test("PASS: Action with no measurements or contributions")
    func actionWithNoRelationships() throws {
        let action = Action(title: "Run")

        try validator.validateComplete((action, [], []))
    }

    @Test("FAIL: Measurement with wrong actionId")
    func measurementWithWrongActionId() {
        let action = Action(title: "Run")
        let wrongMeasurement = MeasuredAction(
            actionId: UUID(),  // Different ID!
            measureId: UUID(),
            value: 5.0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((action, [wrongMeasurement], []))
        }

        do {
            try validator.validateComplete((action, [wrongMeasurement], []))
            Issue.record("Expected ValidationError.inconsistentReference")
        } catch let error as ValidationError {
            if case .inconsistentReference(let message) = error {
                #expect(message.contains("actionId") || message.contains("Measurement"))
            } else {
                Issue.record("Expected .inconsistentReference, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("FAIL: Contribution with wrong actionId")
    func contributionWithWrongActionId() {
        let action = Action(title: "Run")
        let wrongContribution = ActionGoalContribution(
            actionId: UUID(),  // Different ID!
            goalId: UUID()
        )

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((action, [], [wrongContribution]))
        }
    }

    @Test("FAIL: Duplicate measurements for same measure")
    func duplicateMeasurements() {
        let action = Action(title: "Run")
        let measureId = UUID()
        let measurement1 = MeasuredAction(actionId: action.id, measureId: measureId, value: 5.0)
        let measurement2 = MeasuredAction(actionId: action.id, measureId: measureId, value: 3.0)

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((action, [measurement1, measurement2], []))
        }

        do {
            try validator.validateComplete((action, [measurement1, measurement2], []))
            Issue.record("Expected ValidationError.duplicateRecord")
        } catch let error as ValidationError {
            if case .duplicateRecord(let message) = error {
                #expect(message.contains("duplicate") || message.contains("measure"))
            } else {
                Issue.record("Expected .duplicateRecord, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - GoalValidator Comprehensive Tests

@Suite("GoalValidator - Comprehensive Validation")
struct GoalValidatorComprehensiveTests {

    let validator = GoalValidator()

    // MARK: Phase 1 - Form Data Validation

    @Test("PASS: Goal with only title")
    func goalWithOnlyTitle() throws {
        let formData = GoalFormData(title: "Run a marathon")

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with only description")
    func goalWithOnlyDescription() throws {
        let formData = GoalFormData(
            title: "",
            detailedDescription: "Complete 26.2 miles"
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with importance=1 (boundary)")
    func goalWithMinimumImportance() throws {
        let formData = GoalFormData(
            title: "Test",
            expectationImportance: 1
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with importance=10 (boundary)")
    func goalWithMaximumImportance() throws {
        let formData = GoalFormData(
            title: "Test",
            expectationImportance: 10
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with urgency=1 (boundary)")
    func goalWithMinimumUrgency() throws {
        let formData = GoalFormData(
            title: "Test",
            expectationUrgency: 1
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with urgency=10 (boundary)")
    func goalWithMaximumUrgency() throws {
        let formData = GoalFormData(
            title: "Test",
            expectationUrgency: 10
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with same start and target date")
    func goalWithSameDates() throws {
        let date = Date()
        let formData = GoalFormData(
            title: "Test",
            startDate: date,
            targetDate: date
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with valid date range")
    func goalWithValidDateRange() throws {
        let start = Date()
        let target = start.addingTimeInterval(86400 * 7)  // 1 week later
        let formData = GoalFormData(
            title: "Test",
            startDate: start,
            targetDate: target
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with positive metric targets")
    func goalWithPositiveTargets() throws {
        let formData = GoalFormData(
            title: "Test",
            metricTargets: [
                MetricTargetInput(measureId: UUID(), targetValue: 120.0),
                MetricTargetInput(measureId: UUID(), targetValue: 0.1)  // Small but positive
            ]
        )

        try validator.validateFormData(formData)
    }

    @Test("PASS: Goal with valid alignment strengths")
    func goalWithValidAlignments() throws {
        let formData = GoalFormData(
            title: "Test",
            valueAlignments: [
                ValueAlignmentInput(valueId: UUID(), alignmentStrength: 1),   // Min
                ValueAlignmentInput(valueId: UUID(), alignmentStrength: 10),  // Max
                ValueAlignmentInput(valueId: UUID(), alignmentStrength: nil)  // Optional
            ]
        )

        try validator.validateFormData(formData)
    }

    @Test("FAIL: Goal with neither title nor description")
    func goalWithNoContent() {
        let formData = GoalFormData(
            title: "",
            detailedDescription: ""
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }

        do {
            try validator.validateFormData(formData)
            Issue.record("Expected ValidationError.invalidExpectation")
        } catch let error as ValidationError {
            if case .invalidExpectation(let message) = error {
                #expect(message.contains("title") || message.contains("description"))
            } else {
                Issue.record("Expected .invalidExpectation, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("FAIL: Goal with importance=0")
    func goalWithZeroImportance() {
        let formData = GoalFormData(
            title: "Test",
            expectationImportance: 0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("FAIL: Goal with importance=11")
    func goalWithExcessiveImportance() {
        let formData = GoalFormData(
            title: "Test",
            expectationImportance: 11
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("FAIL: Goal with urgency=0")
    func goalWithZeroUrgency() {
        let formData = GoalFormData(
            title: "Test",
            expectationUrgency: 0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("FAIL: Goal with start date after target date")
    func goalWithInvertedDates() {
        let target = Date()
        let start = target.addingTimeInterval(86400)  // 1 day after
        let formData = GoalFormData(
            title: "Test",
            startDate: start,
            targetDate: target
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }

        do {
            try validator.validateFormData(formData)
            Issue.record("Expected ValidationError.invalidDateRange")
        } catch let error as ValidationError {
            if case .invalidDateRange(let message) = error {
                #expect(message.contains("before") || message.contains("date"))
            } else {
                Issue.record("Expected .invalidDateRange, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("FAIL: Goal with zero target value")
    func goalWithZeroTarget() {
        let formData = GoalFormData(
            title: "Test",
            metricTargets: [
                MetricTargetInput(measureId: UUID(), targetValue: 0.0)
            ]
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("FAIL: Goal with negative target value")
    func goalWithNegativeTarget() {
        let formData = GoalFormData(
            title: "Test",
            metricTargets: [
                MetricTargetInput(measureId: UUID(), targetValue: -120.0)
            ]
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("FAIL: Goal with alignment strength=0")
    func goalWithZeroAlignmentStrength() {
        let formData = GoalFormData(
            title: "Test",
            valueAlignments: [
                ValueAlignmentInput(valueId: UUID(), alignmentStrength: 0)
            ]
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    @Test("FAIL: Goal with alignment strength=11")
    func goalWithExcessiveAlignmentStrength() {
        let formData = GoalFormData(
            title: "Test",
            valueAlignments: [
                ValueAlignmentInput(valueId: UUID(), alignmentStrength: 11)
            ]
        )

        #expect(throws: ValidationError.self) {
            try validator.validateFormData(formData)
        }
    }

    // MARK: Phase 2 - Complete Entity Validation

    @Test("PASS: Valid goal entity graph")
    func validGoalGraph() throws {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let goal = Goal(expectationId: expectation.id)

        try validator.validateComplete((expectation, goal, [], []))
    }

    @Test("PASS: Goal with targets and relevances")
    func goalWithRelationships() throws {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let goal = Goal(expectationId: expectation.id)
        let measure = ExpectationMeasure(
            expectationId: expectation.id,
            measureId: UUID(),
            targetValue: 120.0
        )
        let relevance = GoalRelevance(
            goalId: goal.id,
            valueId: UUID()
        )

        try validator.validateComplete((expectation, goal, [measure], [relevance]))
    }

    @Test("FAIL: Goal with wrong expectationId")
    func goalWithWrongExpectationId() {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let wrongGoal = Goal(expectationId: UUID())  // Different ID!

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, wrongGoal, [], []))
        }
    }

    @Test("FAIL: ExpectationMeasure with wrong expectationId")
    func measureWithWrongExpectationId() {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let goal = Goal(expectationId: expectation.id)
        let wrongMeasure = ExpectationMeasure(
            expectationId: UUID(),  // Different ID!
            measureId: UUID(),
            targetValue: 120.0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, goal, [wrongMeasure], []))
        }
    }

    @Test("FAIL: GoalRelevance with wrong goalId")
    func relevanceWithWrongGoalId() {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let goal = Goal(expectationId: expectation.id)
        let wrongRelevance = GoalRelevance(
            goalId: UUID(),  // Different ID!
            valueId: UUID()
        )

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, goal, [], [wrongRelevance]))
        }
    }

    @Test("FAIL: Duplicate metric targets")
    func duplicateMetricTargets() {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let goal = Goal(expectationId: expectation.id)
        let measureId = UUID()
        let measure1 = ExpectationMeasure(
            expectationId: expectation.id,
            measureId: measureId,
            targetValue: 120.0
        )
        let measure2 = ExpectationMeasure(
            expectationId: expectation.id,
            measureId: measureId,
            targetValue: 100.0
        )

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, goal, [measure1, measure2], []))
        }
    }

    @Test("FAIL: Duplicate value alignments")
    func duplicateValueAlignments() {
        let expectation = Expectation(
            title: "Test",
            expectationType: .goal,
            expectationImportance: 8,
            expectationUrgency: 5
        )
        let goal = Goal(expectationId: expectation.id)
        let valueId = UUID()
        let relevance1 = GoalRelevance(goalId: goal.id, valueId: valueId)
        let relevance2 = GoalRelevance(goalId: goal.id, valueId: valueId)

        #expect(throws: ValidationError.self) {
            try validator.validateComplete((expectation, goal, [], [relevance1, relevance2]))
        }
    }
}

// MARK: - Summary Report

/*
 VALIDATION COVERAGE REPORT

 ActionValidator:
 ✓ Phase 1: 10 tests (7 pass scenarios, 3 fail scenarios)
 ✓ Phase 2: 5 tests (2 pass scenarios, 3 fail scenarios)

 GoalValidator:
 ✓ Phase 1: 17 tests (9 pass scenarios, 8 fail scenarios)
 ✓ Phase 2: 7 tests (2 pass scenarios, 5 fail scenarios)

 Total: 39 comprehensive tests

 NEXT STEPS:
 1. Run: swift test --filter ValidatorComprehensiveTests
 2. Fix any failing tests
 3. Add TermValidator and ValueValidator tests (similar pattern)
 4. Once all green, wire validators to coordinators
 */
