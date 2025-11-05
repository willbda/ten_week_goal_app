//
// MetricTargetRow.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Row view for metric target input (like MeasurementInputRow)
// USAGE: Used in RepeatingSection<MetricTargetRow> in GoalFormView
// PATTERN: Picker for measure + TextField for target value + optional notes
//

import Models
import Services
import SwiftUI

/// Row component for metric target input
///
/// Used in goal forms to specify measurable targets.
/// Example: "120 km" or "30 runs"
///
/// PATTERN: Similar to MeasurementInputRow but with notes field
public struct MetricTargetRow: View {
    let availableMeasures: [Measure]
    @Binding var target: MetricTargetInput
    let onRemove: () -> Void

    public init(
        availableMeasures: [Measure],
        target: Binding<MetricTargetInput>,
        onRemove: @escaping () -> Void = {}
    ) {
        self.availableMeasures = availableMeasures
        self._target = target
        self.onRemove = onRemove
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Full-width Picker for measure selection
            Picker("Metric", selection: $target.measureId) {
                Text("Select metric").tag(nil as UUID?)

                ForEach(availableMeasures, id: \.id) { measure in
                    HStack {
                        Text(measure.title ?? measure.unit)
                        Spacer()
                        Text(measure.unit)
                            .foregroundStyle(.secondary)
                    }
                    .tag(measure.id as UUID?)
                }
            }

            // Target value field with unit label
            HStack {
                Text("Target")
                    .foregroundStyle(.secondary)

                Spacer()

                TextField("0", value: $target.targetValue, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)

                if let selectedMeasure = availableMeasures.first(where: { $0.id == target.measureId }) {
                    Text(selectedMeasure.unit)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 60, alignment: .leading)
                }
            }

            // Optional notes field for target rationale
            TextField("Target notes (optional)", text: Binding(
                get: { target.notes ?? "" },
                set: { target.notes = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.footnote)

            // Remove button
            Button(role: .destructive, action: onRemove) {
                Label("Remove target", systemImage: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("With Target") {
    Form {
        Section("Metric Targets") {
            MetricTargetRow(
                availableMeasures: [
                    Measure(unit: "km", measureType: "distance", title: "Distance (km)"),
                    Measure(unit: "minutes", measureType: "time", title: "Duration (minutes)"),
                    Measure(unit: "occasions", measureType: "count", title: "Sessions")
                ],
                target: .constant(MetricTargetInput(
                    measureId: UUID(),
                    targetValue: 120,
                    notes: "Based on 10% weekly increase"
                )),
                onRemove: { print("Removed") }
            )
        }
    }
}

#Preview("Empty") {
    Form {
        Section("Metric Targets") {
            MetricTargetRow(
                availableMeasures: [
                    Measure(unit: "km", measureType: "distance", title: "Distance")
                ],
                target: .constant(MetricTargetInput()),
                onRemove: { print("Removed") }
            )
        }
    }
}
