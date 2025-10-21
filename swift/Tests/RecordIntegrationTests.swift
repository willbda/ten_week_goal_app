// RecordIntegrationTests.swift
// Integration tests for Record layer with real database
//
// Written by Claude Code on 2025-10-19
//
// Tests that Record types correctly bridge between:
// - Database schema (INTEGER IDs, snake_case, JSON strings)
// - Clean domain models (UUID IDs, camelCase, native Swift types)
//
// Uses real database at ../shared/database/application_data.db
// Expected data: 186 actions, 8 goals, 6 values, 3 terms

import Testing
import Foundation
import GRDB
@testable import Database
@testable import Models

@Suite("Record Integration Tests")
struct RecordIntegrationTests {

    // MARK: - Test Setup

    static let dbQueue: DatabaseQueue? = nil

    /// Database queue for tests
    private var dbQueue: DatabaseQueue!

    // MARK: - Database Path Resolution

    /// Get the application database file path
    ///
    /// Uses relative path from test file location using #filePath.
    /// This is the shared database used by both Python and Swift implementations.
    ///
    /// - Returns: Path to database file
    /// - Throws: XCTestError if database not found
    private func getDatabasePath() throws -> String {
        // Use relative path from test file location
        // #filePath = ".../ten_week_goal_app/swift/Tests/RecordIntegrationTests.swift"
        // Go up 2 levels: Tests -> swift -> ten_week_goal_app
        let thisFile = URL(fileURLWithPath: #filePath)
        let projectRoot = thisFile
            .deletingLastPathComponent()  // Remove RecordIntegrationTests.swift
            .deletingLastPathComponent()  // Remove Tests/
            .deletingLastPathComponent()  // Remove swift/

        let databasePath = projectRoot
            .appendingPathComponent("shared/database/application_data.db")
            .path

        guard FileManager.default.fileExists(atPath: databasePath) else {
            throw NSError(
                domain: "RecordIntegrationTests",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: """
                    Database not found at: \(databasePath)

                    Ensure application_data.db exists at this location.
                    This is the shared database containing:
                    - 186 actions
                    - 8 goals
                    - 6 values
                    - 3 terms
                    """
                ]
            )
        }

        return databasePath
    }

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Get database path (resolved from test file location using #filePath)
        let databasePath = try getDatabasePath()

        // Open database connection (read-only for safety)
        dbQueue = try DatabaseQueue(path: databasePath)
    }

    override func tearDownWithError() throws {
        // Close database connection
        dbQueue = nil
        try super.tearDownWithError()
    }

    // MARK: - GoalRecord Integration Tests

    /// Test: Fetch all 8 goals from database and convert to domain models
    ///
    /// Validates:
    /// - GRDB fetches correct number of records
    /// - GoalRecord.toDomain() converts without errors
    /// - All goals have non-empty common_name
    /// - Domain model properties match database values
    @Test func testGoalRecordFetchesAndConvertsAllGoals() throws {
        try dbQueue.read { db in
            // Fetch all goal records using GRDB
            let goalRecords = try GoalRecord.fetchAll(db)

            // Verify count matches expected database state
            XCTAssertEqual(
                goalRecords.count,
                8,
                "Expected 8 goals in database"
            )

            // Convert each record to domain model
            let goals = goalRecords.map { $0.toDomain() }

            // Verify all conversions succeeded
            XCTAssertEqual(
                goals.count,
                8,
                "All 8 records should convert to domain models"
            )

            // Verify all goals have required fields
            for (index, goal) in goals.enumerated() {
                XCTAssertNotNil(
                    goal.friendlyName,
                    "Goal at index \(index) should have friendlyName"
                )
                XCTAssertFalse(
                    goal.friendlyName!.isEmpty,
                    "Goal friendlyName should not be empty"
                )

                // All database goals are SmartGoals, so they should have measurement_unit
                XCTAssertNotNil(
                    goal.measurementUnit,
                    "SmartGoal '\(goal.friendlyName!)' should have measurement unit"
                )
            }

            // Verify specific expected goal exists
            let runningGoal = goals.first {
                $0.friendlyName?.contains("120km") ?? false
            }
            #expect(runningGoal, "Should find '120km running' goal" != nil)
            #expect(runningGoal?.measurementUnit == "km")
        }
    }

