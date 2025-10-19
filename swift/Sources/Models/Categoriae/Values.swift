// Values.swift
// Domain entities for personal values and life areas
//
// Written by Claude Code on 2025-10-18
// Ported from Python implementation (python/categoriae/values.py)
//
// Values reflect a personal, intentional sense of how one's life should go.
// They provide context for evaluating alignment between actions and what matters.

import Foundation

// MARK: - PriorityLevel Value Type

/// Priority level for values (1-100, lower is higher priority)
struct PriorityLevel {
    let value: Int

    init(_ value: Int) {
        guard (1...100).contains(value) else {
            fatalError("PriorityLevel must be between 1 and 100, got \(value)")
        }
        self.value = value
    }
}

// MARK: - Incentives Base Class

/// Base class for all value-related entities
///
/// Incentives represent motivations and priorities that guide decision-making.
/// This includes Values (what you believe is worthwhile), LifeAreas (domains
/// that structure your life), and various value hierarchies.
class Incentives: Persistable {
    // MARK: - Persistable Protocol Requirements

    var id: UUID
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date

    // MARK: - Incentives-specific Properties

    /// Type identifier for polymorphic storage
    var incentiveType: String { return "incentive" }

    /// Priority level (1 = highest, 100 = lowest)
    var priority: PriorityLevel

    /// Life domain this incentive relates to (e.g., "Health", "Relationships")
    var lifeDomain: String

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        priority: PriorityLevel = PriorityLevel(50),
        lifeDomain: String = "General"
    ) {
        self.id = id
        self.friendlyName = friendlyName
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.priority = priority
        self.lifeDomain = lifeDomain
    }
}

// MARK: - Values Class

/// Personal values that align with beliefs about what is worthwhile
///
/// Values are general incentives - things you affirm as important without
/// necessarily tracking them daily. Example: "Creativity", "Integrity"
class Values: Incentives {
    override var incentiveType: String { return "general" }

    override init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        priority: PriorityLevel = PriorityLevel(40),  // Values default to 40
        lifeDomain: String = "General"
    ) {
        super.init(
            id: id,
            friendlyName: friendlyName,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            logTime: logTime,
            priority: priority,
            lifeDomain: lifeDomain
        )
    }
}

// MARK: - LifeAreas Class

/// Domains of life that provide structure and motivation
///
/// LifeAreas help explain why certain goals matter without implying you
/// value them. Example: "Career" might be a persistent life area that guides
/// decisions, but you may not explicitly "value" it in the same way you
/// value "Companionship".
///
/// Importantly, LifeAreas are NOT values.
class LifeAreas: Incentives {
    override var incentiveType: String { return "life_area" }

    override init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        priority: PriorityLevel = PriorityLevel(40),
        lifeDomain: String = "General"
    ) {
        super.init(
            id: id,
            friendlyName: friendlyName,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            logTime: logTime,
            priority: priority,
            lifeDomain: lifeDomain
        )
    }
}

// MARK: - MajorValues Class

/// Actionable values that should regularly appear in actions and goals
///
/// MajorValues are a middle ground between Values and HighestOrderValues.
/// They're actionable enough that you should notice if they're NOT showing
/// up in your tracked actions and goals - a sign of misalignment or drift.
///
/// Example: "Physical health and vitality" is major enough that if you're
/// not seeing health-related actions, something is off.
class MajorValues: Values {
    override var incentiveType: String { return "major" }

    /// How this value shows up in actions/goals (flexible format for now)
    var alignmentGuidance: String?

    init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        priority: PriorityLevel = PriorityLevel(10),  // Major values are high priority
        lifeDomain: String = "General",
        alignmentGuidance: String? = nil
    ) {
        self.alignmentGuidance = alignmentGuidance

        super.init(
            id: id,
            friendlyName: friendlyName,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            logTime: logTime,
            priority: priority,
            lifeDomain: lifeDomain
        )
    }
}

// MARK: - HighestOrderValues Class

/// Abstract, philosophical values at the highest level
///
/// These are high-level concepts that aren't actionable on a daily or
/// monthly basis. They might appear in dashboard personalization or help
/// with goal-setting, but aren't meant for regular tracking.
///
/// Example: "Eudaimonia", "Truth", "Beauty" - aspirational ideals rather
/// than concrete practices.
class HighestOrderValues: Values {
    override var incentiveType: String { return "highest_order" }

    override init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        priority: PriorityLevel = PriorityLevel(1),  // Ultimate priority
        lifeDomain: String = "General"
    ) {
        super.init(
            id: id,
            friendlyName: friendlyName,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            logTime: logTime,
            priority: priority,
            lifeDomain: lifeDomain
        )
    }
}
