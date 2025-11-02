//
// ActionFormView.swift
// Form for creating/editing actions (UI-only, no persistence yet)
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Input form for actions using shared form components.
// Currently validates but doesn't persist to database.
// Uses FormScaffold, ValidationFeedback, and FormHelpers from Templates/.

import SwiftUI
import Models

/// Form view for action input (create/edit)
///
/// Currently UI-only - validates input but calls `onValidate` callback instead of saving.
/// When persistence is added, will convert `onValidate` → `onSave`.
///
/// **Usage**:
/// ```swift
/// ActionFormView(onValidate: { formData in
///     print("Valid action: \(formData.title)")
///     // Later: save to database
/// })
/// ```
public struct ActionFormView: View {

    // MARK: - Properties

    /// Callback when form is validated (placeholder for eventual onSave)
    let onValidate: (ActionFormData) -> Void

    // MARK: - State

    /// Form data (not persisted, just UI state)
    @State private var formData = ActionFormData()

    /// Available measures for picker (predefined catalog)
    private let availableMeasures: [Measure] = [
        .kilometers,
        .hours,
        .minutes,
        .occasions
    ]

    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    public init(onValidate: @escaping (ActionFormData) -> Void) {
        self.onValidate = onValidate
    }

    // MARK: - Body

    public var body: some View {
        FormScaffold(
            title: "New Action",
            canSubmit: formData.isValid,
            onSubmit: handleSubmit,
            onCancel: { dismiss() },
            submitLabel: "Validate"
        ) {
            DocumentableFields(
                title: $formData.title,
                detailedDescription: $formData.detailedDescription,
                freeformNotes: $formData.freeformNotes
            )
            timingSection
            measurementsSection
            ValidationFeedback(
                isValid: formData.isValid,
                errors: formData.errors
            )
        }
    }

    // MARK: - Form Sections

    /// Section 1: Timing (when and how long)
    private var timingSection: some View {
        Section("Timing") {
            DatePicker(
                "When",
                selection: $formData.startTime,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Text("Duration")
                Spacer()
                TextField("Minutes", value: $formData.durationMinutes, format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("min")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Section 2: Measurements (repeating section with add/remove)
    private var measurementsSection: some View {
        Section {
            ForEach($formData.measurements) { $measurement in
                HStack {
                    // Measure picker
                    Picker("Measure", selection: $measurement.measureId) {
                        Text("Select measure").tag(nil as UUID?)
                        ForEach(availableMeasures, id: \.id) { measure in
                            Text(measure.unit).tag(measure.id as UUID?)
                        }
                    }
                    .labelsHidden()

                    // Value field
                    TextField("Value", value: $measurement.value, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)

                    // Remove button
                    Button(role: .destructive) {
                        removeMeasurement(measurement)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            // Add measurement button
            Button {
                addMeasurement()
            } label: {
                Label("Add Measurement", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Measurements")
        } footer: {
            Text("Track distance, time, count, or other metrics for this action")
                .font(.caption)
        }
    }

    // MARK: - Actions

    /// Handle form submission (validation only for now)
    private func handleSubmit() {
        guard formData.isValid else { return }

        onValidate(formData)
        dismiss()
    }

    /// Add a new empty measurement
    private func addMeasurement() {
        formData.measurements.append(MeasurementInput())
    }

    /// Remove a measurement
    private func removeMeasurement(_ measurement: MeasurementInput) {
        formData.measurements.removeAll { $0.id == measurement.id }
    }
}

// MARK: - Previews

#Preview("New Action") {
    ActionFormView { formData in
        print("Validated action: \(formData.title)")
    }
}

#Preview("Pre-filled") {
    struct PreviewWrapper: View {
        @State var showForm = true

        var body: some View {
            Button("Show Form") {
                showForm = true
            }
            .sheet(isPresented: $showForm) {
                ActionFormView { formData in
                    print("Validated: \(formData.title)")
                }
                .onAppear {
                    // Simulate pre-filled data
                    // Note: In actual usage, would pass initial data to form
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("With Measurements") {
    struct PreviewWrapper: View {
        var body: some View {
            ActionFormView { formData in
                print("Action with \(formData.measurements.count) measurements")
                print("Title: \(formData.title)")
                formData.measurements.forEach { measurement in
                    print("  - Value: \(measurement.value)")
                }
            }
        }
    }

    return PreviewWrapper()
}
