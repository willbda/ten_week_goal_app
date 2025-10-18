// Action.swift
// Domain entity representing an action taken at a point in time
//
// Written by Claude Code on 2025-10-17
// Ported from Python implementation (python/categoriae/actions.py)

import Foundation

/// An action taken at a point in time, with optional measurements and timing
///
/// Actions serve as the primary entity for tracking what you've done.
/// They can include quantitative measurements (distance, duration, reps, etc.)
/// and timing information (when started, how long it took).
///
/// Inherits from PersistableEntity: commonName, id, description, notes, logTime
class Action: PersistableEntity {
    // MARK: - Action-specific Properties

    /// Quantitative measurements associated with this action
    /// Key: measurement type (e.g., "distance_km", "reps")
    /// Value: numeric value
    var measurementUnitsByAmount: [String: Double]?

    /// How long the action took (in minutes)
    var durationMinutes: Double?

    /// When the action started (optional, requires duration if set)
    var startTime: Date?

    // MARK: - Initialization

    /// Create a new action with required and optional fields
    /// - Parameters:
    ///   - commonName: Short description of the action
    ///   - id: Database identifier (nil for new actions)
    ///   - description: Optional detailed description
    ///   - notes: Optional freeform notes
    ///   - logTime: When action was logged (defaults to now)
    ///   - measurementUnitsByAmount: Optional measurements dictionary
    ///   - durationMinutes: Optional duration in minutes
    ///   - startTime: Optional start time
    init(
        commonName: String,
        id: Int? = nil,
        description: String? = nil,
        notes: String? = nil,
        logTime: Date = Date(),
        measurementUnitsByAmount: [String: Double]? = nil,
        durationMinutes: Double? = nil,
        startTime: Date? = nil
    ) {
        self.measurementUnitsByAmount = measurementUnitsByAmount
        self.durationMinutes = durationMinutes
        self.startTime = startTime

        super.init(
            commonName: commonName,
            id: id,
            description: description,
            notes: notes,
            logTime: logTime
        )
    }

    // MARK: - Validation

    /// Validate that this action meets core requirements
    /// - Returns: true if action is valid
    func isValid() -> Bool {
        // Check measurement values are positive
        if let measurements = measurementUnitsByAmount {
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

// MARK: - Equatable

extension Action: Equatable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        // Compare inherited properties
        lhs.id == rhs.id &&
        lhs.commonName == rhs.commonName &&
        lhs.description == rhs.description &&
        lhs.notes == rhs.notes &&
        lhs.logTime == rhs.logTime &&
        // Compare Action-specific properties
        lhs.measurementUnitsByAmount == rhs.measurementUnitsByAmount &&
        lhs.durationMinutes == rhs.durationMinutes &&
        lhs.startTime == rhs.startTime
    }
}
