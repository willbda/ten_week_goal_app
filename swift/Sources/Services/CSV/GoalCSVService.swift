//
// GoalCSVService.swift
// Written by Claude Code on 2025-11-07
//
// PURPOSE:
// CSV import/export for Goals with embedded reference data in single file.
//
// TEMPLATE STRUCTURE (single file):
// 1. MEASURES section - Reference table of available measures
// 2. VALUES section - Reference table of personal values
// 3. IMPORT section - Actual data entry rows with numbered lines
//
// IMPORT SECTION:
// - Fields row: Column names
// - Optionality row: REQUIRED vs optional indicator
// - Sample row: Example data (skipped during import)
// - Numbered data rows (1-10): User fills these in
//
// COLUMNS:
// - title, description, notes, importance, urgency
// - target_value, target_unit
// - value_1_name, value_2_name
// - start_date, target_date, expected_term_length
//
// DATE FORMAT: ISO 8601 (2025-11-06)
//

import Foundation
import Models
import SQLiteData

@MainActor
public final class GoalCSVService {
    private let database: any DatabaseWriter
    private let coordinator: GoalCoordinator

    // MARK: - Initialization

    public init(database: any DatabaseWriter, coordinator: GoalCoordinator) {
        self.database = database
        self.coordinator = coordinator
    }

    // MARK: - Export Template

    /// Export blank template with embedded reference data (single file)
    public func exportTemplate(to directory: URL) async throws -> URL {
        let templatePath = directory.appendingPathComponent("goals_template.csv")
        try await exportBlankTemplate(to: templatePath)
        return templatePath
    }

    /// Export all existing goals to CSV (filled template with reference data)
    public func exportGoals(to directory: URL) async throws -> URL {
        let exportPath = directory.appendingPathComponent("goals_export.csv")
        try await exportFilledTemplate(to: exportPath)
        return exportPath
    }

    // MARK: - Import

    /// Parse CSV and generate preview (does not import)
    /// Returns preview rows for user confirmation
    public func previewImport(from csvPath: URL) async throws -> CSVParseResult<GoalPreview> {
        let rows = try parseCSV(from: csvPath)
        let lookup = try await buildLookupTables()

        var previews: [GoalPreview] = []
        var errors: [String] = []

        for row in rows {
            do {
                let preview = try convertToPreview(row, lookup: lookup)
                previews.append(preview)
            } catch {
                errors.append("Row \(row.lineNumber): \(error.localizedDescription)")
            }
        }

        return CSVParseResult(previews: previews, errors: errors)
    }

    /// Import selected goal previews
    /// Only imports goals where isSelected is true
    public func importSelected(_ previews: [GoalPreview]) async throws -> CSVImportResult {
        let lookup = try await buildLookupTables()

        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for preview in previews {
            do {
                let formData = try await convertPreviewToFormData(preview, lookup: lookup)
                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((preview.rowNumber, error.localizedDescription))
            }
        }

        return CSVImportResult(successes: successes, failures: failures)
    }

    // MARK: - Template Generation

