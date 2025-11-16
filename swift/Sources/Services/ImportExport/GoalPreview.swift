//
// GoalPreview.swift
// Written by Claude Code on 2025-11-07
//
// PURPOSE:
// Preview model for Goal CSV import confirmation screen.
// Shows parsed goal data before database commit.
//

import Foundation

/// Preview of a goal parsed from CSV, ready for user confirmation
public struct GoalPreview: CSVPreviewable {
    public let id: UUID
    public let rowNumber: Int

    // Expectation fields
    public let title: String
    public let description: String
    public let notes: String
    public let expectationImportance: Int
    public let expectationUrgency: Int

    // Goal fields
    public let startDate: Date?
    public let targetDate: Date?
    public let actionPlan: String?
    public let expectedTermLength: Int?

    // Metric targets (resolved)
    public let targets: [(unit: String, value: Double)]

    // Value alignments (names for fuzzy matching)
    public let valueNames: [String]

    // Optional: Term assignment
    public let termNumber: Int?

    // Validation status
    public let validationStatus: ValidationStatus

    public init(
        rowNumber: Int,
        title: String,
        description: String = "",
        notes: String = "",
        expectationImportance: Int = 5,
        expectationUrgency: Int = 5,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        actionPlan: String? = nil,
        expectedTermLength: Int? = nil,
        targets: [(unit: String, value: Double)] = [],
        valueNames: [String] = [],
        termNumber: Int? = nil,
        validationStatus: ValidationStatus = .valid
    ) {
        self.id = UUID()
        self.rowNumber = rowNumber
        self.title = title
        self.description = description
        self.notes = notes
        self.expectationImportance = expectationImportance
        self.expectationUrgency = expectationUrgency
        self.startDate = startDate
        self.targetDate = targetDate
        self.actionPlan = actionPlan
        self.expectedTermLength = expectedTermLength
        self.targets = targets
        self.valueNames = valueNames
        self.termNumber = termNumber
        self.validationStatus = validationStatus
    }

    /// Display summary for list view
    public var summary: String {
        var parts: [String] = [title]

        if !targets.isEmpty {
            let targetText = targets
                .map { "\($0.value) \($0.unit)" }
                .joined(separator: ", ")
            parts.append("Target: \(targetText)")
        }

        if !valueNames.isEmpty {
            parts.append("Values: \(valueNames.joined(separator: ", "))")
        }

        if let start = startDate, let target = targetDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            parts.append("\(formatter.string(from: start)) → \(formatter.string(from: target))")
        }

        return parts.joined(separator: " | ")
    }

    /// Is this row valid for import?
    public var isValid: Bool {
        validationStatus == .valid
    }
}
