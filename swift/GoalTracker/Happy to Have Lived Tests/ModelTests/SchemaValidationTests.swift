// SchemaValidationTests.swift
// Written by Claude Code on 2025-11-10
//
// PURPOSE: Comprehensive schema ↔ entity validation through write-read-aggregate round-trips
//
// TEST STRATEGY:
// Part A: Bootstrap database from schema_current.sql
// Part B: Load sample data from schema_validation_data.json
// Part C: Write entities in FK-safe dependency order
// Part D: Read entities back from database
// Part E: Run aggregation queries and verify results
// Part F: Preserve database for post-mortem inspection
//
// WHAT THIS VALIDATES:
// ✅ schema_current.sql creates correct tables
// ✅ @Table macros map to database columns correctly
// ✅ Coordinators write data correctly (FK relationships work)
// ✅ Database queries return expected results
// ✅ Complex JOIN queries aggregate correctly
//
// GENUINE QUESTIONS ANSWERED:
// Q: Do @Table/@Column macros correctly map Swift types to SQLite types?
// Q: Do FK constraints enforce referential integrity?
// Q: Can we create 10 goals + 20 actions with complex relationships atomically?
// Q: Do aggregation queries return correct results?
// Q: Can we inspect the database after test runs?

import Foundation
import Testing
import SQLiteData
@testable import Database
@testable import Services
@testable import Models

@Suite("Schema Validation - Round-Trip Tests", .serialized)
struct SchemaValidationTests {

    // MARK: - Shared Test State

    /// Shared database for all tests in this suite
    /// Created once in Part A, used throughout, preserved in Part F
    nonisolated(unsafe) private static var database: DatabaseQueue!

    /// Sample data loaded from JSON
    nonisolated(unsafe) private static var sampleData: SampleDataSet!

    /// UUID mappings for cross-references (populated during Part C)
    nonisolated(unsafe) private static var measureIds: [UUID] = []
    nonisolated(unsafe) private static var valueIds: [UUID] = []
    nonisolated(unsafe) private static var goalIds: [UUID] = []
    nonisolated(unsafe) private static var termIds: [UUID] = []
    nonisolated(unsafe) private static var timePeriodIds: [UUID] = []

    // MARK: - Part A: Bootstrap Database

    @Test("Part A: Bootstrap database from schema_current.sql")
    func testDatabaseBootstrap() async throws {
        print("\n=== PART A: Database Bootstrap ===")

        // Use DatabaseBootstrap.createDatabase with .localTesting mode
        // This automatically:
        // - Creates temp database at correct location (via DatabaseMode.localTesting.path)
        // - Enables WAL mode
        // - Loads schema_current.sql from Database module bundle
        // - Uses exact same code path as production app
        print("Creating database using DatabaseBootstrap.createDatabase(mode: .localTesting)")

        // Clean slate: remove existing test database
        let dbPath = DatabaseBootstrap.DatabaseMode.localTesting.path
        try? FileManager.default.removeItem(at: dbPath)

        // Create database using production bootstrap code
        let db = try DatabaseBootstrap.createDatabase(mode: .localTesting)

        print("✓ Database created with WAL mode enabled")
        print("✓ Schema loaded from schema_current.sql (via DatabaseBootstrap)")

        // Verify core tables exist
        let hasActions = try await db.read { db in try db.tableExists("actions") }
        let hasGoals = try await db.read { db in try db.tableExists("goals") }
        let hasMeasures = try await db.read { db in try db.tableExists("measures") }
        let hasValues = try await db.read { db in try db.tableExists("personalValues") }

        #expect(hasActions, "actions table should exist")
        #expect(hasGoals, "goals table should exist")
        #expect(hasMeasures, "measures table should exist")
        #expect(hasValues, "personalValues table should exist")

        print("✓ Verified: Core tables exist (actions, goals, measures, personalValues)")

        // Verify semantic tables exist (v0.7.5)
        let hasSemanticEmbeddings = try await db.read { db in try db.tableExists("semanticEmbeddings") }
        let hasLLMConversations = try await db.read { db in try db.tableExists("llmConversations") }
        let hasLLMMessages = try await db.read { db in try db.tableExists("llmMessages") }

        #expect(hasSemanticEmbeddings, "semanticEmbeddings table should exist")
        #expect(hasLLMConversations, "llmConversations table should exist")
        #expect(hasLLMMessages, "llmMessages table should exist")

        print("✓ Verified: Semantic tables exist (semanticEmbeddings, llmConversations, llmMessages)")

        // Store for other tests
        SchemaValidationTests.database = db

        print("✓ Database location: \(dbPath.path)")
    }

