// AppViewModel.swift
// Root app state management
//
// Written by Claude Code on 2025-10-19

import SwiftUI
import Database

/// Root application state manager
///
/// Manages database connection and provides it to the entire app via SwiftUI environment.
/// Uses @Observable for automatic view updates (Swift 5.9+).
@Observable
@MainActor
final class AppViewModel {

    // MARK: - Properties

    /// Database manager for all data operations
    private(set) var database: DatabaseManager?

    /// Loading state for app initialization
    private(set) var isInitializing = false

    /// Error state for initialization failures
    private(set) var initializationError: Error?

    // MARK: - Initialization

    /// Initialize database connection
    ///
    /// Called once on app launch via `.task` modifier.
    /// Uses default database configuration (file-based storage).
    func initialize() async {
        guard database == nil else { return } // Already initialized

        isInitializing = true
        defer { isInitializing = false }

        do {
            // Initialize with default configuration (production database)
            database = try await DatabaseManager(configuration: .default)
            initializationError = nil
        } catch {
            initializationError = error
            print("❌ Failed to initialize database: \(error)")
        }
    }

    /// Get database manager (for view models)
    ///
    /// Returns nil if database hasn't been initialized yet.
    var databaseManager: DatabaseManager? {
        database
    }
}
