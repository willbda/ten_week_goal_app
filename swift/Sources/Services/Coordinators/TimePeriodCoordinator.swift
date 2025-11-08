//
// TimePeriodCoordinator.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Coordinates creation of TimePeriod entities with specializations (GoalTerm, Year, etc.)
// ARCHITECTURE: Ontologically pure - works with TimePeriod abstraction, creates appropriate specialization
//

import Foundation
import Models
import SQLiteData

/// Coordinates creation of TimePeriod entities with atomic persistence.
///
/// ARCHITECTURE DECISION: Ontological purity in data layer
/// - Coordinator works with TimePeriod (abstraction), not Term/Year (specifics)
/// - Creates TimePeriod + appropriate specialization (GoalTerm, Year, etc.) atomically
/// - Views handle user-friendly naming ("Terms", "Years") via type-specific wrappers
///
/// Validation Strategy:
/// - NO validation in coordinator (trusts caller)
/// - Database enforces: NOT NULL, foreign keys, CHECK constraints, date ranges
/// - Business rules enforced by TimePeriodValidator (Phase 2)
///
/// PATTERN: Two-model atomic transaction (TimePeriod + Specialization)
/// Similar to: Goal (Expectation + Goal), but simpler (1:1 relationship)
@MainActor
public final class TimePeriodCoordinator: ObservableObject {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    /// Creates TimePeriod with specialization from form data.
    /// - Parameter formData: Validated form data with specialization type
    /// - Returns: Persisted TimePeriod with generated ID
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION:
    /// 1. Insert TimePeriod (abstraction)
    /// 2. Insert specialization (GoalTerm, Year, etc.) with FK to TimePeriod
    /// 3. Return TimePeriod (caller can access specialization via relationship)
    public func create(from formData: TimePeriodFormData) async throws -> TimePeriod {
        return try await database.write { db in
            // 1. Insert TimePeriod (using .insert for CREATE, not .upsert)
            let timePeriod = try TimePeriod.insert {
                TimePeriod.Draft(
                    id: UUID(),
                    title: formData.title,
                    detailedDescription: formData.detailedDescription,
                    freeformNotes: formData.freeformNotes,
                    logTime: Date(),
                    startDate: formData.startDate,
                    endDate: formData.targetDate  // FormData uses targetDate, model uses endDate
                )
            }
            .returning { $0 }
            .fetchOne(db)!

            // 2. Insert specialization based on type (using .insert for CREATE)
            switch formData.specialization {
            case .term(let number):
                // Insert GoalTerm with FK to TimePeriod
                try GoalTerm.insert {
                    GoalTerm.Draft(
                        id: UUID(),
                        timePeriodId: timePeriod.id,
                        termNumber: number,
                        theme: formData.theme,  // Include theme on create
                        reflection: nil,
                        status: .planned  // Default status for new terms
                    )
                }
                .execute(db)

            case .year(let yearNumber):
                // Future: Insert Year model when created
                // For now, just create TimePeriod without specialization
                // This allows the architecture to work even without Year model
                break

            case .custom:
                // No specialization - just the TimePeriod
                break
            }

            // 3. Return TimePeriod (caller can access goalTerm via relationship if needed)
            return timePeriod
        }
    }

    /// Updates existing TimePeriod with specialization from form data.
    /// - Parameters:
    ///   - timePeriod: Existing TimePeriod to update
    ///   - goalTerm: Existing GoalTerm to update
    ///   - formData: New form data
    /// - Returns: Updated TimePeriod
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION:
    /// 1. Update TimePeriod (preserves id and logTime)
    /// 2. Update specialization (GoalTerm, Year, etc.)
    /// 3. Return updated TimePeriod
    public func update(
        timePeriod: TimePeriod,
        goalTerm: GoalTerm,
        from formData: TimePeriodFormData
    ) async throws -> TimePeriod {
        return try await database.write { db in
            // 1. Update TimePeriod (preserve id and logTime)
            let updatedTimePeriod = try TimePeriod.upsert {
                TimePeriod.Draft(
                    id: timePeriod.id,  // Preserve ID
                    title: formData.title,
                    detailedDescription: formData.detailedDescription,
                    freeformNotes: formData.freeformNotes,
                    logTime: timePeriod.logTime,  // Preserve original logTime
                    startDate: formData.startDate,
                    endDate: formData.targetDate
                )
            }
            .returning { $0 }
            .fetchOne(db)!

            // 2. Update specialization based on type
            switch formData.specialization {
            case .term(let number):
                try GoalTerm.upsert {
                    GoalTerm.Draft(
                        id: goalTerm.id,  // Preserve ID
                        timePeriodId: updatedTimePeriod.id,
                        termNumber: number,
                        theme: formData.theme,
                        reflection: formData.reflection,
                        status: formData.status ?? goalTerm.status
                    )
                }
                .execute(db)

            case .year(let yearNumber):
                // Future: Update Year model when created
                break

            case .custom:
                // No specialization to update
                break
            }

            return updatedTimePeriod
        }
    }

    /// Deletes TimePeriod and its specialization.
    /// - Parameters:
    ///   - timePeriod: TimePeriod to delete
    ///   - goalTerm: Associated GoalTerm to delete
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION:
    /// 1. Delete specialization first (FK dependency)
    /// 2. Delete TimePeriod
    ///
    /// NOTE: This will fail if TermGoalAssignments exist (FK constraint)
    /// In future, could check for assignments and warn user first
    public func delete(
        timePeriod: TimePeriod,
        goalTerm: GoalTerm
    ) async throws {
        try await database.write { db in
            // 1. Delete GoalTerm first (has FK to TimePeriod)
            try GoalTerm.delete(goalTerm).execute(db)

            // 2. Delete TimePeriod
            try TimePeriod.delete(timePeriod).execute(db)
        }
    }
}
