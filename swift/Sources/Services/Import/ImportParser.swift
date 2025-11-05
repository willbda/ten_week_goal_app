//
// ImportParser.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Parse flexible input formats (CSV, TSV, simple lists) into staged data structures.
// Auto-detects format and intelligently infers metadata.
//
// SUPPORTED FORMATS:
//
// VALUES:
//   Simple list: "Health & Vitality\nIntellectual Growth"
//   CSV: "Health & Vitality,major,90,Physical wellbeing"
//   TSV: "Health & Vitality\tmajor\t90\tPhysical wellbeing"
//
// MEASURES:
//   Simple: "km,distance,Distance in kilometers"
//   Infers measureType from unit name
//
// GOALS:
//   Format: "Title | Target | Unit | Values"
//   Example: "Run 120km | 120 | km | Health, Movement"
//
// ACTIONS:
//   Format: "Title | Date | Measure:Value | Goals"
//   Example: "Morning run | 2025-11-03 | km:5.2 | Run 120km"
//
// USAGE:
// ```swift
// let input = "Health & Vitality\nIntellectual Growth"
// let values = try ImportParser.parseValues(input)
// // Returns: [StagedValue(...), StagedValue(...)]
// ```
//

import Foundation
import Models

public struct ImportParser {
    // MARK: - Values Parsing

    /// Parse values from flexible input
    public static func parseValues(_ input: String) throws -> [StagedValue] {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Try CSV first (if contains comma or tab)
        if input.contains(",") || input.contains("\t") {
            return try parseValuesCSV(input)
        }

        // Fall back to simple list
        return parseValuesSimpleList(input)
    }

    private static func parseValuesCSV(_ input: String) throws -> [StagedValue] {
        let lines = input.split(separator: "\n").map { String($0) }
        guard !lines.isEmpty else { return [] }

        // Auto-detect separator (comma or tab)
        let separator: Character = input.contains("\t") ? "\t" : ","

        // Check if first line is header (contains "title" or "level")
        let firstLine = lines[0].lowercased()
        let hasHeader = firstLine.contains("title") || firstLine.contains("level")
        let dataLines = hasHeader ? Array(lines.dropFirst()) : lines

        return dataLines.compactMap { line in
            let parts = line.split(separator: separator).map { $0.trimmingCharacters(in: .whitespaces) }
            guard !parts.isEmpty else { return nil }

            // Parse columns: title, [level], [priority], [description]
            let title = parts[0]
            let level: ValueLevel = parts.count > 1 ? ValueLevel(rawValue: parts[1]) ?? .general : .general
            let priority: Int = parts.count > 2 ? Int(parts[2]) ?? 50 : 50
            let description: String? = parts.count > 3 ? parts[3] : nil

            return StagedValue(
                title: title,
                level: level,
                priority: priority,
                detailedDescription: description,
                originalInput: line
            )
        }
    }

    private static func parseValuesSimpleList(_ input: String) -> [StagedValue] {
        input.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }

