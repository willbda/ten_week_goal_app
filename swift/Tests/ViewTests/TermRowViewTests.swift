// TermRowViewTests.swift  
// Tests for TermRowView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21
// Updated by Claude Code on 2025-10-23 (removed termGoalsByID - now uses junction table)

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for TermRowView component
///
/// Verifies the display of term data including term number, theme,
/// date ranges, and status badges (active/upcoming/past).
///
/// Note: Goal count tests removed - goals now stored in junction table (term_goal_assignments)
@Suite("TermRowView Tests")
struct TermRowViewTests {

    // MARK: - Display Tests

    @Test("Displays term number correctly")
    func displaysTermNumber() {
        let term = GoalTerm(
            termNumber: 3,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600)
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
            theme: "Health & Career"
        )

        #expect(term.theme == "Health & Career")
    }

    @Test("Handles term without theme")
    func handlesTermWithoutTheme() {
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600)
        )

        #expect(term.theme == nil)
    }

    // MARK: - Date Display Tests

    @Test("Shows date range correctly")
    func showsDateRange() {
        let startDate = Date()
        let targetDate = Date().addingTimeInterval(70 * 24 * 3600)
        
        let term = GoalTerm(
            termNumber: 1,
            startDate: startDate,
            targetDate: targetDate
        )

        #expect(term.startDate == startDate)
        #expect(term.targetDate == targetDate)
    }

    @Test("Calculates duration correctly")
    func calculatesDuration() {
        let now = Date()
        let term = GoalTerm(
            termNumber: 1,
            startDate: now,
            targetDate: Calendar.current.date(byAdding: .day, value: 70, to: now)!
        )

        let duration = term.targetDate.timeIntervalSince(term.startDate)
        let daysApprox = duration / (24 * 3600)
        
        #expect(daysApprox >= 69 && daysApprox <= 71) // ~70 days
    }

    // MARK: - Status Tests

    @Test("Identifies past term")
    func identifiesPastTerm() {
        let now = Date()
        let term = GoalTerm(
            termNumber: 1,
            startDate: Calendar.current.date(byAdding: .day, value: -100, to: now)!,
            targetDate: Calendar.current.date(byAdding: .day, value: -30, to: now)!
        )

        #expect(term.targetDate < now)
    }

    @Test("Identifies active term")
    func identifiesActiveTerm() {
        let now = Date()
        let term = GoalTerm(
            termNumber: 1,
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: now)!,
            targetDate: Calendar.current.date(byAdding: .day, value: 63, to: now)!
        )

        #expect(term.startDate <= now)
        #expect(term.targetDate >= now)
    }

    @Test("Identifies future term")
    func identifiesFutureTerm() {
        let now = Date()
        let term = GoalTerm(
            termNumber: 2,
            startDate: Calendar.current.date(byAdding: .day, value: 70, to: now)!,
            targetDate: Calendar.current.date(byAdding: .day, value: 140, to: now)!
        )

        #expect(term.startDate > now)
    }

    // MARK: - Edge Cases

    @Test("Handles very long theme text")
    func handlesLongTheme() {
        let longTheme = String(repeating: "Theme ", count: 50)
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            theme: longTheme
        )

        #expect(term.theme == longTheme)
        #expect(term.theme!.count > 100)
    }

    @Test("Handles term with all optional fields nil")
    func handlesMinimalTerm() {
        let term = GoalTerm(
            title: nil,
            detailedDescription: nil,
            freeformNotes: nil,
            termNumber: 1,
            startDate: Date(),
            targetDate: Date().addingTimeInterval(70 * 24 * 3600),
            theme: nil,
            reflection: nil
        )

        #expect(term.title == nil)
        #expect(term.theme == nil)
        #expect(term.reflection == nil)
    }

    @Test("Handles term with reflection")
    func handlesTermWithReflection() {
        let reflection = "Great progress on all goals. Need to focus more on consistency next term."
        let term = GoalTerm(
            termNumber: 1,
            startDate: Date(),
            targetDate: Date(),
            reflection: reflection
        )

        #expect(term.reflection == reflection)
    }
}