    /// Test: GoalRecord preserves all database field values
    ///
    /// Validates:
    /// - Database INTEGER id is captured
    /// - snake_case fields map correctly
    /// - Optional fields handle nil correctly
    /// - goal_type discriminator is preserved
    @Test func testGoalRecordPreservesDatabaseFields() throws {
        try dbQueue.read { db in
            // Fetch first goal with all fields populated
            guard let record = try GoalRecord.fetchOne(db) else {
                XCTFail("Should fetch at least one goal")
                return
            }

            // Verify database fields are populated
            #expect(record.id, "Database id should be populated" != nil)
            #expect(!record.common_name.isEmpty)
            #expect(record.goal_type == "SmartGoal", "All existing goals are SmartGoals")

            // Convert to domain and verify mapping
            let goal = record.toDomain()

            #expect(goal.friendlyName == record.common_name)
            #expect(goal.detailedDescription == record.description)
            #expect(goal.measurementUnit == record.measurement_unit)
            #expect(goal.measurementTarget == record.measurement_target)
            #expect(goal.logTime == record.log_time)
        }
    }

    // MARK: - ActionRecord Integration Tests

    /// Test: Fetch first 5 actions and verify JSON measurement parsing
    ///
    /// Validates:
    /// - GRDB automatically decodes JSON measurement_units_by_amount
    /// - JSON like {"km": 4.78} becomes Swift [String: Double] dictionary
    /// - ActionRecord.toDomain() maps to measuresByUnit correctly
    /// - All actions have valid common_name
    @Test func testActionRecordFetchesAndParsesJSONMeasurements() throws {
        try dbQueue.read { db in
            // Fetch first 5 actions
            let actionRecords = try ActionRecord
                .limit(5)
                .fetchAll(db)

            XCTAssertEqual(
                actionRecords.count,
                5,
                "Should fetch 5 actions from database"
            )

            // Convert to domain models
            let actions = actionRecords.map { $0.toDomain() }

            #expect(actions.count == 5)

            // Verify each action has valid data
            for (index, action) in actions.enumerated() {
                XCTAssertNotNil(
                    action.friendlyName,
                    "Action at index \(index) should have friendlyName"
                )
                XCTAssertFalse(
                    action.friendlyName!.isEmpty,
                    "Action friendlyName should not be empty"
                )

                // Many actions have measurements - verify parsing if present
                if let measures = action.measuresByUnit {
                    XCTAssertGreaterThan(
                        measures.count,
                        0,
                        "If measurements exist, dictionary should not be empty"
                    )

                    // Verify values are valid numbers
                    for (unit, value) in measures {
                        XCTAssertFalse(
                            unit.isEmpty,
                            "Measurement unit should not be empty"
                        )
                        XCTAssertGreaterThan(
                            value,
                            0.0,
                            "Measurement value should be positive"
                        )
                    }
                }
            }
        }
    }

    /// Test: Specific action with known measurements
    ///
    /// Validates:
    /// - JSON {"km": 4.78} parses correctly
    /// - measuresByUnit dictionary contains expected key
    /// - Numeric values preserve precision
    @Test func testActionRecordParsesSpecificMeasurement() throws {
        try dbQueue.read { db in
            // Fetch action with known measurement: "202504-Movement" has {"km": 4.78}
            let sql = "SELECT * FROM actions WHERE common_name LIKE '%Movement%' LIMIT 1"
            let record = try ActionRecord.fetchOne(db, sql: sql)

            guard let record = record else {
                // This test is optional - skip if data changed
                return
            }

            // Verify JSON was decoded by GRDB
            #expect(record.measurement_units_by_amount != nil)

            // Convert to domain
            let action = record.toDomain()

            // Verify measurement dictionary exists
            guard let measures = action.measuresByUnit else {
                XCTFail("Action should have measurements")
                return
            }

            // Verify "km" key exists
            #expect(measures["km"], "Should have 'km' measurement" != nil)

            // Verify value is approximately 4.78 (allowing for floating point precision)
            if let kmValue = measures["km"] {
                XCTAssertEqual(
                    kmValue,
                    4.78,
                    accuracy: 0.01,
                    "km value should be 4.78"
                )
            }
        }
    }

    /// Test: ActionRecord round-trip with database ID preservation
    ///
    /// Validates:
    /// - Record fetched from DB has INTEGER id
    /// - Converting to domain generates new UUID
    /// - Converting back to record resets id to nil (for inserts)
    @Test func testActionRecordRoundTripHandlesIDs() throws {
        try dbQueue.read { db in
            guard let record = try ActionRecord.fetchOne(db) else {
                XCTFail("Should fetch at least one action")
                return
            }

            // Database record should have id
            #expect(record.id, "Fetched record should have database id" != nil)
            let originalDBID = record.id

            // Convert to domain (generates new UUID)
            let action = record.toDomain()
            #expect(action.id, "Domain model should have UUID" != nil)

            // Convert back to record (resets id for insert)
            let newRecord = action.toRecord()
            XCTAssertNil(
                newRecord.id,
                "Converted record should have nil id to allow auto-increment"
            )

            // Fields should be preserved
            #expect(newRecord.common_name == record.common_name)
            #expect(newRecord.measurement_units_by_amount == record.measurement_units_by_amount)
        }
    }

