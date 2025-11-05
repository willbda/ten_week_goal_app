//
// StagedGoal.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Temporary Goal before database commit
// PARSER INPUT: "Run 120km | 120 | km | Health, Movement"
// WORKFLOW: Parse → Resolve references → Commit

import Foundation

public struct StagedGoal: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var targetValue: Double
    public var startDate: Date?
    public var targetDate: Date?
    public var actionPlan: String?

    // References (may be unresolved initially)
    public var measureRef: MeasureReference
    public var valueRefs: [ValueReference]

    public var status: ResolutionStatus
    public var originalInput: String?

    public init(
        title: String,
        targetValue: Double,
        measureRef: MeasureReference,
        valueRefs: [ValueReference] = [],
        status: ResolutionStatus = .needsResolution
    ) {
        self.id = UUID()
        self.title = title
        self.targetValue = targetValue
        self.measureRef = measureRef
        self.valueRefs = valueRefs
        self.status = status
    }

    /// Check if all references are resolved
    public var isResolved: Bool {
        measureRef.resolved != nil &&
        valueRefs.allSatisfy { $0.resolved != nil }
    }
}

// TODO: Add SMART goal validation
// - hasSpecificTarget() -> Bool
// - hasMeasurableMetric() -> Bool
// - hasTimeframe() -> Bool
