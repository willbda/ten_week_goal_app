//
// TermFormView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: User-friendly form for creating/editing Terms (wraps generic TimePeriodFormViewModel)
// ARCHITECTURE: Type-specific view using generic ViewModel with specialization = .term
//

import Models
import Services
import SwiftUI

/// Form for creating or editing a Term (10-week planning period).
///
/// ARCHITECTURE DECISION: Type-Specific View + Generic ViewModel
/// - View is user-friendly (says "Term", not "Time Period")
/// - Wraps TimePeriodFormViewModel with pre-configured specialization = .term(number)
/// - User never sees "Time Period" or "Specialization" in UI
/// - Supports both create (termToEdit = nil) and edit (termToEdit != nil) modes
///
/// PATTERN: Based on PersonalValuesFormView + old TermFormView
/// - FormScaffold template
/// - @State for ViewModel (not @StateObject)
/// - Individual @State properties for form fields
/// - Async save/update in Task
public struct TermFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TimePeriodFormViewModel()

    // MARK: - Edit Mode Support

    /// Term being edited (nil = create mode, not nil = edit mode)
    private let termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)?

    /// Whether in create or edit mode
    private var isEditMode: Bool {
        termToEdit != nil
    }

    /// Form title based on mode
    private var formTitle: String {
        isEditMode ? "Edit Term" : "New Term"
    }

    // Term-specific fields
    @State private var termNumber: Int
    @State private var startDate: Date
    @State private var targetDate: Date
    @State private var theme: String
    @State private var reflection: String
    @State private var status: TermStatus

    // Generic TimePeriod fields
    @State private var title: String
    @State private var description: String
    @State private var notes: String

    // MARK: - Initialization

    public init(termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)? = nil) {
        self.termToEdit = termToEdit

        // Initialize state from termToEdit or defaults
        if let (timePeriod, goalTerm) = termToEdit {
            // Edit mode - populate from existing term
            _termNumber = State(initialValue: goalTerm.termNumber)
            _startDate = State(initialValue: timePeriod.startDate)
            _targetDate = State(initialValue: timePeriod.endDate)
            _theme = State(initialValue: goalTerm.theme ?? "")
            _reflection = State(initialValue: goalTerm.reflection ?? "")
            _status = State(initialValue: goalTerm.status ?? .planned)
            _title = State(initialValue: timePeriod.title ?? "")
            _description = State(initialValue: timePeriod.detailedDescription ?? "")
            _notes = State(initialValue: timePeriod.freeformNotes ?? "")
        } else {
            // Create mode - use defaults
            _termNumber = State(initialValue: 1)
            _startDate = State(initialValue: Date())
            _targetDate = State(initialValue: Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date()) ?? Date())
            _theme = State(initialValue: "")
            _reflection = State(initialValue: "")
            _status = State(initialValue: .planned)
            _title = State(initialValue: "")
            _description = State(initialValue: "")
            _notes = State(initialValue: "")
        }
    }

    public var body: some View {
        FormScaffold(
            title: formTitle,
            canSubmit: !viewModel.isSaving,
            onSubmit: handleSubmit,
            onCancel: { dismiss() }
        ) {
            Section("Term Details") {
                Stepper("Term Number: \(termNumber)", value: $termNumber, in: 1...52)
                    .accessibilityLabel("Term number")

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                DatePicker("End Date", selection: $targetDate, displayedComponents: .date)
            }

            Section {
                TextField("Focus area for this term", text: $theme, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Theme")
            } footer: {
                Text("Optional: What's the main focus? (e.g., \"Health & Fitness\", \"Career Growth\")")
                    .font(.caption)
            }

            // Reflection section (edit mode only)
            if isEditMode {
                Section {
                    TextField("Post-term reflection", text: $reflection, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Reflection")
                } footer: {
                    Text("What did you learn? What would you do differently?")
                        .font(.caption)
                }

                Section {
                    Picker("Status", selection: $status) {
                        ForEach(TermStatus.allCases, id: \.self) { status in
                            Text(status.description).tag(status)
                        }
                    }
                } header: {
                    Text("Status")
                }
            }

            DocumentableFields(
                title: $title,
                detailedDescription: $description,
                freeformNotes: $notes
            )

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
    }

    private func handleSubmit() {
        Task {
            do {
                if let (timePeriod, goalTerm) = termToEdit {
                    // Edit mode - update existing term
                    _ = try await viewModel.update(
                        timePeriod: timePeriod,
                        goalTerm: goalTerm,
                        startDate: startDate,
                        targetDate: targetDate,
                        specialization: .term(number: termNumber),
                        title: title.isEmpty ? nil : title,
                        description: description.isEmpty ? nil : description,
                        notes: notes.isEmpty ? nil : notes,
                        theme: theme.isEmpty ? nil : theme,
                        reflection: reflection.isEmpty ? nil : reflection,
                        status: status
                    )
                } else {
                    // Create mode - create new term
                    _ = try await viewModel.save(
                        startDate: startDate,
                        targetDate: targetDate,
                        specialization: .term(number: termNumber),
                        title: title.isEmpty ? nil : title,
                        description: description.isEmpty ? nil : description,
                        notes: notes.isEmpty ? nil : notes,
                        theme: theme.isEmpty ? nil : theme
                    )
                }
                dismiss()
            } catch {
                // Error already set in viewModel.errorMessage
            }
        }
    }
}
