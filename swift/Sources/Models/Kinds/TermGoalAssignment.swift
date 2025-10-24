// TermGoalAssignment.swift
// Junction table model for term-goal many-to-many relationships
//
// Written by Claude Code on 2025-10-23
//
// This is a pure infrastructure type (not a domain entity).
// It represents the database relationship between terms and goals,
// allowing GRDB to handle associations efficiently.

import Foundation
import GRDB

/// Junction table record for term-goal assignments
///
/// This struct maps to the `term_goal_assignments` table and enables
/// GRDB's association system to load related goals for a term.
///
/// **Design**: This is infrastructure, not a domain model. Users of the
/// app don't think about "assignments" - they think about "goals in a term".
/// This type exists solely to support the database relationship.
///
/// Example queries enabled:
/// ```swift
/// // Fetch all goals for a term (via association)
/// let term = try GoalTerm.including(all: GoalTerm.goals).fetchOne(db, id: termId)
///
/// // Fetch all terms containing a goal
/// let terms = try Goal.including(all: Goal.terms).fetchAll(db)
/// ```
public struct TermGoalAssignment: Codable, Sendable, FetchableRecord, PersistableRecord {

    // MARK: - Properties

    /// UUID of the term
    public var termUUID: UUID

    /// UUID of the goal
    public var goalUUID: UUID

    /// Order of this goal within the term (0-indexed)
    public var assignmentOrder: Int?

    /// When this assignment was created
    public var createdAt: Date

    // MARK: - GRDB Configuration

    public static let databaseTableName = "term_goal_assignments"

    /// Codable keys for snake_case mapping
    enum CodingKeys: String, CodingKey {
        case termUUID = "term_uuid"
        case goalUUID = "goal_uuid"
        case assignmentOrder = "assignment_order"
        case createdAt = "created_at"
    }

    /// Use centralized UUID encoding strategy (UPPERCASE)
    public static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy {
        EntityUUIDEncoding.strategy
    }

    /// Handle INSERT conflicts by replacing
    public static let persistenceConflictPolicy = PersistenceConflictPolicy(
        insert: .replace,
        update: .replace
    )

    // MARK: - Associations

    /// Association to the term
    public static let term = belongsTo(GoalTerm.self, key: "term", using: ForeignKey(["term_uuid"]))

    /// Association to the goal
    public static let goal = belongsTo(Goal.self, key: "goal", using: ForeignKey(["goal_uuid"]))

    // MARK: - Initialization

    public init(
        termUUID: UUID,
        goalUUID: UUID,
        assignmentOrder: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.termUUID = termUUID
        self.goalUUID = goalUUID
        self.assignmentOrder = assignmentOrder
        self.createdAt = createdAt
    }
}
