//
// ActionsListView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: List view for Actions with measurements and goal contributions
// PATTERN: @Fetch with ActionsWithMeasuresAndGoals, tap/swipe interactions
//

import SwiftUI
import Models
import Services
import SQLiteData

/// Main list view for Actions
///
/// **Pattern**: @Fetch with custom FetchKeyRequest (like TermsListView)
/// **Features**:
/// - Displays actions with measurements and goal badges
/// - Tap row to edit
/// - Swipe right to delete
/// - Swipe left to edit
/// - Empty state with CTA
///
/// **Usage**:
/// ```swift
/// NavigationStack {
///     ActionsListView()
/// }
/// ```
public struct ActionsListView: View {
    // MARK: - State

    @Fetch(wrappedValue: [], ActionsWithMeasuresAndGoals())
    private var actions: [ActionWithDetails]

    @State private var showingAddAction = false
    @State private var actionToEdit: ActionWithDetails?
    @State private var actionToDelete: ActionWithDetails?

    // MARK: - Body

    public init() {}

    public var body: some View {
        Group {
            if actions.isEmpty {
                emptyState
            } else {
                actionsList
            }
        }
        .navigationTitle("Actions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAction = true
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAction) {
            NavigationStack {
                ActionFormView()
            }
        }
        .sheet(item: $actionToEdit) { actionDetails in
            NavigationStack {
                ActionFormView(actionToEdit: actionDetails)
            }
        }
        .alert(
            "Delete Action",
            isPresented: .constant(actionToDelete != nil),
            presenting: actionToDelete
        ) { actionDetails in
            Button("Cancel", role: .cancel) {
                actionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                delete(actionDetails)
            }
        } message: { actionDetails in
            Text("Are you sure you want to delete '\(actionDetails.action.title ?? "this action")'?")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Actions Yet", systemImage: "checkmark.circle")
        } description: {
            Text("Track what you've done by adding your first action")
        } actions: {
            Button("Add Action") {
                showingAddAction = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions List

    private var actionsList: some View {
        List {
            ForEach(actions) { actionDetails in
                ActionRowView(actionDetails: actionDetails)
                    .onTapGesture {
                        edit(actionDetails)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            actionToDelete = actionDetails
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            edit(actionDetails)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
    }

    // MARK: - Actions

    private func edit(_ actionDetails: ActionWithDetails) {
        actionToEdit = actionDetails
    }

    private func delete(_ actionDetails: ActionWithDetails) {
        Task {
            // Create temporary ViewModel for delete operation
            let viewModel = ActionFormViewModel()
            do {
                try await viewModel.delete(actionDetails: actionDetails)
                actionToDelete = nil
            } catch {
                // Error handled by ViewModel.errorMessage
                // Could show alert here if needed
                print("Delete error: \(error)")
                actionToDelete = nil
            }
        }
    }
}
