// ActionFormView.swift
// Reusable form for creating and editing actions
//
// Written by Claude Code on 2025-10-21

import SwiftUI
import Models

/// Form view for creating or editing an action
///
/// Supports both create and edit modes. When editing, pass an existing action.
/// When creating, pass nil and a new action will be created.
struct ActionFormView: View {

    // MARK: - Properties

    /// The action being edited (nil for create mode)
    let actionToEdit: Action?

    /// Callback when save button is tapped
    let onSave: (Action) -> Void

    /// Callback when cancel button is tapped
    let onCancel: () -> Void

    // MARK: - State

    @State private var friendlyName: String
    @State private var detailedDescription: String
    @State private var freeformNotes: String
    @State private var logTime: Date
    @State private var durationMinutes: String
    @State private var startTime: Date
    @State private var useStartTime: Bool
    @State private var useDuration: Bool

    // Measurements editing
    @State private var measurements: [MeasurementItem]
    @State private var showingAddMeasurement = false

    // MARK: - Initialization

    init(
        action: Action? = nil,
        onSave: @escaping (Action) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.actionToEdit = action
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from action or defaults
        _friendlyName = State(initialValue: action?.friendlyName ?? "")
        _detailedDescription = State(initialValue: action?.detailedDescription ?? "")
        _freeformNotes = State(initialValue: action?.freeformNotes ?? "")
        _logTime = State(initialValue: action?.logTime ?? Date())
        _durationMinutes = State(initialValue: action?.durationMinutes.map { String(format: "%.1f", $0) } ?? "")
        _startTime = State(initialValue: action?.startTime ?? Date())
        _useStartTime = State(initialValue: action?.startTime != nil)
        _useDuration = State(initialValue: action?.durationMinutes != nil)

        // Convert measurements dict to array for editing
        let measurementItems = action?.measuresByUnit?.map { unit, value in
            MeasurementItem(unit: unit, value: value)
        } ?? []
        _measurements = State(initialValue: measurementItems)
    }

    // MARK: - Computed Properties

    private var isEditing: Bool {
        actionToEdit != nil
    }

    private var title: String {
        isEditing ? "Edit Action" : "New Action"
    }

    private var canSave: Bool {
        // At minimum, need either a friendly name or a description
        !friendlyName.trimmingCharacters(in: .whitespaces).isEmpty ||
        !detailedDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                timingSection
                measurementsSection
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAction()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section {
            TextField("Name", text: $friendlyName, axis: .vertical)
                .lineLimit(2...4)

            TextField("Description", text: $detailedDescription, axis: .vertical)
                .lineLimit(3...6)

            TextField("Notes", text: $freeformNotes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Basic Info")
        } footer: {
            Text("Provide at least a name or description")
        }
    }

    private var timingSection: some View {
        Section("Timing") {
            DatePicker("Logged At", selection: $logTime, displayedComponents: [.date, .hourAndMinute])

            Toggle("Set Start Time", isOn: $useStartTime)

            if useStartTime {
                DatePicker("Started At", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
            }

            Toggle("Set Duration", isOn: $useDuration)

            if useDuration {
                HStack {
                    TextField("Duration", text: $durationMinutes)
                        .keyboardType(.decimalPad)
                    Text("minutes")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var measurementsSection: some View {
        Section {
            if measurements.isEmpty {
                Text("No measurements")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(measurements) { measurement in
                    HStack {
                        Text(measurement.unit)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", measurement.value))
                    }
                }
                .onDelete { indexSet in
                    measurements.remove(atOffsets: indexSet)
                }
            }

            Button {
                showingAddMeasurement = true
            } label: {
                Label("Add Measurement", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Measurements")
        } footer: {
            Text("Track quantitative data like distance, reps, or duration")
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementSheet { unit, value in
                measurements.append(MeasurementItem(unit: unit, value: value))
            }
        }
    }

    // MARK: - Actions

    private func saveAction() {
        // Build measurements dictionary
        let measuresByUnit: [String: Double]? = measurements.isEmpty ? nil : Dictionary(
            uniqueKeysWithValues: measurements.map { ($0.unit, $0.value) }
        )

        // Parse duration
        let duration: Double? = useDuration ? Double(durationMinutes) : nil

        // Create or update action
        let action = Action(
            friendlyName: friendlyName.isEmpty ? nil : friendlyName,
            detailedDescription: detailedDescription.isEmpty ? nil : detailedDescription,
            freeformNotes: freeformNotes.isEmpty ? nil : freeformNotes,
            measuresByUnit: measuresByUnit,
            durationMinutes: duration,
            startTime: useStartTime ? startTime : nil,
            logTime: logTime,
            id: actionToEdit?.id ?? UUID()  // Preserve ID when editing
        )

        onSave(action)
    }
}

// MARK: - Supporting Types

/// Identifiable wrapper for a measurement (unit + value)
private struct MeasurementItem: Identifiable {
    let id = UUID()
    let unit: String
    let value: Double
}

/// Sheet for adding a new measurement
private struct AddMeasurementSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String, Double) -> Void

    @State private var unit = ""
    @State private var value = ""

    var canAdd: Bool {
        !unit.isEmpty && Double(value) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Unit (e.g., km, reps, pages)", text: $unit)
                    TextField("Value", text: $value)
                        .keyboardType(.decimalPad)
                } footer: {
                    Text("Add a quantitative measurement for this action")
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let numericValue = Double(value) {
                            onAdd(unit, numericValue)
                            dismiss()
                        }
                    }
                    .disabled(!canAdd)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Create Mode") {
    ActionFormView(
        action: nil,
        onSave: { action in
            print("Would save: \(action)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}

#Preview("Edit Mode") {
    ActionFormView(
        action: Action(
            friendlyName: "Morning run",
            detailedDescription: "Easy recovery run in the park",
            measuresByUnit: ["km": 5.0, "minutes": 30],
            durationMinutes: 30,
            startTime: Date().addingTimeInterval(-3600),
            logTime: Date().addingTimeInterval(-3600)
        ),
        onSave: { action in
            print("Would save: \(action)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
