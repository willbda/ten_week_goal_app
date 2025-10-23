// MatchingService.swift
// Business logic for matching actions to goals
//
// Written by Claude Code on 2025-10-22
// Ported from Python implementation (python/ethica/progress_matching.py)
//
// This is BUSINESS LOGIC, not infrastructure. Contains domain rules for:
// - Period matching: Is action within goal timeframe?
// - Unit matching: Does measurement align with goal target?
// - Actionability matching: Do keywords indicate relevance?
//
// All functions are pure (no side effects) and can be tested without a database.

import Foundation
import Models

/// Stateless matching functions for determining action-goal relationships
///
/// **Pattern**: Business logic operates ON entities, uses pure functions with
/// no side effects, and can be fully tested without touching a database.
///
/// **Usage Example**:
/// ```swift
/// let periodMatch = MatchingService.matchesOnPeriod(action: myAction, goal: myGoal)
/// let (unitMatch, key, value) = MatchingService.matchesOnUnit(action: myAction, goal: myGoal)
/// let (actionableMatch, contribution) = MatchingService.matchesWithActionability(
///     action: myAction,
///     goal: myGoal
/// )
/// let confidence = MatchingService.calculateConfidence(
///     periodMatch: periodMatch,
///     actionabilityMatch: actionableMatch
/// )
/// ```
public struct MatchingService {

    // MARK: - Period Matching

    /// Check if action occurred during goal's active period
    ///
    /// - Parameters:
    ///   - action: Action with logTime
    ///   - goal: Goal with startDate/targetDate (or no dates for loose goals)
    ///
    /// - Returns: `true` if action is within goal period, or goal has no period constraint
    ///
    /// **Examples**:
    /// - Action on Oct 15, Goal Oct 1-31 → true
    /// - Action on Nov 5, Goal Oct 1-31 → false
    /// - Action on Oct 15, Goal with no dates → true
    public static func matchesOnPeriod(action: Action, goal: Goal) -> Bool {
        // Goals without dates accept all actions
        guard let startDate = goal.startDate else { return true }
        guard let targetDate = goal.targetDate else { return true }

        // Check if action falls within period
        return startDate <= action.logTime && action.logTime <= targetDate
    }

    // MARK: - Unit Matching

    /// Check if action has measurements compatible with goal's target unit
    ///
    /// - Parameters:
    ///   - action: Action with optional measuresByUnit dict
    ///   - goal: Goal with measurementUnit
    ///
    /// - Returns: Tuple of `(matched, matchedKey, value)`:
    ///   - `matched`: True if action has compatible measurement
    ///   - `matchedKey`: The measurement key that matched (e.g., "distance_km")
    ///   - `value`: The measurement value (e.g., 5.0)
    ///
    /// **Examples**:
    /// - Action: `{"distance_km": 5.0}`, Goal unit: "km" → (true, "distance_km", 5.0)
    /// - Action: `{"minutes": 30}`, Goal unit: "km" → (false, nil, nil)
    /// - Action: no measurements, Goal unit: "km" → (false, nil, nil)
    public static func matchesOnUnit(action: Action, goal: Goal) -> (Bool, String?, Double?) {
        guard let measurements = action.measuresByUnit,
              let goalUnit = goal.measurementUnit else {
            return (false, nil, nil)
        }

        // Normalize goal unit (lowercase, replace spaces with underscores)
        let normalizedGoalUnit = goalUnit.lowercased().replacingOccurrences(of: " ", with: "_")

        // Look for measurement keys containing the goal unit
        for (key, value) in measurements {
            if key.lowercased().contains(normalizedGoalUnit) {
                return (true, key, value)
            }
        }

        return (false, nil, nil)
    }

    // MARK: - Actionability Matching

    /// Structure for parsed actionability hints from goal.howGoalIsActionable JSON
    ///
    /// **Format**: `{"units": ["minutes", "km"], "keywords": ["yoga", "run*"]}`
    private struct ActionabilityHints: Codable {
        let units: [String]
        let keywords: [String]
    }

