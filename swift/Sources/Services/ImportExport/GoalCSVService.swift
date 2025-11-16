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

// REMOVED @MainActor: CSV parsing and file I/O are background operations
// that shouldn't block the main thread. File reading/writing is I/O-bound
// work that benefits from running off the main actor.
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

    // MARK: - Import (Using CSVEngine + GoalMapper)

    /// Parse CSV and generate preview (does not import)
    public func previewImport(from csvPath: URL) async throws -> CSVParseResult<GoalPreview> {
        // Parse CSV with CSVEngine
        let parsedData = try CSVEngine.parse(fileURL: csvPath)
        let mapper = GoalMapper(database: database)

        var previews: [GoalPreview] = []
        var errors: [String] = []

        for rowIndex in 0..<parsedData.count {
            let rowDict = parsedData.row(rowIndex)
            let rowNumber = rowIndex + 1

            do {
                // Map to FormData first
                let formData = try mapper.map(row: rowDict, rowNumber: rowNumber)

                // Convert to preview (using GoalPreview's structure)
                let preview = GoalPreview(
                    rowNumber: rowNumber,
                    title: formData.title,
                    description: formData.detailedDescription,
                    notes: formData.freeformNotes,
                    expectationImportance: formData.expectationImportance,
                    expectationUrgency: formData.expectationUrgency,
                    startDate: formData.startDate,
                    targetDate: formData.targetDate,
                    actionPlan: formData.actionPlan,
                    expectedTermLength: formData.expectedTermLength,
                    targets: formData.metricTargets.map { ($0.measureId?.uuidString ?? "", $0.targetValue) },
                    valueNames: formData.valueAlignments.map { $0.valueId?.uuidString ?? "" },
                    termNumber: nil,
                    validationStatus: .valid
                )
                previews.append(preview)
            } catch {
                errors.append("Row \(rowNumber): \(error.localizedDescription)")
            }
        }

        return CSVParseResult(previews: previews, errors: errors)
    }

    /// Import selected goal previews
    public func importSelected(_ previews: [GoalPreview]) async throws -> CSVImportResult {
        let mapper = GoalMapper(database: database)
        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for preview in previews {
            do {
                // Reconstruct metric targets from preview
                var metricTargets: [MetricTargetInput] = []
                for (measureIdString, targetValue) in preview.targets {
                    if let measureId = UUID(uuidString: measureIdString) {
                        metricTargets.append(MetricTargetInput(measureId: measureId, targetValue: targetValue))
                    }
                }

                // Reconstruct value alignments from preview
                var valueAlignments: [ValueAlignmentInput] = []
                for valueIdString in preview.valueNames {
                    if let valueId = UUID(uuidString: valueIdString) {
                        valueAlignments.append(ValueAlignmentInput(valueId: valueId, alignmentStrength: 5))
                    }
                }

                let formData = GoalFormData(
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
                    termId: nil
                )

                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((preview.rowNumber, error.localizedDescription))
            }
        }

        return CSVImportResult(successes: successes, failures: failures)
    }

    /// Import goals from CSV file (direct import, no preview)
    public func importGoals(from csvPath: URL) async throws -> CSVImportResult {
        // Parse CSV with CSVEngine
        let parsedData = try CSVEngine.parse(fileURL: csvPath)
        let mapper = GoalMapper(database: database)

        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for rowIndex in 0..<parsedData.count {
            let rowDict = parsedData.row(rowIndex)
            let rowNumber = rowIndex + 1

            do {
                let formData = try mapper.map(row: rowDict, rowNumber: rowNumber)
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

}

    // MARK: - CSV Helper

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
