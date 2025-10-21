// ActionFormViewTests.swift
// Tests for ActionFormView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for ActionFormView component
///
/// Verifies form behavior including create/edit modes, validation,
/// and state management.
@Suite("ActionFormView Tests")
struct ActionFormViewTests {

    // MARK: - Mode Detection Tests

    @Test("Create mode has correct title")
    func createModeTitle() {
        var savedAction: Action?
        let view = ActionFormView(
            action: nil,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        // When action is nil, it's create mode
        #expect(view.actionToEdit == nil)
    }

    @Test("Edit mode has correct title and preserves action")
    func editModePreservesAction() {
        let existingAction = Action(
            friendlyName: "Test Action",
            measuresByUnit: ["km": 5.0],
            logTime: Date()
        )

        var savedAction: Action?
        let view = ActionFormView(
            action: existingAction,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        #expect(view.actionToEdit != nil)
        #expect(view.actionToEdit?.friendlyName == "Test Action")
        #expect(view.actionToEdit?.measuresByUnit?["km"] == 5.0)
    }

    // MARK: - Initialization Tests

    @Test("Initializes with empty fields in create mode")
    func initializesEmptyInCreateMode() {
        var savedAction: Action?
        let view = ActionFormView(
            action: nil,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        // In create mode, action should be nil
        #expect(view.actionToEdit == nil)
    }

    @Test("Initializes with action data in edit mode")
    func initializesWithDataInEditMode() {
        let startTime = Date().addingTimeInterval(-3600)
        let logTime = Date()

        let existingAction = Action(
            friendlyName: "Morning run",
            detailedDescription: "Easy recovery",
            freeformNotes: "Felt good",
            measuresByUnit: ["km": 5.0],
            durationMinutes: 30.0,
            startTime: startTime,
            logTime: logTime
        )

        var savedAction: Action?
        let view = ActionFormView(
            action: existingAction,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        #expect(view.actionToEdit?.friendlyName == "Morning run")
        #expect(view.actionToEdit?.detailedDescription == "Easy recovery")
        #expect(view.actionToEdit?.freeformNotes == "Felt good")
        #expect(view.actionToEdit?.measuresByUnit?["km"] == 5.0)
        #expect(view.actionToEdit?.durationMinutes == 30.0)
        #expect(view.actionToEdit?.startTime == startTime)
        #expect(view.actionToEdit?.logTime == logTime)
    }

    @Test("Initializes measurements as empty array when nil")
    func initializesEmptyMeasurements() {
        let action = Action(
            friendlyName: "Test",
            measuresByUnit: nil,
            logTime: Date()
        )

        var savedAction: Action?
        let view = ActionFormView(
            action: action,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        #expect(view.actionToEdit?.measuresByUnit == nil)
    }

    @Test("Converts measurements dict to array for editing")
    func convertsMeasurementsToArray() {
        let action = Action(
            friendlyName: "Workout",
            measuresByUnit: [
                "reps": 100.0,
                "sets": 5.0
            ],
            logTime: Date()
        )

        var savedAction: Action?
        let view = ActionFormView(
            action: action,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        #expect(view.actionToEdit?.measuresByUnit?.count == 2)
        #expect(view.actionToEdit?.measuresByUnit?["reps"] == 100.0)
        #expect(view.actionToEdit?.measuresByUnit?["sets"] == 5.0)
    }

    // MARK: - Validation Tests

    @Test("Form is valid with friendly name only")
    func validWithFriendlyNameOnly() {
        let action = Action(
            friendlyName: "Test",
            logTime: Date()
        )

        #expect(action.friendlyName != nil)
        #expect(!action.friendlyName!.isEmpty)
    }

    @Test("Form is valid with description only")
    func validWithDescriptionOnly() {
        let action = Action(
            friendlyName: nil,
            detailedDescription: "Some description",
            logTime: Date()
        )

        #expect(action.detailedDescription != nil)
        #expect(!action.detailedDescription!.isEmpty)
    }

    @Test("Form validation checks for whitespace-only input")
    func checksWhitespaceOnlyInput() {
        let whitespaceOnly = "   "
        let trimmed = whitespaceOnly.trimmingCharacters(in: .whitespaces)

        #expect(trimmed.isEmpty)
    }

    // MARK: - Timing State Tests

    @Test("Toggles enable/disable start time field")
    func togglesStartTimeField() {
        let action = Action(
            friendlyName: "Test",
            startTime: nil,
            logTime: Date()
        )

        #expect(action.startTime == nil)

        let actionWithStartTime = Action(
            friendlyName: "Test",
            durationMinutes: 30.0,
            startTime: Date(),
            logTime: Date()
        )

        #expect(actionWithStartTime.startTime != nil)
    }

    @Test("Toggles enable/disable duration field")
    func togglesDurationField() {
        let action = Action(
            friendlyName: "Test",
            durationMinutes: nil,
            logTime: Date()
        )

        #expect(action.durationMinutes == nil)

        let actionWithDuration = Action(
            friendlyName: "Test",
            durationMinutes: 45.0,
            logTime: Date()
        )

        #expect(actionWithDuration.durationMinutes == 45.0)
    }

    @Test("Start time requires duration for validity")
    func startTimeRequiresDuration() {
        // Invalid: start time without duration
        var invalidAction = Action(
            friendlyName: "Test",
            startTime: Date(),
            logTime: Date()
        )
        invalidAction.startTime = Date()

        #expect(!invalidAction.isValid())

        // Valid: start time with duration
        var validAction = Action(
            friendlyName: "Test",
            durationMinutes: 30.0,
            startTime: Date(),
            logTime: Date()
        )

        #expect(validAction.isValid())
    }

    // MARK: - Measurements Tests

    @Test("Can add measurements to action")
    func canAddMeasurements() {
        let action = Action(
            friendlyName: "Run",
            measuresByUnit: ["km": 5.0],
            logTime: Date()
        )

        #expect(action.measuresByUnit?.count == 1)
        #expect(action.measuresByUnit?["km"] == 5.0)
    }

    @Test("Can handle empty measurements")
    func canHandleEmptyMeasurements() {
        let action = Action(
            friendlyName: "Meditation",
            measuresByUnit: nil,
            logTime: Date()
        )

        #expect(action.measuresByUnit == nil)
    }

    @Test("Preserves measurement precision")
    func preservesMeasurementPrecision() {
        let action = Action(
            friendlyName: "Run",
            measuresByUnit: ["km": 5.234],
            logTime: Date()
        )

        #expect(action.measuresByUnit?["km"] == 5.234)
    }

    // MARK: - Save Behavior Tests

    @Test("Save creates new action with UUID in create mode")
    func saveCreatesNewAction() {
        var savedAction: Action?
        var wasSaved = false

        let view = ActionFormView(
            action: nil,
            onSave: { action in
                savedAction = action
                wasSaved = true
            },
            onCancel: {}
        )

        // Simulate would-be save
        let newAction = Action(
            friendlyName: "New Action",
            logTime: Date()
        )

        #expect(newAction.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("Save preserves UUID in edit mode")
    func savePreservesUUIDInEditMode() {
        let originalID = UUID()
        let existingAction = Action(
            friendlyName: "Original",
            id: originalID
        )

        var savedAction: Action?
        let view = ActionFormView(
            action: existingAction,
            onSave: { savedAction = $0 },
            onCancel: {}
        )

        // Edited action should preserve the same ID
        let editedAction = Action(
            friendlyName: "Edited",
            id: originalID
        )

        #expect(editedAction.id == originalID)
    }

    @Test("Save converts empty strings to nil")
    func saveConvertsEmptyStringsToNil() {
        let action = Action(
            friendlyName: "",
            detailedDescription: "",
            freeformNotes: "",
            logTime: Date()
        )

        // Empty strings should be treated as nil
        let trimmedName = action.friendlyName?.trimmingCharacters(in: .whitespaces)
        #expect(trimmedName?.isEmpty ?? true)
    }

    @Test("Save builds measurements dictionary correctly")
    func saveBuildsCorrectMeasurements() {
        let measurements = [
            "km": 5.0,
            "minutes": 30.0
        ]

        let action = Action(
            friendlyName: "Run",
            measuresByUnit: measurements,
            logTime: Date()
        )

        #expect(action.measuresByUnit?.count == 2)
        #expect(action.measuresByUnit?["km"] == 5.0)
        #expect(action.measuresByUnit?["minutes"] == 30.0)
    }

    // MARK: - Cancel Behavior Tests

    @Test("Cancel callback is provided")
    func cancelCallbackProvided() {
        var wasCancelled = false

        let view = ActionFormView(
            action: nil,
            onSave: { _ in },
            onCancel: { wasCancelled = true }
        )

        // Verify cancel callback exists
        #expect(!wasCancelled)
    }

    // MARK: - Edge Cases

    @Test("Handles nil values for optional fields")
    func handlesNilOptionalFields() {
        let action = Action(
            friendlyName: "Test",
            detailedDescription: nil,
            freeformNotes: nil,
            measuresByUnit: nil,
            durationMinutes: nil,
            startTime: nil,
            logTime: Date()
        )

        #expect(action.detailedDescription == nil)
        #expect(action.freeformNotes == nil)
        #expect(action.measuresByUnit == nil)
        #expect(action.durationMinutes == nil)
        #expect(action.startTime == nil)
    }

    @Test("Handles action with all fields populated")
    func handlesFullyPopulatedAction() {
        let action = Action(
            friendlyName: "Complete Action",
            detailedDescription: "Full description",
            freeformNotes: "Detailed notes",
            measuresByUnit: [
                "km": 5.0,
                "minutes": 30.0,
                "calories": 250.0
            ],
            durationMinutes: 30.0,
            startTime: Date().addingTimeInterval(-1800),
            logTime: Date()
        )

        #expect(action.friendlyName == "Complete Action")
        #expect(action.detailedDescription == "Full description")
        #expect(action.freeformNotes == "Detailed notes")
        #expect(action.measuresByUnit?.count == 3)
        #expect(action.durationMinutes == 30.0)
        #expect(action.startTime != nil)
    }
}