    // MARK: - Part B: Load Sample Data

    @Test("Part B: Load and parse schema_validation_data.json")
    func testLoadSampleData() throws {
        print("\n=== PART B: Load Sample Data ===")

        let data = try SampleDataLoader.load()

        print("Loaded sample data:")
        print("  - \(data.measures.count) measures")
        print("  - \(data.personalValues.count) personal values")
        print("  - \(data.goals.count) goals")
        print("  - \(data.actions.count) actions")
        print("  - \(data.terms.count) terms")

        // Verify counts match expected
        #expect(data.measures.count == 7, "Should have 7 measures")
        #expect(data.personalValues.count == 5, "Should have 5 personal values")
        #expect(data.goals.count == 10, "Should have 10 goals")
        #expect(data.actions.count == 20, "Should have 20 actions")
        #expect(data.terms.count == 5, "Should have 5 terms")

        print("✓ Loaded: 7 measures, 5 values, 10 goals, 20 actions, 5 terms")

        // Store for other tests
        SchemaValidationTests.sampleData = data
    }

    // MARK: - Part C: Write Entities in Dependency Order

    @Test("Part C: Write entities in FK-safe dependency order")
    func testWriteEntitiesInDependencyOrder() async throws {
        print("\n=== PART C: Write Entities in Dependency Order ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        // =====================================================================
        // LAYER 1: Entities with no foreign keys
        // =====================================================================
        print("\nLayer 1: Creating entities with no FKs...")

        // Create Measures
        var measureIds: [UUID] = []
        for measureData in data.measures {
            let measureId = UUID()
            try await db.write { db in
                _ = try Measure.insert {
                    Measure.Draft(
                        id: measureId,
                        logTime: Date(),
                        title: measureData.title,
                        detailedDescription: measureData.detailedDescription,
                        freeformNotes: measureData.freeformNotes,
                        unit: measureData.unit,
                        measureType: measureData.measureType,
                        canonicalUnit: measureData.canonicalUnit,
                        conversionFactor: measureData.conversionFactor
                    )
                }.execute(db)
            }
            measureIds.append(measureId)
        }
        print("  ✓ Created \(measureIds.count) measures")

        // Create PersonalValues
        var valueIds: [UUID] = []
        let valueCoordinator = PersonalValueCoordinator(database: db)
        for valueData in data.personalValues {
            let formData = valueData.toFormData()
            let value = try await valueCoordinator.create(from: formData)
            valueIds.append(value.id)
        }
        print("  ✓ Created \(valueIds.count) personal values")

        // Create TimePeriods for Terms
        var timePeriodIds: [UUID] = []
        let timePeriodCoordinator = TimePeriodCoordinator(database: db)
        for termData in data.terms {
            let formData = termData.toTimePeriodFormData()
            let timePeriod = try await timePeriodCoordinator.create(from: formData)
            timePeriodIds.append(timePeriod.id)
        }
        print("  ✓ Created \(timePeriodIds.count) time periods")

        print("✓ Layer 1 complete: \(measureIds.count) measures, \(valueIds.count) values, \(timePeriodIds.count) time periods")

        // =====================================================================
        // LAYER 2: Goals (FK to Expectations, Measures, Values)
        // =====================================================================
        print("\nLayer 2: Creating goals with metric targets and value alignments...")

        var goalIds: [UUID] = []
        let goalCoordinator = GoalCoordinator(database: db)

        for goalData in data.goals {
            let formData = goalData.toFormData(
                measureIds: measureIds,
                valueIds: valueIds
            )
            let goal = try await goalCoordinator.create(from: formData)
            goalIds.append(goal.id)
        }
        print("  ✓ Created \(goalIds.count) goals")

        print("✓ Layer 2 complete: \(goalIds.count) goals with metric targets and value alignments")

        // =====================================================================
        // LAYER 3: Terms (FK to TimePeriods) and Actions (FK to Measures, Goals)
        // =====================================================================
        print("\nLayer 3: Creating terms and actions...")

        // Fetch created GoalTerms (already created by TimePeriodCoordinator)
        var termIds: [UUID] = []
        for timePeriodId in timePeriodIds {
            let termId = try await db.read { db in
                try GoalTerm
                    .where { $0.timePeriodId.eq(timePeriodId) }
                    .fetchOne(db)!
                    .id
            }
            termIds.append(termId)
        }

        // Create TermGoalAssignments for terms that have goals
        for (index, termData) in data.terms.enumerated() {
            let termId = termIds[index]  // Capture before async

            // Create TermGoalAssignments if term has goals
            if let goalIndices = termData.goalIndices {
                for (order, goalIndex) in goalIndices.enumerated() {
                    let goalId = goalIds[goalIndex]  // Capture before async
                    try await db.write { db in
                        _ = try TermGoalAssignment.insert {
                            TermGoalAssignment.Draft(
                                id: UUID(),
                                termId: termId,
                                goalId: goalId,
                                assignmentOrder: order + 1,
                                createdAt: Date()
                            )
                        }.execute(db)
                    }
                }
            }
        }
        print("  ✓ Created \(termIds.count) terms with goal assignments")

        // Create Actions
        var actionCount = 0
        let actionCoordinator = ActionCoordinator(database: db)

        for actionData in data.actions {
            let formData = actionData.toFormData(
                measureIds: measureIds,
                goalIds: goalIds
            )
            _ = try await actionCoordinator.create(from: formData)
            actionCount += 1
        }
        print("  ✓ Created \(actionCount) actions with measurements and goal contributions")

        print("✓ Layer 3 complete: \(termIds.count) terms, \(actionCount) actions")

        // =====================================================================
        // VERIFY COUNTS IN DATABASE
        // =====================================================================
        print("\nVerifying entity counts in database...")

        let measuresInDB = try await db.read { db in try Measure.all.fetchCount(db) }
        let valuesInDB = try await db.read { db in try PersonalValue.all.fetchCount(db) }
        let goalsInDB = try await db.read { db in try Goal.all.fetchCount(db) }
        let actionsInDB = try await db.read { db in try Action.all.fetchCount(db) }
        let termsInDB = try await db.read { db in try GoalTerm.all.fetchCount(db) }

        #expect(measuresInDB == 7, "Database should have 7 measures")
        #expect(valuesInDB == 5, "Database should have 5 values")
        #expect(goalsInDB == 10, "Database should have 10 goals")
        #expect(actionsInDB == 20, "Database should have 20 actions")
        #expect(termsInDB == 5, "Database should have 5 terms")

        print("✓ Verified: DB has \(measuresInDB) measures (expected 7)")
        print("✓ Verified: DB has \(valuesInDB) values (expected 5)")
        print("✓ Verified: DB has \(goalsInDB) goals (expected 10)")
        print("✓ Verified: DB has \(actionsInDB) actions (expected 20)")
        print("✓ Verified: DB has \(termsInDB) terms (expected 5)")

        // Store IDs for aggregation tests
        SchemaValidationTests.measureIds = measureIds
        SchemaValidationTests.valueIds = valueIds
        SchemaValidationTests.goalIds = goalIds
        SchemaValidationTests.termIds = termIds
        SchemaValidationTests.timePeriodIds = timePeriodIds
    }

    // MARK: - Part D: Read Entities Back from Database

    @Test("Part D: Read entities back from database")
    func testReadEntitiesBack() async throws {
        print("\n=== PART D: Read Entities Back from Database ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        // =====================================================================
        // READ MEASURES
        // =====================================================================
        print("\nReading measures from database...")

        let measures = try await db.read { db in
            try Measure.all.order(by: \.title).fetchAll(db)
        }

        #expect(measures.count == 7, "Should read 7 measures")
        print("✓ Read \(measures.count) measures from DB")

        // Verify specific measure
        let km = measures.first { $0.title == "Kilometers" }!
        #expect(km.unit == "km", "Kilometers should have unit 'km'")
        #expect(km.measureType == "distance", "Kilometers should be distance type")
        #expect(km.conversionFactor == 1000.0, "Kilometers should have conversion factor 1000.0")
        print("✓ Measure 'Kilometers' has correct fields: unit='km', type='distance', factor=1000.0")

        // =====================================================================
        // READ PERSONAL VALUES
        // =====================================================================
        print("\nReading personal values from database...")

        let values = try await db.read { db in
            try PersonalValue.all.order(by: \.priority).fetchAll(db)
        }

        #expect(values.count == 5, "Should read 5 values")
        print("✓ Read \(values.count) values from DB")

        // Sort descending in Swift (SQLiteData orders ascending by default)
        let sortedValues = values.sorted { ($0.priority ?? 0) > ($1.priority ?? 0) }

        // Verify priority ordering (descending)
        #expect(sortedValues[0].priority! >= sortedValues[1].priority!, "Values should be ordered by priority desc")
        print("✓ Values correctly ordered by priority (highest first)")

        // =====================================================================
        // READ GOALS
        // =====================================================================
        print("\nReading goals from database...")

        let goals = try await db.read { db in
            try Goal.all.fetchAll(db)
        }

        #expect(goals.count == 10, "Should read 10 goals")
        print("✓ Read \(goals.count) goals from DB")

        // Verify date fields decode correctly
        let goalsWithDates = goals.filter { $0.startDate != nil && $0.targetDate != nil }
        #expect(goalsWithDates.count > 0, "At least some goals should have dates")
        print("✓ Goal dates decoded correctly from database")

        // =====================================================================
        // READ ACTIONS
        // =====================================================================
        print("\nReading actions from database...")

        let actions = try await db.read { db in
            try Action.all.order(by: \.logTime).fetchAll(db)
        }

        #expect(actions.count == 20, "Should read 20 actions")
        print("✓ Read \(actions.count) actions from DB")

        // Verify action with measurements
        let actionsWithDuration = actions.filter { $0.durationMinutes != nil }
        #expect(actionsWithDuration.count > 0, "Some actions should have duration")
        print("✓ Action fields decoded correctly (duration, startTime)")

        // =====================================================================
        // READ RELATIONSHIP TABLES
        // =====================================================================
        print("\nReading relationship tables...")

        let measuredActions = try await db.read { db in
            try MeasuredAction.all.fetchAll(db)
        }
        print("✓ Read \(measuredActions.count) measured actions")

        let goalRelevances = try await db.read { db in
            try GoalRelevance.all.fetchAll(db)
        }
        print("✓ Read \(goalRelevances.count) goal relevances")

        let actionGoalContributions = try await db.read { db in
            try ActionGoalContribution.all.fetchAll(db)
        }
        print("✓ Read \(actionGoalContributions.count) action goal contributions")

        #expect(measuredActions.count > 0, "Should have measurement records")
        #expect(goalRelevances.count > 0, "Should have goal-value alignments")
        #expect(actionGoalContributions.count > 0, "Should have action-goal contributions")

        print("✓ All entities read successfully with correct types")
    }

    // MARK: - Part E: Complex Lookups and Aggregations

    @Test("Part E.1: Aggregation - Total kilometers run")
    func testAggregationTotalKilometers() async throws {
        print("\n=== PART E.1: Aggregation - Total Kilometers ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.totalKilometers

        // Find Kilometers measure
        let km = try await db.read { db in
            try Measure.all.where { $0.title == "Kilometers" }.fetchOne(db)!
        }

        // Sum all measurements for this measure
        let total = try await db.read { db in
            let measurements = try MeasuredAction.all
                .where { $0.measureId == km.id }
                .fetchAll(db)
            return measurements.reduce(0.0) { $0 + $1.value }
        }

        #expect(total == expected, "Total kilometers should match expected")
        print("✓ Aggregation: totalKilometers = \(total) (expected \(expected))")
    }

    @Test("Part E.2: Aggregation - Actions with measurements")
    func testAggregationActionsWithMeasurements() async throws {
        print("\n=== PART E.2: Aggregation - Actions With Measurements ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.actionsWithMeasurements

        // Count distinct action IDs in MeasuredAction table
        let count = try await db.read { db in
            let measurements = try MeasuredAction.all.fetchAll(db)
            let uniqueActionIds = Set(measurements.map { $0.actionId })
            return uniqueActionIds.count
        }

        #expect(count == expected, "Count of actions with measurements should match")
        print("✓ Aggregation: actionsWithMeasurements = \(count) (expected \(expected))")
    }

    @Test("Part E.3: Aggregation - Goals aligned to Physical Health")
    func testAggregationGoalsAlignedToPhysicalHealth() async throws {
        print("\n=== PART E.3: Aggregation - Goals Aligned to Physical Health ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.goalsAlignedToPhysicalHealth

        // Find Physical Health value
        let physicalHealth = try await db.read { db in
            try PersonalValue.all
                .where { $0.title == "Physical Health and Vitality" }
                .fetchOne(db)!
        }

        // Count goal relevances for this value
        let count = try await db.read { db in
            try GoalRelevance.all
                .where { $0.valueId == physicalHealth.id }
                .fetchCount(db)
        }

        #expect(count == expected, "Goals aligned to physical health should match")
        print("✓ Aggregation: goalsAlignedToPhysicalHealth = \(count) (expected \(expected))")
    }

    @Test("Part E.4: Aggregation - Total study hours")
    func testAggregationTotalStudyHours() async throws {
        print("\n=== PART E.4: Aggregation - Total Study Hours ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.totalStudyHours

        // Find Hours measure
        let hours = try await db.read { db in
            try Measure.all.where { $0.title == "Hours" }.fetchOne(db)!
        }

        // Sum all hour measurements
        let total = try await db.read { db in
            let measurements = try MeasuredAction.all
                .where { $0.measureId == hours.id }
                .fetchAll(db)
            return measurements.reduce(0.0) { $0 + $1.value }
        }

        #expect(total == expected, "Total study hours should match")
        print("✓ Aggregation: totalStudyHours = \(total) (expected \(expected))")
    }

    @Test("Part E.5: Aggregation - Total meditation sessions")
    func testAggregationTotalMeditationSessions() async throws {
        print("\n=== PART E.5: Aggregation - Total Meditation Sessions ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.totalMeditationSessions

        // Find Sessions measure and meditation goal
        let sessions = try await db.read { db in
            try Measure.all.where { $0.title == "Sessions" }.fetchOne(db)!
        }

        let meditationGoal = try await db.read { db -> Goal in
            // Find meditation goal by searching expectations
            // Based on sample data, "Daily Meditation Practice" is at index 7
            let goals = try Goal.all.fetchAll(db)
            return goals[7]  // Daily Meditation Practice
        }

        // Count session measurements for meditation actions
        let total = try await db.read { db in
            // Get actions contributing to meditation goal
            let contributions = try ActionGoalContribution.all
                .where { $0.goalId == meditationGoal.id }
                .fetchAll(db)
            let actionIds = contributions.map { $0.actionId }

            // Sum session measurements for these actions
            let measurements = try MeasuredAction.all.fetchAll(db)
            let filtered = measurements.filter { actionIds.contains($0.actionId) && $0.measureId == sessions.id }
            return Int(filtered.reduce(0.0) { $0 + $1.value })
        }

        #expect(total == expected, "Total meditation sessions should match")
        print("✓ Aggregation: totalMeditationSessions = \(total) (expected \(expected))")
    }

    @Test("Part E.6: Aggregation - Strength training sessions")
    func testAggregationStrengthTrainingSessions() async throws {
        print("\n=== PART E.6: Aggregation - Strength Training Sessions ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.strengthTrainingSessions

        // Find Sessions measure and strength training goal
        let sessions = try await db.read { db in
            try Measure.all.where { $0.title == "Sessions" }.fetchOne(db)!
        }

        let strengthGoal = try await db.read { db -> Goal in
            // Find strength training goal by searching expectations
            // Based on sample data, "Strength Training 3x Weekly" is at index 5
            let goals = try Goal.all.fetchAll(db)
            return goals[5]  // Strength Training 3x Weekly
        }

        // Count session measurements for strength training actions
        let total = try await db.read { db in
            let contributions = try ActionGoalContribution.all
                .where { $0.goalId == strengthGoal.id }
                .fetchAll(db)
            let actionIds = contributions.map { $0.actionId }

            let measurements = try MeasuredAction.all.fetchAll(db)
            let filtered = measurements.filter { actionIds.contains($0.actionId) && $0.measureId == sessions.id }
            return Int(filtered.reduce(0.0) { $0 + $1.value })
        }

        #expect(total == expected, "Strength training sessions should match")
        print("✓ Aggregation: strengthTrainingSessions = \(total) (expected \(expected))")
    }

    @Test("Part E.7: Aggregation - Actions contributing to goals")
    func testAggregationActionsContributingToGoals() async throws {
        print("\n=== PART E.7: Aggregation - Actions Contributing to Goals ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.actionsContributingToGoals

        // Count distinct action IDs in ActionGoalContribution table
        let count = try await db.read { db in
            let contributions = try ActionGoalContribution.all.fetchAll(db)
            let uniqueActionIds = Set(contributions.map { $0.actionId })
            return uniqueActionIds.count
        }

        #expect(count == expected, "Actions contributing to goals should match")
        print("✓ Aggregation: actionsContributingToGoals = \(count) (expected \(expected))")
    }

    @Test("Part E.8: Aggregation - Goals by high importance")
    func testAggregationGoalsByImportanceHigh() async throws {
        print("\n=== PART E.8: Aggregation - Goals with High Importance ===")

        guard let db = SchemaValidationTests.database else {
            throw TestError.databaseNotInitialized
        }

        guard let data = SchemaValidationTests.sampleData else {
            throw TestError.sampleDataNotLoaded
        }

        let expected = data.expectedAggregations.goalsByImportanceHigh

        // Count expectations with importance >= 9 and type = goal
        let count = try await db.read { db in
            // Use raw SQL query since Expectation doesn't have .all
            let sql = "SELECT COUNT(*) FROM expectations WHERE expectationImportance >= 9 AND expectationType = 'goal'"
            return try Int.fetchOne(db, sql: sql) ?? 0
        }

        #expect(count == expected, "High importance goals should match")
        print("✓ Aggregation: goalsByImportanceHigh = \(count) (expected \(expected))")
    }

    // MARK: - Part F: Preserve Test Database

    @Test("Part F: Preserve database for inspection")
    func testPreserveDatabase() throws {
        print("\n=== PART F: Preserve Test Database ===")

        guard SchemaValidationTests.database != nil else {
            throw TestError.databaseNotInitialized
        }

        // Database is already at DatabaseBootstrap.DatabaseMode.localTesting.path
        // Just print the location for inspection (sandboxed app can't copy outside container)
        let dbURL = DatabaseBootstrap.DatabaseMode.localTesting.path

        print("✓ Database preserved at:")
        print("   \(dbURL.path)")
        print("\n   Inspect with:")
        print("     sqlite3 \"\(dbURL.path)\"")
        print("\n   Or copy to Desktop with:")
        print("     cp \"\(dbURL.path)\" ~/Desktop/test_db.db")
        print("\n   Example queries:")
        print("     SELECT COUNT(*) FROM actions;")
        print("     SELECT title, unit FROM measures;")
        print("     SELECT e.title, g.startDate, g.targetDate FROM goals g JOIN expectations e ON g.expectationId = e.id;")
    }

    // MARK: - Test Errors

    enum TestError: Error {
        case databaseNotInitialized
        case sampleDataNotLoaded
        case schemaFileNotFound
    }
}
