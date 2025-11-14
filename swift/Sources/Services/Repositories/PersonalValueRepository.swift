//
// PersonalValueRepository.swift
// Written by Claude Code on 2025-11-08
// Refactored to #sql pattern on 2025-11-10
//
// PURPOSE:
// Read coordinator for PersonalValue entities - centralizes query logic.
// Complements PersonalValueCoordinator (writes) by handling all read operations.
//
// RESPONSIBILITIES:
// 1. Read operations - fetchAll(), fetchByLevel(), fetchById(), fetchByGoal()
// 2. Existence checks - existsByTitle(), exists()
// 3. Error mapping - DatabaseError → ValidationError
//
// QUERY PATTERN:
// Uses SQLiteData's #sql macro for all queries.
// - Type-safe SQL with compile-time table/column checking
// - Direct SQL for clarity and performance
// - FetchKeyRequest pattern for complex multi-value queries
//

import Foundation
import Models
import SQLiteData

// REMOVED @MainActor: Repository performs database queries which are I/O
// operations that should run in background. Database reads should not block
// the main thread. ViewModels will await results on main actor as needed.
//
// SENDABLE: Conforms to Sendable for Swift 6 strict concurrency.
// Safe because:
// - Only immutable property (private let database)
// - All methods are async (thread-safe by nature)
// - Can be safely passed from @MainActor ViewModels to background tasks
public final class PersonalValueRepository: Sendable {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    // MARK: - Read Operations

    /// Fetch all personal values ordered by priority (highest priority first)
    public func fetchAll() async throws -> [PersonalValue] {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT \(PersonalValue.columns)
                    FROM \(PersonalValue.self)
                    ORDER BY \(PersonalValue.priority) DESC
                    """,
                    as: PersonalValue.self
                ).fetchAll(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch values of a specific level
    public func fetchByLevel(_ level: ValueLevel) async throws -> [PersonalValue] {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT \(PersonalValue.columns)
                    FROM \(PersonalValue.self)
                    WHERE \(PersonalValue.valueLevel) = \(bind: level)
                    ORDER BY \(PersonalValue.priority) DESC
                    """,
                    as: PersonalValue.self
                ).fetchAll(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch single value by ID
    public func fetchById(_ id: UUID) async throws -> PersonalValue? {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT \(PersonalValue.columns)
                    FROM \(PersonalValue.self)
                    WHERE \(PersonalValue.id) = \(bind: id)
                    """,
                    as: PersonalValue.self
                ).fetchOne(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch values aligned with a specific goal
    public func fetchByGoal(_ goalId: UUID) async throws -> [PersonalValue] {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT \(PersonalValue.columns)
                    FROM \(PersonalValue.self)
                    INNER JOIN \(GoalRelevance.self) ON \(PersonalValue.id) = \(GoalRelevance.valueId)
                    WHERE \(GoalRelevance.goalId) = \(bind: goalId)
                    ORDER BY \(PersonalValue.priority) DESC
                    """,
                    as: PersonalValue.self
                ).fetchAll(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Existence Checks

    /// Check if a value with this title already exists (case-insensitive)
    public func existsByTitle(_ title: String) async throws -> Bool {
        do {
            return try await database.read { db in
                try ExistsByTitleRequest(title: title).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Check if a value exists by ID
    public func exists(_ id: UUID) async throws -> Bool {
        do {
            return try await database.read { db in
                try ExistsByIdRequest(id: id).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Error Mapping

    private func mapDatabaseError(_ error: Error) -> ValidationError {
        guard let dbError = error as? DatabaseError else {
            return .databaseConstraint(error.localizedDescription)
        }

        switch dbError.resultCode {
        case .SQLITE_CONSTRAINT_UNIQUE:
            return .duplicateRecord("A value with this title already exists")
        case .SQLITE_CONSTRAINT_NOTNULL:
            let message = dbError.message ?? "Required field is missing"
            return .missingRequiredField(message)
        case .SQLITE_CONSTRAINT_FOREIGNKEY:
            return .foreignKeyViolation("Referenced record no longer exists")
        case .SQLITE_CONSTRAINT:
            let message = dbError.message ?? "Database constraint violated"
            return .databaseConstraint(message)
        default:
            return .databaseConstraint(dbError.localizedDescription)
        }
    }
}

// MARK: - Fetch Requests

/// Check if a title exists (case-insensitive)
private struct ExistsByTitleRequest: FetchKeyRequest {
    typealias Value = Bool
    let title: String

    func fetch(_ db: Database) throws -> Bool {
        let count = try #sql(
            """
            SELECT COUNT(*)
            FROM \(PersonalValue.self)
            WHERE LOWER(\(PersonalValue.title)) = LOWER(\(bind: title))
            """,
            as: Int.self
        ).fetchOne(db) ?? 0
        return count > 0
    }
}

/// Check if an ID exists
private struct ExistsByIdRequest: FetchKeyRequest {
    typealias Value = Bool
    let id: UUID

    func fetch(_ db: Database) throws -> Bool {
        let count = try #sql(
            """
            SELECT COUNT(*)
            FROM \(PersonalValue.self)
            WHERE \(PersonalValue.id) = \(bind: id)
            """,
            as: Int.self
        ).fetchOne(db) ?? 0
        return count > 0
    }
}

// MARK: - Implementation Notes

// WHY #sql MACRO?
//
// Benefits:
// 1. Type Safety - Compile-time checking of table/column names via \(Type.column)
// 2. SQL Clarity - Standard SQL is universally understood
// 3. Performance - Direct SQL execution
// 4. Power - Full SQL feature set (JOINs, CTEs, window functions)
// 5. Security - Automatic SQL injection protection with \(bind:)
//
// Pattern:
// - Simple queries: Direct #sql() calls in repository methods
// - Complex queries: FetchKeyRequest structs for multi-value results
// - All parameters use \(bind: value) for safe SQL injection prevention
// - Error mapping ensures user-friendly messages (DatabaseError → ValidationError)

// WHY FetchKeyRequest FOR EXISTENCE CHECKS?
//
// While simple, existence checks benefit from FetchKeyRequest pattern:
// - Encapsulates COUNT query logic
// - Makes intent explicit (returns Bool, not Int)
// - Easy to test in isolation
// - Reusable if needed elsewhere
// - Follows SQLiteData patterns
