// ValueTests.swift
// Tests for Values hierarchy (Incentives, Values, LifeAreas, MajorValues, HighestOrderValues)
//
// Created by David Williams on 10/19/25
// Updated by Claude Code on 10/19/25 (comprehensive test coverage)
// Ported from Python implementation (python/tests/test_values.py)

import XCTest
@testable import Models

final class ValueTests: XCTestCase {

    // MARK: - Incentives Tests

    func testMinimalIncentivesCreation() {
        let incentive = Incentives(friendlyName: "Honesty")

        XCTAssertEqual(incentive.friendlyName, "Honesty")
        XCTAssertNotNil(incentive.id) // UUID auto-generated
        XCTAssertNotNil(incentive.logTime) // Defaults to Date()
        XCTAssertEqual(incentive.polymorphicSubtype, "incentive")
        XCTAssertEqual(incentive.priority, 50) // Default priority
        XCTAssertNil(incentive.lifeDomain) // Optional
    }

    func testFullyPopulatedIncentives() {
        let incentive = Incentives(
            friendlyName: "Curiosity",
            detailedDescription: "Desire to learn and explore",
            freeformNotes: "Foundation of growth",
            priority: 30,
            lifeDomain: "Personal Development"
        )

        XCTAssertEqual(incentive.friendlyName, "Curiosity")
        XCTAssertEqual(incentive.detailedDescription, "Desire to learn and explore")
        XCTAssertEqual(incentive.priority, 30)
        XCTAssertEqual(incentive.lifeDomain, "Personal Development")
    }

    // MARK: - Values Tests

    func testValuesCreation() {
        let value = Values(friendlyName: "Integrity")

        XCTAssertEqual(value.friendlyName, "Integrity")
        XCTAssertEqual(value.polymorphicSubtype, "general")
        XCTAssertEqual(value.priority, 40) // Values default to 40
        XCTAssertNotNil(value.id)
    }

    func testValuesWithLifeDomain() {
        let value = Values(
            friendlyName: "Work-life balance",
            detailedDescription: "Maintaining boundaries between work and personal life",
            priority: 25,
            lifeDomain: "Career"
        )

        XCTAssertEqual(value.lifeDomain, "Career")
        XCTAssertEqual(value.priority, 25)
    }

    // MARK: - LifeAreas Tests

    func testLifeAreasCreation() {
        let lifeArea = LifeAreas(friendlyName: "Health & Fitness")

        XCTAssertEqual(lifeArea.friendlyName, "Health & Fitness")
        XCTAssertEqual(lifeArea.polymorphicSubtype, "life_area")
        XCTAssertEqual(lifeArea.priority, 40) // LifeAreas default to 40
        XCTAssertNotNil(lifeArea.id)
    }

    func testLifeAreasCategorization() {
        let lifeArea = LifeAreas(
            friendlyName: "Career Development",
            detailedDescription: "Professional growth and advancement",
            priority: 20,
            lifeDomain: "Career"
        )

        XCTAssertEqual(lifeArea.detailedDescription, "Professional growth and advancement")
        XCTAssertEqual(lifeArea.lifeDomain, "Career")
    }

    // MARK: - MajorValues Tests

    func testMajorValuesCreation() {
        let majorValue = MajorValues(
            friendlyName: "Physical health and vitality"
        )

        XCTAssertEqual(majorValue.friendlyName, "Physical health and vitality")
        XCTAssertEqual(majorValue.polymorphicSubtype, "major")
        XCTAssertEqual(majorValue.priority, 10) // Major values default to 10 (high priority)
        XCTAssertNil(majorValue.alignmentGuidance) // Optional
    }

