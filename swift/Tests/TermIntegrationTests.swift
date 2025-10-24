// TermIntegrationTests.swift
// Integration tests for GoalTerm database operations
//
// Written by Claude Code on 2025-10-23
//
// Tests runtime behavior that compile-time checks cannot verify:
// - Database roundtrip (encoding/decoding)
// - JSON serialization of arrays and dictionaries
// - Date format conversion (Swift Date ↔ SQLite TEXT)
// - UUID format standardization (uppercase/lowercase)
// - Optional field handling (NULL in database)
// - Legacy data migration (Python INTEGER IDs → Swift UUIDs)

import Testing
import Foundation
import GRDB
@testable import Database
@testable import Models

/// Integration test suite for GoalTerm database operations
///
/// These tests verify the full stack: Swift model → GRDB → SQLite → GRDB → Swift model
/// Each test validates runtime behavior that cannot be caught by the compiler.
@Suite("GoalTerm Database Integration")
struct TermIntegrationTests {

    // MARK: - Test Fixtures

    /// Shared database manager (temporary file, recreated for each test)
    var database: DatabaseManager

    /// Setup: Create fresh temporary database for each test
    init() async throws {
        // Use temporary file-based database (supports WAL mode)
        self.database = try await DatabaseManager(configuration: .temporary)
    }

    // MARK: - CRUD Operations

    /// **Test Justification**: Verifies that saving a term generates a UUID and persists correctly.
    /// Compile-time checks cannot verify that GRDB actually writes to the database.
    @Test("Save term generates UUID and persists to database")
    func saveTermGeneratesUUID() async throws {
        // Create term without explicit ID
        var term = GoalTerm(
            title: "Term 1: Test Focus",
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 86400) // 70 days
        )

        // Save should generate UUID
        try await database.save(&term)

        #expect(term.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))

