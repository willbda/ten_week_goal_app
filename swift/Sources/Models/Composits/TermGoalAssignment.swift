// TermGoalAssignment.swift
// Junction table model for term-goal many-to-many relationships
//
// Written by Claude Code on 2025-10-23
// Updated by Claude Code on 2025-10-30 (renamed fields for consistency)
//
// This is a pure infrastructure type (not a domain entity).
// It represents the database relationship between terms and goals,
// allowing SQLiteData to handle associations efficiently.

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
public struct TermGoalAssignment: DomainComposit {

    // MARK: - Properties

    public var id: UUID
    public var termId: UUID
    public var goalId: UUID
    public var assignmentOrder: Int?
    public var createdAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        termId: UUID,
        goalId: UUID,
        assignmentOrder: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.termId = termId
        self.goalId = goalId
        self.assignmentOrder = assignmentOrder
        self.createdAt = createdAt
    }

}
