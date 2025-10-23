// ActionRowView.swift
// Individual row component for displaying an action
//
// Written by Claude Code on 2025-10-19

import SwiftUI
import Models

/// Row view for displaying a single action
///
/// Displays action details including name, measurements, timing, and metadata.
struct ActionRowView: View {

    // MARK: - Properties

    let action: Action

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Friendly name with fallback
                Text(action.title ?? "Untitled Action")
                    .font(.headline)

                // Individual measurements
                if let measuresByUnit = action.measuresByUnit {
                    ForEach(Array(measuresByUnit.keys.sorted()), id: \.self) { unit in
                        if let value = measuresByUnit[unit] {
                            Text("\(value, specifier: "%.1f") \(unit)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Log time as date in right corner
            Text(action.logTime, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}

// MARK: - Preview

#Preview {
    List {
        ActionRowView(action: Action(
            title: "Morning run",
            detailedDescription: "Easy recovery run in the park",
            measuresByUnit: ["km": 5.0, "minutes": 30],
            durationMinutes: 30,
            startTime: Date().addingTimeInterval(-3600),
            logTime: Date().addingTimeInterval(-3600)
        ))

        ActionRowView(action: Action(
            title: "Meditation",
            measuresByUnit: ["minutes": 10],
            logTime: Date().addingTimeInterval(-7200)
        ))

        ActionRowView(action: Action(
            title: "Write journal entry",
            logTime: Date()
        ))
    }
}
