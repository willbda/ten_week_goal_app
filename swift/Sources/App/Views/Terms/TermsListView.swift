// TermsListView.swift
// Main list view for displaying all terms
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// List view displaying all terms
///
/// Shows terms sorted by term number (most recent first).
/// Supports navigation to detail view and swipe-to-delete.
public struct TermsListView: View {

    // MARK: - Initialization

    public init() {}

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - State

    /// View model for terms management
    @State private var viewModel: TermsViewModel?

    /// Sheet presentation for adding new term
    @State private var showingAddTerm = false

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
        .navigationTitle("Terms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTerm = true
                } label: {
                    Label("Add Term", systemImage: "plus")
                }
                .disabled(viewModel == nil)
            }
        }
        .task {
            // Initialize view model when view appears
            if let database = appViewModel.databaseManager {
                viewModel = TermsViewModel(database: database)
                await viewModel?.loadTerms()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: TermsViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView("Loading terms...")
        } else if let error = viewModel.error {
            ContentUnavailableView {
                Label("Error Loading Terms", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Retry") {
                    Task {
                        await viewModel.loadTerms()
                    }
                }
            }
        } else if viewModel.terms.isEmpty {
            ContentUnavailableView {
                Label("No Terms Yet", systemImage: "calendar")
            } description: {
                Text("Organize your goals by creating your first 10-week term")
            } actions: {
                Button("Add Term") {
                    showingAddTerm = true
                }
            }
        } else {
            List {
                ForEach(viewModel.terms) { term in
                    TermRowView(term: term)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteTerm(term)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .refreshable {
                await viewModel.loadTerms()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TermsListView()
            .environment(AppViewModel())
    }
}
