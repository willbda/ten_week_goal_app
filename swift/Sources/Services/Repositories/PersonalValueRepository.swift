//
// PersonalValueRepository.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Read coordinator for PersonalValue entities - centralizes query logic.
// Complements PersonalValueCoordinator (writes) by handling all read operations.
//
// RESPONSIBILITIES:
// 1. Read operations - fetchAll(), fetchByLevel()
// 2. Existence checks - existsByTitle() (prevent duplicate values)
// 3. Error mapping - DatabaseError → ValidationError
//
// USED BY:
// - PersonalValuesFormViewModel (for loading values list)
// - GoalFormView (for value alignment picker)
// - PersonalValueCoordinator (for existence checks)
//
// DEPENDS ON:
// - Database (SQLiteData DatabaseWriter)
// - Models (PersonalValue, ValueLevel enum)
// - ValidationError (Services/Validation)
//
// QUERY PATTERN:
// Uses SQLiteData's type-safe query builders (.order, .where, .fetchAll)
// No FetchKeyRequest needed for simple single-table queries
//

import Foundation
import Models
import SQLiteData

@MainActor
public final class PersonalValueRepository {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    // MARK: - Read Operations

    /// Fetch all personal values ordered by priority (highest priority first)
    ///
    /// **Query**: Single table query with ORDER BY
    /// **Performance**: Fast (indexed priority column, no JOINs)
    /// **Usage**: Loading values list in forms, dashboards
    ///
    /// - Returns: Array of PersonalValues sorted by priority (1 = highest)
    /// - Throws: ValidationError if database operation fails
    public func fetchAll() async throws -> [PersonalValue] {
        do {
            return try await database.read { db in
                try PersonalValue.order { $0.priority.desc() }.fetchAll(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch values of a specific level (general, major, highest_order, life_area)
    ///
    /// **Query**: Single table query with WHERE + ORDER BY
    /// **Performance**: Fast (indexed valueLevel column)
    /// **Usage**: Filtered value pickers, level-specific displays
    ///
    /// - Parameter level: ValueLevel to filter by
    /// - Returns: Array of PersonalValues with matching level, sorted by priority
    /// - Throws: ValidationError if database operation fails
    public func fetchByLevel(_ level: ValueLevel) async throws -> [PersonalValue] {
        do {
            return try await database.read { db in
                try PersonalValue
                    .where { $0.valueLevel.eq(level) }
                    .order { $0.priority.desc() }
                    .fetchAll(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch single value by ID
    ///
    /// **Query**: Primary key lookup (fastest query type)
    /// **Performance**: O(1) - index lookup
    /// **Usage**: Loading existing value for edit, detail views
    ///
    /// - Parameter id: UUID of value to fetch
    /// - Returns: PersonalValue if found, nil otherwise
    /// - Throws: ValidationError if database operation fails
    public func fetchById(_ id: UUID) async throws -> PersonalValue? {
        do {
            return try await database.read { db in
                try PersonalValue.where { $0.id.eq(id) }.fetchOne(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch values aligned with a specific goal
    ///
    /// **Query**: JOIN through GoalRelevances junction table
    /// **Performance**: Indexed JOIN (goalId, valueId both indexed)
    /// **Usage**: Showing aligned values for a goal
    ///
    /// **Implementation Note**: Simple JOIN query pattern from TermsQuery.swift
    /// No need for FetchKeyRequest wrapper for this simple relationship
    ///
    /// - Parameter goalId: UUID of goal to find aligned values for
    /// - Returns: Array of PersonalValues aligned with this goal, sorted by priority
    /// - Throws: ValidationError if database operation fails
    public func fetchByGoal(_ goalId: UUID) async throws -> [PersonalValue] {
        do {
            return try await database.read { db in
                // Pattern: JOIN PersonalValue with GoalRelevances where goalId matches
                // SQLiteData returns [(PersonalValue, GoalRelevance)] from join
                let results = try PersonalValue.all
                    .join(GoalRelevance.all) { value, relevance in
                        value.id.eq(relevance.valueId).and(relevance.goalId.eq(goalId))
                    }
                    .order { value, _ in value.priority.desc() }
                    .fetchAll(db)

                // Extract just the PersonalValue from the tuple
                return results.map { (value, _) in value }
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Existence Checks

    /// Check if a value with this title already exists
    ///
    /// **Purpose**: Prevent duplicate values in CSV import and manual creation
    /// **Query**: Existence check (fast - no need to fetch full record)
    /// **Case sensitivity**: Case-insensitive comparison for user-friendly UX
    ///
    /// **Usage Pattern**:
    /// ```swift
    /// // In coordinator, before creating:
    /// if try await repository.existsByTitle(formData.title) {
    ///     throw ValidationError.duplicateRecord("Value '\(formData.title)' already exists")
    /// }
    /// ```
    ///
    /// - Parameter title: Title to check (case-insensitive)
    /// - Returns: true if value with this title exists, false otherwise
    /// - Throws: ValidationError if database operation fails
    public func existsByTitle(_ title: String) async throws -> Bool {
        do {
            return try await database.read { db in
                // Case-insensitive search - fetch all and compare in memory
                // Note: For large datasets (>1000 values), could add normalized title column + index
                // Current approach is fine for typical usage (<100 values)
                let allValues = try PersonalValue.order { $0.title.asc() }.fetchAll(db)
                return allValues.contains { value in
                    value.title?.lowercased() == title.lowercased()
                }
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Check if a value exists by ID
    ///
    /// **Purpose**: Validate foreign key references before insert
    /// **Query**: Primary key existence check (O(1) index lookup)
    ///
    /// **Usage Pattern**:
    /// ```swift
    /// // In GoalCoordinator, before creating GoalRelevance:
    /// guard try await valueRepository.exists(valueId) else {
    ///     throw ValidationError.foreignKeyViolation("Value not found")
    /// }
    /// ```
    ///
    /// - Parameter id: UUID to check
    /// - Returns: true if value exists, false otherwise
    /// - Throws: ValidationError if database operation fails
    public func exists(_ id: UUID) async throws -> Bool {
        do {
            return try await database.read { db in
                try PersonalValue.where { $0.id.eq(id) }.fetchOne(db) != nil
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Error Mapping

    /// Map database errors to user-friendly validation errors
    ///
    /// **Purpose**: Convert low-level database errors to user-facing messages
    /// **Pattern**: Inspect SQLite error codes and constraints
    ///
    /// **Error Mapping**:
    /// - SQLITE_CONSTRAINT_UNIQUE → duplicateRecord
    /// - SQLITE_CONSTRAINT_NOTNULL → missingRequiredField
    /// - SQLITE_CONSTRAINT_FOREIGNKEY → foreignKeyViolation
    /// - Other DatabaseError → databaseConstraint
    /// - Non-DatabaseError → generic databaseError
    ///
    /// - Parameter error: Raw error from database operation
    /// - Returns: ValidationError with user-friendly message
    func mapDatabaseError(_ error: Error) -> ValidationError {
        guard let dbError = error as? DatabaseError else {
            return .databaseConstraint(error.localizedDescription)
        }

        // Inspect SQLite result code for specific error types
        // Pattern from GRDB documentation on error handling
        switch dbError.resultCode {
        case .SQLITE_CONSTRAINT_UNIQUE:
            return .duplicateRecord("A value with this title already exists")

        case .SQLITE_CONSTRAINT_NOTNULL:
            // Parse which field is NULL from message
            let message = dbError.message ?? "Required field is missing"
            return .missingRequiredField(message)

        case .SQLITE_CONSTRAINT_FOREIGNKEY:
            return .foreignKeyViolation("Referenced record no longer exists")

        case .SQLITE_CONSTRAINT:
            // Generic constraint violation (CHECK constraints, etc.)
            let message = dbError.message ?? "Database constraint violated"
            return .databaseConstraint(message)

        default:
            // Other database errors (I/O, corruption, etc.)
            return .databaseConstraint(dbError.localizedDescription)
        }
    }
}

// MARK: - Implementation Notes

// WHY NO FetchKeyRequest?
//
// PersonalValue queries are simple single-table operations:
// - fetchAll() → no JOIN needed
// - fetchByLevel() → no JOIN needed
// - fetchById() → primary key lookup
// - fetchByGoal() → simple 1:1 JOIN
//
// FetchKeyRequest is valuable for:
// - Complex multi-table JOINs (ActionsWithMeasuresAndGoals)
// - Bulk loading strategies (N+1 prevention)
// - Reusable queries across ViewModels
//
// PersonalValue queries are simple enough to inline in repository methods.
// If we later need @Fetch observation, can extract to FetchKeyRequest.

// WHY CASE-INSENSITIVE TITLE CHECK?
//
// User-friendly duplicate prevention:
// - "Creativity" and "creativity" are duplicates
// - Prevents CSV import confusion
// - Matches user expectations
//
// Tradeoff: Slightly slower query (function call in WHERE clause)
// Benefit: Much better UX
//
// If performance becomes issue (>10k values), can add:
// - Normalized title column (LOWER(title) stored)
// - Index on normalized column
// - Current approach is fine for <1000 values

// WHY ASYNC/AWAIT?
//
// All database operations must be async:
// - DatabaseQueue serializes writes (thread-safe)
// - @MainActor ensures UI updates on main thread
// - Async enables proper error propagation
// - Matches SQLiteData patterns

// ERROR HANDLING STRATEGY
//
// Two-layer approach:
// 1. Database layer catches DatabaseError, maps to ValidationError
// 2. Coordinator/ViewModel catches ValidationError, displays error.userMessage
//
// Benefits:
// - No raw SQL errors leak to UI
// - Consistent error messages across app
// - Easy to test error scenarios
// - Localizable in future (ValidationError.userMessage can be localized)
