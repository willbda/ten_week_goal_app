// Values.swift
// Domain entities for personal values and life areas
//
// Written by Claude Code on 2025-10-18
// Updated by Claude Code on 2025-10-19 (converted classes to structs for Sendable)
// Ported from Python implementation (python/categoriae/values.py)
//
// Values reflect a personal, intentional sense of how one's life should go.
// They provide context for evaluating alignment between actions and what matters.

import Foundation

// MARK: - PriorityLevel Value Type

/// Priority level for values (1-100, lower is higher priority)
public struct PriorityLevel: Codable, Equatable, Sendable {
    public let value: Int

    public init(_ value: Int) throws {
        guard (1...100).contains(value) else {
            throw ValidationError.invalidValue(
                field: "priority",
                value: String(value),
                reason: "Priority must be between 1 and 100"
            )
        }
        self.value = value
    }
}

// MARK: - Incentives Base Struct

///† Base struct for all value-related entities
///
/// Incentives represent motivations and priorities that guide decision-making.
/// This includes Values (what you believe is worthwhile), LifeAreas (domains
/// that structure your life), and various value hierarchies.
public struct Incentives: Persistable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Motivating)

    /// Priority level (1 = highest, 100 = lowest)
    public var priority: Int

    /// Life domain this incentive relates to (e.g., "Health", "Relationships")
    public var lifeDomain: String?

    // MARK: - Polymorphic Type (Polymorphable)

    /// Type identifier for polymorphic storage
    public var polymorphicSubtype: String { return "incentive" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                    // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "log_time"
        case priority
        case lifeDomain = "life_domain"
        // polymorphicSubtype is computed, returns type string
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Domain-specific
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
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}

// MARK: - Values Struct

/// Personal values that align with beliefs about what is worthwhile
///
/// Values are general incentives - things you affirm as important without
/// necessarily tracking them daily. Example: "Creativity", "Integrity"
public struct Values: Persistable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Motivating)

    public var priority: Int
    public var lifeDomain: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "general" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                    // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "log_time"
        case priority
        case lifeDomain = "life_domain"
        // polymorphicSubtype is computed, returns type string
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Domain-specific
        priority: Int = 40,  // Values default to 40
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
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}

// MARK: - LifeAreas Struct

/// Domains of life that provide structure and motivation
///
/// LifeAreas help explain why certain goals matter without implying you
/// value them. Example: "Career" might be a persistent life area that guides
/// decisions, but you may not explicitly "value" it in the same way you
/// value "Companionship".
///
/// Importantly, LifeAreas are NOT values.
public struct LifeAreas: Persistable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Motivating)

    public var priority: Int
    public var lifeDomain: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "life_area" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                    // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "log_time"
        case priority
        case lifeDomain = "life_domain"
        // polymorphicSubtype is computed, returns type string
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Domain-specific
        priority: Int = 40,
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
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}

// MARK: - MajorValues Struct

/// Actionable values that should regularly appear in actions and goals
///
/// MajorValues are a middle ground between Values and HighestOrderValues.
/// They're actionable enough that you should notice if they're NOT showing
/// up in your tracked actions and goals - a sign of misalignment or drift.
///
/// Example: "Physical health and vitality" is major enough that if you're
/// not seeing health-related actions, something is off.
public struct MajorValues: Persistable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Motivating)

    public var priority: Int
    public var lifeDomain: String?

    /// How this value shows up in actions/goals (flexible format for now)
    public var alignmentGuidance: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "major" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                    // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "log_time"
        case priority
        case lifeDomain = "life_domain"
        case alignmentGuidance = "alignment_guidance"
        // polymorphicSubtype is computed, returns type string
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Domain-specific
        priority: Int = 10,  // Major values are high priority
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil,
        // System-generated
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.priority = priority
        self.lifeDomain = lifeDomain
        self.alignmentGuidance = alignmentGuidance
    }
}

// MARK: - HighestOrderValues Struct

/// Abstract, philosophical values at the highest level
///
/// These are high-level concepts that aren't actionable on a daily or
/// monthly basis. They might appear in dashboard personalization or help
/// with goal-setting, but aren't meant for regular tracking.
///
/// Example: "Eudaimonia", "Truth", "Beauty" - aspirational ideals rather
/// than concrete practices.
public struct HighestOrderValues: Persistable, Polymorphable, Motivating, Codable, Sendable {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Domain-specific Properties (Motivating)

    public var priority: Int
    public var lifeDomain: String?

    // MARK: - Polymorphic Type (Polymorphable)

    public var polymorphicSubtype: String { return "highest_order" }

    // MARK: - Codable Mapping

    /// Maps Swift property names to database column names
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                    // UUID column (Swift-native)
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case logTime = "log_time"
        case priority
        case lifeDomain = "life_domain"
        // polymorphicSubtype is computed, returns type string
    }

    // MARK: - Initialization

    public init(
        // Core identity
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        // Domain-specific
        priority: Int = 1,  // Ultimate priority
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
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}
