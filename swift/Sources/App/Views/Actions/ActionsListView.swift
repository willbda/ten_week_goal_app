// ActionsListView.swift
// Main list view for displaying all actions
//
// Written by Claude Code on 2025-10-19

import SwiftUI
import Models

/// List view displaying all actions
///
/// Shows actions sorted by log time (most recent first).
/// Supports navigation to detail view and swipe-to-delete.
public struct ActionsListView: View {

    // MARK: - Initialization

    public init() {}

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - State

    /// View model for actions management
    @State private var viewModel: ActionsViewModel?

    /// Sheet presentation for adding new action
    @State private var showingAddAction = false

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
                    showingAddAction = true
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
                .disabled(viewModel == nil)
            }
        }
        .task {
            // Initialize view model when view appears
            if let database = appViewModel.databaseManager {
                viewModel = ActionsViewModel(database: database)
                await viewModel?.loadActions()
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
                    showingAddAction = true
                }
            }
        } else {
            List {
                ForEach(viewModel.actions) { action in
                    ActionRowView(action: action)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteAction(action)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .refreshable {
                await viewModel.loadActions()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActionsListView()
            .environment(AppViewModel())
    }
}
