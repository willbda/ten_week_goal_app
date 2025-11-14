//
// ActionRepository.swift
// Written by Claude Code on 2025-11-09
// Refactored to JSON aggregation on 2025-11-13
//
// PURPOSE:
// Read coordinator for Action entities with measurements and goal contributions.
// Uses JSON aggregation pattern for efficient single-query fetches.
//
// RESPONSIBILITIES:
// 1. Complex reads - fetchAll(), fetchByDateRange(), fetchByGoal() with JSON aggregation
// 2. Aggregations - totalByMeasure(), countByGoal()
// 3. Existence checks - exists() for duplicate prevention
// 4. Error mapping - DatabaseError → ValidationError
//
// PATTERN (migrated from query builders + Dictionary(grouping:)):
// - Single SQL query with json_group_array() for relationships
// - Row structs with FetchableRecord for decoding
// - assembleActionWithDetails() for JSON parsing and model construction
// - Mirrors GoalRepository pattern (GoalRepository.swift:260-508)
//

import Foundation
import Models
import SQLiteData
import GRDB  // For FetchableRecord protocol

// MARK: - Repository Implementation

public final class ActionRepository: Sendable {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    // MARK: - Complex Queries

    /// Fetch all actions with measurements and goal contributions
    ///
    /// **Performance**: Single query with JSON aggregation (was 3 queries)
    /// **Pattern**: Mirrors GoalRepository.fetchAll()
    public func fetchAll() async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                let rows = try ActionQueryRow.fetchAll(db, sql: fetchAllSQL)
                return try rows.map { row in
                    try assembleActionWithDetails(from: row)
                }
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch actions within a date range
    ///
    /// **Performance**: Single query with JSON aggregation + date filter
    public func fetchByDateRange(_ range: ClosedRange<Date>) async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                let sql = """
                \(baseQuerySQL)
                WHERE a.logTime BETWEEN ? AND ?
                ORDER BY a.logTime DESC
                """

                let rows = try ActionQueryRow.fetchAll(db, sql: sql, arguments: [range.lowerBound, range.upperBound])
                return try rows.map { row in
                    try assembleActionWithDetails(from: row)
                }
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch actions contributing to a specific goal
    ///
    /// **Performance**: Single query with JSON aggregation + goal filter
    public func fetchByGoal(_ goalId: UUID) async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                let sql = """
                \(baseQuerySQL)
                WHERE EXISTS (
                    SELECT 1 FROM actionGoalContributions agc2
                    WHERE agc2.actionId = a.id AND agc2.goalId = ?
                )
                ORDER BY a.logTime DESC
                """

                let rows = try ActionQueryRow.fetchAll(db, sql: sql, arguments: [goalId])
                return try rows.map { row in
                    try assembleActionWithDetails(from: row)
                }
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch recent actions with limit
    ///
    /// **Performance**: Single query with JSON aggregation + LIMIT
    public func fetchRecentActions(limit: Int) async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                let sql = """
                \(baseQuerySQL)
                ORDER BY a.logTime DESC
                LIMIT ?
                """

                let rows = try ActionQueryRow.fetchAll(db, sql: sql, arguments: [limit])
                return try rows.map { row in
                    try assembleActionWithDetails(from: row)
                }
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Aggregations

    /// Calculate total value for a measure within a date range
    public func totalByMeasure(_ measureId: UUID, in range: ClosedRange<Date>) async throws -> Double {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT COALESCE(SUM(\(MeasuredAction.value)), 0.0) as total
                    FROM \(MeasuredAction.self)
                    INNER JOIN \(Action.self) ON \(MeasuredAction.actionId) = \(Action.id)
                    WHERE \(MeasuredAction.measureId) = \(bind: measureId)
                      AND \(Action.logTime) BETWEEN \(bind: range.lowerBound) AND \(bind: range.upperBound)
                    """,
                    as: Double.self
                ).fetchOne(db) ?? 0.0
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Count actions contributing to a specific goal
    public func countByGoal(_ goalId: UUID) async throws -> Int {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT COUNT(DISTINCT \(ActionGoalContribution.actionId))
                    FROM \(ActionGoalContribution.self)
                    WHERE \(ActionGoalContribution.goalId) = \(bind: goalId)
                    """,
                    as: Int.self
                ).fetchOne(db) ?? 0
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Existence Checks

