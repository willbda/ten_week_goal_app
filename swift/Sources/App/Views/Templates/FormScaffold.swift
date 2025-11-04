//
// FormScaffold.swift
// Reusable form wrapper with consistent navigation and toolbar
//
// Written by Claude Code on 2025-11-01
// Updated by Claude Code on 2025-11-01 - Added extensive customization parameters
//
// PURPOSE:
// Provides consistent navigation structure, toolbar buttons, and dismiss handling
// for all entity forms (Terms, Goals, Actions, Values).
//
// DESIGN:
// - Form wrapper with consistent toolbar and structure
// - Cancel button (leading, optional)
// - Submit button (trailing, conditionally disabled)
// - Form content injected via @ViewBuilder
// - Highly customizable via parameters
// - Navigation context provided by parent view
//
// CUSTOMIZATION KNOBS & DIALS:
//
// REQUIRED PARAMETERS (must come first for trailing closure syntax):
//   - title: String
//   - canSubmit: Bool
//   - onSubmit: () -> Void
//   - onCancel: () -> Void
//
// OPTIONAL PARAMETERS (all have defaults):
//
// 🎛️ CORE CUSTOMIZATION:
//   - submitLabel: String (default: "Save")
//   - cancelLabel: String (default: "Cancel")
//
// 🎛️ APPEARANCE:
//   - formStyle.backgroundColor: Color? (default: nil)
//   - formStyle.scrollIndicatorsVisible: Bool (default: true)
//   // - formStyle.scrollDisabled: Bool [COMMENTED OUT - not universally compatible]
//
// 🎛️ TOOLBAR:
//   - showCancelButton: Bool (default: true)
//   - cancelButtonRole: ButtonRole? (default: nil, can be .destructive, .cancel)
//   - submitButtonRole: ButtonRole? (default: nil, can be .destructive, .cancel)
//   - leadingToolbarItems: [ToolbarItemConfig] (default: [])
//   - trailingToolbarItems: [ToolbarItemConfig] (default: [])
//
// 🎛️ VALIDATION:
//   - showValidationFeedback: Bool (default: false) - Shows orange banner at top
//   - validationMessage: String? (default: nil) - Message text in banner
//
// 🎛️ ACCESSIBILITY:
//   - accessibilityHint: String? (default: nil)
//
// COMMENTED OUT KNOBS (platform compatibility issues):
//   - navigationTitleDisplayMode [iOS only - causes compilation issues on macOS]
//
// USAGE EXAMPLES: See #Preview blocks at bottom of file
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
///     onSubmit: { saveToDatabase() },
///     onCancel: { dismiss() },
///     submitLabel: "Save"
/// ) {
///     Section("Details") {
///         TextField("Name", text: $name)
///     }
/// }
/// ```
public struct FormScaffold<Content: View>: View {

    // MARK: - Properties

    // Core properties
    private let title: String
    private let canSubmit: Bool
    private let submitLabel: String
    private let onSubmit: () -> Void
    private let onCancel: () -> Void
    private let content: () -> Content

    // Appearance customization
    private let formStyle: FormStyleConfig

    // Toolbar customization
    private let cancelLabel: String
    private let showCancelButton: Bool
    private let cancelButtonRole: ButtonRole?
    private let submitButtonRole: ButtonRole?

    // Additional toolbar items
    private let leadingToolbarItems: [ToolbarItemConfig]
    private let trailingToolbarItems: [ToolbarItemConfig]

    // Visual feedback
    private let showValidationFeedback: Bool
    private let validationMessage: String?

    // Accessibility
    private let accessibilityHint: String?

    // MARK: - Supporting Types

    public struct FormStyleConfig: Sendable {
        let backgroundColor: Color?
        // let scrollDisabled: Bool  // Commented: Not compatible with all iOS versions
        let scrollIndicatorsVisible: Bool
    }
}

// MARK: - Static Defaults (outside generic type)

extension FormScaffold.FormStyleConfig {
    public static var standard: FormScaffold.FormStyleConfig {
        FormScaffold.FormStyleConfig(
            backgroundColor: nil,
            scrollIndicatorsVisible: true
        )
    }
}

// MARK: - FormScaffold Continued

extension FormScaffold {

public struct ToolbarItemConfig: Identifiable {
        public let id = UUID()
        let label: String
        let systemImage: String?
        let action: () -> Void
        let disabled: Bool

        public init(
            label: String,
            systemImage: String? = nil,
            action: @escaping () -> Void,
            disabled: Bool = false
        ) {
            self.label = label
            self.systemImage = systemImage
            self.action = action
            self.disabled = disabled
        }
    }

    // MARK: - Initialization

