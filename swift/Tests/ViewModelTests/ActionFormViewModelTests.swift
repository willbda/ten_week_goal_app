// ActionFormViewModelTests.swift
// Created: 2025-11-06
//
// PURPOSE: Test ActionFormViewModel coordinator integration and error handling
//
// GENUINE QUESTIONS THIS FILE ANSWERS:
//
// 1. COORDINATOR INVOCATION:
//    Q: When save() called, does ViewModel actually invoke coordinator.create()?
//    Q: Is coordinator.create() called with correctly assembled FormData?
//    Q: Are individual params (title, measurements, goals) correctly mapped to FormData?
//    Why: ViewModel might have logic error that skips coordinator call.
//
// 2. ERROR PROPAGATION:
//    Q: When coordinator throws ValidationError, does ViewModel set errorMessage?
//    Q: Is errorMessage user-friendly (not raw Swift error)?
//    Q: Does error clear on next successful save?
//    Why: Error handling chain could drop exceptions.
//
// 3. STATE MANAGEMENT:
//    Q: Is isSaving true during async save operation?
//    Q: Is isSaving false after save completes (both success and error)?
//    Q: Does @Observable trigger SwiftUI updates for these state changes?
//    Why: Loading states might not update correctly.
//
// 4. RESULT PROPAGATION:
//    Q: Does save() return the created Action?
//    Q: Does returned Action have valid ID and fields?
//    Q: Does update() return the updated Action?
//    Why: ViewModel might return stale data or wrong entity.
//
// 5. FORM DATA ASSEMBLY:
//    Q: Are measurements array correctly converted to [MeasurementInput]?
//    Q: Are goal IDs correctly converted to [GoalContributionInput]?
//    Q: Do optional fields (durationMinutes, startTime) handle nil correctly?
//    Why: Data mapping could lose information or mistype.
//
// 6. UPDATE SEMANTICS:
//    Q: Does update() preserve Action.id from original?
//    Q: Does update() call coordinator.update() not create()?
//    Q: Are modified fields sent to coordinator?
//    Why: Update might accidentally create new entity.
//
// 7. DELETE SEMANTICS:
//    Q: Does delete() actually invoke coordinator.delete()?
//    Q: Does delete() handle cascade (measurements, contributions)?
//    Q: Does errorMessage clear on successful delete?
//    Why: Delete might not fully execute or handle errors.
//
// WHAT WE'RE NOT TESTING:
// - That ViewModel has save/update/delete methods (obvious from code)
// - That ViewModel uses @Observable (obvious from code)
// - Coordinator logic (that's coordinator tests)
// - Database persistence (that's coordinator tests)
//
// TEST STRUCTURE:
// - Use in-memory DatabaseQueue
// - Create ViewModel with test database
// - Call ViewModel methods, verify coordinator invoked
// - Check state changes (isSaving, errorMessage)
// - Verify returned data correctness

import Foundation
import Testing
import SQLiteData
@testable import App
@testable import Services
@testable import Models

@Suite("ActionFormViewModel - Coordinator Integration")
struct ActionFormViewModelTests {

    // MARK: - Test Questions: Save Operation

    // Q: Does save() with valid data successfully create Action?
    // How to test: Call viewModel.save(...), verify returned Action has valid ID
    // Why: ViewModel might have logic error preventing save
    // @Test("Save: Creates Action with valid ID")

    // Q: Does save() set isSaving=true during operation?
    // How to test: Monitor isSaving during async save call
    // Why: Loading state might not update
    // @Test("Save: Sets isSaving=true during operation")

    // Q: Does save() set isSaving=false after completion?
    // How to test: Call save(), await completion, verify isSaving=false
    // Why: defer block might not execute
    // @Test("Save: Sets isSaving=false after completion")

    // Q: Does save() set isSaving=false even on error?
    // How to test: Call save with invalid data, verify isSaving=false after throw
    // Why: defer block might be skipped on throw
    // @Test("Save: Sets isSaving=false even on error")

