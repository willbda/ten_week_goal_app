//
// ValidationState.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Track validation issues (errors & warnings) during import wizard.
// Errors block commit, warnings are informational.
//
// WORKFLOW:
// 1. Parser/Validator detects issue
// 2. Creates ValidationError or ValidationWarning
// 3. Adds to ValidationState
// 4. ReviewStep displays issues for resolution
// 5. User resolves → remove from state
//
// EXAMPLE ISSUES:
// - Error: "Measure 'books' not found"
// - Warning: "Value 'Health' fuzzy-matched to 'Health & Vitality' (95%)"
//

import Foundation

/// Container for all validation issues
public struct ValidationState: Codable {
    /// Blocking errors (must resolve before commit)
    public var errors: [ImportValidationError]

    /// Non-blocking warnings (informational)
    public var warnings: [ValidationWarning]

    public init(errors: [ImportValidationError] = [], warnings: [ValidationWarning] = []) {
        self.errors = errors
        self.warnings = warnings
        }

    /// Check if import can proceed
    public var canCommit: Bool {
        errors.isEmpty
    }

    /// Total issue count
    public var totalIssues: Int {
        errors.count + warnings.count
    }
}

/// Blocking validation error during import
public struct ImportValidationError: Codable, Identifiable {
    public let id: UUID
    public let entityType: EntityType
    public let entityId: UUID
    public let message: String
    public var suggestion: String?
    public let created: Date

    public init(
        entityType: EntityType,
        entityId: UUID,
        message: String,
        suggestion: String? = nil
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.message = message
        self.suggestion = suggestion
        self.created = Date()
    }
}

/// Non-blocking validation warning
public struct ValidationWarning: Codable, Identifiable {
    public let id: UUID
    public let entityType: EntityType
    public let entityId: UUID
    public let message: String
    public let autoResolved: Bool
    public let created: Date

    public init(
        entityType: EntityType,
        entityId: UUID,
        message: String,
        autoResolved: Bool = false
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityId = entityId
        self.message = message
        self.autoResolved = autoResolved
        self.created = Date()
    }
}

/// Entity type for validation tracking
public enum EntityType: String, Codable {
    case value = "value"
    case measure = "measure"
    case goal = "goal"
    case action = "action"
}

// TODO: Add validation rule definitions
// - Duplicate detection threshold
// - Fuzzy match confidence threshold (e.g., >0.90 = auto-resolve)
// - Required field validation
