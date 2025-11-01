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

    // MARK: - Properties

    @ObservationIgnored
    @FetchAll
    var actionsQuery: [Action]

    private(set) var error: Error?

    // MARK: - Computed Properties

    /// Actions sorted by log time (most recent first)
    var actions: [Action] {
        actionsQuery.sorted { $0.logTime > $1.logTime }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - CRUD Operations

    func createAction(_ action: Action) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                try Action.upsert { action }
                    .execute(db)
            }
        } catch {
            self.error = error
            print("❌ Failed to create action: \(error)")
        }
    }

    func updateAction(_ action: Action) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                try Action.upsert { action }
                    .execute(db)
            }
        } catch {
            self.error = error
            print("❌ Failed to update action: \(error)")
        }
    }

    func deleteAction(_ action: Action) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                try Action.delete(action)
                    .execute(db)
            }
        } catch {
            self.error = error
            print("❌ Failed to delete action: \(error)")
        }
    }
}
