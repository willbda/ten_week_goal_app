// InferenceService.swift
// Coordination service for inferring action-goal relationships
//
// Written by Claude Code on 2025-10-22
// Ported from Python implementation (python/ethica/inference_service.py)
//
// This is a COORDINATION LAYER that:
// - Uses MatchingService for stateless matching logic
// - Creates ActionGoalRelationship objects
// - Filters relationships by confidence
// - Provides manual relationship management
//
// Thread-safe via actor isolation (Swift 6 concurrency)

import Foundation
import Models

/// Thread-safe service for inferring and managing action-goal relationships
///
/// **Pattern**: Actor provides isolated state for batch processing while delegating
/// matching logic to stateless MatchingService functions.
///
/// **Usage Example**:
/// ```swift
/// let service = InferenceService()
/// let relationships = await service.inferMatches(
///     actions: allActions,
///     goals: allGoals,
///     requirePeriodMatch: true
/// )
/// let (confident, ambiguous) = await service.filterAmbiguous(relationships)
/// ```
public actor InferenceService {

    // MARK: - Initialization

    public init() {}

    // MARK: - Batch Inference

    /// Automatically infer which actions contribute to which goals
    ///
    /// Applies matching criteria (period + actionability) and creates
    /// ActionGoalRelationship objects for all valid matches.
    ///
    /// - Parameters:
    ///   - actions: List of actions to match
    ///   - goals: List of active goals
    ///   - requirePeriodMatch: If true, only match actions within goal period
    ///
    /// - Returns: List of ActionGoalRelationship objects with auto-inferred relationships
    ///
    /// **Matching Strategy** (all criteria must pass):
    /// 1. Period: Action during goal timeframe (if goal has dates)
    /// 2. Actionability: Action has correct unit AND description contains required keywords
    ///
    /// **Example**:
    /// - 100 actions × 10 goals = up to 1000 potential matches
    /// - Returns ~20 high-confidence matches after filtering
    public func inferMatches(
        actions: [Action],
        goals: [Goal],
        requirePeriodMatch: Bool = true
    ) async -> [ActionGoalRelationship] {
        var relationships: [ActionGoalRelationship] = []

        for action in actions {
            for goal in goals {
                // Criterion 1: Period match
                let periodMatch = MatchingService.matchesOnPeriod(action: action, goal: goal)
                if requirePeriodMatch && !periodMatch {
                    continue
                }

                // Criterion 2: Actionability match (unit + keywords)
                let (actionabilityMatch, contribution) = MatchingService.matchesWithActionability(
                    action: action,
                    goal: goal
                )
                if !actionabilityMatch {
                    continue
                }

                // Calculate confidence
                let confidence = MatchingService.calculateConfidence(
                    periodMatch: periodMatch,
                    actionabilityMatch: actionabilityMatch
                )

                // Create relationship
                let relationship = ActionGoalRelationship(
                    actionId: action.id,
                    goalId: goal.id,
                    contribution: contribution ?? 0.0,
                    matchMethod: .autoInferred,
                    confidence: confidence,
                    matchedOn: buildMatchCriteria(
                        periodMatch: periodMatch,
                        actionabilityMatch: actionabilityMatch
                    )
                )

                relationships.append(relationship)
            }
        }

        return relationships
    }

    /// Build list of match criteria that were satisfied
    private func buildMatchCriteria(
        periodMatch: Bool,
        actionabilityMatch: Bool
    ) -> [ActionGoalRelationship.MatchCriteria] {
        var criteria: [ActionGoalRelationship.MatchCriteria] = []

        if periodMatch {
            criteria.append(.period)
        }

        // Actionability implies both unit and description match
        if actionabilityMatch {
            criteria.append(.unit)
            criteria.append(.description)
        }

        return criteria
    }

    // MARK: - Filtering

    /// Separate high-confidence matches from ambiguous ones needing user confirmation
    ///
    /// - Parameters:
    ///   - relationships: List of all inferred matches
    ///   - confidenceThreshold: Confidence level above which matches are accepted (default 0.7)
    ///
    /// - Returns: Tuple of (confident matches, ambiguous matches)
    ///
    /// **Example**:
    /// - Input: 50 relationships with confidence ranging 0.3-0.9
    /// - Output: (35 confident, 15 ambiguous) with threshold 0.7
    public func filterAmbiguous(
        _ relationships: [ActionGoalRelationship],
        confidenceThreshold: Double = 0.7
    ) async -> (confident: [ActionGoalRelationship], ambiguous: [ActionGoalRelationship]) {
        let confident = relationships.filter { $0.confidence >= confidenceThreshold }
        let ambiguous = relationships.filter { $0.confidence < confidenceThreshold }

        return (confident: confident, ambiguous: ambiguous)
    }

    // MARK: - Manual Relationship Management

    /// Create a manual relationship when user explicitly assigns action to goal
    ///
    /// - Parameters:
    ///   - action: The action to assign
    ///   - goal: The goal to assign it to
    ///   - contribution: Optional override for contribution amount
    ///                   (if nil, infers from measurements)
    ///
    /// - Returns: ActionGoalRelationship with method='manual' and confidence=1.0
    ///
    /// **Example**:
    /// - User sees action "Morning run" and goal "Marathon training"
    /// - User clicks "Add to goal"
    /// - Creates manual relationship with full confidence
    public func createManualRelationship(
        action: Action,
        goal: Goal,
        contribution: Double? = nil
    ) async -> ActionGoalRelationship {
        // Infer contribution if not provided
        let finalContribution: Double
        if let provided = contribution {
            finalContribution = provided
        } else {
            let (_, _, inferred) = MatchingService.matchesOnUnit(action: action, goal: goal)
            finalContribution = inferred ?? 0.0
        }

        return ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: finalContribution,
            matchMethod: .manual,
            confidence: 1.0,
            matchedOn: [] // Manual assignments don't track match criteria
        )
    }

    /// Convert an auto-inferred relationship to user-confirmed
    ///
    /// - Parameter relationship: Auto-inferred relationship to confirm
    ///
    /// - Returns: New ActionGoalRelationship with method='user_confirmed' and confidence=1.0
    ///
    /// **Example**:
    /// - System suggests: "Yoga class" → "Flexibility goal" (confidence 0.8)
    /// - User reviews and clicks "Confirm"
    /// - Creates confirmed relationship with full confidence
    public func confirmRelationship(
        _ relationship: ActionGoalRelationship
    ) async -> ActionGoalRelationship {
        return ActionGoalRelationship(
            id: relationship.id, // Preserve ID to replace original
            actionId: relationship.actionId,
            goalId: relationship.goalId,
            contribution: relationship.contribution,
            matchMethod: .userConfirmed,
            confidence: 1.0,
            matchedOn: relationship.matchedOn
        )
    }
}
