// MetricRepository.swift
// Service for querying normalized metric data
//
// Written by Claude Code on 2025-10-30
//
// PURPOSE:
// Provides clean API for working with the normalized metrics system.
// Handles joins between actions/goals and their metrics.
// Encapsulates SQL complexity behind simple method calls.

import Foundation
import SQLiteData
import GRDB

/// Repository for metric-related queries and operations
///
/// This service handles the complexity of the 3NF normalized schema,
/// providing simple methods for common metric operations.
///
/// **Usage**:
/// ```swift
/// let repo = MetricRepository()
///
/// // Get all metrics for an action
/// let measurements = await repo.getMetricsForAction(myAction)
///
/// // Record a new measurement
/// await repo.recordMeasurement(
///     action: myAction,
///     metric: distanceMetric,
///     value: 5.2
/// )
///
/// // Calculate goal progress
/// let progress = await repo.calculateProgress(for: myGoal)
/// ```
@MainActor
public class MetricRepository: ObservableObject {

    // MARK: - Metric Catalog Operations

    /// Fetch all available metrics
    public func getAllMetrics() async throws -> [Metric] {
        return try await Metric.all()
    }

    /// Fetch metrics by type
    public func getMetrics(ofType type: String) async throws -> [Metric] {
        return try await Metric.filter(\.metricType == type)
    }

    /// Find or create a metric
    public func findOrCreateMetric(unit: String, type: String) async throws -> Metric {
        // First try to find existing metric
        if let existing = try await Metric.filter(\.unit == unit).first {
            return existing
        }

        // Create new metric
        let metric = Metric(
            unit: unit,
            metricType: type,
            title: unit.capitalized
        )
        try await metric.insert()
        return metric
    }

    // MARK: - Action Metrics Operations

    /// Get all metrics for an action with their values
    public func getMetricsForAction(_ action: Action) async throws -> [(metric: Metric, value: Double)] {
        // Fetch all ActionMetrics for this action
        let actionMetrics = try await ActionMetric.filter(\.actionId == action.id)

        // Fetch corresponding Metrics
        var results: [(metric: Metric, value: Double)] = []
        for am in actionMetrics {
            if let metric = try await Metric.find(am.metricId) {
                results.append((metric: metric, value: am.value))
            }
        }

        return results
    }

    /// Record a measurement for an action
    public func recordMeasurement(action: Action, metric: Metric, value: Double) async throws {
        // Check if measurement already exists
        let existing = try await ActionMetric.filter(
            \.actionId == action.id && \.metricId == metric.id
        ).first

        if let existing = existing {
            // Update existing measurement
            var updated = existing
            updated.value = value
            updated.recordedAt = Date()
            try await updated.update()
        } else {
            // Create new measurement
            let measurement = ActionMetric(
                actionId: action.id,
                metricId: metric.id,
                value: value
            )
            try await measurement.insert()
        }
    }

    /// Remove a measurement from an action
    public func removeMeasurement(action: Action, metric: Metric) async throws {
        if let measurement = try await ActionMetric.filter(
            \.actionId == action.id && \.metricId == metric.id
        ).first {
            try await measurement.delete()
        }
    }

    // MARK: - Goal Metrics Operations

    /// Get all target metrics for a goal
    public func getMetricsForGoal(_ goal: Goal) async throws -> [(metric: Metric, targetValue: Double)] {
        // Fetch all GoalMetrics for this goal
        let goalMetrics = try await GoalMetric.filter(\.goalId == goal.id)

        // Fetch corresponding Metrics
        var results: [(metric: Metric, targetValue: Double)] = []
        for gm in goalMetrics {
            if let metric = try await Metric.find(gm.metricId) {
                results.append((metric: metric, targetValue: gm.targetValue))
            }
        }

        return results
    }

    /// Set a target metric for a goal
    public func setGoalTarget(goal: Goal, metric: Metric, targetValue: Double) async throws {
        // Check if target already exists
        let existing = try await GoalMetric.filter(
            \.goalId == goal.id && \.metricId == metric.id
        ).first

        if let existing = existing {
            // Update existing target
            var updated = existing
            updated.targetValue = targetValue
            try await updated.update()
        } else {
            // Create new target
            let target = GoalMetric(
                goalId: goal.id,
                metricId: metric.id,
                targetValue: targetValue
            )
            try await target.insert()
        }
    }

    // MARK: - Progress Calculation

    /// Calculate progress for a goal based on contributing actions
    public func calculateProgress(for goal: Goal) async throws -> GoalProgress {
        // Get goal targets
        let targets = try await getMetricsForGoal(goal)

        // Get contributing actions
        let contributions = try await ActionGoalContribution.filter(\.goalId == goal.id)

        var progressByMetric: [UUID: (actual: Double, target: Double)] = [:]

        // Calculate progress for each metric
        for (metric, targetValue) in targets {
            var actualValue: Double = 0.0

            // Sum contributions for this metric
            for contribution in contributions {
                if contribution.metricId == metric.id {
                    actualValue += contribution.contributionAmount ?? 0
                }
            }

            progressByMetric[metric.id] = (actual: actualValue, target: targetValue)
        }

        // Calculate overall percentage
        var totalPercentage: Double = 0.0
        if !progressByMetric.isEmpty {
            let percentages = progressByMetric.values.map { actual, target in
                target > 0 ? (actual / target) * 100 : 0
            }
            totalPercentage = percentages.reduce(0, +) / Double(percentages.count)
        }

        return GoalProgress(
            goalId: goal.id,
            progressByMetric: progressByMetric,
            overallPercentage: min(100, totalPercentage)
        )
    }

    // MARK: - Aggregation Queries

    /// Get total for a metric across all actions
    public func totalForMetric(_ metric: Metric) async throws -> Double {
        let measurements = try await ActionMetric.filter(\.metricId == metric.id)
        return measurements.reduce(0) { $0 + $1.value }
    }

    /// Get total for a metric type across all actions
    public func totalForMetricType(_ type: String) async throws -> [(metric: Metric, total: Double)] {
        let metrics = try await getMetrics(ofType: type)

        var results: [(metric: Metric, total: Double)] = []
        for metric in metrics {
            let total = try await totalForMetric(metric)
            if total > 0 {
                results.append((metric: metric, total: total))
            }
        }

        return results
    }

    /// Get metrics for actions in date range
    public func metricsInDateRange(from startDate: Date, to endDate: Date) async throws -> [ActionMetric] {
        return try await ActionMetric.filter(
            \.recordedAt >= startDate && \.recordedAt <= endDate
        )
    }
}

// MARK: - Supporting Types

/// Progress information for a goal
public struct GoalProgress {
    public let goalId: UUID
    public let progressByMetric: [UUID: (actual: Double, target: Double)]
    public let overallPercentage: Double

    /// Check if goal is complete
    public var isComplete: Bool {
        overallPercentage >= 100
    }

    /// Get progress for a specific metric
    public func progress(for metricId: UUID) -> (actual: Double, target: Double)? {
        progressByMetric[metricId]
    }

    /// Get percentage for a specific metric
    public func percentage(for metricId: UUID) -> Double {
        guard let (actual, target) = progressByMetric[metricId],
              target > 0 else { return 0 }
        return min(100, (actual / target) * 100)
    }
}