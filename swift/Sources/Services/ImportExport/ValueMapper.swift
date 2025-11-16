//
// ValueMapper.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Maps CSV rows to PersonalValueFormData for PersonalValueCoordinator.
// Simplest mapper - no relationships, just field extraction.
//

import Foundation
import Models

// MARK: - Value Mapper

/// Maps CSV rows to PersonalValueFormData
public struct ValueMapper: CSVMapper {

    public init() {}

    public func map(row: [String: String], rowNumber: Int) throws -> PersonalValueFormData {
        // 1. Extract required fields
        guard let title = row["title"]?.nonEmpty else {
            throw MapError.missingRequired(row: rowNumber, field: "title")
        }

        guard let levelStr = row["level"]?.nonEmpty else {
            throw MapError.missingRequired(row: rowNumber, field: "level")
        }

        guard let valueLevel = ValueLevel(rawValue: levelStr) else {
            throw MapError.invalidValue(
                row: rowNumber,
                field: "level",
                value: levelStr,
                reason: "Must be one of: general, major, highest_order, life_area"
            )
        }

        // 2. Extract optional fields
        let description = row["description"]?.nonEmpty
        let notes = row["notes"]?.nonEmpty
        let lifeDomain = row["life_domain"]?.nonEmpty
        let alignmentGuidance = row["alignment_guidance"]?.nonEmpty

        // 3. Parse optional priority
        let priority: Int?
        if let priorityStr = row["priority"]?.nonEmpty {
            guard let value = Int(priorityStr), value >= 1 else {
                throw MapError.invalidValue(
                    row: rowNumber,
                    field: "priority",
                    value: priorityStr,
                    reason: "Must be positive integer"
                )
            }
            priority = value
        } else {
            // Use default priority for level (if not specified)
            priority = valueLevel.defaultPriority
        }

        return PersonalValueFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            valueLevel: valueLevel,
            priority: priority,
            lifeDomain: lifeDomain,
            alignmentGuidance: alignmentGuidance
        )
    }
}
