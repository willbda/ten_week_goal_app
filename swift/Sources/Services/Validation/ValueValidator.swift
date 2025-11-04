// ValueValidator.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Validates PersonalValue entities.
// Compensates for type safety loss when using #sql macros for database operations.
//
// ARCHITECTURE POSITION:
// Validation layer - validates PersonalValue entities before persistence.
//
// UPSTREAM (calls this):
// - ValueCoordinator.createValue()
// - ValueCoordinator.updateValue()
// - Tests (ValueValidatorTests)
//
// DOWNSTREAM (this calls):
// - ValidationError (throws errors)
//
// ENTITY VALIDATED:
// - PersonalValue (single entity, no related children)
//
// VALIDATION RULES:
//
// Phase 1: validateFormData() - Business Rules
//  Value must have title OR description
//   Rationale: Values need textual definition
//
//  Priority must be 1-100 (if provided)
//   Rationale: Standard priority scale (1 = highest, 100 = lowest)
//
//  ValueLevel must be valid enum (handled by Swift type system)
//   Note: This is compile-time checked, kept here for completeness
//
// Phase 2: validateComplete() - Referential Integrity
// (No child entities to validate for PersonalValue - simplified validator)
//  Priority falls back to valueLevel default if not provided
//   Rationale: Ensure priority is always set
//
// FORM DATA STRUCTURE:
// struct ValueFormData {
//     var title: String?
//     var description: String?
//     var notes: String?
//     var priority: Int?
//     var valueLevel: ValueLevel
//     var lifeDomain: String?
//     var alignmentGuidance: String?
// }
//
// USAGE EXAMPLE:
// let validator = ValueValidator()
//
// // Phase 1: Validate form
// try validator.validateFormData(formData)
//
// // Assemble entity
// let value = PersonalValue(
//     title: formData.title,
//     priority: formData.priority,
//     valueLevel: formData.valueLevel,
//     ...
// )
//
// // Phase 2: Validate complete entity
// try validator.validateComplete(value)
//
// // Safe to persist
// try await repository.save(value)

import Foundation

/// Form data for value creation/update
public struct ValueFormData {
    public var title: String?
    public var description: String?
    public var notes: String?
    public var priority: Int?
    public var valueLevel: ValueLevel
    public var lifeDomain: String?
    public var alignmentGuidance: String?

    public init(
        title: String? = nil,
        description: String? = nil,
        notes: String? = nil,
        priority: Int? = nil,
        valueLevel: ValueLevel = .general,
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil
    ) {
        self.title = title
        self.description = description
        self.notes = notes
        self.priority = priority
        self.valueLevel = valueLevel
        self.lifeDomain = lifeDomain
        self.alignmentGuidance = alignmentGuidance
    }
}

/// Validates PersonalValue entities
public struct ValueValidator: EntityValidator {

    // MARK: - EntityValidator Conformance

    public typealias FormData = ValueFormData
    public typealias Entity = PersonalValue

    public init() {}

    // MARK: - Phase 1: Form Data Validation

    /// Validates raw form data before model creation
    ///
    /// Business Rules:
    /// - Value must have title or description
    /// - Priority must be 1-100 (if provided)
    ///
    /// - Parameter formData: Raw form input from UI
    /// - Throws: ValidationError if business rules violated
    public func validateFormData(_ formData: ValueFormData) throws {
        // Rule 1: Value must have title or description
        let hasTitle = formData.title?.isEmpty == false
        let hasDescription = formData.description?.isEmpty == false

        guard hasTitle || hasDescription else {
            throw ValidationError.emptyValue(
                "Value must have a title or description"
            )
        }

        // Rule 2: Priority must be 1-100 (if provided)
        if let priority = formData.priority {
            guard (1...100).contains(priority) else {
                throw ValidationError.invalidPriority(
                    "Priority must be 1-100, got \(priority)"
                )
            }
        }
    }

    // MARK: - Phase 2: Complete Entity Validation

    /// Validates assembled entity before persistence
    ///
    /// For PersonalValue, this is simplified since there are no child entities.
    /// We just verify the priority was set (either explicitly or via default).
    ///
    /// - Parameter entities: Complete PersonalValue entity
    /// - Throws: ValidationError if entity is invalid
    public func validateComplete(_ entities: PersonalValue) throws {
        let value = entities

        // Check: Priority should be set (either explicitly or via default)
        // This is defensive - the model initializer handles this, but we verify
        guard let priority = value.priority, (1...100).contains(priority) else {
            throw ValidationError.invalidPriority(
                "Priority must be set and in range 1-100"
            )
        }
    }
}

// MARK: - Design Notes

// WHY REQUIRE TITLE OR DESCRIPTION?
//
// Values need textual definition for human understanding. Even abstract values
// like "Eudaimonia" need at least a title. This prevents data quality issues.

// WHY 1-100 PRIORITY SCALE?
//
// Wider scale than Eisenhower matrix (1-10) because values have more nuance:
// - 1-10: Highest order values
// - 11-30: Major values
// - 31-50: General values
// - 51-100: Life areas and lower priority values
//
// This scale accommodates the full range of value types.

// WHY ALLOW NULL PRIORITY IN FORM?
//
// If user doesn't provide priority, we use the valueLevel default:
// - .general ’ 40
// - .major ’ 10
// - .highestOrder ’ 1
// - .lifeArea ’ 40
//
// This provides sensible defaults while allowing explicit override.

// WHY NO CHILD ENTITIES?
//
// Unlike Action (has MeasuredAction[]) or Goal (has ExpectationMeasure[]),
// PersonalValue is a standalone entity. This simplifies validation significantly.
//
// Related entities:
// - GoalRelevance: Links goals ’ values (validated in GoalValidator)
// - Not part of value creation flow

// SIMPLIFIED PHASE 2
//
// For most validators, Phase 2 checks referential integrity of child entities.
// PersonalValue has no children, so Phase 2 is minimal - just verify the
// model was assembled correctly.
//
// This is still useful:
// - Catches bugs in coordinator assembly logic
// - Ensures priority was set (model init could theoretically fail)
// - Maintains consistent validator interface

// FUTURE EXTENSIONS:
//
// - Add validation for lifeDomain enum (if we formalize domains)
// - Add validation for alignmentGuidance length (prevent essays)
// - Add validation for duplicate titles (requires database access)
// - Add business rule: major values should have alignmentGuidance
