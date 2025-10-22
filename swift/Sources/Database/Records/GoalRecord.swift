// GoalRecord.swift
// Database transfer object for Goals table
//
// Written by Claude Code on 2025-10-19
//
// This Record type bridges between:
// - Database schema (INTEGER id, snake_case columns, "SmartGoal" type)
// - Clean domain models (UUID id, camelCase properties, "goal"/"milestone" subtypes)
//
// Pattern:
// - Struct matches database schema exactly
// - CodingKeys map column names (minimal since we match DB naming)
// - toDomain() converts Record -> Domain model
// - Domain.toRecord() converts Domain model -> Record

import Foundation
import GRDB
import Models

/// Database representation of goals table
///
/// Maps database schema to domain Goal/Milestone types.
/// Database uses INTEGER ids and snake_case columns.
/// All existing goals in database have goal_type = "SmartGoal"
struct GoalRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Database Fields

    /// Database INTEGER primary key (auto-increment, used by Python)
    var id: Int64?

    /// UUID stored as TEXT (used by Swift, UNIQUE constraint in DB)
    /// This provides stable IDs across Swift fetches while maintaining
    /// Python compatibility (Python uses INTEGER id, Swift uses uuid_id)
    var uuid_id: String?

    /// Short identifier (maps to Goal.title)
    var title: String

    /// Optional elaboration (maps to Goal.detailedDescription)
    var description: String?

    /// Freeform notes (maps to Goal.freeformNotes)
    var notes: String?

    /// When created/logged (ISO format in DB)
    var log_time: Date

    /// Polymorphic type identifier: "Goal", "SmartGoal", "Milestone"
    var goal_type: String

    /// Numeric target (e.g., 120.0 for "run 120km")
    var measurement_target: Double?

    /// Unit of measurement (e.g., "km", "hours", "pages")
    var measurement_unit: String?

    /// Goal period start date (ISO format in DB)
    var start_date: Date?

    /// Goal period end date (ISO format in DB)
    var target_date: Date?

    /// Why this goal matters (SMART: Relevant)
    var how_goal_is_relevant: String?

    /// How to achieve it (SMART: Actionable)
    var how_goal_is_actionable: String?

    /// Expected duration in weeks
    var expected_term_length: Int?

    // MARK: - GRDB Configuration

    /// CodingKeys for database column mapping
    /// Since our property names match database columns exactly, we only need this
    /// for GRDB's Codable conformance
    enum CodingKeys: String, CodingKey {
        case id
        case uuid_id
        case title
        case description
        case notes
        case log_time
        case goal_type
        case measurement_target
        case measurement_unit
        case start_date
        case target_date
        case how_goal_is_relevant
        case how_goal_is_actionable
        case expected_term_length
    }

    /// Table name in database
    static let databaseTableName = "goals"
}

// MARK: - Database -> Domain Conversion

extension GoalRecord {
    /// Convert database record to clean domain model
    ///
    /// Handles:
    /// - uuid_id TEXT -> UUID (stable across fetches!)
    /// - snake_case columns -> camelCase properties
    /// - "SmartGoal" type -> "goal" or "milestone" subtype
    ///
    /// Returns Goal or Milestone based on goal_type.
    /// For now, treats all as Goal since database only has "SmartGoal"
    ///
    /// UUID Mapping:
    /// - If uuid_id exists in database, parse and use it (stable ID)
    /// - If uuid_id is nil, generate new UUID and it will be saved on next write
    func toDomain() -> Goal {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return Goal(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            measurementUnit: measurement_unit,
            measurementTarget: measurement_target,
            startDate: start_date,
            targetDate: target_date,
            howGoalIsRelevant: how_goal_is_relevant,
            howGoalIsActionable: how_goal_is_actionable,
            expectedTermLength: expected_term_length,
            priority: 50,  // Database doesn't store priority, use default
            lifeDomain: nil,  // Database doesn't store lifeDomain
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }

    /// Convert to Milestone if goal_type indicates milestone
    /// Returns nil if this isn't a milestone type
    func toMilestone() -> Milestone? {
        guard goal_type.lowercased() == "milestone" else {
            return nil
        }

        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return Milestone(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            measurementUnit: measurement_unit,
            measurementTarget: measurement_target,
            startDate: start_date,
            targetDate: target_date,
            priority: 30,
            lifeDomain: nil,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }
}

// MARK: - Domain -> Database Conversion

extension Goal {
    /// Convert clean domain model to database record
    ///
    /// Handles:
    /// - UUID domain ID -> uuid_id TEXT field (stable across fetches)
    /// - camelCase properties -> snake_case columns
    /// - "goal" subtype -> "SmartGoal" type (for DB compatibility)
    ///
    /// Dual ID System:
    /// - id INTEGER: Set to nil, database auto-increments (Python uses this)
    /// - uuid_id TEXT: Stores Swift's UUID as string (Swift uses this)
    func toRecord() -> GoalRecord {
        GoalRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            title: title ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            goal_type: "SmartGoal",  // Database compatibility (all goals stored as SmartGoal)
            measurement_target: measurementTarget,
            measurement_unit: measurementUnit,
            start_date: startDate,
            target_date: targetDate,
            how_goal_is_relevant: howGoalIsRelevant,
            how_goal_is_actionable: howGoalIsActionable,
            expected_term_length: expectedTermLength
        )
    }
}

extension Milestone {
    /// Convert Milestone to database record
    func toRecord() -> GoalRecord {
        GoalRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            title: title ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            goal_type: "Milestone",  // Distinguish milestones in database
            measurement_target: measurementTarget,
            measurement_unit: measurementUnit,
            start_date: startDate,
            target_date: targetDate,
            how_goal_is_relevant: nil,  // Milestones don't have SMART fields
            how_goal_is_actionable: nil,
            expected_term_length: nil
        )
    }
}
