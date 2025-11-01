// TimePeriod.swift
// Pure temporal container - chronological boundaries without planning semantics
//
// Written by Claude Code on 2025-10-31
//
// PURPOSE:
// Represents pure time spans (start → end) without goal planning semantics.
// Can be used for:
// - Calendar periods (quarters, years, months) for reporting
// - Temporal bounds for GoalTerms (planning scaffolds)
// - Filtering actions by date ranges
//
// DESIGN PRINCIPLE:
// TimePeriod is a chronological FACT - it exists independent of goal planning.
// GoalTerm is a planning SCAFFOLD - it references a TimePeriod and adds semantics.

import Foundation
import SQLiteData

/// A span of time with defined start and end boundaries
///
/// **Database Table**: `timePeriods`
/// **Purpose**: Pure chronological container - no planning semantics
///
/// **Usage**:
/// ```swift
/// // Create a 10-week planning period
/// let tenWeeks = TimePeriod(
///     title: "Term 5 Period",
///     startDate: Date("2025-03-01"),
///     endDate: Date("2025-05-10")  // 70 days later
/// )
///
/// // Create a calendar quarter for reporting
/// let q1_2026 = TimePeriod(
///     title: "Q1 2026",
///     startDate: Date("2026-01-01"),
///     endDate: Date("2026-03-31")
/// )
///
/// // GoalTerm references this for planning
/// let goalTerm = GoalTerm(
///     timePeriodId: tenWeeks.id,
///     termNumber: 5,
///     theme: "Health and momentum"
/// )
/// ```
@Table
public struct TimePeriod: DomainAbstraction {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Temporal Boundaries

    /// When this period begins
    public var startDate: Date

    /// When this period ends
    public var endDate: Date

    // MARK: - Initialization

    /// Create a new time period
    ///
    /// - Parameters:
    ///   - title: Human-readable name ("Q1 2026", "Term 5 Period")
    ///   - detailedDescription: Optional explanation
    ///   - freeformNotes: Additional notes
    ///   - startDate: Beginning of period
    ///   - endDate: End of period
    ///   - logTime: When this period was created
    ///   - id: Unique identifier
    public init(
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        startDate: Date,
        endDate: Date,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        precondition(
            startDate <= endDate,
            "Start date must be before or equal to end date")

        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.startDate = startDate
        self.endDate = endDate
    }
}