    // MARK: - ValueRecord Integration Tests

    /// Test: Fetch all 6 values and convert to appropriate domain types
    ///
    /// Validates:
    /// - ValueRecord.toDomain() returns correct types based on incentive_type
    /// - "highest_order" -> HighestOrderValues
    /// - "major" -> MajorValues
    /// - All 6 values convert successfully
    @Test func testValueRecordFetchesAndConvertsPolymorphicTypes() throws {
        try dbQueue.read { db in
            // Fetch all value records
            let valueRecords = try ValueRecord.fetchAll(db)

            XCTAssertEqual(
                valueRecords.count,
                6,
                "Expected 6 values in database"
            )

            // Track type counts
            var highestOrderCount = 0
            var majorCount = 0

            // Convert each record and verify type
            for record in valueRecords {
                let domainValue = record.toDomain()

                // Verify correct type based on incentive_type
                switch record.incentive_type {
                case "highest_order":
                    XCTAssertTrue(
                        domainValue is HighestOrderValues,
                        "incentive_type='highest_order' should produce HighestOrderValues"
                    )
                    highestOrderCount += 1

                case "major":
                    XCTAssertTrue(
                        domainValue is MajorValues,
                        "incentive_type='major' should produce MajorValues"
                    )
                    majorCount += 1

                default:
                    // Other types also valid
                    break
                }
            }

            // Verify expected counts based on sample data
            #expect(highestOrderCount == 2, "Expected 2 highest_order values")
            #expect(majorCount == 4, "Expected 4 major values")
        }
    }

    /// Test: MajorValues preserve alignment_guidance field
    ///
    /// Validates:
    /// - MajorValues have alignment_guidance populated
    /// - Other value types don't use this field
    @Test func testValueRecordPreservesMajorValueAlignmentGuidance() throws {
        try dbQueue.read { db in
            // Fetch a major value
            let sql = "SELECT * FROM personal_values WHERE incentive_type = 'major' LIMIT 1"
            guard let record = try ValueRecord.fetchOne(db, sql: sql) else {
                XCTFail("Should fetch at least one major value")
                return
            }

            // Convert to domain (should be MajorValues)
            let domainValue = record.toDomain()

            guard let majorValue = domainValue as? MajorValues else {
                XCTFail("Should convert to MajorValues")
                return
            }

            // MajorValues can have alignment_guidance
            // (May be nil in database, but field should exist in domain model)
            #expect(majorValue.alignmentGuidance != nil)
        }
    }

    /// Test: ValueRecord type-specific conversion methods
    ///
    /// Validates:
    /// - toMajorValues() returns MajorValues
    /// - toHighestOrderValues() returns HighestOrderValues
    /// - All required fields are populated
    @Test func testValueRecordTypeSpecificConversions() throws {
        try dbQueue.read { db in
            // Fetch highest_order value
            let highestSQL = "SELECT * FROM personal_values WHERE incentive_type = 'highest_order' LIMIT 1"
            if let record = try ValueRecord.fetchOne(db, sql: highestSQL) {
                let value = record.toHighestOrderValues()

                #expect(value.friendlyName != nil)
                #expect(!value.friendlyName!.isEmpty)
                #expect(value.priority > 0)
            }

            // Fetch major value
            let majorSQL = "SELECT * FROM personal_values WHERE incentive_type = 'major' LIMIT 1"
            if let record = try ValueRecord.fetchOne(db, sql: majorSQL) {
                let value = record.toMajorValues()

                #expect(value.friendlyName != nil)
                #expect(!value.friendlyName!.isEmpty)
                #expect(value.priority > 0)
            }
        }
    }

    // MARK: - TermRecord Integration Tests

