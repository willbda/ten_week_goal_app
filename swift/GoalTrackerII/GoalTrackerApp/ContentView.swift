//
//  ContentView.swift
//  GoalTrackerII
//
//  Created by David Williams on 11/1/25.
//

import SwiftUI
import Models
import SQLiteData

struct ContentView: View {
    @FetchAll var goals: [Goal]
    @FetchAll var expectations: [Expectation]

    var body: some View {
        NavigationStack {
            List {
                if goals.isEmpty {
                    ContentUnavailableView(
                        "No Goals Yet",
                        systemImage: "target",
                        description: Text("Create your first 10-week goal to get started")
                    )
                } else {
                    ForEach(goals, id: \.id) { goal in
                        if let expectation = expectations.first(where: { $0.id == goal.expectationId }) {
                            GoalRow(goal: goal, expectation: expectation)
                        }
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // TODO: Add new goal
                    } label: {
                        Label("Add Goal", systemImage: "plus")
                    }
                }
            }
        }
    }
}

struct GoalRow: View {
    let goal: Goal
    let expectation: Expectation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(expectation.title ?? "Untitled Goal")
                .font(.headline)

            if let description = expectation.detailedDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let startDate = goal.startDate {
                    Label(startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let targetDate = goal.targetDate {
                    Label(targetDate.formatted(date: .abbreviated, time: .omitted), systemImage: "flag")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
