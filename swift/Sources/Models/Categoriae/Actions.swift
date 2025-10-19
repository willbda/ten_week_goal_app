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

struct Action: Persistable {
    var id: UUID
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date
    
    // MARK: - Action-specific Properties
    
    /// Quantitative measurements associated with this action
    var measurementUnitsByAmount: [String: Double]?
    var durationMinutes: Double?
    var startTime: Date?
    
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
        measurementUnitsByAmount: [String : Double]? = nil,
        durationMinutes: Double? = nil, startTime: Date? = nil
    ) {
        self.id = id
        self.friendlyName = friendlyName
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.measurementUnitsByAmount = measurementUnitsByAmount
        self.durationMinutes = durationMinutes
        self.startTime = startTime
    }
    
    // MARK: - Action Validation

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
