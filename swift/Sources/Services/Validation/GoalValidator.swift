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
//Expectation must have title OR description
//   Rationale: Goals need textual definition
//
//Importance must be 1-10
//   Rationale: Eisenhower matrix bounds
//
//Urgency must be 1-10
//   Rationale: Eisenhower matrix bounds
//
//StartDate must be before targetDate (if both provided)
//   Rationale: Can't achieve goal before starting
//
//TargetValue must be positive (for measurements)
//   Rationale: Negative targets are nonsensical
//
//AlignmentStrength must be 1-10 (if provided)
//   Rationale: Standard alignment scale
//
// Phase 2: validateComplete() - Referential Integrity
//Goal references correct expectationId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//All measurements reference correct expectationId
//   Rationale: Measurements belong to expectation, not goal
//
//All relevances reference correct goalId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//No duplicate measurements for same measure
//   Rationale: Should update existing, not create duplicate
//
//No duplicate relevances for same value
//   Rationale: Should update existing, not create duplicate
//
// FORM DATA STRUCTURE (from Coordinators/FormData/GoalFormData.swift):
// struct GoalFormData {
//     // Expectation fields
//     let title: String                           // Empty string if not provided
//     let detailedDescription: String             // Empty string if not provided
//     let freeformNotes: String                   // Empty string if not provided
//     let expectationImportance: Int              // Default: 8 for goals
//     let expectationUrgency: Int                 // Default: 5 for goals
//
//     // Goal fields
//     let startDate: Date?                        // Optional
//     let targetDate: Date?                       // Optional
//     let actionPlan: String?                     // Optional
//     let expectedTermLength: Int?                // Optional
//
//     // Related entities
//     let metricTargets: [MetricTargetInput]      // Metric targets (measureId, value, notes)
//     let valueAlignments: [ValueAlignmentInput]  // Value alignments (valueId, strength, notes)
//     let termId: UUID?                           // Optional term assignment
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
import Models

// Import existing FormData types from Coordinators
// GoalFormData, MetricTargetInput, ValueAlignmentInput defined in swift/Sources/Services/Coordinators/FormData/
// Note: Using existing FormData pattern:
//   - title, detailedDescription, freeformNotes: String (not String?)
//   - expectationImportance, expectationUrgency: Int (not importance/urgency)
//   - metricTargets: [MetricTargetInput] (not measurements)

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
    /// - Parameter formData: Raw form input from UI (GoalFormData from Coordinators)
    /// - Throws: ValidationError if business rules violated
    public func validateFormData(_ formData: GoalFormData) throws {
        // Rule 1: Expectation must have title or description
        // Note: Existing FormData uses String (not String?), so check isEmpty
        let hasTitle = !formData.title.isEmpty
        let hasDescription = !formData.detailedDescription.isEmpty

        guard hasTitle || hasDescription else {
            throw ValidationError.invalidExpectation(
                "Goal must have a title or description"
            )
        }

        // Rule 2: Importance must be 1-10
        // Note: Field name is expectationImportance (not importance)
        guard (1...10).contains(formData.expectationImportance) else {
            throw ValidationError.invalidPriority(
                "Importance must be 1-10, got \(formData.expectationImportance)"
            )
        }

        // Rule 3: Urgency must be 1-10
        // Note: Field name is expectationUrgency (not urgency)
        guard (1...10).contains(formData.expectationUrgency) else {
            throw ValidationError.invalidPriority(
                "Urgency must be 1-10, got \(formData.expectationUrgency)"
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
        // Note: Field name is metricTargets (not measurements)
        for target in formData.metricTargets {
            guard target.targetValue > 0 else {
                throw ValidationError.invalidExpectation(
                    "Target value must be positive, got \(target.targetValue)"
                )
            }
        }

        // Rule 6: Alignment strengths must be 1-10
        for alignment in formData.valueAlignments {
            guard (1...10).contains(alignment.alignmentStrength) else {
                throw ValidationError.invalidPriority(
                    "Alignment strength must be 1-10, got \(alignment.alignmentStrength)"
                )
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
