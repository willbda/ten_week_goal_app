// GoalValidator.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Validates Goal entities and their related expectation, measurements, and value alignments.
// Compensates for type safety loss when using #sql macros for database operations.
//
// ARCHITECTURE POSITION:
// Validation layer - validates Goal entity graphs before persistence.
//
// UPSTREAM (calls this):
// - GoalCoordinator.createGoal()
// - GoalCoordinator.updateGoal()
// - Tests (GoalValidatorTests)
//
// DOWNSTREAM (this calls):
// - ValidationError (throws errors)
//
// ENTITY GRAPH VALIDATED:
// - Expectation (base entity with title, description, importance, urgency)
// - Goal (subtype with dates, action plan)
// - ExpectationMeasure[] (0..n measurement targets)
// - GoalRelevance[] (0..n value alignments)
//
// VALIDATION RULES:
//
// Phase 1: validateFormData() - Business Rules
//  Expectation must have title OR description
//   Rationale: Goals need textual definition
//
//  Importance must be 1-10
//   Rationale: Eisenhower matrix bounds
//
//  Urgency must be 1-10
//   Rationale: Eisenhower matrix bounds
//
//  StartDate must be before targetDate (if both provided)
//   Rationale: Can't achieve goal before starting
//
//  TargetValue must be positive (for measurements)
//   Rationale: Negative targets are nonsensical
//
//  AlignmentStrength must be 1-10 (if provided)
//   Rationale: Standard alignment scale
//
// Phase 2: validateComplete() - Referential Integrity
//  Goal references correct expectationId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//  All measurements reference correct expectationId
//   Rationale: Measurements belong to expectation, not goal
//
//  All relevances reference correct goalId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//  No duplicate measurements for same measure
//   Rationale: Should update existing, not create duplicate
//
//  No duplicate relevances for same value
//   Rationale: Should update existing, not create duplicate
//
// FORM DATA STRUCTURE:
// struct GoalFormData {
//     // Expectation fields
//     var title: String?
//     var description: String?
//     var notes: String?
//     var importance: Int
//     var urgency: Int
//
//     // Goal fields
//     var startDate: Date?
//     var targetDate: Date?
//     var actionPlan: String?
//     var expectedTermLength: Int?
//
//     // Related entities
//     var measurements: [MeasurementTargetInput]  // (measureId, targetValue)
//     var valueAlignments: [ValueAlignmentInput]  // (valueId, strength, notes)
// }
//
// USAGE EXAMPLE:
// let validator = GoalValidator()
//
// // Phase 1: Validate form
// try validator.validateFormData(formData)
//
// // Assemble entities
// let expectation = Expectation(title: formData.title, ...)
// let goal = Goal(expectationId: expectation.id, ...)
// let measurements = formData.measurements.map { ... }
// let relevances = formData.valueAlignments.map { ... }
//
// // Phase 2: Validate complete graph
// try validator.validateComplete((expectation, goal, measurements, relevances))
//
// // Safe to persist
// try await repository.save(expectation, goal, measurements, relevances)

import Foundation

/// Form data for goal creation/update
public struct GoalFormData {
    // Expectation fields
    public var title: String?
    public var description: String?
    public var notes: String?
    public var importance: Int
    public var urgency: Int

    // Goal fields
    public var startDate: Date?
    public var targetDate: Date?
    public var actionPlan: String?
    public var expectedTermLength: Int?

    // Related entities
    public var measurements: [MeasurementTargetInput]
    public var valueAlignments: [ValueAlignmentInput]

    public init(
        title: String? = nil,
        description: String? = nil,
        notes: String? = nil,
        importance: Int = 8,  // Default for goals
        urgency: Int = 5,     // Default for goals
        startDate: Date? = nil,
        targetDate: Date? = nil,
        actionPlan: String? = nil,
        expectedTermLength: Int? = nil,
        measurements: [MeasurementTargetInput] = [],
        valueAlignments: [ValueAlignmentInput] = []
    ) {
        self.title = title
        self.description = description
        self.notes = notes
        self.importance = importance
        self.urgency = urgency
        self.startDate = startDate
        self.targetDate = targetDate
        self.actionPlan = actionPlan
        self.expectedTermLength = expectedTermLength
        self.measurements = measurements
        self.valueAlignments = valueAlignments
    }
}

/// Measurement target input from form
public struct MeasurementTargetInput {
    public var measureId: UUID
    public var targetValue: Double
    public var notes: String?

    public init(measureId: UUID, targetValue: Double, notes: String? = nil) {
        self.measureId = measureId
        self.targetValue = targetValue
        self.notes = notes
    }
}

/// Value alignment input from form
public struct ValueAlignmentInput {
    public var valueId: UUID
    public var alignmentStrength: Int?
    public var relevanceNotes: String?

    public init(valueId: UUID, alignmentStrength: Int? = nil, relevanceNotes: String? = nil) {
        self.valueId = valueId
        self.alignmentStrength = alignmentStrength
        self.relevanceNotes = relevanceNotes
    }
}

/// Validates Goal entities and their relationships
public struct GoalValidator: EntityValidator {

    // MARK: - EntityValidator Conformance

    public typealias FormData = GoalFormData
    public typealias Entity = (Expectation, Goal, [ExpectationMeasure], [GoalRelevance])

    public init() {}

    // MARK: - Phase 1: Form Data Validation

