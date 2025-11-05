// ExpectationMeasure.swift
// Relationship between expectations and their measurement targets
//
// Written by Claude Code on 2025-10-28
// Updated by Claude Code on 2025-10-31 (renamed from GoalMetric to ExpectationMeasure)
//
// ARCHITECTURE:
// - Expectations describe intentions (what you want to achieve, how you'll approach it)
// - ExpectationMeasures describe measurable targets (0 to many per expectation)
// - A goal can have multiple metrics (distance + time + count)
//
// EXAMPLES:
// Goal "Spring into Running" →
//   - ExpectationMeasure(expectationId: goalId, measureId: distance_km, targetValue: 120.0)
//   - ExpectationMeasure(expectationId: goalId, measureId: duration_hours, targetValue: 20.0)
//   - ExpectationMeasure(expectationId: goalId, measureId: occasions, targetValue: 30.0)
//
// Goal "Get healthier" →
//   - No ExpectationMeasures (minimal goal)
//
// Milestone "Reach 50km by week 5" →
//   - No ExpectationMeasures (milestone - just has targetDate in Expectation)

import Foundation
import SQLiteData

/// Links an expectation to a metric with a target value
///
/// **Database Table**: `expectation_measures` (or `goalMetrics` in legacy schemas)
/// **Purpose**: Store measurable targets for expectations (goals, milestones, obligations)
///
/// **Why separate from Expectation?**
/// - Expectations can have 0 to many metrics
/// - Enables queries: "All expectations targeting distance metrics"
/// - Symmetric with MeasuredAction (both use junction pattern)
/// - Type-safe: measureId references metrics catalog
///
/// **Usage**:
/// ```swift
/// // Expectation: "Spring into Running"
/// let expectation = Expectation(
///     title: "Spring into Running",
///     expectationType: .goal
/// )
/// let goal = Goal(
///     expectationId: expectation.id,
///     startDate: Date("2025-03-01"),
///     targetDate: Date("2025-05-10")
/// )
///
/// // Target: 120 km
/// let distanceTarget = ExpectationMeasure(
///     expectationId: expectation.id,
///     measureId: metricsKm.id,
///     targetValue: 120.0
/// )
///
/// // Target: 30 runs
/// let frequencyTarget = ExpectationMeasure(
///     expectationId: expectation.id,
///     measureId: metricsOccasions.id,
///     targetValue: 30.0
/// )
/// ```
@Table
public struct ExpectationMeasure: DomainBasic {
    // MARK: - Identity

    public var id: UUID

    // MARK: - Documentation

    /// Optional: Notes about target calculation or rationale
    /// Example: "Based on current 40km/week average, 10% weekly increase"
    ///
    /// **Special case**: ExpectationMeasure keeps freeformNotes (unlike other Composits)
    /// because target-setting often needs explanation ("Why 120km? Based on 10% growth")
    public var freeformNotes: String?

    // MARK: - Relationship Fields

    /// The expectation this metric belongs to
    public var expectationId: UUID

    /// The metric being targeted (references metrics catalog)
    /// Example: UUID of "distance_km" metric
    public var measureId: UUID

    /// The target value to achieve
    /// Example: 120.0 (for 120 kilometers)
    public var targetValue: Double

    /// When this target was set
    /// Tracks when expectations are defined or revised
    public var createdAt: Date

    // MARK: - Initialization

    /// Create a new expectation metric target
    ///
    /// - Parameters:
    ///   - expectationId: The expectation this metric belongs to
    ///   - measureId: The metric being targeted (from metrics catalog)
    ///   - targetValue: The target value to achieve
    ///   - createdAt: When this target was set (defaults to now)
    ///   - freeformNotes: Optional notes about target rationale
    ///   - id: Unique identifier (generates new UUID if not provided)
    public init(
        expectationId: UUID,
        measureId: UUID,
        targetValue: Double,
        createdAt: Date = Date(),
        freeformNotes: String? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.expectationId = expectationId
        self.measureId = measureId
        self.targetValue = targetValue
        self.createdAt = createdAt
        self.freeformNotes = freeformNotes
    }
}
