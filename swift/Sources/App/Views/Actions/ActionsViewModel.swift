// ActionsViewModel.swift
// State management for actions list and operations
//
// Written by Claude Code on 2025-10-19
// Refactored by Claude Code on 2025-10-24 for SQLiteData @FetchAll

import SwiftUI
import SQLiteData
import Models
import GRDB

/// View model for actions list and CRUD operations
///
/// Manages state for the actions list view, including loading, creating,
/// updating, and deleting actions. Uses @Observable + @FetchAll for automatic
/// reactive database queries.
@Observable
@MainActor
final class ActionsViewModel {

    // MARK: - Properties (Reactive Database Query)

    /// Actions from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var actionsQuery: [Action]

    /// Error state (for CRUD operations)
    private(set) var error: Error?

    // MARK: - Computed Properties

    /// Actions sorted by log time (most recent first)
    var actions: [Action] {
        actionsQuery.sorted { $0.logTime > $1.logTime }
    }

    // MARK: - Initialization

    /// Create view model
    /// Note: @FetchAll property automatically connects to database via prepareDependencies
    init() {
        // No database parameter needed - @FetchAll uses dependency injection
    }

    // MARK: - CRUD Operations

    /// Create new action
    /// - Parameter action: Action to create
    func createAction(_ action: Action) async {
        @Dependency(\.defaultDatabase) var database
        do {
            // Insert action using upsert (handles both create and update)
            try await database.write { db in
                try Action.upsert { action }
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to create action: \(error)")
        }
    }

    /// Update existing action
    /// - Parameter action: Action to update
    func updateAction(_ action: Action) async {
        @Dependency(\.defaultDatabase) var database
        do {
            // Upsert handles both insert and update based on primary key
            try await database.write { db in
                try Action.upsert { action }
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to update action: \(error)")
        }
    }

    /// Delete action
    /// - Parameter action: Action to delete
    ///
    /// Deletes action from database.
    func deleteAction(_ action: Action) async {
        @Dependency(\.defaultDatabase) var database
        do {
            // Delete action from database (static method)
            try await database.write { db in
                try Action.delete(action)
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to delete action: \(error)")
        }
    }
}
