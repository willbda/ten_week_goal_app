// TermRowView.swift
// Individual row component for displaying a term
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// Row view for displaying a single term
///
/// Displays term details including term number, date range, theme, and goal count.
///
/// **Note**: Goal count must be provided by parent view (fetched via DatabaseManager.fetchTermWithGoals)
/// since this synchronous view cannot perform async database queries.
struct TermRowView: View {

    // MARK: - Properties

    let term: GoalTerm
    let goalCount: Int?  // Optional: number of goals assigned to this term

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Term number and name
                HStack {
                    Text("Term \(term.termNumber)")
                        .font(DesignSystem.Typography.headline)

                    if let theme = term.theme {
                        Text("• \(theme)")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status badge
                    statusBadge
                }

                // Date range
                HStack {
                    Image(systemName: "calendar")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text(dateRangeText)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Goal count (if provided)
                if let count = goalCount, count > 0 {
                    HStack {
                        Image(systemName: "target")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)

                        Text("\(count) goal\(count == 1 ? "" : "s")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }

    // MARK: - Helpers

    private var statusBadge: some View {
        Group {
            if isActive {
                Text("ACTIVE")
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.xs - 2)
                    .padding(.vertical, DesignSystem.Spacing.xxs - 2)
                    .background(DesignSystem.Colors.success)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            } else if isUpcoming {
                Text("UPCOMING")
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.xs - 2)
                    .padding(.vertical, DesignSystem.Spacing.xxs - 2)
                    .background(DesignSystem.Colors.info)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            } else {
                Text("PAST")
                    .font(DesignSystem.Typography.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.xs - 2)
                    .padding(.vertical, DesignSystem.Spacing.xxs - 2)
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
        // Active term with goals
        TermRowView(
            term: GoalTerm(
                title: "Fall Focus",
                termNumber: 3,
                startDate: Date().addingTimeInterval(-7 * 24 * 3600), // 7 days ago
                targetDate: Date().addingTimeInterval(63 * 24 * 3600), // 63 days from now
                theme: "Health & Career"
            ),
            goalCount: 3
        )

        // Upcoming term with one goal
        TermRowView(
            term: GoalTerm(
                title: "Winter Planning",
                termNumber: 4,
                startDate: Date().addingTimeInterval(70 * 24 * 3600), // 70 days from now
                targetDate: Date().addingTimeInterval(140 * 24 * 3600),
                theme: "Relationships"
            ),
            goalCount: 1
        )

        // Past term with goals
        TermRowView(
            term: GoalTerm(
                title: "Summer Growth",
                termNumber: 2,
                startDate: Date().addingTimeInterval(-80 * 24 * 3600),
                targetDate: Date().addingTimeInterval(-10 * 24 * 3600)
            ),
            goalCount: 2
        )

        // Simple term without goals
        TermRowView(
            term: GoalTerm(
                termNumber: 1,
                startDate: Date().addingTimeInterval(-150 * 24 * 3600),
                targetDate: Date().addingTimeInterval(-80 * 24 * 3600)
            ),
            goalCount: 0
        )
    }
}
