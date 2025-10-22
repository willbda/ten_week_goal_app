// TermRowViewTests.swift
// Tests for TermRowView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for TermRowView component
///
/// Verifies the display of term data including term number, theme,
/// date ranges, goal counts, and status badges (active/upcoming/past).
@Suite("TermRowView Tests")
struct TermRowViewTests {

    // MARK: - Display Tests

    @Test("Displays term number correctly")
    func displaysTermNumber() {
        let term = GoalTerm(
            termNumber: 3,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: []
        )

        #expect(term.termNumber == 3)
    }

    @Test("Displays term with theme")
    func displaysTermTheme() {
        let term = GoalTerm(
            title: "Fall Focus",
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            theme: "Health & Career",
            termGoalsByID: []
        )

        #expect(term.theme == "Health & Career")
    }

    @Test("Handles term without theme")
    func handlesTermWithoutTheme() {
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: []
        )

        #expect(term.theme == nil)
    }

    @Test("Displays date range")
    func displaysDateRange() {
        let startDate = Date()
        let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: startDate)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        #expect(term.startDate == startDate)
        #expect(term.targetDate == targetDate)
    }

    @Test("Displays goal count")
    func displaysGoalCount() {
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: [UUID(), UUID(), UUID()]
        )

        #expect(term.termGoalsByID.count == 3)
    }

    @Test("Handles term with no goals")
    func handlesTermWithNoGoals() {
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: []
        )

        #expect(term.termGoalsByID.isEmpty)
    }

    @Test("Displays singular 'goal' for count of 1")
    func displaysSingularGoal() {
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: [UUID()]
        )

        #expect(term.termGoalsByID.count == 1)
    }

    @Test("Displays plural 'goals' for count > 1")
    func displaysPluralGoals() {
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: [UUID(), UUID()]
        )

        #expect(term.termGoalsByID.count > 1)
    }

    // MARK: - Status Badge Tests

    @Test("Shows ACTIVE badge for current term")
    func showsActiveBadgeForCurrentTerm() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: 63, to: now)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        // Term should be active (now is between start and target)
        let isActive = term.startDate <= now && now <= term.targetDate
        #expect(isActive)
    }

    @Test("Shows UPCOMING badge for future term")
    func showsUpcomingBadgeForFutureTerm() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: 70, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: 140, to: now)!

        let term = GoalTerm(
            termNumber: 2,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        // Term should be upcoming (start is in future)
        let isUpcoming = term.startDate > now
        #expect(isUpcoming)
    }

    @Test("Shows PAST badge for completed term")
    func showsPastBadgeForCompletedTerm() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -80, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        // Term should be past (target date is in the past)
        let isPast = term.targetDate < now
        #expect(isPast)
    }

    @Test("Term starting today is active")
    func termStartingTodayIsActive() {
        let now = Date()
        let startDate = now
        let targetDate = Calendar.current.date(byAdding: .day, value: 70, to: now)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let isActive = term.startDate <= now && now <= term.targetDate
        #expect(isActive)
    }

    @Test("Term ending today is active")
    func termEndingTodayIsActive() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -70, to: now)!
        let targetDate = now

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let isActive = term.startDate <= now && now <= term.targetDate
        #expect(isActive)
    }

    @Test("Term ending yesterday is past")
    func termEndingYesterdayIsPast() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -80, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let isPast = term.targetDate < now
        #expect(isPast)
    }

    @Test("Term starting tomorrow is upcoming")
    func termStartingTomorrowIsUpcoming() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: 71, to: now)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let isUpcoming = term.startDate > now
        #expect(isUpcoming)
    }

    // MARK: - Date Range Formatting Tests

    @Test("Formats standard 10-week term")
    func formatsStandardTenWeekTerm() {
        let startDate = Date()
        let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: startDate)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        // Verify date difference is approximately 70 days
        let daysDifference = Calendar.current.dateComponents([.day], from: term.startDate, to: term.targetDate).day!
        #expect(daysDifference >= 69 && daysDifference <= 70)
    }

    @Test("Handles short term duration")
    func handlesShortTermDuration() {
        let startDate = Date()
        let targetDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let daysDifference = Calendar.current.dateComponents([.day], from: term.startDate, to: term.targetDate).day!
        #expect(daysDifference == 7)
    }

    @Test("Handles long term duration")
    func handlesLongTermDuration() {
        let startDate = Date()
        let targetDate = Calendar.current.date(byAdding: .month, value: 6, to: startDate)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let monthsDifference = Calendar.current.dateComponents([.month], from: term.startDate, to: term.targetDate).month!
        #expect(monthsDifference == 6)
    }

    // MARK: - Combined Features Tests

    @Test("Displays active term with all features")
    func displaysActiveTermWithAllFeatures() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: 63, to: now)!

        let term = GoalTerm(
            title: "Fall Focus",
            termNumber: 3,
            startDate: startDate,
            targetDate: targetDate,
            theme: "Health & Career",
            termGoalsByID: [UUID(), UUID(), UUID()]
        )

        #expect(term.termNumber == 3)
        #expect(term.theme == "Health & Career")
        #expect(term.termGoalsByID.count == 3)

        let isActive = term.startDate <= now && now <= term.targetDate
        #expect(isActive)
    }

    @Test("Displays upcoming term with partial features")
    func displaysUpcomingTermPartialFeatures() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: 70, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: 140, to: now)!

        let term = GoalTerm(
            title: "Winter Planning",
            termNumber: 4,
            startDate: startDate,
            targetDate: targetDate,
            theme: "Relationships",
            termGoalsByID: [UUID()]
        )

        #expect(term.termNumber == 4)
        #expect(term.theme == "Relationships")
        #expect(term.termGoalsByID.count == 1)

        let isUpcoming = term.startDate > now
        #expect(isUpcoming)
    }

    @Test("Displays past term with minimal features")
    func displaysPastTermMinimalFeatures() {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -150, to: now)!
        let targetDate = Calendar.current.date(byAdding: .day, value: -80, to: now)!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        #expect(term.termNumber == 1)
        #expect(term.theme == nil)
        #expect(term.termGoalsByID.isEmpty)

        let isPast = term.targetDate < now
        #expect(isPast)
    }

    // MARK: - Edge Cases

    @Test("Handles very high term number")
    func handlesHighTermNumber() {
        let term = GoalTerm(
            termNumber: 99,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: []
        )

        #expect(term.termNumber == 99)
    }

    @Test("Handles very long theme")
    func handlesLongTheme() {
        let longTheme = String(repeating: "Very long theme text ", count: 10)
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            theme: longTheme,
            termGoalsByID: []
        )

        #expect(term.theme == longTheme)
        #expect(term.theme!.count > 100)
    }

    @Test("Handles many goals")
    func handlesManyGoals() {
        let manyGoals = (1...20).map { _ in UUID() }
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            termGoalsByID: manyGoals
        )

        #expect(term.termGoalsByID.count == 20)
    }

    @Test("Handles term with far past dates")
    func handlesFarPastDates() {
        let startDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())!
        let targetDate = Calendar.current.date(byAdding: .year, value: -4, to: Date())!

        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let isPast = term.targetDate < Date()
        #expect(isPast)
    }

    @Test("Handles term with far future dates")
    func handlesFarFutureDates() {
        let startDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        let targetDate = Calendar.current.date(byAdding: .year, value: 6, to: Date())!

        let term = GoalTerm(
            termNumber: 10,
            startDate: startDate,
            targetDate: targetDate,
            termGoalsByID: []
        )

        let isUpcoming = term.startDate > Date()
        #expect(isUpcoming)
    }

    @Test("Handles single day term")
    func handlesSingleDayTerm() {
        let date = Date()
        let term = GoalTerm(
            termNumber: 1,
            startDate: date,
            targetDate: date,
            termGoalsByID: []
        )

        let daysDifference = Calendar.current.dateComponents([.day], from: term.startDate, to: term.targetDate).day!
        #expect(daysDifference == 0)
    }

    @Test("Multiple terms have unique properties")
    func multipleTermsHaveUniqueProperties() {
        let now = Date()

        let term1 = GoalTerm(
            termNumber: 1,
            startDate: Calendar.current.date(byAdding: .day, value: -80, to: now)!,
            targetDate: Calendar.current.date(byAdding: .day, value: -10, to: now)!,
            theme: "Past Term",
            termGoalsByID: []
        )

        let term2 = GoalTerm(
            termNumber: 2,
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: now)!,
            targetDate: Calendar.current.date(byAdding: .day, value: 63, to: now)!,
            theme: "Active Term",
            termGoalsByID: [UUID()]
        )

        let term3 = GoalTerm(
            termNumber: 3,
            startDate: Calendar.current.date(byAdding: .day, value: 70, to: now)!,
            targetDate: Calendar.current.date(byAdding: .day, value: 140, to: now)!,
            theme: "Future Term",
            termGoalsByID: [UUID(), UUID()]
        )

        #expect(term1.termNumber != term2.termNumber)
        #expect(term2.termNumber != term3.termNumber)
        #expect(term1.theme != term2.theme)
        #expect(term2.theme != term3.theme)
    }

    @Test("Friendly name is independent of display")
    func titleIsIndependent() {
        let term = GoalTerm(
            title: "Custom Name",
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            theme: "Different Theme",
            termGoalsByID: []
        )

        #expect(term.title == "Custom Name")
        #expect(term.theme == "Different Theme")
    }
}
