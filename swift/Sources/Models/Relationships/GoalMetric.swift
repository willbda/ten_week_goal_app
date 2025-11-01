// GoalMetric.swift
// Relationship between goals and their measurement targets
//
// Written by Claude Code on 2025-10-28
//
// ARCHITECTURE:
// - Goals describe intentions (what you want to achieve, how you'll approach it)
// - GoalMetrics describe measurable targets (0 to many per goal)
// - A goal can have multiple metrics (distance + time + count)
//
// EXAMPLES:
// Goal "Spring into Running" →
//   - GoalMetric(metricId: distance_km, targetValue: 120.0)
//   - GoalMetric(metricId: duration_hours, targetValue: 20.0)
//   - GoalMetric(metricId: occasions, targetValue: 30.0)
//
// Goal "Get healthier" →
//   - No GoalMetrics (minimal goal)
//
// Goal "Complete project by Friday" →
//   - No GoalMetrics (milestone - just has targetDate in Goal)

import Foundation
import SQLiteData

/// Links a goal to a metric with a target value
///
/// **Database Table**: `goal_metrics`
/// **Purpose**: Store measurable targets for goals
///
/// **Why separate from Goal?**
/// - Goals can have 0 to many metrics
/// - Enables queries: "All goals targeting distance metrics"
/// - Symmetric with ActionMetric (both use junction pattern)
/// - Type-safe: metricId references metrics catalog
///
/// **Usage**:
/// ```swift
/// // Goal: "Spring into Running"
/// let goal = Goal(
///     title: "Spring into Running",
///     startDate: Date("2025-03-01"),
///     targetDate: Date("2025-05-10")
/// )
///
/// // Target: 120 km
/// let distanceTarget = GoalMetric(
///     goalId: goal.id,
///     metricId: metricsKm.id,
///     targetValue: 120.0
/// )
///
/// // Target: 30 runs
/// let frequencyTarget = GoalMetric(
///     goalId: goal.id,
///     metricId: metricsOccasions.id,
///     targetValue: 30.0
/// )
/// ```
@Table
public struct GoalMetric: Persistable, Sendable {
    // MARK: - Required Fields (Persistable)

    public var id: UUID
    public var logTime: Date

    // MARK: - Optional Persistable Fields

    /// Optional: Human-readable label for this target
    /// Example: "Weekly running target", "Total distance goal"
    public var title: String?

    /// Optional: Additional context about this metric
    public var detailedDescription: String?

    /// Optional: Notes about target calculation or rationale
    /// Example: "Based on current 40km/week average, 10% weekly increase"
    public var freeformNotes: String?

    // MARK: - Relationship Fields

    /// The goal this metric belongs to
    public var goalId: UUID

    /// The metric being targeted (references metrics catalog)
    /// Example: UUID of "distance_km" metric
    public var metricId: UUID

    /// The target value to achieve
    /// Example: 120.0 (for 120 kilometers)
    public var targetValue: Double

    // MARK: - Initialization

    /// Create a new goal metric target
    ///
    /// - Parameters:
    ///   - goalId: The goal this metric belongs to
    ///   - metricId: The metric being targeted (from metrics catalog)
    ///   - targetValue: The target value to achieve
    ///   - title: Optional human-readable label
    ///   - detailedDescription: Optional additional context
    ///   - freeformNotes: Optional notes about target rationale
    ///   - logTime: When this metric was created (defaults to now)
    ///   - id: Unique identifier (generates new UUID if not provided)
    public init(
        goalId: UUID,
        metricId: UUID,
        targetValue: Double,
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.logTime = logTime
        self.goalId = goalId
        self.metricId = metricId
        self.targetValue = targetValue
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
    }
}
