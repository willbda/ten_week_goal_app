//
// ActionWithDetails.swift
// Created on 2025-11-10
//
// PURPOSE: Wrapper types for Action with measurements and goal contributions
// ARCHITECTURE: Part of Models layer (NOT Views or Services layer)
// USAGE: Returned by ActionRepository, passed to ActionRowView
//

import Foundation

/// Wrapper combining Action with its measurements and goal contributions
///
/// Fetched efficiently via bulk queries in ActionRepository.
/// Passed to ActionRowView to avoid N+1 queries in list display.
public struct ActionWithDetails: Identifiable, Hashable, Sendable {
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

/// Helper: MeasuredAction with its Measure
public struct ActionMeasurement: Identifiable, Hashable, Sendable {
    public let measuredAction: MeasuredAction
    public let measure: Measure
    public var id: UUID { measuredAction.id }

    public init(measuredAction: MeasuredAction, measure: Measure) {
        self.measuredAction = measuredAction
        self.measure = measure
    }
}

/// Helper: ActionGoalContribution with its Goal
public struct ActionContribution: Identifiable, Hashable, Sendable {
    public let contribution: ActionGoalContribution
    public let goal: Goal
    public var id: UUID { contribution.id }

    public init(contribution: ActionGoalContribution, goal: Goal) {
        self.contribution = contribution
        self.goal = goal
    }
}