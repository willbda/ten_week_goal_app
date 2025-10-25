//  GetGoalsTool.swift
//  Tool for AI to query goals from the database
//
//  Written by Claude Code on 2025-10-23
//
//  This tool allows the Foundation Models LLM to fetch and search goals
//  from the GRDB database, with support for text search, type filtering,
//  and date range queries.

import Foundation
import GRDB
import Models
import Dependencies

#if canImport(FoundationModels)
import FoundationModels

/// Tool that fetches goals from the database for the AI assistant
///
/// The model can call this tool to access goal data when answering
/// questions about progress, targets, or goal-related insights.
///
/// Example queries the model might make:
/// - "Show me all SmartGoals"
/// - "Find goals with 'running' in the description"
/// - "What goals are active in July?"
@available(macOS 26.0, *)
struct GetGoalsTool: Tool {

    // MARK: - Tool Protocol

    let name = "getGoals"
    let description = "Fetch goals from the database with optional filters for search text, goal type, and date range"

    // MARK: - Properties

    @Dependency(\.defaultDatabase) var database

    // MARK: - Arguments

    /// Arguments the model can provide when calling this tool
    @Generable(description: "Parameters for fetching goals")
    struct Arguments {
        @Guide(description: "Optional text to search for in goal descriptions (case-insensitive)")
        var searchText: String?

        @Guide(description: "Filter by goal type: 'Goal', 'SmartGoal', or 'Milestone'")
        var goalType: String?

        @Guide(description: "Start date for filtering goals (ISO8601 format)")
        var startDate: String?

        @Guide(description: "End date for filtering goals (ISO8601 format)")
        var endDate: String?

        @Guide(description: "Maximum number of results to return", .range(1...100))
        var limit: Int = 50
    }

    // MARK: - Tool Execution

    /// Execute the tool with the provided arguments
    ///
    /// - Parameter arguments: Search parameters from the model
    /// - Returns: Formatted string describing the found goals
    func call(arguments: Arguments) async throws -> String {
        do {
            // Build SQL query with filters
            var sql = "SELECT * FROM goals WHERE 1=1"
            var queryArguments: [any DatabaseValueConvertible & Sendable] = []

            // Add search text filter if provided
            if let searchText = arguments.searchText, !searchText.isEmpty {
                sql += " AND (friendly_name LIKE ? OR description LIKE ?)"
                let searchPattern = "%\(searchText)%"
                queryArguments.append(searchPattern)
                queryArguments.append(searchPattern)
            }

            // Add goal type filter if provided
            if let goalType = arguments.goalType, !goalType.isEmpty {
                sql += " AND goal_type = ?"
                queryArguments.append(goalType)
            }

            // Add date range filters if provided
            if let startDate = arguments.startDate {
                sql += " AND (target_date >= ? OR target_date IS NULL)"
                queryArguments.append(startDate)
            }

            if let endDate = arguments.endDate {
                sql += " AND (start_date <= ? OR start_date IS NULL)"
                queryArguments.append(endDate)
            }

            // Add ordering and limit
            sql += " ORDER BY log_time DESC LIMIT ?"
            queryArguments.append(Int64(arguments.limit))

            // Fetch goals from database
            let goals: [Goal] = try await database.read { db in
                try Goal.fetchAll(db, sql: sql, arguments: StatementArguments(queryArguments))
            }

            // Format results for the model to understand
            if goals.isEmpty {
                return "No goals found matching the criteria."
            }

            var result = "Found \(goals.count) goal(s):\n\n"

            for goal in goals {
                result += formatGoal(goal)
                result += "\n---\n"
            }

            return result

        } catch {
            return "Error fetching goals: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Format a goal into a human-readable string
    private func formatGoal(_ goal: Goal) -> String {
        var lines: [String] = []

        // Title and type
        let title = goal.title ?? "Untitled Goal"
        // Goal type would need to be determined by checking which subtype this is
        let goalType = "Goal" // For now, just use base type
        lines.append("• \(title) [\(goalType)]")

        // Description if present
        if let description = goal.detailedDescription {
            lines.append("  Description: \(description)")
        }

        // Measurement target if present
        if let target = goal.measurementTarget,
           let unit = goal.measurementUnit {
            lines.append("  Target: \(target) \(unit)")
        }

        // Date range if present
        if let start = goal.startDate {
            lines.append("  Start: \(formatDate(start))")
        }
        if let target = goal.targetDate {
            lines.append("  Due: \(formatDate(target))")
        }

        // Relevance and actionability for SmartGoals
        if let relevance = goal.howGoalIsRelevant {
            lines.append("  Why it matters: \(relevance)")
        }
        if let actionable = goal.howGoalIsActionable {
            lines.append("  How to achieve: \(actionable)")
        }

        return lines.joined(separator: "\n")
    }

    /// Format a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Sendable

@available(macOS 26.0, *)
extension GetGoalsTool: Sendable {}

#endif // canImport(FoundationModels)