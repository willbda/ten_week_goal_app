//
// ReferenceTypes.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Type-safe references to other entities during import wizard.
// Handles three states: existing (in DB), staged (in wizard), unresolved (needs matching).
//
// WORKFLOW:
// 1. Parser creates unresolved: MeasureReference.unresolved("km")
// 2. Wizard attempts auto-resolve: finds existing "km" in DB → .existing(uuid)
// 3. Or finds "km" in staged measures → .staged(uuid)
// 4. If multiple matches → user chooses → resolve manually
//
// USAGE:
// ```swift
// let ref = MeasureReference.unresolved("kilometers")
// if let resolvedId = ref.autoResolve(existing: dbMeasures, staged: stagedMeasures) {
//     ref = .existing(resolvedId)
// }
// ```
//

import Foundation
import Models

// MARK: - Measure Reference

/// Reference to a Measure (existing, staged, or unresolved)
public enum MeasureReference: Codable {
    case existing(UUID)         // Already in database
    case staged(UUID)           // From import wizard Step 2
    case unresolved(String)     // "km" - needs resolution

    /// Resolved UUID (nil if unresolved)
    public var resolved: UUID? {
        switch self {
        case .existing(let id), .staged(let id):
            return id
        case .unresolved:
            return nil
        }
    }

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .existing, .staged:
            return "Resolved"
        case .unresolved(let input):
            return input
        }
    }

    /// Attempt to resolve measure reference by unit name
    public static func match(
        unit: String,
        existing: [Measure],
        staged: [StagedMeasure]
    ) -> MeasureReference {
        let normalizedUnit = unit.lowercased().trimmingCharacters(in: .whitespaces)

        // Check existing measures (exact match on unit)
        if let match = existing.first(where: { $0.unit.lowercased() == normalizedUnit }) {
            return .existing(match.id)
        }

        // Check staged measures
        if let match = staged.first(where: { $0.unit.lowercased() == normalizedUnit }) {
            return .staged(match.id)
        }

        // No match - will create new on commit
        return .unresolved(unit)
    }
}

// MARK: - Value Reference

/// Reference to a PersonalValue with fuzzy matching support
public struct ValueReference: Codable {
    /// Input string from user
    public let input: String

    /// Resolved UUID (nil if unresolved)
    public var resolved: UUID?

    /// Fuzzy matches for user disambiguation
    public var suggestions: [ValueSuggestion]

    /// Match confidence (0.0-1.0)
    public var confidence: Double?

    public init(input: String, resolved: UUID? = nil, suggestions: [ValueSuggestion] = []) {
        self.input = input
        self.resolved = resolved
        self.suggestions = suggestions
    }

    public var isResolved: Bool {
        resolved != nil
    }
}

public struct ValueSuggestion: Codable {
    public let id: UUID
    public let title: String
    public let confidence: Double  // 0.0-1.0

    public init(id: UUID, title: String, confidence: Double) {
        self.id = id
        self.title = title
        self.confidence = confidence
    }
}

// MARK: - Goal Reference

/// Reference to a Goal (existing or staged)
public struct GoalReference: Codable {
    public let input: String
    public var resolved: UUID?
    public var suggestions: [GoalSuggestion]

    public init(input: String, resolved: UUID? = nil) {
        self.input = input
        self.resolved = resolved
        self.suggestions = []
    }

    public var isResolved: Bool {
        resolved != nil
    }
}

public struct GoalSuggestion: Codable {
    public let id: UUID
    public let title: String
    public let confidence: Double

    public init(id: UUID, title: String, confidence: Double) {
        self.id = id
        self.title = title
        self.confidence = confidence
    }
}

// MARK: - Matching Utilities

