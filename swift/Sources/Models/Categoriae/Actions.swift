// Action.swift
// Domain entity representing an action taken at a point in time
//
// Written by Claude Code on 2025-10-17
// Updated by Claude Code on 2025-10-18 for GRDB integration
// Ported from Python implementation (python/categoriae/actions.py)

import Foundation
import GRDB

/// An action taken at a point in time, with optional measurements and timing
///
/// Actions serve as the primary entity for tracking what you've done.
/// They can include quantitative measurements (distance, duration, reps, etc.)
/// and timing information (when started, how long it took).
///

struct Action: Persistable, Performed, Codable, Sendable, FetchableRecord, PersistableRecord, TableRecord {
    var id: UUID
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date

    // MARK: - Performed Properties

    /// Quantitative measurements associated with this action
    /// Maps to database column: measurement_units_by_amount
    var measurements: [String: Double]?
    var durationMinutes: Double?
    var startTime: Date?

    // MARK: - TableRecord

    /// Database table name for GRDB
    static let databaseTableName = "actions"

    // MARK: - Codable Support

    /// Custom coding keys for database snake_case compatibility
    enum CodingKeys: String, CodingKey {
        case id
        case friendlyName = "friendly_name"
        case detailedDescription = "detailed_description"
        case freeformNotes = "freeform_notes"
        case logTime = "log_time"
        case measurements = "measurement_units_by_amount"
        case durationMinutes = "duration_minutes"
        case startTime = "start_time"
    }
    
    // MARK: - Initialization
    
    /// Create a new action with required and optional fields
    /// - Parameters:
    ///   - freindlyName: Short description of the action
    ///   - id: Application assigned UUID
    ///   - description: Optional detailed description
    ///   - notes: Optional freeform notes
    ///   - logTime: When action was logged (defaults to now)
    ///   - measurementUnitsByAmount: Optional measurements dictionary
    ///   - durationMinutes: Optional duration in minutes
    ///   - startTime: Optional start time
    
    init(
        //By writing a custom initializer, we permit ourselves default values.
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        measurements: [String : Double]? = nil,
        durationMinutes: Double? = nil,
        startTime: Date? = nil
    ) {
        self.id = id
        self.friendlyName = friendlyName
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.measurements = measurements
        self.durationMinutes = durationMinutes
        self.startTime = startTime
    }
    
    // MARK: - Action Validation

    func isValid() -> Bool {
        // Check measurement values are positive
        if let measurements = measurements {
            for (_, value) in measurements {
                if value <= 0 {
                    return false
                }
            }
        }

        // If start_time exists, duration should too
        if startTime != nil && durationMinutes == nil {
            return false
        }

        return true
    }
}
