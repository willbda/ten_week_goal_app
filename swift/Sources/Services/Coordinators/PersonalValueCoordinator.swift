import Foundation
import Models
import SQLiteData

/// Coordinates creation of PersonalValue entities with atomic persistence.
///
/// Validation Strategy:
/// - NO validation in coordinator (trusts caller)
/// - Database enforces: NOT NULL, foreign keys, CHECK constraints
/// - Business rules enforced by ValueValidator (Phase 2)
@MainActor
public final class PersonalValueCoordinator: ObservableObject {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    /// Creates a PersonalValue from form data.
    /// - Parameter formData: Validated form data (validation is caller's responsibility)
    /// - Returns: Persisted PersonalValue with generated ID
    /// - Throws: Database errors if constraints violated
    public func create(from formData: ValueFormData) async throws -> PersonalValue {
        return try await database.write { db in
            try PersonalValue.insert {
                PersonalValue.Draft(
                    id: UUID(),
                    title: formData.title,
                    detailedDescription: formData.detailedDescription,
                    freeformNotes: formData.freeformNotes,
                    logTime: Date(),
                    valueLevel: formData.valueLevel,
                    priority: formData.priority,
                    lifeDomain: formData.lifeDomain,
                    alignmentGuidance: formData.alignmentGuidance
                )
            }
            .returning()
            .fetchOne(db)!
        }
    }
}
