import Dependencies
import Foundation
import Models
import SQLiteData

// ARCHITECTURE DECISION: Why Coordinators?
// CONTEXT: Evaluated alternatives in ARCHITECTURE_EVALUATION_20251102.md
// OPTIONS CONSIDERED:
//   A. Static methods on models (PersonalValue.create(...))
//   B. Repository pattern (PersonalValueRepository)
//   C. Coordinator pattern (this approach)
// WHY COORDINATORS:
//   - Consistent pattern across simple (PersonalValue) and complex (Goal) entities
//   - Clear separation: Models = data structure, Coordinators = persistence logic
//   - Enables multi-model atomic transactions (critical for Goal + Expectation + Measures)
//   - Easier to test persistence logic in isolation
//   - ViewModels stay focused on UI state, not database operations
// TRADEOFF: Extra layer for simple entities, but consistency matters more
// WHEN NOT TO USE: If entity has zero relationships and trivial validation
// FUTURE: If this layer feels burdensome, consider hybrid (coordinators for complex only)

/// Coordinates creation of PersonalValue entities with atomic persistence.
///
/// Validation Strategy:
/// - NO validation in coordinator (trusts caller)
/// - Database enforces: NOT NULL, foreign keys, CHECK constraints
/// - Business rules enforced by ValueValidator (Phase 2)
///
/// ARCHITECTURE NOTE: PersonalValue is the simplest coordinator (single model, no relationships)
/// Use this as template for other single-model coordinators (Term, Milestone)
/// For multi-model coordinators (Goal, Action), see GoalCoordinator for atomic transaction pattern
@MainActor
public final class PersonalValueCoordinator: ObservableObject {
    // ARCHITECTURE DECISION: DatabaseWriter instead of DatabaseQueue
    // CONTEXT: SQLiteData uses DatabaseWriter protocol (from GRDB)
    // PATTERN: From SQLiteData examples and DatabaseBootstrap.swift
    // WHY: DatabaseWriter is the protocol, DatabaseQueue is the concrete type
    //      Using protocol allows flexibility (could use DatabasePool for multi-threaded access)
    // SEE: sqlite-data-main/Examples/CaseStudies/ObservableModelDemo.swift:56-67
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    /// Creates a PersonalValue from form data.
    /// - Parameter formData: Validated form data (validation is caller's responsibility)
    /// - Returns: Persisted PersonalValue with generated ID
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION NOTE: Uses `.insert` for CREATE operations
    /// This ensures CloudKit properly tracks new records vs updates
    /// For updates, use `.upsert` with existing ID (see update() method in Phase 4)
    public func create(from formData: ValueFormData) async throws -> PersonalValue {
        return try await database.write { db in
            try PersonalValue.insert {
                PersonalValue.Draft(
                    id: UUID(),
                    title: formData.title,
                    detailedDescription: formData.detailedDescription,
                    freeformNotes: formData.freeformNotes,
                    logTime: Date(),
                    priority: formData.priority,
                    valueLevel: formData.valueLevel,
                    lifeDomain: formData.lifeDomain,
                    alignmentGuidance: formData.alignmentGuidance
                )
            }
            .returning { $0 }
            .fetchOne(db)!
        }
    }

    /// Updates existing PersonalValue from form data.
    /// - Parameters:
    ///   - value: Existing PersonalValue to update
    ///   - formData: New form data (FormData pattern - not individual params!)
    /// - Returns: Updated PersonalValue
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION:
    /// 1. Use .upsert (not .insert) with existing ID
    /// 2. Preserve id and logTime from existing value
    /// 3. Return updated value
    ///
    /// PATTERN: FormData-based method (follows ActionCoordinator pattern)
    public func update(
        value: PersonalValue,
        from formData: ValueFormData
    ) async throws -> PersonalValue {
        return try await database.write { db in
            try PersonalValue.upsert {
                PersonalValue.Draft(
                    id: value.id,  // Preserve ID
                    title: formData.title,
                    detailedDescription: formData.detailedDescription,
                    freeformNotes: formData.freeformNotes,
                    logTime: value.logTime,  // Preserve original logTime
                    priority: formData.priority,
                    valueLevel: formData.valueLevel,
                    lifeDomain: formData.lifeDomain,
                    alignmentGuidance: formData.alignmentGuidance
                )
            }
            .returning { $0 }
            .fetchOne(db)!  // Safe: successful upsert always returns value
        }
    }

    /// Deletes PersonalValue.
    /// - Parameter value: PersonalValue to delete
    /// - Throws: Database errors if constraints violated (e.g., GoalRelevances exist)
    ///
    /// IMPLEMENTATION:
    /// 1. Simple delete (no relationships to cascade for PersonalValue)
    /// 2. Database FK constraints will prevent deletion if GoalRelevances exist
    /// 3. For more complex entities (Action, Goal), see their coordinators for cascade pattern
    ///
    /// NOTE: If GoalRelevances reference this value, database will throw FK constraint error.
    /// In future, could query for dependent goals and return helpful error message.
    public func delete(value: PersonalValue) async throws {
        try await database.write { db in
            try PersonalValue.delete(value).execute(db)
        }
    }
}
