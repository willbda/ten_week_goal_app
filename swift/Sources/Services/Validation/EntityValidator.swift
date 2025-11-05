// EntityValidator.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Protocol defining the standard interface for all entity validators.
// Enforces two-phase validation: (1) form data, (2) complete entity graph.
//
// ARCHITECTURE POSITION:
// Protocol layer - defines contract for all validators.
//
// UPSTREAM (calls this):
// - Coordinators (ActionCoordinator, GoalCoordinator, etc.)
// - Tests (mock implementations for testing)
//
// DOWNSTREAM (this calls):
// - None (protocol definition only)
//
// IMPLEMENTATIONS:
// - ActionValidator
// - GoalValidator
// - TermValidator
// - ValueValidator
//
// DESIGN RATIONALE:
// Two-phase validation compensates for loss of compile-time type safety:
//
// Phase 1: validateFormData()
//   - Validates raw user input before model creation
//   - Checks business rules (empty fields, date ranges, priorities)
//   - Fast feedback - no database access
//   - Example: Ensure action has SOME content
//
// Phase 2: validateComplete()
//   - Validates assembled entity graph
//   - Checks referential integrity (IDs match, relationships consistent)
//   - Catches assembly bugs before database write
//   - Example: Ensure measurement.actionId == action.id
//
// WHY TWO PHASES:
// - Phase 1: Fail fast on bad user input (UX)
// - Phase 2: Catch programmer errors in assembly logic (safety net)
// - Together: Replace compile-time checks lost with #sql macros
//
// USAGE PATTERN:
// struct MyValidator: EntityValidator {
//     func validateFormData(_ data: MyFormData) throws {
//         guard data.title != nil else {
//             throw ValidationError.emptyValue("Title required")
//         }
//     }
//
//     func validateComplete(_ entities: (MyEntity, [MyChild])) throws {
//         let (parent, children) = entities
//         for child in children {
//             guard child.parentId == parent.id else {
//                 throw ValidationError.inconsistentReference("Child must reference parent")
//             }
//         }
//     }
// }
//
// COORDINATOR USAGE:
// func create(formData: MyFormData) async throws -> MyEntity {
//     try validator.validateFormData(formData)           // Phase 1
//     let entity = assemble(formData)                   // Build graph
//     try validator.validateComplete(entity)            // Phase 2
//     try await repository.save(entity)                 // Persist
//     return entity
// }

import Foundation

/// Protocol for entity validators
/// Defines two-phase validation: form data ’ complete entity graph
public protocol EntityValidator {

    // MARK: - Associated Types

    /// Type of form data (user input from UI)
    associatedtype FormData

    /// Type of complete entity graph (assembled models ready for persistence)
    associatedtype Entity

    // MARK: - Validation Methods

    /// Phase 1: Validate raw form data before model creation
    ///
    /// Purpose: Fast feedback on user input
    /// Validates: Business rules, required fields, value ranges
    /// No database access required
    ///
    /// - Parameter formData: Raw form data from UI
    /// - Throws: ValidationError if business rules violated
    func validateFormData(_ formData: FormData) throws

    /// Phase 2: Validate assembled entity graph before persistence
    ///
    /// Purpose: Catch assembly bugs and referential integrity issues
    /// Validates: ID consistency, relationship integrity, graph structure
    /// Runs after models assembled, before database write
    ///
    /// - Parameter entities: Complete entity graph ready for persistence
    /// - Throws: ValidationError if graph is inconsistent
    func validateComplete(_ entities: Entity) throws
}

// MARK: - Design Notes

// PHASE 1 vs PHASE 2:
//
// Phase 1 (validateFormData):
// - User-facing validation
// - Fast feedback (< 1ms)
// - Business rule violations
// - Example: "Priority must be 1-10"
//
// Phase 2 (validateComplete):
// - Developer-facing validation
// - Safety net for bugs
// - Referential integrity
// - Example: "Measurement.actionId must match Action.id"
//
// Both phases throw same ValidationError type for consistent handling.

// TESTING STRATEGY:
//
// Validators are PURE functions with no dependencies:
// - No database access
// - No coordinator dependencies
// - Just plain structs in/out
//
// This makes testing fast and isolated:
// func testRejectsEmptyAction() {
//     let validator = ActionValidator()
//     let emptyData = ActionFormData(...)
//     XCTAssertThrowsError(try validator.validateFormData(emptyData))
// }
//
// No mocking required! Test exhaustively before wiring to coordinators.

// WHY NOT SINGLE PHASE?
//
// Could combine both into one validate() call, but two phases provide:
// 1. Faster user feedback (Phase 1 before expensive assembly)
// 2. Clear separation of concerns (user error vs programmer error)
// 3. Better error messages (context-specific)
// 4. Easier testing (test phases independently)

// FUTURE EXTENSIONS:
//
// - Add async version for database-dependent validation
//   func validateWithDatabase(_ entities: Entity) async throws
//
// - Add warning level (non-fatal validation issues)
//   func validateWithWarnings(_ data: FormData) -> [ValidationWarning]
//
// - Add batch validation for bulk operations
//   func validateBatch(_ items: [FormData]) throws -> [ValidationResult]
