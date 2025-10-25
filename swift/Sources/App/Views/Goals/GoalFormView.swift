// GoalFormView.swift
// Reusable form for creating and editing goals
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// Form view for creating or editing a goal
///
/// Supports both minimal goals (just description) and SMART goals (all fields).
/// Provides toggles to progressively add SMART criteria.
struct GoalFormView: View {

    // MARK: - Properties

    /// The goal being edited (nil for create mode)
    let goalToEdit: Goal?

    /// Callback when save button is tapped
    let onSave: (Goal) -> Void

    /// Callback when cancel button is tapped
    let onCancel: () -> Void

    // MARK: - State

    // Core identity
    @State private var title: String
    @State private var detailedDescription: String
    @State private var freeformNotes: String
    @State private var logTime: Date

    // Completable properties (SMART criteria)
    @State private var measurementUnit: String
    @State private var measurementTarget: String
    @State private var startDate: Date
    @State private var targetDate: Date
    @State private var useStartDate: Bool
    @State private var useTargetDate: Bool
    @State private var useMeasurement: Bool

    // SMART enhancement fields
    @State private var howGoalIsRelevant: String
    @State private var howGoalIsActionable: String
    @State private var expectedTermLength: String
    @State private var useSmartFields: Bool

    // UI state
    @State private var showingSmartInfo = false

    // MARK: - Initialization

    init(
        goal: Goal? = nil,
        onSave: @escaping (Goal) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.goalToEdit = goal
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from goal or defaults
        _title = State(initialValue: goal?.title ?? "")
        _detailedDescription = State(initialValue: goal?.detailedDescription ?? "")
        _freeformNotes = State(initialValue: goal?.freeformNotes ?? "")
        _logTime = State(initialValue: goal?.logTime ?? Date())

        // Measurement fields
        _measurementUnit = State(initialValue: goal?.measurementUnit ?? "")
        _measurementTarget = State(initialValue: goal?.measurementTarget.map { String(format: "%.1f", $0) } ?? "")
        _useMeasurement = State(initialValue: goal?.measurementUnit != nil || goal?.measurementTarget != nil)

        // Date fields
        _startDate = State(initialValue: goal?.startDate ?? Date())
        _targetDate = State(initialValue: goal?.targetDate ?? Date().addingTimeInterval(86400 * 70)) // 10 weeks from now
        _useStartDate = State(initialValue: goal?.startDate != nil)
        _useTargetDate = State(initialValue: goal?.targetDate != nil)

        // SMART fields
        _howGoalIsRelevant = State(initialValue: goal?.howGoalIsRelevant ?? "")
        _howGoalIsActionable = State(initialValue: goal?.howGoalIsActionable ?? "")
        _expectedTermLength = State(initialValue: goal?.expectedTermLength.map { String($0) } ?? "10")
        _useSmartFields = State(initialValue: goal?.howGoalIsRelevant != nil || goal?.howGoalIsActionable != nil)
    }

    // MARK: - Computed Properties

    private var isEditing: Bool {
        goalToEdit != nil
    }

    private var viewTitle: String {
        isEditing ? "Edit Goal" : "New Goal"
    }

