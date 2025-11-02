//
// ActionRowView.swift
// Specialized row view for displaying actions in lists
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Uses EntityRowView from Templates/ to display action data.
// Receives pre-formatted MeasurementDisplay data from parent.
//
// NOTE: MeasurementDisplay is now imported from Templates/MeasurementDisplay.swift
// for reusability across all entity types (Actions, Goals, Terms, Values).

import SwiftUI
import Models

// MARK: - ActionRowView

/// Displays an action in a list using EntityRowView
///
/// Shows action title, description, timestamp, measurements as badges,
/// and duration in trailing content.
///
/// **Usage**:
/// ```swift
/// ActionRowView(
///     action: morningRun,
///     measurements: [
///         MeasurementDisplay(value: 5.2, unit: "km", measureType: "distance")
///     ]
/// )
/// ```
public struct ActionRowView: View {
    let action: Action
    let measurements: [MeasurementDisplay]  // Pre-formatted by parent

    public init(action: Action, measurements: [MeasurementDisplay]) {
        self.action = action
        self.measurements = measurements
    }

    public var body: some View {
        EntityRowView(
            title: action.title ?? "Untitled Action",
            subtitle: action.detailedDescription,
            caption: formatTimestamp(action.startTime),
            badges: makeBadges(),
            trailingContent: {
                if let duration = action.durationMinutes {
                    Text("\(Int(duration))m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }

    // MARK: - Helpers

    /// Creates badges from measurements
    ///
    /// Uses MeasurementDisplay's built-in displayString and color properties
    /// for consistent formatting across all entity types.
    private func makeBadges() -> [Badge] {
        measurements.map { measurement in
            Badge(
                text: measurement.displayString,
                color: measurement.color
            )
        }
    }

    /// Formats timestamp as relative time
    /// Example: "2 hours ago", "Yesterday"
    private func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else {
            return formatTimestamp(action.logTime)
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview("Action with Measurements") {
    List {
        ActionRowView(
            action: Action(
                title: "Morning Run",
                detailedDescription: "5K in the park",
                durationMinutes: 28,
                startTime: Date()
            ),
            measurements: [
                MeasurementDisplay(value: 5.2, unit: "km", measureType: "distance"),
                MeasurementDisplay(value: 28, unit: "minutes", measureType: "time")
            ]
        )
    }
}

#Preview("Action without Measurements") {
    List {
        ActionRowView(
            action: Action(
                title: "Team Meeting",
                detailedDescription: "Weekly sync with product team",
                durationMinutes: 45,
                startTime: Date().addingTimeInterval(-3600)
            ),
            measurements: []
        )
    }
}

#Preview("Multiple Actions") {
    List {
        ActionRowView(
            action: Action(
                title: "Meditation",
                durationMinutes: 20,
                startTime: Date()
            ),
            measurements: [
                MeasurementDisplay(value: 1, unit: "occasions", measureType: "count")
            ]
        )

        ActionRowView(
            action: Action(
                title: "Guitar Practice",
                detailedDescription: "Worked on blues scales",
                durationMinutes: 45,
                startTime: Date().addingTimeInterval(-7200)
            ),
            measurements: [
                MeasurementDisplay(value: 45, unit: "minutes", measureType: "time"),
                MeasurementDisplay(value: 1, unit: "occasions", measureType: "count")
            ]
        )

        ActionRowView(
            action: Action(
                title: "Bike Commute",
                durationMinutes: 22,
                startTime: Date().addingTimeInterval(-86400)
            ),
            measurements: [
                MeasurementDisplay(value: 8.5, unit: "km", measureType: "distance")
            ]
        )
    }
}
