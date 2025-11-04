// ActionValidator.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Validates Action entities and their related measurements and goal contributions.
// Compensates for type safety loss when using #sql macros for database operations.
//
// ARCHITECTURE POSITION:
// Validation layer - validates Action entity graphs before persistence.
//
// UPSTREAM (calls this):
// - ActionCoordinator.createAction()
// - ActionCoordinator.updateAction()
// - Tests (ActionValidatorTests)
//
// DOWNSTREAM (this calls):
// - ValidationError (throws errors)
//
// ENTITY GRAPH VALIDATED:
// - Action (main entity)
// - MeasuredAction[] (0..n measurements)
// - ActionGoalContribution[] (0..n goal links)
//
// VALIDATION RULES:
//
// Phase 1: validateFormData() - Business Rules
//  Action must have SOME content:
//   - title OR description OR notes (textual content)
//   - OR measurements (quantitative data)
//   - OR goal contributions (purpose/intent)
//   Rationale: Empty actions provide no value
//
//  Duration must be positive (if provided)
//   Rationale: Negative duration is nonsensical
//
//  StartTime must be before logTime (if both provided)
//   Rationale: Can't start after logging
//
// Phase 2: validateComplete() - Referential Integrity
//  All measurements reference correct actionId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//  All contributions reference correct actionId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//  No duplicate measurements for same measure
//   Rationale: Should update existing, not create duplicate
//
// FORM DATA STRUCTURE (from Coordinators/FormData/ActionFormData.swift):
// struct ActionFormData {
//     let title: String                      // Empty string if not provided
//     let detailedDescription: String        // Empty string if not provided
//     let freeformNotes: String             // Empty string if not provided
//     let durationMinutes: Double           // 0 if not provided
//     let startTime: Date                   // Defaults to Date()
//     let measurements: [MeasurementInput]  // (id, measureId?, value)
//     let goalContributions: Set<UUID>      // Goal IDs this action contributes to
// }
//
// USAGE EXAMPLE:
// let validator = ActionValidator()
//
// // Phase 1: Validate form
// try validator.validateFormData(formData)
//
// // Assemble entities
// let action = Action(title: formData.title.isEmpty ? nil : formData.title, ...)
// let measurements = formData.measurements.filter { $0.isValid }.map {
//     MeasuredAction(actionId: action.id, measureId: $0.measureId!, value: $0.value)
// }
// let contributions = formData.goalContributions.map { goalId in
//     ActionGoalContribution(actionId: action.id, goalId: goalId)
// }
//
// // Phase 2: Validate complete graph
// try validator.validateComplete((action, measurements, contributions))
//
// // Safe to persist (handled by ActionCoordinator)
// try await coordinator.create(from: formData)

import Foundation
import Models

// Import existing FormData types from Coordinators
// ActionFormData, MeasurementInput defined in swift/Sources/Services/Coordinators/FormData/
// Note: Using existing FormData pattern:
//   - title, detailedDescription, freeformNotes: String (not String?)
//   - durationMinutes: Double (not Double?)
//   - goalContributions: Set<UUID> (not [GoalLinkInput])

/// Validates Action entities and their relationships
public struct ActionValidator: EntityValidator {

    // MARK: - EntityValidator Conformance

    public typealias FormData = ActionFormData
    public typealias Entity = (Action, [MeasuredAction], [ActionGoalContribution])

    public init() {}

    // MARK: - Phase 1: Form Data Validation

    /// Validates raw form data before model creation
    ///
    /// Business Rules:
    /// - Action must have title, description, notes, measurements, or goal links
    /// - Duration must be positive (if provided)
    /// - StartTime must be before current time (if provided)
    ///
    /// - Parameter formData: Raw form input from UI (ActionFormData from Coordinators)
    /// - Throws: ValidationError if business rules violated
    public func validateFormData(_ formData: ActionFormData) throws {
        // Rule 1: Action must have SOME content
        // Note: Existing FormData uses String (not String?), so check isEmpty
        let hasText = !formData.title.isEmpty ||
                     !formData.detailedDescription.isEmpty ||
                     !formData.freeformNotes.isEmpty
        let hasMeasurements = !formData.measurements.isEmpty
        let hasGoalLinks = !formData.goalContributions.isEmpty

        guard hasText || hasMeasurements || hasGoalLinks else {
            throw ValidationError.emptyAction(
                "Action must have title, description, notes, measurements, or goal links"
            )
        }

        // Rule 2: Duration must be non-negative
        // Note: Existing FormData uses Double (defaults to 0 = "not provided")
        // Coordinator treats 0 as nil, so we only check for negative values
        if formData.durationMinutes < 0 {
            throw ValidationError.invalidExpectation(
                "Duration cannot be negative, got \(formData.durationMinutes) minutes"
            )
        }

        // Rule 3: StartTime should be reasonable (not in future)
        if formData.startTime > Date() {
            throw ValidationError.invalidDateRange(
                "Start time cannot be in the future"
            )
        }
    }

    // MARK: - Phase 2: Complete Entity Validation

    /// Validates assembled entity graph before persistence
    ///
    /// Referential Integrity Checks:
    /// - All measurements reference correct actionId
    /// - All contributions reference correct actionId
    /// - No duplicate measurements for same measure
    ///
    /// - Parameter entities: Complete entity graph (Action, MeasuredAction[], ActionGoalContribution[])
    /// - Throws: ValidationError if graph is inconsistent
    public func validateComplete(_ entities: Entity) throws {
        let (action, measurements, contributions) = entities

        // Check 1: All measurements reference this action
        for measurement in measurements {
            guard measurement.actionId == action.id else {
                throw ValidationError.inconsistentReference(
                    "Measurement \(measurement.id) has actionId \(measurement.actionId) but expected \(action.id)"
                )
            }
        }

        // Check 2: All contributions reference this action
        for contribution in contributions {
            guard contribution.actionId == action.id else {
                throw ValidationError.inconsistentReference(
                    "Contribution \(contribution.id) has actionId \(contribution.actionId) but expected \(action.id)"
                )
            }
        }

        // Check 3: No duplicate measurements
        let measureIds = measurements.map { $0.measureId }
        let uniqueMeasureIds = Set(measureIds)
        guard measureIds.count == uniqueMeasureIds.count else {
            throw ValidationError.duplicateRecord(
                "Action has duplicate measurements for the same measure"
            )
        }
    }
}

// MARK: - Design Notes

// WHY "SOME CONTENT" RULE?
//
// An action with no title, no description, no measurements, and no goal links
// provides no information. It's a data quality issue that should be caught early.
//
// This is a business rule, not a technical constraint. The database schema allows
// all fields to be null, but the business logic requires meaningful data.

// WHY ALLOW MEASUREMENTS-ONLY ACTIONS?
//
// Example: Health data import from Apple Health
// - Action: nil title, nil description
// - Measurement: 5.2km distance
// - Goal link: Marathon training goal
//
// This is valid! The measurement tells us what happened, and the goal link
// provides context. The title is redundant.

// WHY CHECK DUPLICATE MEASUREMENTS?
//
// If user selects "distance" twice in the form, something is wrong.
// Should either:
// - Update the existing measurement
// - Show error in UI (better UX)
//
// Catching this in validator prevents data quality issues.

// FUTURE EXTENSIONS:
//
// - Add validation for measurement values (positive only? range checks?)
// - Add validation for goalId existence (requires database access)
// - Add validation for measureId existence (requires database access)
// - Add warning level for suspicious patterns (e.g., 1000km run)
