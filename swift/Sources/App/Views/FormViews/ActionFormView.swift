//
// ActionFormView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Form for creating/editing Actions with measurements and goal contributions
// PATTERN: Edit mode support via optional actionToEdit parameter (like TermFormView)
//
// PLANNED REFACTOR (2025-11-03):
// This file will be refactored to use shared form components:
// - Replace timingSection with TimingSection component
// - Replace measurementsSection with RepeatingSection<MeasurementInputRow>
// - Replace goalContributionsSection with MultiSelectSection
// - Extract buildFormData() helper pattern for template
//
// ISSUE SOLVED: Measurement TextField alignment (pushed far right by picker in HStack)
// See: Sources/App/Views/Components/FormComponents/README.md
//

import Models
import Services
import SwiftUI

// MARK: - Helper Types

/// Wrapper for goal selection in MultiSelectSection
private struct GoalOption: Identifiable {
    let id: UUID
    let goal: Goal
    let title: String

    init(goal: Goal, title: String) {
        self.id = goal.id
        self.goal = goal
        self.title = title
    }
}

// MARK: - Form View

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
    @State private var measurements: [MeasurementInput]
    @State private var selectedGoalIds: Set<UUID>

    // MARK: - Initialization

    public init(actionToEdit: ActionWithDetails? = nil) {
        self.actionToEdit = actionToEdit

        if let actionToEdit = actionToEdit {
            // Edit mode - initialize from existing data
            _title = State(initialValue: actionToEdit.action.title ?? "")
            _detailedDescription = State(
                initialValue: actionToEdit.action.detailedDescription ?? "")
            _freeformNotes = State(initialValue: actionToEdit.action.freeformNotes ?? "")
            _startTime = State(
                initialValue: actionToEdit.action.startTime ?? actionToEdit.action.logTime)
            _durationMinutes = State(initialValue: actionToEdit.action.durationMinutes ?? 0)

            // Convert measurements to edit format
            let existingMeasurements = actionToEdit.measurements.map { measurement in
                MeasurementInput(
                    id: measurement.measuredAction.id,
                    measureId: measurement.measuredAction.measureId,
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

            // Replaced timingSection with component
            TimingSection(
                startTime: $startTime,
                durationMinutes: $durationMinutes
            )

            // Replaced measurementsSection with components (fixes alignment issue!)
            RepeatingSection(
                title: "Measurements",
                items: measurements,
                addButtonLabel: "Add Measurement",
                footer: "Track distance, time, count, or other metrics for this action",
                onAdd: addMeasurement
            ) { measurement in
                MeasurementInputRow(
                    measureId: bindingForMeasurement(measurement.id).measureId,
                    value: bindingForMeasurement(measurement.id).value,
                    availableMeasures: viewModel.availableMeasures,
                    onRemove: { removeMeasurement(id: measurement.id) }
                )
            }

            // Replaced goalContributionsSection with component
            MultiSelectSection(
                items: viewModel.availableGoals.map { GoalOption(goal: $0.0, title: $0.1) },
                title: "Goal Contributions",
                itemLabel: { $0.title },
                selectedIds: $selectedGoalIds
            )

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

    // MARK: - Helpers

    /// Handle form submission (create or update)
    ///
    /// REFINEMENT NEEDED (2025-11-03):
    /// Should extract buildFormData() helper to reduce code duplication:
    /// ```swift
    /// private func buildFormData() -> ActionFormData {
    ///     let measurementInputs = measurements.compactMap { m in
    ///         guard let measureId = m.measureId, m.value > 0 else { return nil }
    ///         return MeasurementInput(measureId: measureId, value: m.value)
    ///     }
    ///     return ActionFormData(
    ///         title: title,
    ///         detailedDescription: detailedDescription,
    ///         freeformNotes: freeformNotes,
    ///         durationMinutes: durationMinutes,
    ///         startTime: startTime,
    ///         measurements: measurementInputs,
    ///         goalContributions: selectedGoalIds
    ///     )
    /// }
    ///
    /// private func handleSubmit() {
    ///     Task {
    ///         let formData = buildFormData()
    ///         if let action = actionToEdit {
    ///             try await viewModel.update(actionDetails: action, formData: formData)
    ///         } else {
    ///             try await viewModel.save(formData: formData)
    ///         }
    ///         dismiss()
    ///     }
    /// }
    /// ```
    /// Pattern to establish: PersonalValuesFormView (when updated)
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
        measurements.append(MeasurementInput(id: UUID(), measureId: nil, value: 0))
    }

    /// Remove a measurement by ID
    private func removeMeasurement(id: UUID) {
        measurements.removeAll { $0.id == id }
    }

    /// Create bindings for measurement fields
    ///
    /// Returns a tuple of bindings for (measureId, value) for the given measurement ID
    private func bindingForMeasurement(_ id: UUID) -> (measureId: Binding<UUID?>, value: Binding<Double>) {
        guard let index = measurements.firstIndex(where: { $0.id == id }) else {
            // Fallback for missing measurement (shouldn't happen in practice)
            return (
                measureId: .constant(nil),
                value: .constant(0)
            )
        }

        return (
            measureId: Binding(
                get: { measurements[index].measureId },
                set: { measurements[index].measureId = $0 }
            ),
            value: Binding(
                get: { measurements[index].value },
                set: { measurements[index].value = $0 }
            )
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
