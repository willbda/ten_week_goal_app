// GoalValueAlignmentTests.swift
// Tests for GoalValueAlignment model
//
// Written by Claude Code on 2025-10-22

import Testing
import Foundation
@testable import Models

@Suite("GoalValueAlignment Model Tests")
struct GoalValueAlignmentTests {

    // MARK: - Initialization Tests

    @Test("Initialize with minimal fields")
    func initializeMinimal() {
        let goalId = UUID()
        let valueId = UUID()

        let alignment = GoalValueAlignment(
            goalId: goalId,
            valueId: valueId,
            alignmentStrength: 0.8,
            assignmentMethod: .manual
        )

        #expect(alignment.goalId == goalId)
        #expect(alignment.valueId == valueId)
        #expect(alignment.alignmentStrength == 0.8)
        #expect(alignment.assignmentMethod == .manual)
        #expect(alignment.confidence == 1.0)  // Default
    }

    @Test("Initialize with all fields")
    func initializeComplete() {
        let id = UUID()
        let goalId = UUID()
        let valueId = UUID()
        let createdAt = Date()

        let alignment = GoalValueAlignment(
            id: id,
            goalId: goalId,
            valueId: valueId,
            alignmentStrength: 0.65,
            assignmentMethod: .autoInferred,
            confidence: 0.7,
            createdAt: createdAt
        )

        #expect(alignment.id == id)
        #expect(alignment.goalId == goalId)
        #expect(alignment.valueId == valueId)
        #expect(alignment.alignmentStrength == 0.65)
        #expect(alignment.assignmentMethod == .autoInferred)
        #expect(alignment.confidence == 0.7)
        #expect(alignment.createdAt == createdAt)
    }

    // MARK: - AssignmentMethod Tests

    @Test("AssignmentMethod enum values")
    func assignmentMethodEnumValues() {
        #expect(GoalValueAlignment.AssignmentMethod.autoInferred.rawValue == "auto_inferred")
        #expect(GoalValueAlignment.AssignmentMethod.userConfirmed.rawValue == "user_confirmed")
        #expect(GoalValueAlignment.AssignmentMethod.manual.rawValue == "manual")
    }

    // MARK: - Computed Properties Tests

    @Test("isInferred property")
    func isInferredProperty() {
        let inferred = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .autoInferred
        )
        #expect(inferred.isInferred == true)

        let manual = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .manual
        )
        #expect(manual.isInferred == false)
    }

    @Test("isConfirmed property")
    func isConfirmedProperty() {
        let inferred = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .autoInferred
        )
        #expect(inferred.isConfirmed == false)

        let confirmed = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .userConfirmed
        )
        #expect(confirmed.isConfirmed == true)

        let manual = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .manual
        )
        #expect(manual.isConfirmed == true)
    }

    @Test("isStrongAlignment property")
    func isStrongAlignmentProperty() {
        let strong = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.9,
            assignmentMethod: .manual
        )
        #expect(strong.isStrongAlignment == true)

        let weak = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.5,
            assignmentMethod: .manual
        )
        #expect(weak.isStrongAlignment == false)
    }

    @Test("isSpeculative property")
    func isSpeculativeProperty() {
        let speculative = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.4,
            assignmentMethod: .autoInferred,
            confidence: 0.3
        )
        #expect(speculative.isSpeculative == true)

        let clear = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .autoInferred,
            confidence: 0.9
        )
        #expect(clear.isSpeculative == false)

        let manual = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.3,  // Low alignment but manual
            assignmentMethod: .manual,
            confidence: 0.2
        )
        #expect(manual.isSpeculative == false)
    }

    @Test("qualityScore property")
    func qualityScoreProperty() {
        // High alignment + high confidence = high quality
        let highQuality = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.9,
            assignmentMethod: .manual,
            confidence: 1.0
        )
        let expectedHighScore = sqrt(0.9 * 1.0)
        #expect(abs(highQuality.qualityScore - expectedHighScore) < 0.001)

        // Low alignment + low confidence = low quality
        let lowQuality = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.3,
            assignmentMethod: .autoInferred,
            confidence: 0.4
        )
        let expectedLowScore = sqrt(0.3 * 0.4)
        #expect(abs(lowQuality.qualityScore - expectedLowScore) < 0.001)
    }

    // MARK: - Validation Tests

    @Test("Valid alignment passes validation")
    func validAlignment() {
        let alignment = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.75,
            assignmentMethod: .autoInferred,
            confidence: 0.8
        )
        #expect(alignment.isValid() == true)
    }

    @Test("Invalid alignment strength fails validation")
    func invalidAlignmentStrength() {
        let tooHigh = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 1.5,
            assignmentMethod: .manual
        )
        #expect(tooHigh.isValid() == false)

        let tooLow = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: -0.1,
            assignmentMethod: .manual
        )
        #expect(tooLow.isValid() == false)
    }

    @Test("Invalid confidence fails validation")
    func invalidConfidence() {
        let tooHigh = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.5,
            assignmentMethod: .autoInferred,
            confidence: 1.5
        )
        #expect(tooHigh.isValid() == false)

        let tooLow = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.5,
            assignmentMethod: .autoInferred,
            confidence: -0.1
        )
        #expect(tooLow.isValid() == false)
    }

    @Test("Nil UUIDs fail validation")
    func nilUUIDs() {
        let nilUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        let nilGoal = GoalValueAlignment(
            goalId: nilUUID,
            valueId: UUID(),
            alignmentStrength: 0.8,
            assignmentMethod: .manual
        )
        #expect(nilGoal.isValid() == false)

        let nilValue = GoalValueAlignment(
            goalId: UUID(),
            valueId: nilUUID,
            alignmentStrength: 0.8,
            assignmentMethod: .manual
        )
        #expect(nilValue.isValid() == false)
    }

    // MARK: - Codable Tests

    @Test("Encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = GoalValueAlignment(
            goalId: UUID(),
            valueId: UUID(),
            alignmentStrength: 0.85,
            assignmentMethod: .userConfirmed,
            confidence: 0.9
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GoalValueAlignment.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.goalId == original.goalId)
        #expect(decoded.valueId == original.valueId)
        #expect(decoded.alignmentStrength == original.alignmentStrength)
        #expect(decoded.assignmentMethod == original.assignmentMethod)
        #expect(decoded.confidence == original.confidence)
    }

    // MARK: - Equatable Tests

    @Test("Equal alignments are equal")
    func equalityTest() {
        let id = UUID()
        let goalId = UUID()
        let valueId = UUID()
        let createdAt = Date()

        let alignment1 = GoalValueAlignment(
            id: id,
            goalId: goalId,
            valueId: valueId,
            alignmentStrength: 0.8,
            assignmentMethod: .manual,
            confidence: 1.0,
            createdAt: createdAt
        )

        let alignment2 = GoalValueAlignment(
            id: id,
            goalId: goalId,
            valueId: valueId,
            alignmentStrength: 0.8,
            assignmentMethod: .manual,
            confidence: 1.0,
            createdAt: createdAt
        )

        #expect(alignment1 == alignment2)
    }

    @Test("Different alignments are not equal")
    func inequalityTest() {
        let goalId = UUID()
        let valueId = UUID()

        let alignment1 = GoalValueAlignment(
            goalId: goalId,
            valueId: valueId,
            alignmentStrength: 0.8,
            assignmentMethod: .manual
        )

        let alignment2 = GoalValueAlignment(
            goalId: goalId,
            valueId: valueId,
            alignmentStrength: 0.5,  // Different strength
            assignmentMethod: .manual
        )

        #expect(alignment1 != alignment2)
    }
}
