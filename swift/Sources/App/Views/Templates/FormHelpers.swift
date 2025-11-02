//
// FormHelpers.swift
// Shared utilities for form views
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Common validation utilities, date helpers, and formatters
// used across all entity form views (Terms, Goals, Actions, Values).

import Foundation

// MARK: - Date Extensions

extension Date {
    /// Creates a date N days from today
    ///
    /// - Parameter days: Number of days to add (can be negative for past dates)
    /// - Returns: Date offset by specified days
    ///
    /// **Example**:
    /// ```swift
    /// let tenWeeksLater = Date.daysFromNow(70)  // 70 days = ~10 weeks
    /// let yesterday = Date.daysFromNow(-1)
    /// ```
    public static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    /// Human-readable duration between two dates
    ///
    /// - Parameter endDate: The end date of the duration
    /// - Returns: String like "10 weeks, 2 days" or "3 days"
    ///
    /// **Example**:
    /// ```swift
    /// let start = Date()
    /// let end = Date.daysFromNow(72)
    /// print(start.durationString(to: end))  // "10 weeks, 2 days"
    /// ```
    public func durationString(to endDate: Date) -> String {
        let components = Calendar.current.dateComponents(
            [.weekOfYear, .day],
            from: self,
            to: endDate
        )

        let weeks = components.weekOfYear ?? 0
        let days = components.day ?? 0

        if weeks > 0 && days > 0 {
            return "\(weeks) week\(weeks == 1 ? "" : "s"), \(days) day\(days == 1 ? "" : "s")"
        } else if weeks > 0 {
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Checks if string has valid non-empty content (not just whitespace)
    ///
    /// **Example**:
    /// ```swift
    /// "  ".isValidNonEmpty        // false
    /// "  Hello  ".isValidNonEmpty // true
    /// "".isValidNonEmpty          // false
    /// ```
    public var isValidNonEmpty: Bool {
        !self.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Validates string length is within specified range
    ///
    /// - Parameter range: Allowed character count range
    /// - Returns: True if trimmed string length is in range
    ///
    /// **Example**:
    /// ```swift
    /// "Theme".isValid(length: 1...100)  // true
    /// "".isValid(length: 1...100)        // false
    /// ```
    public func isValid(length range: ClosedRange<Int>) -> Bool {
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        return range.contains(trimmed.count)
    }
}

// MARK: - Validation Helpers

/// Common validation result type
///
/// **Usage**:
/// ```swift
/// func validateTermNumber(_ num: Int) -> ValidationResult {
///     num > 0 ? .valid : .invalid("Term number must be positive")
/// }
/// ```
public enum ValidationResult {
    case valid
    case invalid(String)

    public var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    public var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}
