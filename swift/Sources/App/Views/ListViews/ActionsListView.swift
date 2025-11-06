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
/// - Quick Add section (duplicate recent actions, log for active goals)
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

    @Fetch(wrappedValue: [], ActiveGoals())
    private var activeGoals: [GoalWithDetails]

    @State private var showingAddAction = false
    @State private var actionToEdit: ActionWithDetails?
    @State private var actionToDelete: ActionWithDetails?
    @State private var selectedAction: ActionWithDetails?
    @State private var formData: ActionFormData?  // For Quick Add pre-filling
    @State private var refreshID = UUID()  // Force refresh after edits/deletes

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
        .id(refreshID)  // Force re-render when refreshID changes
        .navigationTitle("Actions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAction = true
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingAddAction) {
            NavigationStack {
                if let data = formData {
                    // Quick Add mode (pre-filled from duplicate or goal)
                    ActionFormView(initialData: data)
                } else {
                    // Create mode (empty form)
                    ActionFormView()
                }
            }
        }
        .onChange(of: showingAddAction) { _, isShowing in
            // Clear formData when sheet is dismissed
            if !isShowing {
                formData = nil
                refreshID = UUID()  // Refresh list after creating action
            }
        }
        .sheet(item: $actionToEdit) { actionDetails in
            NavigationStack {
                ActionFormView(actionToEdit: actionDetails)
            }
        }
        .onChange(of: actionToEdit) { oldValue, newValue in
            // Refresh list when edit sheet is dismissed
            if newValue == nil && oldValue != nil {
                refreshID = UUID()
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
        List(selection: $selectedAction) {
            // Quick Add Section
            QuickAddSection(
                recentActions: Array(actions.prefix(5)),
                activeGoals: Array(activeGoals.prefix(5)),
                onDuplicateAction: { preFilledData in
                    formData = preFilledData
                    showingAddAction = true
                },
                onLogActionForGoal: { goalDetail in
                    // Pre-fill form with goal's first metric
                    formData = buildFormDataForGoal(goalDetail)
                    showingAddAction = true
                }
            )

            // Actions List
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
                    // Context menu for mouse/trackpad users
                    .contextMenu {
                        Button {
                            edit(actionDetails)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            actionToDelete = actionDetails
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .tag(actionDetails)
            }
        }
        #if os(macOS)
        .onDeleteCommand {
            if let selected = selectedAction {
                actionToDelete = selected
            }
        }
        #endif
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
                refreshID = UUID()  // Refresh list after delete
            } catch {
                // Error handled by ViewModel.errorMessage
                // Could show alert here if needed
                print("Delete error: \(error)")
                actionToDelete = nil
            }
        }
    }

    // MARK: - Quick Add Helpers

    /// Build ActionFormData for logging action toward a goal
    ///
    /// Pre-fills form with goal's first metric target (if any)
    /// and pre-selects the goal for contribution tracking
    private func buildFormDataForGoal(_ goalDetail: GoalWithDetails) -> ActionFormData {
        // Pre-fill with goal's first metric (if any)
        let measurements: [MeasurementInput] = goalDetail.metricTargets.prefix(1).map { target in
            MeasurementInput(
                measureId: target.measure.id,
                value: 0  // User will enter actual value
            )
        }

        return ActionFormData(
            title: "",  // User will enter title
            measurements: measurements,
            goalContributions: [goalDetail.goal.id]  // Pre-select this goal
        )
    }
}