    func testMajorValuesWithAlignmentGuidance() {
        let majorValue = MajorValues(
            friendlyName: "Physical health and vitality",
            detailedDescription: "Maintaining energy and strength",
            priority: 10,
            lifeDomain: "Health",
            alignmentGuidance: "Should see regular exercise, healthy meals, and adequate sleep in weekly actions"
        )

        XCTAssertEqual(majorValue.alignmentGuidance, "Should see regular exercise, healthy meals, and adequate sleep in weekly actions")
        XCTAssertEqual(majorValue.lifeDomain, "Health")
        XCTAssertEqual(majorValue.priority, 10)
    }

    func testMajorValuesHighPriority() {
        // Major values are actionable, so they should have high priority by default
        let majorValue = MajorValues(friendlyName: "Family connection")

        XCTAssertEqual(majorValue.priority, 10) // High priority
        XCTAssertLessThan(majorValue.priority, 40) // Higher than general values
    }

    // MARK: - HighestOrderValues Tests

    func testHighestOrderValuesCreation() {
        let highestValue = HighestOrderValues(
            friendlyName: "Eudaimonia"
        )

        XCTAssertEqual(highestValue.friendlyName, "Eudaimonia")
        XCTAssertEqual(highestValue.polymorphicSubtype, "highest_order")
        XCTAssertEqual(highestValue.priority, 1) // Ultimate priority
        XCTAssertNotNil(highestValue.id)
    }

    func testHighestOrderValuesPhilosophical() {
        let highestValue = HighestOrderValues(
            friendlyName: "Truth",
            detailedDescription: "Seeking and honoring truth in all forms",
            freeformNotes: "Abstract ideal that guides decision-making",
            priority: 1,
            lifeDomain: "Philosophy"
        )

        XCTAssertEqual(highestValue.detailedDescription, "Seeking and honoring truth in all forms")
        XCTAssertEqual(highestValue.priority, 1) // Ultimate priority
        XCTAssertEqual(highestValue.lifeDomain, "Philosophy")
    }

    func testHighestOrderValuesUltimatePriority() {
        let highestValue = HighestOrderValues(friendlyName: "Beauty")

        XCTAssertEqual(highestValue.priority, 1) // Ultimate priority
        XCTAssertLessThan(highestValue.priority, 10) // Higher than major values
        XCTAssertLessThan(highestValue.priority, 40) // Higher than general values
    }

    // MARK: - Polymorphic Type Tests

    func testPolymorphicSubtypes() {
        let incentive = Incentives(friendlyName: "Test")
        let value = Values(friendlyName: "Test")
        let lifeArea = LifeAreas(friendlyName: "Test")
        let majorValue = MajorValues(friendlyName: "Test")
        let highestValue = HighestOrderValues(friendlyName: "Test")

        XCTAssertEqual(incentive.polymorphicSubtype, "incentive")
        XCTAssertEqual(value.polymorphicSubtype, "general")
        XCTAssertEqual(lifeArea.polymorphicSubtype, "life_area")
        XCTAssertEqual(majorValue.polymorphicSubtype, "major")
        XCTAssertEqual(highestValue.polymorphicSubtype, "highest_order")
    }

    // MARK: - Priority Hierarchy Tests

    func testPriorityDefaults() {
        let incentive = Incentives(friendlyName: "Test")
        let value = Values(friendlyName: "Test")
        let lifeArea = LifeAreas(friendlyName: "Test")
        let majorValue = MajorValues(friendlyName: "Test")
        let highestValue = HighestOrderValues(friendlyName: "Test")

        // Verify hierarchy: Highest (1) > Major (10) > Value/LifeArea (40) > Incentive (50)
        XCTAssertEqual(highestValue.priority, 1)
        XCTAssertEqual(majorValue.priority, 10)
        XCTAssertEqual(value.priority, 40)
        XCTAssertEqual(lifeArea.priority, 40)
        XCTAssertEqual(incentive.priority, 50)

        // Verify ordering
        XCTAssertLessThan(highestValue.priority, majorValue.priority)
        XCTAssertLessThan(majorValue.priority, value.priority)
        XCTAssertLessThan(value.priority, incentive.priority)
    }
}
