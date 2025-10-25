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

    // MARK: - State

    /// View model for terms management
    @State private var viewModel = TermsViewModel()

    /// Sheet presentation for term form (create or edit)
    @State private var showingTermForm = false

    /// The term currently being edited (nil = create mode)
    @State private var termToEdit: GoalTerm?

    // MARK: - Body

    public var body: some View {
        contentView(viewModel: viewModel)
            .navigationTitle("Terms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        termToEdit = nil  // Create mode
                        showingTermForm = true
                    } label: {
                        Label("Add Term", systemImage: "plus")
                    }
                }
            }
        .sheet(isPresented: $showingTermForm) {
            TermFormView(
                term: termToEdit,
                    onSave: { term, goalIDs in
                        Task {
                            if termToEdit != nil {
                                // Edit mode - update existing term
                                await viewModel.updateTerm(term, goalIDs: goalIDs)
                            } else {
                                // Create mode - create new term
                                await viewModel.createTerm(term, goalIDs: goalIDs)
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

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: TermsViewModel) -> some View {
        if let error = viewModel.error {
            ContentUnavailableView {
                Label("Error Loading Terms", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
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
                    TermRowView(term: term, goalCount: nil)  // TODO: Fetch goal count from database
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
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TermsListView()
    }
}
