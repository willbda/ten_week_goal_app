//
// ActionFormView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Form for creating/editing Actions with measurements and goal contributions
// PATTERN: Edit mode support via optional actionToEdit parameter (like TermFormView)
//

import SwiftUI
import Models
import Services

/// Form view for Action input (create + edit)
///
/// **Pattern**: Single form for create and edit (like TermFormView)
/// **Edit Mode**: Triggered by passing `actionToEdit` parameter
/// **State Initialization**: In init() based on actionToEdit
///
/// **Usage**:
/// ```swift
/// // Create mode
/// ActionFormView()
///
/// // Edit mode
/// ActionFormView(actionToEdit: actionDetails)
/// ```
public struct ActionFormView: View {
    // MARK: - Edit Mode

    let actionToEdit: ActionWithDetails?
    var isEditMode: Bool { actionToEdit != nil }
    var formTitle: String { isEditMode ? "Edit Action" : "New Action" }

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActionFormViewModel()

    // Form fields
    @State private var title: String
    @State private var detailedDescription: String
    @State private var freeformNotes: String
    @State private var startTime: Date
    @State private var durationMinutes: Double
    @State private var measurements: [(id: UUID, measureId: UUID?, value: Double)]
    @State private var selectedGoalIds: Set<UUID>

    // MARK: - Initialization

    public init(actionToEdit: ActionWithDetails? = nil) {
        self.actionToEdit = actionToEdit

        if let actionToEdit = actionToEdit {
            // Edit mode - initialize from existing data
            _title = State(initialValue: actionToEdit.action.title ?? "")
            _detailedDescription = State(initialValue: actionToEdit.action.detailedDescription ?? "")
            _freeformNotes = State(initialValue: actionToEdit.action.freeformNotes ?? "")
            _startTime = State(initialValue: actionToEdit.action.startTime ?? actionToEdit.action.logTime)
            _durationMinutes = State(initialValue: actionToEdit.action.durationMinutes ?? 0)

            // Convert measurements to edit format
            let existingMeasurements = actionToEdit.measurements.map { measurement in
                (
                    id: measurement.measuredAction.id,
                    measureId: measurement.measuredAction.measureId as UUID?,
                    value: measurement.measuredAction.value
                )
            }
            _measurements = State(initialValue: existingMeasurements)

            // Convert contributions to Set<UUID>
            let existingGoalIds = Set(actionToEdit.contributions.map { $0.contribution.goalId })
            _selectedGoalIds = State(initialValue: existingGoalIds)
        } else {
            // Create mode - defaults
            _title = State(initialValue: "")
            _detailedDescription = State(initialValue: "")
            _freeformNotes = State(initialValue: "")
            _startTime = State(initialValue: Date())
            _durationMinutes = State(initialValue: 0)
            _measurements = State(initialValue: [])
            _selectedGoalIds = State(initialValue: [])
        }
    }

    // MARK: - Body

    public var body: some View {
        FormScaffold(
            title: formTitle,
            canSubmit: !title.isEmpty && !viewModel.isSaving,
            onSubmit: handleSubmit,
            onCancel: { dismiss() }
        ) {
            DocumentableFields(
                title: $title,
                detailedDescription: $detailedDescription,
                freeformNotes: $freeformNotes
            )

            timingSection
            measurementsSection
            goalContributionsSection

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .task {
            await viewModel.loadOptions()
        }
    }

    // MARK: - Form Sections

    /// Section 1: Timing (when and how long)
    private var timingSection: some View {
        Section("Timing") {
            DatePicker(
                "When",
                selection: $startTime,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Text("Duration")
                Spacer()
                TextField("Minutes", value: $durationMinutes, format: .number)
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
            ForEach($measurements, id: \.id) { $measurement in
                HStack {
                    // Measure picker
                    Picker("Measure", selection: $measurement.measureId) {
                        Text("Select measure").tag(nil as UUID?)
                        ForEach(viewModel.availableMeasures, id: \.id) { measure in
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
                        removeMeasurement(id: measurement.id)
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

    /// Section 3: Goal Contributions (multi-select)
    private var goalContributionsSection: some View {
        Section {
            if viewModel.availableGoals.isEmpty {
                Text("No goals available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.availableGoals, id: \.0.id) { (goal, title) in
                    Toggle(isOn: binding(for: goal.id)) {
                        Text(title)
                    }
                }
            }
        } header: {
            Text("Goal Contributions")
        } footer: {
            Text("Select goals this action contributes toward")
                .font(.caption)
        }
    }

    // MARK: - Actions

    /// Handle form submission (create or update)
    private func handleSubmit() {
        Task {
            do {
                // Convert measurements to tuple format for ViewModel
                let measurementTuples: [(UUID, Double)] = measurements.compactMap { measurement in
                    guard let measureId = measurement.measureId, measurement.value > 0 else {
                        return nil
                    }
                    return (measureId, measurement.value)
                }

                if let actionToEdit = actionToEdit {
                    // Update existing action
                    _ = try await viewModel.update(
                        actionDetails: actionToEdit,
                        title: title,
                        description: detailedDescription,
                        notes: freeformNotes,
                        durationMinutes: durationMinutes,
                        startTime: startTime,
                        measurements: measurementTuples,
                        goalContributions: selectedGoalIds
                    )
                } else {
                    // Create new action
                    _ = try await viewModel.save(
                        title: title,
                        description: detailedDescription,
                        notes: freeformNotes,
                        durationMinutes: durationMinutes,
                        startTime: startTime,
                        measurements: measurementTuples,
                        goalContributions: selectedGoalIds
                    )
                }
                dismiss()
            } catch {
                // Error handled by viewModel.errorMessage
            }
        }
    }

    /// Add a new empty measurement
    private func addMeasurement() {
        measurements.append((id: UUID(), measureId: nil, value: 0))
    }

    /// Remove a measurement by ID
    private func removeMeasurement(id: UUID) {
        measurements.removeAll { $0.id == id }
    }

    /// Create a binding for goal toggle
    private func binding(for goalId: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedGoalIds.contains(goalId) },
            set: { isSelected in
                if isSelected {
                    selectedGoalIds.insert(goalId)
                } else {
                    selectedGoalIds.remove(goalId)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview("New Action") {
    NavigationStack {
        ActionFormView()
    }
}

#Preview("Edit Action") {
    NavigationStack {
        ActionFormView(
            actionToEdit: ActionWithDetails(
                action: Action(
                    title: "Morning run",
                    detailedDescription: "Great weather",
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
