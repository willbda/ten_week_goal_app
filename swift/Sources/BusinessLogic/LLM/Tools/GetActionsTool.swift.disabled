//  GetActionsTool.swift
//  Tool for AI to query actions from the database
//
//  Written by Claude Code on 2025-10-23
//
//  This tool allows the Foundation Models LLM to fetch and search actions
//  from the GRDB database, with support for text search, measurement filters,
//  and date range queries.

import Foundation
import GRDB
import Models
import Dependencies

#if canImport(FoundationModels)
import FoundationModels

/// Tool that fetches actions from the database for the AI assistant
///
/// The model can call this tool to access action data when answering
/// questions about what the user has accomplished, patterns in their
/// activities, or progress toward goals.
///
/// Example queries the model might make:
/// - "Show me all running actions from July"
/// - "Find actions with measurements"
/// - "What did I accomplish last week?"
@available(macOS 26.0, *)
struct GetActionsTool: Tool {

    // MARK: - Tool Protocol

    let name = "getActions"
    let description = "Fetch actions from the database with optional filters for search text, measurements, and date range"

    // MARK: - Properties

    @Dependency(\.defaultDatabase) var database

    // MARK: - Arguments

    /// Arguments the model can provide when calling this tool
    @Generable(description: "Parameters for fetching actions")
    struct Arguments {
        @Guide(description: "Optional text to search for in action descriptions (case-insensitive)")
        var searchText: String?

        @Guide(description: "Filter to only show actions with measurements (true/false)")
        var hasMeasurements: Bool?

        @Guide(description: "Start date for filtering actions (ISO8601 format)")
        var startDate: String?

        @Guide(description: "End date for filtering actions (ISO8601 format)")
        var endDate: String?

        @Guide(description: "Maximum number of results to return", .range(1...100))
        var limit: Int = 50
    }

    // MARK: - Tool Execution

    /// Execute the tool with the provided arguments
    ///
    /// - Parameter arguments: Search parameters from the model
    /// - Returns: Formatted string describing the found actions
    func call(arguments: Arguments) async throws -> String {
        do {
            // Build SQL query with filters
            var sql = "SELECT * FROM actions WHERE 1=1"
            var queryArguments: [any DatabaseValueConvertible & Sendable] = []

            // Add search text filter if provided
            if let searchText = arguments.searchText, !searchText.isEmpty {
                sql += " AND (friendly_name LIKE ? OR description LIKE ?)"
                let searchPattern = "%\(searchText)%"
                queryArguments.append(searchPattern)
                queryArguments.append(searchPattern)
            }

            // Add measurements filter if provided
            if let hasMeasurements = arguments.hasMeasurements {
                if hasMeasurements {
                    sql += " AND measurement_units_by_amount IS NOT NULL"
                    sql += " AND measurement_units_by_amount != '{}'"
                } else {
                    sql += " AND (measurement_units_by_amount IS NULL"
                    sql += " OR measurement_units_by_amount = '{}')"
                }
            }

            // Add date range filters if provided
            if let startDate = arguments.startDate {
                sql += " AND log_time >= ?"
                queryArguments.append(startDate)
            }

            if let endDate = arguments.endDate {
                sql += " AND log_time <= ?"
                queryArguments.append(endDate)
            }

            // Add ordering and limit
            sql += " ORDER BY log_time DESC LIMIT ?"
            queryArguments.append(Int64(arguments.limit))

            // Fetch actions from database
            let actions: [Action] = try await database.read { db in
                try Action.fetchAll(db, sql: sql, arguments: StatementArguments(queryArguments))
            }

            // Format results for the model to understand
            if actions.isEmpty {
                return "No actions found matching the criteria."
            }

            var result = "Found \(actions.count) action(s):\n\n"

            for action in actions {
                result += formatAction(action)
                result += "\n---\n"
            }

            return result

        } catch {
            return "Error fetching actions: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Format an action into a human-readable string
    private func formatAction(_ action: Action) -> String {
        var lines: [String] = []

        // Title
        let title = action.title ?? "Untitled Action"
        lines.append("• \(title)")

        // Description if present
        if let description = action.detailedDescription {
            lines.append("  Description: \(description)")
        }

        // Timestamp
        lines.append("  Logged: \(formatDate(action.logTime))")

        // Duration if present
        if let duration = action.durationMinutes {
            lines.append("  Duration: \(formatDuration(duration))")
        }

        // Start time if different from log time
        if let startTime = action.startTime,
           startTime != action.logTime {
            lines.append("  Started: \(formatDate(startTime))")
        }

        // Measurements if present
        if let measurements = action.measuresByUnit,
           !measurements.isEmpty {
            lines.append("  Measurements:")
            for (unit, amount) in measurements {
                lines.append("    - \(amount) \(unit)")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Format a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Format duration in minutes to a readable string
    private func formatDuration(_ minutes: Double) -> String {
        if minutes < 60 {
            return "\(Int(minutes)) minutes"
        } else {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            if mins == 0 {
                return "\(hours) hour(s)"
            } else {
                return "\(hours) hour(s) \(mins) minutes"
            }
        }
    }
}

// MARK: - Sendable

@available(macOS 26.0, *)
extension GetActionsTool: Sendable {}

#endif // canImport(FoundationModels)