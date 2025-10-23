// FormFieldModifiers.swift
// Reusable view modifiers for form field styling and validation
//
// Written by Claude Code on 2025-10-21
//
// Provides consistent validation, styling, and help text across all forms

import SwiftUI

// MARK: - Validation Modifier

/// Adds validation indicator and error message to form fields
///
/// Shows a warning icon when field is invalid and provides optional
/// error message via help text.
///
/// Example:
/// ```swift
/// TextField("Email", text: $email)
///     .validationState(isValid: email.contains("@"), error: "Invalid email")
/// ```
struct ValidationStateModifier: ViewModifier {
    let isValid: Bool
    let errorMessage: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .trailing) {
                if !isValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .padding(.trailing, 8)
                        .help(errorMessage ?? "Invalid input")
                }
            }
    }
}

extension View {
    /// Add validation indicator to a form field
    /// - Parameters:
    ///   - isValid: Whether the current value is valid
    ///   - error: Optional error message shown on hover
    /// - Returns: View with validation indicator
    public func validationState(isValid: Bool, error: String? = nil) -> some View {
        modifier(ValidationStateModifier(isValid: isValid, errorMessage: error))
    }
}

// MARK: - Field Help Text Modifier

/// Adds helper text below a form field
///
/// Provides context or instructions for form fields.
///
/// Example:
/// ```swift
/// TextField("Priority", value: $priority, format: .number)
///     .fieldHelp("Priority from 1 (highest) to 100 (lowest)")
/// ```
struct FieldHelpModifier: ViewModifier {
    let helpText: String
    let icon: String?

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content

            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.caption2)
                }
                Text(helpText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension View {
    /// Add help text below a form field
    /// - Parameters:
    ///   - text: Help text to display
    ///   - icon: Optional SF Symbol icon
    /// - Returns: View with help text
    public func fieldHelp(_ text: String, icon: String? = nil) -> some View {
        modifier(FieldHelpModifier(helpText: text, icon: icon))
    }
}

// MARK: - Required Field Modifier

/// Marks a field as required with visual indicator
///
/// Adds an asterisk (*) next to the field label
///
/// Example:
/// ```swift
/// TextField("Title", text: $title)
///     .requiredField()
/// ```
struct RequiredFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 4) {
            content
            Text("*")
                .foregroundStyle(.red)
                .font(DesignSystem.Typography.callout)
        }
    }
}

extension View {
    /// Mark a field as required
    /// - Returns: View with required indicator
    public func requiredField() -> some View {
        modifier(RequiredFieldModifier())
    }
}

// MARK: - Form Section Header Modifier

/// Styled header for form sections
///
/// Provides consistent typography and spacing for section headers
///
/// Example:
/// ```swift
/// Text("Basic Information")
///     .formSectionHeader()
/// ```
struct FormSectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(.primary)
            .textCase(nil) // Override default uppercase in Form
    }
}

extension View {
    /// Style text as a form section header
    /// - Returns: Styled header view
    public func formSectionHeader() -> some View {
        modifier(FormSectionHeaderModifier())
    }
}

// MARK: - Character Counter Modifier

/// Adds character count below text field
///
/// Shows current length and optional maximum length
///
/// Example:
/// ```swift
/// TextField("Description", text: $description)
///     .characterCount(current: description.count, max: 500)
/// ```
struct CharacterCountModifier: ViewModifier {
    let current: Int
    let maximum: Int?

    var countText: String {
        if let maximum = maximum {
            return "\(current) / \(maximum)"
        } else {
            return "\(current)"
        }
    }

    var isOverLimit: Bool {
        if let maximum = maximum {
            return current > maximum
        }
        return false
    }

    func body(content: Content) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            content

            Text(countText)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(isOverLimit ? .red : .secondary)
        }
    }
}

extension View {
    /// Add character count below text field
    /// - Parameters:
    ///   - current: Current character count
    ///   - max: Optional maximum character limit
    /// - Returns: View with character counter
    public func characterCount(current: Int, max: Int? = nil) -> some View {
        modifier(CharacterCountModifier(current: current, maximum: max))
    }
}

// MARK: - Combined Form Field Style

/// Complete form field styling with all common features
///
/// Combines validation, help text, and required indicator
///
/// Example:
/// ```swift
/// TextField("Email", text: $email)
///     .formField(
///         isValid: email.contains("@"),
///         error: "Invalid email format",
///         help: "We'll never share your email",
///         isRequired: true
///     )
/// ```
struct FormFieldStyle: ViewModifier {
    let isValid: Bool
    let errorMessage: String?
    let helpText: String?
    let isRequired: Bool

    func body(content: Content) -> some View {
        Group {
            if isRequired {
                content
                    .requiredField()
            } else {
                content
            }
        }
        .validationState(isValid: isValid, error: errorMessage)
        .if(helpText != nil) { view in
            view.fieldHelp(helpText!)
        }
    }
}

extension View {
    /// Apply complete form field styling
    /// - Parameters:
    ///   - isValid: Whether current value is valid (default: true)
    ///   - error: Optional error message
    ///   - help: Optional help text
    ///   - isRequired: Whether field is required (default: false)
    /// - Returns: Fully styled form field
    public func formField(
        isValid: Bool = true,
        error: String? = nil,
        help: String? = nil,
        isRequired: Bool = false
    ) -> some View {
        modifier(FormFieldStyle(
            isValid: isValid,
            errorMessage: error,
            helpText: help,
            isRequired: isRequired
        ))
    }
}

// MARK: - Conditional Modifier Helper

extension View {
    /// Conditionally apply a view modifier
    /// - Parameters:
    ///   - condition: Whether to apply the modifier
    ///   - transform: Modifier to apply if condition is true
    /// - Returns: Transformed view or original view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Previews

#Preview("Validation States") {
    Form {
        Section("Validation Examples") {
            TextField("Valid Email", text: .constant("test@example.com"))
                .validationState(isValid: true)

            TextField("Invalid Email", text: .constant("invalid"))
                .validationState(isValid: false, error: "Must contain @")

            TextField("Missing Required", text: .constant(""))
                .requiredField()
                .validationState(isValid: false, error: "This field is required")
        }
    }
}

#Preview("Help Text") {
    Form {
        Section("Field Help") {
            TextField("Priority", value: .constant(50), format: .number)
                .fieldHelp("Priority from 1 (highest) to 100 (lowest)", icon: "info.circle")

            TextField("Description", text: .constant(""), axis: .vertical)
                .fieldHelp("Describe your goal in detail")
        }
    }
}

// Additional previews removed due to linter issues with @Previewable
// The modifiers work correctly in the app
