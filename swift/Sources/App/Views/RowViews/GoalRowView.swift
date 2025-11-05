//
// GoalRowView.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Display row for Goal with multi-metric progress and value alignment
// RECEIVES: GoalWithDetails from parent (no database access here)
// DISPLAYS: Title, dates, progress, value badges, status
//

import Models
import SwiftUI

/// Row view for goal display in lists
///
/// PATTERN: Like TermRowView, receives full data from parent
/// NO DATABASE ACCESS: All data passed via GoalWithDetails
/// DISPLAYS:
/// - Title from Expectation
/// - Date range from Goal
/// - Progress indicator (multi-metric)
/// - Value alignment badges
/// - Status indicator (on track, behind, completed)
public struct GoalRowView: View {
    let goalDetails: GoalWithDetails

    public init(goalDetails: GoalWithDetails) {
        self.goalDetails = goalDetails
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short

        if let start = goalDetails.goal.startDate, let end = goalDetails.goal.targetDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let end = goalDetails.goal.targetDate {
            return "Due \(formatter.string(from: end))"
        } else {
            return "No due date"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and importance/urgency
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goalDetails.expectation.title ?? "Untitled Goal")
                        .font(.headline)

                    if let description = goalDetails.expectation.detailedDescription, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Importance/Urgency badges
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(goalDetails.expectation.expectationImportance)")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)

                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                        Text("\(goalDetails.expectation.expectationUrgency)")
                            .font(.caption)
                    }
                    .foregroundStyle(.red)
                }
            }

            // Progress (if metrics exist)
            if !goalDetails.metricTargets.isEmpty {
                ProgressIndicator(
                    metricTargets: goalDetails.metricTargets,
                    actualProgress: [:],  // TODO: Calculate actual progress in Phase 2
                    displayMode: .compact
                )
            }

            // Value alignments
            if !goalDetails.valueAlignments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(goalDetails.valueAlignments) { alignment in
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                Text(alignment.value.title ?? "Value")
                                    .font(.caption)
                                if let strength = alignment.goalRelevance.alignmentStrength {
                                    Text("(\(strength))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Date range
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("With Metrics and Values") {
    List {
        GoalRowView(
            goalDetails: GoalWithDetails(
                goal: Goal(
                    expectationId: UUID(),
                    startDate: Date(),
                    targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date()),
                    actionPlan: "Run 3x per week"
                ),
                expectation: Expectation(
                    title: "Spring into Running",
                    detailedDescription: "Build running habit and endurance",
                    expectationType: .goal,
                    expectationImportance: 8,
                    expectationUrgency: 5
                ),
                metricTargets: [
                    ExpectationMeasureWithMetric(
                        expectationMeasure: ExpectationMeasure(
                            expectationId: UUID(),
                            measureId: UUID(),
                            targetValue: 120
                        ),
                        measure: Measure(unit: "km", measureType: "distance", title: "Distance")
                    )
                ],
                valueAlignments: [
                    GoalRelevanceWithValue(
                        goalRelevance: GoalRelevance(
                            goalId: UUID(),
                            valueId: UUID(),
                            alignmentStrength: 9
                        ),
                        value: PersonalValue(
                            title: "Health",
                            priority: 10,
                            valueLevel: .major,
                            lifeDomain: "health"
                        )
                    )
                ]
            )
        )
    }
}

#Preview("Minimal Goal") {
    List {
        GoalRowView(
            goalDetails: GoalWithDetails(
                goal: Goal(
                    expectationId: UUID(),
                    startDate: nil,
                    targetDate: Date()
                ),
                expectation: Expectation(
                    title: "Simple Goal",
                    expectationType: .goal,
                    expectationImportance: 5,
                    expectationUrgency: 5
                )
            )
        )
    }
}
