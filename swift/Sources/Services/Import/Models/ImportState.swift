//
// ImportState.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Root JSON structure for persisting import wizard state to disk.
// Enables crash recovery, draft saving, and import history.
//
// ARCHITECTURE:
// - Codable struct that maps directly to active_import.json
// - Contains all staged data + validation state + progress tracking
// - Version field allows schema evolution
//
// USAGE:
// ```swift
// let state = ImportState(
//     version: "1.0",
//     created: Date(),
//     lastModified: Date(),
//     currentStep: 2,
//     status: .inProgress,
//     staged: StagedData(),
//     validation: ValidationState()
// )
//
// let encoder = JSONEncoder()
// encoder.outputFormatting = .prettyPrinted
// let json = try encoder.encode(state)
// ```
//

import Foundation

/// Root structure for import wizard persistence
public struct ImportState: Codable {
    /// Schema version for migration support
    public let version: String

    /// When this import was first created
    public let created: Date

    /// Last modification timestamp (for auto-save tracking)
    public var lastModified: Date

    /// Current wizard step (1-6)
    public var currentStep: Int

    /// Import status (inProgress/draft/completed)
    public var status: ImportStatus

    /// All staged data (values, measures, goals, actions)
    public var staged: StagedData

    /// Validation results (errors, warnings)
    public var validation: ValidationState

    public init(
        version: String,
        created: Date,
        lastModified: Date,
        currentStep: Int,
        status: ImportStatus,
        staged: StagedData,
        validation: ValidationState
    ) {
        self.version = version
        self.created = created
        self.lastModified = lastModified
        self.currentStep = currentStep
        self.status = status
        self.staged = staged
        self.validation = validation
    }
}

/// Import workflow status
public enum ImportStatus: String, Codable {
    case inProgress = "in_progress"   // Active wizard session
    case draft = "draft"                // Saved for later
    case completed = "completed"        // Successfully committed
}

/// Container for all staged entities
public struct StagedData: Codable {
    public var created: Date
    public var values: [StagedValue]
    public var measures: [StagedMeasure]
    public var goals: [StagedGoal]
    public var actions: [StagedAction]

    public init(
        created: Date = Date(),
        values: [StagedValue] = [],
        measures: [StagedMeasure] = [],
        goals: [StagedGoal] = [],
        actions: [StagedAction] = []
    ) {
        self.created = created
        self.values = values
        self.measures = measures
        self.goals = goals
        self.actions = actions
    }
}

// TODO: Implement metadata tracking
// - Total entity counts
// - Unresolved reference counts
// - Estimated commit time
