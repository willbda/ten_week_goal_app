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

    // MARK: - Import

    /// Parse CSV and generate preview (does not import)
    /// Returns preview rows for user confirmation
    public func previewImport(from csvPath: URL) async throws -> CSVParseResult<ValuePreview> {
        let rows = try parseCSV(from: csvPath)

        var previews: [ValuePreview] = []
        var errors: [String] = []

        for row in rows {
            do {
                let preview = try convertToPreview(row)
                previews.append(preview)
            } catch {
                errors.append("Row \(row.lineNumber): \(error.localizedDescription)")
            }
        }

        return CSVParseResult(previews: previews, errors: errors)
    }

    /// Import selected value previews
    /// Only imports values where isSelected is true
    public func importSelected(_ previews: [ValuePreview]) async throws -> CSVImportResult {
        var successes = 0
        var failures: [(row: Int, error: String)] = []

        for preview in previews {
            do {
                let formData = convertPreviewToFormData(preview)
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
        csv += "Sample,Physical Health,Regular exercise and nutrition,,5,major,Health,Exercise 3x/week\n"

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
        csv += "Sample,Physical Health,Regular exercise and nutrition,,5,major,Health,Exercise 3x/week\n"

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

            csv += "\(index + 1),\(title),\(description),\(notes),\(priority),\(level),\(lifeDomain),\(alignmentGuidance)\n"
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

    // MARK: - Row Conversion

    private func convertToPreview(_ row: CSVRow) throws -> ValuePreview {
        // 1. Validate required fields
        guard let title = row.data["title"], !title.isEmpty else {
            throw CSVError.missingRequiredField(row: row.lineNumber, field: "title")
        }

        guard let levelString = row.data["level"], !levelString.isEmpty else {
            throw CSVError.missingRequiredField(row: row.lineNumber, field: "level")
        }

        // 2. Parse valueLevel enum
        guard let valueLevel = ValueLevel(rawValue: levelString.lowercased()) else {
            throw CSVError.invalidFormat("Invalid level '\(levelString)'. Must be: general, major, highest_order, life_area")
        }

        // 3. Parse optional priority
        let priority: Int?
        if let priorityString = row.data["priority"], !priorityString.isEmpty {
            if let p = Int(priorityString) {
                priority = p
            } else {
                throw CSVError.invalidFormat("Invalid priority '\(priorityString)'. Must be a number between 1-100")
            }
        } else {
            priority = nil  // Will use valueLevel.defaultPriority
        }

        // 4. Extract other fields (all optional)
        let description = row.data["description"]?.isEmpty == false ? row.data["description"] : nil
        let notes = row.data["notes"]?.isEmpty == false ? row.data["notes"] : nil
        let lifeDomain = row.data["life_domain"]?.isEmpty == false ? row.data["life_domain"] : nil
        let alignmentGuidance = row.data["alignment_guidance"]?.isEmpty == false ? row.data["alignment_guidance"] : nil

        // 5. Validate constraints
        var validationStatus: ValidationStatus = .valid

        if let p = priority, !(1...100).contains(p) {
            validationStatus = .error("Priority must be 1-100, got \(p)")
        }

        return ValuePreview(
            rowNumber: row.lineNumber,
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            priority: priority,
            valueLevel: valueLevel,
            lifeDomain: lifeDomain,
            alignmentGuidance: alignmentGuidance,
            validationStatus: validationStatus
        )
    }

    private func convertPreviewToFormData(_ preview: ValuePreview) -> ValueFormData {
        return ValueFormData(
            title: preview.valueTitle,
            detailedDescription: preview.detailedDescription,
            freeformNotes: preview.freeformNotes,
            valueLevel: preview.valueLevel,
            priority: preview.priority,
            lifeDomain: preview.lifeDomain,
            alignmentGuidance: preview.alignmentGuidance
        )
    }

    // MARK: - Helpers

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

// MARK: - CSVImportService Conformance

extension ValueCSVService: CSVImportService {
    public var entityName: String { "Value" }
    public var entityNamePlural: String { "Values" }

    public func exportAll(to directory: URL) async throws -> URL {
        try await exportValues(to: directory)
    }
}
