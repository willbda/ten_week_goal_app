// UUIDMapper.swift
// Stable UUID mapping for INTEGER database IDs
//
// Written by Claude Code on 2025-10-19
//
// Provides bidirectional mapping between:
// - Database INTEGER ids (auto-increment, Python compatible)
// - Domain model UUIDs (type-safe, Swift best practice)
//
// This ensures UUIDs remain stable across database reads while preserving
// compatibility with Python implementation that uses INTEGER ids.

import Foundation
import GRDB

/// Thread-safe UUID mapping service
///
/// Maps database INTEGER ids to stable UUIDs for domain models.
/// UUIDs are generated once on first read and persisted in uuid_mappings table.
///
/// Usage:
/// ```swift
/// // Within a GRDB transaction:
/// let uuid = try mapper.uuid(for: "actions", databaseId: 42, in: db)
/// // Returns same UUID every time for (actions, 42)
/// ```
public actor UUIDMapper {

    // MARK: - Public API

    /// Get UUID for a database record (creates if doesn't exist)
    ///
    /// - Parameters:
    ///   - entityType: Table name (e.g., "actions", "goals")
    ///   - databaseId: INTEGER id from database
    ///   - db: Active database connection (must be in transaction)
    /// - Returns: Stable UUID for this record
    /// - Throws: GRDB errors if database operation fails
    ///
    /// **Thread-safe**: Must be called within GRDB transaction (db parameter)
    ///
    /// **Non-isolated**: Safe to call from within database transactions
    ///
    /// **Readonly handling**: If database is readonly, generates temporary UUID (won't be stable)
    public nonisolated func uuid(for entityType: String, databaseId: Int64, in db: Database) throws -> UUID {
        // Check database mapping
        if let existing = try fetchMapping(entityType: entityType, databaseId: databaseId, in: db) {
            return existing
        }

        // Generate new UUID
        let newUUID = UUID()

        // Try to persist (may fail in readonly database)
        do {
            try insertMapping(entityType: entityType, databaseId: databaseId, uuid: newUUID, in: db)
        } catch {
            // If insert fails (readonly database), just return temporary UUID
            // This means UUIDs won't be stable in readonly mode, but won't crash
            print("⚠️ Could not persist UUID mapping (readonly database?): \(error)")
        }

        return newUUID
    }

    /// Get database ID for a UUID (reverse lookup)
    ///
    /// - Parameters:
    ///   - uuid: UUID from domain model
    ///   - entityType: Table name to search
    ///   - db: Active database connection
    /// - Returns: Database INTEGER id if found, nil otherwise
    /// - Throws: GRDB errors if database operation fails
    ///
    /// Used for UPDATE operations where you have domain model UUID but need database id.
    public nonisolated func databaseId(for uuid: UUID, entityType: String, in db: Database) throws -> Int64? {
        let sql = """
            SELECT database_id FROM uuid_mappings
            WHERE uuid = ? AND entity_type = ?
            LIMIT 1
            """

        return try Int64.fetchOne(db, sql: sql, arguments: [uuid.uuidString, entityType])
    }

    // MARK: - Private Implementation

    /// Fetch existing UUID mapping from database
    private nonisolated func fetchMapping(entityType: String, databaseId: Int64, in db: Database) throws -> UUID? {
        let sql = """
            SELECT uuid FROM uuid_mappings
            WHERE entity_type = ? AND database_id = ?
            LIMIT 1
            """

        guard let uuidString = try String.fetchOne(db, sql: sql, arguments: [entityType, databaseId]) else {
            return nil
        }

        return UUID(uuidString: uuidString)
    }

    /// Insert new UUID mapping into database
    private nonisolated func insertMapping(entityType: String, databaseId: Int64, uuid: UUID, in db: Database) throws {
        let sql = """
            INSERT INTO uuid_mappings (entity_type, database_id, uuid)
            VALUES (?, ?, ?)
            """

        try db.execute(sql: sql, arguments: [entityType, databaseId, uuid.uuidString])
    }
}

// Note: DatabaseManager will hold a UUIDMapper instance
// Added as property in DatabaseManager.swift
