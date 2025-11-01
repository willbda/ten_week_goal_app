// Goals.swift
// Domain entity representing objectives and intentions
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (consolidated Goal/SmartGoal, removed Doable properties)
// Updated by Claude Code on 2025-10-28 (decomposed into Goal + GoalMetric)
// Ported from Python implementation (python/categoriae/goals.py)
//
// ARCHITECTURE:
// - Goal: The narrative/intention (what you want to achieve, why, how)
// - GoalMetric: Measurable targets (0 to many per goal)
// - Classification (milestone, SMART, etc.): Determined by services examining Goal + GoalMetrics
//
// A goal can be:
// - Minimal: Just narrative, no metrics (e.g., "Get healthier")
// - Measured: Narrative + metrics (e.g., "Run 120km in 10 weeks")
// - SMART: Measured + complete metadata (dates, action plan, value alignment)
//
// Services determine classification by querying:
// - Has metrics? → Measured
// - Has metrics + dates + action plan? → SMART
// - Has only targetDate, no metrics? → Milestone

import Foundation
import SQLiteData

// MARK: - Goal Struct

/// Represents the narrative and intention of a goal
///
/// Goals describe **what you want to achieve** and **how you'll approach it**.
/// Measurement targets are stored separately in GoalMetric relationships.
///
/// **Minimal goal example**:
/// ```swift
/// Goal(title: "Get healthier")
/// // No metrics, no dates - just an intention
/// ```
///
/// **Measured goal example**:
/// ```swift
/// let goal = Goal(
///     title: "Spring into Running",
///     startDate: Date("2025-03-01"),
///     targetDate: Date("2025-05-10"),
///     actionPlan: "Run 3x/week, increase 10% weekly"
/// )
/// // Metrics added separately:
/// GoalMetric(goalId: goal.id, metricId: distanceKm, targetValue: 120.0)
/// GoalMetric(goalId: goal.id, metricId: occasions, targetValue: 30.0)
/// ```
///
/// **Classification**: Determined by services, not stored in Goal
/// - Service queries GoalMetrics for this goal
/// - Evaluates completeness of fields
/// - Returns classification (minimal, milestone, measured, SMART)
@Table
public struct Goal: Persistable, Sendable {
    // MARK: - Required Fields

    public var id: UUID
    public var logTime: Date

    // MARK: - Core Content

    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?

    // MARK: - Temporal Bounds

    public var startDate: Date?
    public var targetDate: Date?

    // MARK: - Implementation Metadata

    public var actionPlan: String?
    public var expectedTermLength: Int?

    // MARK: - Initialization

    public init(
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        actionPlan: String? = nil,
        expectedTermLength: Int? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        precondition(title != nil || detailedDescription != nil,
                    "Goal must have either title or detailedDescription")

        self.id = id
        self.logTime = logTime
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.startDate = startDate
        self.targetDate = targetDate
        self.actionPlan = actionPlan
        self.expectedTermLength = expectedTermLength
    }
}
