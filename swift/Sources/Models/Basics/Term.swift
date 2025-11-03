// Term.swift
// Goal planning scaffolds with temporal boundaries and state
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (fixed protocols, moved methods to extensions)
// Updated by Claude Code on 2025-10-31 (refactored to reference TimePeriod via FK)
// Ported from Python implementation (python/categoriae/terms.py)
//
// Inspired by "4,000 Weeks" thinking - how do we structure finite time?
// GoalTerms provide planning scaffolds with state (active, delayed, completed).
// They reference TimePeriods for chronological boundaries.

import Foundation
import SQLiteData

// MARK: - TermStatus Enum

/// Status of a goal planning term
///
/// Unlike calendar periods (which are just time), goal terms have
/// planning state that reflects progress and intention.
public enum TermStatus: String, Codable, CaseIterable, Sendable, QueryRepresentable, QueryBindable {
    case planned = "planned"  // Future term, not yet started
    case active = "active"  // Currently working on goals
    case completed = "completed"  // Successfully finished
    case delayed = "delayed"  // Behind schedule
    case onHold = "on_hold"  // Paused, may resume
    case cancelled = "cancelled"  // Abandoned

    /// Human-readable description
    public var description: String {
        switch self {
        case .planned:
            return "Planned"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .delayed:
            return "Delayed"
        case .onHold:
            return "On Hold"
        case .cancelled:
            return "Cancelled"
        }
    }
}

// MARK: - GoalTerm Struct

/// A goal planning scaffold with temporal boundaries and state
///
/// **Database Table**: `goalTerms`
/// **FK**: `timePeriodId` → `timePeriods.id`
///
/// **Purpose**: Planning container for goals with state and reflection.
///
/// Unlike pure TimePeriods (chronological facts), GoalTerms have:
/// - Planning state (active, delayed, completed)
/// - Theme and focus area
/// - Reflection after completion
/// - Association with goals (via termGoalAssignments)
///
/// **Architecture**:
/// - TimePeriod stores chronological boundaries (start/end dates)
/// - GoalTerm stores planning semantics (theme, status, reflection)
/// - This separation allows calendar periods to exist without goal planning
///
/// **Example**:
/// ```swift
/// // First create the temporal boundary
/// let period = TimePeriod.tenWeeks(
///     from: Date("2025-03-01"),
///     title: "Term 5 Period"
/// )
///
/// // Then create the goal term with planning semantics
/// let term = GoalTerm(
///     timePeriodId: period.id,
///     termNumber: 5,
///     theme: "Health and momentum",
///     status: .active
/// )
/// ```
@Table
public struct GoalTerm: DomainBasic {
    // MARK: - Identity

    public var id: UUID

    // MARK: - FK to Temporal Period

    /// References the temporal boundaries (start/end dates)
    /// FK to timePeriods.id
    public var timePeriodId: UUID

    // MARK: - Planning Semantics

    /// Sequential term number (Term 1, Term 2, Term 5...)
    public var termNumber: Int

    /// Optional focus area or theme for this term
    /// Example: "Health and relationships", "Career growth"
    public var theme: String?

    /// Optional reflection written after term completion
    /// Example: "Learned: need better time blocking for morning workouts"
    public var reflection: String?

    /// Current status of this planning term
    /// Example: .active, .delayed, .completed
    public var status: TermStatus?

    // MARK: - Initialization

    /// Create a new goal term
    ///
    /// - Parameters:
    ///   - timePeriodId: FK to the temporal period defining start/end dates
    ///   - termNumber: Sequential number (Term 5)
    ///   - theme: Optional focus area
    ///   - reflection: Optional post-term reflection
    ///   - status: Planning state
    ///   - id: Unique identifier
    public init(
        timePeriodId: UUID,
        termNumber: Int,
        theme: String? = nil,
        reflection: String? = nil,
        status: TermStatus? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.timePeriodId = timePeriodId
        self.termNumber = termNumber
        self.theme = theme
        self.reflection = reflection
        self.status = status
    }
}

// MARK: - Relationships
//
// JOIN queries defined in TermsQuery.swift for efficient data fetching
//
// Usage pattern (see TermsWithPeriods in TermsQuery.swift):
//   GoalTerm.all
//     .order(by: \.termNumber, .descending)
//     .including(required: GoalTerm.timePeriod)
//     .map { term, timePeriod in TermWithPeriod(term: term, timePeriod: timePeriod) }
//
// This enables efficient single-query fetches instead of N+1 queries
// See sqlite-data-main/Examples/Reminders/Schema.swift for similar patterns