            return StagedValue(
                title: trimmed,
                level: inferValueLevel(from: trimmed),
                priority: 50,
                originalInput: trimmed
            )
        }
    }

    /// Infer value level from text characteristics
    private static func inferValueLevel(from text: String) -> ValueLevel {
        // TODO: Implement smart inference
        // - Length-based: >100 chars = highestOrder
        // - Keyword-based: "core", "fundamental" = highestOrder
        // - Default: general
        .general
    }

    // MARK: - Measures Parsing

    public static func parseMeasures(_ input: String) throws -> [StagedMeasure] {
        let lines = input.split(separator: "\n").map { String($0) }
        guard !lines.isEmpty else { return [] }

        // Auto-detect separator (comma or tab)
        let separator: Character = input.contains("\t") ? "\t" : ","

        // Check if first line is header
        let firstLine = lines[0].lowercased()
        let hasHeader = firstLine.contains("unit") || firstLine.contains("type")
        let dataLines = hasHeader ? Array(lines.dropFirst()) : lines

        return dataLines.compactMap { line -> StagedMeasure? in
            let parts = line.split(separator: separator).map { $0.trimmingCharacters(in: .whitespaces) }
            guard !parts.isEmpty else { return nil }

            // Parse columns: unit, [measureType], [description]
            let unit = parts[0]
            let measureType: String = parts.count > 1 && !parts[1].isEmpty
                ? parts[1]
                : inferMeasureType(from: unit)
            let description: String? = parts.count > 2 ? parts[2] : nil

            return StagedMeasure(
                unit: unit,
                measureType: measureType,
                detailedDescription: description,
                originalInput: line
            )
        }
    }

    /// Infer measure type from unit name
    private static func inferMeasureType(from unit: String) -> String {
        let lower = unit.lowercased()

        // Distance units
        if ["km", "kilometers", "mile", "miles", "m", "meters"].contains(lower) {
            return "distance"
        }

        // Time units
        if ["min", "minutes", "hour", "hours", "sec", "seconds"].contains(lower) {
            return "time"
        }

        // Mass units
        if ["kg", "kilograms", "lb", "pounds", "g", "grams"].contains(lower) {
            return "mass"
        }

        // Default to count
        return "count"
    }

    // MARK: - Goals Parsing

    public static func parseGoals(
        _ input: String,
        stagedMeasures: [StagedMeasure],
        stagedValues: [StagedValue]
    ) throws -> [StagedGoal] {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lines = input.split(separator: "\n").map { String($0) }

        return lines.compactMap { line -> StagedGoal? in
            // Format: "Title | TargetValue | Unit | ValueNames"
            // Example: "Run 120km | 120 | km | Health, Movement"
            let parts = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 3 else { return nil }

            let title = parts[0]
            guard let targetValue = Double(parts[1]) else { return nil }
            let unitInput = parts[2]

            // Parse value references (optional, comma-separated)
            let valueInputs = parts.count > 3
                ? parts[3].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                : []

            // Create unresolved references (will be resolved later)
            let measureRef = MeasureReference.unresolved(unitInput)
            let valueRefs = valueInputs.map { ValueReference(input: String($0)) }

            return StagedGoal(
                title: title,
                targetValue: targetValue,
                measureRef: measureRef,
                valueRefs: valueRefs,
                status: .needsResolution
            )
        }
    }

    // MARK: - Actions Parsing

    public static func parseActions(
        _ input: String,
        stagedMeasures: [StagedMeasure],
        stagedGoals: [StagedGoal]
    ) throws -> [StagedAction] {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lines = input.split(separator: "\n").map { String($0) }

        return lines.compactMap { line -> StagedAction? in
            // Format: "Title | Date | Measurements | Goals"
            // Example: "Morning run | 2025-11-03 | km:5.2,minutes:28 | Run 120km"
            let parts = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 2 else { return nil }

            let title = parts[0]
            guard let date = parseDate(parts[1]) else { return nil }

            // Parse measurements (unit:value pairs, comma-separated)
            let measurements = parts.count > 2
                ? parseMeasurements(parts[2])
                : []

            // Parse goal references (comma-separated goal titles)
            let goalInputs = parts.count > 3
                ? parts[3].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                : []

            let goalRefs = goalInputs.map { GoalReference(input: String($0)) }

            return StagedAction(
                title: title,
                date: date,
                measurements: measurements,
                goalRefs: goalRefs,
                status: .needsResolution
            )
        }
    }

    // MARK: - Helpers

    private static func parseDate(_ input: String) -> Date? {
        // Try ISO8601 format first: "2025-11-03"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: input) {
            return date
        }

        // Try with time: "2025-11-03 14:30"
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = formatter.date(from: input) {
            return date
        }

        return nil
    }

    private static func parseMeasurements(_ input: String) -> [StagedMeasurement] {
        // Format: "km:5.2,minutes:28"
        input.split(separator: ",").compactMap { part in
            let components = part.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard components.count == 2,
                  let value = Double(components[1]) else {
                return nil
            }

            let unit = components[0]
            return StagedMeasurement(
                measureRef: .unresolved(unit),
                value: value
            )
        }
    }
}

// MARK: - Date Parsing
// Supports: "2025-11-03" or "2025-11-03 14:30"
