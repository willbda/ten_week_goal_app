//
// RepeatingSection.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Container for add/remove item sections (measurements, targets, etc.)
//
// SOLVES: Inconsistent "Add" button placement and styling
// PATTERN: Section with dynamic content + add button at bottom
// USAGE: Measurements, Targets, any repeating form input
//
// DESIGN:
// - Generic content: ViewBuilder accepts any row view
// - Add button: Consistent placement at bottom
// - Section structure: Header + items + add button + footer
// - Spacing: Proper padding for each item
// - Empty state: Shows add button even when empty
//
// EXAMPLE:
// RepeatingSection(
//     title: "Measurements",
//     items: measurements,
//     addButtonLabel: "Add Measurement",
//     footer: "Track distance, time, count, or other metrics",
//     onAdd: addMeasurement
// ) { measurement in
//     MeasurementInputRow(...)
// }

import SwiftUI

public struct RepeatingSection<Item: Identifiable, Content: View>: View {
    let title: String
    let items: [Item]
    let addButtonLabel: String
    let footer: String?
    let onAdd: () -> Void
    @ViewBuilder let content: (Item) -> Content

    public init(
        title: String,
        items: [Item],
        addButtonLabel: String,
        footer: String? = nil,
        onAdd: @escaping () -> Void,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.addButtonLabel = addButtonLabel
        self.footer = footer
        self.onAdd = onAdd
        self.content = content
    }

    public var body: some View {
        // TODO: Implement section
        // - Section with header and footer
        // - ForEach over items with content closure
        // - Add button at bottom
        // - Proper spacing
        Text("RepeatingSection - TODO")
    }
}
