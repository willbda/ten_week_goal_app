// GoalsViewModel.swift
// State management for goals list and operations
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Database
import Models

/// View model for goals list and CRUD operations
///
/// Manages state for the goals list view, including loading, creating,
/// updating, and deleting goals. Uses @Observable for automatic view updates.
@Observable
@MainActor
final class GoalsViewModel {

    // MARK: - Properties

    /// Database manager for data operations
    private let database: DatabaseManager

    /// All goals loaded from database
    private(set) var goals: [Goal] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error state
    private(set) var error: Error?

    // MARK: - Initialization

    /// Create view model with database manager
    /// - Parameter database: Database manager for data operations
    init(database: DatabaseManager) {
        self.database = database
    }

    // MARK: - Loading

    /// Load all goals from database
    ///
    /// Fetches all goals and sorts by priority and target date.
    func loadGoals() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch all goals from database
            goals = try await database.fetchGoals()
                .sorted { goal1, goal2 in
                    // Sort by priority first (lower numbers = higher priority)
                    if goal1.priority != goal2.priority {
                        return goal1.priority < goal2.priority
                    }
                    // Then by target date (soonest first)
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
        } catch {
            self.error = error
            print("❌ Failed to load goals: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// Create new goal
    /// - Parameter goal: Goal to create
    func createGoal(_ goal: Goal) async {
        do {
            // Save goal to database
            try await database.saveGoal(goal)

            // Reload to get updated list
            await loadGoals()
        } catch {
            self.error = error
            print("❌ Failed to create goal: \(error)")
        }
    }

    /// Update existing goal
    /// - Parameter goal: Goal to update
    func updateGoal(_ goal: Goal) async {
        do {
            // Save goal to database (saveGoal handles both create and update)
            try await database.saveGoal(goal)

            // Reload to get updated list
            await loadGoals()
        } catch {
            self.error = error
            print("❌ Failed to update goal: \(error)")
        }
    }

    /// Delete goal
    /// - Parameter goal: Goal to delete
    ///
    /// Note: This may need to be implemented when delete functionality
    /// is added to DatabaseManager for goals.
    func deleteGoal(_ goal: Goal) async {
        // TODO: Implement when database delete method is available
        print("⚠️ Delete goal not yet implemented in database")
        self.error = NSError(
            domain: "GoalsViewModel",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "Delete goal functionality not yet implemented"]
        )
    }
}