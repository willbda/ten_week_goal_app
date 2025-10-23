// GoalRowView.swift
// Individual row component for displaying a goal
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// Row view for displaying a single goal
///
/// Displays goal details including name, measurement target, target date, and priority.
struct GoalRowView: View {

    // MARK: - Properties

    let goal: Goal

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Goal name with priority indicator
                HStack {
                    Text(goal.title ?? "Untitled Goal")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Priority badge
                    if goal.priority <= 10 {
                        Text("HIGH")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    } else if goal.priority <= 30 {
                        Text("MED")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                
                // Measurement target
                if let unit = goal.measurementUnit, let target = goal.measurementTarget {
                    Text("Target: \(target, specifier: "%.1f") \(unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Target date and progress
                HStack {
                    if let targetDate = goal.targetDate {
                        let isOverdue = Calendar.current.startOfDay(for: targetDate) < Calendar.current.startOfDay(for: Date())

                        Label {
                            Text(targetDate, style: .date)
                        } icon: {
                            Image(systemName: isOverdue ? "clock.badge.exclamationmark" : "clock")
                                .foregroundStyle(isOverdue ? .red : .secondary)
                        }
                        .font(.caption)
                        .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    // Life domain tag
                    if let domain = goal.lifeDomain {
                        Text(domain)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    List {
        GoalRowView(goal: Goal(
            title: "Run 120km in 10 weeks",
            detailedDescription: "Complete running goal for fitness",
            measurementUnit: "km",
            measurementTarget: 120.0,
            startDate: Date(),
            targetDate: Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date()),
            howGoalIsRelevant: "Improve cardiovascular health",
            howGoalIsActionable: "Run 3-4 times per week",
            expectedTermLength: 10,
            priority: 5,
            lifeDomain: "Health"
        ))

        GoalRowView(goal: Goal(
            title: "Learn Swift",
            detailedDescription: "Master iOS development",
            measurementUnit: "hours",
            measurementTarget: 100.0,
            targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            priority: 15,
            lifeDomain: "Career"
        ))

        GoalRowView(goal: Goal(
            title: "Get healthier",
            detailedDescription: "General wellness improvement",
            priority: 25
        ))

        // Overdue goal
        GoalRowView(goal: Goal(
            title: "Overdue goal",
            measurementUnit: "tasks",
            measurementTarget: 5.0,
            targetDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            priority: 8,
            lifeDomain: "Work"
        ))
    }
}