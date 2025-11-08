// TermValidator.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Validates Term entities and their temporal boundaries and goal assignments.
// Compensates for type safety loss when using #sql macros for database operations.
//
// ARCHITECTURE POSITION:
// Validation layer - validates Term entity graphs before persistence.
//
// UPSTREAM (calls this):
// - TermCoordinator.createTerm()
// - TermCoordinator.updateTerm()
// - Tests (TermValidatorTests)
//
// DOWNSTREAM (this calls):
// - ValidationError (throws errors)
//
// ENTITY GRAPH VALIDATED:
// - TimePeriod (temporal boundaries with start/end dates)
// - GoalTerm (term with number, theme, status)
// - TermGoalAssignment[] (0..n goal assignments)
//
// VALIDATION RULES:
//
// Phase 1: validateFormData() - Business Rules
//TimePeriod must have startDate before endDate
//   Rationale: Temporal boundary must be logically consistent
//
//Term number must be positive
//   Rationale: Terms are sequentially numbered (Term 1, 2, 3...)
//
//Status must be valid enum value (handled by Swift type system)
//   Note: This is compile-time checked, kept here for completeness
//
// Phase 2: validateComplete() - Referential Integrity
//GoalTerm references correct timePeriodId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//All assignments reference correct termId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//No duplicate goal assignments
//   Rationale: Same goal shouldn't appear twice in term
//
// FORM DATA STRUCTURE (from Coordinators/FormData/TimePeriodFormData.swift):
// struct TimePeriodFormData {
//     let title: String?                              // Optional
//     let detailedDescription: String?                // Optional
//     let freeformNotes: String?                      // Optional
//     let startDate: Date                             // Required
//     let targetDate: Date                            // Required (not endDate!)
//     let specialization: TimePeriodSpecialization    // Enum: .term(number), .year(yearNumber), .custom
//
//     // GoalTerm-specific fields (used when specialization = .term)
//     let theme: String?                              // Optional
//     let reflection: String?                         // Optional
//     let status: TermStatus?                         // Optional
// }
//
// Note: Goal assignments (TermGoalAssignment) are handled separately,
// not part of creation FormData. They're added after term creation.
//
// USAGE EXAMPLE:
// let validator = TermValidator()
//
// // Create FormData with term specialization
// let formData = TimePeriodFormData(
//     title: "Term 5",
//     startDate: Date(),
//     targetDate: Date().addingTimeInterval(86400 * 70),  // 10 weeks
//     specialization: .term(number: 5),
//     theme: "Health and momentum",
//     status: .planned
// )
//
// // Phase 1: Validate form
// try validator.validateFormData(formData)
//
// // Assemble entities (handled by TimePeriodCoordinator)
// try await coordinator.create(from: formData)
//
// // Goal assignments are added separately after term creation:
// let assignment = TermGoalAssignment(termId: goalTerm.id, goalId: goalId)
//
// // Phase 2: Validate complete graph (with assignments)
// try validator.validateComplete((timePeriod, goalTerm, assignments))

import Foundation
import Models

// Import existing FormData types from Coordinators
// TimePeriodFormData, TimePeriodSpecialization defined in swift/Sources/Services/Coordinators/FormData/
// Note: Using existing FormData pattern:
//   - Works with TimePeriod + GoalTerm atomically via specialization enum
//   - targetDate (not endDate) for consistency with Goal terminology
//   - Goal assignments (TermGoalAssignment) handled separately after creation

/// Validates Term entities and their relationships
public struct TermValidator: EntityValidator {

    // MARK: - EntityValidator Conformance

    public typealias FormData = TimePeriodFormData
    public typealias Entity = (TimePeriod, GoalTerm, [TermGoalAssignment])

    public init() {}

    // MARK: - Phase 1: Form Data Validation

