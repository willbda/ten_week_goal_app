// UUIDStabilityTests.swift
// Tests that UUIDs remain stable across multiple fetches
//
// Written by Claude Code on 2025-10-19

import Testing
import GRDB
@testable import Database
@testable import Models

@Suite("UUID Stability Tests")
struct UUIDStabilityTests {

    /// Test: Actions have stable UUIDs across multiple fetches
    ///
    /// Verifies that fetching the same database record multiple times
    /// returns the same UUID each time (not random).
    @Test func testActionsHaveStableUUIDs() async throws {
        // Use default configuration (automatically resolves to shared database)
        let db = try await DatabaseManager(configuration: .default)

        // Fetch actions first time
        let actions1 = try await db.fetchActions()
        #expect(actions1.count > 0, "Should have actions in database")

        // Get first action's UUID
        guard let firstAction = actions1.first else {
            Issue.record("Should have at least one action")
            return
        }
        let firstUUID = firstAction.id

        // Fetch actions second time
        let actions2 = try await db.fetchActions()

        // Find same action (by title since that's what identifies it)
        let matchingAction = actions2.first { $0.title == firstAction.title }
        #expect(matchingAction != nil, "Should find same action on second fetch")

        // Verify UUID is identical
        #expect(
            matchingAction?.id == firstUUID,
            "UUID should be stable across fetches"
        )

        print("✅ UUID Stability verified: \(firstUUID)")
    }

    /// Test: Goals have stable UUIDs across multiple fetches
    @Test func testGoalsHaveStableUUIDs() async throws {
        // Use default configuration (automatically resolves to shared database)
        let db = try await DatabaseManager(configuration: .default)

        // Fetch goals first time
        let goals1 = try await db.fetchGoals()
        #expect(goals1.count > 0, "Should have goals in database")

        guard let firstGoal = goals1.first else {
            Issue.record("Should have at least one goal")
            return
        }
        let firstUUID = firstGoal.id

        // Fetch goals second time
        let goals2 = try await db.fetchGoals()

        let matchingGoal = goals2.first { $0.title == firstGoal.title }
        #expect(matchingGoal != nil, "Should find same goal on second fetch")

        // Verify UUID is identical
        #expect(
            matchingGoal?.id == firstUUID,
            "UUID should be stable across fetches"
        )

        print("✅ UUID Stability verified: \(firstUUID)")
    }
}
