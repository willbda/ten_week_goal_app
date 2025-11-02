//
// MeasurementDisplay.swift
// Shared model for pre-formatted measurement display
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Provides pre-formatted measurement data to row views across all entities.
// Avoids database queries in display components.
// Implements MeasurementDisplayContract from ComponentContracts.
//
// REUSABILITY:
// Used by ActionRowView, GoalRowView, TermRowView, ValueRowView for consistent
// measurement display across the app.

import Foundation
import SwiftUI

/// Pre-formatted measurement for display in row views
///
/// Parent views (ListView) query the database and format measurements
/// into this struct before passing to child row views.
///
/// **Note:** Implements MeasurementDisplayContract protocol from test fixtures.
/// The protocol is defined in Tests/ViewTests/ComponentContracts.swift but we
/// don't import test modules in production code, so the conformance is structural only.
///
/// **Why this pattern?**
/// - Row views are pure display components (no database access)
/// - Parent views handle data fetching/formatting
/// - Easy to test with mock data
/// - Reusable across Actions/Goals/Terms/Values
///
/// **Usage**:
/// ```swift
/// // In ActionsListView (parent):
/// let measurements = [
///     MeasurementDisplay(value: 5.2, unit: "km", measureType: "distance"),
///     MeasurementDisplay(value: 28.0, unit: "minutes", measureType: "time")
/// ]
///
/// // Pass to ActionRowView (child):
/// ActionRowView(action: action, measurements: measurements)
///
/// // Use displayString and color:
/// Text(measurement.displayString)  // "5.2 km"
/// BadgeView(badge: Badge(text: measurement.displayString, color: measurement.color))
/// ```
public struct MeasurementDisplay: Identifiable {

    // MARK: - Properties

    public let id: UUID
    public let value: Double
    public let unit: String
    public let measureType: String

    // MARK: - Display Properties

    /// Formatted string for display
    /// (Matches MeasurementDisplayContract protocol requirement)
    ///
    /// Formats the value with appropriate precision:
    /// - Whole numbers: "5 km" (no decimals)
    /// - Decimals: "5.2 km" (one decimal place)
    ///
    /// **Examples**:
    /// ```swift
    /// MeasurementDisplay(value: 5.0, unit: "km", ...).displayString  // "5 km"
    /// MeasurementDisplay(value: 5.2, unit: "km", ...).displayString  // "5.2 km"
    /// MeasurementDisplay(value: 28.0, unit: "minutes", ...).displayString  // "28 minutes"
    /// ```
    public var displayString: String {
        let formattedValue: String
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            // Whole number - no decimals
            formattedValue = String(format: "%.0f", value)
        } else {
            // Has decimal - show 1 decimal place
            formattedValue = String(format: "%.1f", value)
        }
        return "\(formattedValue) \(unit)"
    }

    // MARK: - Convenience Properties

    /// Color for this measurement type
    ///
    /// Used by BadgeView for consistent coloring across the app.
    ///
    /// **Color Mapping**:
    /// - "distance" → .blue
    /// - "time" → .green
    /// - "count" → .orange
    /// - other → .gray
    ///
    /// **Usage**:
    /// ```swift
    /// let badge = Badge(
    ///     text: measurement.displayString,
    ///     color: measurement.color
    /// )
    /// ```
    public var color: Color {
        switch measureType {
        case "distance": return .blue
        case "time": return .green
        case "count": return .orange
        default: return .gray
        }
    }

    // MARK: - Initialization

    /// Create a pre-formatted measurement display
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - value: Numeric measurement value
    ///   - unit: Unit string ("km", "minutes", "occasions", etc.)
    ///   - measureType: Category for coloring ("distance", "time", "count")
    public init(
        id: UUID = UUID(),
        value: Double,
        unit: String,
        measureType: String
    ) {
        self.id = id
        self.value = value
        self.unit = unit
        self.measureType = measureType
    }
}

// MARK: - Previews

#Preview("Display String Examples") {
    VStack(alignment: .leading, spacing: 12) {
        Group {
            Text("Distance:")
                .font(.caption).foregroundStyle(.secondary)
            Text(MeasurementDisplay(
                value: 5.2, unit: "km", measureType: "distance"
            ).displayString)
                .font(.headline)
        }

        Divider()

        Group {
            Text("Time:")
                .font(.caption).foregroundStyle(.secondary)
            Text(MeasurementDisplay(
                value: 28.0, unit: "minutes", measureType: "time"
            ).displayString)
                .font(.headline)
        }

        Divider()

        Group {
            Text("Count:")
                .font(.caption).foregroundStyle(.secondary)
            Text(MeasurementDisplay(
                value: 3, unit: "occasions", measureType: "count"
            ).displayString)
                .font(.headline)
        }

        Divider()

        Group {
            Text("Whole Number:")
                .font(.caption).foregroundStyle(.secondary)
            Text(MeasurementDisplay(
                value: 10.0, unit: "km", measureType: "distance"
            ).displayString)
                .font(.headline)
        }
    }
    .padding()
}

#Preview("As Badges") {
    HStack(spacing: 8) {
        ForEach([
            MeasurementDisplay(value: 5.2, unit: "km", measureType: "distance"),
            MeasurementDisplay(value: 28.0, unit: "min", measureType: "time"),
            MeasurementDisplay(value: 3, unit: "occasions", measureType: "count")
        ]) { measurement in
            BadgeView(badge: Badge(
                text: measurement.displayString,
                color: measurement.color
            ))
        }
    }
    .padding()
}

#Preview("Color Variations") {
    VStack(spacing: 12) {
        ForEach([
            MeasurementDisplay(value: 5.2, unit: "km", measureType: "distance"),
            MeasurementDisplay(value: 2.5, unit: "hours", measureType: "time"),
            MeasurementDisplay(value: 10, unit: "reps", measureType: "count"),
            MeasurementDisplay(value: 75.0, unit: "kg", measureType: "mass")
        ]) { measurement in
            HStack {
                Circle()
                    .fill(measurement.color)
                    .frame(width: 20, height: 20)
                Text(measurement.displayString)
                Text("(\(measurement.measureType))")
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}

#Preview("Precision Handling") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Whole numbers (no decimals):")
            .font(.caption).foregroundStyle(.secondary)

        ForEach([1.0, 5.0, 100.0], id: \.self) { value in
            Text(MeasurementDisplay(
                value: value, unit: "km", measureType: "distance"
            ).displayString)
        }

        Divider()

        Text("With decimals (1 decimal place):")
            .font(.caption).foregroundStyle(.secondary)

        ForEach([1.5, 5.2, 10.7], id: \.self) { value in
            Text(MeasurementDisplay(
                value: value, unit: "km", measureType: "distance"
            ).displayString)
        }
    }
    .padding()
}
