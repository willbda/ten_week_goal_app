// ExpectationTests.swift
// Comprehensive tests for Expectation enum with associated values
//
// Written by Claude Code on 2025-10-22
//
// Tests cover:
// - Enum construction and type safety
// - Codable encoding/decoding (JSON)
// - GRDB database persistence
// - Factory method validation
// - Polymorphic array operations
// - Query helpers

import Testing
import Foundation
@testable import Models
@testable import Database
import GRDB

// Disambiguate Models.Expectation from Testing.Expectation
typealias GoalExpectation = Models.Expectation

@Suite("Expectation Enum Tests")
struct ExpectationTests {

    // MARK: - Construction & Type Safety Tests

    @Test("Goal requires all SMART fields")
    func goalRequiresSmartFields() throws {
        let now = Date()
        let future = now.addingTimeInterval(60 * 60 * 24 * 70) // 10 weeks

        // Valid goal should succeed
        let validGoal = try GoalExpectation.goal(
            title: "Run 120km in 10 weeks",
            measurementUnit: "km",
            measurementTarget: 120,
            startDate: now,
            targetDate: future,
            howRelevant: "Improve cardiovascular health",
            howActionable: "Run 3x per week, track progress"
        )

        #expect(validGoal.title == "Run 120km in 10 weeks")

        // Invalid goal (empty title) should throw
        #expect(throws: ValidationError.self) {
            try GoalExpectation.goal(
                title: "",
                measurementUnit: "km",
                measurementTarget: 120,
                startDate: now,
                targetDate: future,
                howRelevant: "Test",
                howActionable: "Test"
            )
        }

