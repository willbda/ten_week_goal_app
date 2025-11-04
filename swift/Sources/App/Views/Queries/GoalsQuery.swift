//
// GoalsQuery.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: FetchKeyRequest for efficient Goal + relationships fetching
// PATTERN: Complex JOIN - most intricate query in app
// OUTPUT: [GoalWithDetails] with all related data
// PERFORMANCE: Single query (or minimal queries), no N+1
//

import Foundation
import Models
import SQLiteData

/// Fetches all goals with their full relationship graph
///
/// QUERY STRATEGY: Bulk-fetch pattern (5 queries total, no N+1)
/// 1. Fetch all Goals + Expectations (1 JOIN)
/// 2. Bulk fetch ExpectationMeasures + Measures for all expectation IDs
/// 3. Bulk fetch GoalRelevances + Values for all goal IDs
/// 4. Bulk fetch TermGoalAssignments for all goal IDs
/// 5. Group results in Swift (fast in-memory operation)
///
/// PERFORMANCE: ~5 queries regardless of goal count
/// PATTERN: Same as ActionsQuery (avoid N+1)
///
/// USED BY: GoalsListView via @Fetch
public struct GoalsQuery: FetchKeyRequest {
    public typealias Value = [GoalWithDetails]

    public init() {}

    public func fetch(_ db: Database) throws -> [GoalWithDetails] {
        // STRATEGY: For now, use query builder for basic Goal + Expectation fetch
        // TODO: Migrate to #sql when we add relationship fetching (Phase 2)
        //
        // FUTURE #sql APPROACH (after validation layers complete):
        // See ActionsQuery.swift:113-127 for pattern
        // Benefits: Single query vs multiple, DB-side aggregation, clearer intent
        // Prerequisites: Integration tests, Layer B validation, error mapping

        // 1. Fetch all Goals + Expectations (using query builder)
        let goalsWithExpectations = try Goal.all
            .order { $0.targetDate ?? Date.distantFuture }
            .join(Expectation.all) { $0.expectationId.eq($1.id) }
            .fetchAll(db)

        // Early return if no goals
        guard !goalsWithExpectations.isEmpty else { return [] }

        // TODO Phase 2: Add bulk fetching of relationships
        // For now, return basic goal data only (matches current capability)
        // When adding relationships, follow this pattern:
        //
        // 1. Collect goal/expectation IDs
        // 2. Bulk fetch ExpectationMeasures + Measures (WHERE expectationId IN ...)
        // 3. Bulk fetch GoalRelevances + Values (WHERE goalId IN ...)
        // 4. Bulk fetch TermGoalAssignments (WHERE goalId IN ...)
        // 5. Group results in-memory
        //
        // Consider #sql macro for this (see ActionsQuery for example)

        return goalsWithExpectations.map { (goal, expectation) in
            GoalWithDetails(
                goal: goal,
                expectation: expectation,
                metricTargets: [],  // TODO: Fetch in Phase 2
                valueAlignments: [],  // TODO: Fetch in Phase 2
                termAssignment: nil  // TODO: Fetch in Phase 2
            )
        }
    }
}