    /// Check if action matches goal using structured howGoalIsActionable hints
    ///
    /// Parses goal's `howGoalIsActionable` JSON (format: `{"units": [...], "keywords": [...]}`)
    /// and checks BOTH:
    /// 1. Action has measurement matching allowed units
    /// 2. Action description contains required keywords
    ///
    /// This prevents false positives like:
    /// - Yoga actions matching writing goals (both use minutes)
    /// - Walking actions matching running goals (both use km)
    ///
    /// - Parameters:
    ///   - action: Action with measurements and title
    ///   - goal: Goal with howGoalIsActionable JSON field
    ///
    /// - Returns: Tuple of `(matched, contribution)`:
    ///   - `matched`: True if both unit and keyword match
    ///   - `contribution`: Measurement value if matched, nil otherwise
    ///
    /// **Examples**:
    /// - Goal: `{"units": ["minutes"], "keywords": ["yoga", "pilates"]}`
    ///   Action: "Yoga class" with `{"minutes": 30}` → (true, 30.0)
    /// - Goal: `{"units": ["minutes"], "keywords": ["write", "revise"]}`
    ///   Action: "Yoga class" with `{"minutes": 30}` → (false, nil) // Wrong keywords
    public static func matchesWithActionability(action: Action, goal: Goal) -> (Bool, Double?) {
        // If no actionability hints, fall back to simple unit matching
        guard let actionabilityJSON = goal.howGoalIsActionable,
              !actionabilityJSON.isEmpty else {
            let (matched, _, contribution) = matchesOnUnit(action: action, goal: goal)
            return (matched, contribution)
        }

        // Parse JSON hints
        let hints: ActionabilityHints
        do {
            guard let data = actionabilityJSON.data(using: .utf8) else {
                // Can't convert to Data - fall back to unit matching
                let (matched, _, contribution) = matchesOnUnit(action: action, goal: goal)
                return (matched, contribution)
            }
            hints = try JSONDecoder().decode(ActionabilityHints.self, from: data)
        } catch {
            // Malformed JSON - fall back to unit matching
            let (matched, _, contribution) = matchesOnUnit(action: action, goal: goal)
            return (matched, contribution)
        }

        // Normalize units and keywords
        let allowedUnits = hints.units.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        let requiredKeywords = hints.keywords.map {
            $0.lowercased()
              .trimmingCharacters(in: .whitespaces)
              .replacingOccurrences(of: "*", with: "")
              .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }

        // Empty hints - fall back to unit matching
        if allowedUnits.isEmpty || requiredKeywords.isEmpty {
            let (matched, _, contribution) = matchesOnUnit(action: action, goal: goal)
            return (matched, contribution)
        }

        // Check 1: Does action have measurement matching allowed units?
        guard let measurements = action.measuresByUnit else {
            return (false, nil)
        }

        var contribution: Double? = nil
        for (key, value) in measurements {
            if allowedUnits.contains(key.lowercased()) {
                contribution = value
                break
            }
        }

        guard contribution != nil else {
            return (false, nil)
        }

        // Check 2: Does action description contain required keywords?
        guard let title = action.title else {
            return (false, nil)
        }

        let titleLower = title.lowercased()
        let keywordMatched = requiredKeywords.contains { titleLower.contains($0) }

        if !keywordMatched {
            return (false, nil)
        }

        // Both checks passed!
        return (true, contribution)
    }

    // MARK: - Confidence Calculation

    /// Calculate overall match confidence based on which criteria matched
    ///
    /// - Parameters:
    ///   - periodMatch: Whether action occurred during goal's timeframe
    ///   - actionabilityMatch: Whether action matched goal's actionability criteria
    ///
    /// - Returns: Confidence score 0.0-1.0
    ///
    /// **Scoring**:
    /// - Period + Actionability = 0.9 (high confidence)
    /// - Actionability validates both unit AND keyword requirements
    public static func calculateConfidence(
        periodMatch: Bool,
        actionabilityMatch: Bool
    ) -> Double {
        // High confidence for period + actionability match
        // (Actionability already validates both unit and keyword requirements)
        if periodMatch && actionabilityMatch {
            return 0.9
        }

        // Lower confidence for partial matches
        // (Currently not used, but allows future refinement)
        return 0.0
    }
}
