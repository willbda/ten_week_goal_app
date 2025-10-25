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

    // MARK: - Properties (Reactive Database Query)

    /// Goals from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var goalsQuery: [Goal]

    /// Error state (for CRUD operations)
    private(set) var error: Error?

    // MARK: - Initialization

    /// Create view model
    /// Note: @FetchAll property automatically connects to database via prepareDependencies
    init() {
        // No database parameter needed - @FetchAll uses dependency injection
    }

    // MARK: - Computed Properties

    /// Goals sorted for display
    ///
    /// Sorts goals by:
    /// 1. Target date (soonest first)
    /// 2. Goals with target dates before those without
    /// 3. Log time (most recent first)
    var goals: [Goal] {
        goalsQuery.sorted { goal1, goal2 in
            // Sort by target date (soonest first)
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
            // Finally by log time (most recent first)
            return goal1.logTime > goal2.logTime
        }
    }

    // MARK: - CRUD Operations

    /// Create new goal
    /// - Parameter goal: Goal to create
    func createGoal(_ goal: Goal) async {
        @Dependency(\.defaultDatabase) var database
        do {
            // Insert goal using upsert (handles both create and update)
            try await database.write { db in
                try Goal.upsert { goal }
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to create goal: \(error)")
        }
    }

    /// Update existing goal
    /// - Parameter goal: Goal to update
    func updateGoal(_ goal: Goal) async {
        @Dependency(\.defaultDatabase) var database
        do {
            // Upsert handles both insert and update based on primary key
            try await database.write { db in
                try Goal.upsert { goal }
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to update goal: \(error)")
        }
    }

    /// Delete goal
    /// - Parameter goal: Goal to delete
    func deleteGoal(_ goal: Goal) async {
        @Dependency(\.defaultDatabase) var database
        do {
            // Delete goal from database (static method)
            try await database.write { db in
                try Goal.delete(goal)
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to delete goal: \(error)")
        }
    }
}
