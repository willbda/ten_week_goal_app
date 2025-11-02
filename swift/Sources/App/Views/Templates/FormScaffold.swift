//
// FormScaffold.swift
// Reusable form wrapper with consistent navigation and toolbar
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Provides consistent navigation structure, toolbar buttons, and dismiss handling
// for all entity forms (Terms, Goals, Actions, Values).
//
// DESIGN:
// - NavigationStack wrapper for forms
// - Cancel button (leading, always enabled)
// - Submit button (trailing, conditionally disabled)
// - Form content injected via @ViewBuilder
//

import SwiftUI

/// Reusable wrapper for entity form views
///
/// Provides consistent navigation, toolbar, and structure for all forms.
///
/// **Usage**:
/// ```swift
/// FormScaffold(
///     title: "New Term",
///     canSubmit: formData.isValid,
///     submitLabel: "Save",
///     onSubmit: { saveToDatabase() },
///     onCancel: { dismiss() }
/// ) {
///     Section("Details") {
///         TextField("Name", text: $name)
///     }
/// }
/// ```
public struct FormScaffold<Content: View>: View {

    // MARK: - Properties

    private let title: String
    private let canSubmit: Bool
    private let submitLabel: String
    private let onSubmit: () -> Void
    private let onCancel: () -> Void
    private let content: () -> Content

    // MARK: - Initialization

    public init(
        title: String,
        canSubmit: Bool,
        submitLabel: String = "Save",
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.canSubmit = canSubmit
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                content()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(submitLabel, action: onSubmit)
                        .disabled(!canSubmit)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Valid Form") {
    FormScaffold(
        title: "New Term",
        canSubmit: true,
        submitLabel: "Save",
        onSubmit: { print("Saved") },
        onCancel: { print("Cancelled") }
    ) {
        Section("Details") {
            TextField("Name", text: .constant("Sample Term"))
            TextField("Description", text: .constant("This is a sample"))
        }
        
        Section("Dates") {
            DatePicker("Start Date", selection: .constant(Date()))
            DatePicker("End Date", selection: .constant(Date()))
        }
    }
}

#Preview("Invalid Form") {
    FormScaffold(
        title: "Edit Goal",
        canSubmit: false,
        submitLabel: "Validate",
        onSubmit: { print("Saved") },
        onCancel: { print("Cancelled") }
    ) {
        Section("Sample") {
            Text("Submit button should be disabled")
            TextField("Empty Field", text: .constant(""))
        }
    }
}
