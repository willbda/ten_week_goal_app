// ActionGoalRelationshipTests.swift
// Tests for ActionGoalRelationship model
//
// Written by Claude Code on 2025-10-22

import Testing
import Foundation
@testable import Models

@Suite("ActionGoalRelationship Model Tests")
struct ActionGoalRelationshipTests {

    // MARK: - Initialization Tests

    @Test("Initialize with minimal required fields")
    func initializeMinimal() {
        let actionId = UUID()
        let goalId = UUID()

        let relationship = ActionGoalRelationship(
            actionId: actionId,
            goalId: goalId,
            contribution: 5.0,
            matchMethod: .manual
        )

        #expect(relationship.actionId == actionId)
        #expect(relationship.goalId == goalId)
        #expect(relationship.contribution == 5.0)
        #expect(relationship.matchMethod == .manual)
        #expect(relationship.confidence == 1.0)  // Default
        #expect(relationship.matchedOn.isEmpty)   // Default empty
        #expect(relationship.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }

    @Test("Initialize with all fields")
    func initializeComplete() {
        let id = UUID()
        let actionId = UUID()
        let goalId = UUID()
        let createdAt = Date()

        let relationship = ActionGoalRelationship(
            id: id,
            actionId: actionId,
            goalId: goalId,
            contribution: 10.5,
            matchMethod: .autoInferred,
            confidence: 0.85,
            matchedOn: [.period, .unit, .description],
            createdAt: createdAt
        )

        #expect(relationship.id == id)
        #expect(relationship.actionId == actionId)
        #expect(relationship.goalId == goalId)
        #expect(relationship.contribution == 10.5)
        #expect(relationship.matchMethod == .autoInferred)
        #expect(relationship.confidence == 0.85)
        #expect(relationship.matchedOn.count == 3)
        #expect(relationship.createdAt == createdAt)
    }

    // MARK: - MatchMethod Tests

    @Test("MatchMethod enum values")
    func matchMethodEnumValues() {
        #expect(ActionGoalRelationship.MatchMethod.autoInferred.rawValue == "auto_inferred")
        #expect(ActionGoalRelationship.MatchMethod.userConfirmed.rawValue == "user_confirmed")
        #expect(ActionGoalRelationship.MatchMethod.manual.rawValue == "manual")
    }

    // MARK: - MatchCriteria Tests

    @Test("MatchCriteria enum values")
    func matchCriteriaEnumValues() {
        #expect(ActionGoalRelationship.MatchCriteria.period.rawValue == "period")
        #expect(ActionGoalRelationship.MatchCriteria.unit.rawValue == "unit")
        #expect(ActionGoalRelationship.MatchCriteria.description.rawValue == "description")
    }

    // MARK: - Computed Properties Tests

    @Test("isInferred property")
    func isInferredProperty() {
        let inferred = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred
        )
        #expect(inferred.isInferred == true)

        let confirmed = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .userConfirmed
        )
        #expect(confirmed.isInferred == false)

        let manual = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .manual
        )
        #expect(manual.isInferred == false)
    }

    @Test("isConfirmed property")
    func isConfirmedProperty() {
        let inferred = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred
        )
        #expect(inferred.isConfirmed == false)

        let confirmed = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .userConfirmed
        )
        #expect(confirmed.isConfirmed == true)

        let manual = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .manual
        )
        #expect(manual.isConfirmed == true)
    }

    @Test("isHighConfidence property")
    func isHighConfidenceProperty() {
        let high = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: 0.9
        )
        #expect(high.isHighConfidence == true)

        let medium = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: 0.5
        )
        #expect(medium.isHighConfidence == false)
    }

    @Test("isAmbiguous property")
    func isAmbiguousProperty() {
        let ambiguous = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: 0.3
        )
        #expect(ambiguous.isAmbiguous == true)

        let clear = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: 0.7
        )
        #expect(clear.isAmbiguous == false)

        let manual = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .manual,
            confidence: 0.2  // Low confidence but manual, not ambiguous
        )
        #expect(manual.isAmbiguous == false)
    }

    // MARK: - Validation Tests

    @Test("Valid relationship passes validation")
    func validRelationship() {
        let relationship = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 5.0,
            matchMethod: .autoInferred,
            confidence: 0.8
        )
        #expect(relationship.isValid() == true)
    }

    @Test("Negative contribution fails validation")
    func negativeContribution() {
        let relationship = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: -1.0,
            matchMethod: .manual
        )
        #expect(relationship.isValid() == false)
    }

    @Test("Invalid confidence fails validation")
    func invalidConfidence() {
        let tooHigh = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: 1.5
        )
        #expect(tooHigh.isValid() == false)

        let tooLow = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .autoInferred,
            confidence: -0.1
        )
        #expect(tooLow.isValid() == false)
    }

    @Test("Nil UUIDs fail validation")
    func nilUUIDs() {
        let nilUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        let nilAction = ActionGoalRelationship(
            actionId: nilUUID,
            goalId: UUID(),
            contribution: 1.0,
            matchMethod: .manual
        )
        #expect(nilAction.isValid() == false)

        let nilGoal = ActionGoalRelationship(
            actionId: UUID(),
            goalId: nilUUID,
            contribution: 1.0,
            matchMethod: .manual
        )
        #expect(nilGoal.isValid() == false)
    }

    // MARK: - Codable Tests

    @Test("Encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 7.5,
            matchMethod: .userConfirmed,
            confidence: 0.95,
            matchedOn: [.period, .unit]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ActionGoalRelationship.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.actionId == original.actionId)
        #expect(decoded.goalId == original.goalId)
        #expect(decoded.contribution == original.contribution)
        #expect(decoded.matchMethod == original.matchMethod)
        #expect(decoded.confidence == original.confidence)
        #expect(decoded.matchedOn == original.matchedOn)
    }

    // MARK: - Equatable Tests

    @Test("Equal relationships are equal")
    func equalityTest() {
        let id = UUID()
        let actionId = UUID()
        let goalId = UUID()
        let createdAt = Date()

        let relationship1 = ActionGoalRelationship(
            id: id,
            actionId: actionId,
            goalId: goalId,
            contribution: 5.0,
            matchMethod: .manual,
            confidence: 1.0,
            matchedOn: [],
            createdAt: createdAt
        )

        let relationship2 = ActionGoalRelationship(
            id: id,
            actionId: actionId,
            goalId: goalId,
            contribution: 5.0,
            matchMethod: .manual,
            confidence: 1.0,
            matchedOn: [],
            createdAt: createdAt
        )

        #expect(relationship1 == relationship2)
    }

    @Test("Different relationships are not equal")
    func inequalityTest() {
        let actionId = UUID()
        let goalId = UUID()

        let relationship1 = ActionGoalRelationship(
            actionId: actionId,
            goalId: goalId,
            contribution: 5.0,
            matchMethod: .manual
        )

        let relationship2 = ActionGoalRelationship(
            actionId: actionId,
            goalId: goalId,
            contribution: 10.0,  // Different contribution
            matchMethod: .manual
        )

        #expect(relationship1 != relationship2)
    }
}
