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

    /// Sheet presentation for term form (create or edit)
    @State private var showingTermForm = false

    /// The term currently being edited (nil = create mode)
    @State private var termToEdit: GoalTerm?

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
                    termToEdit = nil  // Create mode
                    showingTermForm = true
                } label: {
                    Label("Add Term", systemImage: "plus")
                }
                .disabled(viewModel == nil)
            }
        }
        .sheet(isPresented: $showingTermForm) {
            if viewModel != nil {
                TermFormView(
                    term: termToEdit,
                    onSave: { term in
                        Task {
                            if termToEdit != nil {
                                // Edit mode - update existing term
                                await viewModel?.updateTerm(term)
                            } else {
                                // Create mode - create new term
                                await viewModel?.createTerm(term)
                            }
                        }
                        showingTermForm = false
                        termToEdit = nil
                    },
                    onCancel: {
                        showingTermForm = false
                        termToEdit = nil
                    }
                )
                #if os(macOS)
                .frame(minWidth: 600, minHeight: 700)
                #endif
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
                    termToEdit = nil
                    showingTermForm = true
                }
            }
        } else {
            List {
                ForEach(viewModel.terms) { term in
                    TermRowView(term: term)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            termToEdit = term
                            showingTermForm = true
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteTerm(term)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                termToEdit = term
                                showingTermForm = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
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
