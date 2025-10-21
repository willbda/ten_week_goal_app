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

    /// UUID mapper for stable ID conversion (INTEGER ↔ UUID)
    public let uuidMapper: UUIDMapper

    // MARK: - Initialization

    /// Initialize database manager with configuration
    ///
    /// Creates or opens database file, initializes schema if needed.
    ///
    /// - Parameter configuration: Database and schema paths
    /// - Throws: DatabaseError if initialization fails
    public init(configuration: DatabaseConfiguration = .default) async throws {
        self.configuration = configuration
        self.uuidMapper = UUIDMapper()  // Initialize UUID mapper

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

        // Create database pool (not async in GRDB)
        if configuration.isInMemory {
            // In-memory database for testing
            // GRDB uses ":memory:" special path for in-memory databases
            self.dbPool = try DatabasePool(path: ":memory:")
        } else {
            // File-based database for production
            self.dbPool = try DatabasePool(path: configuration.databasePath.path)
        }

        // Initialize schema if database is new or in-memory
        let databaseExists = !configuration.isInMemory &&
                            FileManager.default.fileExists(atPath: configuration.databasePath.path)
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
        record: ActionRecord,
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
        record: TermRecord,
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
    /// - Returns: Array of Goal domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let goals = try await db.fetchGoals()
    /// for goal in goals {
    ///     print(goal.friendlyName ?? "")  // Uses stable UUID
    /// }
    /// ```
    public func fetchGoals() async throws -> [Goal] {
        do {
            return try await dbPool.read { db in
                try GoalRecord.fetchAll(db).map { record in
                    var goal = record.toDomain()
                    // Replace random UUID with stable mapped UUID
                    if let dbId = record.id {
                        goal.id = try uuidMapper.uuid(for: "goals", databaseId: dbId, in: db)
                    }
                    return goal
                }
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
    /// - Returns: Array of Action domain models
    /// - Throws: DatabaseError.queryFailed
    ///
    /// Example:
    /// ```swift
    /// let actions = try await db.fetchActions()
    /// for action in actions {
    ///     print(action.friendlyName ?? "")  // Uses stable UUID
    /// }
    /// ```
    public func fetchActions() async throws -> [Action] {
        do {
            return try await dbPool.read { db in
                try ActionRecord.fetchAll(db).map { record in
                    var action = record.toDomain()
                    // Replace random UUID with stable mapped UUID
                    if let dbId = record.id {
                        action.id = try uuidMapper.uuid(for: "actions", databaseId: dbId, in: db)
                    }
                    return action
                }
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
                return try ValueRecord.fetchAll(db, sql: sql).map { $0.toMajorValues() }
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
                return try ValueRecord.fetchAll(db, sql: sql).map { $0.toHighestOrderValues() }
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
                let sql = "SELECT * FROM personal_values WHERE incentive_type = 'general'"
                return try ValueRecord.fetchAll(db, sql: sql).map { $0.toValues() }
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
                return try ValueRecord.fetchAll(db, sql: sql).map { $0.toLifeAreas() }
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
    ///     print("Term \(term.termNumber): \(term.friendlyName ?? "")")
    /// }
    /// ```
    public func fetchTerms() async throws -> [GoalTerm] {
        do {
            return try await dbPool.read { db in
                try TermRecord.fetchAll(db).map { $0.toDomain() }
            }
        } catch {
            throw DatabaseError.queryFailed(
                sql: "SELECT * FROM terms",
                error: error
            )
        }
    }

    /// Save a new Action to database (INSERT only)
    ///
    /// Converts domain Action to ActionRecord, inserts into database.
    /// Database will auto-generate INTEGER id.
    ///
    /// **Limitation**: Cannot update existing actions (no UUID→Int mapping)
    ///
    /// - Parameter action: Action domain model to save
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// let action = Action(friendlyName: "Morning run", measuresByUnit: ["km": 5.0])
    /// try await db.saveAction(action)
    /// ```
    public func saveAction(_ action: Action) async throws {
        do {
            try await dbPool.write { db in
                let record = action.toRecord()
                try record.insert(db)
                // Note: record.id now has database-generated INTEGER id,
                // but we can't propagate it back to domain Action (UUID mismatch)
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "INSERT",
                table: "actions",
                error: error
            )
        }
    }

    /// Save a new Goal to database (INSERT only)
    ///
    /// Converts domain Goal to GoalRecord, inserts into database.
    /// Database will auto-generate INTEGER id.
    ///
    /// **Limitation**: Cannot update existing goals (no UUID→Int mapping)
    ///
    /// - Parameter goal: Goal domain model to save
    /// - Throws: DatabaseError.writeFailed
    ///
    /// Example:
    /// ```swift
    /// let goal = Goal(friendlyName: "Run 120km", measurementUnit: "km", measurementTarget: 120.0)
    /// try await db.saveGoal(goal)
    /// ```
    public func saveGoal(_ goal: Goal) async throws {
        do {
            try await dbPool.write { db in
                let record = goal.toRecord()
                try record.save(db)  // Use save() instead of insert() to handle both create and update
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
                let record = term.toRecord()
                try record.insert(db)
            }
        } catch {
            throw DatabaseError.writeFailed(
                operation: "INSERT",
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
                // Look up database ID from UUID
                guard let databaseId = try uuidMapper.databaseId(
                    for: action.id,
                    entityType: "actions",
                    in: db
                ) else {
                    throw DatabaseError.recordNotFound(table: "actions", id: action.id)
                }

                // Fetch the record to archive
                guard let record = try ActionRecord.fetchOne(db, key: ["id": databaseId]) else {
                    throw DatabaseError.recordNotFound(table: "actions", id: action.id)
                }

                // Archive the database record (not domain model)
                try archiveActionRecord(db: db, record: record, reason: "delete", notes: "Deleted from UI")

                // Then delete the database record
                try db.execute(sql: "DELETE FROM actions WHERE id = ?", arguments: [databaseId])

                // Delete UUID mapping
                try db.execute(
                    sql: "DELETE FROM uuid_mappings WHERE entity_type = ? AND database_id = ?",
                    arguments: ["actions", databaseId]
                )
            }
        } catch let error as DatabaseError {
            throw error
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "actions",
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
                // Look up database ID from UUID
                guard let databaseId = try uuidMapper.databaseId(
                    for: term.id,
                    entityType: "terms",
                    in: db
                ) else {
                    throw DatabaseError.recordNotFound(table: "terms", id: term.id)
                }

                // Fetch the record to archive
                guard let record = try TermRecord.fetchOne(db, key: ["id": databaseId]) else {
                    throw DatabaseError.recordNotFound(table: "terms", id: term.id)
                }

                // Archive the database record
                try archiveTermRecord(db: db, record: record, reason: "delete", notes: "Deleted from UI")

                // Then delete the database record
                try db.execute(sql: "DELETE FROM terms WHERE id = ?", arguments: [databaseId])

                // Delete UUID mapping
                try db.execute(
                    sql: "DELETE FROM uuid_mappings WHERE entity_type = ? AND database_id = ?",
                    arguments: ["terms", databaseId]
                )
            }
        } catch let error as DatabaseError {
            throw error
        } catch {
            throw DatabaseError.writeFailed(
                operation: "DELETE",
                table: "terms",
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
