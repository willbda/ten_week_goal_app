// RelationshipGRDBTests.swift
// Integration tests for ActionGoalRelationship with GRDB
//
// Written by Claude Code on 2025-10-22
// Tests direct GRDB conformance for relationship entities
//
// Note: Relationships use GRDB's native methods directly since they're join tables,
// not domain entities with title/description/notes fields.

import Testing
import GRDB
import Foundation
@testable import Models
@testable import Database

@Suite("ActionGoalRelationship GRDB Integration")
struct RelationshipGRDBTests {

    // Helper to get database pool directly
    func getPool() async throws -> DatabasePool {
        let config = DatabaseConfiguration.temporary
        let pool: DatabasePool

        if config.isInMemory {
            pool = try DatabasePool(path: ":memory:")
        } else {
            pool = try DatabasePool(path: config.databasePath.path)
        }

        // Initialize schema
        try await pool.write { db in
            let schemaSQL = """
            CREATE TABLE IF NOT EXISTS actions (
                uuid_id TEXT PRIMARY KEY,
                title TEXT,
                description TEXT,
                notes TEXT,
                log_time TEXT NOT NULL,
                measurement_units_by_amount TEXT,
                start_time TEXT,
                duration_minutes REAL
            );

            CREATE TABLE IF NOT EXISTS goals (
                uuid_id TEXT PRIMARY KEY,
                title TEXT,
                description TEXT,
                notes TEXT,
                log_time TEXT NOT NULL,
                measurement_unit TEXT,
                measurement_target REAL,
                start_date TEXT,
                target_date TEXT,
                how_goal_is_relevant TEXT,
                how_goal_is_actionable TEXT,
                expected_term_length INTEGER,
                priority INTEGER DEFAULT 50,
                life_domain TEXT,
                polymorphic_subtype TEXT DEFAULT 'goal'
            );

            CREATE TABLE IF NOT EXISTS action_goal_progress (
                uuid_id TEXT PRIMARY KEY,
                action_id TEXT NOT NULL,
                goal_id TEXT NOT NULL,
                contribution REAL NOT NULL,
                match_method TEXT NOT NULL,
                confidence REAL,
                matched_on TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (action_id) REFERENCES actions(uuid_id) ON DELETE CASCADE,
                FOREIGN KEY (goal_id) REFERENCES goals(uuid_id) ON DELETE CASCADE,
                UNIQUE(action_id, goal_id)
            );
            """

            try db.execute(sql: schemaSQL)
        }

        return pool
    }

    // MARK: - Basic CRUD Operations