    /// Validates raw form data before model creation
    ///
    /// Business Rules:
    /// - StartDate must be before targetDate
    /// - Term number must be positive (extracted from specialization enum)
    /// - Must be a term specialization (not year or custom)
    ///
    /// - Parameter formData: Raw form input from UI (TimePeriodFormData from Coordinators)
    /// - Throws: ValidationError if business rules violated
    public func validateFormData(_ formData: TimePeriodFormData) throws {
        // Rule 1: StartDate must be before targetDate
        // Note: Existing FormData uses targetDate (not endDate)
        guard formData.startDate < formData.targetDate else {
            throw ValidationError.invalidDateRange(
                "Start date must be before target date"
            )
        }

        // Rule 2: Must be a term specialization with valid term number
        // Extract term number from specialization enum
        guard case .term(let termNumber) = formData.specialization else {
            throw ValidationError.invalidExpectation(
                "TimePeriodFormData must have .term specialization for TermValidator"
            )
        }

        // Rule 3: Term number must be positive
        guard termNumber > 0 else {
            throw ValidationError.invalidExpectation(
                "Term number must be positive, got \(termNumber)"
            )
        }
    }

    // MARK: - Phase 2: Complete Entity Validation

    /// Validates assembled entity graph before persistence
    ///
    /// Referential Integrity Checks:
    /// - GoalTerm references correct timePeriodId
    /// - All assignments reference correct termId
    /// - No duplicate goal assignments
    ///
    /// - Parameter entities: Complete entity graph (TimePeriod, GoalTerm, TermGoalAssignment[])
    /// - Throws: ValidationError if graph is inconsistent
    public func validateComplete(_ entities: Entity) throws {
        let (timePeriod, goalTerm, assignments) = entities

        // Check 1: GoalTerm references correct timePeriod
        guard goalTerm.timePeriodId == timePeriod.id else {
            throw ValidationError.inconsistentReference(
                "GoalTerm.timePeriodId \(goalTerm.timePeriodId) does not match TimePeriod.id \(timePeriod.id)"
            )
        }

        // Check 2: All assignments reference correct term
        for assignment in assignments {
            guard assignment.termId == goalTerm.id else {
                throw ValidationError.inconsistentReference(
                    "TermGoalAssignment \(assignment.id) has termId \(assignment.termId) but expected \(goalTerm.id)"
                )
            }
        }

        // Check 3: No duplicate goal assignments
        let goalIds = assignments.map { $0.goalId }
        let uniqueGoalIds = Set(goalIds)
        guard goalIds.count == uniqueGoalIds.count else {
            throw ValidationError.duplicateRecord(
                "Term has duplicate assignments for the same goal"
            )
        }
    }
}

// MARK: - Design Notes

// WHY SEPARATE TIMEPERIOD AND GOALTERM?
//
// TimePeriod: Pure chronological fact (start to end)
// GoalTerm: Planning scaffold with semantics (theme, status, reflection)
//
// This separation allows:
// - Calendar periods to exist without goal planning
// - Multiple terms to reference same period (e.g., parallel experiments)
// - Reporting on time spans independent of planning
//
// Validation ensures they stay connected properly.

// WHY REQUIRE POSITIVE TERM NUMBERS?
//
// Terms are sequentially numbered: Term 1, Term 2, Term 3...
// Zero or negative terms are meaningless. This catches UI bugs.

// WHY ALLOW DUPLICATE GOAL ASSIGNMENTS CHECK?
//
// User might accidentally assign same goal twice in UI.
// Better to catch here than create confusing data.
//
// Note: This doesn't prevent goal from being in multiple terms
// (that's valid - goals can span terms). It only prevents
// duplicate assignments within SAME term.

// WHY ALLOW ZERO GOAL ASSIGNMENTS?
//
// Terms can be created before goals are assigned:
// - Create term structure upfront
// - Assign goals as they emerge
// - This is valid workflow

// FUTURE EXTENSIONS:
//
// - Add validation for term duration (typically 10 weeks)
// - Add validation for overlapping terms (warn but allow)
// - Add validation for goalId existence (requires database access)
// - Add business rule: active terms can't overlap (one active at a time)