    /// Check if an action exists by title and date
    public func exists(title: String, on date: Date) async throws -> Bool {
        do {
            return try await database.read { db in
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    return false
                }

                let sql = """
                SELECT COUNT(*) FROM actions
                WHERE title = ? AND logTime >= ? AND logTime < ?
                """

                let count = try Int.fetchOne(db, sql: sql, arguments: [title, startOfDay, endOfDay]) ?? 0
                return count > 0
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Check if an action exists by ID
    public func exists(_ id: UUID) async throws -> Bool {
        do {
            return try await database.read { db in
                let sql = "SELECT COUNT(*) FROM actions WHERE id = ?"
                let count = try Int.fetchOne(db, sql: sql, arguments: [id]) ?? 0
                return count > 0
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
        case .SQLITE_CONSTRAINT_FOREIGNKEY:
            if dbError.message?.contains("measureId") == true {
                return .invalidMeasure("Measure not found")
            }
            if dbError.message?.contains("goalId") == true {
                return .invalidGoal("Goal not found")
            }
            return .foreignKeyViolation("Referenced entity not found")
        case .SQLITE_CONSTRAINT_UNIQUE:
            return .duplicateRecord("This entry already exists")
        case .SQLITE_CONSTRAINT_NOTNULL:
            return .missingRequiredField("Required field is missing")
        case .SQLITE_CONSTRAINT:
            return .databaseConstraint(dbError.message ?? "Database constraint violated")
        default:
            return .databaseConstraint(dbError.localizedDescription)
        }
    }
}

// MARK: - SQL Queries

extension ActionRepository {
    /// Base SQL query with JSON aggregation for measurements and contributions
    ///
    /// **Pattern**: Mirrors GoalRepository.baseQuerySQL (GoalRepository.swift:452-508)
    /// **Performance**: Single query replaces 3 separate queries + Dictionary(grouping:)
    private var baseQuerySQL: String {
        """
        SELECT
            a.id as actionId,
            a.title as actionTitle,
            a.detailedDescription as actionDetailedDescription,
            a.freeformNotes as actionFreeformNotes,
            a.logTime as actionLogTime,
            a.durationMinutes as actionDurationMinutes,
            a.startTime as actionStartTime,

            -- Measurements JSON array (all measurements for this action)
            COALESCE(
                (
                    SELECT json_group_array(
                        json_object(
                            'measuredActionId', ma.id,
                            'value', ma.value,
                            'createdAt', ma.createdAt,
                            'measureId', m.id,
                            'measureTitle', m.title,
                            'measureDetailedDescription', m.detailedDescription,
                            'measureFreeformNotes', m.freeformNotes,
                            'measureLogTime', m.logTime,
                            'measureUnit', m.unit,
                            'measureType', m.measureType,
                            'measureCanonicalUnit', m.canonicalUnit,
                            'measureConversionFactor', m.conversionFactor
                        )
                    )
                    FROM measuredActions ma
                    JOIN measures m ON ma.measureId = m.id
                    WHERE ma.actionId = a.id
                ),
                '[]'
            ) as measurementsJson,

            -- Contributions JSON array (all goals this action contributes to)
            COALESCE(
                (
                    SELECT json_group_array(
                        json_object(
                            'contributionId', agc.id,
                            'contributionAmount', agc.contributionAmount,
                            'measureId', agc.measureId,
                            'createdAt', agc.createdAt,
                            'goalId', g.id
                        )
                    )
                    FROM actionGoalContributions agc
                    JOIN goals g ON agc.goalId = g.id
                    WHERE agc.actionId = a.id
                ),
                '[]'
            ) as contributionsJson

        FROM actions a
        """
    }

    /// Fetch all actions SQL (no filters)
    private var fetchAllSQL: String {
        """
        \(baseQuerySQL)
        ORDER BY a.logTime DESC
        """
    }
}

// MARK: - Row Types

/// Result row from JSON aggregation query
///
/// **Pattern**: Mirrors GoalQueryRow (GoalRepository.swift:186-246)
/// Decodes SQL result with json_group_array() columns
public struct ActionQueryRow: Decodable, FetchableRecord, Sendable {
    // Action fields
    let actionId: String
    let actionTitle: String?
    let actionDetailedDescription: String?
    let actionFreeformNotes: String?
    let actionLogTime: String
    let actionDurationMinutes: Double?
    let actionStartTime: String?

    // JSON arrays (decoded as strings, parsed manually)
    let measurementsJson: String
    let contributionsJson: String
}

/// Decoded measurement from JSON array
///
/// **Pattern**: Mirrors MeasureJsonRow from GoalRepository
private struct MeasurementJsonRow: Decodable, Sendable {
    let measuredActionId: String
    let value: Double
    let createdAt: String
    let measureId: String
    let measureTitle: String?
    let measureDetailedDescription: String?
    let measureFreeformNotes: String?
    let measureLogTime: String
    let measureUnit: String
    let measureType: String
    let measureCanonicalUnit: String?
    let measureConversionFactor: Double?
}

/// Decoded contribution from JSON array
private struct ContributionJsonRow: Decodable, Sendable {
    let contributionId: String
    let contributionAmount: Double?
    let measureId: String?
    let createdAt: String
    let goalId: String
}

// MARK: - Assembly Function

/// Assemble ActionWithDetails from JSON query row
///
/// **Pattern**: Mirrors assembleGoalWithDetails() (GoalRepository.swift:260-423)
/// **Process**:
/// 1. Parse JSON strings to structured arrays
/// 2. Convert string dates/UUIDs to proper types
/// 3. Build domain models with correct init parameter order
/// 4. Return assembled ActionWithDetails
public func assembleActionWithDetails(from row: ActionQueryRow) throws -> ActionWithDetails {
    let decoder = JSONDecoder()

    // Parse action fields
    guard let actionUUID = UUID(uuidString: row.actionId) else {
        throw ValidationError.databaseConstraint("Invalid action ID: \(row.actionId)")
    }

    let action = Action(
        title: row.actionTitle,
        detailedDescription: row.actionDetailedDescription,
        freeformNotes: row.actionFreeformNotes,
        durationMinutes: row.actionDurationMinutes,
        startTime: parseDate(row.actionStartTime),
        logTime: parseDate(row.actionLogTime) ?? Date(),
        id: actionUUID
    )

    // Parse measurements JSON
    let measurementsData = row.measurementsJson.data(using: .utf8)!
    let measurementsJson = try decoder.decode([MeasurementJsonRow].self, from: measurementsData)

    let measurements: [ActionMeasurement] = try measurementsJson.map { m in
        guard let measuredActionUUID = UUID(uuidString: m.measuredActionId),
              let measureUUID = UUID(uuidString: m.measureId) else {
            throw ValidationError.databaseConstraint("Invalid UUID in measurement for action \(row.actionId)")
        }

        let measuredAction = MeasuredAction(
            actionId: actionUUID,
            measureId: measureUUID,
            value: m.value,
            createdAt: parseDate(m.createdAt) ?? Date(),
            id: measuredActionUUID
        )

        let measure = Measure(
            unit: m.measureUnit,
            measureType: m.measureType,
            title: m.measureTitle,
            detailedDescription: m.measureDetailedDescription,
            freeformNotes: m.measureFreeformNotes,
            canonicalUnit: m.measureCanonicalUnit,
            conversionFactor: m.measureConversionFactor,
            logTime: parseDate(m.measureLogTime) ?? Date(),
            id: measureUUID
        )

        return ActionMeasurement(measuredAction: measuredAction, measure: measure)
    }

    // Parse contributions JSON
    let contributionsData = row.contributionsJson.data(using: .utf8)!
    let contributionsJson = try decoder.decode([ContributionJsonRow].self, from: contributionsData)

    let contributions: [ActionContribution] = try contributionsJson.map { c in
        guard let contributionUUID = UUID(uuidString: c.contributionId),
              let goalUUID = UUID(uuidString: c.goalId) else {
            throw ValidationError.databaseConstraint("Invalid UUID in contribution for action \(row.actionId)")
        }

        let measureUUID: UUID? = if let mid = c.measureId {
            UUID(uuidString: mid)
        } else {
            nil
        }

        let contribution = ActionGoalContribution(
            actionId: actionUUID,
            goalId: goalUUID,
            contributionAmount: c.contributionAmount,
            measureId: measureUUID,
            createdAt: parseDate(c.createdAt) ?? Date(),
            id: contributionUUID
        )

        // Note: Goal is minimal here (just ID), full details fetched elsewhere if needed
        let goal = Goal(
            expectationId: UUID(),  // Placeholder - not used in list view
            startDate: nil,
            targetDate: nil,
            actionPlan: nil,
            expectedTermLength: nil,
            id: goalUUID
        )

        return ActionContribution(contribution: contribution, goal: goal)
    }

    return ActionWithDetails(
        action: action,
        measurements: measurements,
        contributions: contributions
    )
}

// MARK: - Date Parsing Helper

/// Parse ISO8601 date string to Date
///
/// **Pattern**: Shared with GoalRepository (GoalRepository.swift:425-434)
private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString else { return nil }
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: dateString)
}

// MARK: - Implementation Notes

// MIGRATION FROM QUERY BUILDERS TO JSON AGGREGATION
//
// **Previous Pattern** (ActionRepository.swift before 2025-11-13):
// - 3-4 separate queries with query builders
// - Dictionary(grouping:) for in-memory assembly
// - ~150ms for 381 actions (3 queries + Swift grouping)
//
// **New Pattern** (following GoalRepository.swift:452-508):
// - Single SQL query with json_group_array()
// - Database-side aggregation (SQLite does the grouping)
// - Expected ~50-70ms for same dataset (2-3x improvement)
//
// **Benefits**:
// 1. **Performance**: 3 queries → 1 query (fewer round trips)
// 2. **Database work**: SQLite does grouping (more efficient than Swift)
// 3. **Consistency**: Matches GoalRepository pattern exactly
// 4. **Maintainability**: All relationship logic in SQL (not scattered across fetch requests)
//
// **Trade-offs**:
// - Longer SQL string (but clearer intent)
// - JSON parsing overhead (minimal with JSONDecoder)
// - Requires FetchableRecord from GRDB (minimal import)
//
// **Reference Implementation**: GoalRepository.swift:260-508
// **Migration Date**: 2025-11-13
