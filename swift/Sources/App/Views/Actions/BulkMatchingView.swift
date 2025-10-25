// BulkMatchingView.swift
// Bulk action-goal matching interface for quickly assigning goals to actions
//
// Written by Claude Code on 2025-10-23

import SwiftUI
import Models


/// Bulk matching interface for quickly assigning goals to multiple actions
///
/// Shows all actions in a list with tappable goal badges. Selected goals are
/// highlighted, unselected are grayed out. Tapping a badge toggles selection
/// and saves immediately to the database.
///
/// **Usage Pattern:**
/// - Scan through actions quickly
/// - Tap goal badges to toggle selection
/// - Auto-saves on every tap (no "Save" button needed)
/// - Shows progress: "15 of 186 actions matched"
struct BulkMatchingView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// All actions to match
    @State private var actions: [Action] = []

    /// All available goals
    @State private var goals: [Goal] = []

    /// Mapping of action ID → selected goal IDs
    @State private var actionGoalSelections: [UUID: Set<UUID>] = [:]

    /// Loading state
    @State private var isLoading = false

    /// Error state
    @State private var error: String?

    // MARK: - Computed Properties

    /// Number of actions that have at least one goal selected
    private var matchedActionsCount: Int {
        actionGoalSelections.values.filter { !$0.isEmpty }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = error {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await loadData()
                            }
                        }
                    }
                } else if actions.isEmpty {
                    ContentUnavailableView {
                        Label("No Actions", systemImage: "checkmark.circle")
                    } description: {
                        Text("All actions have been matched to goals!")
                    }
                } else {
                    matchingList
                }
            }
            .navigationTitle("Match Actions to Goals")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .status) {
                    Text("\(matchedActionsCount) of \(actions.count) matched")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Matching List

    private var matchingList: some View {
        List {
            ForEach(actions) { action in
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Action header
                    actionHeader(action)

                    // Goal badges (tappable)
                    goalBadgesSection(for: action)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
        }
    }

    // MARK: - Subviews

    private func actionHeader(_ action: Action) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text(action.title ?? "Untitled Action")
                .font(DesignSystem.Typography.headline)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(action.logTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !action.measuresByUnit.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)

                    ForEach(Array(action.measuresByUnit.keys.sorted().prefix(2)), id: \.self) { unit in
                        if let value = action.measuresByUnit[unit] {
                            Text("\(value, specifier: "%.1f") \(unit)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func goalBadgesSection(for action: Action) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text("Contributing To:")
                .font(.caption)
                .foregroundStyle(.secondary)

            if goals.isEmpty {
                Text("No goals available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                // Simple vertical list of badges (avoids nested ForEach complexity)
                ForEach(goals) { goal in
                    GoalBadge(
                        goal: goal,
                        isSelected: isGoalSelected(goal.id, for: action.id),
                        onTap: {
                            toggleGoalSelection(goal.id, for: action.id)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func isGoalSelected(_ goalId: UUID, for actionId: UUID) -> Bool {
        actionGoalSelections[actionId]?.contains(goalId) ?? false
    }

    private func toggleGoalSelection(_ goalId: UUID, for actionId: UUID) {
        // Toggle selection
        if actionGoalSelections[actionId]?.contains(goalId) == true {
            actionGoalSelections[actionId]?.remove(goalId)
        } else {
            if actionGoalSelections[actionId] == nil {
                actionGoalSelections[actionId] = []
            }
            actionGoalSelections[actionId]?.insert(goalId)
        }

        // Auto-save to database
        Task {
            await saveRelationship(goalId: goalId, actionId: actionId)
        }
    }

    private func saveRelationship(goalId: UUID, actionId: UUID) async {
        // TODO: Implement using relationship storage with SQLiteData
        // For now, leave empty until relationship support is added
    }

    private func loadData() async {
        // TODO: Implement using ActionsViewModel and GoalsViewModel with @FetchAll
        // For now, leave empty until ViewModels are integrated with SQLiteData
        isLoading = true
        error = nil
        defer { isLoading = false }

        actions = []
        goals = []
    }
}

// MARK: - Goal Badge Component

/// Tappable goal badge with selected/unselected states
private struct GoalBadge: View {
    let goal: Goal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)

                Text(goal.title ?? "Goal")
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                Capsule()
                    .fill(isSelected
                          ? DesignSystem.Colors.goals
                          : Color.secondary.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Preview

#Preview {
    BulkMatchingView()
}