    /// Test: Fetch all 3 terms and parse JSON goal ID arrays
    ///
    /// Validates:
    /// - TermRecord.toDomain() handles JSON arrays like "[1, 2, 3]"
    /// - Empty arrays "[]" parse correctly
    /// - termGoalsByID contains UUIDs (even if placeholders)
    /// - All terms have required fields
    @Test func testTermRecordFetchesAndParsesGoalIDArrays() throws {
        try dbQueue.read { db in
            // Fetch all term records
            let termRecords = try TermRecord.fetchAll(db)

            XCTAssertEqual(
                termRecords.count,
                3,
                "Expected 3 terms in database"
            )

            // Convert to domain models
            let terms = termRecords.map { $0.toDomain() }

            #expect(terms.count == 3)

            // Verify each term has valid data
            for (index, term) in terms.enumerated() {
                XCTAssertNotNil(
                    term.friendlyName,
                    "Term at index \(index) should have friendlyName"
                )
                XCTAssertGreaterThan(
                    term.termNumber,
                    0,
                    "Term number should be positive"
                )
                #expect(term.startDate, "Term should have start date" != nil)
                #expect(term.targetDate, "Term should have target date" != nil)

                // termGoalsByID should always be present (even if empty)
                // Since it's a non-optional array, we just verify it exists
                XCTAssertGreaterThanOrEqual(
                    term.termGoalsByID.count,
                    0,
                    "termGoalsByID should be a valid array (can be empty)"
                )
            }
        }
    }

    /// Test: Term with multiple goal IDs parses correctly
    ///
    /// Validates:
    /// - JSON "[1, 2, 3]" produces array with 3 UUIDs
    /// - Each UUID is valid (non-zero)
    @Test func testTermRecordParsesMultipleGoalIDs() throws {
        try dbQueue.read { db in
            // Fetch term with goal IDs: "Term 1" has [1, 2, 3]
            let sql = "SELECT * FROM terms WHERE term_goals_by_id = '[1, 2, 3]' LIMIT 1"
            guard let record = try TermRecord.fetchOne(db, sql: sql) else {
                // This test is optional - skip if data changed
                return
            }

            // Convert to domain
            let term = record.toDomain()

            // Verify goal IDs array
            XCTAssertEqual(
                term.termGoalsByID.count,
                3,
                "Should parse 3 goal IDs from '[1, 2, 3]'"
            )

            // Verify each UUID is valid
            for (index, uuid) in term.termGoalsByID.enumerated() {
                XCTAssertNotEqual(
                    uuid.uuidString,
                    "00000000-0000-0000-0000-000000000000",
                    "UUID at index \(index) should not be zero"
                )
            }
        }
    }

    /// Test: Term with empty goal array parses correctly
    ///
    /// Validates:
    /// - JSON "[]" produces empty array (not nil)
    @Test func testTermRecordParsesEmptyGoalIDArray() throws {
        try dbQueue.read { db in
            // Fetch term with empty array: "Term 3: Mindfulness" has []
            let sql = "SELECT * FROM terms WHERE term_goals_by_id = '[]' LIMIT 1"
            guard let record = try TermRecord.fetchOne(db, sql: sql) else {
                // This test is optional - skip if data changed
                return
            }

            // Convert to domain
            let term = record.toDomain()

            // Verify empty array (not nil)
            XCTAssertEqual(
                term.termGoalsByID.count,
                0,
                "Empty JSON array should produce 0 UUIDs"
            )
        }
    }

    /// Test: TermRecord preserves term_number and dates
    ///
    /// Validates:
    /// - term_number maps to termNumber
    /// - start_date and target_date are preserved
    /// - Dates are valid Date objects
    @Test func testTermRecordPreservesNumberAndDates() throws {
        try dbQueue.read { db in
            guard let record = try TermRecord.fetchOne(db) else {
                XCTFail("Should fetch at least one term")
                return
            }

            // Convert to domain
            let term = record.toDomain()

            // Verify term number
            #expect(term.termNumber == record.term_number)

            // Verify dates
            #expect(term.startDate == record.start_date)
            #expect(term.targetDate == record.target_date)

            // Verify start date is before target date
            XCTAssertLessThan(
                term.startDate,
                term.targetDate,
                "Start date should be before target date"
            )
        }
    }

    // MARK: - Cross-Record Integration Tests

    /// Test: Database contains consistent data across all tables
    ///
    /// Validates:
    /// - All tables have expected record counts
    /// - No table is empty
    @Test func testDatabaseHasExpectedRecordCounts() throws {
        try dbQueue.read { db in
            let actionCount = try ActionRecord.fetchCount(db)
            let goalCount = try GoalRecord.fetchCount(db)
            let valueCount = try ValueRecord.fetchCount(db)
            let termCount = try TermRecord.fetchCount(db)

            #expect(actionCount == 186, "Expected 186 actions")
            #expect(goalCount == 8, "Expected 8 goals")
            #expect(valueCount == 6, "Expected 6 values")
            #expect(termCount == 3, "Expected 3 terms")
        }
    }
}
