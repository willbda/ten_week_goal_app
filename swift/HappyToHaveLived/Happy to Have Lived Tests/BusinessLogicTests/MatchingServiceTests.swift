//
// MatchingServiceTests.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Unit tests for MatchingService (3NF schema version)
// PATTERN: Swift Testing (@Test), pure function testing (no database needed)
//

import Foundation
import Testing

@testable import Models
@testable import Services

@Suite("MatchingService Tests")
struct MatchingServiceTests {

    // MARK: - Period Matching Tests

    @Test("Period matching - action within goal timeframe")
    func testPeriodMatchWithinRange() {
        let action = Action(
            title: "Morning run",
            logTime: Date()  // Today
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),  // 7 days ago
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())  // 7 days from now
        )

        let match = MatchingService.matchesOnPeriod(action: action, goal: goal)

        #expect(match == true)
    }

    @Test("Period matching - action outside goal timeframe")
    func testPeriodMatchOutsideRange() {
        let action = Action(
            title: "Old run",
            logTime: Calendar.current.date(byAdding: .day, value: -30, to: Date())!  // 30 days ago
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),  // 7 days ago
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())  // 7 days from now
        )

        let match = MatchingService.matchesOnPeriod(action: action, goal: goal)

        #expect(match == false)
    }

    @Test("Period matching - goal with no dates always matches")
    func testPeriodMatchNoDateConstraints() {
        let action = Action(
            title: "Any action",
            logTime: Date()
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: nil,  // No date constraints
            targetDate: nil
        )

        let match = MatchingService.matchesOnPeriod(action: action, goal: goal)

        #expect(match == true)
    }

    // MARK: - Metric Matching Tests

    @Test("Metric matching - perfect overlap (1 metric)")
    func testMetricMatchPerfectOverlap() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let actionMeasures = [(kmMeasure, 5.0)]
        let goalTargets = [(kmMeasure, 120.0)]

        let result = MatchingService.matchesOnMetrics(
            actionMeasures: actionMeasures,
            goalTargets: goalTargets
        )

        #expect(result.hasOverlap == true)
        #expect(result.contribution == 5.0)
        #expect(result.confidence == 1.0)
        #expect(result.sharedMetrics.count == 1)
        #expect(result.sharedMetrics.first?.id == kmMeasure.id)
    }

    @Test("Metric matching - partial overlap (2 of 2 goal metrics)")
    func testMetricMatchPartialOverlap() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")
        let sessionsMeasure = Measure(unit: "sessions", measureType: "count")
        let minutesMeasure = Measure(unit: "minutes", measureType: "time")

        // Action has km + minutes
        let actionMeasures = [(kmMeasure, 5.0), (minutesMeasure, 30.0)]

        // Goal targets km + sessions (only km overlaps)
        let goalTargets = [(kmMeasure, 120.0), (sessionsMeasure, 20.0)]

        let result = MatchingService.matchesOnMetrics(
            actionMeasures: actionMeasures,
            goalTargets: goalTargets
        )

        #expect(result.hasOverlap == true)
        #expect(result.contribution == 5.0)  // Only km contributes
        #expect(result.sharedMetrics.count == 1)
        #expect(result.confidence == 0.5)  // 1 of 2 goal metrics matched
    }

    @Test("Metric matching - no overlap")
    func testMetricMatchNoOverlap() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")
        let pagesMeasure = Measure(unit: "pages", measureType: "count")

        let actionMeasures = [(pagesMeasure, 25.0)]
        let goalTargets = [(kmMeasure, 120.0)]

        let result = MatchingService.matchesOnMetrics(
            actionMeasures: actionMeasures,
            goalTargets: goalTargets
        )

        #expect(result.hasOverlap == false)
        #expect(result.contribution == nil)
        #expect(result.confidence == 0.0)
        #expect(result.sharedMetrics.isEmpty)
    }

    @Test("Metric matching - empty action measurements")
    func testMetricMatchEmptyActionMeasurements() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let actionMeasures: [(Measure, Double)] = []
        let goalTargets = [(kmMeasure, 120.0)]

        let result = MatchingService.matchesOnMetrics(
            actionMeasures: actionMeasures,
            goalTargets: goalTargets
        )

        #expect(result.hasOverlap == false)
        #expect(result.contribution == nil)
    }

    @Test("Metric matching - multiple shared metrics sum contribution")
    func testMetricMatchMultipleSharedMetrics() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")
        let sessionsMeasure = Measure(unit: "sessions", measureType: "count")

        // Action has both km and sessions
        let actionMeasures = [(kmMeasure, 5.0), (sessionsMeasure, 1.0)]

        // Goal targets both
        let goalTargets = [(kmMeasure, 120.0), (sessionsMeasure, 20.0)]

        let result = MatchingService.matchesOnMetrics(
            actionMeasures: actionMeasures,
            goalTargets: goalTargets
        )

        #expect(result.hasOverlap == true)
        #expect(result.contribution == 6.0)  // 5.0 + 1.0
        #expect(result.sharedMetrics.count == 2)
        #expect(result.confidence == 1.0)  // 2 of 2 matched
    }

    // MARK: - Keyword Matching Tests

    @Test("Keyword matching - title contains keyword")
    func testKeywordMatchContainsInTitle() {
        let action = Action(title: "Morning run in the park")
        let keywords = ["run", "jog", "sprint"]

        let match = MatchingService.matchesOnKeywords(action: action, keywords: keywords)

        #expect(match == true)
    }

    @Test("Keyword matching - description contains keyword")
    func testKeywordMatchContainsInDescription() {
        let action = Action(
            title: "Exercise",
            detailedDescription: "Went for a nice jog around the lake"
        )
        let keywords = ["run", "jog", "sprint"]

        let match = MatchingService.matchesOnKeywords(action: action, keywords: keywords)

        #expect(match == true)
    }

    @Test("Keyword matching - no match")
    func testKeywordMatchNoMatch() {
        let action = Action(title: "Yoga class")
        let keywords = ["run", "jog", "sprint"]

        let match = MatchingService.matchesOnKeywords(action: action, keywords: keywords)

        #expect(match == false)
    }

    @Test("Keyword matching - empty keywords always matches")
    func testKeywordMatchEmptyKeywords() {
        let action = Action(title: "Any action")
        let keywords: [String] = []

        let match = MatchingService.matchesOnKeywords(action: action, keywords: keywords)

        #expect(match == true)  // Empty keywords means no filtering
    }

    @Test("Keyword matching - case insensitive")
    func testKeywordMatchCaseInsensitive() {
        let action = Action(title: "Morning RUN")
        let keywords = ["run"]

        let match = MatchingService.matchesOnKeywords(action: action, keywords: keywords)

        #expect(match == true)
    }

    @Test("Keyword matching - empty action text")
    func testKeywordMatchEmptyActionText() {
        let action = Action(title: nil, detailedDescription: nil)
        let keywords = ["run"]

        let match = MatchingService.matchesOnKeywords(action: action, keywords: keywords)

        #expect(match == false)
    }

    // MARK: - Combined Matching Tests

    @Test("Combined matching - full match (period + metrics + keywords)")
    func testCombinedMatchSuccess() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let action = Action(
            title: "Morning run",
            logTime: Date()
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )

        let result = MatchingService.matches(
            action: action,
            actionMeasures: [(kmMeasure, 5.0)],
            goal: goal,
            goalTargets: [(kmMeasure, 120.0)],
            keywords: ["run", "jog"]
        )

        #expect(result.isMatch == true)
        #expect(result.periodMatch == true)
        #expect(result.metricMatch.hasOverlap == true)
        #expect(result.keywordMatch == true)
        #expect(result.overallConfidence > 0.8)  // High confidence
    }

    @Test("Combined matching - fails on period mismatch")
    func testCombinedMatchFailsPeriod() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let action = Action(
            title: "Old run",
            logTime: Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )

        let result = MatchingService.matches(
            action: action,
            actionMeasures: [(kmMeasure, 5.0)],
            goal: goal,
            goalTargets: [(kmMeasure, 120.0)],
            keywords: ["run"]
        )

        #expect(result.isMatch == false)  // Period mismatch fails entire match
        #expect(result.periodMatch == false)
        #expect(result.overallConfidence == 0.0)
    }

    @Test("Combined matching - fails on metric mismatch")
    func testCombinedMatchFailsMetrics() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")
        let pagesMeasure = Measure(unit: "pages", measureType: "count")

        let action = Action(
            title: "Reading",
            logTime: Date()
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )

        let result = MatchingService.matches(
            action: action,
            actionMeasures: [(pagesMeasure, 25.0)],
            goal: goal,
            goalTargets: [(kmMeasure, 120.0)],
            keywords: nil
        )

        #expect(result.isMatch == false)  // Metric mismatch fails entire match
        #expect(result.metricMatch.hasOverlap == false)
        #expect(result.overallConfidence == 0.0)
    }

    @Test("Combined matching - keywords are optional (nil is ok)")
    func testCombinedMatchNoKeywords() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let action = Action(
            title: "Exercise",
            logTime: Date()
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )

        let result = MatchingService.matches(
            action: action,
            actionMeasures: [(kmMeasure, 5.0)],
            goal: goal,
            goalTargets: [(kmMeasure, 120.0)],
            keywords: nil  // No keywords provided
        )

        #expect(result.isMatch == true)
        #expect(result.keywordMatch == nil)  // Not checked
        #expect(result.overallConfidence > 0.5)  // Lower without keyword boost
    }

    @Test("Combined matching - keyword mismatch reduces confidence but doesn't fail match")
    func testCombinedMatchKeywordMismatchReducesConfidence() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let action = Action(
            title: "Yoga class",  // Doesn't contain "run"
            logTime: Date()
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )

        let result = MatchingService.matches(
            action: action,
            actionMeasures: [(kmMeasure, 5.0)],
            goal: goal,
            goalTargets: [(kmMeasure, 120.0)],
            keywords: ["run", "jog"]  // Action doesn't match these
        )

        #expect(result.isMatch == true)  // Still matches (period + metrics ok)
        #expect(result.keywordMatch == false)
        #expect(result.overallConfidence < 0.7)  // Lower confidence without keyword match
    }

    @Test("Combined matching - contribution amount is accessible")
    func testCombinedMatchContributionAmount() {
        let kmMeasure = Measure(unit: "km", measureType: "distance")

        let action = Action(
            title: "Run",
            logTime: Date()
        )

        let goal = Goal(
            expectationId: UUID(),
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )

        let result = MatchingService.matches(
            action: action,
            actionMeasures: [(kmMeasure, 8.5)],
            goal: goal,
            goalTargets: [(kmMeasure, 120.0)],
            keywords: nil
        )

        #expect(result.isMatch == true)
        #expect(result.metricMatch.contribution == 8.5)
    }
}
