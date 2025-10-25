// TermsViewModel.swift
// State management for terms list and operations
//
// Written by Claude Code on 2025-10-20
// Refactored by Claude Code on 2025-10-24 for SQLiteData @FetchAll

import SwiftUI
import SQLiteData
import Models
import GRDB

/// View model for terms list and CRUD operations
///
/// Manages state for the terms list view, including loading, creating,
/// updating, and deleting terms. Uses @Observable + @FetchAll for automatic
/// reactive database queries.
@Observable
@MainActor
final class TermsViewModel {

    // MARK: - Properties (Reactive Database Query)

    /// Terms from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var termsQuery: [GoalTerm]

    /// Error state (for CRUD operations)
    private(set) var error: Error?

    // MARK: - Computed Properties

    /// Terms sorted by term number (most recent first)
    var terms: [GoalTerm] {
        termsQuery.sorted { $0.termNumber > $1.termNumber }
    }

    // MARK: - Initialization

    /// Create view model
    /// Note: @FetchAll property automatically connects to database via prepareDependencies
    init() {
        // No database parameter needed - @FetchAll uses @Dependency(\.defaultDatabase)
    }

    // MARK: - CRUD Operations

    /// Create new term with goal assignments
    /// - Parameters:
    ///   - term: Term to create
    ///   - goalIDs: Set of goal UUIDs to assign to this term
    func createTerm(_ term: GoalTerm, goalIDs: Set<UUID>) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                // Insert term using upsert
                try GoalTerm.upsert { term }
                    .execute(db)

                // Create junction table assignments for each goal
                for (index, goalID) in goalIDs.enumerated() {
                    let assignment = TermGoalAssignment(
                        termUUID: term.id,
                        goalUUID: goalID,
                        assignmentOrder: index
                    )
                    try TermGoalAssignment.insert { assignment }
                        .execute(db)
                }
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to create term: \(error)")
        }
    }

    /// Update existing term and goal assignments
    /// - Parameters:
    ///   - term: Term to update
    ///   - goalIDs: Set of goal UUIDs to assign to this term (replaces existing assignments)
    func updateTerm(_ term: GoalTerm, goalIDs: Set<UUID>) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                // Upsert term
                try GoalTerm.upsert { term }
                    .execute(db)

                // Remove existing assignments
                try db.execute(
                    sql: "DELETE FROM term_goal_assignments WHERE term_id = ?",
                    arguments: [term.id.uuidString]
                )

                // Create new assignments
                for (index, goalID) in goalIDs.enumerated() {
                    let assignment = TermGoalAssignment(
                        termUUID: term.id,
                        goalUUID: goalID,
                        assignmentOrder: index
                    )
                    try TermGoalAssignment.insert { assignment }
                        .execute(db)
                }
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to update term: \(error)")
        }
    }

    /// Delete term
    /// - Parameter term: Term to delete
    ///
    /// Deletes term from database.
    func deleteTerm(_ term: GoalTerm) async {
        @Dependency(\.defaultDatabase) var database
        do {
            try await database.write { db in
                // Delete term from database (static method, junction table records cascade)
                try GoalTerm.delete(term)
                    .execute(db)
            }
            // @FetchAll automatically refreshes
        } catch {
            self.error = error
            print("❌ Failed to delete term: \(error)")
        }
    }
}
