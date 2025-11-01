// ActionMetric.swift
// Junction table linking actions to their measurements
//
// Written by Claude Code on 2025-10-30
//
// ARCHITECTURE:
// - Pure junction table (database artifact)
// - Links Actions to Metrics with measured values
// - Replaces the JSON measuresByUnit dictionary
// - Always accessed in context of its related Persistable entities
//
// 3NF COMPLIANCE:
// - No redundant data (references existing entities)
// - Enables proper indexing and foreign key constraints
// - Each measurement is a separate row (atomic values)
//
// EXAMPLES:
// Action "Morning run" →
//   - ActionMetric(actionId: run.id, metricId: km.id, value: 5.2)
//   - ActionMetric(actionId: run.id, metricId: minutes.id, value: 28.0)

import Foundation
import SQLiteData

/// Links an action to a metric with a measured value
///
/// **Database Table**: `actionMetrics`
/// **Purpose**: Store measurements for actions
///
/// **Design Principle**: This is a pure junction table - a database artifact
/// that exists solely to link Actions and Metrics. It doesn't need Persistable
/// fields because it's always accessed through its related entities.
///
/// **Why separate from Action?**
/// - Actions can have 0 to many measurements
/// - Enables queries: "All actions measuring distance"
/// - Allows indexing on metricId for aggregations
/// - Maintains 3NF (no multi-valued attributes)
///
/// **Usage**:
/// ```swift
/// // Record that an action measured 5.2 km
/// let measurement = ActionMetric(
///     actionId: morningRun.id,
///     metricId: kilometersMetric.id,
///     value: 5.2
/// )
///
/// // Record multiple measurements for same action
/// let timeMeasurement = ActionMetric(
///     actionId: morningRun.id,
///     metricId: minutesMetric.id,
///     value: 28.0
/// )
/// ```
@Table
public struct ActionMetric: Identifiable, Sendable {
    // MARK: - Identity

    /// Unique identifier (required by SQLiteData)
    public var id: UUID

    // MARK: - Relationship Fields

    /// The action this measurement belongs to
    public var actionId: UUID

    /// The metric being measured (references metrics catalog)
    public var metricId: UUID

    /// The measured value
    /// Example: 5.2 for 5.2 kilometers
    public var value: Double

    /// When this measurement was recorded
    /// Usually matches the action's logTime, but can differ for retroactive entries
    public var recordedAt: Date

    // MARK: - Initialization

    /// Create a new action measurement
    ///
    /// - Parameters:
    ///   - actionId: The action this measurement belongs to
    ///   - metricId: The metric being measured (from metrics catalog)
    ///   - value: The measured value
    ///   - recordedAt: When this was recorded (defaults to now)
    ///   - id: Unique identifier (generates new UUID if not provided)
    public init(
        actionId: UUID,
        metricId: UUID,
        value: Double,
        recordedAt: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.actionId = actionId
        self.metricId = metricId
        self.value = value
        self.recordedAt = recordedAt
    }
}

// MARK: - Query Helpers

extension ActionMetric {
    /// Check if this measurement is for a specific metric type
    /// Note: Requires joining with metrics table to check metricType
    public func isForMetricType(_ type: String, metrics: [Metric]) -> Bool {
        metrics.first(where: { $0.id == metricId })?.metricType == type
    }

    /// Get the unit for this measurement
    /// Note: Requires joining with metrics table
    public func unit(from metrics: [Metric]) -> String? {
        metrics.first(where: { $0.id == metricId })?.unit
    }
}