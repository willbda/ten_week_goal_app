//
// GoalWithDetails.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Wrapper type combining Goal + Expectation + related data
// PATTERN: Like TermWithPeriod, ActionWithDetails
// USAGE: Returned by GoalsQuery, passed to GoalRowView (avoids N+1 queries)
//

import Foundation
import Models

/// Wrapper combining Goal with its full relationship graph
///
/// Fetched efficiently via single JOIN query in GoalsQuery.
/// Passed to GoalRowView to avoid N+1 queries in list display.
public struct GoalWithDetails: Identifiable, Hashable, Sendable {
    public let goal: Goal
    public let expectation: Expectation
    public let metricTargets: [ExpectationMeasureWithMetric]
    public let valueAlignments: [GoalRelevanceWithValue]
    public let termAssignment: TermGoalAssignment?

    public var id: UUID { goal.id }

    public init(
        goal: Goal,
        expectation: Expectation,
        metricTargets: [ExpectationMeasureWithMetric] = [],
        valueAlignments: [GoalRelevanceWithValue] = [],
        termAssignment: TermGoalAssignment? = nil
    ) {
        self.goal = goal
        self.expectation = expectation
        self.metricTargets = metricTargets
        self.valueAlignments = valueAlignments
        self.termAssignment = termAssignment
    }
}

/// Helper: ExpectationMeasure with its Measure
public struct ExpectationMeasureWithMetric: Identifiable, Hashable, Sendable {
    public let expectationMeasure: ExpectationMeasure
    public let measure: Measure
    public var id: UUID { expectationMeasure.id }

    public init(expectationMeasure: ExpectationMeasure, measure: Measure) {
        self.expectationMeasure = expectationMeasure
        self.measure = measure
    }
}

/// Helper: GoalRelevance with its PersonalValue
public struct GoalRelevanceWithValue: Identifiable, Hashable, Sendable {
    public let goalRelevance: GoalRelevance
    public let value: PersonalValue
    public var id: UUID { goalRelevance.id }

    public init(goalRelevance: GoalRelevance, value: PersonalValue) {
        self.goalRelevance = goalRelevance
        self.value = value
    }
}
