// ActionTests.swift
// Tests for Action domain entity
//
// Written by Claude Code on 2025-10-17
// Updated 2025-10-18: Consolidated to essential tests
// Updated 2025-10-21: Converted to modern Swift Testing framework
// Ported from Python implementation (python/tests/test_actions.py)

import Foundation
import Testing
@testable import Models

/// Test suite for Action domain entity
///
/// Verifies action creation, validation rules, and throwing validation.
@Suite("Action Tests")
struct ActionTests {

    // MARK: - Creation & Defaults

    @Test("Creates minimal action with defaults")
    func minimalActionCreation() {
        let action = Action(friendlyName: "Morning run")

        #expect(action.friendlyName == "Morning run")
        #expect(action.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(action.logTime != nil)
        #expect(action.measuresByUnit == nil)
        #expect(action.durationMinutes == nil)
        #expect(action.startTime == nil)
    }

    @Test("Creates fully populated action")
    func fullyPopulatedAction() {
        let action = Action(
            friendlyName: "Interval training",
            detailedDescription: "High intensity workout",
            freeformNotes: "Felt great!",
            measuresByUnit: [
                "distance_miles": 3.2,
                "pace_min_per_mile": 8.5,
                "avg_heart_rate": 145.0
            ],
            durationMinutes: 45.0,
            startTime: Date()
        )

        #expect(action.isValid())
        #expect(action.measuresByUnit?.count == 3)
        #expect(action.detailedDescription == "High intensity workout")
    }

    // MARK: - Validation Rules

    @Test("Validates positive measurements")
    func measurementValidationPositive() {
        var validAction = Action(friendlyName: "Run")
        validAction.measuresByUnit = ["distance_km": 5.0]
        #expect(validAction.isValid())
    }

    @Test("Rejects negative measurements")
    func measurementValidationNegative() {
        var negativeAction = Action(friendlyName: "Run")
        negativeAction.measuresByUnit = ["distance_km": -5.0]
        #expect(!negativeAction.isValid())
    }

    @Test("Rejects zero measurements")
    func measurementValidationZero() {
        var zeroAction = Action(friendlyName: "Run")
        zeroAction.measuresByUnit = ["distance_km": 0.0]
        #expect(!zeroAction.isValid())
    }

    @Test("Rejects start time without duration")
    func startTimeRequiresDuration() {
        var invalid = Action(friendlyName: "Workout")
        invalid.startTime = Date()
        #expect(!invalid.isValid())
    }

    @Test("Accepts start time with duration")
    func startTimeWithDuration() {
        var valid = Action(friendlyName: "Workout")
        valid.startTime = Date()
        valid.durationMinutes = 45.0
        #expect(valid.isValid())
    }

    @Test("Accepts duration without start time")
    func durationWithoutStartTime() {
        var validDurationOnly = Action(friendlyName: "Workout")
        validDurationOnly.durationMinutes = 30.0
        #expect(validDurationOnly.isValid())
    }

    // MARK: - Throwing Validation

    @Test("Throwing validation succeeds for valid action")
    func throwingValidationSuccess() throws {
        let validAction = Action(
            friendlyName: "Run",
            measuresByUnit: ["km": 5.0],
            durationMinutes: 30.0,
            startTime: Date()
        )
        try validAction.validate()
        // If we get here, validation succeeded
        #expect(true)
    }

    @Test("Throwing validation fails for negative measurement")
    func throwingValidationNegativeMeasurement() {
        var action = Action(friendlyName: "Run")
        action.measuresByUnit = ["km": -5.0]

        #expect(throws: ValidationError.self) {
            try action.validate()
        }
    }

    @Test("Throwing validation fails for missing duration with start time")
    func throwingValidationMissingDuration() {
        var action = Action(friendlyName: "Workout")
        action.startTime = Date()
        // Missing durationMinutes

        #expect(throws: ValidationError.self) {
            try action.validate()
        }
    }

    @Test("Throwing validation provides correct error for negative measurement")
    func throwingValidationNegativeMeasurementDetails() {
        var action = Action(friendlyName: "Run")
        action.measuresByUnit = ["km": -5.0]

        do {
            try action.validate()
            #expect(Bool(false), "Should have thrown ValidationError")
        } catch let error as ValidationError {
            if case .invalidValue(let field, let value, let reason) = error {
                #expect(field == "measurement[km]")
                #expect(value == "-5.0")
                #expect(reason.contains("positive"))
            } else {
                #expect(Bool(false), "Wrong ValidationError case")
            }
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Throwing validation provides correct error for missing duration")
    func throwingValidationMissingDurationDetails() {
        var action = Action(friendlyName: "Workout")
        action.startTime = Date()

        do {
            try action.validate()
            #expect(Bool(false), "Should have thrown ValidationError")
        } catch let error as ValidationError {
            if case .missingRequiredField(let field, let context) = error {
                #expect(field == "durationMinutes")
                #expect(context.contains("startTime"))
            } else {
                #expect(Bool(false), "Wrong ValidationError case")
            }
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    // MARK: - Equality (UUID-based)

    @Test("Actions are equal with same UUID")
    func equalityBasedOnUUID() {
        let sharedID = UUID()
        let action1 = Action(friendlyName: "Run", id: sharedID)
        let action2 = Action(friendlyName: "Sprint", id: sharedID)

        // Same UUID = equal, even with different names
        #expect(action1 == action2)
    }

    @Test("Actions are not equal with different UUIDs")
    func inequalityDifferentUUIDs() {
        let action1 = Action(friendlyName: "Run", id: UUID())
        let action2 = Action(friendlyName: "Run", id: UUID())

        #expect(action1 != action2)
    }
}