    /// Validates raw form data before model creation
    ///
    /// Business Rules:
    /// - Expectation must have title or description
    /// - Importance and urgency must be 1-10
    /// - StartDate must be before targetDate
    /// - Target values must be positive
    /// - Alignment strengths must be 1-10
    ///
    /// - Parameter formData: Raw form input from UI
    /// - Throws: ValidationError if business rules violated
    public func validateFormData(_ formData: GoalFormData) throws {
        // Rule 1: Expectation must have title or description
        let hasTitle = formData.title?.isEmpty == false
        let hasDescription = formData.description?.isEmpty == false

        guard hasTitle || hasDescription else {
            throw ValidationError.invalidExpectation(
                "Goal must have a title or description"
            )
        }

        // Rule 2: Importance must be 1-10
        guard (1...10).contains(formData.importance) else {
            throw ValidationError.invalidPriority(
                "Importance must be 1-10, got \(formData.importance)"
            )
        }

        // Rule 3: Urgency must be 1-10
        guard (1...10).contains(formData.urgency) else {
            throw ValidationError.invalidPriority(
                "Urgency must be 1-10, got \(formData.urgency)"
            )
        }

        // Rule 4: StartDate must be before targetDate
        if let start = formData.startDate, let target = formData.targetDate {
            guard start <= target else {
                throw ValidationError.invalidDateRange(
                    "Start date must be before or equal to target date"
                )
            }
        }

        // Rule 5: Target values must be positive
        for measurement in formData.measurements {
            guard measurement.targetValue > 0 else {
                throw ValidationError.invalidExpectation(
                    "Target value must be positive, got \(measurement.targetValue)"
                )
            }
        }

        // Rule 6: Alignment strengths must be 1-10 (if provided)
        for alignment in formData.valueAlignments {
            if let strength = alignment.alignmentStrength {
                guard (1...10).contains(strength) else {
                    throw ValidationError.invalidPriority(
                        "Alignment strength must be 1-10, got \(strength)"
                    )
                }
            }
        }
    }

    // MARK: - Phase 2: Complete Entity Validation

    /// Validates assembled entity graph before persistence
    ///
    /// Referential Integrity Checks:
    /// - Goal references correct expectationId
    /// - All measurements reference correct expectationId
    /// - All relevances reference correct goalId
    /// - No duplicate measurements
    /// - No duplicate relevances
    ///
    /// - Parameter entities: Complete entity graph (Expectation, Goal, ExpectationMeasure[], GoalRelevance[])
    /// - Throws: ValidationError if graph is inconsistent
    public func validateComplete(_ entities: Entity) throws {
        let (expectation, goal, measurements, relevances) = entities

        // Check 1: Goal references correct expectation
        guard goal.expectationId == expectation.id else {
            throw ValidationError.inconsistentReference(
                "Goal.expectationId \(goal.expectationId) does not match Expectation.id \(expectation.id)"
            )
        }

        // Check 2: All measurements reference correct expectation
        for measurement in measurements {
            guard measurement.expectationId == expectation.id else {
                throw ValidationError.inconsistentReference(
                    "ExpectationMeasure \(measurement.id) has expectationId \(measurement.expectationId) but expected \(expectation.id)"
                )
            }
        }

        // Check 3: All relevances reference correct goal
        for relevance in relevances {
            guard relevance.goalId == goal.id else {
                throw ValidationError.inconsistentReference(
                    "GoalRelevance \(relevance.id) has goalId \(relevance.goalId) but expected \(goal.id)"
                )
            }
        }

        // Check 4: No duplicate measurements
        let measureIds = measurements.map { $0.measureId }
        let uniqueMeasureIds = Set(measureIds)
        guard measureIds.count == uniqueMeasureIds.count else {
            throw ValidationError.duplicateRecord(
                "Goal has duplicate measurement targets for the same measure"
            )
        }

        // Check 5: No duplicate relevances
        let valueIds = relevances.map { $0.valueId }
        let uniqueValueIds = Set(valueIds)
        guard valueIds.count == uniqueValueIds.count else {
            throw ValidationError.duplicateRecord(
                "Goal has duplicate alignments to the same value"
            )
        }
    }
}

// MARK: - Design Notes

// WHY REQUIRE TITLE OR DESCRIPTION?
//
// Goals need textual definition for human understanding. Even if you have
// measurements (run 120km), you need narrative intent ("get healthier", "train
// for marathon"). This prevents data quality issues where goals become just numbers.

// WHY EISENHOWER MATRIX (1-10 SCALE)?
//
// Importance + Urgency form the Eisenhower matrix for prioritization:
// - Importance: How much this matters to you (intrinsic value)
// - Urgency: How time-sensitive this is (deadline pressure)
//
// Scale of 1-10 provides enough granularity without overwhelming choice.

// WHY ALLOW ZERO MEASUREMENTS?
//
// Not all goals are quantifiable:
// - "Build better relationship with partner" (qualitative)
// - "Develop technical leadership skills" (emergent)
// - "Explore new creative outlets" (discovery-oriented)
//
// These are valid minimal goals. Measurements are optional.

// WHY ALLOW ZERO VALUE ALIGNMENTS?
//
// User may create goal before defining values, or goal may be exploratory
// (discovering what you value). Alignment can be established later.

// PHASE 2 CATCHES ASSEMBLY BUGS
//
// Example bug caught:
// let expectation = Expectation(id: UUID())
// let goal = Goal(expectationId: UUID())  // Oops! Wrong ID!
//
// validateComplete() catches this before database write.

// FUTURE EXTENSIONS:
//
// - Add validation for measureId existence (requires database access)
// - Add validation for valueId existence (requires database access)
// - Add warning for goals with no measurements AND no relevances (low quality)
// - Add validation for term length reasonableness (1-52 weeks?)
