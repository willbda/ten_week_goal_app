// ValueTests.swift
// Tests for Values hierarchy (Incentives, Values, LifeAreas, MajorValues, HighestOrderValues)
//
// Created by David Williams on 10/19/25
// Updated by Claude Code on 10/19/25 (comprehensive test coverage)
// Updated 2025-10-21: Converted to modern Swift Testing framework
// Ported from Python implementation (python/tests/test_values.py)

import Foundation
import Testing
@testable import Models

/// Test suite for Values hierarchy
///
/// Verifies creation and polymorphic subtypes for Incentives, Values, LifeAreas, MajorValues, and HighestOrderValues.
@Suite("Value Tests")
struct ValueTests {

    // MARK: - Incentives Tests

    @Test("Creates minimal incentive with defaults") func testMinimalIncentivesCreation() {
        let incentive = Incentives(title: "Honesty")

        #expect(incentive.title == "Honesty")
        #expect(incentive.id != nil) // UUID auto-generated
        #expect(incentive.logTime != nil) // Defaults to Date()
        #expect(incentive.polymorphicSubtype == "incentive")
        #expect(incentive.priority == 50) // Default priority
        #expect(incentive.lifeDomain == nil) // Optional
    }

    @Test("Creates fully populated incentive") func testFullyPopulatedIncentives() {
        let incentive = Incentives(
            title: "Curiosity",
            detailedDescription: "Desire to learn and explore",
            freeformNotes: "Foundation of growth",
            priority: 30,
            lifeDomain: "Personal Development"
        )

        #expect(incentive.title == "Curiosity")
        #expect(incentive.detailedDescription == "Desire to learn and explore")
        #expect(incentive.priority == 30)
        #expect(incentive.lifeDomain == "Personal Development")
    }

    // MARK: - Values Tests

    @Test("Creates general value") func testValuesCreation() {
        let value = Values(title: "Integrity")

        #expect(value.title == "Integrity")
        #expect(value.polymorphicSubtype == "general")
        #expect(value.priority == 40) // Values default to 40
        #expect(value.id != nil)
    }

    @Test("Creates value with life domain") func testValuesWithLifeDomain() {
        let value = Values(
            title: "Work-life balance",
            detailedDescription: "Maintaining boundaries between work and personal life",
            priority: 25,
            lifeDomain: "Career"
        )

        #expect(value.lifeDomain == "Career")
        #expect(value.priority == 25)
    }

    // MARK: - LifeAreas Tests

    @Test("Creates life area") func testLifeAreasCreation() {
        let lifeArea = LifeAreas(title: "Health & Fitness")

        #expect(lifeArea.title == "Health & Fitness")
        #expect(lifeArea.polymorphicSubtype == "life_area")
        #expect(lifeArea.priority == 40) // LifeAreas default to 40
        #expect(lifeArea.id != nil)
    }

    @Test("Categorizes life area") func testLifeAreasCategorization() {
        let lifeArea = LifeAreas(
            title: "Career Development",
            detailedDescription: "Professional growth and advancement",
            priority: 20,
            lifeDomain: "Career"
        )

        #expect(lifeArea.detailedDescription == "Professional growth and advancement")
        #expect(lifeArea.lifeDomain == "Career")
    }

    // MARK: - MajorValues Tests

    @Test("Creates major value") func testMajorValuesCreation() {
        let majorValue = MajorValues(
            title: "Physical health and vitality"
        )

        #expect(majorValue.title == "Physical health and vitality")
        #expect(majorValue.polymorphicSubtype == "major")
        #expect(majorValue.priority == 10) // Major values default to 10 (high priority)
        #expect(majorValue.alignmentGuidance == nil) // Optional
    }

    @Test("Creates major value with alignment guidance") func testMajorValuesWithAlignmentGuidance() {
        let majorValue = MajorValues(
            title: "Physical health and vitality",
            detailedDescription: "Maintaining energy and strength",
            priority: 10,
            lifeDomain: "Health",
            alignmentGuidance: "Should see regular exercise, healthy meals, and adequate sleep in weekly actions"
        )

        #expect(majorValue.alignmentGuidance == "Should see regular exercise, healthy meals, and adequate sleep in weekly actions")
        #expect(majorValue.lifeDomain == "Health")
        #expect(majorValue.priority == 10)
    }

    @Test("Major values have high priority by default") func testMajorValuesHighPriority() {
        // Major values are actionable, so they should have high priority by default
        let majorValue = MajorValues(title: "Family connection")

        #expect(majorValue.priority == 10) // High priority
        #expect(majorValue.priority < 40) // Higher than general values
    }

    // MARK: - HighestOrderValues Tests

    @Test("Creates highest order value") func testHighestOrderValuesCreation() {
        let highestValue = HighestOrderValues(
            title: "Eudaimonia"
        )

        #expect(highestValue.title == "Eudaimonia")
        #expect(highestValue.polymorphicSubtype == "highest_order")
        #expect(highestValue.priority == 1) // Ultimate priority
        #expect(highestValue.id != nil)
    }

    @Test("Creates philosophical highest order value") func testHighestOrderValuesPhilosophical() {
        let highestValue = HighestOrderValues(
            title: "Truth",
            detailedDescription: "Seeking and honoring truth in all forms",
            freeformNotes: "Abstract ideal that guides decision-making",
            priority: 1,
            lifeDomain: "Philosophy"
        )

        #expect(highestValue.detailedDescription == "Seeking and honoring truth in all forms")
        #expect(highestValue.priority == 1) // Ultimate priority
        #expect(highestValue.lifeDomain == "Philosophy")
    }

    @Test("Highest order values have ultimate priority") func testHighestOrderValuesUltimatePriority() {
        let highestValue = HighestOrderValues(title: "Beauty")

        #expect(highestValue.priority == 1) // Ultimate priority
        #expect(highestValue.priority < 10) // Higher than major values
        #expect(highestValue.priority < 40) // Higher than general values
    }

    // MARK: - Polymorphic Type Tests

    @Test("Verifies polymorphic subtypes") func testPolymorphicSubtypes() {
        let incentive = Incentives(title: "Test")
        let value = Values(title: "Test")
        let lifeArea = LifeAreas(title: "Test")
        let majorValue = MajorValues(title: "Test")
        let highestValue = HighestOrderValues(title: "Test")

        #expect(incentive.polymorphicSubtype == "incentive")
        #expect(value.polymorphicSubtype == "general")
        #expect(lifeArea.polymorphicSubtype == "life_area")
        #expect(majorValue.polymorphicSubtype == "major")
        #expect(highestValue.polymorphicSubtype == "highest_order")
    }

    // MARK: - Priority Hierarchy Tests

    @Test("Verifies priority defaults form hierarchy") func testPriorityDefaults() {
        let incentive = Incentives(title: "Test")
        let value = Values(title: "Test")
        let lifeArea = LifeAreas(title: "Test")
        let majorValue = MajorValues(title: "Test")
        let highestValue = HighestOrderValues(title: "Test")

        // Verify hierarchy: Highest (1) > Major (10) > Value/LifeArea (40) > Incentive (50)
        #expect(highestValue.priority == 1)
        #expect(majorValue.priority == 10)
        #expect(value.priority == 40)
        #expect(lifeArea.priority == 40)
        #expect(incentive.priority == 50)

        // Verify ordering
        #expect(highestValue.priority < majorValue.priority)
        #expect(majorValue.priority < value.priority)
        #expect(value.priority < incentive.priority)
    }
}
