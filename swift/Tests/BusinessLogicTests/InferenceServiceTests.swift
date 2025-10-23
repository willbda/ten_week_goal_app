// InferenceServiceTests.swift
// Tests for InferenceService coordination logic
//
// Written by Claude Code on 2025-10-22

import Testing
import Foundation
@testable import Models
@testable import BusinessLogic

@Suite("InferenceService Tests")
struct InferenceServiceTests {

    // MARK: - Helper Data

    /// Create test action with measurements
    func makeAction(
        title: String,
        measuresByUnit: [String: Double],
        logTime: Date = Date(timeIntervalSince1970: 1_000_000)
    ) -> Action {
        return Action(
            title: title,
            measuresByUnit: measuresByUnit,
            logTime: logTime
        )
    }

    /// Create test goal with actionability hints
    func makeGoal(
        title: String,
        measurementUnit: String,
        measurementTarget: Double,
        startDate: Date? = Date(timeIntervalSince1970: 500_000),
        targetDate: Date? = Date(timeIntervalSince1970: 1_500_000),
        howGoalIsActionable: String? = nil
    ) -> Goal {
        return Goal(
            title: title,
            measurementUnit: measurementUnit,
            measurementTarget: measurementTarget,
            startDate: startDate,
            targetDate: targetDate,
            howGoalIsActionable: howGoalIsActionable
        )
    }

    // MARK: - Batch Inference Tests

    @Test("Batch inference: finds matching relationships")
    func batchInferenceFindMatches() async {
        let service = InferenceService()

        let actions = [
            makeAction(
                title: "Yoga class",
                measuresByUnit: ["minutes": 30.0]
            ),
            makeAction(
                title: "Running outside",
                measuresByUnit: ["km": 5.0]
            ),
        ]

        let goals = [
            makeGoal(
                title: "Practice yoga",
                measurementUnit: "minutes",
                measurementTarget: 300.0,
                howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga"]}"#
            ),
            makeGoal(
                title: "Run regularly",
                measurementUnit: "km",
                measurementTarget: 100.0,
                howGoalIsActionable: #"{"units": ["km"], "keywords": ["run"]}"#
            ),
        ]

        let relationships = await service.inferMatches(
            actions: actions,
            goals: goals,
            requirePeriodMatch: true
        )

        // Should find 2 matches (yoga→yoga goal, run→run goal)
        #expect(relationships.count == 2)

        // All should be auto-inferred
        #expect(relationships.allSatisfy { $0.matchMethod == .autoInferred })

        // All should have high confidence
        #expect(relationships.allSatisfy { $0.confidence == 0.9 })
    }

    @Test("Batch inference: filters by period when required")
    func batchInferenceFiltersByPeriod() async {
        let service = InferenceService()

        let earlyAction = makeAction(
            title: "Yoga class",
            measuresByUnit: ["minutes": 30.0],
            logTime: Date(timeIntervalSince1970: 100_000) // Before goal starts
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            startDate: Date(timeIntervalSince1970: 1_000_000), // After action
            targetDate: Date(timeIntervalSince1970: 2_000_000),
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga"]}"#
        )

        let relationships = await service.inferMatches(
            actions: [earlyAction],
            goals: [goal],
            requirePeriodMatch: true
        )

        // Should find no matches (action before goal period)
        #expect(relationships.isEmpty)
    }

    @Test("Batch inference: allows period mismatch when not required")
    func batchInferenceAllowsPeriodMismatch() async {
        let service = InferenceService()

        let earlyAction = makeAction(
            title: "Yoga class",
            measuresByUnit: ["minutes": 30.0],
            logTime: Date(timeIntervalSince1970: 100_000) // Before goal starts
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            startDate: Date(timeIntervalSince1970: 1_000_000), // After action
            targetDate: Date(timeIntervalSince1970: 2_000_000),
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga"]}"#
        )

        let relationships = await service.inferMatches(
            actions: [earlyAction],
            goals: [goal],
            requirePeriodMatch: false // Allow period mismatch
        )

        // Should find match (period check disabled)
        #expect(relationships.count == 1)
    }

    @Test("Batch inference: excludes keyword mismatches")
    func batchInferenceExcludesKeywordMismatches() async {
        let service = InferenceService()

        let action = makeAction(
            title: "Writing session",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga"]}"#
        )

        let relationships = await service.inferMatches(
            actions: [action],
            goals: [goal],
            requirePeriodMatch: true
        )

        // Should find no matches (wrong keyword)
        #expect(relationships.isEmpty)
    }

    @Test("Batch inference: includes matched criteria")
    func batchInferenceIncludesMatchedCriteria() async {
        let service = InferenceService()

        let action = makeAction(
            title: "Yoga class",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga"]}"#
        )

        let relationships = await service.inferMatches(
            actions: [action],
            goals: [goal],
            requirePeriodMatch: true
        )

        #expect(relationships.count == 1)

        let relationship = relationships[0]

        // Should have period, unit, and description criteria
        #expect(relationship.matchedOn.contains(.period))
        #expect(relationship.matchedOn.contains(.unit))
        #expect(relationship.matchedOn.contains(.description))
    }

    @Test("Batch inference: handles empty inputs gracefully")
    func batchInferenceEmptyInputs() async {
        let service = InferenceService()

        // Empty actions
        var relationships = await service.inferMatches(
            actions: [],
            goals: [makeGoal(title: "Test", measurementUnit: "km", measurementTarget: 100.0)],
            requirePeriodMatch: true
        )
        #expect(relationships.isEmpty)

        // Empty goals
        relationships = await service.inferMatches(
            actions: [makeAction(title: "Test", measuresByUnit: ["km": 5.0])],
            goals: [],
            requirePeriodMatch: true
        )
        #expect(relationships.isEmpty)

        // Both empty
        relationships = await service.inferMatches(
            actions: [],
            goals: [],
            requirePeriodMatch: true
        )
        #expect(relationships.isEmpty)
    }

