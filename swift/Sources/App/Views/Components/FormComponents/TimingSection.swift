//
// TimingSection.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Standard timing fields (when + duration) with consistent styling
//
// SOLVES: Inconsistent TextField alignment for duration input
// PATTERN: DatePicker + duration field with proper width and alignment
// USAGE: Actions, any timestamped entity
//
// DESIGN:
// - DatePicker: Standard SwiftUI date/time picker
// - Duration field: Consistent width (100pt), trailing alignment, proper spacing
// - Unit label: Shows "min" next to value
// - Section: "Timing" header
// - Spacing: Matches other form sections
//
// EXAMPLE:
// TimingSection(
//     startTime: $startTime,
//     durationMinutes: $durationMinutes
// )

import SwiftUI

public struct TimingSection: View {
    @Binding var startTime: Date
    @Binding var durationMinutes: Double

    public init(
        startTime: Binding<Date>,
        durationMinutes: Binding<Double>
    ) {
        self._startTime = startTime
        self._durationMinutes = durationMinutes
    }

    public var body: some View {
        Section("Timing") {
            // Date and time picker
            DatePicker(
                "When",
                selection: $startTime,
                displayedComponents: [.date, .hourAndMinute]
            )

            // Duration field with consistent styling
            HStack {
                Text("Duration")
                Spacer()
                TextField("Minutes", value: $durationMinutes, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)  // Consistent with MeasurementInputRow
                Text("min")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Current Time") {
    Form {
        TimingSection(
            startTime: .constant(Date()),
            durationMinutes: .constant(0)
        )
    }
}

#Preview("With Duration") {
    Form {
        TimingSection(
            startTime: .constant(Date()),
            durationMinutes: .constant(28)
        )
    }
}
