//  ActionGRDBTests.swift
//  Integration tests for Action with direct GRDB conformance
//
//  Written by Claude Code on 2025-10-22
//  Updated by Claude Code on 2025-10-22 (use .temporary config for WAL mode)
//  Proof-of-concept: Tests that Action can be used directly with GRDB
//  without intermediate Record types (ActionRecord).
//
//  This test suite proves:
//  1. Action conforms to FetchableRecord, PersistableRecord, TableRecord
//  2. Can save/fetch actions using generic GRDB methods
//  3. Proper column mapping via CodingKeys
//  4. No need for entity-specific database methods
//
//  Note: Uses .temporary configuration (not .inMemory) because WAL mode
//  doesn't work with in-memory databases.

import Testing
import GRDB
import Foundation
@testable import Models
@testable import Database

/// Integration tests for Action with direct GRDB conformance
///
/// This test suite verifies that Action can be used directly with GRDB's
/// generic database operations without requiring a separate Record type.
@Suite("Action GRDB Integration")
struct ActionGRDBTests {

    // MARK: - Basic CRUD Operations

    @Test("Action can be saved and fetched using GRDB directly")
    @MainActor
    func actionRoundTrip() async throws {
        // Setup temporary database (WAL mode compatible)
        let db = try await DatabaseManager(configuration: .temporary)

        // Create action with various properties
        var action = Action(
            title: "Test Run",
            detailedDescription: "Morning 5K run",
            measuresByUnit: ["km": 5.0, "minutes": 30],
            logTime: Date()
        )

        // Save using generic GRDB method (not entity-specific!)
        try await db.save(&action)

        // Fetch using generic GRDB method
        let fetched: [Action] = try await db.fetchAll()

        // Verify results
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Test Run")
        #expect(fetched.first?.detailedDescription == "Morning 5K run")
        #expect(fetched.first?.measuresByUnit?["km"] == 5.0)
        #expect(fetched.first?.measuresByUnit?["minutes"] == 30)
    }

    @Test("Action UUID is preserved after save")
    @MainActor
    func actionUUIDPreservation() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create action (gets UUID in init)
        var action = Action(
            title: "UUID Test",
            logTime: Date()
        )

        let originalId = action.id

        // Save action
        try await db.save(&action)

        // Fetch and verify UUID matches
        let fetched: [Action] = try await db.fetchAll()
        #expect(fetched.first?.id == originalId)
    }

    @Test("Action can be fetched by ID")
    @MainActor
    func actionFetchById() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create and save action
        var action = Action(
            title: "Fetch Test",
            logTime: Date()
        )
        try await db.save(&action)

        // Fetch by ID using generic method
        let fetched = try await db.fetchOne(Action.self, id: action.id)

        // Verify
        #expect(fetched != nil)
        #expect(fetched?.title == "Fetch Test")
        #expect(fetched?.id == action.id)
    }

    // MARK: - Optional Fields

    @Test("Action with minimal fields can be saved")
    @MainActor
    func actionMinimalFields() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create action with only required field (logTime has default)
        var action = Action(title: "Minimal")

        try await db.save(&action)

        let fetched: [Action] = try await db.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Minimal")
        #expect(fetched.first?.detailedDescription == nil)
        #expect(fetched.first?.measuresByUnit == nil)
    }

    @Test("Action with all optional fields can be saved")
    @MainActor
    func actionAllFields() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        let startTime = Date().addingTimeInterval(-3600)  // 1 hour ago
        let logTime = Date()

        var action = Action(
            title: "Complete Action",
            detailedDescription: "Detailed description here",
            freeformNotes: "Some notes",
            measuresByUnit: ["km": 10.0, "calories": 500],
            durationMinutes: 60,
            startTime: startTime,
            logTime: logTime
        )

        try await db.save(&action)

        let fetched: [Action] = try await db.fetchAll()
        #expect(fetched.count == 1)

        let result = try #require(fetched.first)
        #expect(result.title == "Complete Action")
        #expect(result.detailedDescription == "Detailed description here")
        #expect(result.freeformNotes == "Some notes")
        #expect(result.measuresByUnit?["km"] == 10.0)
        #expect(result.measuresByUnit?["calories"] == 500)
        #expect(result.durationMinutes == 60)
        #expect(result.startTime != nil)
    }

    // MARK: - Multiple Records

    @Test("Multiple actions can be saved and retrieved")
    @MainActor
    func multipleActions() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create multiple actions
        var action1 = Action(title: "First", measuresByUnit: ["km": 5.0])
        var action2 = Action(title: "Second", measuresByUnit: ["km": 10.0])
        var action3 = Action(title: "Third", measuresByUnit: ["km": 15.0])

        try await db.save(&action1)
        try await db.save(&action2)
        try await db.save(&action3)

        // Fetch all
        let fetched: [Action] = try await db.fetchAll()

        // Verify
        #expect(fetched.count == 3)
        let titles = fetched.compactMap { $0.title }
        #expect(titles.contains("First"))
        #expect(titles.contains("Second"))
        #expect(titles.contains("Third"))
    }

    // MARK: - Update Operations

    @Test("Action can be updated")
    @MainActor
    func actionUpdate() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create and save initial action
        var action = Action(
            title: "Original Title",
            measuresByUnit: ["km": 5.0]
        )
        try await db.save(&action)

        // Modify and update
        action.title = "Updated Title"
        action.measuresByUnit = ["km": 10.0]
        try await db.update(action)

        // Fetch and verify update
        let fetched = try await db.fetchOne(Action.self, id: action.id)
        #expect(fetched?.title == "Updated Title")
        #expect(fetched?.measuresByUnit?["km"] == 10.0)
    }

    // MARK: - Delete Operations

    @Test("Action can be deleted")
    @MainActor
    func actionDelete() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create and save action
        var action = Action(title: "To Delete")
        try await db.save(&action)

        // Verify it exists
        var fetched: [Action] = try await db.fetchAll()
        #expect(fetched.count == 1)

        // Delete
        try await db.delete(Action.self, id: action.id)

        // Verify it's gone
        fetched = try await db.fetchAll()
        #expect(fetched.count == 0)
    }

    // MARK: - Edge Cases

    @Test("Action with empty measurements dictionary")
    @MainActor
    func actionEmptyMeasurements() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        var action = Action(
            title: "Empty Measures",
            measuresByUnit: [:]  // Empty dict
        )

        try await db.save(&action)

        let fetched: [Action] = try await db.fetchAll()
        #expect(fetched.first?.measuresByUnit != nil)
        #expect(fetched.first?.measuresByUnit?.isEmpty == true)
    }

    @Test("Action with zero duration")
    @MainActor
    func actionZeroDuration() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        var action = Action(
            title: "Zero Duration",
            durationMinutes: 0.0
        )

        try await db.save(&action)

        let fetched: [Action] = try await db.fetchAll()
        #expect(fetched.first?.durationMinutes == 0.0)
    }

    @Test("Action with very large measurements")
    @MainActor
    func actionLargeMeasurements() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        var action = Action(
            title: "Large Values",
            measuresByUnit: [
                "meters": 1_000_000.0,
                "calories": 999_999.99,
                "steps": 50_000.0
            ]
        )

        try await db.save(&action)

        let fetched: [Action] = try await db.fetchAll()
        #expect(fetched.first?.measuresByUnit?["meters"] == 1_000_000.0)
        #expect(fetched.first?.measuresByUnit?["calories"] == 999_999.99)
        #expect(fetched.first?.measuresByUnit?["steps"] == 50_000.0)
    }
}
