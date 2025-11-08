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

        // Handle duplicate assignments - keep most recent (by createdAt)
        let assignmentsByGoal = Dictionary(
            termAssignments.map { ($0.goalId, $0) },
            uniquingKeysWith: { existing, new in
                // Keep the one with most recent createdAt
                return new.createdAt > existing.createdAt ? new : existing
            }
        )

        // 6. Combine all data
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

/// Fetches active goals (goals with target dates in the future or null)
///
/// USED BY: ActionsListView Quick Add section
/// PATTERN: Filtered version of GoalsQuery
public struct ActiveGoals: FetchKeyRequest {
    public typealias Value = [GoalWithDetails]

    public init() {}

    public func fetch(_ db: Database) throws -> [GoalWithDetails] {
        let now = Date()

        // Fetch all goals with expectations, then filter/sort in-memory
        // (Avoids Swift type-checker timeout with complex query builder closures)
        let allGoalsWithExpectations = try Goal.all
            .join(Expectation.all) { $0.expectationId.eq($1.id) }
            .fetchAll(db)

        // Filter to active goals (no target date OR target date in future)
        let goalsWithExpectations = allGoalsWithExpectations
            .filter { (goal, _) in
                goal.targetDate == nil || goal.targetDate! >= now
            }
            .sorted { (a, b) in
                let dateA = a.0.targetDate ?? Date.distantFuture
                let dateB = b.0.targetDate ?? Date.distantFuture
                return dateA < dateB
            }

        // For QuickAdd, we also need metric targets (to pre-fill form)
        guard !goalsWithExpectations.isEmpty else { return [] }

        // Collect expectation IDs for bulk fetch
        let expectationIds = goalsWithExpectations.map { $0.0.expectationId }

        // Bulk fetch ExpectationMeasures + Measures
        let measuresWithTargets = try ExpectationMeasure
            .where { expectationIds.contains($0.expectationId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        // Group by expectation ID
        let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }

        return goalsWithExpectations.map { (goal, expectation) in
            let targets = targetsByExpectation[expectation.id]?.map { (measure, metric) in
                ExpectationMeasureWithMetric(expectationMeasure: measure, measure: metric)
            } ?? []

            return GoalWithDetails(
                goal: goal,
                expectation: expectation,
                metricTargets: targets,
                valueAlignments: [],  // Not needed for Quick Add
                termAssignment: nil   // Not needed for Quick Add
            )
        }
    }
}
