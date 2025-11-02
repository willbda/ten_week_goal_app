//
// ActionFormData.swift
// Form state for Action creation/editing (not persisted)
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Temporary struct holding form state for action input.
// Includes validation logic but no database operations.
// This is UI state only - will convert to Action + MeasuredAction when persistence added.

import Foundation
import Models

/// Form state for action input (not a database entity)
///
/// Holds user input and validates it before eventual persistence.
/// Follows the exact pattern from TermFormData.
///
/// **Usage**:
/// ```swift
/// @State private var formData = ActionFormData()
///
/// // User edits...
/// formData.title = "Morning run"
/// formData.measurements.append(MeasurementInput(measureId: Measure.kilometers.id, value: 5.2))
///
/// // Validation
/// if formData.isValid {
///     // Later: create Action + MeasuredAction entities and save
///     print("Valid action: \(formData.title)")
/// }
/// ```
public struct ActionFormData {

    // MARK: - Properties

    /// Required: The name of the action
    /// Example: "Morning run", "Team meeting", "Guitar practice"
    public var title: String = ""

    /// Optional: Detailed description of what was done
    /// Example: "5K route through the park, felt strong"
    public var detailedDescription: String = ""

    /// Optional: Free-form notes
    /// Example: "Weather was perfect, saw three deer"
    public var freeformNotes: String = ""

    /// Optional: How long the action took (in minutes)
    /// Example: 28.0 for 28 minutes
    public var durationMinutes: Double = 0

    /// When this action occurred
    /// Defaults to now, but can be changed for retroactive logging
    public var startTime: Date = Date()

    /// Measurements associated with this action
    /// Example: [MeasurementInput(measureId: km.id, value: 5.2)]
    public var measurements: [MeasurementInput] = []

    /// Optional: Goal contributions (future feature)
    /// Currently unused - will query available goals when persistence is added
    public var goalContributions: Set<UUID> = []

    // MARK: - Validation

    /// Whether the current form data is valid
    public var isValid: Bool {
        !title.isEmpty &&
        title.count <= 200 &&
        (durationMinutes == 0 || durationMinutes > 0) &&
        measurements.allSatisfy { $0.isValid }
    }

    /// List of current validation errors
    public var errors: [String] {
        var errs: [String] = []

        if title.isEmpty {
            errs.append("Title is required")
        }

        if title.count > 200 {
            errs.append("Title must be 200 characters or less")
        }

        if durationMinutes < 0 {
            errs.append("Duration cannot be negative")
        }

        let invalidMeasurements = measurements.filter { !$0.isValid }
        if !invalidMeasurements.isEmpty {
            errs.append("\(invalidMeasurements.count) measurement(s) incomplete")
        }

        return errs
    }

    // MARK: - Initialization

    public init() {
        // Default initialization
    }

    // MARK: - Future: Entity Creation

    /// Creates Action + MeasuredAction entities from form data
    ///
    /// **Note**: Not implemented yet - UI-only phase.
    /// When persistence is added, this will create:
    /// - Action entity with core fields
    /// - MeasuredAction entities for each measurement
    ///
    /// - Returns: Tuple of (Action, [MeasuredAction]) ready to persist
    // public func createEntities() -> (Action, [MeasuredAction]) {
    //     // TODO: Implement when adding database persistence
    // }
}

// MARK: - MeasurementInput Helper

/// Temporary struct for measurement input in the form
///
/// Holds the measure selection and value before conversion to MeasuredAction.
///
/// **Usage**:
/// ```swift
/// var measurements: [MeasurementInput] = []
/// measurements.append(MeasurementInput(
///     measureId: Measure.kilometers.id,
///     value: 5.2
/// ))
/// ```
public struct MeasurementInput: Identifiable {
    public let id = UUID()
    public var measureId: UUID?  // FK to measures catalog
    public var value: Double = 0.0

    /// Whether this measurement is valid (has both measure and positive value)
    public var isValid: Bool {
        measureId != nil && value > 0
    }

    public init(measureId: UUID? = nil, value: Double = 0.0) {
        self.measureId = measureId
        self.value = value
    }
}
