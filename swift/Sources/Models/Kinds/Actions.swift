// Action.swift
// Domain entity representing an action taken at a point in time
//
// Written by Claude Code on 2025-10-17
// Updated by Claude Code on 2025-10-19 (validation moved to ModelExtensions.swift)
// Updated by Claude Code on 2025-10-22 (added direct GRDB conformance)
// Ported from Python implementation (python/categoriae/actions.py)

import Foundation
import Playgrounds
import GRDB

/// An action taken at a point in time, with optional measurements and timing
///
/// Actions serve as the primary entity for tracking what you've done.
/// They can include quantitative measurements (distance, duration, reps, etc.)
/// and timing information (when started, how long it took).
///
/// **GRDB Conformance**: This struct conforms to FetchableRecord, PersistableRecord,
/// and TableRecord, enabling direct database operations without intermediate Record types.
///
public struct Action: Persistable, Doable, Codable, Sendable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Core Identity (Persistable)

    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?

    // MARK: - Domain-specific Properties (Doable)

    /// Quantitative measurements associated with this action
    /// Maps unit names to measured values (e.g., ["km": 5.0, "minutes": 30])
    public var measuresByUnit: [String: Double]?
    public var durationMinutes: Double?
    public var startTime: Date?

    // MARK: - System-generated (Persistable)

    public var logTime: Date
    public var id: UUID

    // MARK: - GRDB Integration

    /// CodingKeys for mapping Swift properties to database columns
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                                  // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case measuresByUnit = "measurement_units_by_amount"
        case durationMinutes = "duration_minutes"
        case startTime = "start_time"
        case logTime = "log_time"
    }

    /// Column enum for type-safe query building
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let detailedDescription = Column(CodingKeys.detailedDescription)
        static let freeformNotes = Column(CodingKeys.freeformNotes)
        static let measuresByUnit = Column(CodingKeys.measuresByUnit)
        static let durationMinutes = Column(CodingKeys.durationMinutes)
        static let startTime = Column(CodingKeys.startTime)
        static let logTime = Column(CodingKeys.logTime)
    }

    /// TableRecord conformance - specify database table name
    public static let databaseTableName = "actions"

    // MARK: - Initialization

    /// Create a new action with required and optional fields
    /// - Parameters:
    ///   - title: Short description of the action
    ///   - detailedDescription: Optional detailed description
    ///   - freeformNotes: Optional freeform notes
    ///   - measuresByUnit: Optional measurements by unit (e.g., ["km": 5.0])
    ///   - durationMinutes: Optional duration in minutes
    ///   - startTime: Optional start time
    ///   - logTime: When action was logged (defaults to now)
    ///   - id: Application assigned UUID

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Domain-specific
        measuresByUnit: [String: Double]? = nil,
        durationMinutes: Double? = nil,
        startTime: Date? = nil,
        // System-generated
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        // Core identity
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        // Domain-specific
        self.measuresByUnit = measuresByUnit
        self.durationMinutes = durationMinutes
        self.startTime = startTime
        // System-generated
        self.logTime = logTime
        self.id = id
    }
}

