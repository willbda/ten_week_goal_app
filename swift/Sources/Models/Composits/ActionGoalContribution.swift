// ActionGoalContribution.swift
// Junction table tracking how actions contribute to goals
//
// Written by Claude Code on 2025-10-30
//
// ARCHITECTURE:
// - Pure junction table (database artifact)
// - Links Actions to Goals they contribute toward
// - Tracks contribution amounts and which metric was advanced
// - Enables progress calculation and contribution analysis
//
// 3NF COMPLIANCE:
// - Separates action-goal relationships from entity tables
// - Enables many-to-many relationships (actions can serve multiple goals)
// - References metrics catalog for type safety

import Foundation
import SQLiteData

/// Tracks how an action contributes to a goal's progress
///
/// **Database Table**: `actionGoalContributions`
/// **Purpose**: Record which actions advance which goals
///
/// **Design Principle**: This is a pure junction table that links Actions
/// to the Goals they help achieve. It's always accessed in the context of
/// calculating progress or analyzing contributions.
///
/// **Why separate from Action?**
/// - Actions can contribute to 0 to many goals
/// - Goals can receive contributions from many actions
/// - Enables queries: "All actions contributing to goal X"
/// - Supports progress tracking with specific amounts
///
/// **Usage**:
/// ```swift
/// // Record that a run contributed 5.2km toward a running goal
/// let contribution = ActionGoalContribution(
///     actionId: morningRun.id,
///     goalId: marathonGoal.id,
///     contributionAmount: 5.2,
///     measureId: kilometersMetric.id
/// )
///
/// // Record that same action also contributed to health goal
/// let healthContribution = ActionGoalContribution(
///     actionId: morningRun.id,
///     goalId: healthGoal.id,
///     contributionAmount: 1.0,  // 1 occasion
///     measureId: occasionsMetric.id
/// )
/// ```
@Table
public struct ActionGoalContribution: DomainComposit {
    // MARK: - Identity

    /// Unique identifier (required by SQLiteData)
    public var id: UUID

    // MARK: - Relationship Fields

    /// The action making the contribution
    public var actionId: UUID

    /// The goal receiving the contribution
    public var goalId: UUID

    /// Amount contributed (in the metric's units)
    /// Example: 5.2 for 5.2km toward a distance goal
    public var contributionAmount: Double?

    /// Which metric this contribution is measured in
    /// References the metrics catalog for unit consistency
    public var measureId: UUID?

    /// When this contribution was recorded
    /// Usually matches action's logTime, but can differ for retroactive assignments
    public var createdAt: Date

    // MARK: - Initialization

    /// Create a new action-goal contribution
    ///
    /// - Parameters:
    ///   - actionId: The contributing action
    ///   - goalId: The goal being advanced
    ///   - contributionAmount: How much was contributed
    ///   - measureId: Which metric (from catalog)
    ///   - createdAt: When recorded (defaults to now)
    ///   - id: Unique identifier
    public init(
        actionId: UUID,
        goalId: UUID,
        contributionAmount: Double? = nil,
        measureId: UUID? = nil,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.actionId = actionId
        self.goalId = goalId
        self.contributionAmount = contributionAmount
        self.measureId = measureId
        self.createdAt = createdAt
    }
}
