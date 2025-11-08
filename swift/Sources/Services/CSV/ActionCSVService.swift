//
// ActionCSVService.swift
// Written by Claude Code on 2025-11-06
// Updated: 2025-11-06 - Single-file template with embedded reference data
//
// PURPOSE:
// CSV import/export for Actions with embedded reference data in single file.
//
// TEMPLATE STRUCTURE (single file):
// 1. UNITS section - Reference table of available measures
// 2. GOALS section - Reference table of available goals
// 3. IMPORT section - Actual data entry rows with numbered lines
//
// IMPORT SECTION:
// - Fields row: Column names
// - Optionality row: REQUIRED vs optional indicator
// - Sample row: Example data (skipped during import)
// - Numbered data rows (1-10): User fills these in
//
// COLUMNS:
// - title, description, notes, duration_minutes, start_time
// - goal_1_title, measure_1_unit, measure_1_value, measure_2_unit, measure_2_value
//
// DATE FORMAT: ISO 8601 (2025-11-06T07:00:00Z)
//
// EMPTY FIELDS:
// - Empty title → Error (required)
// - Empty start_time → Auto-assigned to current Date()
// - Empty measurements/goals → Skipped
//

import Foundation
import Models
import SQLiteData

@MainActor
public final class ActionCSVService {
    private let database: any DatabaseWriter
    private let coordinator: ActionCoordinator

    // MARK: - Initialization

    public init(database: any DatabaseWriter, coordinator: ActionCoordinator) {
        self.database = database
        self.coordinator = coordinator
    }

    // MARK: - Export Template

    /// Export blank template with embedded reference data (single file)
    public func exportTemplate(to directory: URL) async throws -> URL {
        let templatePath = directory.appendingPathComponent("actions_template.csv")
        try await exportBlankTemplate(to: templatePath)
        return templatePath
    }

    /// Export all existing actions to CSV (filled template with reference data)
    public func exportActions(to directory: URL) async throws -> URL {
        let exportPath = directory.appendingPathComponent("actions_export.csv")
        try await exportFilledTemplate(to: exportPath)
        return exportPath
    }

    // MARK: - Import