    public init(
        title: String,
        canSubmit: Bool,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,

        // Core customization (commonly used)
        submitLabel: String = "Save",
        cancelLabel: String = "Cancel",

        // Appearance
        formStyle: FormStyleConfig = .standard,

        // Toolbar configuration
        showCancelButton: Bool = true,
        cancelButtonRole: ButtonRole? = nil,
        submitButtonRole: ButtonRole? = nil,
        leadingToolbarItems: [ToolbarItemConfig] = [],
        trailingToolbarItems: [ToolbarItemConfig] = [],

        // Validation feedback
        showValidationFeedback: Bool = false,
        validationMessage: String? = nil,

        // Accessibility
        accessibilityHint: String? = nil,

        @ViewBuilder content: @escaping () -> Content
    ) {
        // Core
        self.title = title
        self.canSubmit = canSubmit
        self.submitLabel = submitLabel
        self.cancelLabel = cancelLabel
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.content = content

        // Appearance
        self.formStyle = formStyle

        // Toolbar
        self.showCancelButton = showCancelButton
        self.cancelButtonRole = cancelButtonRole
        self.submitButtonRole = submitButtonRole
        self.leadingToolbarItems = leadingToolbarItems
        self.trailingToolbarItems = trailingToolbarItems

        // Validation
        self.showValidationFeedback = showValidationFeedback
        self.validationMessage = validationMessage

        // Accessibility
        self.accessibilityHint = accessibilityHint
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            validationBannerView
            formContent
        }
    }

    @ViewBuilder
    private var validationBannerView: some View {
        if showValidationFeedback, let message = validationMessage {
            ValidationBanner(message: message)
        }
    }

    private var formContent: some View {
        Form {
            content()
        }
        .navigationTitle(title)
        .applyFormStyle(formStyle)
        .toolbar {
            cancelToolbarItem
            leadingToolbarContent
            submitToolbarItem
            trailingToolbarContent
        }
        .accessibilityHint(accessibilityHint ?? "")
    }

    @ToolbarContentBuilder
    private var cancelToolbarItem: some ToolbarContent {
        if showCancelButton {
            ToolbarItem(placement: .cancellationAction) {
                Button(cancelLabel, role: cancelButtonRole, action: onCancel)
            }
        }
    }

    @ToolbarContentBuilder
    private var submitToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(submitLabel, role: submitButtonRole, action: onSubmit)
                .disabled(!canSubmit)
        }
    }

    @ToolbarContentBuilder
    private var leadingToolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItemGroup(placement: .navigationBarLeading) {
            ForEach(leadingToolbarItems) { item in
                toolbarButton(for: item)
            }
        }
        #else
        ToolbarItemGroup(placement: .automatic) {
            ForEach(leadingToolbarItems) { item in
                toolbarButton(for: item)
            }
        }
        #endif
    }

    @ToolbarContentBuilder
    private var trailingToolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            ForEach(trailingToolbarItems) { item in
                toolbarButton(for: item)
            }
        }
        #else
        ToolbarItemGroup(placement: .automatic) {
            ForEach(trailingToolbarItems) { item in
                toolbarButton(for: item)
            }
        }
        #endif
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func toolbarButton(for config: ToolbarItemConfig) -> some View {
        if let systemImage = config.systemImage {
            Button(action: config.action) {
                Label(config.label, systemImage: systemImage)
            }
            .disabled(config.disabled)
        } else {
            Button(config.label, action: config.action)
                .disabled(config.disabled)
        }
    }
}

// MARK: - View Extensions

private extension View {
    @ViewBuilder
    func applyFormStyle<Content: View>(_ style: FormScaffold<Content>.FormStyleConfig) -> some View {
        self
            .background(style.backgroundColor)
            // .scrollDisabledIfNeeded(style.scrollDisabled)  // Commented: Not universally compatible
            .scrollIndicators(style.scrollIndicatorsVisible ? .visible : .hidden)
    }
}

/// Validation feedback banner
private struct ValidationBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Previews

#Preview("Basic Form") {
    FormScaffold(
        title: "New Term",
        canSubmit: true,
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

#Preview("With Validation Feedback") {
    FormScaffold(
        title: "Edit Goal",
        canSubmit: false,
        onSubmit: { print("Saved") },
        onCancel: { print("Cancelled") },
        submitLabel: "Validate",
        showValidationFeedback: true,
        validationMessage: "Title and target date are required"
    ) {
        Section("Sample") {
            Text("Submit button disabled - validation feedback shown")
            TextField("Empty Field", text: .constant(""))
        }
    }
}

#Preview("Custom Toolbar Items") {
    FormScaffold(
        title: "Advanced Form",
        canSubmit: true,
        onSubmit: { print("Created") },
        onCancel: { print("Discarded") },
        submitLabel: "Create",
        cancelLabel: "Discard",  // 🎛️ Knob: Custom cancel label
        leadingToolbarItems: [  // 🎛️ Knob: Additional leading buttons
            .init(label: "Help", systemImage: "questionmark.circle", action: { print("Help") })
        ],
        trailingToolbarItems: [  // 🎛️ Knob: Additional trailing buttons
            .init(label: "Preview", systemImage: "eye", action: { print("Preview") }),
            .init(label: "Template", systemImage: "doc.text", action: { print("Template") })
        ]
    ) {
        Section("Form with extra toolbar buttons") {
            Text("Notice the additional help and preview buttons")
        }
    }
}

#Preview("Destructive Actions") {
    FormScaffold(
        title: "Delete Item",
        canSubmit: true,
        onSubmit: { print("Deleted") },
        onCancel: { print("Cancelled") },
        submitLabel: "Delete",
        submitButtonRole: .destructive,  // 🎛️ Knob: .destructive makes it red
        showValidationFeedback: true,
        validationMessage: "This action cannot be undone"
    ) {
        Section {
            Text("Are you sure you want to delete this item?")
        }
    }
}

#Preview("No Cancel Button") {
    FormScaffold(
        title: "Required Form",
        canSubmit: false,
        onSubmit: { print("Saved") },
        onCancel: { print("Should not appear") },
        showCancelButton: false  // 🎛️ Knob: Hide cancel button
    ) {
        Section {
            Text("This form must be completed")
            TextField("Required Field", text: .constant(""))
        }
    }
}

#Preview("Custom Styling") {
    FormScaffold(
        title: "Styled Form",
        canSubmit: true,
        onSubmit: { print("Saved") },
        onCancel: { print("Cancelled") },
        formStyle: .init(  // 🎛️ Knob: Custom form appearance
            backgroundColor: Color.blue.opacity(0.05),
            scrollIndicatorsVisible: false  // 🎛️ Knob: Hide scroll indicators
        )
    ) {
        Section("Custom Background") {
            Text("Notice the subtle blue background")
            Text("Scroll indicators are hidden")
        }
    }
}
