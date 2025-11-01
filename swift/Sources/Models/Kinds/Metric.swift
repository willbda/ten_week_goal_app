// Metric.swift
// First-class entity representing units of measurement
//
// Written by Claude Code on 2025-10-30
//
// ARCHITECTURE:
// - Metrics are catalog entries for units of measurement (km, hours, occasions)
// - Actions reference metrics through ActionMetric junction table
// - Goals reference metrics through GoalMetric junction table
// - This replaces the JSON measuresByUnit dictionary with proper normalization
//
// EXAMPLES:
// - Metric(unit: "km", metricType: "distance", title: "Distance in kilometers")
// - Metric(unit: "hours", metricType: "time", title: "Duration in hours")
// - Metric(unit: "occasions", metricType: "count", title: "Number of occurrences")
//
// 3NF COMPLIANCE:
// - Atomic values only (no JSON/arrays)
// - Single source of truth for each metric definition
// - Enables indexing and foreign key constraints

import Foundation
import SQLiteData

/// Catalog entry for a unit of measurement
///
/// **Database Table**: `metrics`
/// **Purpose**: Define available units for measurements and targets
///
/// **Why separate from Action/Goal?**
/// - Single source of truth for unit definitions
/// - Enables queries like "all actions measuring distance"
/// - Supports unit conversion and grouping by type
/// - Prevents typos and inconsistencies in unit names
///
/// **Usage**:
/// ```swift
/// // Define available metrics
/// let distanceKm = Metric(
///     unit: "km",
///     metricType: "distance",
///     title: "Distance",
///     detailedDescription: "Distance measured in kilometers"
/// )
///
/// let durationHours = Metric(
///     unit: "hours",
///     metricType: "time",
///     title: "Duration",
///     detailedDescription: "Time duration in hours"
/// )
///
/// let occasions = Metric(
///     unit: "occasions",
///     metricType: "count",
///     title: "Occasions",
///     detailedDescription: "Number of times an activity occurs"
/// )
/// ```
@Table
public struct Metric: Persistable, Sendable {
    // MARK: - Required Fields (Persistable)

    public var id: UUID
    public var logTime: Date

    // MARK: - Optional Persistable Fields

    /// Human-readable name for the metric
    /// Example: "Distance", "Duration", "Occasions"
    public var title: String?

    /// Detailed explanation of what this metric measures
    /// Example: "Distance covered during running activities"
    public var detailedDescription: String?

    /// Additional notes about usage or conversion
    /// Example: "1 km = 0.621371 miles"
    public var freeformNotes: String?

    // MARK: - Metric-specific Fields

    /// The unit of measurement
    /// Examples: "km", "miles", "hours", "minutes", "occasions", "reps"
    public var unit: String

    /// Category for grouping related metrics
    /// Examples: "distance", "time", "count", "mass", "frequency"
    public var metricType: String

    /// Optional: Canonical unit for conversion
    /// Example: "meters" for distance metrics, "seconds" for time metrics
    public var canonicalUnit: String?

    /// Optional: Conversion factor to canonical unit
    /// Example: 1000.0 for km→meters, 3600.0 for hours→seconds
    public var conversionFactor: Double?

    // MARK: - Initialization

    /// Create a new metric definition
    ///
    /// - Parameters:
    ///   - unit: The unit of measurement (required)
    ///   - metricType: Category for grouping (required)
    ///   - title: Human-readable name
    ///   - detailedDescription: Explanation of the metric
    ///   - freeformNotes: Additional notes
    ///   - canonicalUnit: Base unit for conversions
    ///   - conversionFactor: Factor to convert to canonical
    ///   - logTime: When this metric was created
    ///   - id: Unique identifier
    public init(
        unit: String,
        metricType: String,
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        canonicalUnit: String? = nil,
        conversionFactor: Double? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.logTime = logTime
        self.unit = unit
        self.metricType = metricType
        self.title = title ?? unit.capitalized
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.canonicalUnit = canonicalUnit
        self.conversionFactor = conversionFactor
    }
}

// MARK: - Common Metrics

extension Metric {
    /// Predefined distance metric in kilometers
    public static let kilometers = Metric(
        unit: "km",
        metricType: "distance",
        title: "Distance",
        detailedDescription: "Distance measured in kilometers",
        canonicalUnit: "meters",
        conversionFactor: 1000.0
    )

    /// Predefined time metric in hours
    public static let hours = Metric(
        unit: "hours",
        metricType: "time",
        title: "Duration",
        detailedDescription: "Time duration in hours",
        canonicalUnit: "seconds",
        conversionFactor: 3600.0
    )

    /// Predefined count metric for occasions
    public static let occasions = Metric(
        unit: "occasions",
        metricType: "count",
        title: "Occasions",
        detailedDescription: "Number of times an activity occurs"
    )

    /// Predefined time metric in minutes
    public static let minutes = Metric(
        unit: "minutes",
        metricType: "time",
        title: "Minutes",
        detailedDescription: "Time duration in minutes",
        canonicalUnit: "seconds",
        conversionFactor: 60.0
    )
}