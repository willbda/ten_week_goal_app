// ActionTests.swift
// Tests for Action domain entity
//
// Written by Claude Code on 2025-10-17
// Mirrors Python test patterns from tests/test_actions.py

import XCTest
@testable import Categoriae

final class ActionTests: XCTestCase {

    // MARK: - Basic Creation Tests

    func testActionCreationWithCommonName() {
        let action = Action(commonName: "Did pushups")

        XCTAssertEqual(action.commonName, "Did pushups")
        XCTAssertNotNil(action.logTime)
        XCTAssertNil(action.id) // New action has no ID
    }

    func testActionHasOptionalAttributes() {
        let action = Action(commonName: "Ran")

        XCTAssertNil(action.measurementUnitsByAmount)
        XCTAssertNil(action.durationMinutes)
        XCTAssertNil(action.startTime)
    }

    // MARK: - Validation Tests

    func testValidActionWithMeasurements() {
        var action = Action(commonName: "Ran 3 miles")
        action.measurementUnitsByAmount = [
            "distance_miles": 3.0,
            "duration_minutes": 30.0
        ]

        XCTAssertTrue(action.isValid())
    }

    func testInvalidActionWithNegativeMeasurement() {
        var action = Action(commonName: "Ran")
        action.measurementUnitsByAmount = ["distance_miles": -5.0]

        XCTAssertFalse(action.isValid())
    }

    func testInvalidActionWithZeroMeasurement() {
        var action = Action(commonName: "Ran")
        action.measurementUnitsByAmount = ["distance_miles": 0.0]

        XCTAssertFalse(action.isValid())
    }

    func testInvalidActionStartTimeWithoutDuration() {
        var action = Action(commonName: "Workout")
        action.startTime = Date()
        // duration_minutes is nil

        XCTAssertFalse(action.isValid())
    }

    func testValidActionWithStartTimeAndDuration() {
        var action = Action(commonName: "Workout")
        action.startTime = Date()
        action.durationMinutes = 45.0

        XCTAssertTrue(action.isValid())
    }

    // MARK: - Edge Cases

    func testActionWithEmptyCommonName() {
        let action = Action(commonName: "")

        XCTAssertEqual(action.commonName, "")
        // Note: isValid() doesn't check this - design decision matching Python
    }

    func testActionWithMixedMeasurements() {
        var action = Action(commonName: "Complex workout")
        action.measurementUnitsByAmount = [
            "weight_lbs": 150.0,
            "reps": 20.0,
            "sets": 3.0
        ]

        XCTAssertTrue(action.isValid())
        XCTAssertEqual(action.measurementUnitsByAmount?.count, 3)
    }

    // MARK: - Equatable Tests

    func testActionEquality() {
        let action1 = Action(commonName: "Test", id: 1)
        let action2 = Action(commonName: "Test", id: 1)

        XCTAssertEqual(action1, action2)
    }

    func testActionInequality() {
        let action1 = Action(commonName: "Test 1", id: 1)
        let action2 = Action(commonName: "Test 2", id: 2)

        XCTAssertNotEqual(action1, action2)
    }
}
