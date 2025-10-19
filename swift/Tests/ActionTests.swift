// ActionTests.swift
// Tests for Action domain entity
//
// Written by Claude Code on 2025-10-17
// Updated 2025-10-18: Consolidated to essential tests
// Ported from Python implementation (python/tests/test_actions.py)

import XCTest
@testable import Models

final class ActionTests: XCTestCase {

    // MARK: - Creation & Defaults

    func testMinimalActionCreation() {
        let action = Action(friendlyName: "Morning run")

        XCTAssertEqual(action.friendlyName, "Morning run")
        XCTAssertNotNil(action.id) // UUID auto-generated
        XCTAssertNotNil(action.logTime) // Defaults to Date()
        XCTAssertNil(action.measurementUnitsByAmount)
        XCTAssertNil(action.durationMinutes)
        XCTAssertNil(action.startTime)
    }

    func testFullyPopulatedAction() {
        let action = Action(
            friendlyName: "Interval training",
            detailedDescription: "High intensity workout",
            freeformNotes: "Felt great!",
            measurementUnitsByAmount: [
                "distance_miles": 3.2,
                "pace_min_per_mile": 8.5,
                "avg_heart_rate": 145.0
            ],
            durationMinutes: 45.0,
            startTime: Date()
        )

        XCTAssertTrue(action.isValid())
        XCTAssertEqual(action.measurementUnitsByAmount?.count, 3)
        XCTAssertEqual(action.detailedDescription, "High intensity workout")
    }

    // MARK: - Validation Rules

    func testMeasurementValidation() {
        // Valid: positive measurements
        var validAction = Action(friendlyName: "Run")
        validAction.measurementUnitsByAmount = ["distance_km": 5.0]
        XCTAssertTrue(validAction.isValid())

        // Invalid: negative measurement
        var negativeAction = Action(friendlyName: "Run")
        negativeAction.measurementUnitsByAmount = ["distance_km": -5.0]
        XCTAssertFalse(negativeAction.isValid())

        // Invalid: zero measurement
        var zeroAction = Action(friendlyName: "Run")
        zeroAction.measurementUnitsByAmount = ["distance_km": 0.0]
        XCTAssertFalse(zeroAction.isValid())
    }

    func testStartTimeDurationRule() {
        // Invalid: startTime without duration
        var invalid = Action(friendlyName: "Workout")
        invalid.startTime = Date()
        XCTAssertFalse(invalid.isValid())

        // Valid: startTime WITH duration
        var valid = Action(friendlyName: "Workout")
        valid.startTime = Date()
        valid.durationMinutes = 45.0
        XCTAssertTrue(valid.isValid())

        // Valid: duration without startTime (allowed)
        var validDurationOnly = Action(friendlyName: "Workout")
        validDurationOnly.durationMinutes = 30.0
        XCTAssertTrue(validDurationOnly.isValid())
    }

    // MARK: - Equality (UUID-based)

    func testEqualityBasedOnUUID() {
        let sharedID = UUID()
        let action1 = Action(id: sharedID, friendlyName: "Run")
        let action2 = Action(id: sharedID, friendlyName: "Sprint") // Different name!

        // Same UUID = equal, even with different names
        XCTAssertEqual(action1, action2)

        // Different UUIDs = not equal
        let action3 = Action(id: UUID(), friendlyName: "Run")
        XCTAssertNotEqual(action1, action3)
    }
}
