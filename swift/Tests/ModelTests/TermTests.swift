// TermTests.swift
// Tests for GoalTerm and LifeTime domain entities
//
// Written by Claude Code on 2025-10-19
// Ported from Python implementation (python/tests/test_terms.py)

import XCTest
@testable import Models

final class TermTests: XCTestCase {

    // MARK: - GoalTerm Creation & Defaults

    func testMinimalTermCreation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later (10 weeks)

        let term = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end
        )

        XCTAssertEqual(term.termNumber, 1)
        XCTAssertEqual(term.polymorphicSubtype, "goal_term")
        XCTAssertNotNil(term.id) // UUID auto-generated
        XCTAssertNotNil(term.logTime) // Defaults to Date()
        XCTAssertTrue(term.termGoalsByID.isEmpty) // Empty array by default
        XCTAssertNil(term.theme)
        XCTAssertNil(term.reflection)
    }

    func testFullyPopulatedTerm() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)
        let goalID1 = UUID()
        let goalID2 = UUID()

        let term = GoalTerm(
            friendlyName: "Q4 2025",
            detailedDescription: "Final term of the year",
            freeformNotes: "Focus on momentum",
            termNumber: 4,
            startDate: start,
            targetDate: end,
            theme: "Building sustainable habits",
            termGoalsByID: [goalID1, goalID2],
            reflection: "Made great progress on consistency"
        )

        XCTAssertEqual(term.friendlyName, "Q4 2025")
        XCTAssertEqual(term.theme, "Building sustainable habits")
        XCTAssertEqual(term.termGoalsByID.count, 2)
        XCTAssertTrue(term.termGoalsByID.contains(goalID1))
        XCTAssertTrue(term.termGoalsByID.contains(goalID2))
        XCTAssertEqual(term.reflection, "Made great progress on consistency")
    }

    // MARK: - GoalTerm Validation

    func testTermDateValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        // Valid: start before end
        let validTerm = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end
        )
        XCTAssertTrue(validTerm.isValid())

        // Invalid: start after end
        let invalidTerm = GoalTerm(
            termNumber: 1,
            startDate: end,
            targetDate: start
        )
        XCTAssertFalse(invalidTerm.isValid())

        // Invalid: start equals end
        let sameDate = Date()
        let equalTerm = GoalTerm(
            termNumber: 1,
            startDate: sameDate,
            targetDate: sameDate
        )
        XCTAssertFalse(equalTerm.isValid())
    }

    func testTermNumberValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        // Valid: positive term number
        let validTerm = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end
        )
        XCTAssertTrue(validTerm.isValid())

        // Valid: zero term number
        let zeroTerm = GoalTerm(
            termNumber: 0,
            startDate: start,
            targetDate: end
        )
        XCTAssertTrue(zeroTerm.isValid())

        // Invalid: negative term number
        let negativeTerm = GoalTerm(
            termNumber: -1,
            startDate: start,
            targetDate: end
        )
        XCTAssertFalse(negativeTerm.isValid())
    }

    // MARK: - Active Status Tests

    func testIsActiveCurrentTerm() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-60*60*24) // 1 day ago
        let tomorrow = now.addingTimeInterval(60*60*24) // 1 day from now

        let activeTerm = GoalTerm(
            termNumber: 1,
            startDate: yesterday,
            targetDate: tomorrow
        )

        XCTAssertTrue(activeTerm.isActive()) // Current date is today
        XCTAssertTrue(activeTerm.isActive(checkDate: now))
    }

    func testIsActiveFutureTerm() {
        let now = Date()
        let nextWeek = now.addingTimeInterval(60*60*24*7) // 7 days from now
        let tenWeeksFromNow = now.addingTimeInterval(60*60*24*77) // 77 days from now

        let futureTerm = GoalTerm(
            termNumber: 2,
            startDate: nextWeek,
            targetDate: tenWeeksFromNow
        )

        XCTAssertFalse(futureTerm.isActive()) // Not started yet
        XCTAssertFalse(futureTerm.isActive(checkDate: now))
    }

    func testIsActivePastTerm() {
        let now = Date()
        let twoMonthsAgo = now.addingTimeInterval(-60*60*24*60) // 60 days ago
        let oneMonthAgo = now.addingTimeInterval(-60*60*24*30) // 30 days ago

        let pastTerm = GoalTerm(
            termNumber: 0,
            startDate: twoMonthsAgo,
            targetDate: oneMonthAgo
        )

        XCTAssertFalse(pastTerm.isActive()) // Already completed
        XCTAssertFalse(pastTerm.isActive(checkDate: now))
    }

    // MARK: - Days Remaining Tests

    func testDaysRemainingActiveTerm() {
        let now = Date()
        let tomorrow = now.addingTimeInterval(60*60*24) // 1 day from now
        let tenDaysFromNow = now.addingTimeInterval(60*60*24*10) // 10 days from now

        let term = GoalTerm(
            termNumber: 1,
            startDate: tomorrow,
            targetDate: tenDaysFromNow
        )

        let remaining = term.daysRemaining(fromDate: now)
        XCTAssertEqual(remaining, 10) // 10 days until target
    }

    func testDaysRemainingPastTerm() {
        let now = Date()
        let oneMonthAgo = now.addingTimeInterval(-60*60*24*30) // 30 days ago
        let twoWeeksAgo = now.addingTimeInterval(-60*60*24*14) // 14 days ago

        let pastTerm = GoalTerm(
            termNumber: 0,
            startDate: oneMonthAgo,
            targetDate: twoWeeksAgo
        )

        let remaining = pastTerm.daysRemaining(fromDate: now)
        XCTAssertEqual(remaining, 0) // Past term has 0 days remaining
    }

    // MARK: - Progress Percentage Tests

    func testProgressPercentageNotStarted() {
        let now = Date()
        let nextWeek = now.addingTimeInterval(60*60*24*7) // 7 days from now
        let tenWeeksFromNow = now.addingTimeInterval(60*60*24*77) // 77 days from now

        let futureTerm = GoalTerm(
            termNumber: 1,
            startDate: nextWeek,
            targetDate: tenWeeksFromNow
        )

        let progress = futureTerm.progressPercentage(fromDate: now)
        XCTAssertEqual(progress, 0.0, accuracy: 0.01) // Not started yet
    }

    func testProgressPercentageHalfway() {
        let now = Date()
        let fiveDaysAgo = now.addingTimeInterval(-60*60*24*5) // 5 days ago
        let fiveDaysFromNow = now.addingTimeInterval(60*60*24*5) // 5 days from now

        let term = GoalTerm(
            termNumber: 1,
            startDate: fiveDaysAgo,
            targetDate: fiveDaysFromNow
        )

        let progress = term.progressPercentage(fromDate: now)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01) // Halfway through
    }

    func testProgressPercentageComplete() {
        let now = Date()
        let tenDaysAgo = now.addingTimeInterval(-60*60*24*10) // 10 days ago
        let fiveDaysAgo = now.addingTimeInterval(-60*60*24*5) // 5 days ago

        let pastTerm = GoalTerm(
            termNumber: 0,
            startDate: tenDaysAgo,
            targetDate: fiveDaysAgo
        )

        let progress = pastTerm.progressPercentage(fromDate: now)
        XCTAssertEqual(progress, 1.0, accuracy: 0.01) // Complete
    }

    // MARK: - Goal Association Tests

    func testTermWithMultipleGoals() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        let goalIDs = [UUID(), UUID(), UUID()]

        let term = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end,
            termGoalsByID: goalIDs
        )

        XCTAssertEqual(term.termGoalsByID.count, 3)
        for goalID in goalIDs {
            XCTAssertTrue(term.termGoalsByID.contains(goalID))
        }
    }

    // MARK: - LifeTime Tests

    func testLifeTimeCreation() {
        let birthDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970

        let lifetime = LifeTime(birthDate: birthDate)

        XCTAssertEqual(lifetime.polymorphicSubtype, "lifetime")
        XCTAssertEqual(lifetime.birthDate, birthDate)
        XCTAssertNil(lifetime.estimatedDeathDate) // Optional
        XCTAssertNotNil(lifetime.id)
    }

    func testLifeTimeWithEstimatedDeath() {
        let birthDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let deathDate = birthDate.addingTimeInterval(60*60*24*365.25*79) // 79 years later

        let lifetime = LifeTime(
            birthDate: birthDate,
            estimatedDeathDate: deathDate
        )

        XCTAssertEqual(lifetime.estimatedDeathDate, deathDate)
    }

    func testWeeksLived() {
        let birthDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let currentDate = birthDate.addingTimeInterval(60*60*24*7*100) // 100 weeks later

        let lifetime = LifeTime(birthDate: birthDate)
        let weeks = lifetime.weeksLived(currentDate: currentDate)

        XCTAssertEqual(weeks, 100)
    }

    func testWeeksRemainingWithEstimate() {
        let currentDate = Date()
        let birthDate = currentDate.addingTimeInterval(-60*60*24*365.25*30) // Born 30 years ago
        let deathDate = currentDate.addingTimeInterval(60*60*24*365.25*49) // Die in 49 years

        let lifetime = LifeTime(
            birthDate: birthDate,
            estimatedDeathDate: deathDate
        )

        let remaining = lifetime.weeksRemaining(currentDate: currentDate)
        XCTAssertNotNil(remaining)
        // Approximately 49 years * 52 weeks = ~2,548 weeks
        XCTAssertGreaterThan(remaining!, 2500)
        XCTAssertLessThan(remaining!, 2600)
    }

    func testWeeksRemainingNoEstimate() {
        let birthDate = Date(timeIntervalSince1970: 0)
        let lifetime = LifeTime(birthDate: birthDate) // No death estimate

        let remaining = lifetime.weeksRemaining()
        XCTAssertNil(remaining) // Can't calculate without estimate
    }
}
