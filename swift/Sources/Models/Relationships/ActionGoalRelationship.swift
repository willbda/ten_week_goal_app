// ActionGoalRelationship.swift
// Represents a derived relationship between an action and a goal
//
// Written by Claude Code on 2025-10-22
// Ported from Python implementation (python/categoriae/relationships.py)
//
// This defines WHAT the relationship looks like (the data shape).
// The HOW (matching logic, inference rules) lives in BusinessLogic/MatchingService.swift

import Foundation
import GRDB

/// Represents a discovered or assigned relationship between an action and a goal
///
/// ActionGoalRelationships are DERIVED entities - they represent computed or inferred
/// connections between actions and goals. They can be:
/// - Auto-inferred by matching algorithms (period + unit + description matching)
/// - User-confirmed (user approved an auto-inferred suggestion)
/// - Manual (user explicitly created the relationship)
///
/// **Relationship to Database:**
/// - Stored in `action_goal_progress` table
/// - Acts as a cache/projection - can be recalculated from actions + goals
/// - Has a unique constraint on (action_id, goal_id) - one action can only contribute
///   to a specific goal once
///
/// **Usage Example:**
/// ```swift
/// let relationship = ActionGoalRelationship(
///     actionId: runAction.id,
///     goalId: marathonGoal.id,
///     contribution: 5.0,  // 5 km contributed
///     matchMethod: .autoInferred,
///     confidence: 0.95,
///     matchedOn: [.period, .unit, .description]
/// )
/// ```
public struct ActionGoalRelationship: Codable, Sendable, Identifiable, Equatable,
                                      FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Core Identity

    /// Unique identifier for this relationship
    public var id: UUID

    /// UUID of the action that contributes to the goal
    public var actionId: UUID

    /// UUID of the goal being contributed to
    public var goalId: UUID

    // MARK: - Relationship Properties

    /// Amount this action contributes toward the goal
    ///
    /// For goals with measurement targets, this is the numeric contribution
    /// (e.g., 5.0 km toward a 50 km goal).
    /// For goals without measurements, this might be 1.0 (one completion count).
    public var contribution: Double

    /// How this relationship was determined
    public var matchMethod: MatchMethod

    /// Confidence score for the relationship (0.0-1.0)
    ///
    /// - For `.manual` and `.userConfirmed`: Always 1.0
    /// - For `.autoInferred`: Variable based on match quality
    ///   - 1.0 = Perfect match (period + unit + description all match)
    ///   - 0.7-0.9 = Strong match (period + unit match, description partial)
    ///   - 0.4-0.6 = Moderate match (period + unit match only)
    ///   - <0.4 = Weak match (may need user review)
    public var confidence: Double

    /// Which criteria were used to establish this match
    ///
    /// For auto-inferred relationships, tracks what signals contributed:
    /// - `.period`: Action occurred during goal's active timeframe
    /// - `.unit`: Action has measurement compatible with goal's target unit
    /// - `.description`: Action description fuzzy-matches goal description
    public var matchedOn: [MatchCriteria]

    /// When this relationship was created
    public var createdAt: Date

    // MARK: - GRDB Integration

    /// CodingKeys for mapping Swift properties to database columns
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"
        case actionId = "action_id"
        case goalId = "goal_id"
        case contribution
        case matchMethod = "match_method"
        case confidence
        case matchedOn = "matched_on"
        case createdAt = "created_at"
    }

    /// Column enum for type-safe query building
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let actionId = Column(CodingKeys.actionId)
        static let goalId = Column(CodingKeys.goalId)
        static let contribution = Column(CodingKeys.contribution)
        static let matchMethod = Column(CodingKeys.matchMethod)
        static let confidence = Column(CodingKeys.confidence)
        static let matchedOn = Column(CodingKeys.matchedOn)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    /// TableRecord conformance - specify database table name
    public static let databaseTableName = "action_goal_progress"

    /// Configure UUID storage as uppercase string (Swift's UUID default format)
    public static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy {
        .uppercaseString
    }

    // MARK: - Nested Types

    /// How the relationship was determined
    public enum MatchMethod: String, Codable, Sendable {
        /// Computed by matching algorithm (period + unit + description)
        case autoInferred = "auto_inferred"

        /// User confirmed an auto-inferred suggestion
        case userConfirmed = "user_confirmed"

        /// User explicitly created this relationship
        case manual = "manual"
    }

    /// Criteria used for matching actions to goals
    public enum MatchCriteria: String, Codable, Sendable {
        /// Action occurred during goal's active period (start_date to target_date)
        case period

        /// Action has measurement compatible with goal's target unit
        /// (e.g., "distance_km" in action matches "km" in goal)
        case unit

        /// Action description contains keywords from goal description
        /// or goal's `how_goal_is_actionable` field
        case description
    }

    // MARK: - Initialization

    /// Create a new action-goal relationship
    ///
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - actionId: UUID of the contributing action
    ///   - goalId: UUID of the goal being contributed to
    ///   - contribution: Amount contributed (e.g., 5.0 km)
    ///   - matchMethod: How the relationship was determined
    ///   - confidence: Confidence score 0.0-1.0 (defaults to 1.0)
    ///   - matchedOn: Criteria that matched (empty array means not tracked)
    ///   - createdAt: When created (defaults to now)
    public init(
        id: UUID = UUID(),
        actionId: UUID,
        goalId: UUID,
        contribution: Double,
        matchMethod: MatchMethod,
        confidence: Double = 1.0,
        matchedOn: [MatchCriteria] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.actionId = actionId
        self.goalId = goalId
        self.contribution = contribution
        self.matchMethod = matchMethod
        self.confidence = confidence
        self.matchedOn = matchedOn
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension ActionGoalRelationship {
    /// Whether this relationship was automatically inferred
    public var isInferred: Bool {
        matchMethod == .autoInferred
    }

    /// Whether this relationship has been confirmed by the user
    public var isConfirmed: Bool {
        matchMethod == .userConfirmed || matchMethod == .manual
    }

    /// Whether this match is considered high confidence (≥0.7)
    public var isHighConfidence: Bool {
        confidence >= 0.7
    }

    /// Whether this match is ambiguous and might need user review (<0.4)
    public var isAmbiguous: Bool {
        confidence < 0.4 && matchMethod == .autoInferred
    }
}

// MARK: - Validation

extension ActionGoalRelationship {
    /// Validate the relationship data
    ///
    /// - Returns: `true` if all fields are valid
    public func isValid() -> Bool {
        // Contribution must be non-negative
        guard contribution >= 0 else { return false }

        // Confidence must be in range [0, 1]
        guard confidence >= 0.0 && confidence <= 1.0 else { return false }

        // IDs must not be nil UUID
        guard actionId != UUID(uuidString: "00000000-0000-0000-0000-000000000000")! else { return false }
        guard goalId != UUID(uuidString: "00000000-0000-0000-0000-000000000000")! else { return false }

        return true
    }
}
