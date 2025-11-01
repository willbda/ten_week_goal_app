// GoalRelevance.swift
// Junction table linking goals to the values they serve
//
// Written by Claude Code on 2025-10-30
//
// ARCHITECTURE:
// - Pure junction table (database artifact)
// - Links Goals to Values with alignment metadata
// - Replaces flat text "howGoalIsRelevant" field with structured relationships
// - Enables queries like "which goals serve value X" or "which values does goal Y align with"
//
// 3NF COMPLIANCE:
// - Separates goal-value relationships from goal entity
// - Enables many-to-many relationships (goals can serve multiple values)
// - No redundant data storage

import Foundation
import SQLiteData

/// Links a goal to a value it serves or aligns with
///
/// **Database Table**: `goalRelevance`
/// **Purpose**: Store goal-value alignments
///
/// **Design Principle**: This is a pure junction table - a database artifact
/// that exists solely to link Goals and Values. It's always accessed through
/// its related Persistable entities.
///
/// **Why separate from Goal?**
/// - Goals can align with 0 to many values
/// - Values can be served by 0 to many goals
/// - Enables queries: "All goals serving health values"
/// - Allows tracking alignment strength
///
/// **Usage**:
/// ```swift
/// // Link a running goal to health value
/// let alignment = GoalRelevance(
///     goalId: runningGoal.id,
///     valueId: healthValue.id,
///     alignmentStrength: 9,
///     relevanceNotes: "Running directly supports physical health and vitality"
/// )
///
/// // Link same goal to companionship value
/// let socialAlignment = GoalRelevance(
///     goalId: runningGoal.id,
///     valueId: companionshipValue.id,
///     alignmentStrength: 6,
///     relevanceNotes: "Running with partner strengthens relationship"
/// )
/// ```
@Table
public struct GoalRelevance: Identifiable, Sendable {
    // MARK: - Identity

    /// Unique identifier (required by SQLiteData)
    public var id: UUID

    // MARK: - Relationship Fields

    /// The goal in this alignment
    public var goalId: UUID

    /// The value being served
    public var valueId: UUID

    /// Strength of alignment (1-10 scale)
    /// 10 = perfectly aligned, 1 = tangentially related
    public var alignmentStrength: Int?

    /// Optional notes explaining the alignment
    /// Example: "Morning runs support health and provide thinking time"
    public var relevanceNotes: String?

    /// When this alignment was identified
    public var createdAt: Date

    // MARK: - Initialization

    /// Create a new goal-value alignment
    ///
    /// - Parameters:
    ///   - goalId: The goal being aligned
    ///   - valueId: The value being served
    ///   - alignmentStrength: How strongly aligned (1-10)
    ///   - relevanceNotes: Optional explanation
    ///   - createdAt: When identified (defaults to now)
    ///   - id: Unique identifier
    public init(
        goalId: UUID,
        valueId: UUID,
        alignmentStrength: Int? = nil,
        relevanceNotes: String? = nil,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.goalId = goalId
        self.valueId = valueId
        self.alignmentStrength = alignmentStrength
        self.relevanceNotes = relevanceNotes
        self.createdAt = createdAt
    }
}

// MARK: - Alignment Analysis

extension GoalRelevance {
    /// Check if this is a strong alignment (8 or higher)
    public var isStrongAlignment: Bool {
        guard let strength = alignmentStrength else { return false }
        return strength >= 8
    }

    /// Check if this is a weak alignment (3 or lower)
    public var isWeakAlignment: Bool {
        guard let strength = alignmentStrength else { return false }
        return strength <= 3
    }

    /// Normalized alignment score (0.0 to 1.0)
    public var normalizedScore: Double? {
        guard let strength = alignmentStrength else { return nil }
        return Double(strength) / 10.0
    }
}