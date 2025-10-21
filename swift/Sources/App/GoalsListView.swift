// GoalsListView.swift
// Main list view for displaying all goals
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

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
        goals.filter { goal in
            guard let targetDate = goal.targetDate else { return false }
            return targetDate >= Date()
        }
    }
    
    /// Goals that are overdue (have target dates in the past)
    private func overdueGoals(from goals: [Goal]) -> [Goal] {
        goals.filter { goal in
            guard let targetDate = goal.targetDate else { return false }
            return targetDate < Date()
        }
    }
    
    /// Goals that don't have target dates
    private func goalsWithoutDates(from goals: [Goal]) -> [Goal] {
        goals.filter { $0.targetDate == nil }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GoalsListView()
            .environment(AppViewModel())
    }
}