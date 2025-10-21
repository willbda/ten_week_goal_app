// ActionRecord.swift
// Database transfer object for Actions table
//
// Written by Claude Code on 2025-10-19
//
// Bridges between database schema and clean Action domain model.
// Database uses INTEGER ids, snake_case columns, and JSON for measurements.

import Foundation
import GRDB
import Models
import Playgrounds

/// Database representation of actions table
///
/// Maps database schema to domain Action type.
/// Handles JSON serialization of measurements automatically via Codable.
public struct ActionRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Database Fields

    /// Database INTEGER primary key (auto-increment, used by Python)
    public var id: Int64?

    /// UUID stored as TEXT (used by Swift, UNIQUE constraint in DB)
    /// This provides stable IDs across Swift fetches while maintaining
    /// Python compatibility (Python uses INTEGER id, Swift uses uuid_id)
    public var uuid_id: String?

    /// Short identifier (maps to Action.friendlyName)
    public var common_name: String

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
        case common_name
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
    public init(
        id: Int64? = nil,
        uuid_id: String? = nil,
        common_name: String,
        description: String? = nil,
        notes: String? = nil,
        log_time: Date,
        measurement_units_by_amount: [String: Double]? = nil,
        start_time: Date? = nil,
        duration_minutes: Double? = nil
    ) {
        self.id = id
        self.uuid_id = uuid_id
        self.common_name = common_name
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
    /// Handles:
    /// - uuid_id TEXT -> UUID (stable across fetches!)
    /// - snake_case columns -> camelCase properties
    /// - JSON measurement_units_by_amount -> measuresByUnit dictionary
    ///
    /// UUID Mapping:
    /// - If uuid_id exists in database, parse and use it (stable ID)
    /// - If uuid_id is nil, generate new UUID and it will be saved on next write
    func toDomain() -> Action {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return Action(
            friendlyName: common_name,
            detailedDescription: description,
            freeformNotes: notes,
            measuresByUnit: measurement_units_by_amount,  // JSON auto-decoded by GRDB
            durationMinutes: duration_minutes,
            startTime: start_time,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }
}

// MARK: - Domain -> Database Conversion

public extension Action {
    /// Convert clean domain model to database record
    ///
    /// Handles:
    /// - UUID domain ID -> uuid_id TEXT field (stable across fetches)
    /// - camelCase properties -> snake_case columns
    /// - measuresByUnit dictionary -> JSON measurement_units_by_amount
    ///
    /// Dual ID System:
    /// - id INTEGER: Set to nil, database auto-increments (Python uses this)
    /// - uuid_id TEXT: Stores Swift's UUID as string (Swift uses this)
    func toRecord() -> ActionRecord {
        ActionRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            common_name: friendlyName ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            measurement_units_by_amount: measuresByUnit,  // GRDB auto-encodes to JSON
            start_time: startTime,
            duration_minutes: durationMinutes
        )
    }
}

