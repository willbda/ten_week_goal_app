// Goal.swift
// Subtype of Expectation representing goals with date ranges
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (consolidated Goal/SmartGoal, removed Doable properties)
// Updated by Claude Code on 2025-10-28 (decomposed into Goal + ExpectationMeasure)
// Updated by Claude Code on 2025-10-31 (converted to Expectation subtype for 3NF)
// Ported from Python implementation (python/categoriae/goals.py)
//
// ARCHITECTURE:
// - Expectation: Base table with shared fields (title, description, priority)
// - Goal: Subtype table with FK to expectations.id
// - ExpectationMeasure: Measurable targets (0 to many per goal)
// - Classification (minimal, measured, SMART): Determined by services
//
// A goal can be:
// - Minimal: Just narrative, no metrics (e.g., "Get healthier")
// - Measured: Narrative + metrics (e.g., "Run 120km in 10 weeks")
// - SMART: Measured + complete metadata (dates, action plan, value alignment)

import Foundation
import SQLiteData

// MARK: - Goal Struct

/// Goal subtype - objectives with date ranges and action plans
///
/// **Database Table**: `goals`
/// **FK**: `expectationId` → `expectations.id`
///
/// **Purpose**: Track personal objectives over time
///
/// Goals have date ranges (startDate→targetDate) and action plans.
/// Unlike milestones (single checkpoint) or obligations (external deadline),
/// goals represent self-directed work over a period of time.
///
/// **3NF Design**:
/// - Base fields (title, description) in Expectation
/// - Goal-specific fields (dates, plan) in Goal
/// - Measurements in ExpectationMeasure junction table
/// - No redundant data
///
/// **Example**:
/// ```swift
/// // First create the base expectation
/// let expectation = Expectation(
///     title: "Spring into Running",
///     detailedDescription: "Build running habit and endurance",
///     expectationType: .goal,
///     expectationImportance: 8,  // Self-directed, high importance
///     expectationUrgency: 5       // Flexible timing, medium urgency
/// )
///
/// // Then create the goal subtype
/// let goal = Goal(
///     expectationId: expectation.id,
///     startDate: Date("2025-03-01"),
///     targetDate: Date("2025-05-10"),
///     actionPlan: "Run 3x/week, increase 10% weekly",
///     expectedTermLength: 10
/// )
///
/// // Add measurements via ExpectationMeasure:
/// ExpectationMeasure(expectationId: expectation.id, measureId: km, targetValue: 120.0)
/// ```
@Table
public struct Goal: DomainBasic {
    // MARK: - Identity

    /// Unique identifier for this goal record
    public var id: UUID

    // MARK: - Foreign Key to Base

    /// References the base expectation
    /// FK to expectations.id
    public var expectationId: UUID

    // MARK: - Temporal Bounds

    /// When to start working on this goal
    public var startDate: Date?

    /// When this goal should be achieved
    public var targetDate: Date?

    // MARK: - Implementation Metadata

    /// How you plan to achieve this goal
    /// Examples: "Run 3x/week", "Study 1hr daily", "Practice with mentor weekly"
    public var actionPlan: String?

    /// Expected planning horizon in weeks
    /// Typically 10 (for 10-week terms) but can vary
    public var expectedTermLength: Int?

    // MARK: - Initialization

    /// Create a new goal
    ///
    /// - Parameters:
    ///   - expectationId: FK to base expectation
    ///   - startDate: When to start working on this
    ///   - targetDate: When this should be achieved
    ///   - actionPlan: How to achieve this goal
    ///   - expectedTermLength: Planning horizon in weeks
    ///   - id: Unique identifier (auto-generated if not provided)
    public init(
        expectationId: UUID,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        actionPlan: String? = nil,
        expectedTermLength: Int? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.expectationId = expectationId
        self.startDate = startDate
        self.targetDate = targetDate
        self.actionPlan = actionPlan
        self.expectedTermLength = expectedTermLength
    }
}
