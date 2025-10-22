// TermTests.swift
// Tests for GoalTerm and LifeTime domain entities
//
// Written by Claude Code on 2025-10-19
// Updated 2025-10-21: Converted to modern Swift Testing framework
// Ported from Python implementation (python/tests/test_terms.py)

import Foundation
import Testing
@testable import Models

@Suite("Term Tests")
struct TermTests {

    // MARK: - GoalTerm Creation & Defaults

    @Test func testMinimalTermCreation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70) // 70 days later (10 weeks)

        let term = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end
        )

        #expect(term.termNumber == 1)
        #expect(term.polymorphicSubtype == "goal_term")
        #expect(term.id != nil) // UUID auto-generated
        #expect(term.logTime != nil) // Defaults to Date()
        #expect(term.termGoalsByID.isEmpty) // Empty array by default
        #expect(term.theme == nil)
        #expect(term.reflection == nil)
    }

    @Test func testFullyPopulatedTerm() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)
        let goalID1 = UUID()
        let goalID2 = UUID()

        let term = GoalTerm(
            title: "Q4 2025",
            detailedDescription: "Final term of the year",
            freeformNotes: "Focus on momentum",
            termNumber: 4,
            startDate: start,
            targetDate: end,
            theme: "Building sustainable habits",
            termGoalsByID: [goalID1, goalID2],
            reflection: "Made great progress on consistency"
        )

        #expect(term.title == "Q4 2025")
        #expect(term.theme == "Building sustainable habits")
        #expect(term.termGoalsByID.count == 2)
        #expect(term.termGoalsByID.contains(goalID1))
        #expect(term.termGoalsByID.contains(goalID2))
        #expect(term.reflection == "Made great progress on consistency")
    }

    // MARK: - GoalTerm Validation

    @Test func testTermDateValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        // Valid: start before end
        let validTerm = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end
        )
        #expect(validTerm.isValid())

        // Invalid: start after end
        let invalidTerm = GoalTerm(
            termNumber: 1,
            startDate: end,
            targetDate: start
        )
        #expect(!invalidTerm.isValid())

        // Invalid: start equals end
        let sameDate = Date()
        let equalTerm = GoalTerm(
            termNumber: 1,
            startDate: sameDate,
            targetDate: sameDate
        )
        #expect(!equalTerm.isValid())
    }

    @Test func testTermNumberValidation() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        // Valid: positive term number
        let validTerm = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end
        )
        #expect(validTerm.isValid())

        // Valid: zero term number
        let zeroTerm = GoalTerm(
            termNumber: 0,
            startDate: start,
            targetDate: end
        )
        #expect(zeroTerm.isValid())

        // Invalid: negative term number
        let negativeTerm = GoalTerm(
            termNumber: -1,
            startDate: start,
            targetDate: end
        )
        #expect(!negativeTerm.isValid())
    }

    // MARK: - Active Status Tests

    @Test func testIsActiveCurrentTerm() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-60*60*24) // 1 day ago
        let tomorrow = now.addingTimeInterval(60*60*24) // 1 day from now

        let activeTerm = GoalTerm(
            termNumber: 1,
            startDate: yesterday,
            targetDate: tomorrow
        )

        #expect(activeTerm.isActive()) // Current date is today
        #expect(activeTerm.isActive(checkDate: now))
    }

    @Test func testIsActiveFutureTerm() {
        let now = Date()
        let nextWeek = now.addingTimeInterval(60*60*24*7) // 7 days from now
        let tenWeeksFromNow = now.addingTimeInterval(60*60*24*77) // 77 days from now

        let futureTerm = GoalTerm(
            termNumber: 2,
            startDate: nextWeek,
            targetDate: tenWeeksFromNow
        )

        #expect(!futureTerm.isActive()) // Not started yet
        #expect(!futureTerm.isActive(checkDate: now))
    }

    @Test func testIsActivePastTerm() {
        let now = Date()
        let twoMonthsAgo = now.addingTimeInterval(-60*60*24*60) // 60 days ago
        let oneMonthAgo = now.addingTimeInterval(-60*60*24*30) // 30 days ago

        let pastTerm = GoalTerm(
            termNumber: 0,
            startDate: twoMonthsAgo,
            targetDate: oneMonthAgo
        )

        #expect(!pastTerm.isActive()) // Already completed
        #expect(!pastTerm.isActive(checkDate: now))
    }

    // MARK: - Days Remaining Tests

    @Test func testDaysRemainingActiveTerm() {
        let now = Date()
        let tomorrow = now.addingTimeInterval(60*60*24) // 1 day from now
        let tenDaysFromNow = now.addingTimeInterval(60*60*24*10) // 10 days from now

        let term = GoalTerm(
            termNumber: 1,
            startDate: tomorrow,
            targetDate: tenDaysFromNow
        )

        let remaining = term.daysRemaining(fromDate: now)
        #expect(remaining == 10) // 10 days until target
    }

    @Test func testDaysRemainingPastTerm() {
        let now = Date()
        let oneMonthAgo = now.addingTimeInterval(-60*60*24*30) // 30 days ago
        let twoWeeksAgo = now.addingTimeInterval(-60*60*24*14) // 14 days ago

        let pastTerm = GoalTerm(
            termNumber: 0,
            startDate: oneMonthAgo,
            targetDate: twoWeeksAgo
        )

        let remaining = pastTerm.daysRemaining(fromDate: now)
        #expect(remaining == 0) // Past term has 0 days remaining
    }

    // MARK: - Progress Percentage Tests

    @Test func testProgressPercentageNotStarted() {
        let now = Date()
        let nextWeek = now.addingTimeInterval(60*60*24*7) // 7 days from now
        let tenWeeksFromNow = now.addingTimeInterval(60*60*24*77) // 77 days from now

        let futureTerm = GoalTerm(
            termNumber: 1,
            startDate: nextWeek,
            targetDate: tenWeeksFromNow
        )

        let progress = futureTerm.progressPercentage(fromDate: now)
        #expect(abs(progress - 0.0) < 0.01) // Not started yet
    }

    @Test func testProgressPercentageHalfway() {
        let now = Date()
        let fiveDaysAgo = now.addingTimeInterval(-60*60*24*5) // 5 days ago
        let fiveDaysFromNow = now.addingTimeInterval(60*60*24*5) // 5 days from now

        let term = GoalTerm(
            termNumber: 1,
            startDate: fiveDaysAgo,
            targetDate: fiveDaysFromNow
        )

        let progress = term.progressPercentage(fromDate: now)
        #expect(abs(progress - 0.5) < 0.01) // Halfway through
    }

    @Test func testProgressPercentageComplete() {
        let now = Date()
        let tenDaysAgo = now.addingTimeInterval(-60*60*24*10) // 10 days ago
        let fiveDaysAgo = now.addingTimeInterval(-60*60*24*5) // 5 days ago

        let pastTerm = GoalTerm(
            termNumber: 0,
            startDate: tenDaysAgo,
            targetDate: fiveDaysAgo
        )

        let progress = pastTerm.progressPercentage(fromDate: now)
        #expect(abs(progress - 1.0) < 0.01) // Complete
    }

    // MARK: - Goal Association Tests

    @Test func testTermWithMultipleGoals() {
        let start = Date()
        let end = start.addingTimeInterval(60*60*24*70)

        let goalIDs = [UUID(), UUID(), UUID()]

        let term = GoalTerm(
            termNumber: 1,
            startDate: start,
            targetDate: end,
            termGoalsByID: goalIDs
        )

        #expect(term.termGoalsByID.count == 3)
        for goalID in goalIDs {
            #expect(term.termGoalsByID.contains(goalID))
        }
    }

    // MARK: - LifeTime Tests

    @Test func testLifeTimeCreation() {
        let birthDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970

        let lifetime = LifeTime(birthDate: birthDate)

        #expect(lifetime.polymorphicSubtype == "lifetime")
        #expect(lifetime.birthDate == birthDate)
        #expect(lifetime.estimatedDeathDate == nil) // Optional
        #expect(lifetime.id != nil)
    }

    @Test func testLifeTimeWithEstimatedDeath() {
        let birthDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let deathDate = birthDate.addingTimeInterval(60*60*24*365.25*79) // 79 years later

        let lifetime = LifeTime(
            birthDate: birthDate,
            estimatedDeathDate: deathDate
        )

        #expect(lifetime.estimatedDeathDate == deathDate)
    }

    @Test func testWeeksLived() {
        let birthDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let currentDate = birthDate.addingTimeInterval(60*60*24*7*100) // 100 weeks later

        let lifetime = LifeTime(birthDate: birthDate)
        let weeks = lifetime.weeksLived(currentDate: currentDate)

        #expect(weeks == 100)
    }

    @Test func testWeeksRemainingWithEstimate() {
        let currentDate = Date()
        let birthDate = currentDate.addingTimeInterval(-60*60*24*365.25*30) // Born 30 years ago
        let deathDate = currentDate.addingTimeInterval(60*60*24*365.25*49) // Die in 49 years

        let lifetime = LifeTime(
            birthDate: birthDate,
            estimatedDeathDate: deathDate
        )

        let remaining = lifetime.weeksRemaining(currentDate: currentDate)
        #expect(remaining != nil)
        // Approximately 49 years * 52 weeks = ~2,548 weeks
        #expect(remaining! > 2500)
        #expect(remaining! < 2600)
    }

    @Test func testWeeksRemainingNoEstimate() {
        let birthDate = Date(timeIntervalSince1970: 0)
        let lifetime = LifeTime(birthDate: birthDate) // No death estimate

        let remaining = lifetime.weeksRemaining()
        #expect(remaining == nil) // Can't calculate without estimate
    }
}
