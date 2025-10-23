// GoalValueAlignment.swift
// Represents alignment between a goal and a personal value
//
// Written by Claude Code on 2025-10-22
// Ported from Python implementation (python/categoriae/relationships.py)
//
// Goals should reflect personal values - this relationship tracks which goals
// serve which values. Used to ensure actions/goals align with what matters most.

import Foundation
import GRDB

/// Represents alignment between a goal and a personal value
///
/// GoalValueAlignments help answer: "Why am I pursuing this goal?"
/// and "Am I working on what truly matters to me?"
///
/// Alignments can be:
/// - Auto-inferred: Detected via life domain matching, keyword analysis, or theme similarity
/// - User-confirmed: User approved an auto-inferred alignment
/// - Manual: User explicitly declared the alignment
///
/// **Relationship to Database:**
/// - Stored in `goal_value_alignment` table
/// - Has a unique constraint on (goal_id, value_id) - a goal can only align with
///   a specific value once
///
/// **Alignment vs Confidence:**
/// - `alignmentStrength`: How strongly this goal serves the value (objective measure)
/// - `confidence`: How certain we are about the alignment assessment (epistemic measure)
///
/// Example: A goal might have:
/// - High alignment (0.9) + high confidence (0.9) = Strong, clear connection
/// - High alignment (0.9) + low confidence (0.4) = Strong but uncertain
/// - Low alignment (0.3) + high confidence (1.0) = Weak but confirmed connection
///
/// **Usage Example:**
/// ```swift
/// let alignment = GoalValueAlignment(
///     goalId: healthGoal.id,
///     valueId: vitalityValue.id,
///     alignmentStrength: 0.85,  // Strong alignment
///     assignmentMethod: .autoInferred,
///     confidence: 0.7  // Moderately confident in assessment
/// )
/// ```
public struct GoalValueAlignment: Codable, Sendable, Identifiable, Equatable,
                                   FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Core Identity

    /// Unique identifier for this alignment
    public var id: UUID

    /// UUID of the goal being aligned
    public var goalId: UUID

    /// UUID of the value this goal serves
    public var valueId: UUID

    // MARK: - Alignment Properties

    /// How strongly this goal serves the value (0.0-1.0)
    ///
    /// This measures the **objective alignment**, distinct from confidence:
    /// - 1.0 = Perfect alignment (life domain match + strong keyword overlap + explicit intent)
    /// - 0.7-0.9 = Strong alignment (life domain match + some keyword overlap)
    /// - 0.5-0.6 = Moderate alignment (life domain match OR keyword overlap)
    /// - 0.3-0.4 = Weak alignment (tangential connection, speculative)
    /// - <0.3 = Very weak (probably not a meaningful alignment)
    ///
    /// **Examples:**
    /// - Goal: "Run marathon" + Value: "Physical vitality" → 0.95 alignment
    /// - Goal: "Learn Spanish" + Value: "Intellectual growth" → 0.85 alignment
    /// - Goal: "Get promotion" + Value: "Family time" → 0.2 alignment (weak)
    public var alignmentStrength: Double

    /// How this alignment was determined
    public var assignmentMethod: AssignmentMethod

    /// Confidence in the alignment assessment (0.0-1.0)
    ///
    /// This measures **epistemic confidence**, distinct from alignment strength:
    /// - 1.0 for manual/confirmed alignments (user declared it)
    /// - Variable for auto-inferred based on signal strength:
    ///   - High confidence (0.8-1.0): Multiple strong signals (domain + keywords + theme)
    ///   - Medium confidence (0.5-0.7): Some signals present
    ///   - Low confidence (<0.5): Speculative, needs review
    public var confidence: Double

    /// When this alignment was created
    public var createdAt: Date

    // MARK: - GRDB Integration

    /// CodingKeys for mapping Swift properties to database columns
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"
        case goalId = "goal_id"
        case valueId = "value_id"
        case alignmentStrength = "alignment_strength"
        case assignmentMethod = "assignment_method"
        case confidence
        case createdAt = "created_at"
    }

    /// Column enum for type-safe query building
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let goalId = Column(CodingKeys.goalId)
        static let valueId = Column(CodingKeys.valueId)
        static let alignmentStrength = Column(CodingKeys.alignmentStrength)
        static let assignmentMethod = Column(CodingKeys.assignmentMethod)
        static let confidence = Column(CodingKeys.confidence)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    /// TableRecord conformance - specify database table name
    public static let databaseTableName = "goal_value_alignment"

    /// Configure UUID storage as uppercase string (matches TEXT column in database)
    public static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy {
        .uppercaseString
    }

    // MARK: - Nested Types

    /// How the alignment was determined
    public enum AssignmentMethod: String, Codable, Sendable {
        /// Detected via life domain matching, keywords, or theme analysis
        case autoInferred = "auto_inferred"

        /// User confirmed an auto-inferred alignment
        case userConfirmed = "user_confirmed"

        /// User explicitly declared this alignment
        case manual = "manual"
    }

    // MARK: - Initialization

    /// Create a new goal-value alignment
    ///
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - goalId: UUID of the goal being aligned
    ///   - valueId: UUID of the value being served
    ///   - alignmentStrength: How strongly goal serves value (0.0-1.0)
    ///   - assignmentMethod: How the alignment was determined
    ///   - confidence: Confidence in the assessment (0.0-1.0, defaults to 1.0)
    ///   - createdAt: When created (defaults to now)
    public init(
        id: UUID = UUID(),
        goalId: UUID,
        valueId: UUID,
        alignmentStrength: Double,
        assignmentMethod: AssignmentMethod,
        confidence: Double = 1.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goalId = goalId
        self.valueId = valueId
        self.alignmentStrength = alignmentStrength
        self.assignmentMethod = assignmentMethod
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension GoalValueAlignment {
    /// Whether this alignment was automatically inferred
    public var isInferred: Bool {
        assignmentMethod == .autoInferred
    }

    /// Whether this alignment has been confirmed by the user
    public var isConfirmed: Bool {
        assignmentMethod == .userConfirmed || assignmentMethod == .manual
    }

    /// Whether this is a strong alignment (strength ≥ 0.7)
    public var isStrongAlignment: Bool {
        alignmentStrength >= 0.7
    }

    /// Whether this alignment is high confidence (≥0.7)
    public var isHighConfidence: Bool {
        confidence >= 0.7
    }

    /// Whether this alignment is speculative and might need review
    ///
    /// Low alignment + low confidence = probably not meaningful
    public var isSpeculative: Bool {
        alignmentStrength < 0.5 && confidence < 0.5 && assignmentMethod == .autoInferred
    }

    /// Overall quality score combining alignment and confidence
    ///
    /// This gives a single metric for "how good is this alignment?"
    /// - Strong alignment + high confidence = high quality
    /// - Weak alignment OR low confidence = low quality
    ///
    /// Returns the geometric mean: sqrt(alignmentStrength × confidence)
    public var qualityScore: Double {
        sqrt(alignmentStrength * confidence)
    }
}

// MARK: - Validation

extension GoalValueAlignment {
    /// Validate the alignment data
    ///
    /// - Returns: `true` if all fields are valid
    public func isValid() -> Bool {
        // Alignment strength must be in range [0, 1]
        guard alignmentStrength >= 0.0 && alignmentStrength <= 1.0 else { return false }

        // Confidence must be in range [0, 1]
        guard confidence >= 0.0 && confidence <= 1.0 else { return false }

        // IDs must not be nil UUID
        guard goalId != UUID(uuidString: "00000000-0000-0000-0000-000000000000")! else { return false }
        guard valueId != UUID(uuidString: "00000000-0000-0000-0000-000000000000")! else { return false }

        return true
    }
}
