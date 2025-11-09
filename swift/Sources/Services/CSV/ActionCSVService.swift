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

    // MARK: - Import (Using CSVEngine + ActionMapper)

    /// Parse CSV and generate preview (does not import)
    /// Returns preview rows for user confirmation
    public func previewImport(from csvPath: URL) async throws -> CSVParseResult<ActionPreview> {
        // Parse CSV with CSVEngine
        let parsedData = try CSVEngine.parse(fileURL: csvPath)
        let mapper = ActionMapper(database: database)

        var previews: [ActionPreview] = []
        var errors: [String] = []

        for rowIndex in 0..<parsedData.count {
            let rowDict = parsedData.row(rowIndex)
            let rowNumber = rowIndex + 1

            do {
                // Map to FormData first
                let formData = try mapper.map(row: rowDict, rowNumber: rowNumber)

                // Convert to preview (using ActionPreview's structure)
                let preview = ActionPreview(
                    rowNumber: rowNumber,
                    title: formData.title,
                    description: formData.detailedDescription,
                    notes: formData.freeformNotes,
                    durationMinutes: formData.durationMinutes,
                    startTime: formData.startTime,
                    measurements: formData.measurements.map { ($0.measureId?.uuidString ?? "", $0.value) },
                    goalTitles: Array(formData.goalContributions).map { $0.uuidString },  // TODO: lookup titles
                    validationStatus: .valid
                )
                previews.append(preview)
            } catch {
                errors.append("Row \(rowNumber): \(error.localizedDescription)")
            }
        }

        return CSVParseResult(previews: previews, errors: errors)
    }

    /// Import selected action previews
    /// Note: This requires re-parsing from the original CSV to get measurements & goals
    /// If you have the CSV path available, use importActions() instead for better performance
    public func importSelected(_ previews: [ActionPreview]) async throws -> CSVImportResult {
        // Since preview doesn't preserve measurements/goals fully,
        // we need to reconstruct from the limited data we have
        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for preview in previews {
            do {
                // Reconstruct measurements from preview (UUIDs stored as strings)
                var measurements: [MeasurementInput] = []
                for (measureIdString, value) in preview.measurements {
                    if let measureId = UUID(uuidString: measureIdString) {
                        measurements.append(MeasurementInput(measureId: measureId, value: value))
                    }
                }

                // Reconstruct goal contributions from preview (UUIDs stored as strings)
                var goalContributions: Set<UUID> = []
                for goalIdString in preview.goalTitles {
                    if let goalId = UUID(uuidString: goalIdString) {
                        goalContributions.insert(goalId)
                    }
                }

                let formData = ActionFormData(
                    title: preview.title,
                    detailedDescription: preview.description,
                    freeformNotes: preview.notes,
                    durationMinutes: preview.durationMinutes,
                    startTime: preview.startTime,
                    measurements: measurements,
                    goalContributions: goalContributions
                )

                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((preview.rowNumber, error.localizedDescription))
            }
        }

        return CSVImportResult(successes: successes, failures: failures)
    }

    /// Import actions from CSV file using robust CSVEngine (direct import, no preview)
    public func importActions(from csvPath: URL) async throws -> CSVImportResult {
        // 1. Parse CSV with CSVEngine (handles encoding, line endings, quotes)
        let parsedData = try CSVEngine.parse(fileURL: csvPath)

        // 2. Map rows to FormData using ActionMapper
        let mapper = ActionMapper(database: database)
        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for rowIndex in 0..<parsedData.count {
            let rowDict = parsedData.row(rowIndex)
            let rowNumber = rowIndex + 1  // User-facing row numbers start at 1

            do {
                let formData = try mapper.map(row: rowDict, rowNumber: rowNumber)

                // 3. Import via coordinator
                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((rowNumber, error.localizedDescription))
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

            // Fetch all actions
            let actions = try Action.all.order { $0.logTime.desc() }.fetchAll(db)

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

        // Write actual action data rows
        for (index, action) in actions.enumerated() {
            let title = escapeCSV(action.title ?? "")
            let description = escapeCSV(action.detailedDescription ?? "")
            let notes = escapeCSV(action.freeformNotes ?? "")
            let duration = action.durationMinutes.map { String($0) } ?? ""

            // Format start time as ISO 8601
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let startTime = action.startTime.map { formatter.string(from: $0) } ?? ""

            // TODO: Fetch measurements and goal contributions for this action
            // For now, export without measurements/goals (user can add manually)
            csv += "\(index + 1),\(title),\(description),\(notes),\(duration),\(startTime),,,,,\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    // MARK: - CSV Helper

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
