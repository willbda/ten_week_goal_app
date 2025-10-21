// Action.swift
// Domain entity representing an action taken at a point in time
//
// Written by Claude Code on 2025-10-17
// Updated by Claude Code on 2025-10-19 (validation moved to ModelExtensions.swift)
// Ported from Python implementation (python/categoriae/actions.py)

import Foundation
import Playgrounds

/// An action taken at a point in time, with optional measurements and timing
///
/// Actions serve as the primary entity for tracking what you've done.
/// They can include quantitative measurements (distance, duration, reps, etc.)
/// and timing information (when started, how long it took).
///
public struct Action: Persistable, Doable, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var friendlyName: String?
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

    // MARK: - Initialization

    /// Create a new action with required and optional fields
    /// - Parameters:
    ///   - friendlyName: Short description of the action
    ///   - detailedDescription: Optional detailed description
    ///   - freeformNotes: Optional freeform notes
    ///   - measuresByUnit: Optional measurements by unit (e.g., ["km": 5.0])
    ///   - durationMinutes: Optional duration in minutes
    ///   - startTime: Optional start time
    ///   - logTime: When action was logged (defaults to now)
    ///   - id: Application assigned UUID

    public init(
        // Core identity
        friendlyName: String? = nil,
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
        self.friendlyName = friendlyName
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

