//  DatabaseConfiguration.swift
//  Minimal database configuration
//
//  Written by Claude Code on 2025-10-18
//  Simplified by Claude Code on 2025-10-19
//  Ported from Python implementation (python/config/settings.py)
//
//  Just holds database and schema paths. No filesystem helpers.

import Foundation

/// Minimal database configuration
///
/// Holds two paths: database file and schema directory.
/// DatabaseManager handles all filesystem operations.
public struct DatabaseConfiguration: Sendable {

    // MARK: - Properties

    /// Path to SQLite database file
    public let databasePath: URL

    /// Directory containing SQL schema files
    public let schemaDirectory: URL

    /// Whether this is an in-memory database (for testing)
    public let isInMemory: Bool

    // MARK: - Initialization

    /// Create a configuration with custom paths
    ///
    /// - Parameters:
    ///   - databasePath: Path to SQLite database file
    ///   - schemaDirectory: Directory containing .sql schema files
    ///   - isInMemory: Whether to use in-memory database (testing only)
    public init(
        databasePath: URL,
        schemaDirectory: URL,
        isInMemory: Bool = false
    ) {
        self.databasePath = databasePath
        self.schemaDirectory = schemaDirectory
        self.isInMemory = isInMemory
    }

    // MARK: - Presets

    /// Standard shared database location
    ///
    /// Uses relative paths from Swift package directory:
    /// - Database: `../../shared/database/application_data.db`
    /// - Schemas: `../../shared/schemas/`
    ///
    /// Resolves at compile time using #filePath, so works regardless of
    /// where the project is located on the filesystem.
    public static var `default`: DatabaseConfiguration {
        // Get project root from this source file's location
        // #filePath = ".../ten_week_goal_app/swift/Sources/Database/DatabaseConfiguration.swift"
        // Go up 3 levels: Database -> Sources -> swift -> ten_week_goal_app
        let thisFile = URL(fileURLWithPath: #filePath)
        let projectRoot = thisFile
            .deletingLastPathComponent()  // Remove DatabaseConfiguration.swift
            .deletingLastPathComponent()  // Remove Database/
            .deletingLastPathComponent()  // Remove Sources/
            .deletingLastPathComponent()  // Remove swift/

        return DatabaseConfiguration(
            databasePath: projectRoot
                .appendingPathComponent("shared/database/application_data.db"),
            schemaDirectory: projectRoot
                .appendingPathComponent("shared/schemas"),
            isInMemory: false
        )
    }

    /// In-memory database for testing
    ///
    /// Uses in-memory SQLite database (`:memory:`).
    /// Still loads schemas from shared/schemas/ directory.
    public static var inMemory: DatabaseConfiguration {
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        return DatabaseConfiguration(
            databasePath: URL(fileURLWithPath: ":memory:"),
            schemaDirectory: projectRoot
                .appendingPathComponent("../shared/schemas")
                .standardized,
            isInMemory: true
        )
    }
}
