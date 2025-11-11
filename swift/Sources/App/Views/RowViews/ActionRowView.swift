//
// ActionRowView.swift
// Specialized row view for displaying actions in lists
//
// Written by Claude Code on 2025-11-01
// Updated by Claude Code on 2025-11-02 (ActionWithDetails pattern)
//
// PURPOSE:
// Displays Action with measurements and goal contributions.
// Receives ActionWithDetails from parent JOIN query (no N+1).

import SwiftUI
import Models
import Services

// MARK: - ActionRowView

/// Displays an action in a list with measurements and goal contributions
///
/// **Pattern**: Receives ActionWithDetails from parent (like TermRowView)
/// **No database access** - all data passed from parent via JOIN
///
/// **Usage**:
/// ```swift
/// ForEach(actionsWithDetails) { actionDetails in
///     ActionRowView(actionDetails: actionDetails)
/// }
/// ```
public struct ActionRowView: View {
    let actionDetails: ActionWithDetails

    public init(actionDetails: ActionWithDetails) {
        self.actionDetails = actionDetails
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title only (relative timestamp removed for clarity)
            // Previously displayed: logTime with .relative style ("2 hours ago")
            // Removed as it was found to be distracting rather than helpful
            Text(actionDetails.action.title ?? "Untitled Action")
                .font(.headline)

            // Measurements (if any)
            if !actionDetails.measurements.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "ruler")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(measurementsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Duration (if tracked AND no time measurement exists)
            // Hide duration if there's already a time-based measurement to avoid redundancy
            if let duration = actionDetails.action.durationMinutes,
               duration > 0,
               !hasTimeMeasurement {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Int(duration)) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Goal contributions badge (if any)
            if !actionDetails.contributions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    Text("\(actionDetails.contributions.count) goal\(actionDetails.contributions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            // Description (if present)
            if let description = actionDetails.action.detailedDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    /// Checks if any measurement is time-based
    ///
    /// Used to avoid redundant display when both durationMinutes and time measurements exist.
    /// Time-based units: minutes, min, hours, hrs, seconds, secs
    private var hasTimeMeasurement: Bool {
        let timeUnits = ["minutes", "min", "hours", "hrs", "hour", "seconds", "secs", "second"]
        return actionDetails.measurements.contains { measurement in
            let unit = measurement.measure.unit.lowercased()
            return timeUnits.contains(unit) || measurement.measure.measureType == "time"
        }
    }

    /// Formats measurements as comma-separated list
    /// Example: "5.2 km, 28 min, 3 occasions"
    private var measurementsText: String {
        actionDetails.measurements
            .map { measurement in
                let value = measurement.measuredAction.value
                let unit = measurement.measure.unit

                // Format value (no decimals if whole number)
                let valueStr = value.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", value)
                    : String(format: "%.1f", value)

                return "\(valueStr) \(unit)"
            }
            .joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("Action with Measurements") {
    List {
        ActionRowView(
            actionDetails: ActionWithDetails(
                action: Action(
                    title: "Morning run",
                    detailedDescription: "Great weather, felt strong",
                    durationMinutes: 28,
                    startTime: Date(),
                    logTime: Date()
                ),
                measurements: [
                    ActionMeasurement(
                        measuredAction: MeasuredAction(
                            actionId: UUID(),
                            measureId: UUID(),
                            value: 5.2
                        ),
                        measure: Measure(unit: "km", measureType: "distance", title: "Distance")
                    )
                ],
                contributions: []
            )
        )
    }
}

#Preview("Multiple Measurements + Goals") {
    List {
        ActionRowView(
            actionDetails: ActionWithDetails(
                action: Action(
                    title: "Team meeting",
                    detailedDescription: "Quarterly planning session",
                    durationMinutes: 90,
                    startTime: Date().addingTimeInterval(-3600),
                    logTime: Date().addingTimeInterval(-3600)
                ),
                measurements: [
                    ActionMeasurement(
                        measuredAction: MeasuredAction(
                            actionId: UUID(),
                            measureId: UUID(),
                            value: 1
                        ),
                        measure: Measure(unit: "occasions", measureType: "count", title: "Occasions")
                    ),
                    ActionMeasurement(
                        measuredAction: MeasuredAction(
                            actionId: UUID(),
                            measureId: UUID(),
                            value: 90
                        ),
                        measure: Measure(unit: "minutes", measureType: "time", title: "Minutes")
                    )
                ],
                contributions: [
                    ActionContribution(
                        contribution: ActionGoalContribution(
                            actionId: UUID(),
                            goalId: UUID()
                        ),
                        goal: Goal(expectationId: UUID())
                    ),
                    ActionContribution(
                        contribution: ActionGoalContribution(
                            actionId: UUID(),
                            goalId: UUID()
                        ),
                        goal: Goal(expectationId: UUID())
                    )
                ]
            )
        )
    }
}

#Preview("No Measurements") {
    List {
        ActionRowView(
            actionDetails: ActionWithDetails(
                action: Action(
                    title: "Quick task",
                    startTime: Date(),
                    logTime: Date()
                ),
                measurements: [],
                contributions: []
            )
        )
    }
}
