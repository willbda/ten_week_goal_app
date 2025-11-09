//
// ActionMapper.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Maps CSV rows to ActionFormData for ActionCoordinator.
// Handles field extraction, measurement parsing, goal lookups.
//

import Foundation
import Models
import SQLiteData

// MARK: - Action Mapper

/// Maps CSV rows to ActionFormData
public struct ActionMapper: CSVMapper {
    private let database: any DatabaseWriter  // Writer needed for auto-create measures

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    public func map(row: [String: String], rowNumber: Int) throws -> ActionFormData {
        // 1. Extract required fields
        guard let title = row["title"]?.nonEmpty else {
            throw MapError.missingRequired(row: rowNumber, field: "title")
        }

        // 2. Extract optional fields
        let description = row["description"]?.nonEmpty ?? ""
        let notes = row["notes"]?.nonEmpty ?? ""

        // 3. Parse duration (optional)
        let durationMinutes: Double
        if let durationStr = row["duration_minutes"]?.nonEmpty {
            guard let duration = Double(durationStr), duration >= 0 else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: "duration_minutes",
                    value: durationStr,
                    reason: "Must be non-negative number"
                )
            }
            durationMinutes = duration
        } else {
            durationMinutes = 0
        }

        // 4. Parse start time (optional, defaults to now)
        let startTime: Date
        if let startTimeStr = row["start_time"]?.nonEmpty {
            guard let parsedDate = parseISO8601(startTimeStr) else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: "start_time",
                    value: startTimeStr,
                    reason: "Expected ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ)"
                )
            }
            startTime = parsedDate
        } else {
            startTime = Date()
        }

        // 5. Parse measurements (measure_1_unit, measure_1_value, etc.)
        let measurements = try parseMeasurements(from: row, rowNumber: rowNumber)

        // 6. Parse goal contributions (goal_1_title, goal_2_title, etc.)
        let goalContributions = try parseGoalContributions(from: row, rowNumber: rowNumber)

        return ActionFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            durationMinutes: durationMinutes,
            startTime: startTime,
            measurements: measurements,
            goalContributions: goalContributions
        )
    }

    // MARK: - Measurement Parsing

    /// Parse measure_N_unit and measure_N_value columns
    private func parseMeasurements(
        from row: [String: String],
        rowNumber: Int
    ) throws -> [MeasurementInput] {
        var measurements: [MeasurementInput] = []

        // Look for measure_1_unit, measure_2_unit, etc.
        for i in 1...10 {  // Support up to 10 measurements
            let unitKey = "measure_\(i)_unit"
            let valueKey = "measure_\(i)_value"

            guard let unit = row[unitKey]?.nonEmpty else {
                // No more measurements
                break
            }

            guard let valueStr = row[valueKey]?.nonEmpty else {
                throw MapError.missingRequired(row: rowNumber, field: valueKey)
            }

            guard let value = Double(valueStr), value > 0 else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: valueKey,
                    value: valueStr,
                    reason: "Must be positive number"
                )
            }

            // Look up or create measure
            let measureId = try lookupOrCreateMeasure(unit: unit, rowNumber: rowNumber)

            measurements.append(MeasurementInput(measureId: measureId, value: value))
        }

        return measurements
    }

    /// Look up measure by unit, create if not found
    private func lookupOrCreateMeasure(unit: String, rowNumber: Int) throws -> UUID {
        // Try to find existing measure
        if let existingMeasure = try? database.read({ db in
            try Measure.all.where { $0.unit.eq(unit) }.fetchOne(db)
        }) {
            return existingMeasure.id
        }

        // Create new measure (auto-create pattern from GoalCSVService)
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

    // MARK: - Goal Contribution Parsing

    /// Parse goal_1_title, goal_2_title, etc.
    private func parseGoalContributions(
        from row: [String: String],
        rowNumber: Int
    ) throws -> Set<UUID> {
        var goalIds: Set<UUID> = []

        // Look for goal_1_title, goal_2_title, etc.
        for i in 1...10 {  // Support up to 10 goal contributions
            let goalKey = "goal_\(i)_title"

            guard let goalTitle = row[goalKey]?.nonEmpty else {
                // No more goals
                break
            }

            // Look up goal by title
            guard let goalId = try lookupGoalByTitle(goalTitle) else {
                throw MapError.lookupFailed(
                    row: rowNumber,
                    entity: "Goal",
                    identifier: goalTitle
                )
            }

            goalIds.insert(goalId)
        }

        return goalIds
    }

    /// Look up goal by exact title match
    private func lookupGoalByTitle(_ title: String) throws -> UUID? {
        return try database.read { db in
            // Join Goal with Expectation to get title
            let results = try Goal.all
                .join(Expectation.all) { goal, expectation in
                    goal.expectationId.eq(expectation.id)
                }
                .fetchAll(db)

            // Find exact match (case-insensitive)
            for (goal, expectation) in results {
                if expectation.title?.lowercased() == title.lowercased() {
                    return goal.id
                }
            }

            return nil
        }
    }

    // MARK: - Date Parsing

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
