// ActionsListView.swift
// Main list view for displaying all actions
//
// Written by Claude Code on 2025-10-19
// Updated by Claude Code on 2025-10-22 for quick add section

import SwiftUI
import Models
import Database

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

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - State

    /// View model for actions management
    @State private var viewModel: ActionsViewModel?

    /// Form presentation state (combines action + mode)
    @State private var actionFormState: ActionFormState?

    /// Active goals for quick add section
    @State private var activeGoals: [Goal] = []

    // MARK: - Form State Wrapper

    /// Wrapper for action form presentation state
    struct ActionFormState: Identifiable {
        let id = UUID()
        let action: Action?
        let mode: ActionFormView.Mode
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                Text("Database not initialized")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Actions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    actionFormState = ActionFormState(action: nil, mode: .create)
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
                .disabled(viewModel == nil)
            }
        }
        .sheet(item: $actionFormState) { formState in
            if let viewModel = viewModel {
                ActionFormView(
                    action: formState.action,
                    mode: formState.mode,
                    onSave: { action in
                        Task {
                            if formState.mode == .edit {
                                // Edit mode - update existing action
                                await viewModel.updateAction(action)
                            } else {
                                // Create mode - create new action
                                await viewModel.createAction(action)
                            }
                        }
                        actionFormState = nil
                    },
                    onCancel: {
                        actionFormState = nil
                    }
                )
            }
        }
        .task {
            // Initialize view model when view appears
            if let database = appViewModel.databaseManager {
                viewModel = ActionsViewModel(database: database)
                await viewModel?.loadActions()
                await loadActiveGoals()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: ActionsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView("Loading actions...")
        } else if let error = viewModel.error {
            ContentUnavailableView {
                Label("Error Loading Actions", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Retry") {
                    Task {
                        await viewModel.loadActions()
                    }
                }
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
                    ActionRowView(action: action)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Click to edit (works with mouse on macOS)
                            actionFormState = ActionFormState(action: action, mode: .edit)
                        }
                        .contextMenu {
                            // Right-click menu (macOS) / long-press menu (iOS)
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
                await viewModel.loadActions()
                await loadActiveGoals()
            }
        }
    }

    // MARK: - Helper Methods

    /// Load active goals for quick add section
    ///
    /// Fetches goals with target dates in the future for the quick add section.
    private func loadActiveGoals() async {
        guard let database = appViewModel.databaseManager else { return }

        do {
            // Fetch all goals and filter to active ones
            let allGoals: [Goal] = try await database.fetchGoals()
            let today = Calendar.current.startOfDay(for: Date())

            activeGoals = allGoals.filter { goal in
                guard let targetDate = goal.targetDate else { return false }
                let goalDay = Calendar.current.startOfDay(for: targetDate)
                return goalDay >= today
            }
            .sorted { ($0.priority) < ($1.priority) }  // Sort by priority
            .prefix(5)
            .map { $0 }
        } catch {
            print("❌ Failed to load active goals: \(error)")
        }
    }

    /// Create a new action pre-filled from goal context
    ///
    /// Creates an action with:
    /// - Title suggested from goal description
    /// - Current timestamp
    ///
    /// Opens ActionFormView pre-filled with the generated data.
    private func createActionForGoal(_ goal: Goal) {
        // Build suggested title from goal
        let suggestedTitle: String?
        if let goalTitle = goal.title {
            suggestedTitle = "Progress on: \(goalTitle)"
        } else if let description = goal.detailedDescription {
            let truncated = description.prefix(40)
            suggestedTitle = "Progress on: \(truncated)\(description.count > 40 ? "..." : "")"
        } else {
            suggestedTitle = nil
        }

        // Create new action with pre-filled data
        let action = Action(
            title: suggestedTitle,
            detailedDescription: nil,  // User will fill if needed
            freeformNotes: nil,
            measuresByUnit: nil,       // User will add via form
            durationMinutes: nil,
            startTime: nil,
            logTime: Date(),           // Current time
            id: UUID()                 // New ID
        )

        actionFormState = ActionFormState(action: action, mode: .create)
    }

    /// Duplicate an existing action
    ///
    /// Creates a new action with all fields copied from the source except:
    /// - `id`: New UUID generated
    /// - `logTime`: Set to current time
    /// - `startTime`: Cleared (user can set if needed)
    ///
    /// Opens the ActionFormView pre-filled with the duplicated data.
    private func duplicateAction(_ action: Action) {
        let duplicate = Action(
            title: action.title,
            detailedDescription: action.detailedDescription,
            freeformNotes: action.freeformNotes,
            measuresByUnit: action.measuresByUnit,
            durationMinutes: action.durationMinutes,
            startTime: nil,        // User will set if needed
            logTime: Date(),       // Current time
            id: UUID()             // New ID
        )

        actionFormState = ActionFormState(action: duplicate, mode: .create)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActionsListView()
            .environment(AppViewModel())
    }
}
