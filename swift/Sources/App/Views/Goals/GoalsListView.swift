// GoalsListView.swift
// Main list view for displaying all goals
//
// Written by Claude Code on 2025-10-20
// Updated by Claude Code on 2025-10-22 for goal-based quick add

import SwiftUI
import Models
import Database

/// List view displaying all goals
///
/// Shows goals sorted by priority and target date.
/// Supports navigation to detail view and swipe-to-delete (when implemented).
public struct GoalsListView: View {

    // MARK: - Initialization

    public init() {}

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - State

    /// View model for goals management
    @State private var viewModel: GoalsViewModel?

    /// Sheet presentation for adding new goal
    @State private var showingAddGoal = false

    /// Sheet presentation for editing existing goal
    @State private var showingEditGoal = false

    /// The goal currently being edited
    @State private var goalToEdit: Goal?

    /// Sheet presentation for creating action from goal
    @State private var showingActionForm = false

    /// The action being created (pre-filled from goal)
    @State private var actionToCreate: Action?

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
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
                .disabled(viewModel == nil)
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            if viewModel != nil {
                GoalFormView(
                    goal: nil,
                    onSave: { goal in
                        Task {
                            await viewModel?.createGoal(goal)
                            showingAddGoal = false
                        }
                    },
                    onCancel: {
                        showingAddGoal = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingEditGoal) {
            if let goalToEdit = goalToEdit, viewModel != nil {
                GoalFormView(
                    goal: goalToEdit,
                    onSave: { goal in
                        Task {
                            await viewModel?.updateGoal(goal)
                            showingEditGoal = false
                            self.goalToEdit = nil
                        }
                    },
                    onCancel: {
                        showingEditGoal = false
                        self.goalToEdit = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingActionForm) {
            if let actionToCreate = actionToCreate, let database = appViewModel.databaseManager {
                ActionFormView(
                    action: actionToCreate,
                    mode: .create,  // Always creating from goals
                    onSave: { action in
                        Task {
                            // Save action directly to database
                            try? await database.saveAction(action)
                            showingActionForm = false
                            self.actionToCreate = nil
                        }
                    },
                    onCancel: {
                        showingActionForm = false
                        self.actionToCreate = nil
                    }
                )
            }
        }
        .task {
            // Initialize view model when view appears
            if let database = appViewModel.databaseManager {
                viewModel = GoalsViewModel(database: database)
                await viewModel?.loadGoals()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: GoalsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView("Loading goals...")
        } else if let error = viewModel.error {
            ContentUnavailableView {
                Label("Error Loading Goals", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Retry") {
                    Task {
                        await viewModel.loadGoals()
                    }
                }
            }
        } else if viewModel.goals.isEmpty {
            ContentUnavailableView {
                Label("No Goals Yet", systemImage: "target")
            } description: {
                Text("Set your first goal to start tracking your objectives")
            } actions: {
                Button("Add Goal") {
                    showingAddGoal = true
                }
            }
        } else {
            List {
                // Current Goals (not overdue)
                if !currentGoals(from: viewModel.goals).isEmpty {
                    Section("Current Goals") {
                        ForEach(currentGoals(from: viewModel.goals)) { goal in
                            GoalRowView(goal: goal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    goalToEdit = goal
                                    showingEditGoal = true
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        createActionForGoal(goal)
                                    } label: {
                                        Label("Log Action", systemImage: "plus.circle")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteGoal(goal)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                // Overdue Goals
                if !overdueGoals(from: viewModel.goals).isEmpty {
                    Section("Overdue Goals") {
                        ForEach(overdueGoals(from: viewModel.goals)) { goal in
                            GoalRowView(goal: goal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    goalToEdit = goal
                                    showingEditGoal = true
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        createActionForGoal(goal)
                                    } label: {
                                        Label("Log Action", systemImage: "plus.circle")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteGoal(goal)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                // Goals without target dates
                if !goalsWithoutDates(from: viewModel.goals).isEmpty {
                    Section("Open-ended Goals") {
                        ForEach(goalsWithoutDates(from: viewModel.goals)) { goal in
                            GoalRowView(goal: goal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    goalToEdit = goal
                                    showingEditGoal = true
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        createActionForGoal(goal)
                                    } label: {
                                        Label("Log Action", systemImage: "plus.circle")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteGoal(goal)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadGoals()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Goals that are current (not overdue and have target dates)
    private func currentGoals(from goals: [Goal]) -> [Goal] {
        let today = Calendar.current.startOfDay(for: Date())
        return goals.filter { goal in
            guard let targetDate = goal.targetDate else { return false }
            let goalDay = Calendar.current.startOfDay(for: targetDate)
            return goalDay >= today
        }
    }

    /// Goals that are overdue (have target dates in the past)
    private func overdueGoals(from goals: [Goal]) -> [Goal] {
        let today = Calendar.current.startOfDay(for: Date())
        return goals.filter { goal in
            guard let targetDate = goal.targetDate else { return false }
            let goalDay = Calendar.current.startOfDay(for: targetDate)
            return goalDay < today
        }
    }
    
    /// Goals that don't have target dates
    private func goalsWithoutDates(from goals: [Goal]) -> [Goal] {
        goals.filter { $0.targetDate == nil }
    }

    /// Create a new action pre-filled from goal context
    ///
    /// Creates an action with:
    /// - Title suggested from goal description
    /// - Measurement unit from goal (if available)
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

        // Note: We don't pre-fill measurements because the user needs to enter
        // the actual value. The ActionFormView's AddMeasurementSheet will guide them
        // to add measurements with the appropriate unit.

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

        actionToCreate = action
        showingActionForm = true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GoalsListView()
            .environment(AppViewModel())
    }
}