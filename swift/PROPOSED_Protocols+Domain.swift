// Protocols+Domain.swift
// Domain extensions for protocol helpers and computed properties
//
// Written by Claude Code on 2025-10-19
//
// This file contains protocol extensions that reduce boilerplate by providing:
// - Validation helper methods (shared across conforming types)
// - Computed properties derived from stored properties
// - Default implementations that can be overridden
//
// TO USE: Add this file to Sources/Models/ directory

import Foundation

// MARK: - Performable Extensions (Past-Oriented Actions)

extension Performable {
    /// Validate that all measurements are positive
    ///
    /// Returns false if any measurement value is <= 0
    /// Returns true if no measurements exist
    public func hasValidMeasurements() -> Bool {
        guard let measurements = measuresByUnit else { return true }

        for (_, value) in measurements {
            if value <= 0 { return false }
        }

        return true
    }

    /// Validate timing consistency
    ///
    /// Rule: If startTime exists, duration should also exist
    public func hasValidTiming() -> Bool {
        if startTime != nil && durationMinutes == nil {
            return false
        }

        return true
    }

    /// Does this action have complete timing information?
    public var hasTiming: Bool {
        startTime != nil && durationMinutes != nil
    }

    /// When did this action end? (calculated from startTime + duration)
    public var endTime: Date? {
        guard let start = startTime, let duration = durationMinutes else { return nil }
        return Calendar.current.date(byAdding: .minute, value: Int(duration), to: start)
    }

    /// Total of all measurements (sum across all units)
    public var totalMeasured: Double {
        measuresByUnit?.values.reduce(0, +) ?? 0
    }

    /// Does this action have any recorded measurements?
    public var hasMeasurements: Bool {
        guard let measurements = measuresByUnit else { return false }
        return !measurements.isEmpty && !measurements.values.allSatisfy { $0 == 0 }
    }

    /// Number of different measurement units recorded
    public var measurementCount: Int {
        measuresByUnit?.count ?? 0
    }
}

// MARK: - Completable Extensions (Future-Oriented Goals)

extension Completable {
    /// Validate measurement target is positive and has a unit
    ///
    /// Returns false if:
    /// - Target exists but is <= 0
    /// - Target exists but unit is missing
    public func hasValidMeasurement() -> Bool {
        // If target exists, it must be positive
        if let target = measurementTarget, target <= 0 {
            return false
        }

        // If target exists, unit must also exist
        if measurementTarget != nil && (measurementUnit == nil || measurementUnit?.isEmpty == true) {
            return false
        }

        return true
    }

    /// Validate date range is logically consistent
    ///
    /// Returns false if start date is >= target date
    public func hasValidDateRange() -> Bool {
        // If both dates exist, start must be before end
        if let start = startTime, let end = targetDate, start >= end {
            return false
        }

        return true
    }

    /// Does this goal have a concrete measurement target?
    public var hasMeasurableTarget: Bool {
        measurementUnit != nil && measurementTarget != nil && measurementTarget! > 0
    }

    /// Does this goal have both start and target dates?
    public var hasDefinedTimeframe: Bool {
        startTime != nil && targetDate != nil
    }

    /// Is this goal time-bounded (has a target date)?
    public var isTimeBounded: Bool {
        targetDate != nil
    }

    /// Days until target date (nil if no target)
    ///
    /// Returns negative value if target is in the past
    public var daysUntilTarget: Int? {
        guard let target = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: target).day
    }

    /// Is the target date in the past?
    public var isPastDue: Bool {
        guard let target = targetDate else { return false }
        return target < Date()
    }

    /// Duration of the goal in days (start to target)
    public var durationInDays: Int? {
        guard let start = startTime, let end = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    /// Percentage of time elapsed (0-100)
    ///
    /// Returns nil if goal doesn't have a defined timeframe
    /// Returns > 100 if past the target date
    public var timeElapsedPercent: Double? {
        guard let start = startTime,
              let end = targetDate else {
            return nil
        }

        let totalDuration = end.timeIntervalSince(start)
        let elapsed = Date().timeIntervalSince(start)

        return min(100.0, (elapsed / totalDuration) * 100.0)
    }
}

