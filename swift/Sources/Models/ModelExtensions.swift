//  ModelExtensions.swift
//  Validation and utility extensions for domain models
//
//  Created by David Williams on 10/19/25.
//  Updated by Claude Code on 10/19/25
//

import Foundation

// MARK: - Validatable + Doable Helpers

/// Validation helpers for entities that are both Validatable and Doable (Actions)
extension Validatable where Self: Doable {
    /// Check if all measurements are positive
    ///
    /// Returns true if no measurements exist or all values > 0
    public func hasValidMeasurements() -> Bool {
        guard let measurements = measuresByUnit else { return true }
        return measurements.values.allSatisfy { $0 > 0 }
    }

    /// Check if timing is consistent
    ///
    /// Rule: startTime requires durationMinutes
    /// Returns true if startTime is nil, or if both startTime and duration exist
    public func hasValidTiming() -> Bool {
        startTime == nil || durationMinutes != nil
    }

    /// Does this have any measurements?
    public var hasMeasurements: Bool {
        guard let measurements = measuresByUnit else { return false }
        return !measurements.isEmpty
    }
}

// MARK: - Validatable + Completable Helpers

/// Validation helpers for entities that are both Validatable and Completable (Goals)
extension Validatable where Self: Completable {
    /// Check if measurement target is valid
    ///
    /// Returns false if:
    /// - Target exists but is <= 0
    /// - Target exists but unit is missing/empty
    public func hasValidMeasurement() -> Bool {
        // If target exists, it must be positive
        if let target = measurementTarget {
            guard target > 0 else { return false }
            guard let unit = measurementUnit, !unit.isEmpty else { return false }
            return true
        }
        return true
    }

    /// Check if date range is valid
    ///
    /// Returns false if start date >= target date
    /// Returns true if either date is missing (partial goals allowed)
    public func hasValidDateRange() -> Bool {
        guard let start = startDate, let end = targetDate else { return true }
        return start < end
    }

    /// Does this goal have a measurable target?
    public var hasMeasurableTarget: Bool {
        guard let target = measurementTarget else { return false }
        guard let unit = measurementUnit, !unit.isEmpty else { return false }
        return target > 0
    }
}

// MARK: - Validatable Default Implementation

extension Validatable {
    /// Default throwing validation based on isValid()
    ///
    /// Subclasses should override this to provide detailed error messages
    /// This default just throws a generic validation error
    public func validate() throws {
        guard isValid() else {
            throw ValidationError.invalidValue(
                field: "entity",
                value: String(describing: Self.self),
                reason: "Validation failed"
            )
        }
    }
}

// MARK: - Action Validation

extension Action: Validatable {
    /// Validates the action's internal consistency
    /// Uses helper methods from Validatable + Doable extension
    ///
    /// Validation rules:
    /// - All measurement values must be positive (hasValidMeasurements)
    /// - If startTime exists, durationMinutes should too (hasValidTiming)
    public func isValid() -> Bool {
        hasValidMeasurements() && hasValidTiming()
    }

    /// Validate action constraints (throwing version)
    ///
    /// Throws ValidationError if:
    /// - Any measurement value is negative or zero
    /// - startTime is provided without durationMinutes
    public func validate() throws {
        // Check measurement values are positive
        if let measurements = measuresByUnit {
            for (unit, value) in measurements {
                if value <= 0 {
                    throw ValidationError.invalidValue(
                        field: "measurement[\(unit)]",
                        value: String(value),
                        reason: "Measurements must be positive"
                    )
                }
            }
        }

        // If start_time exists, duration should too
        if startTime != nil && durationMinutes == nil {
            throw ValidationError.missingRequiredField(
                field: "durationMinutes",
                context: "durationMinutes is required when startTime is provided"
            )
        }
    }
}

// MARK: - Goal Validation

extension Goal: Validatable {
    /// Validates the goal's internal consistency
    /// Uses helper methods from Validatable + Completable extension
    ///
    /// Validation rules:
    /// - Measurement target must be positive (hasValidMeasurement)
    /// - Start date must be before target date (hasValidDateRange)
    public func isValid() -> Bool {
        hasValidMeasurement() && hasValidDateRange()
    }