extension ValueReference {
    /// Attempt to resolve reference against existing and staged values
    /// - Returns: Updated reference with resolution/suggestions
    public static func match(
        input: String,
        existing: [PersonalValue],
        staged: [StagedValue]
    ) -> ValueReference {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. EXACT MATCH (auto-resolve)
        if let exactMatch = existing.first(where: {
            $0.title?.lowercased() == normalizedInput
        }) {
            return ValueReference(
                input: input,
                resolved: exactMatch.id,
                suggestions: []
            )
        }

        if let exactMatch = staged.first(where: {
            $0.title.lowercased() == normalizedInput
        }) {
            return ValueReference(
                input: input,
                resolved: exactMatch.id,
                suggestions: []
            )
        }

        // 2. FUZZY MATCHES (suggestions only)
        var suggestions: [ValueSuggestion] = []

        // Check existing values
        for value in existing {
            guard let title = value.title else { continue }
            if let confidence = fuzzyMatch(input: normalizedInput, target: title.lowercased()) {
                suggestions.append(ValueSuggestion(
                    id: value.id,
                    title: title,
                    confidence: confidence
                ))
            }
        }

        // Check staged values
        for value in staged {
            if let confidence = fuzzyMatch(input: normalizedInput, target: value.title.lowercased()) {
                suggestions.append(ValueSuggestion(
                    id: value.id,
                    title: value.title,
                    confidence: confidence
                ))
            }
        }

        // Sort by confidence (highest first)
        suggestions.sort { $0.confidence > $1.confidence }

        // Return with suggestions (user chooses)
        return ValueReference(
            input: input,
            resolved: nil,
            suggestions: Array(suggestions.prefix(5))  // Top 5 suggestions
        )
    }

    /// Simple fuzzy matching: substring + word overlap
    /// Returns confidence (0.0-1.0) or nil if no match
    fileprivate static func fuzzyMatch(input: String, target: String) -> Double? {
        // Exact match already handled - skip
        if input == target { return nil }

        var score: Double = 0.0

        // Substring match: "health" matches "health & vitality"
        if target.contains(input) {
            score += 0.6
        }

        // Word overlap: "intellectual growth" matches "growth intellectual"
        let inputWords = Set(input.split(separator: " ").map { String($0) })
        let targetWords = Set(target.split(separator: " ").map { String($0) })
        let overlap = inputWords.intersection(targetWords)

        if !overlap.isEmpty {
            let overlapRatio = Double(overlap.count) / Double(max(inputWords.count, targetWords.count))
            score += overlapRatio * 0.4
        }

        // Only suggest if confidence > 0.3
        return score > 0.3 ? score : nil
    }
}

extension GoalReference {
    /// Match against existing and staged goals
    public static func match(
        input: String,
        existing: [Goal],
        existingExpectations: [Expectation],
        staged: [StagedGoal]
    ) -> GoalReference {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespaces)

        // 1. EXACT MATCH
        let expectationMap = Dictionary(uniqueKeysWithValues: existingExpectations.map { ($0.id, $0) })

        for goal in existing {
            guard let expectation = expectationMap[goal.expectationId],
                  let title = expectation.title else { continue }

            if title.lowercased() == normalizedInput {
                return GoalReference(input: input, resolved: goal.id)
            }
        }

        for goal in staged {
            if goal.title.lowercased() == normalizedInput {
                return GoalReference(input: input, resolved: goal.id)
            }
        }

        // 2. FUZZY SUGGESTIONS
        var suggestions: [GoalSuggestion] = []

        for goal in existing {
            guard let expectation = expectationMap[goal.expectationId],
                  let title = expectation.title else { continue }

            if let confidence = ValueReference.fuzzyMatch(input: normalizedInput, target: title.lowercased()) {
                suggestions.append(GoalSuggestion(
                    id: goal.id,
                    title: title,
                    confidence: confidence
                ))
            }
        }

        for goal in staged {
            if let confidence = ValueReference.fuzzyMatch(input: normalizedInput, target: goal.title.lowercased()) {
                suggestions.append(GoalSuggestion(
                    id: goal.id,
                    title: goal.title,
                    confidence: confidence
                ))
            }
        }

        suggestions.sort { $0.confidence > $1.confidence }

        var ref = GoalReference(input: input, resolved: nil)
        ref.suggestions = Array(suggestions.prefix(5))
        return ref
    }
}