// MARK: - Persistable Extensions (Identity & Lifecycle)

extension Persistable {
    /// Was this entity created recently (within last N days)?
    public func isRecent(withinDays days: Int) -> Bool {
        let daysSinceCreation = Calendar.current.dateComponents(
            [.day],
            from: logTime,
            to: Date()
        ).day ?? Int.max

        return daysSinceCreation <= days
    }

    /// How many days ago was this entity created?
    public var daysOld: Int {
        Calendar.current.dateComponents([.day], from: logTime, to: Date()).day ?? 0
    }

    /// Formatted creation time for display (e.g., "Oct 19, 2025 at 3:45 PM")
    public var formattedLogTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: logTime)
    }

    /// Short formatted creation time (e.g., "Oct 19")
    public var shortFormattedLogTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: logTime)
    }
}

// MARK: - Motivating Extensions (Values & Priorities)

extension Motivating {
    /// Is this a high-priority item? (priority >= 70)
    public var isHighPriority: Bool {
        priority >= 70
    }

    /// Is this a medium-priority item? (40 <= priority < 70)
    public var isMediumPriority: Bool {
        priority >= 40 && priority < 70
    }

    /// Is this a low-priority item? (priority < 40)
    public var isLowPriority: Bool {
        priority < 40
    }

    /// Priority category as a string
    public var priorityCategory: String {
        switch priority {
        case 80...: return "Critical"
        case 60..<80: return "High"
        case 40..<60: return "Medium"
        case 20..<40: return "Low"
        default: return "Minimal"
        }
    }
}

// MARK: - Conditional Extensions (Combinations)

/// Extensions for entities that are both Persistable and Completable
extension Persistable where Self: Completable {
    /// Is this goal forward-looking? (target date is after creation)
    public var isForwardLooking: Bool {
        guard let target = targetDate else { return false }
        return target > logTime
    }

    /// Time from creation to target (in days)
    public var plannedDuration: Int? {
        guard let target = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: logTime, to: target).day
    }
}

/// Extensions for entities that are both Persistable and Motivating
extension Persistable where Self: Motivating {
    /// Has this value been defined recently and is high priority?
    public var isNewAndImportant: Bool {
        isRecent(withinDays: 30) && isHighPriority
    }
}

// MARK: - Design Notes

/*
 WHAT BELONGS HERE:

 ✅ Validation helpers (hasValidMeasurement, hasValidDateRange)
    - Reduces duplication across conforming types
    - Testable in isolation

 ✅ Computed properties (hasMeasurableTarget, daysUntilTarget)
    - Derived from stored properties
    - No side effects

 ✅ Formatting helpers (formattedLogTime)
    - Presentation logic that's universal

 ✅ Category checks (isHighPriority)
    - Simple boolean queries about state

 WHAT DOESN'T BELONG HERE:

 ❌ Business logic requiring other entities
    - calculateProgress(from actions:) → Goes in Ethica layer
    - matchingActions(from:) → Goes in Ethica layer

 ❌ Stored properties or default values
    - var id: UUID = UUID() → Must be in type definition
    - Extensions can't add storage

 ❌ Database operations
    - save(), update(), delete() → Goes in Politica layer

 USAGE IN YOUR TYPES:

 struct Action: Persistable, Performable {
     // ... property definitions ...

     func isValid() -> Bool {
         // Use extension methods!
         return hasValidMeasurements() && hasValidTiming()
     }
 }

 struct Goal: Persistable, Completable {
     // ... property definitions ...

     func isValid() -> Bool {
         // Use extension methods!
         return hasValidMeasurement() && hasValidDateRange()
     }
 }

 TESTING:

 func testActionValidation() {
     var action = Action()
     action.measuresByUnit = ["km": -5]  // Invalid!

     XCTAssertFalse(action.hasValidMeasurements())
     XCTAssertFalse(action.isValid())
 }

 func testGoalComputedProperties() {
     var goal = Goal()
     goal.targetDate = Date().addingTimeInterval(10 * 24 * 60 * 60)

     XCTAssertEqual(goal.daysUntilTarget, 10)
     XCTAssertFalse(goal.isPastDue)
 }
 */
