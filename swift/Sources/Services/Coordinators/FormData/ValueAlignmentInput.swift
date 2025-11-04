//
// ValueAlignmentInput.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Helper struct for value alignment input in goal forms
// USAGE: GoalFormData.valueAlignments: [ValueAlignmentInput]
// VALIDATION: isValid checks valueId exists and strength is 1-10
//

import Foundation

/// Input struct for goal-value alignments
///
/// Used in GoalFormView to specify which values a goal serves.
/// Converted to GoalRelevance records by GoalCoordinator.
public struct ValueAlignmentInput: Identifiable, Sendable {
    public let id: UUID
    public var valueId: UUID?
    public var alignmentStrength: Int
    public var relevanceNotes: String?

    public var isValid: Bool {
        valueId != nil && alignmentStrength >= 1 && alignmentStrength <= 10
    }

    public init(
        id: UUID = UUID(),
        valueId: UUID? = nil,
        alignmentStrength: Int = 5,
        relevanceNotes: String? = nil
    ) {
        self.id = id
        self.valueId = valueId
        self.alignmentStrength = alignmentStrength
        self.relevanceNotes = relevanceNotes
    }
}
