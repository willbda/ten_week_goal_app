// TermFormView.swift
// Form for creating and editing 10-week terms
//
// Written by Claude Code on 2025-10-21
//
// Supports both create and edit modes with progressive disclosure

import SwiftUI
import Models

/// Form view for creating or editing a 10-week term
///
/// Terms are fundamental planning units that group goals into
/// focused 70-day periods. This form supports:
/// - Term number and dates
/// - Theme/focus area
/// - Goal selection (multi-select)
/// - Post-term reflection
/// - Optional metadata (title, description, notes)
public struct TermFormView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - Properties

    /// Term being edited (nil = create mode)
    private let termToEdit: GoalTerm?

    /// Callbacks
    /// Save callback now receives both term and selected goal IDs
    /// Parent is responsible for saving term and creating junction table assignments
    private let onSave: (GoalTerm, Set<UUID>) -> Void
    private let onCancel: () -> Void

    // MARK: - Form State

    // Required fields
    @State private var termNumber: Int
    @State private var startDate: Date
    @State private var targetDate: Date

    // Optional fields
    @State private var theme: String
    @State private var title: String
    @State private var detailedDescription: String
    @State private var freeformNotes: String
    @State private var reflection: String

    // Goal selection
    @State private var selectedGoalIDs: Set<UUID>
    @State private var availableGoals: [Goal] = []

    // Progressive disclosure
    @State private var showOptionalFields = false
    @State private var showGoalSelection = false
    @State private var showReflection = false

    // Validation
    @State private var hasAttemptedSave = false

    // MARK: - Computed Properties

    /// Whether in create or edit mode
    private var isEditMode: Bool {
        termToEdit != nil
    }

    /// Form title based on mode
    private var formTitle: String {
        isEditMode ? "Edit Term" : "Create New Term"
    }

    /// Calculated term duration in days
    private var durationInDays: Int {
        let components = Calendar.current.dateComponents(
            [.day],
            from: startDate,
            to: targetDate
        )
        return components.day ?? 0
    }

    /// Whether the form is valid
    private var isFormValid: Bool {
        // Term number must be positive
        termNumber > 0 &&
        // Target date must be after start date
        targetDate > startDate
    }

    // MARK: - Initialization

    public init(
        term: GoalTerm? = nil,
        onSave: @escaping (GoalTerm, Set<UUID>) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.termToEdit = term
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from term or defaults
        if let term = term {
            // Edit mode - populate from existing term
            _termNumber = State(initialValue: term.termNumber)
            _startDate = State(initialValue: term.startDate)
            _targetDate = State(initialValue: term.targetDate)
            _theme = State(initialValue: term.theme ?? "")
            _title = State(initialValue: term.title ?? "")
            _detailedDescription = State(initialValue: term.detailedDescription ?? "")
            _freeformNotes = State(initialValue: term.freeformNotes ?? "")
            _reflection = State(initialValue: term.reflection ?? "")
            // Goal IDs will be loaded async via onAppear
            _selectedGoalIDs = State(initialValue: [])
            // Show optional sections if they have content
            _showOptionalFields = State(initialValue: term.title != nil || term.detailedDescription != nil || term.freeformNotes != nil)
            _showGoalSelection = State(initialValue: false)  // Will be set in onAppear after loading goals
            _showReflection = State(initialValue: term.reflection != nil)
        } else {
            // Create mode - use defaults
            _termNumber = State(initialValue: 1)
            _startDate = State(initialValue: Date())
            // Default to 70 days (10 weeks)
            _targetDate = State(initialValue: Calendar.current.date(
                byAdding: .day,
                value: GoalTerm.TEN_WEEKS_IN_DAYS,
                to: Date()
            ) ?? Date())
            _theme = State(initialValue: "")
            _title = State(initialValue: "")
            _detailedDescription = State(initialValue: "")
            _freeformNotes = State(initialValue: "")
            _reflection = State(initialValue: "")
            _selectedGoalIDs = State(initialValue: [])
        }
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: Basic Information
                Section {
                    // Term Number
                    HStack {
                        Text("Term Number")
                        Spacer()
                        TextField("Number", value: $termNumber, format: .number)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .frame(width: 80)
                            .formField(
                                isValid: termNumber > 0,
                                error: "Must be greater than 0",
                                isRequired: true
                            )
                    }

                    // Start Date
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        displayedComponents: [.date]
                    )

                    // Target Date
                    DatePicker(
                        "Target Date",
                        selection: $targetDate,
                        in: startDate...,
                        displayedComponents: [.date]
                    )
                    .formField(
                        isValid: targetDate > startDate,
                        error: "Must be after start date"
                    )

                    // Duration Display
                    HStack {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(durationInDays) days (\(durationInDays / 7) weeks)")
                            .foregroundStyle(durationInDays == 70 ? Color.primary : Color.orange)
                    }
                    .font(DesignSystem.Typography.callout)
                } header: {
                    Text("Basic Information")
                        .formSectionHeader()
                } footer: {
                    Text("Standard term length is 70 days (10 weeks)")
                        .font(DesignSystem.Typography.caption)
                }

                // MARK: Theme
                Section {
                    TextField("Focus area for this term", text: $theme, axis: .vertical)
                        .lineLimit(2...4)
                        .characterCount(current: theme.count)
                } header: {
                    Text("Theme")
                        .formSectionHeader()
                } footer: {
                    Text("Optional: What's the main focus? (e.g., \"Health & Fitness\", \"Career Growth\")")
                        .font(DesignSystem.Typography.caption)
                }

                // MARK: Goal Selection
                ExpandableFormSection(
                    title: "Assign Goals to This Term",
                    systemImage: "target",
                    subtitle: "Select which goals belong to this 10-week period",
                    isExpanded: $showGoalSelection
                ) {
                    if availableGoals.isEmpty {
                        Text("No goals available")
                            .foregroundStyle(.secondary)
                            .font(DesignSystem.Typography.callout)
                    } else {
                        ForEach(availableGoals) { goal in
                            GoalSelectionRow(
                                goal: goal,
                                isSelected: selectedGoalIDs.contains(goal.id)
                            ) {
                                toggleGoalSelection(goal.id)
                            }
                        }
                    }
                }

                // MARK: Optional Fields
                ExpandableFormSection(
                    title: "Additional Details",
                    systemImage: "text.alignleft",
                    isExpanded: $showOptionalFields
                ) {
                    TextField("Title", text: $title)
                        .fieldHelp("Optional custom title for this term")

                    TextField("Description", text: $detailedDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .characterCount(current: detailedDescription.count)

                    TextField("Notes", text: $freeformNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .fieldHelp("Freeform notes for planning or tracking")
                        .characterCount(current: freeformNotes.count)
                }

                // MARK: Reflection (Edit Mode Only)
                if isEditMode {
                    ExpandableFormSection(
                        title: "Post-Term Reflection",
                        systemImage: "text.quote",
                        subtitle: "What did you learn? What would you do differently?",
                        isExpanded: $showReflection
                    ) {
                        TextField("Reflection", text: $reflection, axis: .vertical)
                            .lineLimit(5...10)
                            .fieldHelp("Written after the term ends")
                            .characterCount(current: reflection.count)
                    }
                }
            }
            .navigationTitle(formTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveButtonTapped()
                    }
                    .disabled(!isFormValid)
                }
            }
            .task {
                // Load available goals and selected goals for existing term
                await loadAvailableGoals()
                await loadSelectedGoals()
            }
        }
    }

    // MARK: - Actions

    /// Handle save button tap
    private func saveButtonTapped() {
        hasAttemptedSave = true

        guard isFormValid else {
            return
        }

        // Create new term or update existing
        let term = GoalTerm(
            title: title.isEmpty ? nil : title,
            detailedDescription: detailedDescription.isEmpty ? nil : detailedDescription,
            freeformNotes: freeformNotes.isEmpty ? nil : freeformNotes,
            termNumber: termNumber,
            startDate: startDate,
            targetDate: targetDate,
            theme: theme.isEmpty ? nil : theme,
            reflection: reflection.isEmpty ? nil : reflection,
            logTime: termToEdit?.logTime ?? Date(),
            id: termToEdit?.id ?? UUID()
        )

        // Pass both term and selected goal IDs to parent
        // Parent will handle saving term and creating junction table assignments
        onSave(term, selectedGoalIDs)
    }

    /// Toggle goal selection
    private func toggleGoalSelection(_ goalID: UUID) {
        if selectedGoalIDs.contains(goalID) {
            selectedGoalIDs.remove(goalID)
        } else {
            selectedGoalIDs.insert(goalID)
        }
    }

    /// Load available goals from database
    private func loadAvailableGoals() async {
        guard let database = appViewModel.databaseManager else {
            return
        }

        do {
            availableGoals = try await database.fetchGoals()
                .sorted { ($0.title ?? "") < ($1.title ?? "") }
        } catch {
            print("❌ Failed to load goals: \(error)")
        }
    }

    /// Load selected goals for existing term (edit mode)
    private func loadSelectedGoals() async {
        guard let term = termToEdit,
              let database = appViewModel.databaseManager else {
            return
        }

        do {
            // Fetch term with goals using junction table
            if let (_, goals) = try await database.fetchTermWithGoals(term.id) {
                selectedGoalIDs = Set(goals.map { $0.id })
                showGoalSelection = !goals.isEmpty
            }
        } catch {
            print("❌ Failed to load term goals: \(error)")
        }
    }
}

