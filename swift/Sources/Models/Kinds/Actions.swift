// Action.swift
// Domain entity representing an action taken at a point in time
//
// Written by Claude Code on 2025-10-17
// Updated by Claude Code on 2025-10-19 (validation moved to ModelExtensions.swift)
// Updated by Claude Code on 2025-10-22 (added direct GRDB conformance)
// Updated by Claude Code on 2025-10-25 (using StructuredQueries JSONRepresentation)
// Ported from Python implementation (python/categoriae/actions.py)

import Foundation
import Playgrounds
import SQLiteData
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
@Table
public struct Action: Persistable, Doable, Sendable, FetchableRecord, PersistableRecord, TableRecord {

    // MARK: - GRDB TableRecord
    public static let databaseTableName = "actions"
    // MARK: - Core Identity (Persistable)

    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?

    // MARK: - Domain-specific Properties (Doable)

    /// Measurements dictionary (JSON storage via StructuredQueries)
    /// Note: Empty dictionary ([:])) instead of nil for compatibility with JSONRepresentation
    @Column(as: [String: Double].JSONRepresentation.self)
    public var measuresByUnit: [String: Double] = [:]

    public var durationMinutes: Double?
    public var startTime: Date?

    // MARK: - System-generated (Persistable)

    public var logTime: Date
    public var id: UUID

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
        measuresByUnit: [String: Double] = [:],
        durationMinutes: Double? = nil,
        startTime: Date? = nil,
        // System-generated
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        // System-generated (initialize first)
        self.logTime = logTime
        self.id = id
        // Core identity
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        // Domain-specific
        self.measuresByUnit = measuresByUnit
        self.durationMinutes = durationMinutes
        self.startTime = startTime
    }
}

