//
// TermsListView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: List view showing Terms with their TimePeriod details
// ARCHITECTURE: JOIN query for efficient single-query fetch
//

import Models
import SQLiteData
import SwiftUI

/// List view for Terms (10-week planning periods).
///
/// ARCHITECTURE DECISION: JOIN Query for Performance
/// - Uses custom TermsWithPeriods query that JOINs GoalTerm + TimePeriod
/// - Single query instead of N+1 fetches (performant)
/// - Observable via @Fetch - auto-updates on database changes
/// - User sees "Terms" in navigation title, not "Time Periods"
///
/// PATTERN: Based on SQLiteData Reminders app JOIN pattern
/// - @Fetch with custom FetchRequest (not @FetchAll)
/// - Navigation + sheet for create
/// - No ViewModel needed (simple list)
/// - TermRowView receives both models directly
public struct TermsListView: View {
    @State private var showingForm = false
    @State private var viewModel = TimePeriodFormViewModel()

    // Query GoalTerms with TimePeriods via JOIN (single query)
    @Fetch(wrappedValue: [], TermsWithPeriods())
    private var termsWithPeriods: [TermWithPeriod]

    /// Term being edited (nil = create mode)
    @State private var termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)?

    /// Selected term for keyboard navigation
    @State private var selectedTerm: TermWithPeriod?

    /// Term to delete (for confirmation)
    @State private var termToDelete: TermWithPeriod?

    public var body: some View {
        Group {
            if termsWithPeriods.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("No Terms Yet", systemImage: "calendar")
                } description: {
                    Text("Organize your goals by creating your first 10-week term")
                } actions: {
                    Button("Add Term") {
                        termToEdit = nil
                        showingForm = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(selection: $selectedTerm) {
                    ForEach(termsWithPeriods) { item in
                        TermRowView(term: item.term, timePeriod: item.timePeriod)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Tap row → edit
                                termToEdit = (item.timePeriod, item.term)
                                showingForm = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    termToDelete = item
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    // Swipe left → edit
                                    termToEdit = (item.timePeriod, item.term)
                                    showingForm = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            // Context menu for mouse/trackpad users
                            .contextMenu {
                                Button {
                                    termToEdit = (item.timePeriod, item.term)
                                    showingForm = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    termToDelete = item
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .tag(item)
                    }
                }
                #if os(macOS)
                .onDeleteCommand {
                    if let selected = selectedTerm {
                        termToDelete = selected
                    }
                }
                #endif
            }
        }
        .navigationTitle("Terms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    termToEdit = nil  // Create mode
                    showingForm = true
                } label: {
                    Label("Add Term", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingForm) {
            NavigationStack {
                TermFormView(termToEdit: termToEdit)
            }
        }
        .alert(
            "Delete Term",
            isPresented: .constant(termToDelete != nil),
            presenting: termToDelete
        ) { item in
            Button("Cancel", role: .cancel) {
                termToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.delete(
                        timePeriod: item.timePeriod,
                        goalTerm: item.term
                    )
                    termToDelete = nil
                }
            }
        } message: { item in
            Text("Are you sure you want to delete Term \(item.term.termNumber)?")
        }
    }
}

#Preview {
    NavigationStack {
        TermsListView()
    }
}