    // Q: Does save() correctly assemble FormData from params?
    // How to test: Pass specific params, verify coordinator receives correct FormData (mock coordinator?)
    // Why: Field mapping could have bugs
    // @Test("Save: Assembles FormData correctly from params")

    // Q: Does save() pass measurements array correctly?
    // How to test: Save with 2 measurements, verify coordinator receives both
    // Why: Array conversion could lose items
    // @Test("Save: Passes measurements array correctly")

    // Q: Does save() pass goal contributions correctly?
    // How to test: Save with 2 goal IDs, verify coordinator receives both
    // Why: ID array could be truncated
    // @Test("Save: Passes goal contributions correctly")

    // MARK: - Test Questions: Error Handling

    // Q: When coordinator throws ValidationError, is errorMessage set?
    // How to test: Save invalid data, catch error, verify errorMessage not nil
    // Why: Error handling chain could drop error
    // @Test("Save: Sets errorMessage on ValidationError")

    // Q: Is errorMessage user-friendly?
    // How to test: Trigger error, verify errorMessage contains actionable text (not "Optional(...)")
    // Why: Error message could be raw Swift error string
    // @Test("Save: errorMessage is user-friendly")

    // Q: Does errorMessage clear on next successful save?
    // How to test: Trigger error, then save valid data, verify errorMessage=nil
    // Why: Old errors might persist
    // @Test("Save: Clears errorMessage on successful save")

    // Q: When coordinator throws database error, is it caught?
    // How to test: Force database error (read-only), verify error handled gracefully
    // Why: Non-validation errors might crash
    // @Test("Save: Handles database errors gracefully")

    // MARK: - Test Questions: Update Operation

    // Q: Does update() preserve Action.id from original?
    // How to test: Create action, update title, verify ID unchanged
    // Why: Update might generate new ID
    // @Test("Update: Preserves original Action.id")

    // Q: Does update() call coordinator.update() not create()?
    // How to test: Update existing action, verify coordinator.update() invoked (mock?)
    // Why: Might accidentally call create()
    // @Test("Update: Calls coordinator.update() not create()")

    // Q: Does update() correctly pass ActionWithDetails?
    // How to test: Update action with measurements, verify all data passed to coordinator
    // Why: Complex wrapper type could be mishandled
    // @Test("Update: Passes ActionWithDetails correctly")

    // Q: Can update add new measurements?
    // How to test: Update to add measurement, verify coordinator receives new measurements array
    // Why: Array manipulation could have bugs
    // @Test("Update: Can add new measurements")

    // Q: Can update remove measurements?
    // How to test: Update to remove measurement, verify coordinator receives reduced array
    // Why: Array filtering could be wrong
    // @Test("Update: Can remove measurements")

    // MARK: - Test Questions: Delete Operation

    // Q: Does delete() actually invoke coordinator.delete()?
    // How to test: Delete action, verify coordinator method called (mock?)
    // Why: Delete might be no-op
    // @Test("Delete: Invokes coordinator.delete()")

    // Q: Does delete() clear errorMessage on success?
    // How to test: Set error, delete successfully, verify errorMessage=nil
    // Why: Old errors might persist
    // @Test("Delete: Clears errorMessage on success")

    // Q: Does delete() set errorMessage if coordinator throws?
    // How to test: Try to delete non-existent action, verify error shown
    // Why: Delete errors might be swallowed
    // @Test("Delete: Sets errorMessage on error")

    // MARK: - Test Questions: Edge Cases

    // Q: Can we save with empty title but measurements present?
    // How to test: Save with title="", measurements=[km:5.0], verify succeeds
    // Why: Empty title might be rejected
    // @Test("Save: Allows empty title if measurements present")

    // Q: Can we save with all optional fields nil?
    // How to test: Save with only required fields, verify optional fields are nil
    // Why: Optional handling might default to empty strings
    // @Test("Save: Handles nil optional fields correctly")

    // Q: What happens if coordinator is nil? (Shouldn't happen, but...)
    // How to test: (Difficult to test without dependency injection)
    // Why: Force unwrap could crash
    // @Test("Save: Handles missing coordinator gracefully")
}
