// ExpandableFormSection.swift
// Reusable expandable form section with toggle
//
// Written by Claude Code on 2025-10-21
//
// This component provides a consistent pattern for progressive disclosure
// in forms. Used across GoalFormView, ActionFormView, TermFormView, etc.

import SwiftUI

/// Expandable form section with toggle control
///
/// Provides progressive disclosure for complex forms. The section can be
/// collapsed (hiding content) or expanded (showing content) based on a
/// binding.
///
/// Example:
/// ```swift
/// @State private var showMeasurement = false
///
/// ExpandableFormSection(
///     title: "Include measurement target",
///     systemImage: "ruler",
///     isExpanded: $showMeasurement
/// ) {
///     TextField("Unit", text: $unit)
///     TextField("Target", value: $target, format: .number)
/// }
/// ```
public struct ExpandableFormSection<Content: View>: View {

    // MARK: - Properties

    /// Section title shown in toggle
    let title: String

    /// Optional SF Symbol icon
    let systemImage: String?

    /// Optional subtitle/description shown below toggle
    let subtitle: String?

    /// Binding to control expanded/collapsed state
    @Binding var isExpanded: Bool

    /// Content shown when expanded
    @ViewBuilder let content: () -> Content

    // MARK: - Initialization

    /// Create expandable section with optional icon and subtitle
    /// - Parameters:
    ///   - title: Section title shown in toggle
    ///   - systemImage: Optional SF Symbol name
    ///   - subtitle: Optional description text
    ///   - isExpanded: Binding to control visibility
    ///   - content: View builder for section content
    public init(
        title: String,
        systemImage: String? = nil,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        Section {
            // Toggle control
            Toggle(isOn: $isExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    if let systemImage = systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Expandable content
            if isExpanded {
                content()
            }
        }
    }
}

// MARK: - Preview
// Previews removed due to linter issues with @Previewable
// The component works correctly in the app
