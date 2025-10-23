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
/// var action = Action(title: "Run")
/// try await db.save(&action)
///
/// // Fetch by ID
/// if let action = try await db.fetchOne(Action.self, id: someUUID) {
///     print(action.title ?? "")
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
        if !configuration.isInMemory {
            let directory = configuration.databasePath.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }

        // Check if database exists BEFORE creating pool (pool creates empty file)
        let databaseExists = !configuration.isInMemory &&
                            FileManager.default.fileExists(atPath: configuration.databasePath.path)

        // Create database pool configuration with foreign keys and WAL mode
        var dbConfig = Configuration()
        dbConfig.foreignKeysEnabled = true  // CRITICAL: Enable foreign key constraints

        // Configure Write-Ahead Logging (WAL) for better concurrency
        // WAL allows multiple readers while a writer is active
        dbConfig.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            // Set synchronous mode for better performance while maintaining safety
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
        }

        // Create database pool (not async in GRDB)
        if configuration.isInMemory {
            // In-memory database for testing
            // GRDB uses ":memory:" special path for in-memory databases
            self.dbPool = try DatabasePool(path: ":memory:", configuration: dbConfig)
        } else {
            // File-based database for production
            self.dbPool = try DatabasePool(path: configuration.databasePath.path, configuration: dbConfig)
        }

        // Initialize schema if database is new or in-memory
        if !databaseExists || configuration.isInMemory {
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
        // Get all .sql files from schema directory
        let contents = try FileManager.default.contentsOfDirectory(
            at: configuration.schemaDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let schemaFiles = contents
            .filter { $0.pathExtension == "sql" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

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

    /// Ensure conversation_history table exists (migration for existing databases)
    ///
    /// This method checks if the conversation_history table exists and creates it
    /// if missing. Safe to call multiple times (idempotent).
    ///
    /// This is used for migrating existing databases that don't have the AI
    /// assistant feature yet. New databases get this table through normal
    /// schema initialization.
    ///
    /// - Throws: DatabaseError if table creation fails
    public func ensureConversationHistoryTable() async throws {
        try await dbPool.write { db in
            // Check if table already exists
            let tableExists = try db.tableExists("conversation_history")

            if !tableExists {
                // Load conversation_history.sql schema
                let schemaPath = configuration.schemaDirectory
                    .appendingPathComponent("conversation_history.sql")

                guard FileManager.default.fileExists(atPath: schemaPath.path) else {
                    throw DatabaseError.schemaInitializationFailed(
                        schemaFile: "conversation_history.sql",
                        error: NSError(domain: "DatabaseManager", code: 2,
                                     userInfo: [NSLocalizedDescriptionKey: "Schema file not found"])
                    )
                }

                let sql = try String(contentsOf: schemaPath, encoding: .utf8)
                try db.execute(sql: sql)
            }
        }
    }

    /// Save any GRDB PersistableRecord (generic version)
    ///
    /// This works with any type conforming to GRDB's PersistableRecord,
    /// not just types conforming to our domain Persistable protocol.
    ///
    /// - Parameter record: The record to save (insert or update)
    /// - Returns: The saved record (with any database-generated values)
    /// - Throws: DatabaseError.writeFailed
    public func saveRecord<T: PersistableRecord & Sendable>(_ record: T) async throws -> T {
        return try await dbPool.write { db in
            var mutableRecord = record
            try mutableRecord.save(db)
            return mutableRecord
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
    ///     print(action.title ?? "")
    /// }
    /// ```
    public func fetchOne<T: FetchableRecord & TableRecord & Sendable>(
        _ type: T.Type,
        id: UUID
    ) async throws -> T? {
        do {
            return try await dbPool.read { db in
                try T.fetchOne(db, sql: "SELECT * FROM \(T.databaseTableName) WHERE uuid_id = ?", arguments: [id.uuidString])
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM \(T.databaseTableName) WHERE uuid_id = ?",
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
    /// var action = Action(title: "Run")
    /// try await db.save(&action)
    /// print(action.id) // Now has UUID
    /// ```
    public func save<T: PersistableRecord & TableRecord & Persistable & FetchableRecord & Encodable & Sendable>(_ record: inout T) async throws {
        // Capture ID before async closure (Swift 6 concurrency requirement)
        let recordId = record.id

        // Check if record exists in database by querying for it
        let exists = try await dbPool.read { db in
            let sql = "SELECT COUNT(*) FROM \(T.databaseTableName) WHERE uuid_id = ?"
            return try Int.fetchOne(db, sql: sql, arguments: [recordId.uuidString]) ?? 0 > 0
        }

        if !exists {
            // New record - insert it
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
            // Existing record - update with archiving
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
                    let sql = "SELECT * FROM \(T.databaseTableName) WHERE uuid_id = ?"
                    if let oldRecord = try T.fetchOne(db, sql: sql, arguments: [record.id.uuidString]) {
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

    /// Insert or update a record (simplified for immutable types like enums)
    ///
    /// This method works with any GRDB-compatible record without requiring
    /// the Persistable protocol. Useful for enum types with associated values.
    ///
    /// - Parameter record: The record to save
    /// - Throws: DatabaseError if save fails
    ///
    /// Example:
    /// ```swift
    /// let goal = try Expectation.goal(...)
    /// try await db.insert(goal)
    /// ```
    public func insert<T: PersistableRecord & Sendable>(_ record: T) async throws {
        try await dbPool.write { db in
            try record.insert(db)
        }
    }

    /// Perform a read-only database operation
    ///
    /// Use this to access the database for queries that don't require
    /// the full DatabaseManager API.
    ///
    /// Example:
    /// ```swift
    /// let goals = try await db.read { db in
    ///     try Expectation.fetchByType(db, type: "goal")
    /// }
    /// ```
    public func read<T: Sendable>(_ operation: @Sendable @escaping (Database) throws -> T) async throws -> T {
        try await dbPool.read(operation)
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
                // Fetch record to archive using SQL
                let sql = "SELECT * FROM \(T.databaseTableName) WHERE uuid_id = ?"
                guard let record = try T.fetchOne(db, sql: sql, arguments: [id.uuidString]) else {
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

    /// Archive an ActionRecord to archive table
    ///
    /// Specialized archiving for ActionRecord (uses Int64 id, not UUID).
    ///
    /// - Parameters:
    ///   - db: Active database connection (within write transaction)
    ///   - record: ActionRecord to archive
    ///   - reason: Why archiving ('update', 'delete', 'manual')
    ///   - notes: Optional additional context
    /// - Throws: GRDB errors if archive insert fails
    private nonisolated func archiveActionRecord(
        db: Database,
        record: Action,
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
            arguments: ["actions", record.id ?? 0, jsonString, reason, notes]
        )
    }

    private nonisolated func archiveTermRecord(
        db: Database,
        record: GoalTerm,
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
            arguments: ["terms", record.id ?? 0, jsonString, reason, notes]
        )
    }

    // MARK: - Record-Aware Operations (Domain Models)

    /// Fetch all Goals from database
    ///
    /// Uses GoalRecord internally to bridge database schema to domain model.
    /// Returns clean Goal domain objects with stable UUID ids.
    ///
    /// **UUID Stability**: UUIDs are mapped from database INTEGER ids via uuid_mappings table.
    /// Same database record always returns same UUID.
    ///
    /// **Side Effect**: Uses write transaction to populate uuid_mappings table on first access.
    /// This ensures UUID stability across subsequent reads. The write only affects uuid_mappings,
    /// not the goals table itself.
    ///
    /// - Returns: Array of Goal domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let goals = try await db.fetchGoals()
    /// for goal in goals {
    ///     print(goal.title ?? "")  // Uses stable UUID
    /// }
    /// ```
    public func fetchGoals() async throws -> [Goal] {
        do {
            return try await dbPool.read { db in
                try Goal.fetchAll(db)
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM goals",
                error: error
            )
        }
    }

    /// Fetch all Actions from database
    ///
    /// Uses ActionRecord internally to bridge database schema to domain model.
    /// Returns clean Action domain objects with stable UUID ids.
    ///
    /// **UUID Stability**: UUIDs are mapped from database INTEGER ids via uuid_mappings table.
    /// Same database record always returns same UUID.
    ///
    /// **Side Effect**: Uses write transaction to populate uuid_mappings table on first access.
    /// This ensures UUID stability across subsequent reads. The write only affects uuid_mappings,
    /// not the actions table itself.
    ///
    /// - Returns: Array of Action domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let actions = try await db.fetchActions()
    /// for action in actions {
    ///     print(action.title ?? "")  // Uses stable UUID
    /// }
    /// ```
    public func fetchActions() async throws -> [Action] {
        do {
            return try await dbPool.read { db in
                try Action.fetchAll(db)
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM actions",
                error: error
            )
        }
    }

    /// Fetch all MajorValues from database
    ///
    /// Filters to incentive_type = 'major' and converts to MajorValues domain models.
    ///
    /// - Returns: Array of MajorValues domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let majorValues = try await db.fetchMajorValues()
    /// ```
    public func fetchMajorValues() async throws -> [MajorValues] {
        do {
            return try await dbPool.read { db in
                let sql = "SELECT * FROM personal_values WHERE incentive_type = 'major'"
                // TODO: Add direct GRDB conformance to Values
                return []  // Temporarily return empty array
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM personal_values WHERE incentive_type = 'major'",
                error: error
            )
        }
    }

    /// Fetch all HighestOrderValues from database
    ///
    /// Filters to incentive_type = 'highest_order' and converts to HighestOrderValues domain models.
    ///
    /// - Returns: Array of HighestOrderValues domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let highestValues = try await db.fetchHighestOrderValues()
    /// ```
    public func fetchHighestOrderValues() async throws -> [HighestOrderValues] {
        do {
            return try await dbPool.read { db in
                let sql = "SELECT * FROM personal_values WHERE incentive_type = 'highest_order'"
                // TODO: Add direct GRDB conformance to Values
                return []  // Temporarily return empty array
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM personal_values WHERE incentive_type = 'highest_order'",
                error: error
            )
        }
    }

    /// Fetch all general Values from database
    ///
    /// Filters to incentive_type = 'general' and converts to Values domain models.
    ///
    /// - Returns: Array of Values domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let values = try await db.fetchGeneralValues()
    /// ```
    public func fetchGeneralValues() async throws -> [Values] {
        do {
            return try await dbPool.read { db in
                try Values.filter(sql: "incentive_type = 'general'").fetchAll(db)
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM personal_values WHERE incentive_type = 'general'",
                error: error
            )
        }
    }

    /// Fetch all LifeAreas from database
    ///
    /// Filters to incentive_type = 'life_area' and converts to LifeAreas domain models.
    ///
    /// - Returns: Array of LifeAreas domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let lifeAreas = try await db.fetchLifeAreas()
    /// ```
    public func fetchLifeAreas() async throws -> [LifeAreas] {
        do {
            return try await dbPool.read { db in
                let sql = "SELECT * FROM personal_values WHERE incentive_type = 'life_area'"
                // TODO: Add direct GRDB conformance to Values
                return []  // Temporarily return empty array
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM personal_values WHERE incentive_type = 'life_area'",
                error: error
            )
        }
    }

    /// Fetch all Terms from database
    ///
    /// Uses TermRecord internally to bridge database schema to domain model.
    /// Note: term_goals_by_id currently generates placeholder UUIDs.
    ///
    /// - Returns: Array of GoalTerm domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let terms = try await db.fetchTerms()
    /// for term in terms {
    ///     print("Term \(term.termNumber): \(term.title ?? "")")
    /// }
    /// ```
    public func fetchTerms() async throws -> [GoalTerm] {
        do {
            return try await dbPool.read { db in
                try GoalTerm.fetchAll(db)
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM terms",
                error: error
            )
        }
    }

    /// Save an Action to database (INSERT or UPDATE)
    ///
    /// Uses Action's direct GRDB conformance to save. GRDB will:
    /// - INSERT if uuid_id doesn't exist
    /// - UPDATE if uuid_id already exists
    ///
    /// - Parameter action: Action domain model to save
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// let action = Action(title: "Morning run", measuresByUnit: ["km": 5.0])
    /// try await db.saveAction(action)
    /// ```
    public func saveAction(_ action: Action) async throws {
        do {
            try await dbPool.write { db in
                try action.save(db)
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "SAVE",
                table: "actions",
                error: error
            )
        }
    }

    /// Save a Goal to the database
    ///
    /// Uses direct GRDB conformance - Goal conforms to PersistableRecord.
    /// GRDB's persistenceConflictPolicy handles INSERT OR REPLACE automatically.
    ///
    /// - Parameter goal: Goal domain model to save
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// let goal = Goal(title: "Run 120km", measurementUnit: "km", measurementTarget: 120.0)
    /// try await db.saveGoal(goal)
    /// ```
    public func saveGoal(_ goal: Goal) async throws {
        do {
            try await dbPool.write { db in
                try goal.save(db)  // Direct GRDB save - handles INSERT/UPDATE via persistenceConflictPolicy
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "SAVE",
                table: "goals",
                error: error
            )
        }
    }

    /// Save a Term to the database
    ///
    /// Creates a new term record in the database.
    ///
    /// - Parameter term: GoalTerm domain model to save
    /// - Throws: DatabaseError if save fails
    ///
    /// Example:
    /// ```swift
    /// let term = GoalTerm(termNumber: 1, startDate: start, targetDate: end)
    /// try await db.saveTerm(term)
    /// ```
    public func saveTerm(_ term: GoalTerm) async throws {
        do {
            try await dbPool.write { db in
                try term.save(db)  // Direct GRDB save - handles INSERT/UPDATE via persistenceConflictPolicy
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "SAVE",
                table: "terms",
                error: error
            )
        }
    }

    /// Delete an Action by UUID
    ///
    /// Uses UUID→Int64 mapping to find database record and delete it.
    /// Archives the action before deletion for audit trail.
    ///
    /// - Parameter action: Action domain model to delete
    /// - Throws: DatabaseError if action not found or delete fails
    ///
    /// Example:
    /// ```swift
    /// try await db.deleteAction(action)
    /// ```
    public func deleteAction(_ action: Action) async throws {
        do {
            try await dbPool.write { db in
                try action.delete(db)  // Direct GRDB delete using uuid_id PRIMARY KEY
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "actions",
                error: error
            )
        }
    }

    /// Delete a Goal by UUID
    ///
    /// Uses direct GRDB conformance - Goal.delete(db) uses uuid_id PRIMARY KEY.
    /// Archiving is not yet implemented for goals.
    ///
    /// - Parameter goal: Goal domain model to delete
    /// - Throws: DatabaseError if goal not found or delete fails
    ///
    /// Example:
    /// ```swift
    /// try await db.deleteGoal(goal)
    /// ```
    public func deleteGoal(_ goal: Goal) async throws {
        do {
            try await dbPool.write { db in
                try goal.delete(db)  // Direct GRDB delete using uuid_id PRIMARY KEY
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "goals",
                error: error
            )
        }
    }

    /// Delete a Term by UUID
    ///
    /// Uses UUID→Int64 mapping to find database record and delete it.
    /// Archives the term before deletion for audit trail.
    ///
    /// - Parameter term: GoalTerm domain model to delete
    /// - Throws: DatabaseError if term not found or delete fails
    ///
    /// Example:
    /// ```swift
    /// try await db.deleteTerm(term)
    /// ```
    public func deleteTerm(_ term: GoalTerm) async throws {
        do {
            try await dbPool.write { db in
                try term.delete(db)  // Direct GRDB delete using uuid_id PRIMARY KEY
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "terms",
                error: error
            )
        }
    }

    // MARK: - Action-Goal Relationship Operations

    /// Fetch all action-goal relationships for a specific action
    ///
    /// Returns all goals that this action contributes to, along with contribution
    /// amount, match method, and confidence scores.
    ///
    /// - Parameter actionId: UUID of the action
    /// - Returns: Array of ActionGoalRelationship objects
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let relationships = try await db.fetchRelationships(forAction: action.id)
    /// for rel in relationships {
    ///     print("Contributes \(rel.contribution) to goal \(rel.goalId)")
    /// }
    /// ```
    public func fetchRelationships(forAction actionId: UUID) async throws -> [ActionGoalRelationship] {
        try await fetch(
            ActionGoalRelationship.self,
            sql: "SELECT * FROM action_goal_progress WHERE action_id = ?",
            arguments: [actionId.uuidString]
        )
    }

    /// Fetch all action-goal relationships for a specific goal
    ///
    /// Returns all actions that contribute to this goal.
    ///
    /// - Parameter goalId: UUID of the goal
    /// - Returns: Array of ActionGoalRelationship objects
    /// - Throws: DatabaseError.queryFailed
    public func fetchRelationships(forGoal goalId: UUID) async throws -> [ActionGoalRelationship] {
        try await fetch(
            ActionGoalRelationship.self,
            sql: "SELECT * FROM action_goal_progress WHERE goal_id = ?",
            arguments: [goalId.uuidString]
        )
    }

    /// Fetch all action-goal relationships
    ///
    /// - Returns: Array of all ActionGoalRelationship objects
    /// - Throws: DatabaseError.queryFailed
    public func fetchAllRelationships() async throws -> [ActionGoalRelationship] {
        try await fetchAll()
    }

    /// Save an action-goal relationship
    ///
    /// Creates a new relationship between an action and a goal, or updates existing.
    /// Uses the UNIQUE(action_id, goal_id) constraint to prevent duplicates.
    ///
    /// - Parameter relationship: ActionGoalRelationship to save
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// let relationship = ActionGoalRelationship(
    ///     actionId: action.id,
    ///     goalId: goal.id,
    ///     contribution: 5.0,
    ///     matchMethod: .manual,
    ///     confidence: 1.0,
    ///     matchedOn: []
    /// )
    /// try await db.saveRelationship(relationship)
    /// ```
    public func saveRelationship(_ relationship: ActionGoalRelationship) async throws {
        do {
            try await dbPool.write { db in
                // Use insert(onConflict: .replace) to handle UNIQUE constraint
                try relationship.insert(db, onConflict: .replace)
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "SAVE",
                table: "action_goal_progress",
                error: error
            )
        }
    }

    /// Delete an action-goal relationship
    ///
    /// Removes the link between an action and a goal.
    ///
    /// - Parameters:
    ///   - actionId: UUID of the action
    ///   - goalId: UUID of the goal
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// try await db.deleteRelationship(actionId: action.id, goalId: goal.id)
    /// ```
    public func deleteRelationship(actionId: UUID, goalId: UUID) async throws {
        do {
            try await dbPool.write { db in
                try db.execute(
                    sql: "DELETE FROM action_goal_progress WHERE action_id = ? AND goal_id = ?",
                    arguments: [actionId.uuidString, goalId.uuidString]
                )
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "action_goal_progress",
                error: error
            )
        }
    }

    /// Delete all relationships for an action
    ///
    /// Removes all goal associations for the specified action.
    ///
    /// - Parameter actionId: UUID of the action
    /// - Throws: DatabaseError.writeFailed
    public func deleteAllRelationships(forAction actionId: UUID) async throws {
        do {
            try await dbPool.write { db in
                try db.execute(
                    sql: "DELETE FROM action_goal_progress WHERE action_id = ?",
                    arguments: [actionId.uuidString]
                )
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "action_goal_progress",
                error: error
            )
        }
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