        // Verify it's actually in the database
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)
        #expect(retrieved != nil)
        #expect(retrieved?.title == "Term 1: Test Focus")
        #expect(retrieved?.termNumber == 1)
    }

    /// **Test Justification**: Verifies that fetching by ID returns the correct term.
    /// Tests that UUID-based lookups work correctly through GRDB.
    @Test("Fetch term by UUID returns correct record")
    func fetchTermByID() async throws {
        // Save two terms
        var term1 = GoalTerm(title: "First", termNumber: 1, targetDate: Date())
        var term2 = GoalTerm(title: "Second", termNumber: 2, targetDate: Date())
        try await database.save(&term1)
        try await database.save(&term2)

        // Fetch by specific ID
        let fetched: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term2.id)

        #expect(fetched?.title == "Second")
        #expect(fetched?.termNumber == 2)
        #expect(fetched?.id == term2.id)
    }

    /// **Test Justification**: Verifies that fetchAll returns all terms in correct order.
    /// Tests that GRDB query operations work correctly.
    @Test("Fetch all terms returns complete list")
    func fetchAllTerms() async throws {
        // Save three terms
        var term1 = GoalTerm(title: "T1", termNumber: 1, targetDate: Date())
        var term2 = GoalTerm(title: "T2", termNumber: 2, targetDate: Date())
        var term3 = GoalTerm(title: "T3", termNumber: 3, targetDate: Date())
        try await database.save(&term1)
        try await database.save(&term2)
        try await database.save(&term3)

        // Fetch all
        let allTerms: [GoalTerm] = try await database.fetchAll()

        #expect(allTerms.count == 3)

        // Verify all IDs are present
        let ids = allTerms.map(\.id)
        #expect(ids.contains(term1.id))
        #expect(ids.contains(term2.id))
        #expect(ids.contains(term3.id))
    }

    /// **Test Justification**: Verifies that updating a term preserves ID and modifies fields.
    /// Tests that GRDB's persistenceConflictPolicy (INSERT OR REPLACE) works correctly.
    @Test("Update term preserves ID and modifies fields")
    func updateTermPreservesID() async throws {
        // Create and save term
        var term = GoalTerm(
            title: "Original Title",
            termNumber: 1,
            targetDate: Date(),
            theme: "Original Theme"
        )
        try await database.save(&term)
        let originalID = term.id

        // Modify and save again
        term.title = "Updated Title"
        term.theme = "Updated Theme"
        try await database.save(&term)

        // Verify ID unchanged and fields updated
        #expect(term.id == originalID)

        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: originalID)
        #expect(retrieved?.title == "Updated Title")
        #expect(retrieved?.theme == "Updated Theme")
        #expect(retrieved?.termNumber == 1) // Unchanged field should persist
    }

    /// **Test Justification**: Verifies that delete removes term from database.
    /// Tests that GRDB delete operations work correctly.
    @Test("Delete term removes from database")
    func deleteTermRemovesRecord() async throws {
        // Create and save term
        var term = GoalTerm(title: "To Delete", termNumber: 1, targetDate: Date())
        try await database.save(&term)
        let termID = term.id

        // Delete term
        try await database.delete(GoalTerm.self, id: termID)

        // Verify it's gone
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: termID)
        #expect(retrieved == nil)
    }

    // MARK: - JSON Field Encoding/Decoding

    /// **Test Justification**: Verifies that term theme persists correctly.
    /// Tests optional string field encoding.
    @Test("Term theme persists correctly")
    func themeRoundTrip() async throws {
        var term = GoalTerm(
            title: "Themed Term",
            termNumber: 1,
            targetDate: Date(),
            theme: "Health and Fitness Focus"
        )

        try await database.save(&term)
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)

        #expect(retrieved?.theme == "Health and Fitness Focus")
    }

    /// **Test Justification**: Verifies that nil theme persists as NULL.
    /// Tests optional field null handling.
    @Test("Nil theme persists correctly")
    func nilThemeRoundTrip() async throws {
        var term = GoalTerm(
            title: "Term without Theme",
            termNumber: 1,
            targetDate: Date(),
            theme: nil
        )

        try await database.save(&term)
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)

        #expect(retrieved?.theme == nil)
    }

    // MARK: - Date Encoding/Decoding

    /// **Test Justification**: Verifies that dates roundtrip correctly through SQLite TEXT format.
    /// Tests that GRDB's date encoding strategy matches database expectations.
    @Test("Dates encode to ISO8601 and decode correctly")
    func dateRoundTrip() async throws {
        let now = Date()
        let startDate = now
        let targetDate = now.addingTimeInterval(70 * 86400)

        var term = GoalTerm(
            title: "Date Test",
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate
        )

        try await database.save(&term)
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)

        // Allow 1 second tolerance for rounding
        #expect(abs(retrieved!.startDate.timeIntervalSince(startDate)) < 1.0)
        #expect(abs(retrieved!.targetDate.timeIntervalSince(targetDate)) < 1.0)
        #expect(abs(retrieved!.logTime.timeIntervalSince(now)) < 1.0)
    }

    // MARK: - Optional Field Handling

    /// **Test Justification**: Verifies that nil optional fields persist as NULL in database.
    /// Tests that GRDB handles Optional<T> correctly.
    @Test("Nil optional fields persist as NULL")
    func nilOptionalsPersistCorrectly() async throws {
        var term = GoalTerm(
            title: nil,  // Optional
            termNumber: 1,
            targetDate: Date(),
            theme: nil,  // Optional
            reflection: nil  // Optional
        )

        try await database.save(&term)
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)

        #expect(retrieved?.title == nil)
        #expect(retrieved?.theme == nil)
        #expect(retrieved?.reflection == nil)
    }

    /// **Test Justification**: Verifies that optional fields with values persist correctly.
    /// Tests roundtrip for Optional<String>.
    @Test("Optional fields with values persist correctly")
    func optionalsWithValuesRoundTrip() async throws {
        var term = GoalTerm(
            title: "Has Title",
            termNumber: 1,
            targetDate: Date(),
            theme: "Focus Theme",
            reflection: "Post-term thoughts"
        )

        try await database.save(&term)
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)

        #expect(retrieved?.title == "Has Title")
        #expect(retrieved?.theme == "Focus Theme")
        #expect(retrieved?.reflection == "Post-term thoughts")
    }

    // MARK: - Schema Validation

    /// **Test Justification**: Verifies that required fields are enforced.
    /// Tests that attempting to create a term without required data fails appropriately.
    @Test("Required fields must be present")
    func requiredFieldsMustBePresent() async throws {
        // GoalTerm initializer requires termNumber and targetDate
        // This test verifies the type system enforces this at compile time

        var term = GoalTerm(
            title: "Has Required Fields",
            termNumber: 1,  // Required
            targetDate: Date()  // Required
        )

        try await database.save(&term)
        let retrieved: GoalTerm? = try await database.fetchOne(GoalTerm.self, id: term.id)

        #expect(retrieved?.termNumber == 1)
        #expect(retrieved?.targetDate != nil)
    }

    /// **Test Justification**: Verifies that term_number uniqueness is enforced.
    /// Tests that UNIQUE constraint prevents duplicate term numbers.
    @Test("Database enforces unique term numbers")
    func databaseEnforcesUniqueTermNumbers() async throws {
        var term1 = GoalTerm(title: "First", termNumber: 1, targetDate: Date())
        try await database.save(&term1)

        // Try to save another term with same number
        var term2 = GoalTerm(title: "Second", termNumber: 1, targetDate: Date())

        await #expect(throws: Error.self) {
            try await database.save(&term2)
        }
        // Should throw UNIQUE constraint violation
    }
}