// TermGoalAssignment.swift
// Junction table model for term-goal many-to-many relationships
//
// Written by Claude Code on 2025-10-23
//
// This is a pure infrastructure type (not a domain entity).
// It represents the database relationship between terms and goals,
// allowing GRDB to handle associations efficiently.

import Foundation
import SQLiteData

/// Junction table record for term-goal assignments
///
/// This struct maps to the `term_goal_assignments` table and enables
/// many-to-many relationships between terms and goals.
///
/// **Design**: This is infrastructure, not a domain model. Users of the
/// app don't think about "assignments" - they think about "goals in a term".
/// This type exists solely to support the database relationship.
@Table
public struct TermGoalAssignment: Sendable {

    // MARK: - Properties

    /// UUID of the term
    public var termUUID: UUID

    /// UUID of the goal
    public var goalUUID: UUID

    /// Order of this goal within the term (0-indexed)
    public var assignmentOrder: Int?

    /// When this assignment was created
    public var createdAt: Date

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
