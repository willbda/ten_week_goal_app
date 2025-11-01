//  ModelExtensions.swift
//  Utility extensions for domain models
//
//  Created by David Williams on 10/19/25.
//  Updated by Claude Code on 10/27/25
//  Note: Validation removed per design in Protocols.swift (moved to service layer)
//

import Foundation

// MARK: - GoalTerm Business Logic

extension GoalTerm {
    public func isActive(checkDate: Date = Date()) -> Bool {
        return startDate <= checkDate && checkDate <= targetDate
    }

    public func daysRemaining(fromDate: Date = Date()) -> Int {
        guard fromDate <= targetDate else { return 0 }
        let components = Calendar.current.dateComponents([.day], from: fromDate, to: targetDate)
        return max(0, components.day ?? 0)
    }

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
    public func weeksLived(currentDate: Date = Date()) -> Int {
        let components = Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: currentDate)
        return max(0, components.weekOfYear ?? 0)
    }

    public func weeksRemaining(currentDate: Date = Date()) -> Int? {
        guard let deathDate = estimatedDeathDate else { return nil }
        guard currentDate <= deathDate else { return 0 }

        let components = Calendar.current.dateComponents([.weekOfYear], from: currentDate, to: deathDate)
        return max(0, components.weekOfYear ?? 0)
    }
}

// MARK: - Goal Helper Methods REMOVED
//
// Per Phase 3 Architecture (2025-10-30): Business logic belongs in Services/Repositories
//
// The following Goal extension methods were removed during 3NF normalization:
// - isSmart(): Now in GoalValidation service (requires metrics parameter)
// - isTimeBound(): Now in GoalValidation service
// - isMeasurable(): Requires GoalMetric junction table query
//
// Use GoalValidation.classify(goal, metrics:) for classification logic
//
// This avoids duplicate sources of truth and ensures business logic
// that requires database queries stays in the service layer.
