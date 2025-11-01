// Action.swift
// Domain entity representing an action taken at a point in time
//
// Written by Claude Code on 2025-10-17
// Updated by Claude Code on 2025-10-19 (validation moved to ModelExtensions.swift)
// Updated by Claude Code on 2025-10-22 (added direct GRDB conformance)
// Updated by Claude Code on 2025-10-25 (using StructuredQueries JSONRepresentation)
// Updated by Claude Code on 2025-10-30 (removed measuresByUnit for 3NF normalization)
// Ported from Python implementation (python/categoriae/actions.py)

import Foundation
import SQLiteData

/// An action taken at a point in time, with optional timing
///
/// Actions serve as the primary entity for tracking what you've done.
/// Measurements are now stored separately in the MeasuredAction junction table
/// for proper 3NF normalization.
///
/// **Design Philosophy**: On Apple platforms, data structures should work equally well
/// in the database AND in SwiftUI. @Table from SQLiteData achieves this by generating
/// database schema and operations at compile time, eliminating boilerplate Record types.
///
/// **3NF Normalization**: Previously stored measurements as JSON dictionary (measuresByUnit).
/// Now measurements are stored in the MeasuredAction junction table, enabling:
/// - Proper indexing on metric types
/// - Foreign key constraints to metrics catalog
/// - Efficient aggregation queries
/// - No JSON parsing overhead
///
/// **Sendable Conformance**: Action is Sendable because it's a struct with only Sendable
/// properties (String, Date, UUID, Double). This allows Actions to safely cross actor
/// boundaries and be used in @MainActor SwiftUI views without Swift 6 concurrency warnings.
///
/// **@Table Benefits**:
/// - Compile-time schema generation for the `actions` table
/// - Type-safe insert/update/delete operations
/// - Automatic Codable conformance
///
@Table
public struct Action: DomainAbstraction {
    // MARK: - Core Identity (Persistable)

    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?

    // MARK: - Domain-specific Properties

    public var durationMinutes: Double?
    public var startTime: Date?

    // MARK: - System-generated

    public var logTime: Date
    public var id: UUID

    // MARK: - Initialization

    public init(
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        durationMinutes: Double? = nil,
        startTime: Date? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.logTime = logTime
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.durationMinutes = durationMinutes
        self.startTime = startTime
    }
}
