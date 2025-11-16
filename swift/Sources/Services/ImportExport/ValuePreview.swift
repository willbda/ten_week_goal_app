//
// ValuePreview.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Preview model for CSV value import with validation status.
// Simpler than GoalPreview - no foreign keys, no junction tables.
//

import Foundation
import Models

/// Preview of a PersonalValue from CSV before import
///
/// **Design**: Direct field mapping from CSV (no database lookups needed)
/// Unlike GoalPreview which requires lookup tables for measures/values,
/// ValuePreview can be created synchronously from CSV row alone.
public struct ValuePreview: CSVPreviewable {
    // MARK: - CSVPreviewable Requirements

    public let id: UUID
    public let rowNumber: Int

    public var title: String { valueTitle }

    public var validationStatus: ValidationStatus

    public var isValid: Bool {
        if case .valid = validationStatus {
            return true
        }
        return false
    }

    public var summary: String {
        var parts: [String] = []

        // Level
        parts.append(valueLevel.displayName)

        // Priority
        if let priority = priority {
            parts.append("Priority: \(priority)")
        } else {
            parts.append("Priority: \(valueLevel.defaultPriority) (default)")
        }

        // Life domain
        if let domain = lifeDomain, !domain.isEmpty {
            parts.append("Domain: \(domain)")
        }

        return parts.joined(separator: " | ")
    }

    // MARK: - Value Fields

    public let valueTitle: String
    public let detailedDescription: String?
    public let freeformNotes: String?
    public let priority: Int?
    public let valueLevel: ValueLevel
    public let lifeDomain: String?
    public let alignmentGuidance: String?

    // MARK: - Initialization

    public init(
        rowNumber: Int,
        title: String,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        priority: Int? = nil,
        valueLevel: ValueLevel,
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil,
        validationStatus: ValidationStatus = .valid
    ) {
        self.id = UUID()
        self.rowNumber = rowNumber
        self.valueTitle = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.priority = priority
        self.valueLevel = valueLevel
        self.lifeDomain = lifeDomain
        self.alignmentGuidance = alignmentGuidance
        self.validationStatus = validationStatus
    }
}

// MARK: - ValueLevel Display

extension ValueLevel {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .general: return "General"
        case .major: return "Major"
        case .highestOrder: return "Highest Order"
        case .lifeArea: return "Life Area"
        }
    }

    /// Default priority for this level
    var defaultPriority: Int {
        switch self {
        case .general: return 40
        case .major: return 10
        case .highestOrder: return 1
        case .lifeArea: return 40
        }
    }
}
