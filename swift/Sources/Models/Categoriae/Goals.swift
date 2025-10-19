// Goals.swift
// Domain entity representing objectives and targets
//
// Written by Claude Code on 2025-10-18
// Ported from Python implementation (python/categoriae/goals.py)
//
// This uses class-based inheritance to demonstrate Swift's object-oriented features
// Hierarchy: Goal → SmartGoal
//            Goal → Milestone

import Foundation

/// Base class for all goal types
///
/// Goals represent objectives with optional measurements and time bounds.
/// This is the most flexible form - all fields are optional.
///
/// Conforms to Persistable: id, friendlyName, detailedDescription, freeformNotes, logTime
class Goal: Persistable {
    // MARK: - Persistable Protocol Requirements

    var id: UUID
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date

    // MARK: - Goal-specific Properties

    /// Type identifier for polymorphic storage ("Goal", "SmartGoal", "Milestone")
    var goalType: String { return "Goal" }

    /// What unit to measure (e.g., "km", "hours", "pages")
    var measurementUnit: String?

    /// Target value to achieve
    var measurementTarget: Double?

    /// When the goal period starts
    var startDate: Date?

    /// When the goal should be achieved by
    var targetDate: Date?

    /// Why this goal matters (SMART: Relevant)
    var howGoalIsRelevant: String?

    /// How to achieve this goal (SMART: Actionable)
    var howGoalIsActionable: String?

    /// Expected duration in weeks (e.g., 10 for ten-week term)
    var expectedTermLength: Int?

    // MARK: - Initialization

    /// Create a new goal with required and optional fields
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - friendlyName: Short description of the goal
    ///   - detailedDescription: Optional elaboration
    ///   - freeformNotes: Optional freeform notes
    ///   - logTime: When goal was created (defaults to now)
    ///   - measurementUnit: Optional unit (e.g., "km")
    ///   - measurementTarget: Optional target value
    ///   - startDate: Optional goal start date
    ///   - targetDate: Optional goal completion date
    ///   - howGoalIsRelevant: Optional relevance statement
    ///   - howGoalIsActionable: Optional action plan
    ///   - expectedTermLength: Optional duration in weeks
    init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        measurementUnit: String? = nil,
        measurementTarget: Double? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        howGoalIsRelevant: String? = nil,
        howGoalIsActionable: String? = nil,
        expectedTermLength: Int? = nil
    ) {
        self.id = id
        self.friendlyName = friendlyName
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
    }

    // MARK: - Validation Methods

    /// Check if this goal has defined start and target dates
    func isTimeBound() -> Bool {
        return startDate != nil && targetDate != nil
    }

    /// Check if this goal has a measurement unit and target
    func isMeasurable() -> Bool {
        return measurementUnit != nil && measurementTarget != nil
    }

    /// General validation - can be overridden by subclasses
    func isValid() -> Bool {
        // Base Goal has no strict requirements
        // Just check that if we have a target, it's positive
        if let target = measurementTarget, target <= 0 {
            return false
        }

        // Check date ordering if both dates exist
        if let start = startDate, let end = targetDate, start >= end {
            return false
        }

        return true
    }
}

// MARK: - SmartGoal Subclass

/// SMART goal with strict validation and required fields
///
/// Enforces all SMART criteria:
/// - Specific: Clear description (via friendlyName)
/// - Measurable: Has unit and target value (required)
/// - Achievable: Target is positive, has action plan (required)
/// - Relevant: Has relevance statement (required)
/// - Time-bound: Has start and end dates (required)
///
/// Example: "Run 120km in 10 weeks starting Oct 10"
class SmartGoal: Goal {
    // MARK: - Override goalType

    override var goalType: String { return "SmartGoal" }

    // MARK: - Initialization with Validation

    /// Create a SMART goal with all required fields
    ///
    /// All SMART criteria fields are required parameters (non-optional in init)
    /// Throws fatalError if validation fails (design choice - could use throws instead)
    init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        measurementUnit: String,          // Required for SMART
        measurementTarget: Double,        // Required for SMART
        startDate: Date,                  // Required for SMART
        targetDate: Date,                 // Required for SMART
        howGoalIsRelevant: String,        // Required for SMART
        howGoalIsActionable: String,      // Required for SMART
        expectedTermLength: Int? = nil
    ) {
        // Call parent initializer with required fields
        super.init(
            id: id,
            friendlyName: friendlyName,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            logTime: logTime,
            measurementUnit: measurementUnit,
            measurementTarget: measurementTarget,
            startDate: startDate,
            targetDate: targetDate,
            howGoalIsRelevant: howGoalIsRelevant,
            howGoalIsActionable: howGoalIsActionable,
            expectedTermLength: expectedTermLength
        )

        // Validate SMART criteria after initialization
        validateSmartCriteria()
    }

    // MARK: - Validation

    private func validateSmartCriteria() {
        // Measurable: must have unit and positive target
        guard let unit = measurementUnit, !unit.isEmpty else {
            fatalError("SmartGoal requires measurementUnit (Measurable)")
        }

        guard let target = measurementTarget, target > 0 else {
            fatalError("SmartGoal requires positive measurementTarget (Measurable, Achievable)")
        }

        // Time-bound: must have valid date range
        guard let start = startDate, let end = targetDate else {
            fatalError("SmartGoal requires both startDate and targetDate (Time-bound)")
        }

        guard start < end else {
            fatalError("SmartGoal startDate must be before targetDate (Time-bound)")
        }

        // Relevant: must have relevance statement
        guard let relevant = howGoalIsRelevant, !relevant.isEmpty else {
            fatalError("SmartGoal requires howGoalIsRelevant (Relevant)")
        }

        // Achievable: must have action plan
        guard let actionable = howGoalIsActionable, !actionable.isEmpty else {
            fatalError("SmartGoal requires howGoalIsActionable (Achievable)")
        }
    }

    override func isValid() -> Bool {
        // SmartGoal is valid if it passes all SMART criteria
        // Since we validate in init, a SmartGoal is always valid if it exists
        return super.isValid() // Also check parent's basic rules
    }
}

// MARK: - Milestone Subclass

/// A significant checkpoint within a larger goal
///
/// Milestones are point-in-time targets, not ranges.
/// They require a target date but not a start date.
///
/// Example: "Reach 50km by week 5"
class Milestone: Goal {
    // MARK: - Override goalType

    override var goalType: String { return "Milestone" }

    // MARK: - Initialization with Validation

    /// Create a milestone with required target date
    ///
    /// Milestones don't have start dates (they're point-in-time)
    init(
        id: UUID = UUID(),
        friendlyName: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        logTime: Date = Date(),
        measurementUnit: String? = nil,
        measurementTarget: Double? = nil,
        targetDate: Date,                 // Required for Milestone
        howGoalIsRelevant: String? = nil,
        howGoalIsActionable: String? = nil,
        expectedTermLength: Int? = nil
    ) {
        // Call parent initializer
        super.init(
            id: id,
            friendlyName: friendlyName,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            logTime: logTime,
            measurementUnit: measurementUnit,
            measurementTarget: measurementTarget,
            startDate: nil,  // Milestones don't have start dates
            targetDate: targetDate,
            howGoalIsRelevant: howGoalIsRelevant,
            howGoalIsActionable: howGoalIsActionable,
            expectedTermLength: expectedTermLength
        )
    }

    override func isValid() -> Bool {
        // Milestone must have a target date
        guard targetDate != nil else {
            return false
        }

        // And must NOT have a start date (point-in-time, not range)
        guard startDate == nil else {
            return false
        }

        return super.isValid()
    }
}
