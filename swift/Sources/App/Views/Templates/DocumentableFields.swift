//
// DocumentableFields.swift
// Reusable section for entities with title/description/notes
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Shared form section for DomainAbstraction entities (Actions, Values, TimePeriods, etc.)
// that have title, detailedDescription, and freeformNotes fields.
//
// NOT used by DomainBasic entities (Terms, Goals) which don't have these fields.

import SwiftUI

/// Form section for Documentable protocol fields (title, description, notes)
///
/// **Usage** (for Actions, Values, TimePeriods):
/// ```swift
/// DocumentableFields(
///     title: $formData.title,
///     detailedDescription: $formData.description,
///     freeformNotes: $formData.notes
/// )
/// ```
///
/// **NOT for**: Terms, Goals (they're DomainBasic, not DomainAbstraction)
public struct DocumentableFields: View {

    // MARK: - Properties

    /// Title/name of the entity
    @Binding var title: String

    /// Detailed description (multi-line)
    @Binding var detailedDescription: String

    /// Freeform notes (optional, collapsible)
    @Binding var freeformNotes: String

    /// Placeholder for title field
    let titlePrompt: String

    /// Placeholder for description field
    let descriptionPrompt: String

    /// Whether to show the notes disclosure group
    let showNotes: Bool

    // MARK: - Initialization

    public init(
        title: Binding<String>,
        detailedDescription: Binding<String>,
        freeformNotes: Binding<String>,
        titlePrompt: String = "Title",
        descriptionPrompt: String = "Description",
        showNotes: Bool = true
    ) {
        self._title = title
        self._detailedDescription = detailedDescription
        self._freeformNotes = freeformNotes
        self.titlePrompt = titlePrompt
        self.descriptionPrompt = descriptionPrompt
        self.showNotes = showNotes
    }

    // MARK: - Body

    public var body: some View {
        Section("Details") {
            TextField(titlePrompt, text: $title)

            TextField(
                descriptionPrompt,
                text: $detailedDescription,
                axis: .vertical
            )
            .lineLimit(3...6)

            if showNotes {
                DisclosureGroup("Additional Notes") {
                    TextEditor(text: $freeformNotes)
                        .frame(minHeight: 100)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Content") {
    Form {
        DocumentableFields(
            title: .constant("Morning Run"),
            detailedDescription: .constant("Ran along the waterfront trail"),
            freeformNotes: .constant("Felt energized, good weather")
        )
    }
}

#Preview("Empty") {
    Form {
        DocumentableFields(
            title: .constant(""),
            detailedDescription: .constant(""),
            freeformNotes: .constant("")
        )
    }
}

#Preview("Without Notes") {
    Form {
        DocumentableFields(
            title: .constant("Action Title"),
            detailedDescription: .constant("Action description"),
            freeformNotes: .constant(""),
            showNotes: false
        )
    }
}
