//
// TermFormData.swift
// Form state for Term creation/editing (not persisted)
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Temporary struct holding form state for term input.
// Includes validation logic but no database operations.
// This is UI state only - converts to GoalTerm when ready to persist.

import Foundation
import Models

/// Form state for term input (not a database entity)
///
/// Holds user input and validates it before conversion to GoalTerm + TimePeriod.
///
/// **Usage**:
/// ```swift
/// @State private var formData = TermFormData()
///
/// // User edits...
/// formData.termNumber = 5
/// formData.theme = "Health focus"
///
/// // Validation
/// if formData.isValid {
///     let (timePeriod, goalTerm) = formData.createEntities()
///     // Save to database
/// }
/// ```
public struct TermFormData {

    // MARK: - Properties

    /// Sequential term number (1, 2, 3...)
    public var termNumber: Int = 1

    /// Optional focus theme for this term
    /// Example: "Health and relationships", "Career growth"
    public var theme: String = ""

    /// Current status of the term
    public var status: TermStatus = .planned

    /// When this term begins
    public var startDate: Date = Date()

    /// When this term ends (default: 10 weeks from start)
    public var endDate: Date = Date.daysFromNow(70)

    /// Optional reflection (usually written after completion)
    public var reflection: String = ""

    // MARK: - Validation

    /// Whether the current form data is valid
    public var isValid: Bool {
        termNumber > 0 &&
        endDate > startDate &&
        theme.count <= 100
    }

    /// List of current validation errors
    public var errors: [String] {
        var errs: [String] = []

        if termNumber <= 0 {
            errs.append("Term number must be positive")
        }

        if endDate <= startDate {
            errs.append("End date must be after start date")
        }

        if theme.count > 100 {
            errs.append("Theme exceeds 100 characters")
        }

        return errs
    }

    // MARK: - Entity Creation

    /// Creates TimePeriod and GoalTerm entities from form data
    ///
    /// Call this when ready to persist validated data.
    ///
    /// - Returns: Tuple of (TimePeriod, GoalTerm) ready to insert into database
    ///
    /// **Note**: This will be used when adding database persistence.
    /// For now (UI-only phase), this method isn't called.
    public func createEntities() -> (TimePeriod, GoalTerm) {
        let timePeriod = TimePeriod(
            title: "Term \(termNumber) Period",
            detailedDescription: theme.isEmpty ? nil : theme,
            startDate: startDate,
            endDate: endDate
        )

        let goalTerm = GoalTerm(
            timePeriodId: timePeriod.id,
            termNumber: termNumber,
            theme: theme.isEmpty ? nil : theme,
            reflection: reflection.isEmpty ? nil : reflection,
            status: status
        )

        return (timePeriod, goalTerm)
    }
}
