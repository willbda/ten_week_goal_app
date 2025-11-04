//
// StagedAction.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Temporary Action before database commit
// PARSER INPUT: "Morning run | 2025-11-03 | km:5.2 | Run 120km"
// WORKFLOW: Parse → Resolve measure/goal refs → Commit

import Foundation

public struct StagedAction: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var date: Date
    public var durationMinutes: Double?
    public var detailedDescription: String?
    public var freeformNotes: String?

    // Measurements: [(measure reference, value)]
    public var measurements: [StagedMeasurement]

    // Goal contributions (optional)
    public var goalRefs: [GoalReference]

    public var status: ResolutionStatus
    public var originalInput: String?

    public init(
        title: String,
        date: Date,
        measurements: [StagedMeasurement] = [],
        goalRefs: [GoalReference] = [],
        status: ResolutionStatus = .needsResolution
    ) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.measurements = measurements
        self.goalRefs = goalRefs
        self.status = status
    }

    public var isResolved: Bool {
        measurements.allSatisfy { $0.measureRef.resolved != nil } &&
        goalRefs.allSatisfy { $0.resolved != nil }
    }
}

public struct StagedMeasurement: Codable {
    public var measureRef: MeasureReference
    public var value: Double

    public init(measureRef: MeasureReference, value: Double) {
        self.measureRef = measureRef
        self.value = value
    }
}

// TODO: Parse multi-measure format
// - "km:5.2,minutes:28" → [(km, 5.2), (minutes, 28)]
