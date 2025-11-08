//
// MetricTargetInput.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Helper struct for metric target input in goal forms
// USAGE: GoalFormData.metricTargets: [MetricTargetInput]
// VALIDATION: isValid checks measureId exists and targetValue > 0
//

import Foundation

/// Input struct for goal metric targets
///
/// Used in GoalFormView to specify measurable targets (e.g., "120 km", "30 runs").
/// Converted to ExpectationMeasure records by GoalCoordinator.
public struct MetricTargetInput: Identifiable, Sendable {
    public let id: UUID
    public var measureId: UUID?
    public var targetValue: Double
    public var notes: String?

    public var isValid: Bool {
        measureId != nil && targetValue > 0
    }

    public init(
        id: UUID = UUID(),
        measureId: UUID? = nil,
        targetValue: Double = 0.0,
        notes: String? = nil
    ) {
        self.id = id
        self.measureId = measureId
        self.targetValue = targetValue
        self.notes = notes
    }
}
