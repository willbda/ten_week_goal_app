// UUIDStabilityTests.swift
// Tests that UUIDs remain stable across multiple fetches
//
// Written by Claude Code on 2025-10-19

import XCTest
import GRDB
@testable import Database
@testable import Models

final class UUIDStabilityTests: XCTestCase {

    private var dbQueue: DatabaseQueue!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Use absolute path (relative paths don't work in test environment)
        let databasePath = "/Users/davidwilliams/Documents/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/shared/database/application_data.db"

        guard FileManager.default.fileExists(atPath: databasePath) else {
            throw NSError(
                domain: "UUIDStabilityTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Database not found at: \(databasePath)"]
            )
        }

        dbQueue = try DatabaseQueue(path: databasePath)
    }

    override func tearDownWithError() throws {
        dbQueue = nil
        try super.tearDownWithError()
    }

    /// Test: Actions have stable UUIDs across multiple fetches
    ///
    /// Verifies that fetching the same database record multiple times
    /// returns the same UUID each time (not random).
    func testActionsHaveStableUUIDs() async throws {
        // Create database manager with UUID mapping
        let config = DatabaseConfiguration(
            databasePath: URL(fileURLWithPath: "/Users/davidwilliams/Documents/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/shared/database/application_data.db"),
            schemaDirectory: URL(fileURLWithPath: "/Users/davidwilliams/Documents/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/shared/schemas"),
            isInMemory: false
        )
        let db = try await DatabaseManager(configuration: config)

        // Fetch actions first time
        let actions1 = try await db.fetchActions()
        XCTAssertGreaterThan(actions1.count, 0, "Should have actions in database")

        // Get first action's UUID
        guard let firstAction = actions1.first else {
            XCTFail("Should have at least one action")
            return
        }
        let firstUUID = firstAction.id

        // Fetch actions second time
        let actions2 = try await db.fetchActions()

        // Find same action (by friendlyName since that's what identifies it)
        let matchingAction = actions2.first { $0.friendlyName == firstAction.friendlyName }
        XCTAssertNotNil(matchingAction, "Should find same action on second fetch")

        // Verify UUID is identical
        XCTAssertEqual(
            matchingAction?.id,
            firstUUID,
            "UUID should be stable across fetches"
        )

        print("✅ UUID Stability verified: \(firstUUID)")
    }

    /// Test: Goals have stable UUIDs across multiple fetches
    func testGoalsHaveStableUUIDs() async throws {
        let config = DatabaseConfiguration(
            databasePath: URL(fileURLWithPath: "/Users/davidwilliams/Documents/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/shared/database/application_data.db"),
            schemaDirectory: URL(fileURLWithPath: "/Users/davidwilliams/Documents/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/shared/schemas"),
            isInMemory: false
        )
        let db = try await DatabaseManager(configuration: config)

        // Fetch goals first time
        let goals1 = try await db.fetchGoals()
        XCTAssertGreaterThan(goals1.count, 0, "Should have goals in database")

        guard let firstGoal = goals1.first else {
            XCTFail("Should have at least one goal")
            return
        }
        let firstUUID = firstGoal.id

        // Fetch goals second time
        let goals2 = try await db.fetchGoals()

        let matchingGoal = goals2.first { $0.friendlyName == firstGoal.friendlyName }
        XCTAssertNotNil(matchingGoal, "Should find same goal on second fetch")

        // Verify UUID is identical
        XCTAssertEqual(
            matchingGoal?.id,
            firstUUID,
            "UUID should be stable across fetches"
        )

        print("✅ UUID Stability verified: \(firstUUID)")
    }
}
