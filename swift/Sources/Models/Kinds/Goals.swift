// Goals.swift
// Domain entity representing objectives and targets
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (consolidated Goal/SmartGoal, removed Doable properties)
// Ported from Python implementation (python/categoriae/goals.py)
//
// Goals are FUTURE-oriented entities (Completable), not PAST-oriented (Doable)
// Two types: Goal (flexible, can be minimal or SMART) and Milestone (point-in-time checkpoint)

import Foundation

// MARK: - Goal Struct

/// Flexible goal structure supporting both minimal and SMART goals
///
/// Goals represent objectives with optional measurements and time bounds.
/// A goal can evolve from minimal ("get healthier") to SMART-compliant
/// ("run 120km in 10 weeks starting Oct 10") by progressively filling in fields.
///
/// Use `isSmart()` validation method to check if goal meets all SMART criteria.
///
/// Conforms to:
/// - Persistable: id, title, detailedDescription, freeformNotes, logTime
/// - Completable: targetDate, measurementUnit, measurementTarget, startDate
/// - Polymorphable: polymorphicSubtype
/// - Motivating: priority, lifeDomain
public struct Goal: Persistable, Completable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Completable)

    /// What unit to measure (e.g., "km", "hours", "pages")
    /// Required for SMART goals, optional for minimal goals
    public var measurementUnit: String?

    /// Target value to achieve
    /// Required for SMART goals, optional for minimal goals
    public var measurementTarget: Double?

    /// When the goal period starts
    /// Required for SMART goals, optional for minimal goals
    public var startDate: Date?

    /// When the goal should be achieved by
    /// Required for SMART goals, optional for minimal goals
    public var targetDate: Date?

    // MARK: - SMART Enhancement Fields

    /// Why this goal matters (SMART: Relevant)
    /// Required for SMART compliance, optional otherwise
    public var howGoalIsRelevant: String?

    /// How to achieve this goal (SMART: Actionable)
    /// Required for SMART compliance, optional otherwise
    public var howGoalIsActionable: String?

    /// Expected duration in weeks (e.g., 10 for ten-week term)
    public var expectedTermLength: Int?

    // MARK: - Motivating Properties

    public var priority: Int
    public var lifeDomain: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "goal" }

    // MARK: - Initialization

    /// Create a new goal with flexible field requirements
    ///
    /// For minimal goals: Provide just title or detailedDescription
    /// For SMART goals: Provide all measurement, date, and SMART fields
    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Completable
        measurementUnit: String? = nil,
        measurementTarget: Double? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        // SMART fields
        howGoalIsRelevant: String? = nil,
        howGoalIsActionable: String? = nil,
        expectedTermLength: Int? = nil,
        // Motivating
        priority: Int = 50,
        lifeDomain: String? = nil,
        // System-generated
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.measurementUnit = measurementUnit
        self.measurementTarget = measurementTarget
        self.startDate = startDate
        self.targetDate = targetDate
        self.howGoalIsRelevant = howGoalIsRelevant
        self.howGoalIsActionable = howGoalIsActionable
        self.expectedTermLength = expectedTermLength
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}

// MARK: - Milestone Struct

/// A significant checkpoint within a larger goal
///
/// Milestones are point-in-time targets, not ranges.
/// They require a target date but not necessarily a start date.
///
/// Example: "Reach 50km by week 5"
public struct Milestone: Persistable, Completable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Completable)

    /// What unit to measure (e.g., "km", "pages")
    public var measurementUnit: String?

    /// Target value to achieve at this checkpoint
    public var measurementTarget: Double?

    /// Optional start date (milestones can be point-in-time)
    public var startDate: Date?

    /// When this milestone should be reached (typically REQUIRED)
    public var targetDate: Date?

    // MARK: - Motivating Properties

    public var priority: Int
    public var lifeDomain: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "milestone" }

    // MARK: - Initialization

    /// Create a milestone checkpoint
    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Completable
        measurementUnit: String? = nil,
        measurementTarget: Double? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        // Motivating
        priority: Int = 30,  // Milestones are moderate priority
        lifeDomain: String? = nil,
        // System-generated
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.measurementUnit = measurementUnit
        self.measurementTarget = measurementTarget
        self.startDate = startDate
        self.targetDate = targetDate
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}