    // MARK: - Filtering Tests

    @Test("Filter ambiguous: separates by confidence threshold")
    func filterAmbiguousSeparatesByThreshold() async {
        let service = InferenceService()

        let relationships = [
            ActionGoalRelationship(
                actionId: UUID(),
                goalId: UUID(),
                contribution: 5.0,
                matchMethod: .autoInferred,
                confidence: 0.9
            ),
            ActionGoalRelationship(
                actionId: UUID(),
                goalId: UUID(),
                contribution: 5.0,
                matchMethod: .autoInferred,
                confidence: 0.5
            ),
            ActionGoalRelationship(
                actionId: UUID(),
                goalId: UUID(),
                contribution: 5.0,
                matchMethod: .autoInferred,
                confidence: 0.3
            ),
        ]

        let (confident, ambiguous) = await service.filterAmbiguous(
            relationships,
            confidenceThreshold: 0.7
        )

        #expect(confident.count == 1) // Only 0.9
        #expect(ambiguous.count == 2) // 0.5 and 0.3
    }

    @Test("Filter ambiguous: uses default threshold 0.7")
    func filterAmbiguousDefaultThreshold() async {
        let service = InferenceService()

        let relationships = [
            ActionGoalRelationship(
                actionId: UUID(),
                goalId: UUID(),
                contribution: 5.0,
                matchMethod: .autoInferred,
                confidence: 0.8
            ),
            ActionGoalRelationship(
                actionId: UUID(),
                goalId: UUID(),
                contribution: 5.0,
                matchMethod: .autoInferred,
                confidence: 0.6
            ),
        ]

        let (confident, ambiguous) = await service.filterAmbiguous(relationships)

        #expect(confident.count == 1) // 0.8 >= 0.7
        #expect(ambiguous.count == 1) // 0.6 < 0.7
    }

    @Test("Filter ambiguous: handles empty input")
    func filterAmbiguousEmptyInput() async {
        let service = InferenceService()

        let (confident, ambiguous) = await service.filterAmbiguous([])

        #expect(confident.isEmpty)
        #expect(ambiguous.isEmpty)
    }

    // MARK: - Manual Relationship Tests

    @Test("Manual relationship: creates with provided contribution")
    func manualRelationshipWithProvidedContribution() async {
        let service = InferenceService()

        let action = makeAction(
            title: "Yoga class",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0
        )

        let relationship = await service.createManualRelationship(
            action: action,
            goal: goal,
            contribution: 45.0 // Override
        )

        #expect(relationship.actionId == action.id)
        #expect(relationship.goalId == goal.id)
        #expect(relationship.contribution == 45.0)
        #expect(relationship.matchMethod == .manual)
        #expect(relationship.confidence == 1.0)
        #expect(relationship.matchedOn.isEmpty) // Manual doesn't track criteria
    }

    @Test("Manual relationship: infers contribution when not provided")
    func manualRelationshipInfersContribution() async {
        let service = InferenceService()

        let action = makeAction(
            title: "Yoga class",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0
        )

        let relationship = await service.createManualRelationship(
            action: action,
            goal: goal
            // No contribution provided
        )

        #expect(relationship.contribution == 30.0) // Inferred from measurements
    }

    @Test("Manual relationship: uses zero when no measurements")
    func manualRelationshipNoMeasurements() async {
        let service = InferenceService()

        let action = Action(
            title: "Think about yoga"
            // No measurements
        )

        let goal = makeGoal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0
        )

        let relationship = await service.createManualRelationship(
            action: action,
            goal: goal
        )

        #expect(relationship.contribution == 0.0)
    }

    // MARK: - Confirmation Tests

    @Test("Confirm relationship: upgrades to user-confirmed")
    func confirmRelationshipUpgrades() async {
        let service = InferenceService()

        let original = ActionGoalRelationship(
            actionId: UUID(),
            goalId: UUID(),
            contribution: 5.0,
            matchMethod: .autoInferred,
            confidence: 0.8,
            matchedOn: [.period, .unit]
        )

        let confirmed = await service.confirmRelationship(original)

        #expect(confirmed.id == original.id) // Preserves ID
        #expect(confirmed.actionId == original.actionId)
        #expect(confirmed.goalId == original.goalId)
        #expect(confirmed.contribution == original.contribution)
        #expect(confirmed.matchMethod == .userConfirmed) // Changed
        #expect(confirmed.confidence == 1.0) // Upgraded
        #expect(confirmed.matchedOn == original.matchedOn) // Preserved
    }

    @Test("Confirm relationship: preserves all data")
    func confirmRelationshipPreservesData() async {
        let service = InferenceService()

        let actionId = UUID()
        let goalId = UUID()
        let id = UUID()

        let original = ActionGoalRelationship(
            id: id,
            actionId: actionId,
            goalId: goalId,
            contribution: 12.5,
            matchMethod: .autoInferred,
            confidence: 0.75,
            matchedOn: [.period, .unit, .description]
        )

        let confirmed = await service.confirmRelationship(original)

        // All data should be preserved except matchMethod and confidence
        #expect(confirmed.id == id)
        #expect(confirmed.actionId == actionId)
        #expect(confirmed.goalId == goalId)
        #expect(confirmed.contribution == 12.5)
        #expect(confirmed.matchedOn.count == 3)
    }
}
