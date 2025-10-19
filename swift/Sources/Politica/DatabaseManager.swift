//  DatabaseManager.swift
//  Actor-based database operations using GRDB native types
//
//  Written by Claude Code on 2025-10-18
//  Refactored on 2025-10-18 to use GRDB's Codable integration
//  Ported from Python implementation (python/politica/database.py)
//
//  This actor provides type-safe database operations using GRDB's
//  FetchableRecord and PersistableRecord protocols. Works with domain
//  entities directly via Codable serialization.
//
//  Uses Swift 6.2 actor isolation for thread-safe database access.

import Foundation
import GRDB
import Models

/// Thread-safe database operations manager
///
/// DatabaseManager is an actor that serializes all database operations,
/// preventing race conditions. All operations are async and type-safe.
///
/// **Pattern**: Uses GRDB's Codable integration for direct entity mapping
///
/// Example:
/// ```swift
/// let db = try await DatabaseManager()
///
/// // Fetch all actions
/// let actions: [Action] = try await db.fetchAll()
///
/// // Save an action
/// var action = Action(friendlyName: "Run")
/// try await db.save(&action)
///
/// // Fetch by ID
/// if let action = try await db.fetchOne(Action.self, id: someUUID) {
///     print(action.friendlyName ?? "")
/// }
/// ```
public actor DatabaseManager {

    // MARK: - Properties

    /// GRDB database pool for connection management
    private let dbPool: DatabasePool

    /// Configuration used to initialize this manager
    public let configuration: DatabaseConfiguration

    // MARK: - Initialization

    /// Initialize database manager with configuration
    ///
    /// Creates or opens database file, initializes schema if needed.
    ///
    /// - Parameter configuration: Database and schema paths
    /// - Throws: DatabaseError if initialization fails
    public init(configuration: DatabaseConfiguration = .default) async throws {
        self.configuration = configuration

        // Ensure database directory exists (skip for in-memory)
        try configuration.ensureDatabaseDirectoryExists()

        // Create database pool (not async in GRDB)
        if configuration.isInMemory {
            // In-memory database for testing
            // GRDB uses ":memory:" special path for in-memory databases
            self.dbPool = try DatabasePool(path: ":memory:")
        } else {
            // File-based database for production
            self.dbPool = try DatabasePool(path: configuration.databasePath.path)
        }

        // Initialize schema if database is new
        if !configuration.databaseExists || configuration.isInMemory {
            try await initializeSchema()
        }
    }

    // MARK: - Schema Management

    /// Initialize database schema from SQL files
    ///
    /// Loads all .sql files from schema directory and executes them in order.
    /// This is idempotent - safe to run multiple times (uses IF NOT EXISTS).
    ///
    /// - Throws: DatabaseError.schemaInitializationFailed
    private func initializeSchema() async throws {
        let schemaFiles = try configuration.getSchemaFiles()

        guard !schemaFiles.isEmpty else {
            throw DatabaseError.schemaInitializationFailed(
                schemaFile: "none",
                error: NSError(domain: "DatabaseManager", code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "No schema files found"])
            )
        }

        try await dbPool.write { db in
            for schemaFile in schemaFiles {
                do {
                    let sql = try String(contentsOf: schemaFile, encoding: .utf8)
                    try db.execute(sql: sql)
                } catch {
                    throw DatabaseError.schemaInitializationFailed(
                        schemaFile: schemaFile.lastPathComponent,
                        error: error
                    )
                }
            }
        }
    }

    // MARK: - Fetch Operations

    /// Fetch all records of a given type
    ///
    /// - Parameter type: The record type to fetch (e.g., Action.self)
    /// - Returns: Array of records
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let actions: [Action] = try await db.fetchAll()
    /// ```
    public func fetchAll<T: FetchableRecord & TableRecord & Sendable>() async throws -> [T] {
        do {
            return try await dbPool.read { db in
                try T.fetchAll(db)
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM \(T.databaseTableName)",
                error: error
            )
        }
    }

    /// Fetch records with custom SQL
    ///
    /// - Parameters:
    ///   - type: The record type to fetch
    ///   - sql: Custom SQL query
    ///   - arguments: Query arguments (Sendable types only)
    /// - Returns: Array of records
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let actions: [Action] = try await db.fetch(
    ///     Action.self,
    ///     sql: "SELECT * FROM actions WHERE friendly_name LIKE ?",
    ///     arguments: ["%run%"]
    /// )
    /// ```
    public func fetch<T: FetchableRecord & Sendable>(
        _ type: T.Type,
        sql: String,
        arguments: [any DatabaseValueConvertible & Sendable] = []
    ) async throws -> [T] {
        do {
            return try await dbPool.read { db in
                try T.fetchAll(db, sql: sql, arguments: StatementArguments(arguments))
            }
        } catch {
            throw DatabaseError.queryFailed(sql: sql, error: error)
        }
    }

    /// Fetch a single record by ID
    ///
    /// - Parameters:
    ///   - type: The record type to fetch
    ///   - id: UUID of the record
    /// - Returns: The record if found, nil otherwise
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// if let action = try await db.fetchOne(Action.self, id: someUUID) {
    ///     print(action.friendlyName ?? "")
    /// }
    /// ```
    public func fetchOne<T: FetchableRecord & TableRecord & Sendable>(
        _ type: T.Type,
        id: UUID
    ) async throws -> T? {
        do {
            return try await dbPool.read { db in
                try T.fetchOne(db, sql: "SELECT * FROM \(T.databaseTableName) WHERE id = ?", arguments: [id.uuidString])
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM \(T.databaseTableName) WHERE id = ?",
                error: error
            )
        }
    }

    // MARK: - Save Operations

    /// Save a record (insert or update)
    ///
    /// If record has a nil or empty UUID, generates new UUID and inserts.
    /// If record has a UUID, updates the existing record with archiving.
    ///
    /// - Parameter record: The record to save (inout for ID assignment)
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// var action = Action(friendlyName: "Run")
    /// try await db.save(&action)
    /// print(action.id) // Now has UUID
    /// ```
    public func save<T: PersistableRecord & TableRecord & Persistable & FetchableRecord & Encodable & Sendable>(_ record: inout T) async throws {
        // Check if this is a new record (id is default UUID())
        let isNew = record.id == UUID()

        if isNew {
            // Generate new ID for new record
            record.id = UUID()

            // Make a copy to capture in async context
            let recordToInsert = record

            do {
                try await dbPool.write { db in
                    try recordToInsert.insert(db)
                }
            } catch {
                throw DatabaseError.writeFailed(
                    operation: "INSERT",
                    table: T.databaseTableName,
                    error: error
                )
            }
        } else {
            // Update existing record with archiving
            try await update(record, archiveOld: true)
        }
    }

    /// Update an existing record with optional archiving
    ///
    /// - Parameters:
    ///   - record: The record to update (must have valid ID)
    ///   - archiveOld: Whether to archive old version before updating
    ///   - notes: Optional notes for archive entry
    /// - Throws: DatabaseError if record not found or update fails
    public func update<T: PersistableRecord & TableRecord & Persistable & FetchableRecord & Encodable & Sendable>(
        _ record: T,
        archiveOld: Bool = true,
        notes: String = ""
    ) async throws {
        guard record.id != UUID() else {
            throw DatabaseError.validationFailed(
                reason: "Cannot update record without ID. Use save() for new records."
            )
        }

        do {
            try await dbPool.write { db in
                // Archive old version if requested
                if archiveOld {
                    if let oldRecord = try T.fetchOne(db, key: ["id": record.id.uuidString]) {
                        try self.archiveRecord(db: db, record: oldRecord, reason: "update", notes: notes)
                    }
                }

                // Perform update
                try record.update(db)
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "UPDATE",
                table: T.databaseTableName,
                error: error
            )
        }
    }

    // MARK: - Delete Operations

    /// Delete a record by ID with archiving
    ///
    /// - Parameters:
    ///   - type: The record type
    ///   - id: UUID of record to delete
    ///   - notes: Optional notes for archive
    /// - Throws: DatabaseError if record not found or delete fails
    ///
    /// Example:
    /// ```swift
    /// try await db.delete(Action.self, id: someUUID)
    /// ```
    public func delete<T: PersistableRecord & TableRecord & FetchableRecord & Persistable & Encodable & Sendable>(
        _ type: T.Type,
        id: UUID,
        notes: String = ""
    ) async throws {
        do {
            try await dbPool.write { db in
                // Fetch record to archive
                guard let record = try T.fetchOne(db, key: ["id": id.uuidString]) else {
                    throw DatabaseError.recordNotFound(table: T.databaseTableName, id: id)
                }

                // Archive first
                try self.archiveRecord(db: db, record: record, reason: "delete", notes: notes)

                // Then delete
                _ = try record.delete(db)
            }
        } catch let error as DatabaseError {
            throw error
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: T.databaseTableName,
                error: error
            )
        }
    }

    // MARK: - Archive Support

    /// Archive a single record to archive table
    ///
    /// This is a private helper used by update and delete operations.
    /// Archives preserve the full record state for audit trail.
    ///
    /// **Note**: This method is called within a write transaction, so it's
    /// nonisolated (doesn't need actor isolation).
    ///
    /// - Parameters:
    ///   - db: Active database connection (within write transaction)
    ///   - record: Record to archive (must be Encodable)
    ///   - reason: Why archiving ('update', 'delete', 'manual')
    ///   - notes: Optional additional context
    /// - Throws: GRDB errors if archive insert fails
    private nonisolated func archiveRecord<T: Encodable & TableRecord & Persistable>(
        db: Database,
        record: T,
        reason: String,
        notes: String
    ) throws {
        // Serialize record to JSON using Codable
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(record)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        let sql = """
            INSERT INTO archive (source_table, source_id, record_data, reason, notes)
            VALUES (?, ?, ?, ?, ?)
            """

        try db.execute(
            sql: sql,
            arguments: [T.databaseTableName, record.id.uuidString, jsonString, reason, notes]
        )
    }
}

// MARK: - TableRecord Extension

extension FetchableRecord {
    /// Default table name derived from type name
    ///
    /// Override this in your type if the table name doesn't match the type name.
    ///
    /// Example:
    /// ```swift
    /// extension Action: TableRecord {
    ///     static let databaseTableName = "actions"
    /// }
    /// ```
    static var databaseTableName: String {
        String(describing: Self.self).lowercased() + "s"
    }
}
