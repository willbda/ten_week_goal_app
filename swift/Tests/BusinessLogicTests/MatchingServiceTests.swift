// MatchingServiceTests.swift
// Tests for MatchingService business logic
//
// Written by Claude Code on 2025-10-22

import Testing
import Foundation
@testable import Models
@testable import BusinessLogic

@Suite("MatchingService Tests")
struct MatchingServiceTests {

    // MARK: - Period Matching Tests

    @Test("Period match: action within goal timeframe")
    func periodMatchWithinTimeframe() {
        let action = Action(
            title: "Run 5km",
            logTime: Date(timeIntervalSince1970: 1_000_000) // Oct 1970
        )

        let goal = Goal(
            title: "Marathon training",
            startDate: Date(timeIntervalSince1970: 500_000),  // Before action
            targetDate: Date(timeIntervalSince1970: 1_500_000) // After action
        )

        let matches = MatchingService.matchesOnPeriod(action: action, goal: goal)
        #expect(matches == true)
    }

    @Test("Period match: action before goal timeframe")
    func periodMatchBeforeTimeframe() {
        let action = Action(
            title: "Run 5km",
            logTime: Date(timeIntervalSince1970: 100_000) // Early
        )

        let goal = Goal(
            title: "Marathon training",
            startDate: Date(timeIntervalSince1970: 1_000_000),  // After action
            targetDate: Date(timeIntervalSince1970: 2_000_000)
        )

        let matches = MatchingService.matchesOnPeriod(action: action, goal: goal)
        #expect(matches == false)
    }

    @Test("Period match: action after goal timeframe")
    func periodMatchAfterTimeframe() {
        let action = Action(
            title: "Run 5km",
            logTime: Date(timeIntervalSince1970: 3_000_000) // Late
        )

        let goal = Goal(
            title: "Marathon training",
            startDate: Date(timeIntervalSince1970: 1_000_000),
            targetDate: Date(timeIntervalSince1970: 2_000_000) // Before action
        )

        let matches = MatchingService.matchesOnPeriod(action: action, goal: goal)
        #expect(matches == false)
    }

    @Test("Period match: goal with no dates accepts all actions")
    func periodMatchNoDates() {
        let action = Action(
            title: "Run 5km",
            logTime: Date()
        )

        let goal = Goal(
            title: "Get healthier"
            // No dates
        )

        let matches = MatchingService.matchesOnPeriod(action: action, goal: goal)
        #expect(matches == true)
    }

    @Test("Period match: action exactly on start date")
    func periodMatchOnStartDate() {
        let date = Date(timeIntervalSince1970: 1_000_000)

        let action = Action(
            title: "Run 5km",
            logTime: date
        )

        let goal = Goal(
            title: "Marathon training",
            startDate: date,
            targetDate: Date(timeIntervalSince1970: 2_000_000)
        )

        let matches = MatchingService.matchesOnPeriod(action: action, goal: goal)
        #expect(matches == true)
    }

    @Test("Period match: action exactly on target date")
    func periodMatchOnTargetDate() {
        let date = Date(timeIntervalSince1970: 2_000_000)

        let action = Action(
            title: "Run 5km",
            logTime: date
        )

        let goal = Goal(
            title: "Marathon training",
            startDate: Date(timeIntervalSince1970: 1_000_000),
            targetDate: date
        )

        let matches = MatchingService.matchesOnPeriod(action: action, goal: goal)
        #expect(matches == true)
    }

    // MARK: - Unit Matching Tests

    @Test("Unit match: exact unit match")
    func unitMatchExact() {
        let action = Action(
            title: "Run 5km",
            measuresByUnit: ["km": 5.0]
        )

        let goal = Goal(
            title: "Run 100km",
            measurementUnit: "km",
            measurementTarget: 100.0
        )

        let (matched, key, value) = MatchingService.matchesOnUnit(action: action, goal: goal)
        #expect(matched == true)
        #expect(key == "km")
        #expect(value == 5.0)
    }

    @Test("Unit match: partial unit match")
    func unitMatchPartial() {
        let action = Action(
            title: "Run 5km",
            measuresByUnit: ["distance_km": 5.0]
        )

        let goal = Goal(
            title: "Run 100km",
            measurementUnit: "km",
            measurementTarget: 100.0
        )

        let (matched, key, value) = MatchingService.matchesOnUnit(action: action, goal: goal)
        #expect(matched == true)
        #expect(key == "distance_km")
        #expect(value == 5.0)
    }

    @Test("Unit match: no match different units")
    func unitMatchNoMatch() {
        let action = Action(
            title: "Bike 20km",
            measuresByUnit: ["km": 20.0]
        )

        let goal = Goal(
            title: "Write 50 pages",
            measurementUnit: "pages",
            measurementTarget: 50.0
        )

        let (matched, key, value) = MatchingService.matchesOnUnit(action: action, goal: goal)
        #expect(matched == false)
        #expect(key == nil)
        #expect(value == nil)
    }

    @Test("Unit match: action has no measurements")
    func unitMatchNoMeasurements() {
        let action = Action(
            title: "Think about running"
            // No measurements
        )

        let goal = Goal(
            title: "Run 100km",
            measurementUnit: "km",
            measurementTarget: 100.0
        )

        let (matched, key, value) = MatchingService.matchesOnUnit(action: action, goal: goal)
        #expect(matched == false)
        #expect(key == nil)
        #expect(value == nil)
    }

