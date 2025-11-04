//
// StagedValue.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Temporary PersonalValue representation before database commit.
// Used during import wizard to hold parsed value data with validation state.
//
// WORKFLOW:
// 1. User pastes: "Health & Vitality"
// 2. Parser creates: StagedValue(title: "Health & Vitality", level: .major, ...)
// 3. Wizard validates: Check for duplicates, infer level
// 4. Committer creates: PersonalValue in database via PersonalValuesCoordinator
//
// WHY SEPARATE FROM PersonalValue?
// - Temporary UUID (not in database yet)
// - Additional import metadata (status, originalInput)
// - Validation state tracking
//

import Foundation
import Models

/// Temporary value awaiting database commit
public struct StagedValue: Codable, Identifiable {
    // MARK: - Identity

    /// Temporary ID for wizard cross-references
    /// Will be replaced with real UUID on commit
    public let id: UUID

    // MARK: - PersonalValue Fields

    public var title: String
    public var level: ValueLevel
    public var priority: Int
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var lifeDomain: String?
    public var alignmentGuidance: String?

    // MARK: - Import Metadata

    /// Resolution status for wizard UI
    public var status: ResolutionStatus

    /// Original input before parsing (for debugging)
    public var originalInput: String?

    /// If duplicate detected, UUID of existing value
    public var existingMatch: UUID?

    public init(
        title: String,
        level: ValueLevel,
        priority: Int = 50,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil,
        status: ResolutionStatus = .resolved,
        originalInput: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.level = level
        self.priority = priority
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.lifeDomain = lifeDomain
        self.alignmentGuidance = alignmentGuidance
        self.status = status
        self.originalInput = originalInput
    }
}

/// Resolution status for staged entities
public enum ResolutionStatus: String, Codable {
    case resolved = "resolved"              // Ready to commit
    case needsResolution = "needs_resolution"  // Requires user input
    case userChoice = "user_choice"         // User must decide between options
}

// TODO: Add validation methods
// - isDuplicate(of existing: [PersonalValue]) -> Bool
// - suggestLevel(from text: String) -> ValueLevel
