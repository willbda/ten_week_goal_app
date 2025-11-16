//
// ActionPreview.swift
// Written by Claude Code on 2025-11-06
//
// PURPOSE:
// Preview model for CSV import confirmation screen.
// Shows parsed data before database commit.
//

import Foundation

/// Preview of an action parsed from CSV, ready for user confirmation
public struct ActionPreview: CSVPreviewable {
    public let id: UUID
    public let rowNumber: Int

    // Parsed fields
    public let title: String
    public let description: String
    public let notes: String
    public let durationMinutes: Double
    public let startTime: Date

    // Measurements (resolved)
    public let measurements: [(unit: String, value: Double)]

    // Goal contributions (resolved)
    public let goalTitles: [String]

    // Validation status
    public let validationStatus: ValidationStatus

    public init(
        rowNumber: Int,
        title: String,
        description: String = "",
        notes: String = "",
        durationMinutes: Double = 0,
        startTime: Date = Date(),
        measurements: [(unit: String, value: Double)] = [],
        goalTitles: [String] = [],
        validationStatus: ValidationStatus = .valid
    ) {
        self.id = UUID()
        self.rowNumber = rowNumber
        self.title = title
        self.description = description
        self.notes = notes
        self.durationMinutes = durationMinutes
        self.startTime = startTime
        self.measurements = measurements
        self.goalTitles = goalTitles
        self.validationStatus = validationStatus
    }

    /// Display summary for list view
    public var summary: String {
        var parts: [String] = [title]

        if !measurements.isEmpty {
            let measureText = measurements
                .map { "\($0.value) \($0.unit)" }
                .joined(separator: ", ")
            parts.append(measureText)
        }

        if !goalTitles.isEmpty {
            parts.append("→ \(goalTitles.joined(separator: ", "))")
        }

        return parts.joined(separator: " | ")
    }

    /// Is this row valid for import?
    public var isValid: Bool {
        validationStatus == .valid
    }
}

/// Validation status for preview row
public enum ValidationStatus: Sendable, Equatable {
    case valid
    case warning(String)
    case error(String)

    public var icon: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    public var message: String? {
        switch self {
        case .valid: return nil
        case .warning(let msg): return msg
        case .error(let msg): return msg
        }
    }
}

/// Result of CSV parsing with action previews
/// Note: Use CSVParseResult<ActionPreview> for new code
public typealias ParseResult = CSVParseResult<ActionPreview>
