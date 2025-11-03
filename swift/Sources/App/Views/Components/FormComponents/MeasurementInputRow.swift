//
// MeasurementInputRow.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Reusable row component for measure + value entry
//
// SOLVES: Alignment issue in ActionFormView where picker pushes TextField far right
// PATTERN: Full-width picker, then value field with proper spacing
// USAGE: Actions (measurements), Goals (targets), any form with metric input
//
// DESIGN:
// - Measure picker: Full width, not cramped in HStack
// - Value field: Aligned left like other fields (not forced right)
// - Unit display: Shows selected measure's unit next to value
// - Remove button: Consistent placement and styling
// - Spacing: Proper padding matches other form sections
//
// EXAMPLE:
// MeasurementInputRow(
//     measureId: $measurement.measureId,
//     value: $measurement.value,
//     availableMeasures: viewModel.availableMeasures,
//     onRemove: { removeMeasurement(id: measurement.id) }
// )

import SwiftUI
import Models

public struct MeasurementInputRow: View {
    @Binding var measureId: UUID?
    @Binding var value: Double
    let availableMeasures: [Measure]
    let onRemove: () -> Void

    public init(
        measureId: Binding<UUID?>,
        value: Binding<Double>,
        availableMeasures: [Measure],
        onRemove: @escaping () -> Void
    ) {
        self._measureId = measureId
        self._value = value
        self.availableMeasures = availableMeasures
        self.onRemove = onRemove
    }

    public var body: some View {
        // TODO: Implement layout
        // - Full-width Picker (not cramped)
        // - Value TextField with proper alignment
        // - Unit label showing selected measure's unit
        // - Remove button
        Text("MeasurementInputRow - TODO")
    }
}