    /// Check if this goal meets all SMART criteria
    /// - Returns: true if goal has all required SMART fields
    ///
    /// SMART criteria:
    /// - Specific: Has title or detailedDescription
    /// - Measurable: Has measurementUnit and measurementTarget
    /// - Achievable: Has howGoalIsActionable
    /// - Relevant: Has howGoalIsRelevant
    /// - Time-bound: Has startDate and targetDate
    public func isSmart() -> Bool {
        return measurementUnit != nil &&
               measurementTarget != nil &&
               startDate != nil &&
               targetDate != nil &&
               howGoalIsRelevant != nil &&
               howGoalIsActionable != nil &&
               isValid()  // Also must pass basic validation
    }

    /// Check if this goal has defined start and target dates
    public func isTimeBound() -> Bool {
        return startDate != nil && targetDate != nil
    }

    /// Check if this goal has a measurement unit and target
    public func isMeasurable() -> Bool {
        return measurementUnit != nil && measurementTarget != nil
    }
}

// MARK: - Milestone Validation

extension Milestone: Validatable {
    /// Validates the milestone's internal consistency
    /// Uses helper methods from Validatable + Completable extension
    ///
    /// Validation rules:
    /// - Target date should be present (milestones are point-in-time)
    /// - Measurement target must be positive (hasValidMeasurement)
    /// - Start date must be before target date (hasValidDateRange)
    public func isValid() -> Bool {
        // Target date is strongly recommended for milestones
        guard targetDate != nil else {
            return false
        }

        // Use helpers for other validation
        return hasValidMeasurement() && hasValidDateRange()
    }
}

// MARK: - GoalTerm Validation and Business Logic

extension GoalTerm: Validatable {
    /// Validates the term's internal consistency
    /// - Returns: true if the term is structurally valid
    ///
    /// Validation rules:
    /// - Start date must be before target date
    /// - Term number should be >= 0
    public func isValid() -> Bool {
        // Check date ordering
        guard startDate < targetDate else {
            return false
        }

        // Term number should be non-negative
        guard termNumber >= 0 else {
            return false
        }

        return true
    }

    /// Check if term is currently active
    /// - Parameter checkDate: The date to check against (defaults to now)
    /// - Returns: true if checkDate falls within term's date range
    public func isActive(checkDate: Date = Date()) -> Bool {
        return startDate <= checkDate && checkDate <= targetDate
    }

    /// Calculate days remaining in term
    /// - Parameter fromDate: The date to calculate from (defaults to now)
    /// - Returns: Number of days until targetDate, or 0 if already past
    public func daysRemaining(fromDate: Date = Date()) -> Int {
        guard fromDate <= targetDate else { return 0 }
        let components = Calendar.current.dateComponents([.day], from: fromDate, to: targetDate)
        return max(0, components.day ?? 0)
    }

    /// Calculate percentage of term completed
    /// - Parameter fromDate: The date to calculate from (defaults to now)
    /// - Returns: Progress from 0.0 (not started) to 1.0 (complete)
    public func progressPercentage(fromDate: Date = Date()) -> Double {
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        let elapsedDays = Calendar.current.dateComponents([.day], from: startDate, to: fromDate).day ?? 0

        if elapsedDays < 0 { return 0.0 }
        if elapsedDays > totalDays { return 1.0 }
        return Double(elapsedDays) / Double(totalDays)
    }
}

// MARK: - LifeTime Business Logic

extension LifeTime {
    /// Calculate weeks lived since birth
    /// - Parameter currentDate: The date to calculate from (defaults to now)
    /// - Returns: Number of weeks lived
    public func weeksLived(currentDate: Date = Date()) -> Int {
        let components = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: currentDate)
        return max(0, components.weekOfYear ?? 0)
    }

    /// Calculate estimated weeks remaining
    /// - Parameter currentDate: The date to calculate from (defaults to now)
    /// - Returns: Estimated weeks remaining, or nil if no death date estimate
    public func weeksRemaining(currentDate: Date = Date()) -> Int? {
        guard let deathDate = estimatedDeathDate else { return nil }
        guard currentDate <= deathDate else { return 0 }

        let components = Calendar.current.dateComponents([.weekOfYear], from: currentDate, to: deathDate)
        return max(0, components.weekOfYear ?? 0)
    }
}
