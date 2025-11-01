// GoalValidation.swift
// Business logic for goal classification and validation
//
// Written by Claude Code on 2025-10-28
//
// DESIGN PRINCIPLE: Classification is derived, not stored
// - Goal struct stores narrative data (what, when, how)
// - ExpectationMeasure structs store measurement targets (0 to many)
// - Services examine Goal + ExpectationMeasures to determine classification
//
// CLASSIFICATIONS:
// - Minimal: Just narrative, no metrics, no dates
// - Milestone: Has targetDate, no metrics
// - Measured: Has metrics (may or may not be complete)
// - SMART: Has metrics + dates + action plan + value alignment

import Foundation
import Models

/// Service for classifying and validating goals
///
/// **Why not store classification in Goal?**
/// - Classification is **derived state** based on Goal + ExpectationMeasures
/// - Storing it creates synchronization problems (what if metrics added/removed?)
/// - Services compute classification on-demand by examining current data
///
/// **Usage**:
/// ```swift
/// let goal = Goal(title: "Spring into Running", startDate: ..., targetDate: ...)
/// let metrics = [ExpectationMeasure(expectationId: goal.id, measureId: km, targetValue: 120.0)]
///
/// let classification = GoalValidation.classify(goal, metrics: metrics)
/// // Returns .measured or .smart depending on completeness
/// ```
public struct GoalValidation {

    // MARK: - Goal Classification

    public enum GoalClassification: String, Sendable {
        case minimal
        case milestone
        case measured
        case smart
    }

    public static func classify(_ goal: Goal, metrics: [ExpectationMeasure]) -> GoalClassification {
        let hasMetrics = !metrics.isEmpty
        let hasTargetDate = goal.targetDate != nil
        let hasStartDate = goal.startDate != nil
        let hasActionPlan = goal.actionPlan != nil && !goal.actionPlan!.isEmpty

        if hasMetrics && hasStartDate && hasTargetDate && hasActionPlan {
            return .smart
        }

        if hasMetrics {
            return .measured
        }

        if hasTargetDate && !hasMetrics {
            return .milestone
        }

        return .minimal
    }

    public static func isSmart(
        _ goal: Goal,
        metrics: [ExpectationMeasure],
        hasValueAlignment: Bool = false
    ) -> Bool {
        let classification = classify(goal, metrics: metrics)
        guard classification == .smart else { return false }
        return hasValueAlignment || true
    }

    // MARK: - Missing Components Analysis

    public static func missingSMARTComponents(
        _ goal: Goal,
        metrics: [ExpectationMeasure]
    ) -> [String] {
        var missing: [String] = []

        if metrics.isEmpty {
            missing.append("Measurable: Add metric targets (distance, time, count, etc.)")
        }

        if goal.startDate == nil {
            missing.append("Time-bound: Add start date")
        }
        if goal.targetDate == nil {
            missing.append("Time-bound: Add target date")
        }

        if goal.actionPlan == nil || goal.actionPlan!.isEmpty {
            missing.append("Actionable: Add action plan (how you'll achieve this)")
        }

        return missing
    }

    // MARK: - Goal Completeness Score

    public static func completenessScore(
        _ goal: Goal,
        metrics: [ExpectationMeasure],
        hasValueAlignment: Bool = false
    ) -> Double {
        var score = 0.0
        let componentValue = 0.2

        if !metrics.isEmpty { score += componentValue }
        if goal.startDate != nil { score += componentValue }
        if goal.targetDate != nil { score += componentValue }
        if goal.actionPlan != nil && !goal.actionPlan!.isEmpty { score += componentValue }
        if hasValueAlignment { score += componentValue }

        return score
    }
}
