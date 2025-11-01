// Obligation.swift
// Subtype of Expectation representing external commitments
//
// Written by Claude Code on 2025-10-31
//
// ARCHITECTURE:
// - References base Expectation entity (FK)
// - Adds obligation-specific fields (deadline, context)
// - Represents external accountability
//
// USAGE:
// Obligations are things requested by others:
// - "Submit quarterly report by Friday"
// - "Review colleague's work by EOD"
// - "Prepare presentation for board meeting"

import Foundation
import SQLiteData

/// Obligation subtype - external commitment or requirement
///
/// **Database Table**: `obligations`
/// **FK**: `expectationId` → `expectations.id`
///
/// **Purpose**: Track external commitments and requirements
///
/// Obligations differ from goals in that they:
/// - Come from external parties (not self-generated)
/// - Have deadlines (not date ranges)
/// - Often have consequences if missed
/// - Typically higher priority due to external accountability
///
/// **Example**:
/// ```swift
/// // First create the base expectation
/// let expectation = Expectation(
///     title: "Submit quarterly report",
///     expectationType: .obligation,
///     expectationImportance: 2,  // External commitment, low importance to you
///     expectationUrgency: 6       // Fixed deadline, moderately high urgency
/// )
///
/// // Then create the obligation subtype
/// let obligation = Obligation(
///     expectationId: expectation.id,
///     deadline: Date("2025-04-30"),
///     requestedBy: "Board of Directors",
///     consequence: "Delays grant disbursement"
/// )
/// ```
@Table
public struct Obligation: DomainBasic {
    // MARK: - Identity

    /// Unique identifier for this obligation record
    public var id: UUID

    // MARK: - Foreign Key to Base

    /// References the base expectation
    /// FK to expectations.id
    public var expectationId: UUID

    // MARK: - Obligation-specific Fields

    /// When this obligation is due
    /// Unlike goals (which have startDate→targetDate ranges),
    /// obligations have a single deadline
    public var deadline: Date

    /// Who requested this or to whom you're accountable
    /// Examples: "Board of Directors", "Manager", "Client Name"
    public var requestedBy: String?

    /// What happens if this obligation is missed
    /// Examples: "Delays grant", "Breach of contract", "Team blocked"
    public var consequence: String?

    // MARK: - Initialization

    /// Create a new obligation
    ///
    /// - Parameters:
    ///   - expectationId: FK to base expectation
    ///   - deadline: When this is due
    ///   - requestedBy: Who requested this
    ///   - consequence: What happens if missed
    ///   - id: Unique identifier (auto-generated if not provided)
    public init(
        expectationId: UUID,
        deadline: Date,
        requestedBy: String? = nil,
        consequence: String? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.expectationId = expectationId
        self.deadline = deadline
        self.requestedBy = requestedBy
        self.consequence = consequence
    }
}
