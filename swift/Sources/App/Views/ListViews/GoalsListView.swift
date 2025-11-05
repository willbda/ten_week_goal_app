//
// GoalsListView.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: List of goals with progress and alignment display
// DATA SOURCE: @Fetch(GoalsQuery())
// INTERACTIONS: Tap to edit, swipe to delete, empty state
//

import Models
import SQLiteData
import SwiftUI

/// List view for goals
///
/// PATTERN: Like TermsListView, ActionsListView
/// DATA: @Fetch with GoalsQuery (reactive updates)
/// DISPLAY: GoalRowView for each goal
/// INTERACTIONS: Tap to edit, swipe to delete
public struct GoalsListView: View {
    @Fetch(wrappedValue: [], GoalsQuery())
    private var goals: [GoalWithDetails]

    @State private var showingAddGoal = false
    @State private var goalToEdit: GoalWithDetails?
    @State private var goalToDelete: GoalWithDetails?
    @State private var showingDeleteAlert = false

    public init() {}

    public var body: some View {
        Group {
            if goals.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("No Goals Yet", systemImage: "target")
                } description: {
                    Text("Set your first goal to start tracking progress")
                } actions: {
                    Button("Add Goal") {
                        showingAddGoal = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // Goal list
                List {
                    ForEach(goals) { goalDetails in
                        GoalRowView(goalDetails: goalDetails)
                            .onTapGesture {
                                goalToEdit = goalDetails
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    goalToDelete = goalDetails
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    goalToEdit = goalDetails
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
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
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            NavigationStack {
                GoalFormView()
            }
        }
        .sheet(item: $goalToEdit) { goalDetails in
            NavigationStack {
                GoalFormView(goalToEdit: goalDetails)
            }
        }
        .alert("Delete Goal?", isPresented: $showingDeleteAlert, presenting: goalToDelete) { goalDetails in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteGoal(goalDetails)
            }
        } message: { goalDetails in
            Text("Are you sure you want to delete \"\(goalDetails.expectation.title ?? "this goal")\"?")
        }
    }

    private func deleteGoal(_ goalDetails: GoalWithDetails) {
        Task {
            let viewModel = GoalFormViewModel()
            try? await viewModel.delete(goalDetails: goalDetails)
        }
    }
}