    @Test("Relationship can be saved and fetched")
    @MainActor
    func relationshipRoundTrip() async throws {
        let pool = try await getPool()

        // Create test action and goal
        let action = Action(title: "Run 5km", measuresByUnit: ["km": 5.0])
        let goal = Goal(title: "Marathon training", measurementUnit: "km", measurementTarget: 100.0)

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        // Create relationship
        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 5.0,
            matchMethod: .autoInferred,
            confidence: 0.9,
            matchedOn: [.period, .unit]
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        // Fetch back
        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.count == 1)
        #expect(fetched.first?.actionId == action.id)
        #expect(fetched.first?.goalId == goal.id)
        #expect(fetched.first?.contribution == 5.0)
        #expect(fetched.first?.matchMethod == .autoInferred)
        #expect(fetched.first?.confidence == 0.9)
        #expect(fetched.first?.matchedOn.count == 2)
    }

    @Test("Relationship UUID is preserved")
    @MainActor
    func relationshipUUIDPreservation() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 1.0,
            matchMethod: .manual
        )

        let originalId = relationship.id

        try await pool.write { db in
            try relationship.insert(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.first?.id == originalId)
    }

    @Test("Relationship can be fetched by ID")
    @MainActor
    func relationshipFetchById() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 1.0,
            matchMethod: .manual
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        let fetched = try await pool.read { db in
            let sql = "SELECT * FROM action_goal_progress WHERE uuid_id = ?"
            return try ActionGoalRelationship.fetchOne(db, sql: sql, arguments: [relationship.id.uuidString])
        }

        #expect(fetched != nil)
        #expect(fetched?.id == relationship.id)
        #expect(fetched?.actionId == action.id)
    }

    // MARK: - Enum Serialization

    @Test("MatchMethod enum serializes correctly")
    @MainActor
    func matchMethodSerialization() async throws {
        let pool = try await getPool()

        // Test all three match methods
        let methods: [ActionGoalRelationship.MatchMethod] = [.autoInferred, .userConfirmed, .manual]

        for (index, method) in methods.enumerated() {
            // Create new action/goal for each iteration to avoid UNIQUE constraint
            let action = Action(title: "Test \(index)")
            let goal = Goal(title: "Test Goal \(index)")

            try await pool.write { db in
                try action.insert(db)
                try goal.insert(db)
            }

            let relationship = ActionGoalRelationship(
                actionId: action.id,
                goalId: goal.id,
                contribution: 1.0,
                matchMethod: method
            )

            try await pool.write { db in
                try relationship.insert(db)
            }

            let fetched = try await pool.read { db in
                let sql = "SELECT * FROM action_goal_progress WHERE uuid_id = ?"
                return try ActionGoalRelationship.fetchOne(db, sql: sql, arguments: [relationship.id.uuidString])
            }

            #expect(fetched?.matchMethod == method)
        }
    }

    @Test("MatchCriteria array serializes correctly")
    @MainActor
    func matchCriteriaSerialization() async throws {
        let pool = try await getPool()

        // Test different combinations
        let criteriaSet: [[ActionGoalRelationship.MatchCriteria]] = [
            [],
            [.period],
            [.unit],
            [.description],
            [.period, .unit],
            [.period, .unit, .description]
        ]

        for (index, criteria) in criteriaSet.enumerated() {
            // Create new action/goal for each iteration to avoid UNIQUE constraint
            let action = Action(title: "Test \(index)")
            let goal = Goal(title: "Test Goal \(index)")

            try await pool.write { db in
                try action.insert(db)
                try goal.insert(db)
            }

            let relationship = ActionGoalRelationship(
                actionId: action.id,
                goalId: goal.id,
                contribution: 1.0,
                matchMethod: .autoInferred,
                matchedOn: criteria
            )

            try await pool.write { db in
                try relationship.insert(db)
            }

            let fetched = try await pool.read { db in
                let sql = "SELECT * FROM action_goal_progress WHERE uuid_id = ?"
                return try ActionGoalRelationship.fetchOne(db, sql: sql, arguments: [relationship.id.uuidString])
            }

            #expect(fetched?.matchedOn.count == criteria.count)
            #expect(Set(fetched?.matchedOn ?? []) == Set(criteria))
        }
    }

    // MARK: - Multiple Relationships

    @Test("Multiple relationships can be saved")
    @MainActor
    func multipleRelationships() async throws {
        let pool = try await getPool()

        let action1 = Action(title: "Run 5km")
        let action2 = Action(title: "Run 10km")
        let goal = Goal(title: "Marathon training")

        try await pool.write { db in
            try action1.insert(db)
            try action2.insert(db)
            try goal.insert(db)
        }

        let rel1 = ActionGoalRelationship(
            actionId: action1.id,
            goalId: goal.id,
            contribution: 5.0,
            matchMethod: .autoInferred
        )

        let rel2 = ActionGoalRelationship(
            actionId: action2.id,
            goalId: goal.id,
            contribution: 10.0,
            matchMethod: .autoInferred
        )

        try await pool.write { db in
            try rel1.insert(db)
            try rel2.insert(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.count == 2)
    }

    // MARK: - Update Operations

    @Test("Relationship can be updated")
    @MainActor
    func relationshipUpdate() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        var relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 5.0,
            matchMethod: .autoInferred,
            confidence: 0.8
        )

        let insertRelationship = relationship  // Capture before async
        try await pool.write { db in
            try insertRelationship.insert(db)
        }

        // Update
        relationship.matchMethod = .userConfirmed
        relationship.confidence = 1.0
        let updatedRelationship = relationship  // Capture before async

        try await pool.write { db in
            try updatedRelationship.update(db)
        }

        let fetched = try await pool.read { db in
            let sql = "SELECT * FROM action_goal_progress WHERE uuid_id = ?"
            return try ActionGoalRelationship.fetchOne(db, sql: sql, arguments: [updatedRelationship.id.uuidString])
        }

        #expect(fetched?.matchMethod == .userConfirmed)
        #expect(fetched?.confidence == 1.0)
    }

    // MARK: - Delete Operations

    @Test("Relationship can be deleted")
    @MainActor
    func relationshipDelete() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 1.0,
            matchMethod: .manual
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        var fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }
        #expect(fetched.count == 1)

        try await pool.write { db in
            try relationship.delete(db)
        }

        fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }
        #expect(fetched.count == 0)
    }

    // MARK: - Foreign Key Constraints

    @Test("Foreign key cascade delete from action")
    @MainActor
    func foreignKeyCascadeAction() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 1.0,
            matchMethod: .manual
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        // Delete action - should cascade to relationship
        try await pool.write { db in
            try action.delete(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }
        #expect(fetched.count == 0) // Relationship deleted via cascade
    }

    // MARK: - Edge Cases

    @Test("Relationship with empty matchedOn")
    @MainActor
    func emptyMatchedOn() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 1.0,
            matchMethod: .manual,
            matchedOn: []
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.first?.matchedOn.isEmpty == true)
    }

    @Test("Relationship with zero contribution")
    @MainActor
    func zeroContribution() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 0.0,
            matchMethod: .manual
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.first?.contribution == 0.0)
    }

    @Test("Relationship with very large contribution")
    @MainActor
    func largeContribution() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 999_999.99,
            matchMethod: .manual
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.first?.contribution == 999_999.99)
    }

    @Test("Relationship with high confidence")
    @MainActor
    func highConfidence() async throws {
        let pool = try await getPool()

        let action = Action(title: "Test")
        let goal = Goal(title: "Test Goal")

        try await pool.write { db in
            try action.insert(db)
            try goal.insert(db)
        }

        let relationship = ActionGoalRelationship(
            actionId: action.id,
            goalId: goal.id,
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: 0.99999
        )

        try await pool.write { db in
            try relationship.insert(db)
        }

        let fetched = try await pool.read { db in
            try ActionGoalRelationship.fetchAll(db)
        }

        #expect(fetched.first?.confidence == 0.99999)
    }
}
