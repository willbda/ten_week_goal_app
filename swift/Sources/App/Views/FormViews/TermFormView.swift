//
// TermFormView.swift
// Written by Claude Code on 2025-11-02
// Rewritten by Claude Code on 2025-11-03 to follow Apple's SwiftUI patterns
//
// PURPOSE: User-friendly form for creating/editing Terms (wraps generic TimePeriodFormViewModel)
// PATTERN: Direct Form structure following Apple's documented SwiftUI patterns
//          No wrapper components - navigation modifiers applied directly to Form
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
/// PATTERN: Apple's direct Form approach
/// - Form directly inside NavigationStack
/// - Navigation modifiers applied to Form itself
/// - Toolbar buttons defined inline
public struct TermFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TimePeriodFormViewModel()

    // MARK: - Edit Mode Support

    /// Term being edited (nil = create mode, not nil = edit mode)
    private let termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)?

    /// Suggested next term number (from TermsListView's @Fetch data)
    /// Used only in create mode to auto-increment from existing terms
    private let suggestedTermNumber: Int?

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

    // Computed properties
    private var canSubmit: Bool {
        !viewModel.isSaving
    }

    // MARK: - Initialization

    /// Initialize form for create or edit mode
    /// - Parameters:
    ///   - termToEdit: Existing term to edit (nil = create mode)
    ///   - suggestedTermNumber: Next term number from TermsListView (create mode only)
    public init(
        termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)? = nil,
        suggestedTermNumber: Int? = nil
    ) {
        self.termToEdit = termToEdit
        self.suggestedTermNumber = suggestedTermNumber

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
            // Create mode - use suggested number or default to 1
            _termNumber = State(initialValue: suggestedTermNumber ?? 1)
            _startDate = State(initialValue: Date())
            _targetDate = State(
                initialValue: Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date())
                    ?? Date())
            _theme = State(initialValue: "")
            _reflection = State(initialValue: "")
            _status = State(initialValue: .planned)
            _title = State(initialValue: "")
            _description = State(initialValue: "")
            _notes = State(initialValue: "")
        }
    }

    public var body: some View {
        Form {
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
                Text(
                    "Optional: What's the main focus? (e.g., \"Health & Fitness\", \"Career Growth\")"
                )
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
        .formStyle(.grouped)
        .navigationTitle(formTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    handleSubmit()
                }
                .disabled(!canSubmit)
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

// MARK: - Previews

#Preview("New Term") {
    NavigationStack {
        TermFormView()
    }
}

#Preview("Edit Term") {
    NavigationStack {
        TermFormView(
            termToEdit: (
                timePeriod: TimePeriod(
                    title: "Spring Term",
                    detailedDescription: "Focus on health and career",
                    startDate: Date(),
                    endDate: Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date())!
                ),
                goalTerm: GoalTerm(
                    timePeriodId: UUID(),
                    termNumber: 1,
                    theme: "Health & Career Growth",
                    status: .active
                )
            )
        )
    }
}
