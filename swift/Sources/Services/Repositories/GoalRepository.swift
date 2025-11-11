//
// GoalRepository.swift
// Written by Claude Code on 2025-11-08
// Implemented on 2025-11-10 following Swift 6 concurrency patterns
//
// PURPOSE:
// Read coordinator for Goal entities - centralizes query logic and existence checks.
// Complements GoalCoordinator (writes) by handling all read operations.
//
// RESPONSIBILITIES:
// 1. Complex reads - fetchAll(), fetchActiveGoals(), fetchByTerm(), fetchByValue()
// 2. Existence checks - existsByTitle() for duplicate prevention
// 3. Error mapping - DatabaseError → ValidationError
//
// PATTERN:
// - Query builders for multi-table fetches (following GoalsQuery pattern)
// - #sql for simple queries and aggregations
// - FetchKeyRequest for complex multi-value results
//

import Foundation
import Models
import SQLiteData
import GRDB  // For FetchableRecord protocol

// REMOVED @MainActor: Repository performs database queries which are I/O
// operations that should run in background. Database reads should not block
// the main thread. ViewModels will await results on main actor as needed.
public final class GoalRepository {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    // MARK: - Read Operations

    /// Fetch all goals with full relationship graph
    ///
    /// Uses bulk-fetch pattern: 5 queries total regardless of goal count
    public func fetchAll() async throws -> [GoalWithDetails] {
        do {
            return try await database.read { db in
                try FetchAllGoalsRequest().fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch active goals (no target date or target date in future)
    ///
    /// Used by QuickAdd sections where only active goals are relevant
    public func fetchActiveGoals() async throws -> [GoalWithDetails] {
        do {
            return try await database.read { db in
                try FetchActiveGoalsRequest().fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch goals assigned to a specific term
    public func fetchByTerm(_ termId: UUID) async throws -> [GoalWithDetails] {
        do {
            return try await database.read { db in
                try FetchGoalsByTermRequest(termId: termId).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch goals aligned with a specific personal value
    ///
    /// Returns simple Goal array (no full details) for lightweight value alignment display
    public func fetchByValue(_ valueId: UUID) async throws -> [Goal] {
        do {
            return try await database.read { db in
                try #sql(
                    """
                    SELECT \(Goal.columns)
                    FROM \(Goal.self)
                    INNER JOIN \(GoalRelevance.self) ON \(Goal.id) = \(GoalRelevance.goalId)
                    WHERE \(GoalRelevance.valueId) = \(bind: valueId)
                    ORDER BY \(Goal.targetDate) ASC
                    """,
                    as: Goal.self
                ).fetchAll(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Dashboard Queries

    /// Fetch all goals with progress calculations for dashboard
    ///
    /// **PERMANENT PATTERN**: Using #sql macro for complex aggregations
    /// This is the production pattern for dashboard queries that need
    /// multi-table JOINs with SQL aggregations (SUM, COALESCE, CASE).
    ///
    /// Returns simplified progress data optimized for dashboard display.
    /// Business logic (status determination, projections) handled by service layer.
    public func fetchAllWithProgress() async throws -> [GoalProgressData] {
        do {
            return try await database.read { db in
                try FetchGoalProgressRequest().fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Existence Checks

    /// Check if a goal with this title already exists (case-insensitive)
    ///
    /// Queries the Expectation table since goal titles are stored there
    public func existsByTitle(_ title: String) async throws -> Bool {
        do {
            return try await database.read { db in
                try ExistsByTitleRequest(title: title).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Check if a goal exists by ID
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
            if dbError.message?.contains("valueId") == true {
                return .emptyValue("Personal value not found")
            }
            if dbError.message?.contains("termId") == true {
                return .databaseConstraint("Term not found")
            }
            return .foreignKeyViolation("Referenced entity not found")
        case .SQLITE_CONSTRAINT_UNIQUE:
            return .duplicateRecord("A goal with this title already exists")
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

/// Fetch all goals with full relationship graph
///
/// Follows the pattern from GoalsQuery.swift with bulk-fetch strategy
private struct FetchAllGoalsRequest: FetchKeyRequest {
    typealias Value = [GoalWithDetails]

    func fetch(_ db: Database) throws -> [GoalWithDetails] {
        // 1. Fetch Goals + Expectations
        let goalsWithExpectations = try Goal.all
            .order { $0.targetDate ?? Date.distantFuture }
            .join(Expectation.all) { $0.expectationId.eq($1.id) }
            .fetchAll(db)

        guard !goalsWithExpectations.isEmpty else { return [] }

        // 2. Collect IDs for bulk fetching
        let goalIds = goalsWithExpectations.map { $0.0.id }
        let expectationIds = goalsWithExpectations.map { $0.0.expectationId }

        // 3. Bulk fetch ExpectationMeasures + Measures
        let measuresWithTargets = try ExpectationMeasure
            .where { expectationIds.contains($0.expectationId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }

        // 4. Bulk fetch GoalRelevances + PersonalValues
        let relevancesWithValues = try GoalRelevance
            .where { goalIds.contains($0.goalId) }
            .join(PersonalValue.all) { $0.valueId.eq($1.id) }
            .fetchAll(db)

        let alignmentsByGoal = Dictionary(grouping: relevancesWithValues) { $0.0.goalId }

        // 5. Bulk fetch TermGoalAssignments
        let termAssignments = try TermGoalAssignment
            .where { goalIds.contains($0.goalId) }
            .fetchAll(db)

        // Handle duplicate assignments - keep most recent
        let assignmentsByGoal = Dictionary(
            termAssignments.map { ($0.goalId, $0) },
            uniquingKeysWith: { existing, new in
                new.createdAt > existing.createdAt ? new : existing
            }
        )

        // 6. Assemble results
        return goalsWithExpectations.map { (goal, expectation) in
            let targets = targetsByExpectation[expectation.id]?.map { (measure, metric) in
                ExpectationMeasureWithMetric(expectationMeasure: measure, measure: metric)
            } ?? []

            let alignments = alignmentsByGoal[goal.id]?.map { (relevance, value) in
                GoalRelevanceWithValue(goalRelevance: relevance, value: value)
            } ?? []

            return GoalWithDetails(
                goal: goal,
                expectation: expectation,
                metricTargets: targets,
                valueAlignments: alignments,
                termAssignment: assignmentsByGoal[goal.id]
            )
        }
    }
}

/// Fetch active goals (target date in future or null)
private struct FetchActiveGoalsRequest: FetchKeyRequest {
    typealias Value = [GoalWithDetails]

    func fetch(_ db: Database) throws -> [GoalWithDetails] {
        let now = Date()

        // Fetch all goals + expectations, then filter in-memory
        let allGoalsWithExpectations = try Goal.all
            .join(Expectation.all) { $0.expectationId.eq($1.id) }
            .fetchAll(db)

        // Filter to active goals
        let goalsWithExpectations = allGoalsWithExpectations
            .filter { (goal, _) in
                goal.targetDate == nil || goal.targetDate! >= now
            }
            .sorted { (a, b) in
                let dateA = a.0.targetDate ?? Date.distantFuture
                let dateB = b.0.targetDate ?? Date.distantFuture
                return dateA < dateB
            }

        guard !goalsWithExpectations.isEmpty else { return [] }

        let expectationIds = goalsWithExpectations.map { $0.0.expectationId }

        // Bulk fetch ExpectationMeasures + Measures for QuickAdd forms
        let measuresWithTargets = try ExpectationMeasure
            .where { expectationIds.contains($0.expectationId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }

        return goalsWithExpectations.map { (goal, expectation) in
            let targets = targetsByExpectation[expectation.id]?.map { (measure, metric) in
                ExpectationMeasureWithMetric(expectationMeasure: measure, measure: metric)
            } ?? []

            return GoalWithDetails(
                goal: goal,
                expectation: expectation,
                metricTargets: targets,
                valueAlignments: [], // Not needed for QuickAdd
                termAssignment: nil  // Not needed for QuickAdd
            )
        }
    }
}

/// Fetch goals assigned to a specific term
private struct FetchGoalsByTermRequest: FetchKeyRequest {
    typealias Value = [GoalWithDetails]
    let termId: UUID

    func fetch(_ db: Database) throws -> [GoalWithDetails] {
        // Find goals assigned to this term
        let assignments = try TermGoalAssignment
            .where { $0.termId.eq(termId) }
            .fetchAll(db)

        guard !assignments.isEmpty else { return [] }

        let goalIds = assignments.map(\.goalId)

        // Fetch goals + expectations
        let goalsWithExpectations = try Goal
            .where { goalIds.contains($0.id) }
            .join(Expectation.all) { $0.expectationId.eq($1.id) }
            .fetchAll(db)

        guard !goalsWithExpectations.isEmpty else { return [] }

        let expectationIds = goalsWithExpectations.map { $0.0.expectationId }

        // Bulk fetch measures and relevances
        let measuresWithTargets = try ExpectationMeasure
            .where { expectationIds.contains($0.expectationId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }

        let relevancesWithValues = try GoalRelevance
            .where { goalIds.contains($0.goalId) }
            .join(PersonalValue.all) { $0.valueId.eq($1.id) }
            .fetchAll(db)

        let alignmentsByGoal = Dictionary(grouping: relevancesWithValues) { $0.0.goalId }

        // Map assignments by goal ID
        let assignmentsByGoal = Dictionary(
            assignments.map { ($0.goalId, $0) },
            uniquingKeysWith: { existing, new in new }
        )

        return goalsWithExpectations.map { (goal, expectation) in
            let targets = targetsByExpectation[expectation.id]?.map { (measure, metric) in
                ExpectationMeasureWithMetric(expectationMeasure: measure, measure: metric)
            } ?? []

            let alignments = alignmentsByGoal[goal.id]?.map { (relevance, value) in
                GoalRelevanceWithValue(goalRelevance: relevance, value: value)
            } ?? []

            return GoalWithDetails(
                goal: goal,
                expectation: expectation,
                metricTargets: targets,
                valueAlignments: alignments,
                termAssignment: assignmentsByGoal[goal.id]
            )
        }
    }
}

/// Check if a goal with this title exists (queries Expectation table)
private struct ExistsByTitleRequest: FetchKeyRequest {
    typealias Value = Bool
    let title: String

    func fetch(_ db: Database) throws -> Bool {
        // Goal titles are stored in the Expectation table
        // Check both directly linked expectations and via goals
        let count = try #sql(
            """
            SELECT COUNT(*)
            FROM \(Expectation.self)
            WHERE LOWER(\(Expectation.title)) = LOWER(\(bind: title))
              AND \(Expectation.expectationType) = 'goal'
            """,
            as: Int.self
        ).fetchOne(db) ?? 0
        return count > 0
    }
}

/// Check if a goal exists by ID
private struct ExistsByIdRequest: FetchKeyRequest {
    typealias Value = Bool
    let id: UUID

    func fetch(_ db: Database) throws -> Bool {
        try Goal.find(id).fetchOne(db) != nil
    }
}

// MARK: - Dashboard Data Types

/// Raw progress data from SQL aggregation
///
/// **PERMANENT PATTERN**: Lightweight DTO for dashboard queries
/// Maps directly to SQL result columns - no complex object graph.
/// Service layer transforms this into business domain objects.
public struct GoalProgressData: Identifiable, Sendable {
    public let id: UUID                    // Goal ID
    public let goalTitle: String           // From expectations.title
    public let targetDate: Date?           // Goal deadline
    public let startDate: Date?            // Goal start
    public let measureId: UUID             // Which measure we're tracking
    public let measureName: String         // From measures.title
    public let measureUnit: String         // From measures.unit (km, hours, etc)
    public let targetValue: Double         // From expectationMeasures.targetValue
    public let currentProgress: Double     // SUM(measuredActions.value)
    public let percentComplete: Double     // Calculated percentage
    public let daysRemaining: Int?        // Days until targetDate

    // Note: Status calculation moved to service layer (business logic)
}

// MARK: - Dashboard Fetch Requests

/// Fetch goal progress with 6-table JOIN and aggregations
///
/// **PERMANENT PATTERN**: #sql macro for complex dashboard queries
/// Based on SQL_QUERY_PATTERNS.md Query 1 (Goal Progress Overview).
///
/// This demonstrates the production pattern for dashboard aggregations:
/// - Multi-table JOINs with LEFT JOINs for optional data
/// - SQL aggregations (SUM, COALESCE) for progress calculations
/// - Direct SQL for clarity and performance
/// - Type-safe parameter binding with \(bind:)
private struct FetchGoalProgressRequest: FetchKeyRequest {
    typealias Value = [GoalProgressData]

    func fetch(_ db: Database) throws -> [GoalProgressData] {
        // Use #sql macro with type interpolation for table/column safety
        // Raw SQL approach chosen for dashboard queries per user requirements
        let rows = try #sql(
            """
            SELECT
                goals.id,
                expectations.title as goalTitle,
                goals.targetDate,
                goals.startDate,
                measures.id as measureId,
                measures.title as measureName,
                measures.unit as measureUnit,
                expectationMeasures.targetValue,
                -- Progress calculation with NULL handling
                COALESCE(SUM(measuredActions.value), 0) as currentProgress,
                -- Percentage with safe division
                CASE
                    WHEN expectationMeasures.targetValue > 0 THEN
                        ROUND(COALESCE(SUM(measuredActions.value), 0) / expectationMeasures.targetValue * 100, 1)
                    ELSE 0
                END as percentComplete,
                -- Days remaining (NULL if no target date)
                CASE
                    WHEN goals.targetDate IS NOT NULL THEN
                        CAST(JULIANDAY(goals.targetDate) - JULIANDAY('now') AS INTEGER)
                    ELSE NULL
                END as daysRemaining
            FROM \(Goal.self)
            INNER JOIN \(Expectation.self) ON goals.expectationId = expectations.id
            INNER JOIN \(ExpectationMeasure.self) ON expectations.id = expectationMeasures.expectationId
            INNER JOIN \(Measure.self) ON expectationMeasures.measureId = measures.id
            -- LEFT JOIN to include goals without actions yet
            LEFT JOIN \(ActionGoalContribution.self) ON goals.id = actionGoalContributions.goalId
            LEFT JOIN \(Action.self) ON actionGoalContributions.actionId = actions.id
            LEFT JOIN \(MeasuredAction.self)
                ON actions.id = measuredActions.actionId
                AND measuredActions.measureId = measures.id
            -- Group by goal AND measure (goals can have multiple measures)
            GROUP BY goals.id, expectationMeasures.id
            -- Order by urgency: behind goals first, then by deadline
            ORDER BY
                percentComplete ASC,
                goals.targetDate ASC NULLS LAST
            """,
            as: GoalProgressRow.self
        ).fetchAll(db)

        // Convert SQL rows to domain objects
        return rows.map { row in
            GoalProgressData(
                id: row.id,
                goalTitle: row.goalTitle,
                targetDate: row.targetDate,
                startDate: row.startDate,
                measureId: row.measureId,
                measureName: row.measureName,
                measureUnit: row.measureUnit,
                targetValue: row.targetValue,
                currentProgress: row.currentProgress,
                percentComplete: row.percentComplete,
                daysRemaining: row.daysRemaining
            )
        }
    }
}

/// SQL result row for goal progress query
///
/// Maps to SQL column names for automatic decoding
private struct GoalProgressRow: FetchableRecord, Sendable {
    let id: UUID
    let goalTitle: String
    let targetDate: Date?
    let startDate: Date?
    let measureId: UUID
    let measureName: String
    let measureUnit: String
    let targetValue: Double
    let currentProgress: Double
    let percentComplete: Double
    let daysRemaining: Int?
}

// MARK: - Implementation Notes

// QUERY PATTERN CHOICE - HYBRID APPROACH
//
// GoalRepository demonstrates both patterns based on use case:
//
// 1. Query builders for entity fetching (fetchAll, fetchActiveGoals):
//    - Matches proven GoalsQuery.swift pattern (already in production)
//    - Bulk-fetch strategy prevents N+1 queries (5 queries total, not 1 per goal)
//    - Type-safe column references catch renames at compile time
//    - Complex assembly logic benefits from Swift's type system
//
// 2. #sql macro for dashboard aggregations (fetchAllWithProgress):
//    - **PERMANENT PATTERN** for dashboard queries
//    - Complex SQL with aggregations (SUM, COALESCE, CASE)
//    - Direct SQL provides clarity for business logic
//    - Performance-critical dashboard queries
//    - User preference for SQL explicitness over abstractions
//
// SWIFT 6 CONCURRENCY
//
// - NO @MainActor: Database I/O should run in background
// - Repository is Sendable-safe (immutable state, final class)
// - ViewModels await results on main actor automatically
// - Pattern matches PersonalValueCoordinator.swift
