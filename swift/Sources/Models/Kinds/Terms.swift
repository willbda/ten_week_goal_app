// Terms.swift
// Time horizons for planning and reflection
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (fixed protocols, moved methods to extensions)
// Ported from Python implementation (python/categoriae/terms.py)
//
// Inspired by "4,000 Weeks" thinking - how do we structure finite time?
// Terms provide temporal scaffolding for goals and rhythmic reflection points.

import Foundation
import SQLiteData

// MARK: - Constants

public let MN_LIFE_EXPECTANCY_YEARS = 79.0
public let DAYS_PER_YEAR = 365.25

// MARK: - GoalTerm Struct

/// A fundamental unit of structured planning
///
/// Inspired by academic terms but adapted for personal productivity.
/// A term should be long enough to make meaningful progress, but short
/// enough to maintain focus and urgency.
///
/// Default: 10 weeks (70 days)
///
/// Business logic methods (isActive, daysRemaining, progressPercentage)
/// are provided via extensions in ModelExtensions.swift
@Table
public struct GoalTerm: Persistable, Sendable {
    // MARK: - Constants

    public static let TEN_WEEKS_IN_DAYS = 70

    // MARK: - Core Identity

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties

    public var termNumber: Int
    public var startDate: Date
    public var targetDate: Date
    public var theme: String?
    public var reflection: String?

    // MARK: - Polymorphic Type

    public var polymorphicSubtype: String = "goal_term"

    // MARK: - Initialization

    public init(
        title: String? = nil,
        detailedDescription: String? = "A focused 10-week period for achieving specific goals",
        freeformNotes: String? = nil,
        termNumber: Int = 0,
        startDate: Date = Date(),
        targetDate: Date,
        theme: String? = nil,
        reflection: String? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.termNumber = termNumber
        self.startDate = startDate
        self.targetDate = targetDate
        self.theme = theme
        self.reflection = reflection
    }
}

// MARK: - LifeTime Struct (Memento Mori)

/// The full arc of a human life - roughly 4,000-4,500 weeks
///
/// Memento Mori as data structure - a reminder that:
/// - Time is finite and precious
/// - How we spend weeks reveals what we truly value
/// - Planning matters because we're mortal
///
/// "I will be dead here shortly. Realistically, maybe that's another 30 to 70 years."
///
/// Business logic methods (weeksLived, weeksRemaining) provided via extensions
@Table
public struct LifeTime: Persistable, Sendable {
    // MARK: - Core Identity

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties

    public var birthDate: Date
    public var estimatedDeathDate: Date?

    // MARK: - Polymorphic Type

    public var polymorphicSubtype: String = "lifetime"

    // MARK: - Initialization

    public init(
        title: String? = nil,
        detailedDescription: String? = "The arc of a human life - memento mori",
        freeformNotes: String? = nil,
        birthDate: Date,
        estimatedDeathDate: Date? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.birthDate = birthDate
        self.estimatedDeathDate = estimatedDeathDate
    }
}

