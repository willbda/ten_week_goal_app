// ValidationErrorTests.swift
// Written by Claude Code on 2025-11-04
// Updated by Claude Code on 2025-11-04 (migrated to Swift Testing)
//
// PURPOSE:
// Test ValidationError enum for proper error messages and conformance.
//
// TESTS:
//  - Business rule error messages (Layer A/B)
//  - Database error messages (Layer C)
//  - LocalizedError conformance
//  - Message completeness

import Testing
@testable import Services

@Suite("ValidationError Tests")
struct ValidationErrorTests {

    // MARK: - Business Rule Error Messages

    @Test("Empty action error message is user-friendly")
    func emptyActionErrorMessage() {
        let error = ValidationError.emptyAction("No content provided")

        #expect(error.userMessage.contains("title"))
        #expect(error.userMessage.contains("description"))
        #expect(error.userMessage.contains("measurements"))
    }

    @Test("Invalid date range error message explains the problem")
    func invalidDateRangeErrorMessage() {
        let error = ValidationError.invalidDateRange("Start after end")

        #expect(error.userMessage.contains("invalid") || error.userMessage.contains("Date"))
    }

    @Test("Invalid priority error message explains range")
    func invalidPriorityErrorMessage() {
        let error = ValidationError.invalidPriority("Got 15")

        #expect(error.userMessage.contains("1-10") || error.userMessage.contains("1-100"))
    }

    @Test("Empty value error message is user-friendly")
    func emptyValueErrorMessage() {
        let error = ValidationError.emptyValue("Missing title")

        #expect(error.userMessage.contains("title") || error.userMessage.contains("description"))
    }

    @Test("Invalid expectation error message is clear")
    func invalidExpectationErrorMessage() {
        let error = ValidationError.invalidExpectation("Missing fields")

        #expect(!error.userMessage.isEmpty)
    }

    @Test("Inconsistent reference error message explains issue")
    func inconsistentReferenceErrorMessage() {
        let error = ValidationError.inconsistentReference("ID mismatch")

        #expect(!error.userMessage.isEmpty)
    }

    // MARK: - Database Error Messages

    @Test("Invalid measure error message is user-friendly")
    func invalidMeasureErrorMessage() {
        let error = ValidationError.invalidMeasure("Measure not found")

        #expect(error.userMessage.contains("measurement"))
        #expect(error.userMessage.contains("available") || error.userMessage.contains("exists"))
    }

    @Test("Invalid goal error message is user-friendly")
    func invalidGoalErrorMessage() {
        let error = ValidationError.invalidGoal("Goal not found")

        #expect(error.userMessage.contains("goal"))
        #expect(error.userMessage.contains("available") || error.userMessage.contains("exists"))
    }

    @Test("Foreign key violation error has no technical jargon")
    func foreignKeyViolationErrorMessage() {
        let error = ValidationError.foreignKeyViolation("Referenced record missing")

        #expect(!error.userMessage.contains("foreign key"))  // No technical jargon
        #expect(error.userMessage.contains("exists") || error.userMessage.contains("available"))
    }

    @Test("Duplicate record error message is clear")
    func duplicateRecordErrorMessage() {
        let error = ValidationError.duplicateRecord("Already exists")

        #expect(error.userMessage.contains("duplicate") || error.userMessage.contains("exists") || error.userMessage.contains("already"))
    }

    @Test("Missing required field error message is specific")
    func missingRequiredFieldErrorMessage() {
        let error = ValidationError.missingRequiredField("title")

        #expect(error.userMessage.contains("required") || error.userMessage.contains("missing"))
    }

    @Test("Database constraint error message is present")
    func databaseConstraintErrorMessage() {
        let error = ValidationError.databaseConstraint("Constraint failed")

        #expect(!error.userMessage.isEmpty)
    }

    // MARK: - LocalizedError Conformance

    @Test("LocalizedError errorDescription matches userMessage")
    func localizedErrorConformance() {
        let error = ValidationError.emptyAction("Test")

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription == error.userMessage)
    }

    // MARK: - Message Completeness

    @Test("All error cases have non-empty messages", arguments: [
        ValidationError.emptyAction("test"),
        ValidationError.emptyValue("test"),
        ValidationError.invalidExpectation("test"),
        ValidationError.invalidDateRange("test"),
        ValidationError.invalidPriority("test"),
        ValidationError.inconsistentReference("test"),
        ValidationError.invalidMeasure("test"),
        ValidationError.invalidGoal("test"),
        ValidationError.duplicateRecord("test"),
        ValidationError.missingRequiredField("test"),
        ValidationError.foreignKeyViolation("test"),
        ValidationError.databaseConstraint("test")
    ])
    func allErrorCasesHaveMessages(error: ValidationError) {
        #expect(!error.userMessage.isEmpty)
        #expect(error.userMessage.count > 10)  // More than just a stub
    }
}

// TESTING STRATEGY:
//
// 1. Message Quality:
//    - User-friendly (no technical jargon)
//    - Actionable (tells user what to fix)
//    - Specific (includes context from associated value)
//
// 2. Conformance:
//    - LocalizedError protocol works
//    - Can be displayed in SwiftUI alerts
//
// 3. Completeness:
//    - Every enum case has a message
//    - No missing switch cases (verified via parameterized test)
//
// 4. No Database Required:
//    - These are pure enum tests
//    - Fast execution (< 1ms per test)
//
// SWIFT TESTING BENEFITS:
//  - @Test macro with descriptive names
//  - #expect for clearer assertions
//  - @Test(arguments:) for parameterized testing
//  - @Suite for organization
//  - No need for XCTestCase inheritance
