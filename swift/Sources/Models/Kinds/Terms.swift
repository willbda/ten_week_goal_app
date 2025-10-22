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
public struct GoalTerm: Persistable, Polymorphable, Codable, Sendable {
    // MARK: - Constants

    public static let TEN_WEEKS_IN_DAYS = 70 // 10 weeks × 7 days/week

    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties

    /// Sequential term number (1, 2, 3, etc.)
    public var termNumber: Int

    /// When this term begins
    public var startDate: Date

    /// When this term ends
    public var targetDate: Date

    /// Optional theme or focus for this term
    public var theme: String?

    /// UUIDs of goals associated with this term
    public var termGoalsByID: [UUID]

    /// Post-term reflection notes
    public var reflection: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "goal_term" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                    // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "created_at"            // Terms table uses created_at
        case termNumber = "term_number"
        case startDate = "start_date"
        case targetDate = "target_date"
        case theme
        case termGoalsByID = "term_goals_by_id"
        case reflection
        case polymorphicSubtype = "term_type"  // For future polymorphism
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = "A focused 10-week period for achieving specific goals",
        freeformNotes: String? = nil,
        // Domain-specific
        termNumber: Int = 0,
        startDate: Date = Date(),
        targetDate: Date,
        theme: String? = nil,
        termGoalsByID: [UUID] = [],
        reflection: String? = nil,
        // System-generated
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
        self.termGoalsByID = termGoalsByID
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
public struct LifeTime: Persistable, Polymorphable, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties

    /// Date of birth
    public var birthDate: Date

    /// Optional estimated death date (based on life expectancy or personal estimate)
    public var estimatedDeathDate: Date?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "lifetime" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                           // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "created_at"
        case birthDate = "birth_date"
        case estimatedDeathDate = "estimated_death_date"
        case polymorphicSubtype = "term_type"         // For future polymorphism
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = "The arc of a human life - memento mori",
        freeformNotes: String? = nil,
        // Domain-specific
        birthDate: Date,
        estimatedDeathDate: Date? = nil,
        // System-generated
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

