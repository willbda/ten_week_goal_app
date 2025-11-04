//
// StagedMeasure.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Temporary Measure before database commit
// PARSER INPUT: "km, distance, Distance in kilometers"
// WORKFLOW: Parse → Validate → Commit via Coordinator

import Foundation
import Models

public struct StagedMeasure: Codable, Identifiable {
    public let id: UUID
    public var unit: String
    public var measureType: String
    public var title: String?
    public var detailedDescription: String?
    public var status: ResolutionStatus
    public var originalInput: String?
    public var existingMatch: UUID?  // If duplicate detected

    public init(
        unit: String,
        measureType: String,
        title: String? = nil,
        detailedDescription: String? = nil,
        status: ResolutionStatus = .resolved,
        originalInput: String? = nil
    ) {
        self.id = UUID()
        self.unit = unit
        self.measureType = measureType
        self.title = title
        self.detailedDescription = detailedDescription
        self.status = status
        self.originalInput = originalInput
    }
}

// TODO: Auto-detect measureType from unit
// - "km", "miles" → "distance"
// - "hours", "minutes" → "time"
// - "occasions", "times" → "count"
