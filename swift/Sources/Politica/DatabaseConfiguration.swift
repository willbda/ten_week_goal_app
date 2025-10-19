//  DatabaseConfiguration.swift
//  Database configuration and path management
//
//  Written by Claude Code on 2025-10-18
//  Ported from Python implementation (python/config/settings.py)
//
//  Provides database and schema paths for DatabaseManager initialization.
//  Supports both file-based and in-memory databases for testing.

import Foundation

/// Configuration for database operations
///
/// Manages paths to database file and SQL schema files.
/// Ensures compatibility with Python implementation by using same database location.
public struct DatabaseConfiguration: Sendable {

    // MARK: - Properties

    /// Path to SQLite database file
    /// This ensures Swift and Python implementations can read/write the same data.
    public let databasePath: URL

    /// Directory containing SQL schema files
    /// Schema files are executed in alphabetical order during initialization.
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

    /// Create default configuration
    ///
    /// Uses standard project paths:
    /// - Database: `../shared/database/application_data.db`
    /// - Schemas: `../shared/schemas/`
    ///
    /// Resolves paths relative to the Swift project root.
    public static var `default`: DatabaseConfiguration {
        // Get path to Swift project root
        // Assumes we're running from: ten_week_goal_app/swift/
        let swiftRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Remove DatabaseConfiguration.swift
            .deletingLastPathComponent()  // Remove Politica/
            .deletingLastPathComponent()  // Remove Sources/

        // Navigate to Python database location
        let pythonRoot = swiftRoot.deletingLastPathComponent().appendingPathComponent("python")
        let databasePath = pythonRoot
            .appendingPathComponent("politica")
            .appendingPathComponent("data_storage")
            .appendingPathComponent("application_data.db")

        // Navigate to shared schemas location
        let sharedRoot = swiftRoot.deletingLastPathComponent().appendingPathComponent("shared")
        let schemaDirectory = sharedRoot.appendingPathComponent("schemas")

        return DatabaseConfiguration(
            databasePath: databasePath,
            schemaDirectory: schemaDirectory,
            isInMemory: false
        )
    }

    /// Create in-memory configuration for testing
    ///
    /// Uses in-memory SQLite database (`:memory:`).
    /// Still loads schemas from shared/schemas/ directory.
    public static var inMemory: DatabaseConfiguration {
        let defaultConfig = DatabaseConfiguration.default

        // In-memory database uses special `:memory:` path
        let memoryPath = URL(fileURLWithPath: ":memory:")

        return DatabaseConfiguration(
            databasePath: memoryPath,
            schemaDirectory: defaultConfig.schemaDirectory,
            isInMemory: true
        )
    }

    // MARK: - Helper Methods

    /// Ensure database directory exists
    ///
    /// Creates parent directory for database file if it doesn't exist.
    /// Skipped for in-memory databases.
    ///
    /// - Throws: FileManager errors if directory cannot be created
    public func ensureDatabaseDirectoryExists() throws {
        guard !isInMemory else { return }

        let directory = databasePath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    /// Check if database file exists
    ///
    /// - Returns: true if database file exists on disk, false otherwise
    ///            Always returns false for in-memory databases
    public var databaseExists: Bool {
        guard !isInMemory else { return false }
        return FileManager.default.fileExists(atPath: databasePath.path)
    }

    /// Get list of SQL schema files
    ///
    /// Returns all `.sql` files from schema directory in alphabetical order.
    ///
    /// - Returns: Array of URLs pointing to .sql files
    /// - Throws: FileManager errors if schema directory doesn't exist
    public func getSchemaFiles() throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: schemaDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return contents
            .filter { $0.pathExtension == "sql" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
