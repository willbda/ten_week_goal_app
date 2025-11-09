//
// GoalMapper.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Maps CSV rows to GoalFormData for GoalCoordinator.
// Handles metric targets, value alignments, term assignments.
//

import Foundation
import Models
import SQLiteData

// MARK: - Goal Mapper

/// Maps CSV rows to GoalFormData
public struct GoalMapper: CSVMapper {
    private let database: any DatabaseWriter  // Writer needed for auto-create measures

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    public func map(row: [String: String], rowNumber: Int) throws -> GoalFormData {
        // 1. Extract required fields
        guard let title = row["title"]?.nonEmpty else {
            throw MapError.missingRequired(row: rowNumber, field: "title")
        }

        // 2. Extract optional Expectation fields
        let description = row["description"]?.nonEmpty ?? ""
        let notes = row["notes"]?.nonEmpty ?? ""

        let importance: Int
        if let importanceStr = row["importance"]?.nonEmpty {
            guard let value = Int(importanceStr), (1...10).contains(value) else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: "importance",
                    value: importanceStr,
                    reason: "Must be integer 1-10"
                )
            }
            importance = value
        } else {
            importance = 8  // Default for goals
        }

        let urgency: Int
        if let urgencyStr = row["urgency"]?.nonEmpty {
            guard let value = Int(urgencyStr), (1...10).contains(value) else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: "urgency",
                    value: urgencyStr,
                    reason: "Must be integer 1-10"
                )
            }
            urgency = value
        } else {
            urgency = 5  // Default for goals
        }

        // 3. Extract Goal fields
        let startDate = try parseOptionalDate(row["start_date"], field: "start_date", rowNumber: rowNumber)
        let targetDate = try parseOptionalDate(row["target_date"], field: "target_date", rowNumber: rowNumber)
        let actionPlan = row["action_plan"]?.nonEmpty

        let expectedTermLength: Int?
        if let termStr = row["expected_term_length"]?.nonEmpty {
            guard let value = Int(termStr), value > 0 else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: "expected_term_length",
                    value: termStr,
                    reason: "Must be positive integer"
                )
            }
            expectedTermLength = value
        } else {
            expectedTermLength = nil
        }

        // 4. Parse metric targets (measure_1_unit, measure_1_target, etc.)
        let metricTargets = try parseMetricTargets(from: row, rowNumber: rowNumber)

        // 5. Parse value alignments (value_1_title, value_1_strength, etc.)
        let valueAlignments = try parseValueAlignments(from: row, rowNumber: rowNumber)

        // 6. Parse optional term assignment (term_number)
        let termId = try parseTermAssignment(from: row, rowNumber: rowNumber)

        return GoalFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            expectationImportance: importance,
            expectationUrgency: urgency,
            startDate: startDate,
            targetDate: targetDate,
            actionPlan: actionPlan,
            expectedTermLength: expectedTermLength,
            metricTargets: metricTargets,
            valueAlignments: valueAlignments,
            termId: termId
        )
    }

    // MARK: - Metric Target Parsing

    /// Parse measure_N_unit and measure_N_target columns
    private func parseMetricTargets(
        from row: [String: String],
        rowNumber: Int
    ) throws -> [MetricTargetInput] {
        var targets: [MetricTargetInput] = []

        for i in 1...10 {  // Support up to 10 targets
            let unitKey = "measure_\(i)_unit"
            let targetKey = "measure_\(i)_target"

            guard let unit = row[unitKey]?.nonEmpty else {
                break  // No more targets
            }

            guard let targetStr = row[targetKey]?.nonEmpty else {
                throw MapError.missingRequired(row: rowNumber, field: targetKey)
            }

            guard let targetValue = Double(targetStr), targetValue > 0 else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: targetKey,
                    value: targetStr,
                    reason: "Must be positive number"
                )
            }

            // Look up or create measure
            let measureId = try lookupOrCreateMeasure(unit: unit, rowNumber: rowNumber)

            targets.append(MetricTargetInput(measureId: measureId, targetValue: targetValue))
        }

        return targets
    }

    // MARK: - Value Alignment Parsing

    /// Parse value_N_title and value_N_strength columns
    private func parseValueAlignments(
        from row: [String: String],
        rowNumber: Int
    ) throws -> [ValueAlignmentInput] {
        var alignments: [ValueAlignmentInput] = []

        for i in 1...10 {  // Support up to 10 value alignments
            let titleKey = "value_\(i)_title"
            let strengthKey = "value_\(i)_strength"

            guard let valueTitle = row[titleKey]?.nonEmpty else {
                break  // No more alignments
            }

            // Alignment strength is optional, default to 5
            let strength: Int
            if let strengthStr = row[strengthKey]?.nonEmpty {
                guard let value = Int(strengthStr), (1...10).contains(value) else {
                    throw MapError.invalidValue(
                        row: rowNumber,
                        field: strengthKey,
                        value: strengthStr,
                        reason: "Must be integer 1-10"
                    )
                }
                strength = value
            } else {
                strength = 5  // Default alignment strength
            }

            // Look up value by title
            guard let valueId = try lookupValueByTitle(valueTitle) else {
                throw MapError.lookupFailed(
                    row: rowNumber,
                    entity: "PersonalValue",
                    identifier: valueTitle
                )
            }

            alignments.append(ValueAlignmentInput(valueId: valueId, alignmentStrength: strength))
        }

        return alignments
    }

    // MARK: - Term Assignment Parsing

    /// Parse term_number column
    private func parseTermAssignment(
        from row: [String: String],
        rowNumber: Int
    ) throws -> UUID? {
        guard let termNumberStr = row["term_number"]?.nonEmpty else {
            return nil
        }

        guard let termNumber = Int(termNumberStr) else {
            throw MapError.invalidValue(
                row: rowNumber,
                field: "term_number",
                value: termNumberStr,
                reason: "Must be integer"
            )
        }

        // Look up term by termNumber
        guard let termId = try lookupTermByNumber(termNumber) else {
            throw MapError.lookupFailed(
                row: rowNumber,
                entity: "Term",
                identifier: String(termNumber)
            )
        }

        return termId
    }

    // MARK: - Lookup Helpers

    /// Look up measure by unit, create if not found (same logic as ActionMapper)
    private func lookupOrCreateMeasure(unit: String, rowNumber: Int) throws -> UUID {
        // Try to find existing measure
        if let existingMeasure = try? database.read({ db in
            try Measure.all.where { $0.unit.eq(unit) }.fetchOne(db)
        }) {
            return existingMeasure.id
        }

        // Create new measure
        let measureId = UUID()
        let measureType = inferMeasureType(from: unit)

        try database.write { db in
            try Measure.insert {
                Measure.Draft(
                    id: measureId,
                    logTime: Date(),
                    title: unit.capitalized,
                    detailedDescription: "Auto-created from CSV import",
                    freeformNotes: nil,
                    unit: unit,
                    measureType: measureType,
                    canonicalUnit: unit,
                    conversionFactor: nil
                )
            }.execute(db)
        }

        return measureId
    }

    /// Infer measure type from unit string
    private func inferMeasureType(from unit: String) -> String {
        let lower = unit.lowercased()
        if ["km", "miles", "m", "meters", "kilometers"].contains(lower) {
            return "distance"
        } else if ["minutes", "hours", "seconds", "min", "hrs", "sec"].contains(lower) {
            return "time"
        } else if ["kg", "lbs", "pounds", "kilograms", "g", "grams"].contains(lower) {
            return "mass"
        } else {
            return "count"
        }
    }

    /// Look up PersonalValue by exact title match
    private func lookupValueByTitle(_ title: String) throws -> UUID? {
        return try database.read { db in
            let values = try PersonalValue.all.fetchAll(db)

            // Find exact match (case-insensitive)
            for value in values {
                if value.title?.lowercased() == title.lowercased() {
                    return value.id
                }
            }

            return nil
        }
    }

    /// Look up Term by termNumber
    private func lookupTermByNumber(_ termNumber: Int) throws -> UUID? {
        return try database.read { db in
            try GoalTerm.all.where { $0.termNumber.eq(termNumber) }.fetchOne(db)?.id
        }
    }

    // MARK: - Date Parsing

    /// Parse optional ISO 8601 date string
    private func parseOptionalDate(
        _ string: String?,
        field: String,
        rowNumber: Int
    ) throws -> Date? {
        guard let string = string?.nonEmpty else {
            return nil
        }

        guard let date = parseISO8601(string) else {
            throw MapError.invalidValue(
                row: rowNumber,
                field: field,
                value: string,
                reason: "Expected ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ)"
            )
        }

        return date
    }

    /// Parse ISO 8601 date string
    private func parseISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        if let date = formatter.date(from: string) {
            return date
        }

        // Try date-only format (YYYY-MM-DD)
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: string)
    }
}
