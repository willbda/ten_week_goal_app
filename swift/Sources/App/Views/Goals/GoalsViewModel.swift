// GoalsViewModel.swift
// State management for goals list and operations
//
// Written by Claude Code on 2025-10-20
// Refactored by Claude Code on 2025-10-24 for SQLiteData @FetchAll

import SwiftUI
import SQLiteData
import Models
import GRDB

/// View model for goals list and CRUD operations
///
/// Manages state for the goals list view, including loading, creating,
/// updating, and deleting goals. Uses @Observable + @FetchAll for automatic
/// reactive database queries.
@Observable
@MainActor
final class GoalsViewModel {

    // MARK: - Properties

    @ObservationIgnored
    @FetchAll
    var goalsQuery: [Goal]

    private(set) var error: Error?

    // MARK: - Initialization

    init() {}

    // MARK: - Computed Properties

    /// Goals sorted by target date, then log time
    var goals: [Goal] {
        goalsQuery.sorted { goal1, goal2 in
            if let date1 = goal1.targetDate, let date2 = goal2.targetDate {
                return date1 < date2
            }
            // Goals with target dates come before those without
            if goal1.targetDate != nil && goal2.targetDate == nil {
                return true
            }
            if goal1.targetDate == nil && goal2.targetDate != nil {
                return false
            }
            return goal1.logTime > goal2.logTime
        }
    }

    // MARK: - CRUD Operations

    func createGoal(_ goal: Goal) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                try Goal.upsert { goal }
                    .execute(db)
            }
        } catch {
            self.error = error
            print("❌ Failed to create goal: \(error)")
        }
    }

    func updateGoal(_ goal: Goal) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                try Goal.upsert { goal }
                    .execute(db)
            }
        } catch {
            self.error = error
            print("❌ Failed to update goal: \(error)")
        }
    }

    func deleteGoal(_ goal: Goal) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                try Goal.delete(goal)
                    .execute(db)
            }
        } catch {
            self.error = error
            print("❌ Failed to delete goal: \(error)")
        }
    }
}
