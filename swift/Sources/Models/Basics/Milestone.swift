// Milestone.swift
// Subtype of Expectation representing point-in-time checkpoints
//
// Written by Claude Code on 2025-10-31
//
// ARCHITECTURE:
// - References base Expectation entity (FK)
// - Adds milestone-specific fields (just targetDate)
// - Simple subtype - minimal overhead
//
// USAGE:
// Milestones are checkpoints, not ranges:
// - "Hit 50km by week 5"
// - "Complete chapter 3 by Nov 15"
// - "Reach intermediate level by June"

import Foundation
import SQLiteData

/// Milestone subtype - point-in-time checkpoint
///
/// **Database Table**: `milestones`
/// **FK**: `expectationId` → `expectations.id`
///
/// **Purpose**: Mark specific moments/checkpoints
///
/// Unlike goals (which have date ranges startDate→targetDate),
/// milestones mark a single point in time when something should be achieved.
///
/// **Example**:
/// ```swift
/// // First create the base expectation
/// let expectation = Expectation(
///     title: "Reach 50km total distance",
///     expectationType: .milestone,
///     expectationImportance: 5,  // Progress checkpoint, medium importance
///     expectationUrgency: 8       // Time-sensitive marker, high urgency
/// )
///
/// // Then create the milestone subtype
/// let milestone = Milestone(
///     expectationId: expectation.id,
///     targetDate: Date("2025-04-15")
/// )
///
/// // Can still use ExpectationMeasure for measurement:
/// ExpectationMeasure(
///     expectationId: expectation.id,  // Works for all expectation types!
///     measureId: kilometersMetric.id,
///     targetValue: 50.0
/// )
/// ```
@Table
public struct Milestone: DomainBasic {
    // MARK: - Identity

    /// Unique identifier for this milestone record
    public var id: UUID

    // MARK: - Foreign Key to Base

    /// References the base expectation
    /// FK to expectations.id
    public var expectationId: UUID

    // MARK: - Milestone-specific Fields

    /// When this checkpoint should be reached
    /// This is the defining characteristic of a milestone - a single point in time
    public var targetDate: Date

    // MARK: - Initialization

    /// Create a new milestone
    ///
    /// - Parameters:
    ///   - expectationId: FK to base expectation
    ///   - targetDate: When this checkpoint should be reached
    ///   - id: Unique identifier (auto-generated if not provided)
    public init(
        expectationId: UUID,
        targetDate: Date,
        id: UUID = UUID()
    ) {
        self.id = id
        self.expectationId = expectationId
        self.targetDate = targetDate
    }
}
