//
// ActionsQuery.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Efficient multi-model query for Actions with measurements and goal contributions
// ARCHITECTURE: FetchKeyRequest pattern from SQLiteData for performant JOIN queries
//

import Foundation
import Models
import SQLiteData

// MARK: - Wrapper Types

/// Combines Action with its related Measure details
///
/// Holds action, measurement value, and the measure catalog entry.
/// Returned from ActionsWithMeasuresAndGoals query.
public struct ActionMeasurement: Identifiable, Sendable {
    public let measuredAction: MeasuredAction
    public let measure: Measure
    public var id: UUID { measuredAction.id }

    public init(measuredAction: MeasuredAction, measure: Measure) {
        self.measuredAction = measuredAction
        self.measure = measure
    }
}

/// Combines Action with its related Goal details
///
/// Holds contribution record and the goal it contributes toward.
/// Returned from ActionsWithMeasuresAndGoals query.
public struct ActionContribution: Identifiable, Sendable {
    public let contribution: ActionGoalContribution
    public let goal: Goal
    public var id: UUID { contribution.id }

    public init(contribution: ActionGoalContribution, goal: Goal) {
        self.contribution = contribution
        self.goal = goal
    }
}

/// Combines Action with all its measurements and goal contributions
///
/// Top-level wrapper returned by ActionsWithMeasuresAndGoals query.
/// Ready for display in list views without additional database access.
///
/// **Usage**:
/// ```swift
/// @Fetch(ActionsWithMeasuresAndGoals())
/// private var actions: [ActionWithDetails]
///
/// ForEach(actions) { actionDetails in
///     ActionRowView(actionDetails: actionDetails)
/// }
/// ```
public struct ActionWithDetails: Identifiable, Sendable {
    public let action: Action
    public let measurements: [ActionMeasurement]
    public let contributions: [ActionContribution]
    public var id: UUID { action.id }

    public init(
        action: Action,
        measurements: [ActionMeasurement] = [],
        contributions: [ActionContribution] = []
    ) {
        self.action = action
        self.measurements = measurements
        self.contributions = contributions
    }
}

// MARK: - Query Implementation

/// Fetches Actions with measurements and goal contributions via efficient JOIN
///
/// **Performance**: Single compound query with LEFT JOINs (no N+1 problem)
/// **Reactivity**: Works with @Fetch for automatic UI updates
///
/// **Query Strategy**:
/// 1. Fetch all actions ordered by logTime DESC
/// 2. For each action, fetch related MeasuredActions + Measures (LEFT JOIN)
/// 3. For each action, fetch related ActionGoalContributions + Goals (LEFT JOIN)
/// 4. Group by action.id to assemble ActionWithDetails
///
/// **Note**: This implementation does multiple passes for clarity.
/// Could be optimized to a single complex query if performance becomes critical.
public struct ActionsWithMeasuresAndGoals: FetchKeyRequest {
    public typealias Value = [ActionWithDetails]

    public init() {}

    public func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // 1. Fetch all actions ordered by most recent first
        let actions = try Action.all
            .order { $0.logTime.desc() }
            .fetchAll(db)

        // 2. For each action, fetch measurements + measures
        var actionsWithDetails: [ActionWithDetails] = []

        for action in actions {
            // Fetch measurements for this action
            // Pattern from Reminders: Use type directly, not .all
            let measurementResults = try MeasuredAction
                .where { $0.actionId.eq(action.id) }
                .join(Measure.all) { $0.measureId.eq($1.id) }
                .fetchAll(db)

            let measurements = measurementResults.map { (measuredAction, measure) in
                ActionMeasurement(measuredAction: measuredAction, measure: measure)
            }

            // Fetch goal contributions for this action
            // Pattern from Reminders: Use type directly, not .all
            let contributionResults = try ActionGoalContribution
                .where { $0.actionId.eq(action.id) }
                .join(Goal.all) { $0.goalId.eq($1.id) }
                .fetchAll(db)

            let contributions = contributionResults.map { (contribution, goal) in
                ActionContribution(contribution: contribution, goal: goal)
            }

            // Assemble ActionWithDetails
            actionsWithDetails.append(
                ActionWithDetails(
                    action: action,
                    measurements: measurements,
                    contributions: contributions
                )
            )
        }

        return actionsWithDetails
    }
}

// MARK: - Alternative: Single-Action Query

/// Fetches a single Action with its details by ID
///
/// Use this for edit mode when you need to load specific action.
///
/// **Usage**:
/// ```swift
/// let actionDetails = try await ActionWithDetailsById(id: actionId).fetch(db)
/// ```
public struct ActionWithDetailsById: FetchKeyRequest {
    public typealias Value = ActionWithDetails?

    public let actionId: UUID

    public init(id: UUID) {
        self.actionId = id
    }

    public func fetch(_ db: Database) throws -> ActionWithDetails? {
        // 1. Fetch the action
        guard let action = try Action.find(actionId).fetchOne(db) else {
            return nil
        }

        // 2. Fetch measurements
        // Pattern from Reminders: Use type directly, not .all
        let measurementResults = try MeasuredAction
            .where { $0.actionId.eq(actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        let measurements = measurementResults.map { (measuredAction, measure) in
            ActionMeasurement(measuredAction: measuredAction, measure: measure)
        }

        // 3. Fetch contributions
        // Pattern from Reminders: Use type directly, not .all
        let contributionResults = try ActionGoalContribution
            .where { $0.actionId.eq(actionId) }
            .join(Goal.all) { $0.goalId.eq($1.id) }
            .fetchAll(db)

        let contributions = contributionResults.map { (contribution, goal) in
            ActionContribution(contribution: contribution, goal: goal)
        }

        return ActionWithDetails(
            action: action,
            measurements: measurements,
            contributions: contributions
        )
    }
}
