// ActionsListView.swift
// Main list view for displaying all actions
//
// Written by Claude Code on 2025-10-19
// Updated by Claude Code on 2025-10-22 for quick add section

import SwiftUI
import Models


/// List view displaying all actions
///
/// Shows actions sorted by log time (most recent first).
/// Supports multiple interaction modes:
/// - Click/tap to edit (mouse and touch)
/// - Right-click/long-press for context menu (Edit/Delete)
/// - Swipe gestures for quick actions (touch devices)
public struct ActionsListView: View {

    // MARK: - Initialization

    public init() {}

    // MARK: - State

    @State private var viewModel = ActionsViewModel()
    @State private var actionFormState: ActionFormState?
    @State private var activeGoals: [Goal] = []
    @State private var actionGoals: [UUID: [Goal]] = [:]
    @State private var showingBulkMatching = false

    // MARK: - Form State Wrapper

    /// Wrapper for action form presentation state
    struct ActionFormState: Identifiable {
        let id = UUID()
        let action: Action?
        let mode: ActionFormView.Mode
    }

    // MARK: - Body

    public var body: some View {
        contentView(viewModel: viewModel)
        .navigationTitle("Actions")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingBulkMatching = true
                } label: {
                    Label("Match to Goals", systemImage: "link.circle")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    actionFormState = ActionFormState(action: nil, mode: .create)
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
            }
        }
        .sheet(item: $actionFormState) { formState in
            ActionFormView(
                action: formState.action,
                mode: formState.mode,
                onSave: { action in
                    Task {
                        if formState.mode == .edit {
                            await viewModel.updateAction(action)
                        } else {
                            await viewModel.createAction(action)
                        }
                        await loadActionGoals()
                    }
                    actionFormState = nil
                },
                onCancel: {
                    actionFormState = nil
                }
            )
        }
        .sheet(isPresented: $showingBulkMatching, onDismiss: {
            Task {
                await loadActionGoals()
            }
        }) {
            BulkMatchingView()
        }
        .task {
            await loadActiveGoals()
            await loadActionGoals()
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: ActionsViewModel) -> some View {
        if let error = viewModel.error {
            ContentUnavailableView {
                Label("Error Loading Actions", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            }
        } else if viewModel.actions.isEmpty {
            ContentUnavailableView {
                Label("No Actions Yet", systemImage: "list.bullet")
            } description: {
                Text("Track what you've done by adding your first action")
            } actions: {
                Button("Add Action") {
                    actionFormState = ActionFormState(action: nil, mode: .create)
                }
            }
        } else {
            List {
                // Quick Add section (recent actions + active goals)
                QuickAddSectionView(
                    recentActions: Array(viewModel.actions.prefix(5)),
                    activeGoals: activeGoals,
                    onDuplicateAction: { action in
                        duplicateAction(action)
                    },
                    onLogActionForGoal: { goal in
                        createActionForGoal(goal)
                    }
                )

                // All Actions section
                Section("All Actions") {
                ForEach(viewModel.actions) { action in
                    ActionRowView(action: action, goals: actionGoals[action.id] ?? [])
                        .contentShape(Rectangle())
                        .onTapGesture {
                            actionFormState = ActionFormState(action: action, mode: .edit)
                        }
                        .contextMenu {
                            Button {
                                duplicateAction(action)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }

                            Button {
                                actionFormState = ActionFormState(action: action, mode: .edit)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteAction(action)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteAction(action)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                duplicateAction(action)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(.green)

                            Button {
                                actionFormState = ActionFormState(action: action, mode: .edit)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .refreshable {
                await loadActiveGoals()
                await loadActionGoals()
            }
        }
    }

    // MARK: - Helper Methods

    private func loadActiveGoals() async {
        // TODO: Implement using GoalsViewModel with @FetchAll
        // For now, leave empty until GoalsViewModel is integrated with SQLiteData
        activeGoals = []
    }

    private func loadActionGoals() async {
        // TODO: Implement using relationship queries with SQLiteData
        // For now, leave empty until relationship support is added
        actionGoals.removeAll()
    }

    /// Create a new action pre-filled from goal context
    private func createActionForGoal(_ goal: Goal) {
        let suggestedTitle: String?
        if let goalTitle = goal.title {
            suggestedTitle = "Progress on: \(goalTitle)"
        } else if let description = goal.detailedDescription {
            let truncated = description.prefix(40)
            suggestedTitle = "Progress on: \(truncated)\(description.count > 40 ? "..." : "")"
        } else {
            suggestedTitle = nil
        }

        let action = Action(
            title: suggestedTitle,
            detailedDescription: nil,
            freeformNotes: nil,
            measuresByUnit: [:],
            durationMinutes: nil,
            startTime: nil,
            logTime: Date(),
            id: UUID()
        )

        actionFormState = ActionFormState(action: action, mode: .create)
    }

    /// Duplicate an existing action with new ID and current timestamp
    private func duplicateAction(_ action: Action) {
        let duplicate = Action(
            title: action.title,
            detailedDescription: action.detailedDescription,
            freeformNotes: action.freeformNotes,
            measuresByUnit: action.measuresByUnit,
            durationMinutes: action.durationMinutes,
            startTime: nil,
            logTime: Date(),
            id: UUID()
        )

        actionFormState = ActionFormState(action: duplicate, mode: .create)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActionsListView()
    }
}
