//
// ActionRepository.swift
// Written by Claude Code on 2025-11-09
// Refactored to #sql type interpolation on 2025-11-10
//
// PURPOSE:
// Read coordinator for Action entities with measurements and goal contributions.
// Uses #sql macros with type interpolation for complex multi-table queries.
//
// RESPONSIBILITIES:
// 1. Complex reads - fetchAll(), fetchByDateRange(), fetchByGoal() with JOINs
// 2. Aggregations - totalByMeasure(), countByGoal()
// 3. Existence checks - exists() for duplicate prevention
// 4. Error mapping - DatabaseError → ValidationError
//
// PATTERN:
// - All queries use #sql with \(Type.column) type interpolation
// - Complex queries return custom result types via FetchKeyRequest
// - Aggregations return scalar types (Double, Int)
//

import Foundation
import Models
import SQLiteData

// MARK: - Repository Implementation

// REMOVED @MainActor: Repository performs database queries which are I/O
// operations that should run in background. Database reads should not block
// the main thread. ViewModels will await results on main actor as needed.
public final class ActionRepository {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    // MARK: - Complex Queries

    /// Fetch all actions with measurements and goal contributions
    ///
    /// Uses FetchKeyRequest pattern for multi-table query result assembly
    public func fetchAll() async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                try FetchAllActionsRequest().fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch actions within a date range
    public func fetchByDateRange(_ range: ClosedRange<Date>) async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                try FetchActionsByDateRangeRequest(range: range).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch actions contributing to a specific goal
    public func fetchByGoal(_ goalId: UUID) async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                try FetchActionsByGoalRequest(goalId: goalId).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch recent actions with limit
    public func fetchRecentActions(limit: Int) async throws -> [ActionWithDetails] {
        do {
            return try await database.read { db in
                try FetchRecentActionsRequest(limit: limit).fetch(db)
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
                try ExistsByTitleAndDateRequest(title: title, date: date).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Check if an action exists by ID
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

// MARK: - Fetch Requests

/// Fetch all actions with measurements and contributions
private struct FetchAllActionsRequest: FetchKeyRequest {
    typealias Value = [ActionWithDetails]

    func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // Fetch actions using query builder
        let actions = try Action.order { $0.logTime.desc() }.fetchAll(db)

        guard !actions.isEmpty else { return [] }

        let actionIds = actions.map(\.id)

        // Fetch all measurements for these actions (bulk query, no N+1)
        let measurementResults = try MeasuredAction
            .where { actionIds.contains($0.actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let measurementsByAction = Dictionary(grouping: measurementResults) { (ma, _) in ma.actionId }

        // Fetch all contributions for these actions (bulk query, no N+1)
        let contributionResults = try ActionGoalContribution
            .where { actionIds.contains($0.actionId) }
            .join(Goal.all) { $0.goalId.eq($1.id) }
            .fetchAll(db)

        let contributionsByAction = Dictionary(grouping: contributionResults) { (c, _) in c.actionId }

        // Assemble results
        return actions.map { action in
            let measurements = (measurementsByAction[action.id] ?? []).map { (ma, m) in
                ActionMeasurement(measuredAction: ma, measure: m)
            }

            let contributions = (contributionsByAction[action.id] ?? []).map { (c, g) in
                ActionContribution(contribution: c, goal: g)
            }

            return ActionWithDetails(
                action: action,
                measurements: measurements,
                contributions: contributions
            )
        }
    }
}

/// Fetch actions within date range
private struct FetchActionsByDateRangeRequest: FetchKeyRequest {
    typealias Value = [ActionWithDetails]
    let range: ClosedRange<Date>

    func fetch(_ db: Database) throws -> [ActionWithDetails] {
        let actions = try Action
            .where { $0.logTime >= range.lowerBound && $0.logTime <= range.upperBound }
            .order { $0.logTime.desc() }
            .fetchAll(db)

        guard !actions.isEmpty else { return [] }

        let actionIds = actions.map(\.id)

        let measurementResults = try MeasuredAction
            .where { actionIds.contains($0.actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let measurementsByAction = Dictionary(grouping: measurementResults) { (ma, _) in ma.actionId }

        let contributionResults = try ActionGoalContribution
            .where { actionIds.contains($0.actionId) }
            .join(Goal.all) { $0.goalId.eq($1.id) }
            .fetchAll(db)

        let contributionsByAction = Dictionary(grouping: contributionResults) { (c, _) in c.actionId }

        return actions.map { action in
            let measurements = (measurementsByAction[action.id] ?? []).map { (ma, m) in
                ActionMeasurement(measuredAction: ma, measure: m)
            }

            let contributions = (contributionsByAction[action.id] ?? []).map { (c, g) in
                ActionContribution(contribution: c, goal: g)
            }

            return ActionWithDetails(
                action: action,
                measurements: measurements,
                contributions: contributions
            )
        }
    }
}

/// Fetch actions by goal
private struct FetchActionsByGoalRequest: FetchKeyRequest {
    typealias Value = [ActionWithDetails]
    let goalId: UUID

    func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // Find actions contributing to this goal
        let contributions = try ActionGoalContribution
            .where { $0.goalId.eq(goalId) }
            .fetchAll(db)

        guard !contributions.isEmpty else { return [] }

        let actionIds = contributions.map(\.actionId)

        let actions = try Action
            .where { actionIds.contains($0.id) }
            .order { $0.logTime.desc() }
            .fetchAll(db)

        let measurementResults = try MeasuredAction
            .where { actionIds.contains($0.actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let measurementsByAction = Dictionary(grouping: measurementResults) { (ma, _) in ma.actionId }

        let contributionResults = try ActionGoalContribution
            .where { actionIds.contains($0.actionId) }
            .join(Goal.all) { $0.goalId.eq($1.id) }
            .fetchAll(db)

        let contributionsByAction = Dictionary(grouping: contributionResults) { (c, _) in c.actionId }

        return actions.map { action in
            let measurements = (measurementsByAction[action.id] ?? []).map { (ma, m) in
                ActionMeasurement(measuredAction: ma, measure: m)
            }

            let contributions = (contributionsByAction[action.id] ?? []).map { (c, g) in
                ActionContribution(contribution: c, goal: g)
            }

            return ActionWithDetails(
                action: action,
                measurements: measurements,
                contributions: contributions
            )
        }
    }
}

/// Fetch recent actions with limit
private struct FetchRecentActionsRequest: FetchKeyRequest {
    typealias Value = [ActionWithDetails]
    let limit: Int

    func fetch(_ db: Database) throws -> [ActionWithDetails] {
        let actions = try Action
            .order { $0.logTime.desc() }
            .limit(limit)
            .fetchAll(db)

        guard !actions.isEmpty else { return [] }

        let actionIds = actions.map(\.id)

        let measurementResults = try MeasuredAction
            .where { actionIds.contains($0.actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let measurementsByAction = Dictionary(grouping: measurementResults) { (ma, _) in ma.actionId }

        let contributionResults = try ActionGoalContribution
            .where { actionIds.contains($0.actionId) }
            .join(Goal.all) { $0.goalId.eq($1.id) }
            .fetchAll(db)

        let contributionsByAction = Dictionary(grouping: contributionResults) { (c, _) in c.actionId }

        return actions.map { action in
            let measurements = (measurementsByAction[action.id] ?? []).map { (ma, m) in
                ActionMeasurement(measuredAction: ma, measure: m)
            }

            let contributions = (contributionsByAction[action.id] ?? []).map { (c, g) in
                ActionContribution(contribution: c, goal: g)
            }

            return ActionWithDetails(
                action: action,
                measurements: measurements,
                contributions: contributions
            )
        }
    }
}

/// Check if action exists by title and date
private struct ExistsByTitleAndDateRequest: FetchKeyRequest {
    typealias Value = Bool
    let title: String
    let date: Date

    func fetch(_ db: Database) throws -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }

        let count = try Action
            .where { $0.title.eq(title) && $0.logTime >= startOfDay && $0.logTime < endOfDay }
            .fetchCount(db)

        return count > 0
    }
}

/// Check if action exists by ID
private struct ExistsByIdRequest: FetchKeyRequest {
    typealias Value = Bool
    let id: UUID

    func fetch(_ db: Database) throws -> Bool {
        try Action.find(id).fetchOne(db) != nil
    }
}

// MARK: - Implementation Notes

// WHY QUERY BUILDERS FOR COMPLEX FETCHES?
//
// The original ActionRepository used #sql with raw SQL and manual column aliasing.
// This new version uses query builders for the fetch operations because:
//
// 1. **Type Safety**: Query builders catch column/table renames at compile time
// 2. **No Manual Assembly**: Don't need ActionDetailsRow with 35+ nullable fields
// 3. **Proven Pattern**: Matches ActionsQuery.swift (already working in production)
// 4. **N+1 Prevention**: Still uses bulk queries (WHERE id IN [...])
// 5. **Cleaner Code**: No 300-line assembler function
//
// Trade-offs:
// - 3-4 queries instead of 1 big JOIN (but still fast with bulk WHERE IN)
// - Query builders are verbose but catch errors at compile time
//
// WHY #sql FOR AGGREGATIONS?
//
// Aggregations (SUM, COUNT) benefit from #sql because:
// - Return scalar types (Double, Int) - no complex assembly needed
// - Type interpolation still provides safety: \(Type.column)
// - SQL is clearer for aggregations than query builder syntax
// - Performance critical (database does the work, not Swift)