        // Invalid goal (negative target) should throw
        #expect(throws: ValidationError.self) {
            try GoalExpectation.goal(
                title: "Invalid",
                measurementUnit: "km",
                measurementTarget: -10,
                startDate: now,
                targetDate: future,
                howRelevant: "Test",
                howActionable: "Test"
            )
        }

        // Invalid goal (dates backwards) should throw
        #expect(throws: ValidationError.self) {
            try GoalExpectation.goal(
                title: "Invalid",
                measurementUnit: "km",
                measurementTarget: 120,
                startDate: future,
                targetDate: now,  // Before start date!
                howRelevant: "Test",
                howActionable: "Test"
            )
        }
    }

    @Test("Milestone requires target date")
    func milestoneRequiresTargetDate() throws {
        let targetDate = Date().addingTimeInterval(60 * 60 * 24 * 35) // 5 weeks

        let milestone = try GoalExpectation.milestone(
            title: "Hit 50km by week 5",
            targetDate: targetDate,
            measurementTarget: 50,
            measurementUnit: "km"
        )

        #expect(milestone.title == "Hit 50km by week 5")

        if case .milestone(let m) = milestone {
            #expect(m.targetDate == targetDate)
            #expect(m.measurementTarget == 50)
            #expect(m.measurementUnit == "km")
        } else {
            Issue.record("Expected milestone case")
        }
    }

    @Test("Obligation requires deadline")
    func obligationRequiresDeadline() throws {
        let deadline = Date().addingTimeInterval(60 * 60 * 24 * 7) // 1 week

        let obligation = try GoalExpectation.obligation(
            title: "Submit quarterly report",
            deadline: deadline,
            requestedBy: "Board of Directors",
            consequence: "Delayed approval"
        )

        #expect(obligation.title == "Submit quarterly report")

        if case .obligation(let o) = obligation {
            #expect(o.deadline == deadline)
            #expect(o.requestedBy == "Board of Directors")
            #expect(o.consequence == "Delayed approval")
            #expect(o.priority == 90) // Default high priority
        } else {
            Issue.record("Expected obligation case")
        }
    }

    @Test("Aspiration has minimal requirements")
    func aspirationMinimalRequirements() {
        let aspiration = GoalExpectation.aspiration(
            title: "Write a book someday",
            lifeDomain: "Career",
            priority: 40
        )

        #expect(aspiration.title == "Write a book someday")

        if case .aspiration(let a) = aspiration {
            #expect(a.lifeDomain == "Career")
            #expect(a.priority == 40)
            #expect(a.targetDate == nil) // Optional
        } else {
            Issue.record("Expected aspiration case")
        }
    }

    // MARK: - Codable Tests

    @Test("Goal encodes and decodes correctly")
    func goalCodableRoundtrip() throws {
        let now = Date()
        let future = now.addingTimeInterval(60 * 60 * 24 * 70)

        let original = try GoalExpectation.goal(
            title: "Run 120km",
            description: "Training plan for fitness",
            measurementUnit: "km",
            measurementTarget: 120,
            startDate: now,
            targetDate: future,
            howRelevant: "Health improvement",
            howActionable: "Run 3x weekly",
            expectedTermLength: 10,
            priority: 85,
            lifeDomain: "Health"
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(original)

        // Decode from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(GoalExpectation.self, from: jsonData)

        // Verify type preserved
        guard case .goal(let decodedGoal) = decoded,
              case .goal(let originalGoal) = original else {
            Issue.record("Type not preserved after decode")
            return
        }

        // Verify fields
        #expect(decodedGoal.id == originalGoal.id)
        #expect(decodedGoal.title == originalGoal.title)
        #expect(decodedGoal.measurementUnit == originalGoal.measurementUnit)
        #expect(decodedGoal.measurementTarget == originalGoal.measurementTarget)
        #expect(decodedGoal.priority == originalGoal.priority)
        #expect(decodedGoal.lifeDomain == originalGoal.lifeDomain)
    }

    @Test("JSON contains type discriminator")
    func jsonContainsTypeDiscriminator() throws {
        let milestone = try GoalExpectation.milestone(
            title: "Test milestone",
            targetDate: Date()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(milestone)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Should contain type field
        #expect(jsonString.contains("\"expectation_type\"") || jsonString.contains("\"type\""))
        #expect(jsonString.contains("milestone"))
        #expect(jsonString.contains("data"))
    }

    // MARK: - Polymorphic Array Tests

    @Test("Mixed types in single array")
    func polymorphicArrayOperations() throws {
        let now = Date()
        let future = now.addingTimeInterval(60 * 60 * 24 * 70)

        let expectations: [GoalExpectation] = [
            try GoalExpectation.goal(
                title: "Goal 1",
                measurementUnit: "km",
                measurementTarget: 100,
                startDate: now,
                targetDate: future,
                howRelevant: "Test",
                howActionable: "Test"
            ),
            try GoalExpectation.milestone(
                title: "Milestone 1",
                targetDate: future
            ),
            try GoalExpectation.obligation(
                title: "Obligation 1",
                deadline: future
            ),
            GoalExpectation.aspiration(
                title: "Aspiration 1"
            )
        ]

        // All types in one array
        #expect(expectations.count == 4)

        // Can filter by type
        let goals = expectations.compactMap { exp -> GoalExpectation.Goal? in
            if case .goal(let g) = exp { return g }
            return nil
        }
        #expect(goals.count == 1)

        // Can access shared interface
        let titles = expectations.map { $0.title }
        #expect(titles.count == 4)
        #expect(titles.contains("Goal 1"))
        #expect(titles.contains("Milestone 1"))
    }

    @Test("Pattern matching is exhaustive")
    func patternMatchingExhaustive() throws {
        let expectations: [GoalExpectation] = [
            try GoalExpectation.goal(
                title: "Test",
                measurementUnit: "units",
                measurementTarget: 10,
                startDate: Date(),
                targetDate: Date().addingTimeInterval(1000),
                howRelevant: "Test",
                howActionable: "Test"
            ),
            try GoalExpectation.milestone(title: "Test", targetDate: Date()),
            try GoalExpectation.obligation(title: "Test", deadline: Date()),
            GoalExpectation.aspiration(title: "Test")
        ]

        var typeNames: [String] = []

        // Exhaustive switch (compiler enforces all cases)
        for exp in expectations {
            switch exp {
            case .goal: typeNames.append("goal")
            case .milestone: typeNames.append("milestone")
            case .obligation: typeNames.append("obligation")
            case .aspiration: typeNames.append("aspiration")
            }
        }

        #expect(typeNames.count == 4)
        #expect(typeNames.contains("goal"))
        #expect(typeNames.contains("milestone"))
        #expect(typeNames.contains("obligation"))
        #expect(typeNames.contains("aspiration"))
    }

    // MARK: - Computed Properties Tests

    @Test("Computed properties delegate correctly")
    func computedPropertiesDelegation() throws {
        let goal = try GoalExpectation.goal(
            title: "Goal Title",
            description: "Goal Description",
            measurementUnit: "km",
            measurementTarget: 100,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(1000),
            howRelevant: "Test",
            howActionable: "Test",
            priority: 75,
            lifeDomain: "Health"
        )

        #expect(goal.title == "Goal Title")
        #expect(goal.description == "Goal Description")
        #expect(goal.priority == 75)
        #expect(goal.lifeDomain == "Health")
        #expect(goal.hasDeadline == true)
        #expect(goal.typeName == "Goal")

        let aspiration = GoalExpectation.aspiration(title: "Aspiration")
        #expect(aspiration.hasDeadline == false)
        #expect(aspiration.typeName == "Aspiration")
    }

    @Test("Deadline property extracts correct date")
    func deadlinePropertyExtraction() throws {
        let goalDate = Date().addingTimeInterval(1000)
        let goal = try GoalExpectation.goal(
            title: "Test",
            measurementUnit: "units",
            measurementTarget: 10,
            startDate: Date(),
            targetDate: goalDate,
            howRelevant: "Test",
            howActionable: "Test"
        )

        #expect(goal.deadline == goalDate)

        let milestoneDate = Date().addingTimeInterval(2000)
        let milestone = try GoalExpectation.milestone(
            title: "Test",
            targetDate: milestoneDate
        )

        #expect(milestone.deadline == milestoneDate)

        let obligationDate = Date().addingTimeInterval(3000)
        let obligation = try GoalExpectation.obligation(
            title: "Test",
            deadline: obligationDate
        )

        #expect(obligation.deadline == obligationDate)
    }
}

// MARK: - GRDB Integration Tests

@Suite("Expectation GRDB Tests")
@MainActor
struct ExpectationGRDBTests {

    @Test("Goal saves and fetches from database")
    func goalDatabaseRoundtrip() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Create and save goal
        let goal = try GoalExpectation.goal(
            title: "Run 120km",
            measurementUnit: "km",
            measurementTarget: 120,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(60 * 60 * 24 * 70),
            howRelevant: "Health",
            howActionable: "Run weekly"
        )

        try await db.insert(goal)

        // Fetch back
        let fetched: [GoalExpectation] = try await db.fetchAll()

        #expect(fetched.count == 1)

        guard case .goal(let fetchedGoal) = fetched[0],
              case .goal(let originalGoal) = goal else {
            Issue.record("Type not preserved")
            return
        }

        #expect(fetchedGoal.id == originalGoal.id)
        #expect(fetchedGoal.title == originalGoal.title)
        #expect(fetchedGoal.measurementTarget == originalGoal.measurementTarget)
    }

    @Test("Mixed types save and fetch correctly")
    func mixedTypesDatabaseRoundtrip() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        let now = Date()
        let future = now.addingTimeInterval(60 * 60 * 24 * 70)

        // Save multiple types
        let goal = try GoalExpectation.goal(
            title: "Goal",
            measurementUnit: "km",
            measurementTarget: 100,
            startDate: now,
            targetDate: future,
            howRelevant: "Test",
            howActionable: "Test"
        )
        let milestone = try GoalExpectation.milestone(
            title: "Milestone",
            targetDate: future
        )
        let obligation = try GoalExpectation.obligation(
            title: "Obligation",
            deadline: future
        )

        try await db.insert(goal)
        try await db.insert(milestone)
        try await db.insert(obligation)

        // Fetch all
        let all: [GoalExpectation] = try await db.fetchAll()

        #expect(all.count == 3)

        // Verify types preserved
        let types = all.map { $0.typeName }
        #expect(types.contains("Goal"))
        #expect(types.contains("Milestone"))
        #expect(types.contains("Obligation"))
    }

    @Test("Can filter by type using expectation_type column")
    func filterByTypeColumn() async throws {
        let db = try await DatabaseManager(configuration: .temporary)

        // Save mixed types
        let future = Date().addingTimeInterval(1000)
        let goal = try GoalExpectation.goal(
            title: "Goal",
            measurementUnit: "units",
            measurementTarget: 10,
            startDate: Date(),
            targetDate: future,
            howRelevant: "Test",
            howActionable: "Test"
        )
        let milestone = try GoalExpectation.milestone(title: "Milestone", targetDate: future)

        try await db.insert(goal)
        try await db.insert(milestone)

        // Fetch only goals
        let goals = try await db.read { db in
            try GoalExpectation.fetchByType(db, type: "goal")
        }

        #expect(goals.count == 1)
        #expect(goals[0].typeName == "Goal")

        // Fetch only milestones
        let milestones = try await db.read { db in
            try GoalExpectation.fetchByType(db, type: "milestone")
        }

        #expect(milestones.count == 1)
        #expect(milestones[0].typeName == "Milestone")
    }
}
