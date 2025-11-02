//
// TermFormView.swift
// Form for creating/editing terms (UI-only, no persistence yet)
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Input form for terms using shared form components.
// Currently validates but doesn't persist to database.
// Uses FormScaffold, ValidationFeedback, and FormHelpers from Shared/.

import SwiftUI
import Models

/// Form view for term input (create/edit)
///
/// Currently UI-only - validates input but calls `onValidate` callback instead of saving.
/// When persistence is added, will convert `onValidate` → `onSave`.
///
/// **Usage**:
/// ```swift
/// TermFormView(onValidate: { formData in
///     print("Valid term: \(formData.termNumber)")
///     // Later: save to database
/// })
/// ```
public struct TermFormView: View {

    // MARK: - Properties

    /// Callback when form is validated (placeholder for eventual onSave)
    let onValidate: (TermFormData) -> Void

    // MARK: - State

    /// Form data (not persisted, just UI state)
    @State private var formData = TermFormData()

    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    public init(onValidate: @escaping (TermFormData) -> Void) {
        self.onValidate = onValidate
    }

    // MARK: - Body

    public var body: some View {
        FormScaffold(
            title: "New Term",
            canSubmit: formData.isValid,
            onSubmit: handleSubmit,
            onCancel: { dismiss() },
            submitLabel: "Validate"
        ) {
            basicInfoSection
            timelineSection
            reflectionSection
            ValidationFeedback(
                isValid: formData.isValid,
                errors: formData.errors
            )
        }
    }

    // MARK: - Form Sections

    /// Section 1: Basic Info (number, theme, status)
    private var basicInfoSection: some View {
        Section("Basic Info") {
            Stepper(
                "Term \(formData.termNumber)",
                value: $formData.termNumber,
                in: 1...100
            )

            TextField("Theme (optional)", text: $formData.theme)

            Picker("Status", selection: $formData.status) {
                ForEach(TermStatus.allCases, id: \.self) { status in
                    Text(status.description).tag(status)
                }
            }
        }
    }

    /// Section 2: Timeline (start/end dates with computed duration)
    private var timelineSection: some View {
        Section("Timeline") {
            DatePicker(
                "Start Date",
                selection: $formData.startDate,
                displayedComponents: .date
            )

            DatePicker(
                "End Date",
                selection: $formData.endDate,
                displayedComponents: .date
            )

            // Computed duration display
            Text("Duration: \(formData.startDate.durationString(to: formData.endDate))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Section 3: Reflection (optional, collapsible)
    private var reflectionSection: some View {
        Section {
            DisclosureGroup("Reflection (optional)") {
                TextEditor(text: $formData.reflection)
                    .frame(minHeight: 100)
            }
        } footer: {
            Text("Reflections are typically written after completing a term")
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
}

// MARK: - Preview

#Preview("New Term") {
    TermFormView { formData in
        print("Validated term \(formData.termNumber): \(formData.theme)")
    }
}

#Preview("Pre-filled") {
    struct PreviewWrapper: View {
        @State var data = TermFormData()

        var body: some View {
            TermFormView { formData in
                print("Validated: \(formData)")
            }
            .onAppear {
                data.termNumber = 5
                data.theme = "Health and relationships"
                data.status = .active
                data.reflection = "Focused on building morning routines"
            }
        }
    }

    return PreviewWrapper()
}
