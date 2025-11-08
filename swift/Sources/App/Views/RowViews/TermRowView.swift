//
// TermRowView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Row display for Term with TimePeriod details
// ARCHITECTURE: Clean display view - receives both models from parent JOIN query
//

import Models
import SwiftUI

/// Row view for displaying a Term with TimePeriod details.
///
/// ARCHITECTURE DECISION: Receive Both Models (No Fetching)
/// - Accepts GoalTerm + TimePeriod directly from parent's JOIN query
/// - No N+1 queries - parent fetches both in single JOIN
/// - Pure display logic - no database access
/// - Displays term number, title, and dates
///
/// PATTERN: Based on PersonalValuesRowView
/// - Simple display, no business logic
/// - BadgeView for term number
/// - Shows TimePeriod title and date range
public struct TermRowView: View {
    let term: GoalTerm
    let timePeriod: TimePeriod

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Term-specific: termNumber badge
                BadgeView(badge: Badge(text: "Term \(term.termNumber)", color: .blue))

                // Generic: TimePeriod title or fallback
                Text(timePeriod.title ?? "Term \(term.termNumber)")
                    .font(.headline)

                // Generic: TimePeriod dates
                Text("\(timePeriod.startDate.formatted(date: .abbreviated, time: .omitted)) - \(timePeriod.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let sampleTerm = GoalTerm(
        timePeriodId: UUID(),
        termNumber: 5,
        theme: "Health & Growth",
        status: .active
    )
    let samplePeriod = TimePeriod(
        title: "Spring Term",
        detailedDescription: "Focus on health and relationships",
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 24 * 70) // 10 weeks
    )

    return List {
        TermRowView(term: sampleTerm, timePeriod: samplePeriod)
    }
}