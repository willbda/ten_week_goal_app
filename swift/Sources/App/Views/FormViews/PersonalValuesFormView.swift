import Models
import Services
import SwiftUI

//
// PersonalValuesFormView.swift
// Form view for PersonalValue creation
// Written by Claude Code on 2025-11-01
//
// PLANNED REFACTOR (2025-11-03):
// This file will be reviewed for padding/spacing consistency:
// - Ensure padding matches component library standards
// - Layout is already good (uses DocumentableFields)
// - May benefit from extracting value-specific sections to components
//
// ISSUE: Padding consistency (centered but needs standard spacing)
// See: Sources/App/Views/Components/FormComponents/README.md
//

// ARCHITECTURE DECISION: Why @State instead of @StateObject?
// CONTEXT: Swift 5.9+ changed how we initialize @Observable models in views
// OLD PATTERN (ObservableObject):
//   @StateObject private var viewModel = PersonalValuesFormViewModel()
// NEW PATTERN (@Observable):
//   @State private var viewModel = PersonalValuesFormViewModel()
// WHY THE CHANGE:
//   - @Observable doesn't need @StateObject wrapper
//   - @State now works with @Observable classes (not just structs!)
//   - Simpler, more consistent API
// SEE: PersonalValuesFormViewModel.swift for why we use @Observable
//
// ARCHITECTURE DECISION: ViewModel uses @Dependency internally
// PATTERN: From SQLiteData's ObservableModelDemo example
// HOW IT WORKS:
//   - ViewModel has @ObservationIgnored @Dependency(\.defaultDatabase)
//   - View just creates ViewModel() with no parameters
//   - Dependency injection happens automatically
// SEE: sqlite-data-main/Examples/CaseStudies/ObservableModelDemo.swift:56-57

// NEXT TASK (2025-11-03): Add Edit Mode Support
//
// PATTERN TO FOLLOW: ActionFormView edit mode
// CHANGES NEEDED:
// 1. Add optional parameter: let valueToEdit: PersonalValue?
// 2. Add computed: var isEditMode: Bool { valueToEdit != nil }
// 3. Add computed: var formTitle: String { isEditMode ? "Edit Value" : "New Value" }
// 4. Update init() to populate @State vars from valueToEdit if present
// 5. Add buildFormData() helper (establishes pattern for template)
// 6. Update handleSubmit() to call update or save based on mode
//
// REFINED PATTERN:
// - buildFormData() helper reduces duplication
// - ViewModel takes FormData (not 7 parameters)
// - Clean, template-ready structure
//

public struct PersonalValuesFormView: View {
    // MARK: - Edit Mode

    let valueToEdit: PersonalValue?
    var isEditMode: Bool { valueToEdit != nil }
    var formTitle: String { isEditMode ? "Edit Value" : "New Value" }

    // MARK: - State

    @State private var viewModel = PersonalValuesFormViewModel()
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title: String
    @State private var selectedLevel: ValueLevel
    @State private var priority: Int
    @State private var description: String
    @State private var notes: String
    @State private var lifeDomain: String
    @State private var alignmentGuidance: String

    // MARK: - Initialization

    public init(valueToEdit: PersonalValue? = nil) {
        self.valueToEdit = valueToEdit

        if let value = valueToEdit {
            // Edit mode - initialize from existing data
            _title = State(initialValue: value.title ?? "")
            _selectedLevel = State(initialValue: value.valueLevel)
            _priority = State(initialValue: value.priority ?? 50)
            _description = State(initialValue: value.detailedDescription ?? "")
            _notes = State(initialValue: value.freeformNotes ?? "")
            _lifeDomain = State(initialValue: value.lifeDomain ?? "")
            _alignmentGuidance = State(initialValue: value.alignmentGuidance ?? "")
        } else {
            // Create mode - defaults
            _title = State(initialValue: "")
            _selectedLevel = State(initialValue: .general)
            _priority = State(initialValue: 50)
            _description = State(initialValue: "")
            _notes = State(initialValue: "")
            _lifeDomain = State(initialValue: "")
            _alignmentGuidance = State(initialValue: "")
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
                detailedDescription: $description,
                freeformNotes: $notes
            )

            Section("Value Properties") {
                Picker("Level", selection: $selectedLevel) {
                    ForEach(ValueLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Stepper("Priority: \(priority)", value: $priority, in: 1...100)
            }

            Section("Context") {
                TextField("Life Domain", text: $lifeDomain)
                TextField("Alignment Guidance", text: $alignmentGuidance, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Actions

    /// Builds FormData from current @State variables.
    ///
    /// PATTERN: buildFormData() helper (establishes pattern for template)
    /// This reduces duplication and makes ViewModel calls cleaner.
    private func buildFormData() -> ValueFormData {
        return ValueFormData(
            title: title,
            detailedDescription: description.isEmpty ? nil : description,
            freeformNotes: notes.isEmpty ? nil : notes,
            valueLevel: selectedLevel,
            priority: priority,
            lifeDomain: lifeDomain.isEmpty ? nil : lifeDomain,
            alignmentGuidance: alignmentGuidance.isEmpty ? nil : alignmentGuidance
        )
    }

    private func handleSubmit() {
        Task {
            do {
                let formData = buildFormData()

                if let valueToEdit = valueToEdit {
                    // Update existing value
                    _ = try await viewModel.update(value: valueToEdit, from: formData)
                } else {
                    // Create new value (using formData instead of individual parameters)
                    _ = try await viewModel.save(from: formData)
                }

                dismiss()
            } catch {
                // Error already set in viewModel.errorMessage and displayed in form
            }
        }
    }

    // TODO: Phase 5 - Add Success Animation
    // PATTERN: .onChange(of: viewModel.successMessage) { _, newValue in
    //     if newValue != nil {
    //         withAnimation(.spring()) { /* show checkmark */ }
    //     }
    // }
    // WHEN: If user feedback indicates they want success confirmation
    // IMPL: Requires @Published var successMessage: String? in ViewModel
}