    private var canSave: Bool {
        // At minimum, need either a friendly name or a description
        !title.trimmingCharacters(in: .whitespaces).isEmpty ||
        !detailedDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isSmart: Bool {
        // Check if current values would make a SMART goal
        useMeasurement && !measurementUnit.isEmpty && Double(measurementTarget) != nil &&
        useStartDate && useTargetDate &&
        useSmartFields && !howGoalIsRelevant.isEmpty && !howGoalIsActionable.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection

                measurementSection

                dateSection

                smartSection

                // SMART status indicator
                if isSmart {
                    Section {
                        Label("This goal meets SMART criteria", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)  // Allow glass background to show through
            #if os(macOS)
            .padding(DesignSystem.Spacing.formPadding)
            .frame(minWidth: 600, minHeight: 700)
            #endif
            .navigationTitle(viewTitle)
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
                        saveGoal()
                    }
                    .disabled(!canSave)
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingSmartInfo) {
                SmartInfoSheet()
            }
        }
        .presentationBackground(ContentMaterials.modal)
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section {
            TextField("Name", text: $title, axis: .vertical)
                .lineLimit(1...3)

            TextField("Description", text: $detailedDescription, axis: .vertical)
                .lineLimit(2...4)

            TextField("Notes", text: $freeformNotes, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Basic Info")
        } footer: {
            Text("Provide at least a name or description")
        }
    }

    private var measurementSection: some View {
        Section("Measurement (Specific & Measurable)") {
            Toggle("Add Measurement", isOn: $useMeasurement)

            if useMeasurement {
                TextField("Unit (e.g., km, hours, pages)", text: $measurementUnit)

                HStack {
                    TextField("Target", text: $measurementTarget)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    if !measurementUnit.isEmpty {
                        Text(measurementUnit)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var dateSection: some View {
        Section {
            Toggle("Set Start Date", isOn: $useStartDate)

            if useStartDate {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            }

            Toggle("Set Target Date", isOn: $useTargetDate)

            if useTargetDate {
                DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
            }

            // TODO(human): Add expected term length field
            // This should show when both dates are set and calculate/display the duration in weeks

            // Show duration when both dates set
            if useStartDate && useTargetDate {
                let days = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
                let weeks = Double(days) / 7.0
                HStack {
                    Text("Duration")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(days) days (~\(String(format: "%.1f", weeks)) weeks)")
                }
            }
        } header: {
            Text("Timeline (Time-bound)")
        }
    }

    private var smartSection: some View {
        Section {
            Toggle("Add SMART Details", isOn: $useSmartFields)

            if useSmartFields {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why is this goal relevant?")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    TextField("How does this align with your values?", text: $howGoalIsRelevant, axis: .vertical)
                        .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("How is this goal actionable?")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    TextField("What specific actions will you take?", text: $howGoalIsActionable, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
        } header: {
            HStack {
                Text("SMART Criteria")
                Spacer()
                Button {
                    showingSmartInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        } footer: {
            if !useSmartFields {
                Text("SMART = Specific, Measurable, Achievable, Relevant, Time-bound")
            }
        }
    }


    // MARK: - Actions

    private func saveGoal() {
        // Parse optional numeric values
        let target: Double? = useMeasurement ? Double(measurementTarget) : nil
        let termLength: Int? = useSmartFields && !expectedTermLength.isEmpty ? Int(expectedTermLength) : nil

        // Create or update goal
        let goal = Goal(
            title: title.isEmpty ? nil : title,
            detailedDescription: detailedDescription.isEmpty ? nil : detailedDescription,
            freeformNotes: freeformNotes.isEmpty ? nil : freeformNotes,
            measurementUnit: useMeasurement && !measurementUnit.isEmpty ? measurementUnit : nil,
            measurementTarget: target,
            startDate: useStartDate ? startDate : nil,
            targetDate: useTargetDate ? targetDate : nil,
            howGoalIsRelevant: useSmartFields && !howGoalIsRelevant.isEmpty ? howGoalIsRelevant : nil,
            howGoalIsActionable: useSmartFields && !howGoalIsActionable.isEmpty ? howGoalIsActionable : nil,
            expectedTermLength: termLength,
            logTime: logTime,
            id: goalToEdit?.id ?? UUID()  // Preserve ID when editing
        )

        onSave(goal)
    }
}

// MARK: - Supporting Views

/// Information sheet explaining SMART criteria
private struct SmartInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Specific", systemImage: "target")
                    Text("Clear and well-defined. \"Run 120km\" not \"exercise more\"")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Label("Measurable", systemImage: "chart.line.uptrend.xyaxis")
                    Text("Quantifiable progress. Use units like km, hours, pages, etc.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Label("Achievable", systemImage: "hand.thumbsup")
                    Text("Realistic given your resources and constraints")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Label("Relevant", systemImage: "heart")
                    Text("Aligns with your values and long-term objectives")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Label("Time-bound", systemImage: "calendar")
                    Text("Has a clear deadline. Typically 10 weeks for a term")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("SMART Goals")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Create Mode") {
    GoalFormView(
        goal: nil,
        onSave: { goal in
            print("Would save: \(goal)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}

#Preview("Edit Mode - Minimal Goal") {
    GoalFormView(
        goal: Goal(
            title: "Get healthier",
            detailedDescription: "Focus on overall wellness"
        ),
        onSave: { goal in
            print("Would save: \(goal)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}

#Preview("Edit Mode - SMART Goal") {
    GoalFormView(
        goal: Goal(
            title: "10-week running goal",
            detailedDescription: "Build running endurance",
            measurementUnit: "km",
            measurementTarget: 120.0,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(86400 * 70),
            howGoalIsRelevant: "Improves cardiovascular health and mental clarity",
            howGoalIsActionable: "Run 3x per week, gradually increasing distance",
            expectedTermLength: 10
        ),
        onSave: { goal in
            print("Would save: \(goal)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
