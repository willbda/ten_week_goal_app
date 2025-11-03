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
        // TODO: Implement section
        // - Section("Timing")
        // - DatePicker with date + time components
        // - Duration HStack with consistent spacing
        // - TextField with .frame(width: 100)
        // - Unit label
        Text("TimingSection - TODO")
    }
}
