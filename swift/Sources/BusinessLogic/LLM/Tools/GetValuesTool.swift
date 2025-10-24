//  GetValuesTool.swift
//  Tool for AI to query values from the database
//
//  Written by Claude Code on 2025-10-23
//
//  This tool allows the Foundation Models LLM to fetch and search values
//  from the GRDB database, with support for filtering by type, life domain,
//  and priority range.

import Foundation
import GRDB
import Models
import Database

#if canImport(FoundationModels)
import FoundationModels

/// Tool that fetches personal values from the database for the AI assistant
///
/// The model can call this tool to access value data when answering
/// questions about motivations, priorities, life domains, and what drives
/// the user's goal-setting behavior.
///
/// Example queries the model might make:
/// - "What are the highest priority values?"
/// - "Show me all values related to Health"
/// - "What MajorValues guide the goal decisions?"
@available(macOS 26.0, *)
struct GetValuesTool: Tool {

    // MARK: - Tool Protocol

    let name = "getValues"
    let description = "Fetch personal values from the database with optional filters for type, life domain, and priority"

    // MARK: - Properties

    let database: DatabaseManager

    // MARK: - Arguments

    /// Arguments the model can provide when calling this tool
    @Generable(description: "Parameters for fetching values")
    struct Arguments {
        @Guide(description: "Filter by value type: 'Value', 'MajorValue', or 'HighestOrderValue'")
        var valueType: String?

        @Guide(description: "Filter by life domain: 'Health', 'Family', 'Career', 'Personal', 'Financial', 'Social', 'Spiritual', 'Learning', etc.")
        var lifeDomain: String?

        @Guide(description: "Minimum priority level (1-100)")
        var minPriority: Int?

        @Guide(description: "Maximum priority level (1-100)")
        var maxPriority: Int?

        @Guide(description: "Maximum number of results to return", .range(1...50))
        var limit: Int = 25
    }

    // MARK: - Tool Execution

    /// Execute the tool with the provided arguments
    ///
    /// - Parameter arguments: Search parameters from the model
    /// - Returns: Formatted string describing the found values
    func call(arguments: Arguments) async throws -> String {
        do {
            // Build SQL query with filters
            var sql = "SELECT * FROM personal_values WHERE 1=1"
            var queryArguments: [any DatabaseValueConvertible & Sendable] = []

            // Add value type filter if provided
            if let valueType = arguments.valueType, !valueType.isEmpty {
                sql += " AND incentive_type = ?"
                queryArguments.append(valueType)
            }

            // Add life domain filter if provided
            if let lifeDomain = arguments.lifeDomain, !lifeDomain.isEmpty {
                sql += " AND life_domain = ?"
                queryArguments.append(lifeDomain)
            }

            // Add priority range filters if provided
            if let minPriority = arguments.minPriority {
                sql += " AND priority >= ?"
                queryArguments.append(Int64(minPriority))
            }

            if let maxPriority = arguments.maxPriority {
                sql += " AND priority <= ?"
                queryArguments.append(Int64(maxPriority))
            }

            // Add ordering (highest priority first) and limit
            sql += " ORDER BY priority DESC, log_time DESC LIMIT ?"
            queryArguments.append(Int64(arguments.limit))

            // Fetch values from database
            let values: [Values] = try await database.fetch(
                Values.self,
                sql: sql,
                arguments: queryArguments
            )

            // Format results for the model to understand
            if values.isEmpty {
                return "No values found matching the criteria."
            }

            // Group values by type for better organization
            let groupedValues = Swift.Dictionary(grouping: values) { value in
                // For now, all values are the same type
                "Values"
            }

            var result = "Found \(values.count) value(s):\n\n"

            // Display HighestOrderValues first, then MajorValues, then Values
            let typeOrder = ["HighestOrderValue", "MajorValue", "Value"]

            for type in typeOrder {
                if let valuesOfType = groupedValues[type], !valuesOfType.isEmpty {
                    result += "=== \(formatValueType(type)) ===\n"
                    for value in valuesOfType {
                        result += formatValue(value)
                        result += "\n"
                    }
                    result += "\n"
                }
            }

            return result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        } catch {
            return "Error fetching values: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// Format a value into a human-readable string
    private func formatValue(_ value: Values) -> String {
        var lines: [String] = []

        // Name and priority
        let name = value.title ?? "Unnamed Value"
        lines.append("• \(name) [Priority: \(value.priority)]")

        // Description if present
        if let description = value.detailedDescription {
            lines.append("  Description: \(description)")
        }

        // Life domain if present
        if let domain = value.lifeDomain {
            lines.append("  Life Domain: \(domain)")
        }

        // Free-form notes if present
        if let notes = value.freeformNotes {
            lines.append("  Notes: \(notes)")
        }

        return lines.joined(separator: "\n")
    }

    /// Format value type for display
    private func formatValueType(_ type: String) -> String {
        switch type {
        case "HighestOrderValue":
            return "Highest Order Values (Core Life Principles)"
        case "MajorValue":
            return "Major Values (Important Drivers)"
        case "Value":
            return "Values (Supporting Beliefs)"
        default:
            return type
        }
    }
}

// MARK: - Sendable

@available(macOS 26.0, *)
extension GetValuesTool: Sendable {}

#endif // canImport(FoundationModels)