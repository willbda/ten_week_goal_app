//
// ActionCSVService.swift
// Written by Claude Code on 2025-11-06
//
// PURPOSE:
// CSV import/export for Actions with reference sheets for measures and goals.
//
// EXPORT FORMAT (3 files):
// 1. actions_template.csv - Blank form OR filled with existing data
// 2. available_measures.csv - All measures from catalog (for reference)
// 3. available_goals.csv - All goals with titles (for reference)
//
// CSV STRUCTURE:
// - Header row: Column names
// - Required row: Indicates which fields are required (REQUIRED vs optional)
// - Sample row: Example data (import ignores this row)
// - Data rows: Actual actions
//
// COLUMNS (name-based, not positional):
// - title, description, notes, duration_minutes, start_time
// - measure_1_unit, measure_1_value, measure_2_unit, measure_2_value, measure_3_unit, measure_3_value
// - goal_1_title, goal_2_title, goal_3_title
//
// DATE FORMAT: ISO 8601 (2025-11-06T07:00:00Z) - matches Swift Date encoding
//
// EMPTY FIELDS:
// - Empty title → Error (required)
// - Empty start_time → Auto-assigned to current Date()
// - Empty measurements → No measurements added
// - Empty goals → No goal contributions
// - Empty duration_minutes → Treated as 0 (no duration tracked)
//
// DUPLICATE DETECTION:
// - If multiple rows have identical non-empty fields, warn and confirm
// - User chooses: "Add all" or "Add one per unique set"
// - Common case: Same title, different dates = NOT duplicates
// - Edge case: Same title, empty dates = Likely duplicates
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

    /// Export blank template with reference sheets
    /// Creates 3 files: template, measures reference, goals reference
    public func exportTemplate(to directory: URL) async throws -> ExportResult {
        // 1. Export blank template with header, required indicator, and sample row
        let templatePath = directory.appendingPathComponent("actions_template.csv")
        try await exportBlankTemplate(to: templatePath)

        // 2. Export measures reference sheet
        let measuresPath = directory.appendingPathComponent("available_measures.csv")
        try await exportMeasuresReference(to: measuresPath)

        // 3. Export goals reference sheet
        let goalsPath = directory.appendingPathComponent("available_goals.csv")
        try await exportGoalsReference(to: goalsPath)

        return ExportResult(
            templatePath: templatePath,
            measuresPath: measuresPath,
            goalsPath: goalsPath
        )
    }

    /// Export all existing actions to CSV (filled template)
    public func exportActions(to directory: URL) async throws -> ExportResult {
        let templatePath = directory.appendingPathComponent("actions_export.csv")
        try await exportFilledTemplate(to: templatePath)

        // Still include reference sheets
        let measuresPath = directory.appendingPathComponent("available_measures.csv")
        try await exportMeasuresReference(to: measuresPath)

        let goalsPath = directory.appendingPathComponent("available_goals.csv")
        try await exportGoalsReference(to: goalsPath)

        return ExportResult(
            templatePath: templatePath,
            measuresPath: measuresPath,
            goalsPath: goalsPath
        )
    }

    // MARK: - Import

    /// Import actions from CSV file
    /// - Parameter csvPath: Path to actions CSV
    /// - Returns: Import result with successes and failures
    public func importActions(from csvPath: URL) async throws -> ImportResult {
        // Parse CSV
        let rows = try parseCSV(from: csvPath)

        // Build lookup tables for resolution
        let lookup = try await buildLookupTables()

        // Detect duplicates
        if let duplicates = detectDuplicates(in: rows) {
            // TODO: Show confirmation dialog
            // For now, import all
            print("⚠️ Warning: Detected \(duplicates.count) potential duplicate groups")
        }

        // Import each row
        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for (index, row) in rows.enumerated() {
            do {
                // Convert CSV row to ActionFormData
                let formData = try convertToFormData(row, lookup: lookup)

                // Use coordinator to create
                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((index + 1, error.localizedDescription))
            }
        }

        return ImportResult(successes: successes, failures: failures)
    }

    // MARK: - Template Generation

    private func exportBlankTemplate(to path: URL) async throws {
        var csv = ""

        // Header row
        csv += "title,description,notes,duration_minutes,start_time,"
        csv += "measure_1_unit,measure_1_value,measure_2_unit,measure_2_value,measure_3_unit,measure_3_value,"
        csv += "goal_1_title,goal_2_title,goal_3_title\n"

        // Required indicator row
        csv += "REQUIRED,optional,optional,optional,optional,"
        csv += "optional,optional,optional,optional,optional,optional,"
        csv += "optional,optional,optional\n"

        // Sample row
        csv += "Morning run,Beautiful weather today,Saw three deer,28,2025-11-06T07:00:00Z,"
        csv += "km,5.2,minutes,28,,,,"
        csv += "Spring into Running,,\n"

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    private func exportFilledTemplate(to path: URL) async throws {
        var csv = ""

        // Header row
        csv += "title,description,notes,duration_minutes,start_time,"
        csv += "measure_1_unit,measure_1_value,measure_2_unit,measure_2_value,measure_3_unit,measure_3_value,"
        csv += "goal_1_title,goal_2_title,goal_3_title\n"

        // Required indicator row
        csv += "REQUIRED,optional,optional,optional,optional,"
        csv += "optional,optional,optional,optional,optional,optional,"
        csv += "optional,optional,optional\n"

        // Sample row
        csv += "Morning run,Beautiful weather today,Saw three deer,28,2025-11-06T07:00:00Z,"
        csv += "km,5.2,minutes,28,,,,"
        csv += "Spring into Running,,\n"

        // TODO: Query all actions with measurements and goals
        // TODO: Format each action as CSV row
        // TODO: Handle variable number of measurements (up to 3)

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    private func exportMeasuresReference(to path: URL) async throws {
        var csv = "unit,type,description\n"

        // Query all measures
        let measures = try await database.read { db in
            try Measure.all.fetchAll(db)
        }

        // Format each measure
        for measure in measures {
            let unit = escapeCSV(measure.unit)
            let type = escapeCSV(measure.measureType)
            let description = escapeCSV(measure.detailedDescription ?? "")
            csv += "\(unit),\(type),\(description)\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    private func exportGoalsReference(to path: URL) async throws {
        var csv = "title,target,unit,description\n"

        // Query all goals with expectations and measures
        let goalsData = try await database.read { db in
            // Fetch all Goals + Expectations
            let goalsWithExpectations = try Goal.all
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .fetchAll(db)

            guard !goalsWithExpectations.isEmpty else { return [(Goal, Expectation, [(ExpectationMeasure, Measure)])]() }

            // Collect expectation IDs for bulk fetch
            let expectationIds = goalsWithExpectations.map { $0.1.id }

            // Bulk fetch ExpectationMeasures + Measures
            let measuresWithTargets = try ExpectationMeasure
                .where { expectationIds.contains($0.expectationId) }
                .join(Measure.all) { $0.measureId.eq($1.id) }
                .fetchAll(db)

            // Group by expectation ID
            let targetsByExpectation = Dictionary(grouping: measuresWithTargets) { $0.0.expectationId }

            // Combine into result
            return goalsWithExpectations.map { (goal, expectation) in
                let targets = targetsByExpectation[expectation.id] ?? []
                return (goal, expectation, targets)
            }
        }

        // Format each goal (one row per metric target)
        for (_, expectation, targets) in goalsData {
            let title = escapeCSV(expectation.title ?? "Untitled Goal")
            let description = escapeCSV(expectation.detailedDescription ?? "")

            if targets.isEmpty {
                // Goal without metrics
                csv += "\(title),,,\(description)\n"
            } else {
                // One row per metric target
                for (measure, metric) in targets {
                    let target = measure.targetValue
                    let unit = escapeCSV(metric.unit)
                    csv += "\(title),\(target),\(unit),\(description)\n"
                }
            }
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    // MARK: - CSV Parsing

    private func parseCSV(from path: URL) throws -> [CSVRow] {
        let content = try String(contentsOf: path, encoding: .utf8)
        let lines = content.split(separator: "\n").map { String($0) }

        guard lines.count >= 3 else {
            throw CSVError.invalidFormat("CSV must have at least header, required, and sample rows")
        }

        // Parse header to get column indices
        let header = lines[0].split(separator: ",").map { String($0) }

        // Skip required indicator row (line 1) and sample row (line 2)
        let dataLines = lines.dropFirst(3)

        // Parse each data row
        return try dataLines.enumerated().compactMap { (index, line) -> CSVRow? in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil  // Skip empty rows
            }

            let values = line.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }

            guard values.count == header.count else {
                throw CSVError.columnMismatch(row: index + 4, expected: header.count, got: values.count)
            }

            // Build dictionary of column name → value
            var rowData: [String: String] = [:]
            for (col, value) in zip(header, values) {
                rowData[col] = value.trimmingCharacters(in: .whitespaces)
            }

            return CSVRow(lineNumber: index + 4, data: rowData)
        }
    }

    // MARK: - Lookup Tables

    private func buildLookupTables() async throws -> LookupTables {
        return try await database.read { db in
            // Build measure unit → UUID map
            let measures = try Measure.all.fetchAll(db)
            var measureMap: [String: UUID] = [:]
            for measure in measures {
                measureMap[measure.unit] = measure.id
            }

            // Build goal title → UUID map (Goal → Expectation)
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
        // Required: title
        guard let title = row.data["title"], !title.isEmpty else {
            throw CSVError.missingRequiredField(row: row.lineNumber, field: "title")
        }

        // Optional: description, notes
        let description = row.data["description"] ?? ""
        let notes = row.data["notes"] ?? ""

        // Optional: duration_minutes (default 0)
        let durationString = row.data["duration_minutes"] ?? ""
        let duration = Double(durationString) ?? 0

        // Optional: start_time (default to now if empty)
        let startTimeString = row.data["start_time"] ?? ""
        let startTime: Date
        if startTimeString.isEmpty {
            startTime = Date()  // Auto-assign current date if empty
        } else {
            guard let parsed = parseDate(startTimeString) else {
                throw CSVError.invalidDate(row: row.lineNumber, value: startTimeString)
            }
            startTime = parsed
        }

        // Parse measurements (up to 3)
        var measurements: [MeasurementInput] = []
        for i in 1...3 {
            let unitKey = "measure_\(i)_unit"
            let valueKey = "measure_\(i)_value"

            guard let unit = row.data[unitKey], !unit.isEmpty,
                  let valueString = row.data[valueKey], !valueString.isEmpty,
                  let value = Double(valueString) else {
                continue  // Skip empty measurements
            }

            // Lookup measureId by unit
            guard let measureId = lookup.measuresByUnit[unit] else {
                let available = Array(lookup.measuresByUnit.keys.sorted().prefix(5)).joined(separator: ", ")
                throw CSVError.measureNotFound(row: row.lineNumber, unit: unit, available: available)
            }

            measurements.append(MeasurementInput(measureId: measureId, value: value))
        }

        // Parse goal contributions (up to 3)
        var goalContributions: Set<UUID> = []
        for i in 1...3 {
            let titleKey = "goal_\(i)_title"

            guard let goalTitle = row.data[titleKey], !goalTitle.isEmpty else {
                continue  // Skip empty goals
            }

            // Lookup goalId by title
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

    // MARK: - Duplicate Detection

    private func detectDuplicates(in rows: [CSVRow]) -> [DuplicateGroup]? {
        // Group rows by title
        var groups: [String: [CSVRow]] = [:]
        for row in rows {
            if let title = row.data["title"], !title.isEmpty {
                groups[title, default: []].append(row)
            }
        }

        // Find groups with multiple rows
        let duplicates = groups.filter { $0.value.count > 1 }

        if duplicates.isEmpty {
            return nil
        }

        // Check if they're true duplicates (all fields match)
        return duplicates.compactMap { (title, rows) in
            // Check if all rows in this group have identical data
            let first = rows[0].data
            let allIdentical = rows.dropFirst().allSatisfy { $0.data == first }

            if allIdentical {
                return DuplicateGroup(title: title, rows: rows.map { $0.lineNumber })
            }
            return nil
        }
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

public struct ExportResult {
    public let templatePath: URL
    public let measuresPath: URL
    public let goalsPath: URL
}

public struct ImportResult {
    public let successes: Int
    public let failures: [(row: Int, error: String)]

    public var hasFailures: Bool {
        !failures.isEmpty
    }

    public var summary: String {
        if failures.isEmpty {
            return "✓ Successfully imported \(successes) actions"
        } else {
            return "⚠️ Imported \(successes) actions, \(failures.count) failed"
        }
    }
}

struct CSVRow {
    let lineNumber: Int
    let data: [String: String]  // Column name → value
}

struct LookupTables {
    let measuresByUnit: [String: UUID]
    let goalsByTitle: [String: UUID]
}

struct DuplicateGroup {
    let title: String
    let rows: [Int]
}

// MARK: - Errors

public enum CSVError: Error {
    case invalidFormat(String)
    case columnMismatch(row: Int, expected: Int, got: Int)
    case missingRequiredField(row: Int, field: String)
    case invalidDate(row: Int, value: String)
    case measureNotFound(row: Int, unit: String, available: String)
    case goalNotFound(row: Int, title: String, available: String)
}