    private func exportBlankTemplate(to path: URL) async throws {
        var csv = ""

        // MEASURES and VALUES sections (reference data)
        csv += ",MEASURES,,,,,VALUES,,,\n"
        csv += ",unit,type,description,,,title,level,priority,description\n"

        // Query measures and values for reference data
        let (measures, values) = try await database.read { db in
            let measures = try Measure.all.order { $0.unit.asc() }.fetchAll(db)
            let values = try PersonalValue.all.order { $0.priority.desc() }.fetchAll(db)
            return (measures, values)
        }

        // Write reference rows (measures on left, values on right)
        let maxRows = max(measures.count, values.count)
        for i in 0..<maxRows {
            // Measures column
            if i < measures.count {
                let measure = measures[i]
                let unit = escapeCSV(measure.unit)
                let type = escapeCSV(measure.measureType)
                let description = escapeCSV(measure.detailedDescription ?? "")
                csv += ",\(unit),\(type),\(description),"
            } else {
                csv += ",,,,"
            }

            csv += ",,"  // Empty columns between sections

            // Values column
            if i < values.count {
                let value = values[i]
                let title = escapeCSV(value.title ?? "Untitled Value")
                let level = escapeCSV(value.valueLevel.rawValue)
                let priority = value.priority
                let description = escapeCSV(value.detailedDescription ?? "")
                csv += ",\(title),\(level),\(priority),\(description)\n"
            } else {
                csv += ",,,,\n"
            }
        }

        // Add blank rows between sections
        for _ in 0..<6 {
            csv += ",,,,,,,,,,\n"
        }

        // IMPORT Section
        csv += ",IMPORT,,,,,,,,,\n"
        csv += "Fields,title,description,notes,importance,urgency,target_value,target_unit,value_1_name,value_2_name,start_date,target_date,term_length\n"
        csv += "Optionality,REQUIRED,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional\n"
        csv += "Sample,Run 120km,Spring training,,5,8,120,km,Health,Movement,2025-04-12,2025-06-21,10\n"

        // Numbered data rows (1-10)
        for i in 1...10 {
            csv += "\(i),,,,,,,,,,,,\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    private func exportFilledTemplate(to path: URL) async throws {
        var csv = ""

        // Same reference sections as blank template
        csv += ",MEASURES,,,,,VALUES,,,\n"
        csv += ",unit,type,description,,,title,level,priority,description\n"

        let (measures, values, goalsData, relevances, targets) = try await database.read { db in
            let measures = try Measure.all.order { $0.unit.asc() }.fetchAll(db)
            let values = try PersonalValue.all.order { $0.priority.desc() }.fetchAll(db)

            // Fetch all Goals + Expectations
            let goalsWithExpectations = try Goal.all
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .fetchAll(db)

            // Fetch all goal-value relevances
            let relevances = try GoalRelevance.all
                .join(PersonalValue.all) { $0.valueId.eq($1.id) }
                .fetchAll(db)

            // Fetch all expectation measures
            let targets = try ExpectationMeasure.all
                .join(Measure.all) { $0.measureId.eq($1.id) }
                .fetchAll(db)

            return (measures, values, goalsWithExpectations, relevances, targets)
        }

        // Write reference rows
        let maxRows = max(measures.count, values.count)
        for i in 0..<maxRows {
            if i < measures.count {
                let measure = measures[i]
                csv += ",\(escapeCSV(measure.unit)),\(escapeCSV(measure.measureType)),\(escapeCSV(measure.detailedDescription ?? "")),"
            } else {
                csv += ",,,,"
            }

            csv += ",,"

            if i < values.count {
                let value = values[i]
                csv += ",\(escapeCSV(value.title ?? "")),\(escapeCSV(value.valueLevel.rawValue)),\(value.priority),\(escapeCSV(value.detailedDescription ?? ""))\n"
            } else {
                csv += ",,,,\n"
            }
        }

        for _ in 0..<6 {
            csv += ",,,,,,,,,,\n"
        }

        // IMPORT Section with actual data
        csv += ",IMPORT,,,,,,,,,\n"
        csv += "Fields,title,description,notes,importance,urgency,target_value,target_unit,value_1_name,value_2_name,start_date,target_date,term_length\n"
        csv += "Optionality,REQUIRED,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional\n"
        csv += "Sample,Run 120km,Spring training,,5,8,120,km,Health,Movement,2025-04-12,2025-06-21,10\n"

        // Group relevances by goal ID
        let relevancesByGoal = Dictionary(grouping: relevances) { $0.0.goalId }
        let targetsByExpectation = Dictionary(grouping: targets) { $0.0.expectationId }

        // Write actual goal data rows
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        for (index, (goal, expectation)) in goalsData.enumerated() {
            let title = escapeCSV(expectation.title ?? "Untitled")
            let description = escapeCSV(expectation.detailedDescription ?? "")
            let notes = escapeCSV(expectation.freeformNotes ?? "")
            let importance = expectation.expectationImportance
            let urgency = expectation.expectationUrgency

            // Get first target (if any)
            let firstTarget = targetsByExpectation[expectation.id]?.first
            let targetValue = firstTarget.map { String($0.0.targetValue) } ?? ""
            let targetUnit = firstTarget?.1.unit ?? ""

            // Get first two values (if any)
            let goalValues = relevancesByGoal[goal.id] ?? []
            let value1 = goalValues.first?.1.title ?? ""
            let value2 = goalValues.dropFirst().first?.1.title ?? ""

            let startDate = goal.startDate.map { dateFormatter.string(from: $0) } ?? ""
            let targetDate = goal.targetDate.map { dateFormatter.string(from: $0) } ?? ""
            let termLength = goal.expectedTermLength.map { String($0) } ?? ""

            csv += "\(index + 1),\(title),\(description),\(notes),\(importance),\(urgency),\(targetValue),\(targetUnit),\(value1),\(value2),\(startDate),\(targetDate),\(termLength)\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    // MARK: - CSV Parsing

    private func parseCSV(from path: URL) throws -> [CSVRow] {
        let content = try String(contentsOf: path, encoding: .utf8)
        // Handle both Unix (\n) and Windows (\r\n) line endings
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Find the IMPORT section
        guard let importIndex = lines.firstIndex(where: { $0.contains("IMPORT") }) else {
            throw CSVError.invalidFormat("CSV must contain 'IMPORT' section marker")
        }

        let importSection = Array(lines.dropFirst(importIndex))

        guard importSection.count >= 4 else {
            throw CSVError.invalidFormat("IMPORT section must have Fields, Optionality, Sample, and data rows")
        }

        // Parse header from Fields row
        let fieldsLine = importSection[1]
        let fields = parseCSVLine(fieldsLine)

        // Skip Fields, Optionality, Sample rows → data starts at index 3
        let dataLines = importSection.dropFirst(3)

        return try dataLines.enumerated().compactMap { (index, line) -> CSVRow? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }

            let values = parseCSVLine(line)

            guard values.count >= fields.count else {
                throw CSVError.columnMismatch(row: importIndex + 4 + index, expected: fields.count, got: values.count)
            }

            // Check if row number is just a number (empty data row)
            let firstValue = values[0].trimmingCharacters(in: .whitespaces)
            if Int(firstValue) != nil && values.dropFirst().allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                return nil  // Skip empty numbered rows
            }

            var rowData: [String: String] = [:]
            for (col, value) in zip(fields, values) {
                rowData[col] = value.trimmingCharacters(in: .whitespaces)
            }

            return CSVRow(lineNumber: importIndex + 4 + index, data: rowData)
        }
    }

    /// Parse a CSV line respecting quoted fields
    /// Handles: `"field with, comma",other field`
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousChar: Character? = nil

        for char in line {
            if char == "\"" {
                if insideQuotes && previousChar == "\"" {
                    // Escaped quote ("")
                    currentField.append(char)
                    previousChar = nil
                    continue
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            previousChar = char
        }

        // Add last field
        fields.append(currentField)

        return fields
    }

    // MARK: - Lookup Tables

    private func buildLookupTables() async throws -> GoalLookupTables {
        return try await database.read { db in
            let measures = try Measure.all.fetchAll(db)
            var measureMap: [String: UUID] = [:]
            for measure in measures {
                measureMap[measure.unit] = measure.id
            }

            let values = try PersonalValue.all.fetchAll(db)
            var valueMap: [String: UUID] = [:]
            for value in values {
                if let title = value.title {
                    valueMap[title.lowercased()] = value.id
                }
            }

            return GoalLookupTables(measuresByUnit: measureMap, valuesByName: valueMap, allValues: values)
        }
    }

    // MARK: - Row Conversion

    private func convertToPreview(_ row: CSVRow, lookup: GoalLookupTables) throws -> GoalPreview {
        guard let title = row.data["title"], !title.isEmpty else {
            throw CSVError.missingRequiredField(row: row.lineNumber, field: "title")
        }

        let description = row.data["description"] ?? ""
        let notes = row.data["notes"] ?? ""
        let importance = Int(row.data["importance"] ?? "5") ?? 5
        let urgency = Int(row.data["urgency"] ?? "5") ?? 5

        // Parse metric target
        var targets: [(unit: String, value: Double)] = []
        var validationStatus: ValidationStatus = .valid

        if let targetValueString = row.data["target_value"], !targetValueString.isEmpty,
           let targetValue = Double(targetValueString),
           let unit = row.data["target_unit"], !unit.isEmpty {

            if lookup.measuresByUnit[unit] == nil {
                // Warning: measure will be auto-created during import
                validationStatus = .warning("Measure '\(unit)' will be created automatically")
            }
            targets.append((unit: unit, value: targetValue))
        }

        // Parse value names
        var valueNames: [String] = []
        for i in 1...2 {
            if let valueName = row.data["value_\(i)_name"], !valueName.isEmpty {
                valueNames.append(valueName)

                // Check if value exists (fuzzy match in real implementation)
                if lookup.valuesByName[valueName.lowercased()] == nil {
                    // Don't error - fuzzy matching will handle this
                    if validationStatus == .valid {
                        validationStatus = .warning("Value '\(valueName)' needs fuzzy matching")
                    }
                }
            }
        }

        // Parse dates
        let startDate = row.data["start_date"].flatMap { parseDate($0) }
        let targetDate = row.data["target_date"].flatMap { parseDate($0) }
        let expectedTermLength = row.data["term_length"].flatMap { Int($0) }

        return GoalPreview(
            rowNumber: row.lineNumber,
            title: title,
            description: description,
            notes: notes,
            expectationImportance: importance,
            expectationUrgency: urgency,
            startDate: startDate,
            targetDate: targetDate,
            expectedTermLength: expectedTermLength,
            targets: targets,
            valueNames: valueNames,
            validationStatus: validationStatus
        )
    }

    private func convertPreviewToFormData(_ preview: GoalPreview, lookup: GoalLookupTables) async throws -> GoalFormData {
        // Convert metric targets (auto-create missing measures)
        var metricTargets: [MetricTargetInput] = []
        for (unit, value) in preview.targets {
            let measureId: UUID
            if let existingId = lookup.measuresByUnit[unit] {
                measureId = existingId
            } else {
                // Auto-create missing measure
                measureId = try await createMeasure(unit: unit)
            }
            metricTargets.append(MetricTargetInput(measureId: measureId, targetValue: value, notes: nil))
        }

        // Convert value alignments with fuzzy matching
        var valueAlignments: [ValueAlignmentInput] = []
        for name in preview.valueNames {
            let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)

            // Try exact match first
            if let valueId = lookup.valuesByName[normalizedName] {
                valueAlignments.append(ValueAlignmentInput(
                    valueId: valueId,
                    alignmentStrength: 5,  // Default strength
                    relevanceNotes: nil
                ))
            } else {
                // Fuzzy match (simple substring for now)
                if let matched = lookup.allValues.first(where: {
                    $0.title?.lowercased().contains(normalizedName) == true
                }) {
                    valueAlignments.append(ValueAlignmentInput(
                        valueId: matched.id,
                        alignmentStrength: 5,
                        relevanceNotes: "Fuzzy matched: \(name) → \(matched.title ?? "")"
                    ))
                }
                // If no match, skip (don't throw error)
            }
        }

        return GoalFormData(
            title: preview.title,
            detailedDescription: preview.description,
            freeformNotes: preview.notes,
            expectationImportance: preview.expectationImportance,
            expectationUrgency: preview.expectationUrgency,
            startDate: preview.startDate,
            targetDate: preview.targetDate,
            actionPlan: preview.actionPlan,
            expectedTermLength: preview.expectedTermLength,
            metricTargets: metricTargets,
            valueAlignments: valueAlignments,
            termId: nil  // Not supported in CSV import yet
        )
    }

    // MARK: - Helpers

    /// Auto-create a measure if it doesn't exist
    /// Attempts to infer measureType from common units
    private func createMeasure(unit: String) async throws -> UUID {
        let measureType = inferMeasureType(from: unit)
        let measureId = UUID()

        try await database.write { db in
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

    /// Infer measure type from unit name
    private func inferMeasureType(from unit: String) -> String {
        let lowercased = unit.lowercased()

        // Distance units
        if ["km", "kilometers", "mi", "miles", "m", "meters", "ft", "feet"].contains(lowercased) {
            return "distance"
        }

        // Time units
        if ["hours", "minutes", "seconds", "min", "sec", "hr", "h"].contains(lowercased) {
            return "time"
        }

        // Mass/weight units
        if ["kg", "kilograms", "lbs", "pounds", "g", "grams"].contains(lowercased) {
            return "mass"
        }

        // Energy units
        if ["kcal", "calories", "cal", "kj", "kilojoules"].contains(lowercased) {
            return "energy"
        }

        // Count units (default for unknown)
        return "count"
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]  // Just date, no time
        return formatter.date(from: string)
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

// MARK: - Supporting Types

struct GoalLookupTables {
    let measuresByUnit: [String: UUID]
    let valuesByName: [String: UUID]  // Lowercase names for matching
    let allValues: [PersonalValue]  // For fuzzy matching
}