// MARK: - Goal Selection Row

/// Row view for goal selection with checkbox
private struct GoalSelectionRow: View {
    let goal: Goal
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(DesignSystem.Typography.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title ?? "Untitled Goal")
                        .foregroundStyle(.primary)

                    if let target = goal.measurementTarget, let unit = goal.measurementUnit {
                        Text("\(target, format: .number) \(unit)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let targetDate = goal.targetDate {
                        Text("Due: \(targetDate, format: .dateTime.month().day().year())")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Create Mode") {
    TermFormView(
        term: nil,
        onSave: { term, goalIDs in
            print("Created term \(term.termNumber) with \(goalIDs.count) goals")
        },
        onCancel: {
            print("Cancelled")
        }
    )
    .environment(AppViewModel())
}

#Preview("Edit Mode") {
    let sampleTerm = GoalTerm(
        title: "Q1 2025",
        detailedDescription: "Focus on health and career growth",
        termNumber: 5,
        startDate: Date(),
        targetDate: Calendar.current.date(byAdding: .day, value: 70, to: Date())!,
        theme: "Health & Career",
        reflection: "Great progress on fitness goals!"
    )

    TermFormView(
        term: sampleTerm,
        onSave: { term, goalIDs in
            print("Updated term \(term.termNumber) with \(goalIDs.count) goals")
        },
        onCancel: {
            print("Cancelled")
        }
    )
    .environment(AppViewModel())
}
