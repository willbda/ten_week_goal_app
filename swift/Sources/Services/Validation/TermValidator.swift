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
//  TimePeriod must have startDate before endDate
//   Rationale: Temporal boundary must be logically consistent
//
//  Term number must be positive
//   Rationale: Terms are sequentially numbered (Term 1, 2, 3...)
//
//  Status must be valid enum value (handled by Swift type system)
//   Note: This is compile-time checked, kept here for completeness
//
// Phase 2: validateComplete() - Referential Integrity
//  GoalTerm references correct timePeriodId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//  All assignments reference correct termId
//   Rationale: Catch assembly bugs (wrong ID assigned)
//
//  No duplicate goal assignments
//   Rationale: Same goal shouldn't appear twice in term
//
// FORM DATA STRUCTURE:
// struct TermFormData {
//     // TimePeriod fields
//     var title: String?
//     var description: String?
//     var startDate: Date
//     var endDate: Date
//
//     // GoalTerm fields
//     var termNumber: Int
//     var theme: String?
//     var reflection: String?
//     var status: TermStatus?
//
//     // Related entities
//     var goalAssignments: [UUID]  // Goal IDs to assign
// }
//
// USAGE EXAMPLE:
// let validator = TermValidator()
//
// // Phase 1: Validate form
// try validator.validateFormData(formData)
//
// // Assemble entities
// let timePeriod = TimePeriod(startDate: formData.startDate, ...)
// let goalTerm = GoalTerm(timePeriodId: timePeriod.id, ...)
// let assignments = formData.goalAssignments.map { goalId in
//     TermGoalAssignment(termId: goalTerm.id, goalId: goalId)
// }
//
// // Phase 2: Validate complete graph
// try validator.validateComplete((timePeriod, goalTerm, assignments))
//
// // Safe to persist
// try await repository.save(timePeriod, goalTerm, assignments)

import Foundation

/// Form data for term creation/update
public struct TermFormData {
    // TimePeriod fields
    public var title: String?
    public var description: String?
    public var startDate: Date
    public var endDate: Date

    // GoalTerm fields
    public var termNumber: Int
    public var theme: String?
    public var reflection: String?
    public var status: TermStatus?

    // Related entities
    public var goalAssignments: [UUID]

    public init(
        title: String? = nil,
        description: String? = nil,
        startDate: Date,
        endDate: Date,
        termNumber: Int,
        theme: String? = nil,
        reflection: String? = nil,
        status: TermStatus? = nil,
        goalAssignments: [UUID] = []
    ) {
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.termNumber = termNumber
        self.theme = theme
        self.reflection = reflection
        self.status = status
        self.goalAssignments = goalAssignments
    }
}

/// Validates Term entities and their relationships
public struct TermValidator: EntityValidator {

    // MARK: - EntityValidator Conformance

    public typealias FormData = TermFormData
    public typealias Entity = (TimePeriod, GoalTerm, [TermGoalAssignment])

    public init() {}

    // MARK: - Phase 1: Form Data Validation

    /// Validates raw form data before model creation
    ///
    /// Business Rules:
    /// - StartDate must be before endDate
    /// - Term number must be positive
    ///
    /// - Parameter formData: Raw form input from UI
    /// - Throws: ValidationError if business rules violated
    public func validateFormData(_ formData: TermFormData) throws {
        // Rule 1: StartDate must be before endDate
        guard formData.startDate < formData.endDate else {
            throw ValidationError.invalidDateRange(
                "Start date must be before end date"
            )
        }

        // Rule 2: Term number must be positive
        guard formData.termNumber > 0 else {
            throw ValidationError.invalidExpectation(
                "Term number must be positive, got \(formData.termNumber)"
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
// TimePeriod: Pure chronological fact (start ’ end)
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
