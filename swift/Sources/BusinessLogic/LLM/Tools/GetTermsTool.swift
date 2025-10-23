//  GetTermsTool.swift
//  Tool for AI to query ten-week terms from the database
//
//  Written by Claude Code on 2025-10-23
//
//  This tool allows the Foundation Models LLM to fetch and search terms
//  from the GRDB database, with support for filtering by status, term number,
//  and date range queries.

import Foundation
import GRDB
import Models
import Database

#if canImport(FoundationModels)
import FoundationModels

/// Tool that fetches ten-week terms from the database for the AI assistant
///
/// The model can call this tool to access term data when answering
/// questions about specific time periods, themes, and the goals associated
/// with different terms.
///
/// Example queries the model might make:
/// - "What was the theme of term 3?"
/// - "Show me the current active term"
/// - "What goals were assigned to the summer term?"
@available(macOS 26.0, *)
struct GetTermsTool: Tool {

    // MARK: - Tool Protocol

    let name = "getTerms"
    let description = "Fetch ten-week terms from the database with optional filters for term number, status, and dates"

    // MARK: - Properties

    let database: DatabaseManager

    // MARK: - Arguments

    /// Arguments the model can provide when calling this tool
    @Generable(description: "Parameters for fetching terms")
    struct Arguments {
        @Guide(description: "Filter by term number (e.g., 1, 2, 3)")
        var termNumber: Int?

        @Guide(description: "Filter by status: 'active', 'upcoming', 'completed', or 'all'")
        var status: String = "all"

        @Guide(description: "Start date for filtering terms (ISO8601 format)")
        var startDate: String?

        @Guide(description: "End date for filtering terms (ISO8601 format)")
        var endDate: String?

        @Guide(description: "Maximum number of results to return", .range(1...20))
        var limit: Int = 10
    }

    // MARK: - Tool Execution

    /// Execute the tool with the provided arguments
    ///
    /// - Parameter arguments: Search parameters from the model
    /// - Returns: Formatted string describing the found terms
    func call(arguments: Arguments) async throws -> String {
        do {
            let now = Date()
            let nowString = ISO8601DateFormatter().string(from: now)

            // Build SQL query with filters
            var sql = "SELECT * FROM terms WHERE 1=1"
            var queryArguments: [any DatabaseValueConvertible & Sendable] = []

            // Add term number filter if provided
            if let termNumber = arguments.termNumber {
                sql += " AND term_number = ?"
                queryArguments.append(Int64(termNumber))
            }

            // Add status filter
            switch arguments.status.lowercased() {
            case "active":
                sql += " AND start_date <= ? AND target_date >= ?"
                queryArguments.append(nowString)
                queryArguments.append(nowString)
            case "upcoming":
                sql += " AND start_date > ?"
                queryArguments.append(nowString)
            case "completed":
                sql += " AND target_date < ?"
                queryArguments.append(nowString)
            case "all":
                // No additional filter
                break
            default:
                // Invalid status, treat as 'all'
                break
            }

            // Add date range filters if provided
            if let startDate = arguments.startDate {
                sql += " AND target_date >= ?"
                queryArguments.append(startDate)
            }

            if let endDate = arguments.endDate {
                sql += " AND start_date <= ?"
                queryArguments.append(endDate)
            }

            // Add ordering and limit
            sql += " ORDER BY term_number DESC LIMIT ?"
            queryArguments.append(Int64(arguments.limit))

            // Fetch terms from database
            let terms: [GoalTerm] = try await database.fetch(
                GoalTerm.self,
                sql: sql,
                arguments: queryArguments
            )

            // Format results for the model to understand
            if terms.isEmpty {
                return "No terms found matching the criteria."
            }

            var result = "Found \(terms.count) term(s):\n\n"

            for term in terms {
                result += await formatTerm(term)
                result += "\n---\n"
            }

            return result

        } catch {
            return "Error fetching terms: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Format a term into a human-readable string
    private func formatTerm(_ term: GoalTerm) async -> String {
        var lines: [String] = []

        // Term number and theme
        lines.append("• Term \(term.termNumber)")
        if let theme = term.theme {
            lines.append("  Theme: \(theme)")
        }

        // Date range
        lines.append("  Period: \(formatDate(term.startDate)) - \(formatDate(term.targetDate))")

        // Status
        let now = Date()
        if term.startDate > now {
            lines.append("  Status: Upcoming")
        } else if term.targetDate < now {
            lines.append("  Status: Completed")
        } else {
            lines.append("  Status: Active")
        }

        // Goals assigned to this term
        let goalIds = term.termGoalsByID
        if !goalIds.isEmpty {
            lines.append("  Assigned Goals (\(goalIds.count)):")

            // Fetch goal names for better readability
            do {
                for goalId in goalIds.prefix(5) {  // Show first 5 goals
                    // goalId is already a UUID, no need to convert from string
                    if let goal = try await database.fetchOne(Goal.self, id: goalId) {
                        let goalName = goal.title ?? "Untitled"
                        lines.append("    - \(goalName)")
                    }
                }
                if goalIds.count > 5 {
                    lines.append("    ... and \(goalIds.count - 5) more")
                }
            } catch {
                // Fallback to just showing IDs
                for goalId in goalIds.prefix(3) {
                    lines.append("    - Goal ID: \(goalId)")
                }
            }
        } else {
            lines.append("  No goals assigned yet")
        }

        // Reflection if present
        if let reflection = term.reflection {
            lines.append("  Reflection: \(reflection)")
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
extension GetTermsTool: Sendable {}

#endif // canImport(FoundationModels)