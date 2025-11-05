//
// TermsQuery.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Custom query that JOINs GoalTerm + TimePeriod for efficient list display
// PATTERN: Based on SQLiteData's Reminders app Schema.swift JOIN examples
//

import Foundation
import Models
import SQLiteData

/// Combined GoalTerm + TimePeriod for list display
public struct TermWithPeriod: Identifiable, Hashable, Sendable {
    public let term: GoalTerm
    public let timePeriod: TimePeriod

    public var id: UUID { term.id }

    public init(term: GoalTerm, timePeriod: TimePeriod) {
        self.term = term
        self.timePeriod = timePeriod
    }
}

/// Query that fetches GoalTerms with their related TimePeriods
///
/// **Architecture**: Single JOIN query instead of N+1 fetches
/// - Fetches GoalTerm + TimePeriod in one query
/// - Orders by termNumber descending (most recent first)
/// - Observable via @Fetch - updates automatically on database changes
///
/// **Usage**:
/// ```swift
/// @Fetch(TermsWithPeriods())
/// private var termsWithPeriods: [TermWithPeriod]
/// ```
///
/// ---
/// **QUERY STRATEGY: Keep Query Builder**
/// ---
/// **Why not migrate to #sql**:
/// - Simple 1:1 JOIN (no aggregation needed)
/// - Query builder is already optimal
/// - Type safety helps during development
/// - No performance benefit from #sql
///
/// **When #sql WOULD make sense**:
/// - If we add aggregations (COUNT of goals per term)
/// - If we need COALESCE for nullable fields
/// - If we add complex filtering (date ranges, status)
///
/// **Example future #sql query** (if adding aggregations):
/// ```swift
/// struct TermWithStats: Decodable {
///     let term: GoalTerm
///     let timePeriod: TimePeriod
///     let goalsCount: Int
///     let completedGoalsCount: Int
/// }
///
/// let stats = try #sql(
///     """
///     SELECT
///         gt.*, tp.*,
///         COUNT(DISTINCT tga.goalId) as goalsCount,
///         COUNT(DISTINCT CASE WHEN g.status = 'completed' THEN tga.goalId END) as completedGoalsCount
///     FROM goalTerms gt
///     JOIN timePeriods tp ON gt.timePeriodId = tp.id
///     LEFT JOIN termGoalAssignments tga ON tga.termId = gt.id
///     LEFT JOIN goals g ON g.id = tga.goalId
///     GROUP BY gt.id
///     ORDER BY gt.termNumber DESC
///     """
/// ).fetchAll(db) as [TermWithStats]
/// ```
///
/// **Decision**: Query builder is correct choice for this simple JOIN.
///
public struct TermsWithPeriods: FetchKeyRequest {
    public typealias Value = [TermWithPeriod]

    public init() {}

    public func fetch(_ db: Database) throws -> [TermWithPeriod] {
        // Single JOIN query (not N+1)
        // Pattern from audit: SQLiteData returns [(GoalTerm, TimePeriod)] from join
        let results = try GoalTerm.all
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        // Map tuple results to our wrapper type
        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}

// MARK: - JOIN Helper Extension
//
// SQLiteData doesn't have BelongsTo/HasMany like GRDB
// Instead, use manual JOIN queries as shown in fetch() above
//
// Pattern from Reminders app:
//   - Define static computed properties that return JOIN queries
//   - Use .join() with column equality checks
//   - See Reminder.withTags in sqlite-data-main/Examples/Reminders/Schema.swift:73-76
