// Terms.swift
// Time horizons for planning and reflection
//
// Written by Claude Code on 2025-10-18
// Ported from Python implementation (python/categoriae/terms.py)
//
// Inspired by "4,000 Weeks" thinking - how do we structure finite time?
// Terms provide temporal scaffolding for goals and rhythmic reflection points.

import Foundation

// MARK: - Constants

/// Life expectancy in Minnesota (CDC data)
let MN_LIFE_EXPECTANCY_YEARS = 79.0

/// Average days per year (accounting for leap years)
let DAYS_PER_YEAR = 365.25

// MARK: - TimeFrame Protocol

/// Base protocol for all time-bounded planning horizons
///
/// Time is the fundamental constraint - we have roughly 4,000 weeks.
/// How we divide and allocate that time reflects what we value.
protocol TimeFrame: Persistable {
    // Inherits: id, friendlyName, detailedDescription, freeformNotes, logTime
}

// MARK: - GoalTerm Class

/// A fundamental unit of structured planning
///
/// Inspired by academic terms but adapted for personal productivity.
/// A term should be long enough to make meaningful progress, but short
/// enough to maintain focus and urgency.
///
/// Default: 10 weeks (70 days)
class GoalTerm: Persistable {
    // MARK: - Persistable Protocol Requirements

    var id: UUID
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date

    // MARK: - Constants

    static let TEN_WEEKS_IN_DAYS = 70 // 10 weeks × 7 days/week

    // MARK: - GoalTerm-specific Properties

    /// Sequential identifier (e.g., Term 1, Term 2)
    var termNumber: Int

    /// First day of term
    var startDate: Date

    /// Last day of term (default: 70 days after start)
    var targetDate: Date

    /// Optional focus area (e.g., "Health & Learning")
    var theme: String?

    /// Goal IDs associated with this term
    var termGoalsByID: [UUID]

    /// Post-term reflection notes
    var reflection: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = "A focused 10-week period for achieving specific goals",
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        termNumber: Int = 0,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        theme: String? = nil,
        termGoalsByID: [UUID] = [],
        reflection: String? = nil
    ) {
        self.id = id
        self.friendlyName = friendlyName
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.termNumber = termNumber
        self.startDate = startDate
        // If no target date provided, default to 70 days after start
        self.targetDate = targetDate ?? startDate.addingTimeInterval(Double(GoalTerm.TEN_WEEKS_IN_DAYS) * 24 * 60 * 60)
        self.theme = theme
        self.termGoalsByID = termGoalsByID
        self.reflection = reflection
    }

    // MARK: - Term Status Methods

    /// Check if term is currently active
    func isActive(checkDate: Date = Date()) -> Bool {
        return startDate <= checkDate && checkDate <= targetDate
    }

    /// Calculate days remaining in term
    func daysRemaining(fromDate: Date = Date()) -> Int {
        guard fromDate <= targetDate else { return 0 }
        let components = Calendar.current.dateComponents([.day], from: fromDate, to: targetDate)
        return max(0, components.day ?? 0)
    }

    /// Calculate percentage of term completed (0.0 to 1.0)
    func progressPercentage(fromDate: Date = Date()) -> Double {
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        let elapsedDays = Calendar.current.dateComponents([.day], from: startDate, to: fromDate).day ?? 0

        if elapsedDays < 0 { return 0.0 }
        if elapsedDays > totalDays { return 1.0 }
        return Double(elapsedDays) / Double(totalDays)
    }
}

// MARK: - LifeTime Class (Memento Mori)

/// The full arc of a human life - roughly 4,500 weeks
///
/// Memento Mori as data structure - a reminder that:
/// - Time is finite and precious
/// - How we spend weeks reveals what we truly value
/// - Planning matters because we're mortal
///
/// "I will be dead here shortly. Realistically, maybe that's another 30 to 70 years."
class LifeTime {
    // MARK: - Properties

    /// Date of birth
    var birthDate: Date

    /// Statistical estimate of death (not fatalistic, just realistic)
    var estimatedDeathDate: Date

    /// How you intend to allocate remaining time across life areas
    var lifeAreasAllocation: [String: Double]

    /// Ongoing philosophical reflection
    var lifeReflection: String?

    // MARK: - Initialization

    init(
        birthDate: Date,
        estimatedDeathDate: Date? = nil,
        lifeAreasAllocation: [String: Double] = [:],
        lifeReflection: String? = nil
    ) {
        self.birthDate = birthDate
        self.lifeReflection = lifeReflection
        self.lifeAreasAllocation = lifeAreasAllocation

        // Calculate estimated death date if not provided
        if let provided = estimatedDeathDate {
            self.estimatedDeathDate = provided
        } else {
            let daysToLive = Int(MN_LIFE_EXPECTANCY_YEARS * DAYS_PER_YEAR)
            self.estimatedDeathDate = birthDate.addingTimeInterval(Double(daysToLive) * 24 * 60 * 60)
        }
    }

    // MARK: - Life Calculations

    /// Calculate approximate weeks lived so far
    func weeksLived(fromDate: Date = Date()) -> Int {
        let days = Calendar.current.dateComponents([.day], from: birthDate, to: fromDate).day ?? 0
        return days / 7
    }

    /// Calculate approximate weeks remaining
    func weeksRemaining(fromDate: Date = Date()) -> Int {
        let days = Calendar.current.dateComponents([.day], from: fromDate, to: estimatedDeathDate).day ?? 0
        return max(0, days / 7)
    }

    /// What fraction of your expected life have you lived? (0.0 to 1.0)
    func percentageLived(fromDate: Date = Date()) -> Double {
        let totalDays = Calendar.current.dateComponents([.day], from: birthDate, to: estimatedDeathDate).day ?? 1
        let livedDays = Calendar.current.dateComponents([.day], from: birthDate, to: fromDate).day ?? 0
        return min(1.0, Double(livedDays) / Double(totalDays))
    }

    /// The classic "4,000 weeks" calculation
    func expectedTotalWeeks() -> Int {
        let totalDays = Calendar.current.dateComponents([.day], from: birthDate, to: estimatedDeathDate).day ?? 0
        return totalDays / 7
    }
}
