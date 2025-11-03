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
    @State private var showingAddTerm = false

    // Query GoalTerms with TimePeriods via JOIN (single query)
    @Fetch(wrappedValue: [], TermsWithPeriods())
    private var termsWithPeriods: [TermWithPeriod]

    public var body: some View {
        List(termsWithPeriods) { item in
            TermRowView(term: item.term, timePeriod: item.timePeriod)
        }
        .navigationTitle("Terms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTerm = true
                } label: {
                    Label("Add Term", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTerm) {
            NavigationStack {
                TermFormView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TermsListView()
    }
}