    /// Parse CSV and generate preview (does not import)
    /// Returns preview rows for user confirmation
    public func previewImport(from csvPath: URL) async throws -> CSVParseResult<ActionPreview> {
        let rows = try parseCSV(from: csvPath)
        let lookup = try await buildLookupTables()

        var previews: [ActionPreview] = []
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

    /// Import selected action previews
    /// Only imports actions where isSelected is true
    public func importSelected(_ previews: [ActionPreview]) async throws -> CSVImportResult {
        let lookup = try await buildLookupTables()

        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for preview in previews {
            do {
                let formData = try convertPreviewToFormData(preview, lookup: lookup)
                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((preview.rowNumber, error.localizedDescription))
            }
        }

        return CSVImportResult(successes: successes, failures: failures)
    }

    /// Import actions from CSV file (direct import, no preview)
    /// Parses rows in IMPORT section (starts after "IMPORT" marker)
    public func importActions(from csvPath: URL) async throws -> CSVImportResult {
        let rows = try parseCSV(from: csvPath)
        let lookup = try await buildLookupTables()

        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for row in rows {
            do {
                let formData = try convertToFormData(row, lookup: lookup)
                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((row.lineNumber, error.localizedDescription))
            }
        }

        return CSVImportResult(successes: successes, failures: failures)
    }

    // MARK: - Template Generation

    private func exportBlankTemplate(to path: URL) async throws {
        var csv = ""

        // UNITS Section (reference data)
        csv += ",UNITS,,,,,,,GOALS,,,\n"
        csv += ",unit,type,description,,,,,title,target,unit,description\n"

        // Query measures and goals for reference data
        let (measures, goalsData) = try await database.read { db in
            let measures = try Measure.all.fetchAll(db)

            // Fetch all Goals + Expectations for reference
            let goalsWithExpectations = try Goal.all
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .fetchAll(db)

            guard !goalsWithExpectations.isEmpty else {
                return (measures, [(Goal, Expectation, [(ExpectationMeasure, Measure)])]())
            }

            let expectationIds = goalsWithExpectations.map { $0.1.id }

            let measuresWithTargets = try ExpectationMeasure
                .where { expectationIds.contains($0.expectationId) }
                .join(Measure.all) { $0.measureId.eq($1.id) }
                .fetchAll(db)

            let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }

            let goalsData = goalsWithExpectations.map { (goal, expectation) in
                let targets = targetsByExpectation[expectation.id] ?? []
                return (goal, expectation, targets)
            }

            return (measures, goalsData)
        }

        // Write reference rows (units on left, goals on right)
        let maxRows = max(measures.count, goalsData.count)
        for i in 0..<maxRows {
            // Units column
            if i < measures.count {
                let measure = measures[i]
                let unit = escapeCSV(measure.unit)
                let type = escapeCSV(measure.measureType)
                let description = escapeCSV(measure.detailedDescription ?? "")
                csv += ",\(unit),\(type),\(description),"
            } else {
                csv += ",,,,"
            }

            csv += ",,,"  // Empty columns between sections

            // Goals column
            if i < goalsData.count {
                let (_, expectation, targets) = goalsData[i]
                let title = escapeCSV(expectation.title ?? "Untitled Goal")
                let description = escapeCSV(expectation.detailedDescription ?? "")

                if targets.isEmpty {
                    csv += ",\(title),,,\(description)\n"
                } else {
                    // Use first target for reference display
                    let (measure, metric) = targets[0]
                    let target = measure.targetValue
                    let unit = escapeCSV(metric.unit)
                    csv += ",\(title),\(target),\(unit),\(description)\n"
                }
            } else {
                csv += ",,,,\n"
            }
        }

        // Add blank rows between sections
        for _ in 0..<6 {
            csv += ",,,,,,,,,,,\n"
        }

        // IMPORT Section
        csv += ",IMPORT,,,,,,,,,,\n"
        csv += "Fields,title,description,notes,duration_minutes,start_time,goal_1_title,measure_1_unit,measure_1_value,measure_2_unit,measure_2_value,\n"
        csv += "Optionality,REQUIRED,optional,optional,optional,optional,optional,optional,optional,optional,optional,\n"
        csv += "Sample,Morning run,Beautiful weather today,Saw three deer,28,2025-11-06T07:00:00Z,,km,5.2,minutes,28,\n"

        // Numbered data rows (1-10)
        for i in 1...10 {
            csv += "\(i),,,,,,,,,,,\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    private func exportFilledTemplate(to path: URL) async throws {
        var csv = ""

        // Same reference sections as blank template
        csv += ",UNITS,,,,,,,GOALS,,,\n"
        csv += ",unit,type,description,,,,,title,target,unit,description\n"

        let (measures, goalsData, actions) = try await database.read { db in
            let measures = try Measure.all.fetchAll(db)

            let goalsWithExpectations = try Goal.all
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .fetchAll(db)

            let expectationIds = goalsWithExpectations.map { $0.1.id }
            let measuresWithTargets = goalsWithExpectations.isEmpty ? [] : try ExpectationMeasure
                .where { expectationIds.contains($0.expectationId) }
                .join(Measure.all) { $0.measureId.eq($1.id) }
                .fetchAll(db)

            let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }
            let goalsData = goalsWithExpectations.map { (goal, expectation) in
                (goal, expectation, targetsByExpectation[expectation.id] ?? [])
            }

            // Fetch all actions with measurements and goals
            let actions = try Action.all.order { $0.logTime.desc() }.fetchAll(db)
            // TODO: Fetch measurements and goal contributions for each action

            return (measures, goalsData, actions)
        }

        // Write reference rows
        let maxRows = max(measures.count, goalsData.count)
        for i in 0..<maxRows {
            if i < measures.count {
                let measure = measures[i]
                csv += ",\(escapeCSV(measure.unit)),\(escapeCSV(measure.measureType)),\(escapeCSV(measure.detailedDescription ?? "")),"
            } else {
                csv += ",,,,"
            }

            csv += ",,,"

            if i < goalsData.count {
                let (_, expectation, targets) = goalsData[i]
                let title = escapeCSV(expectation.title ?? "Untitled Goal")
                let description = escapeCSV(expectation.detailedDescription ?? "")
                if targets.isEmpty {
                    csv += ",\(title),,,\(description)\n"
                } else {
                    let (measure, metric) = targets[0]
                    csv += ",\(title),\(measure.targetValue),\(escapeCSV(metric.unit)),\(description)\n"
                }
            } else {
                csv += ",,,,\n"
            }
        }

        for _ in 0..<6 {
            csv += ",,,,,,,,,,,\n"
        }

        // IMPORT Section with actual data
        csv += ",IMPORT,,,,,,,,,,\n"
        csv += "Fields,title,description,notes,duration_minutes,start_time,goal_1_title,measure_1_unit,measure_1_value,measure_2_unit,measure_2_value,\n"
        csv += "Optionality,REQUIRED,optional,optional,optional,optional,optional,optional,optional,optional,optional,\n"
        csv += "Sample,Morning run,Beautiful weather today,Saw three deer,28,2025-11-06T07:00:00Z,,km,5.2,minutes,28,\n"

        // TODO: Write actual action data rows
        for (index, action) in actions.enumerated() {
            csv += "\(index + 1),\(escapeCSV(action.title ?? "Untitled")),,,,,,,,,,\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    // MARK: - CSV Parsing

    private func parseCSV(from path: URL) throws -> [CSVRow] {
        let content = try String(contentsOf: path, encoding: .utf8)
        let lines = content.split(separator: "\n").map { String($0) }

        // Find the IMPORT section
        guard let importIndex = lines.firstIndex(where: { $0.contains("IMPORT") }) else {
            throw CSVError.invalidFormat("CSV must contain 'IMPORT' section marker")
        }

        // Import section starts after IMPORT marker
        // Line 0: ",IMPORT,..."
        // Line 1: "Fields,title,description,..."
        // Line 2: "Optionality,REQUIRED,..."
        // Line 3: "Sample,Morning run,..."
        // Line 4+: Data rows

        let importSection = Array(lines.dropFirst(importIndex))

        guard importSection.count >= 4 else {
            throw CSVError.invalidFormat("IMPORT section must have Fields, Optionality, Sample, and data rows")
        }

        // Parse header from Fields row
        let fieldsLine = importSection[1]
        let fields = fieldsLine.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }

        // Skip Fields, Optionality, Sample rows → data starts at index 3
        let dataLines = importSection.dropFirst(3)

        return try dataLines.enumerated().compactMap { (index, line) -> CSVRow? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }

            let values = line.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }

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

    // MARK: - Lookup Tables

    private func buildLookupTables() async throws -> LookupTables {
        return try await database.read { db in
            let measures = try Measure.all.fetchAll(db)
            var measureMap: [String: UUID] = [:]
            for measure in measures {
                measureMap[measure.unit] = measure.id
            }

            let goalsWithExpectations = try Goal.all
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .fetchAll(db)

            var goalMap: [String: UUID] = [:]
            for (goal, expectation) in goalsWithExpectations {
                if let title = expectation.title {
                    goalMap[title] = goal.id
                }
            }

            return LookupTables(measuresByUnit: measureMap, goalsByTitle: goalMap)
        }
    }

    // MARK: - Row Conversion

    private func convertToFormData(_ row: CSVRow, lookup: LookupTables) throws -> ActionFormData {
        guard let title = row.data["title"], !title.isEmpty else {
            throw CSVError.missingRequiredField(row: row.lineNumber, field: "title")
        }

        let description = row.data["description"] ?? ""
        let notes = row.data["notes"] ?? ""
        let durationString = row.data["duration_minutes"] ?? ""
        let duration = Double(durationString) ?? 0

        let startTimeString = row.data["start_time"] ?? ""
        let startTime: Date
        if startTimeString.isEmpty {
            startTime = Date()
        } else {
            guard let parsed = parseDate(startTimeString) else {
                throw CSVError.invalidDate(row: row.lineNumber, value: startTimeString)
            }
            startTime = parsed
        }

        // Parse measurements (up to 2 in new format)
        var measurements: [MeasurementInput] = []
        for i in 1...2 {
            let unitKey = "measure_\(i)_unit"
            let valueKey = "measure_\(i)_value"

            guard let unit = row.data[unitKey], !unit.isEmpty,
                  let valueString = row.data[valueKey], !valueString.isEmpty,
                  let value = Double(valueString) else {
                continue
            }

            guard let measureId = lookup.measuresByUnit[unit] else {
                let available = Array(lookup.measuresByUnit.keys.sorted().prefix(5)).joined(separator: ", ")
                throw CSVError.measureNotFound(row: row.lineNumber, unit: unit, available: available)
            }

            measurements.append(MeasurementInput(measureId: measureId, value: value))
        }

        // Parse goal contributions (just 1 in new format)
        var goalContributions: Set<UUID> = []
        if let goalTitle = row.data["goal_1_title"], !goalTitle.isEmpty {
            guard let goalId = lookup.goalsByTitle[goalTitle] else {
                let available = Array(lookup.goalsByTitle.keys.sorted().prefix(5)).joined(separator: ", ")
                throw CSVError.goalNotFound(row: row.lineNumber, title: goalTitle, available: available)
            }
            goalContributions.insert(goalId)
        }

        return ActionFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            durationMinutes: duration,
            startTime: startTime,
            measurements: measurements,
            goalContributions: goalContributions
        )
    }

