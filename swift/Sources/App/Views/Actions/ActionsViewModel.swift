// ActionsViewModel.swift
// State management for actions list and operations
//
// Written by Claude Code on 2025-10-19

import SwiftUI

import Models

/// View model for actions list and CRUD operations
///
/// Manages state for the actions list view, including loading, creating,
/// updating, and deleting actions. Uses @Observable for automatic view updates.
@Observable
@MainActor
final class ActionsViewModel {

    // MARK: - Properties

    /// Database manager for data operations
    private let database: DatabaseManager

    /// All actions loaded from database
    private(set) var actions: [Action] = []

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

    /// Load all actions from database
    ///
    /// Fetches all actions and sorts by log time (most recent first).
    func loadActions() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch all actions from database
            actions = try await database.fetchActions()
                                .sorted { $0.logTime > $1.logTime }
        } catch {
            self.error = error
            print("❌ Failed to load actions: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// Create new action
    /// - Parameter action: Action to create
    func createAction(_ action: Action) async {
        do {
            // Save action to database
            try await database.saveAction(action)

            // Reload to get updated list
            await loadActions()
        } catch {
            self.error = error
            print("❌ Failed to create action: \(error)")
        }
    }

    /// Update existing action
    /// - Parameter action: Action to update
    func updateAction(_ action: Action) async {
        do {
            // Save action to database (saveAction handles both create and update)
            try await database.saveAction(action)

            // Reload to get updated list
            await loadActions()
        } catch {
            self.error = error
            print("❌ Failed to update action: \(error)")
        }
    }

    /// Delete action
    /// - Parameter action: Action to delete
    ///
    /// Deletes action from database with archiving for audit trail.
    /// Uses UUID→Int64 mapping to find database record.
    func deleteAction(_ action: Action) async {
        do {
            // Delete action from database
            try await database.deleteAction(action)

            // Reload to get updated list
            await loadActions()
        } catch {
            self.error = error
            print("❌ Failed to delete action: \(error)")
        }
    }
}
