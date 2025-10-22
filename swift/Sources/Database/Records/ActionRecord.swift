// ActionRecord.swift
// Database transfer object for Actions table
//
// Written by Claude Code on 2025-10-19
// Updated by Claude Code on 2025-10-21: Direct uuid_id usage (eliminated UUIDMapper)
//
// Bridges between database schema and clean Action domain model.
// Database uses INTEGER ids (Python compatibility) and TEXT uuid_id (Swift primary key).

import Foundation
import GRDB
import Models
import Playgrounds

/// Database representation of actions table
///
/// Maps database schema to domain Action type.
/// Handles JSON serialization of measurements automatically via Codable.
///
/// **Dual-ID System** (Cross-Language Compatibility):
/// - `id` (INTEGER): Auto-increment primary key used by Python implementation
/// - `uuid_id` (TEXT): Required UUID string used by Swift as stable identifier
///
/// Swift ignores the INTEGER id and uses uuid_id exclusively for all operations.
/// Python ignores uuid_id and uses INTEGER id. Both can coexist in the same database.
public struct ActionRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Database Fields

    /// Database INTEGER primary key (auto-increment, used by Python)
    ///
    /// **Swift**: Ignored (never read, set to nil on writes)
    /// **Python**: Primary key for all CRUD operations
    /// **Purpose**: Cross-language database compatibility
    public var id: Int64?

    /// UUID stored as TEXT (REQUIRED, used by Swift as primary key)
    ///
    /// **Swift**: Primary key for all CRUD operations (UNIQUE constraint in DB)
    /// **Python**: Ignored (Python doesn't read or validate this column)
    /// **Purpose**: Stable, type-safe identifiers for Swift domain models
    ///
    /// **Requirement**: Must always contain valid UUID string (never nil in practice)
    public var uuid_id: String

    /// Short identifier (maps to Action.title)
    public var title: String

    /// Optional elaboration (maps to Action.detailedDescription)
    public var description: String?

    /// Freeform notes (maps to Action.freeformNotes)
    public var notes: String?

    /// When logged (ISO format in DB)
    public var log_time: Date

    /// Measurements dictionary stored as JSON
    /// Example DB value: '{"km": 5.0, "minutes": 30}'
    /// GRDB automatically encodes/decodes this via Codable
    public var measurement_units_by_amount: [String: Double]?

    /// When action started (ISO format in DB)
    public var start_time: Date?

    /// Duration in minutes
    public var duration_minutes: Double?

    // MARK: - GRDB Configuration

    /// CodingKeys for database column mapping
    enum CodingKeys: String, CodingKey {
        case id
        case uuid_id
        case title
        case description
        case notes
        case log_time
        case measurement_units_by_amount
        case start_time
        case duration_minutes
    }

    /// Table name in database
    public static let databaseTableName = "actions"

    // MARK: - Initialization

    /// Create a new action record
    ///
    /// - Parameters:
    ///   - id: INTEGER id (ignored by Swift, set to nil)
    ///   - uuid_id: REQUIRED UUID string (Swift's primary key)
    ///   - title: Short action identifier
    ///   - description: Optional detailed description
    ///   - notes: Optional freeform notes
    ///   - log_time: When action was logged
    ///   - measurement_units_by_amount: Optional measurements dictionary
    ///   - start_time: Optional action start time
    ///   - duration_minutes: Optional duration
    ///
    /// **Note**: uuid_id is required (no default) to ensure all records have stable IDs
    public init(
        id: Int64? = nil,
        uuid_id: String,  // REQUIRED: No longer optional
        title: String,
        description: String? = nil,
        notes: String? = nil,
        log_time: Date,
        measurement_units_by_amount: [String: Double]? = nil,
        start_time: Date? = nil,
        duration_minutes: Double? = nil
    ) {
        self.id = id
        self.uuid_id = uuid_id
        self.title = title
        self.description = description
        self.notes = notes
        self.log_time = log_time
        self.measurement_units_by_amount = measurement_units_by_amount
        self.start_time = start_time
        self.duration_minutes = duration_minutes
    }
}

// MARK: - Database -> Domain Conversion

public extension ActionRecord {
    /// Convert database record to clean domain model
    ///
    /// **Direct UUID Mapping** (No UUIDMapper dependency):
    /// - Parses uuid_id TEXT directly to UUID
    /// - Crashes if uuid_id is invalid (database integrity issue)
    /// - snake_case columns → camelCase properties
    /// - JSON measurement_units_by_amount → measuresByUnit dictionary
    ///
    /// **Safety**: Force-unwrap is intentional - invalid uuid_id indicates database corruption
    /// that should be caught immediately, not silently recovered from.
    ///
    /// - Returns: Action domain model with stable UUID from database
    func toDomain() -> Action {
        // Direct UUID parsing from database TEXT column
        // Force-unwrap is safe: uuid_id is required and validated at insert time
        guard let uuid = UUID(uuidString: uuid_id) else {
            fatalError("Database integrity error: Invalid UUID '\(uuid_id)' in actions table")
        }

        return Action(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            measuresByUnit: measurement_units_by_amount,  // JSON auto-decoded by GRDB
            durationMinutes: duration_minutes,
            startTime: start_time,
            logTime: log_time,
            id: uuid  // Stable UUID directly from database!
        )
    }
}

// MARK: - Domain -> Database Conversion

public extension Action {
    /// Convert clean domain model to database record
    ///
    /// **Direct UUID Storage**:
    /// - UUID → uuid_id TEXT (direct string conversion)
    /// - camelCase properties → snake_case columns
    /// - measuresByUnit dictionary → JSON measurement_units_by_amount
    ///
    /// **Dual-ID System** (Cross-Language Compatibility):
    /// - `id` (INTEGER): Set to nil → database auto-increments for Python
    /// - `uuid_id` (TEXT): Direct UUID.uuidString → Swift's primary key
    ///
    /// **Database Behavior**:
    /// - INSERT: Both columns are filled (INTEGER auto-increments, uuid_id from domain)
    /// - UPDATE: Swift uses uuid_id in WHERE clause (ignores INTEGER id)
    /// - Python: Uses INTEGER id exclusively (ignores uuid_id column)
    ///
    /// - Returns: ActionRecord ready for GRDB persistence
    func toRecord() -> ActionRecord {
        ActionRecord(
            id: nil,  // Ignored by Swift; database auto-increments for Python
            uuid_id: id.uuidString,  // Direct UUID → TEXT conversion (Swift's primary key)
            title: title ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            measurement_units_by_amount: measuresByUnit,  // GRDB auto-encodes to JSON
            start_time: startTime,
            duration_minutes: durationMinutes
        )
    }
}

// MARK: - GRDB Persistence Notes

// GRDB automatically uses Codable for encoding/decoding.
// Since ActionRecord conforms to Codable + PersistableRecord:
// - CodingKeys maps camelCase ↔ snake_case
// - JSON encoding is automatic for [String: Double] measurements
// - uuid_id is persisted as TEXT column
//
// **Important**: GRDB uses rowid by default for record identity.
// To use uuid_id instead, DatabaseManager must specify WHERE clauses explicitly
// when updating/deleting records.

