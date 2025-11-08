//
// ValidationFeedback.swift
// Reusable validation status display for forms
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Displays validation status (valid/invalid) and lists any validation errors.
// Used consistently across all entity forms.

import SwiftUI

/// Displays validation status and error messages
///
/// Shows a green checkmark when valid, or orange warning with error list when invalid.
///
/// **Usage**:
/// ```swift
/// ValidationFeedback(
///     isValid: formData.isValid,
///     errors: formData.errors
/// )
/// ```
public struct ValidationFeedback: View {

    // MARK: - Properties

    /// Whether the form data is currently valid
    let isValid: Bool

    /// List of validation error messages (empty if valid)
    let errors: [String]

    // MARK: - Initialization

    public init(isValid: Bool, errors: [String]) {
        self.isValid = isValid
        self.errors = errors
    }

    // MARK: - Body

    public var body: some View {
        Section {
            if isValid {
                Label {
                    Text("Form is valid")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Label {
                    Text("Fix errors to continue")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }

                if !errors.isEmpty {
                    ForEach(errors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Validation")
        }
    }
}

// MARK: - Preview

#Preview("Valid State") {
    Form {
        ValidationFeedback(
            isValid: true,
            errors: []
        )
    }
}

#Preview("Invalid with Errors") {
    Form {
        ValidationFeedback(
            isValid: false,
            errors: [
                "Term number must be positive",
                "End date must be after start date",
                "Theme exceeds 100 characters"
            ]
        )
    }
}

#Preview("Invalid No Errors") {
    Form {
        ValidationFeedback(
            isValid: false,
            errors: []
        )
    }
}