    @Test("Unit match: goal has no unit")
    func unitMatchNoGoalUnit() {
        let action = Action(
            title: "Run 5km",
            measuresByUnit: ["km": 5.0]
        )

        let goal = Goal(
            title: "Get healthier"
            // No measurement unit
        )

        let (matched, key, value) = MatchingService.matchesOnUnit(action: action, goal: goal)
        #expect(matched == false)
        #expect(key == nil)
        #expect(value == nil)
    }

    // MARK: - Actionability Matching Tests

    @Test("Actionability match: both unit and keyword match")
    func actionabilityMatchBothMatch() {
        let action = Action(
            title: "Yoga class",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = Goal(
            title: "Practice yoga regularly",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga", "pilates"]}"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == true)
        #expect(contribution == 30.0)
    }

    @Test("Actionability match: unit matches but keyword doesn't")
    func actionabilityMatchUnitOnlyNoKeyword() {
        let action = Action(
            title: "Writing session",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = Goal(
            title: "Practice yoga regularly",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga", "pilates"]}"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == false)
        #expect(contribution == nil)
    }

    @Test("Actionability match: keyword matches but unit doesn't")
    func actionabilityMatchKeywordOnlyNoUnit() {
        let action = Action(
            title: "Yoga reading",
            measuresByUnit: ["pages": 10.0]
        )

        let goal = Goal(
            title: "Practice yoga regularly",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga", "pilates"]}"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == false)
        #expect(contribution == nil)
    }

    @Test("Actionability match: no hints fallback to unit matching")
    func actionabilityMatchNoHints() {
        let action = Action(
            title: "Run 5km",
            measuresByUnit: ["km": 5.0]
        )

        let goal = Goal(
            title: "Run 100km",
            measurementUnit: "km",
            measurementTarget: 100.0
            // No howGoalIsActionable
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == true)
        #expect(contribution == 5.0)
    }

    @Test("Actionability match: empty hints fallback to unit matching")
    func actionabilityMatchEmptyHints() {
        let action = Action(
            title: "Run 5km",
            measuresByUnit: ["km": 5.0]
        )

        let goal = Goal(
            title: "Run 100km",
            measurementUnit: "km",
            measurementTarget: 100.0,
            howGoalIsActionable: #"{"units": [], "keywords": []}"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == true)
        #expect(contribution == 5.0)
    }

    @Test("Actionability match: malformed JSON fallback to unit matching")
    func actionabilityMatchMalformedJSON() {
        let action = Action(
            title: "Run 5km",
            measuresByUnit: ["km": 5.0]
        )

        let goal = Goal(
            title: "Run 100km",
            measurementUnit: "km",
            measurementTarget: 100.0,
            howGoalIsActionable: #"{"units": ["km", broken json"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == true) // Falls back to unit matching
        #expect(contribution == 5.0)
    }

    @Test("Actionability match: wildcard keywords stripped")
    func actionabilityMatchWildcardKeywords() {
        let action = Action(
            title: "Running outside",
            measuresByUnit: ["km": 5.0]
        )

        let goal = Goal(
            title: "Run regularly",
            measurementUnit: "km",
            measurementTarget: 100.0,
            howGoalIsActionable: #"{"units": ["km"], "keywords": ["run*", "jog*"]}"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == true) // "running" contains "run"
        #expect(contribution == 5.0)
    }

    @Test("Actionability match: case insensitive keyword matching")
    func actionabilityMatchCaseInsensitive() {
        let action = Action(
            title: "YOGA CLASS",
            measuresByUnit: ["minutes": 30.0]
        )

        let goal = Goal(
            title: "Practice yoga",
            measurementUnit: "minutes",
            measurementTarget: 300.0,
            howGoalIsActionable: #"{"units": ["minutes"], "keywords": ["yoga"]}"#
        )

        let (matched, contribution) = MatchingService.matchesWithActionability(action: action, goal: goal)
        #expect(matched == true)
        #expect(contribution == 30.0)
    }

    // MARK: - Confidence Calculation Tests

    @Test("Confidence: period + actionability = 0.9")
    func confidenceHighMatch() {
        let confidence = MatchingService.calculateConfidence(
            periodMatch: true,
            actionabilityMatch: true
        )
        #expect(confidence == 0.9)
    }

    @Test("Confidence: no period match = 0.0")
    func confidenceNoPeriod() {
        let confidence = MatchingService.calculateConfidence(
            periodMatch: false,
            actionabilityMatch: true
        )
        #expect(confidence == 0.0)
    }

    @Test("Confidence: no actionability match = 0.0")
    func confidenceNoActionability() {
        let confidence = MatchingService.calculateConfidence(
            periodMatch: true,
            actionabilityMatch: false
        )
        #expect(confidence == 0.0)
    }

    @Test("Confidence: neither match = 0.0")
    func confidenceNoMatch() {
        let confidence = MatchingService.calculateConfidence(
            periodMatch: false,
            actionabilityMatch: false
        )
        #expect(confidence == 0.0)
    }
}
