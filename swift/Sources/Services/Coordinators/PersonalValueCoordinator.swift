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
    /// IMPLEMENTATION NOTE: Uses `.upsert` pattern from SQLiteData examples
    /// This matches the pattern in Reminders/SyncUps apps and enables future edit support
    /// where we can use same method with existing ID to update instead of create
    public func create(from formData: ValueFormData) async throws -> PersonalValue {
        return try await database.write { db in
            try PersonalValue.upsert {
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

    // TODO: Phase 4 - Add Update and Delete
    // PATTERN: update() accepts existing PersonalValue + FormData, preserves id and logTime
    // PATTERN: delete() accepts PersonalValue, checks for dependencies before deleting
    // SEE: GoalCoordinator for relationship handling when deleting
}
