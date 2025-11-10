//
// ValueCSVService.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// CSV import/export for PersonalValues with embedded reference data in single file.
//
// TEMPLATE STRUCTURE (single file):
// 1. VALUE_LEVELS section - Reference table of valid value levels
// 2. IMPORT section - Actual data entry rows with numbered lines
//
// IMPORT SECTION:
// - Fields row: Column names
// - Optionality row: REQUIRED vs optional indicator
// - Sample row: Example data (skipped during import)
// - Numbered data rows (1-10): User fills these in
//
// COLUMNS:
// - title, description, notes, priority, level, life_domain, alignment_guidance
//
// SIMPLIFICATIONS vs GoalCSVService:
// - No lookup tables (no foreign keys to resolve)
// - No auto-creation (values are deliberate entities)
// - No fuzzy matching (direct field parsing)
// - Synchronous conversions (no database queries needed)
//

import Foundation
import Models
import SQLiteData

public final class ValueCSVService {
    private let database: any DatabaseWriter
    private let coordinator: PersonalValueCoordinator

    // MARK: - Initialization

    public init(database: any DatabaseWriter, coordinator: PersonalValueCoordinator) {
        self.database = database
        self.coordinator = coordinator
    }

    // MARK: - Export Template

    /// Export blank template with embedded reference data (single file)
    public func exportTemplate(to directory: URL) async throws -> URL {
        let templatePath = directory.appendingPathComponent("values_template.csv")
        try await exportBlankTemplate(to: templatePath)
        return templatePath
    }

    /// Export all existing values to CSV (filled template with reference data)
    public func exportValues(to directory: URL) async throws -> URL {
        let exportPath = directory.appendingPathComponent("values_export.csv")
        try await exportFilledTemplate(to: exportPath)
        return exportPath
    }

    // MARK: - Import (Using CSVEngine + ValueMapper)

    /// Parse CSV and generate preview (does not import)
    public func previewImport(from csvPath: URL) async throws -> CSVParseResult<ValuePreview> {
        // Parse CSV with CSVEngine
        let parsedData = try CSVEngine.parse(fileURL: csvPath)
        let mapper = ValueMapper()

        var previews: [ValuePreview] = []
        var errors: [String] = []

        for rowIndex in 0..<parsedData.count {
            let rowDict = parsedData.row(rowIndex)
            let rowNumber = rowIndex + 1

            do {
                // Map to FormData first
                let formData = try mapper.map(row: rowDict, rowNumber: rowNumber)

                // Convert to preview (using ValuePreview's structure)
                let preview = ValuePreview(
                    rowNumber: rowNumber,
                    title: formData.title,
                    detailedDescription: formData.detailedDescription,
                    freeformNotes: formData.freeformNotes,
                    priority: formData.priority,
                    valueLevel: formData.valueLevel,
                    lifeDomain: formData.lifeDomain,
                    alignmentGuidance: formData.alignmentGuidance,
                    validationStatus: .valid
                )
                previews.append(preview)
            } catch {
                errors.append("Row \(rowNumber): \(error.localizedDescription)")
            }
        }

        return CSVParseResult(previews: previews, errors: errors)
    }

    /// Import selected value previews
    public func importSelected(_ previews: [ValuePreview]) async throws -> CSVImportResult {
        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for preview in previews {
            do {
                // Re-map the preview data to FormData
                let formData = PersonalValueFormData(
                    title: preview.title,
                    detailedDescription: preview.detailedDescription,
                    freeformNotes: preview.freeformNotes,
                    valueLevel: preview.valueLevel,
                    priority: preview.priority,
                    lifeDomain: preview.lifeDomain,
                    alignmentGuidance: preview.alignmentGuidance
                )

                _ = try await coordinator.create(from: formData)
                successes += 1
            } catch {
                failures.append((preview.rowNumber, error.localizedDescription))
            }
        }

        return CSVImportResult(successes: successes, failures: failures)
    }

    /// Import values from CSV file (direct import, no preview)
    public func importValues(from csvPath: URL) async throws -> CSVImportResult {
        // Parse CSV with CSVEngine
        let parsedData = try CSVEngine.parse(fileURL: csvPath)
        let mapper = ValueMapper()

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

        // VALUE_LEVELS section (reference data)
        csv += ",VALUE_LEVELS,,,\n"
        csv += ",level,default_priority,description\n"

        // Write level options
        csv += ",general,40,Things you affirm as important\n"
        csv += ",major,10,Actionable values for goals/actions\n"
        csv += ",highest_order,1,Abstract philosophical values\n"
        csv += ",life_area,40,Structural domains\n"

        // Add blank rows between sections (8 columns to match IMPORT section)
        for _ in 0..<6 {
            csv += ",,,,,,,,\n"
        }

        // IMPORT Section (8 columns total)
        csv += ",IMPORT,,,,,,,\n"
        csv += "Fields,title,description,notes,priority,level,life_domain,alignment_guidance\n"
        csv += "Optionality,REQUIRED,optional,optional,optional,REQUIRED,optional,optional\n"
        csv +=
            "Sample,Physical Health,Regular exercise and nutrition,,5,major,Health,Exercise 3x/week\n"

        // Numbered data rows (1-10)
        for i in 1...10 {
            csv += "\(i),,,,,,,\n"
        }

        try csv.write(to: path, atomically: true, encoding: .utf8)
    }

    private func exportFilledTemplate(to path: URL) async throws {
        var csv = ""

        // Same reference section as blank template
        csv += ",VALUE_LEVELS,,,\n"
        csv += ",level,default_priority,description\n"
        csv += ",general,40,Things you affirm as important\n"
        csv += ",major,10,Actionable values for goals/actions\n"
        csv += ",highest_order,1,Abstract philosophical values\n"
        csv += ",life_area,40,Structural domains\n"

        for _ in 0..<6 {
            csv += ",,,,,,,,\n"
        }

        // IMPORT Section with actual data (8 columns total)
        csv += ",IMPORT,,,,,,,\n"
        csv += "Fields,title,description,notes,priority,level,life_domain,alignment_guidance\n"
        csv += "Optionality,REQUIRED,optional,optional,optional,REQUIRED,optional,optional\n"
        csv +=
            "Sample,Physical Health,Regular exercise and nutrition,,5,major,Health,Exercise 3x/week\n"

        // Fetch all existing values
        let values = try await database.read { db in
            try PersonalValue.all.order { $0.priority.asc() }.fetchAll(db)
        }

        // Write actual value data rows
        for (index, value) in values.enumerated() {
            let title = escapeCSV(value.title ?? "Untitled")
            let description = escapeCSV(value.detailedDescription ?? "")
            let notes = escapeCSV(value.freeformNotes ?? "")
            let priority = value.priority ?? value.valueLevel.defaultPriority
            let level = value.valueLevel.rawValue
            let lifeDomain = escapeCSV(value.lifeDomain ?? "")
            let alignmentGuidance = escapeCSV(value.alignmentGuidance ?? "")

            csv +=
                "\(index + 1),\(title),\(description),\(notes),\(priority),\(level),\(lifeDomain),\(alignmentGuidance)\n"
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
