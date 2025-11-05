// Measure.swift
// First-class entity representing units of measurement
//
// Written by Claude Code on 2025-10-30
//
// ARCHITECTURE:
// - Measures are catalog entries for units of measurement (km, hours, occasions)
// - Actions reference measures through actionmeasures junction table
// - Expectations reference measures through ExpectationMeasure junction table
// - This replaces the JSON measuresByUnit dictionary with proper normalization
//
// EXAMPLES:
// - Measure(unit: "km", measureType: "distance", title: "Distance in kilometers")
// - Measure(unit: "hours", measureType: "time", title: "Duration in hours")
// - Measure(unit: "occasions", measureType: "count", title: "Number of occurrences")
//
// 3NF COMPLIANCE:
// - Atomic values only (no JSON/arrays)
// - Single source of truth for each measure definition
// - Enables indexing and foreign key constraints

import Foundation
import SQLiteData

/// Catalog entry for a unit of measurement
///
/// **Database Table**: `measures`
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
/// // Define available measures
/// let distanceKm = Measure(
///     unit: "km",
///     measureType: "distance",
///     title: "Distance",
///     detailedDescription: "Distance measured in kilometers"
/// )
///
/// let durationHours = Measure(
///     unit: "hours",
///     measureType: "time",
///     title: "Duration",
///     detailedDescription: "Time duration in hours"
/// )
///
/// let occasions = Measure(
///     unit: "occasions",
///     measureType: "count",
///     title: "Occasions",
///     detailedDescription: "Number of times an activity occurs"
/// )
/// ```
@Table
public struct Measure: DomainAbstraction {
    // MARK: - Required Fields (Persistable)

    public var id: UUID
    public var logTime: Date

    // MARK: - Optional Persistable Fields

    /// Human-readable name for the measure
    /// Example: "Distance", "Duration", "Occasions"
    public var title: String?

    /// Detailed explanation of what this measure measures
    /// Example: "Distance covered during running activities"
    public var detailedDescription: String?

    /// Additional notes about usage or conversion
    /// Example: "1 km = 0.621371 miles"
    public var freeformNotes: String?

    // MARK: - Measure-specific Fields

    /// The unit of measurement
    /// Examples: "km", "miles", "hours", "minutes", "occasions", "reps"
    public var unit: String

    /// Category for grouping related measures
    /// Examples: "distance", "time", "count", "mass", "frequency"
    public var measureType: String

    /// Optional: Canonical unit for conversion
    /// Example: "meters" for distance measures, "seconds" for time measures
    public var canonicalUnit: String?

    /// Optional: Conversion factor to canonical unit
    /// Example: 1000.0 for km→meters, 3600.0 for hours→seconds
    public var conversionFactor: Double?

    // MARK: - Initialization

    /// Create a new measure definition
    ///
    /// - Parameters:
    ///   - unit: The unit of measurement (required)
    ///   - measureType: Category for grouping (required)
    ///   - title: Human-readable name
    ///   - detailedDescription: Explanation of the measure
    ///   - freeformNotes: Additional notes
    ///   - canonicalUnit: Base unit for conversions
    ///   - conversionFactor: Factor to convert to canonical
    ///   - logTime: When this measure was created
    ///   - id: Unique identifier
    public init(
        unit: String,
        measureType: String,
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
        self.measureType = measureType
        self.title = title ?? unit.capitalized
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.canonicalUnit = canonicalUnit
        self.conversionFactor = conversionFactor
    }
}

// MARK: - Default Measures

extension Measure {
    /// Predefined distance measure in kilometers
    public static let kilometers = Measure(
        unit: "km",
        measureType: "distance",
        title: "Distance",
        detailedDescription: "Distance measured in kilometers",
        canonicalUnit: "meters",
        conversionFactor: 1000.0
    )

    /// Predefined time measure in hours
    public static let hours = Measure(
        unit: "hours",
        measureType: "time",
        title: "Duration",
        detailedDescription: "Time duration in hours",
        canonicalUnit: "seconds",
        conversionFactor: 3600.0
    )

    /// Predefined count measure for occasions
    public static let occasions = Measure(
        unit: "occasions",
        measureType: "count",
        title: "Occasions",
        detailedDescription: "Number of times an activity occurs"
    )

    /// Predefined time measure in minutes
    public static let minutes = Measure(
        unit: "minutes",
        measureType: "time",
        title: "Minutes",
        detailedDescription: "Time duration in minutes",
        canonicalUnit: "seconds",
        conversionFactor: 60.0
    )
}