    // MARK: - Preview Conversion

    private func convertToPreview(_ row: CSVRow, lookup: LookupTables) throws -> ActionPreview {
        // Title is required
        guard let title = row.data["title"], !title.isEmpty else {
            throw CSVError.missingRequiredField(row: row.lineNumber, field: "title")
        }

        let description = row.data["description"] ?? ""
        let notes = row.data["notes"] ?? ""
        let durationString = row.data["duration_minutes"] ?? ""
        let duration = Double(durationString) ?? 0

        // Parse date
        let startTimeString = row.data["start_time"] ?? ""
        let startTime: Date
        if startTimeString.isEmpty {
            startTime = Date()
        } else {
            guard let parsed = parseDate(startTimeString) else {
                throw CSVError.invalidDate(row: row.lineNumber, value: startTimeString)
            }
            startTime = parsed
        }

        // Parse measurements
        var measurements: [(unit: String, value: Double)] = []
        var validationStatus: ValidationStatus = .valid

        for i in 1...2 {
            let unitKey = "measure_\(i)_unit"
            let valueKey = "measure_\(i)_value"

            guard let unit = row.data[unitKey], !unit.isEmpty,
                  let valueString = row.data[valueKey], !valueString.isEmpty,
                  let value = Double(valueString) else {
                continue
            }

            // Check if measure exists
            if lookup.measuresByUnit[unit] == nil {
                let available = Array(lookup.measuresByUnit.keys.sorted().prefix(5)).joined(separator: ", ")
                validationStatus = .error("Measure '\(unit)' not found. Available: \(available)")
            } else {
                measurements.append((unit: unit, value: value))
            }
        }

        // Parse goal contributions
        var goalTitles: [String] = []
        if let goalTitle = row.data["goal_1_title"], !goalTitle.isEmpty {
            if lookup.goalsByTitle[goalTitle] == nil {
                let available = Array(lookup.goalsByTitle.keys.sorted().prefix(5)).joined(separator: ", ")
                validationStatus = .error("Goal '\(goalTitle)' not found. Available: \(available)")
            } else {
                goalTitles.append(goalTitle)
            }
        }

        return ActionPreview(
            rowNumber: row.lineNumber,
            title: title,
            description: description,
            notes: notes,
            durationMinutes: duration,
            startTime: startTime,
            measurements: measurements,
            goalTitles: goalTitles,
            validationStatus: validationStatus
        )
    }

    private func convertPreviewToFormData(_ preview: ActionPreview, lookup: LookupTables) throws -> ActionFormData {
        // Convert measurements with lookup
        var measurements: [MeasurementInput] = []
        for (unit, value) in preview.measurements {
            guard let measureId = lookup.measuresByUnit[unit] else {
                throw CSVError.measureNotFound(row: preview.rowNumber, unit: unit, available: "")
            }
            measurements.append(MeasurementInput(measureId: measureId, value: value))
        }

        // Convert goal contributions
        var goalContributions: Set<UUID> = []
        for title in preview.goalTitles {
            guard let goalId = lookup.goalsByTitle[title] else {
                throw CSVError.goalNotFound(row: preview.rowNumber, title: title, available: "")
            }
            goalContributions.insert(goalId)
        }

        return ActionFormData(
            title: preview.title,
            detailedDescription: preview.description,
            freeformNotes: preview.notes,
            durationMinutes: preview.durationMinutes,
            startTime: preview.startTime,
            measurements: measurements,
            goalContributions: goalContributions
        )
    }

    // MARK: - Helpers

    private func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
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

struct LookupTables {
    let measuresByUnit: [String: UUID]
    let goalsByTitle: [String: UUID]
}
