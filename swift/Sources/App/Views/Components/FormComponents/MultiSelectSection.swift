//
// MultiSelectSection.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Reusable multi-select section with Toggle bindings
//
// SOLVES: Duplicated multi-select logic across forms
// PATTERN: Generic over Item type, Set<UUID> binding, consistent styling
// USAGE: Goal contributions, Value alignments, Term assignments, any multi-select
//
// DESIGN:
// - Generic: Works with any Identifiable item where ID == UUID
// - Binding: Syncs with Set<UUID> (standard pattern)
// - Empty state: Shows helpful message when no items available
// - Toggle pattern: Consistent across all forms
// - Section styling: Header + optional footer
//
// EXAMPLE:
// MultiSelectSection(
//     items: viewModel.availableGoals,
//     title: "Goal Contributions",
//     itemLabel: { goal in goal.title },
//     selectedIds: $selectedGoalIds
// )

import SwiftUI

public struct MultiSelectSection<Item: Identifiable>: View where Item.ID == UUID {
    let items: [Item]
    let title: String
    let itemLabel: (Item) -> String
    @Binding var selectedIds: Set<UUID>

    public init(
        items: [Item],
        title: String,
        itemLabel: @escaping (Item) -> String,
        selectedIds: Binding<Set<UUID>>
    ) {
        self.items = items
        self.title = title
        self.itemLabel = itemLabel
        self._selectedIds = selectedIds
    }

    public var body: some View {
        Section {
            if items.isEmpty {
                Text("No \(title.lowercased()) available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    Toggle(isOn: binding(for: item.id)) {
                        Text(itemLabel(item))
                    }
                    .padding(.vertical, 4)  // Modern spacing for touch targets
                }
            }
        } header: {
            Text(title)
        }
    }

    // MARK: - Helpers

    /// Creates a binding for individual item selection
    ///
    /// Synchronizes Set<UUID> with Toggle's Bool state
    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedIds.contains(id) },
            set: { isSelected in
                if isSelected {
                    selectedIds.insert(id)
                } else {
                    selectedIds.remove(id)
                }
            }
        )
    }
}

// MARK: - Preview

private struct MultiSelectPreviewItem: Identifiable {
    let id = UUID()
    let name: String
}

#Preview("With Items") {
    Form {
        MultiSelectSection(
            items: [
                MultiSelectPreviewItem(name: "Goal 1: Health"),
                MultiSelectPreviewItem(name: "Goal 2: Career"),
                MultiSelectPreviewItem(name: "Goal 3: Relationships")
            ],
            title: "Goal Contributions",
            itemLabel: { $0.name },
            selectedIds: .constant([])
        )
    }
}

#Preview("Empty State") {
    Form {
        MultiSelectSection(
            items: [] as [MultiSelectPreviewItem],
            title: "Goal Contributions",
            itemLabel: { $0.name },
            selectedIds: .constant([])
        )
    }
}
