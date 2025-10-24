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

    /// Mapping of action ID → contributing goals
    @State private var actionGoals: [UUID: [Goal]] = [:]

    /// Sheet presentation for bulk matching view
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
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingBulkMatching = true
                } label: {
                    Label("Match to Goals", systemImage: "link.circle")
                }
                .disabled(viewModel == nil)
            }

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
                            // Reload action-goal mappings after save
                            await loadActionGoals()
                        }
                        actionFormState = nil
                    },
                    onCancel: {
                        actionFormState = nil
                    }
                )
            } else {
                // Show loading state while database initializes
                VStack(spacing: DesignSystem.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 400, minHeight: 300)
                .presentationBackground(DesignSystem.Materials.modal)
            }
        }
        .sheet(isPresented: $showingBulkMatching, onDismiss: {
            // Reload action-goal mappings when bulk matching is dismissed
            Task {
                await loadActionGoals()
            }
        }) {
            BulkMatchingView()
        }
        .task {
            // Initialize view model when view appears
            if let database = appViewModel.databaseManager {
                viewModel = ActionsViewModel(database: database)
                await viewModel?.loadActions()
                await loadActiveGoals()
                await loadActionGoals()
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
                    ActionRowView(action: action, goals: actionGoals[action.id] ?? [])
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
                await loadActionGoals()
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
            .sorted { ($0.targetDate ?? Date.distantFuture) < ($1.targetDate ?? Date.distantFuture) }  // Sort by target date
            .prefix(5)
            .map { $0 }
        } catch {
            print("❌ Failed to load active goals: \(error)")
        }
    }

    /// Load action-goal mappings for display
    ///
    /// For each action, fetches its relationships and resolves them to Goal objects.
    /// Populates actionGoals dictionary for display in ActionRowView.
    private func loadActionGoals() async {
        guard let database = appViewModel.databaseManager,
              let viewModel = viewModel else { return }

        do {
            // Fetch all goals once
            let allGoals = try await database.fetchGoals()
            let goalsById = Dictionary(uniqueKeysWithValues: allGoals.map { ($0.id, $0) })

            // Clear previous mappings
            actionGoals.removeAll()

            // For each action, fetch its relationships and resolve to goals
            for action in viewModel.actions {
                let relationships = try await database.fetchRelationships(forAction: action.id)
                let goals = relationships.compactMap { goalsById[$0.goalId] }
                if !goals.isEmpty {
                    actionGoals[action.id] = goals
                }
            }
        } catch {
            print("❌ Failed to load action-goal mappings: \(error)")
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
