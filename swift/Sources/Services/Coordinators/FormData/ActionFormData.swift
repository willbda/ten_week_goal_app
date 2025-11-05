//
// ActionFormData.swift
// Form state for Action creation/editing
//
// Written by Claude Code on 2025-11-01
// Updated by Claude Code on 2025-11-02 (moved to FormData/, made Sendable)
//
// PURPOSE:
// Input DTO for ActionCoordinator. Holds form state and validates before persistence.
// Follows ValueFormData and TimePeriodFormData patterns.

import Foundation
import Models

/// Form state for action input
///
/// Holds user input and validates it before coordinator persistence.
/// Sendable for safe passage across actor boundaries (ViewModel → Coordinator).
///
/// **Usage**:
/// ```swift
/// let formData = ActionFormData(
///     title: "Morning run",
///     durationMinutes: 28.0,
///     startTime: Date(),
///     measurements: [
///         MeasurementInput(measureId: kilometersId, value: 5.2),
///         MeasurementInput(measureId: minutesId, value: 28.0)
///     ],
///     goalContributions: [runningGoalId, healthGoalId]
/// )
///
/// let action = try await coordinator.create(from: formData)
/// ```
public struct ActionFormData: Sendable {

    // MARK: - Properties

    /// Required: The name of the action
    /// Example: "Morning run", "Team meeting", "Guitar practice"
    public let title: String

    /// Optional: Detailed description of what was done
    /// Example: "5K route through the park, felt strong"
    public let detailedDescription: String

    /// Optional: Free-form notes
    /// Example: "Weather was perfect, saw three deer"
    public let freeformNotes: String

    /// Optional: How long the action took (in minutes)
    /// Example: 28.0 for 28 minutes
    /// Zero means no duration tracked
    public let durationMinutes: Double

    /// When this action occurred
    /// Defaults to now, but can be changed for retroactive logging
    public let startTime: Date

    /// Measurements associated with this action
    /// Example: [MeasurementInput(measureId: km.id, value: 5.2)]
    public let measurements: [MeasurementInput]

    /// Goal IDs this action contributes toward
    /// Example: [runningGoalId, healthGoalId]
    /// ActionCoordinator creates ActionGoalContribution records for each
    public let goalContributions: Set<UUID>

    // MARK: - Initialization

    public init(
        title: String = "",
        detailedDescription: String = "",
        freeformNotes: String = "",
        durationMinutes: Double = 0,
        startTime: Date = Date(),
        measurements: [MeasurementInput] = [],
        goalContributions: Set<UUID> = []
    ) {
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.durationMinutes = durationMinutes
        self.startTime = startTime
        self.measurements = measurements
        self.goalContributions = goalContributions
    }
}

// MARK: - MeasurementInput Helper

/// Temporary struct for measurement input in the form
///
/// Holds the measure selection and value before conversion to MeasuredAction.
/// Sendable for safe passage from form to coordinator.
///
/// **Usage**:
/// ```swift
/// var measurements: [MeasurementInput] = []
/// measurements.append(MeasurementInput(
///     measureId: Measure.kilometers.id,
///     value: 5.2
/// ))
/// ```
public struct MeasurementInput: Identifiable, Sendable {
    public let id: UUID
    public var measureId: UUID?  // FK to measures catalog
    public var value: Double

    /// Whether this measurement is valid (has both measure and positive value)
    public var isValid: Bool {
        measureId != nil && value > 0
    }

    public init(
        id: UUID = UUID(),
        measureId: UUID? = nil,
        value: Double = 0.0
    ) {
        self.id = id
        self.measureId = measureId
        self.value = value
    }
}
