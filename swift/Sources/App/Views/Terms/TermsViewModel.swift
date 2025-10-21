// TermsViewModel.swift
// State management for terms list and operations
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Database
import Models

/// View model for terms list and CRUD operations
///
/// Manages state for the terms list view, including loading, creating,
/// updating, and deleting terms. Uses @Observable for automatic view updates.
@Observable
@MainActor
final class TermsViewModel {

    // MARK: - Properties

    /// Database manager for data operations
    private let database: DatabaseManager

    /// All terms loaded from database
    private(set) var terms: [GoalTerm] = []

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

    /// Load all terms from database
    ///
    /// Fetches all terms and sorts by term number (most recent first).
    func loadTerms() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Fetch all terms from database
            terms = try await database.fetchTerms()
                .sorted { $0.termNumber > $1.termNumber }
        } catch {
            self.error = error
            print("❌ Failed to load terms: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// Create new term
    /// - Parameter term: Term to create
    func createTerm(_ term: GoalTerm) async {
        do {
            // Save term to database
            try await database.saveTerm(term)

            // Reload to get updated list
            await loadTerms()
        } catch {
            self.error = error
            print("❌ Failed to create term: \(error)")
        }
    }

    /// Update existing term
    /// - Parameter term: Term to update
    func updateTerm(_ term: GoalTerm) async {
        do {
            // Save term to database
            try await database.saveTerm(term)

            // Reload to get updated list
            await loadTerms()
        } catch {
            self.error = error
            print("❌ Failed to update term: \(error)")
        }
    }

    /// Delete term
    /// - Parameter term: Term to delete
    ///
    /// Deletes term from database with archiving for audit trail.
    func deleteTerm(_ term: GoalTerm) async {
        do {
            // Delete term from database
            try await database.deleteTerm(term)

            // Reload to get updated list
            await loadTerms()
        } catch {
            self.error = error
            print("❌ Failed to delete term: \(error)")
        }
    }
}
