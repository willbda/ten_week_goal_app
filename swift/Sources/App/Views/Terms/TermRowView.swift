// TermRowView.swift
// Individual row component for displaying a term
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// Row view for displaying a single term
///
/// Displays term details including term number, date range, theme, and goal count.
struct TermRowView: View {

    // MARK: - Properties

    let term: GoalTerm

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Term number and name
                HStack {
                    Text("Term \(term.termNumber)")
                        .font(.headline)

                    if let theme = term.theme {
                        Text("• \(theme)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status badge
                    statusBadge
                }

                // Date range
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(dateRangeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Goal count
                if !term.termGoalsByID.isEmpty {
                    HStack {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(term.termGoalsByID.count) goal\(term.termGoalsByID.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var statusBadge: some View {
        Group {
            if isActive {
                Text("ACTIVE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            } else if isUpcoming {
                Text("UPCOMING")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            } else {
                Text("PAST")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private var isActive: Bool {
        let now = Date()
        return term.startDate <= now && now <= term.targetDate
    }

    private var isUpcoming: Bool {
        return term.startDate > Date()
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let start = formatter.string(from: term.startDate)
        let end = formatter.string(from: term.targetDate)

        return "\(start) – \(end)"
    }
}

// MARK: - Preview

#Preview {
    List {
        // Active term
        TermRowView(term: GoalTerm(
            title: "Fall Focus",
            termNumber: 3,
            startDate: Date().addingTimeInterval(-7 * 24 * 3600), // 7 days ago
            targetDate: Date().addingTimeInterval(63 * 24 * 3600), // 63 days from now
            theme: "Health & Career",
            termGoalsByID: [UUID(), UUID(), UUID()]
        ))

        // Upcoming term
        TermRowView(term: GoalTerm(
            title: "Winter Planning",
            termNumber: 4,
            startDate: Date().addingTimeInterval(70 * 24 * 3600), // 70 days from now
            targetDate: Date().addingTimeInterval(140 * 24 * 3600),
            theme: "Relationships",
            termGoalsByID: [UUID()]
        ))

        // Past term
        TermRowView(term: GoalTerm(
            title: "Summer Growth",
            termNumber: 2,
            startDate: Date().addingTimeInterval(-80 * 24 * 3600),
            targetDate: Date().addingTimeInterval(-10 * 24 * 3600),
            termGoalsByID: [UUID(), UUID()]
        ))

        // Simple term without theme
        TermRowView(term: GoalTerm(
            termNumber: 1,
            startDate: Date().addingTimeInterval(-150 * 24 * 3600),
            targetDate: Date().addingTimeInterval(-80 * 24 * 3600),
            termGoalsByID: []
        ))
    }
}
