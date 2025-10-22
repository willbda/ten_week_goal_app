// TermRecord.swift
// Database transfer object for terms table
//
// Written by Claude Code on 2025-10-19
//
// Bridges between database schema and clean GoalTerm domain model.
// Handles complex JSON array of INTEGER goal IDs.
//
// LIMITATION: term_goals_by_id requires stable UUID↔Int mapping.
// For now, we generate UUIDs on read but can't preserve goal associations on write.

import Foundation
import GRDB
import Models

/// Database representation of terms table
///
/// Maps database schema to domain GoalTerm type.
/// Handles JSON array of goal IDs: "[1, 3, 5]" -> [UUID]
///
/// Note: Without stable UUID mapping, goal associations are lost on round-trip.
/// TODO: Implement UUID mapping table to preserve associations.
struct TermRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Database Fields

    /// Database INTEGER primary key (auto-increment, used by Python)
    var id: Int64?

    /// UUID stored as TEXT (used by Swift, UNIQUE constraint in DB)
    /// This provides stable IDs across Swift fetches while maintaining
    /// Python compatibility (Python uses INTEGER id, Swift uses uuid_id)
    var uuid_id: String?

    /// Short identifier (maps to GoalTerm.title)
    var title: String

    /// Optional elaboration (maps to GoalTerm.detailedDescription)
    var description: String?

    /// Freeform notes (maps to GoalTerm.freeformNotes)
    var notes: String?

    /// Sequential term number (1, 2, 3, etc.)
    var term_number: Int

    /// Term start date (ISO format in DB)
    var start_date: Date

    /// Term end date (ISO format in DB)
    var target_date: Date

    /// JSON array of INTEGER goal IDs
    /// Example: "[1, 3, 5]"
    /// Stored as String, needs manual parsing
    var term_goals_by_id: String?

    /// Post-term reflection
    var reflection: String?

    /// When record was created
    var created_at: Date?

    /// When record was last updated
    var updated_at: Date?

    // MARK: - GRDB Configuration

    /// CodingKeys for database column mapping
    enum CodingKeys: String, CodingKey {
        case id
        case uuid_id
        case title
        case description
        case notes
        case term_number
        case start_date
        case target_date
        case term_goals_by_id
        case reflection
        case created_at
        case updated_at
    }

    /// Table name in database
    static let databaseTableName = "terms"
}

// MARK: - Database -> Domain Conversion

extension TermRecord {
    /// Convert database record to clean domain model
    ///
    /// Handles:
    /// - uuid_id TEXT -> UUID (stable across fetches!)
    /// - snake_case columns -> camelCase properties
    /// - JSON array "[1, 3, 5]" -> [UUID] (generates new UUIDs)
    ///
    /// UUID Mapping:
    /// - If uuid_id exists in database, parse and use it (stable ID)
    /// - If uuid_id is nil, generate new UUID and it will be saved on next write
    ///
    /// LIMITATION: Goal IDs in term_goals_by_id are INTEGERs in database,
    /// but we generate new UUIDs. This means we can't look up the actual goals
    /// without a mapping table. For now, we create placeholder UUIDs.
    func toDomain() -> GoalTerm {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        // Parse JSON array of goal IDs
        let goalUUIDs = parseGoalIDs(from: term_goals_by_id)

        return GoalTerm(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            termNumber: term_number,
            startDate: start_date,
            targetDate: target_date,
            theme: description,  // Using description as theme (database doesn't have separate theme field)
            termGoalsByID: goalUUIDs,
            reflection: reflection,
            logTime: created_at ?? Date(),
            id: uuid  // Stable UUID from database!
        )
    }

    /// Parse JSON array of INTEGER goal IDs into UUID array
    ///
    /// Converts: "[1, 3, 5]" -> [UUID(), UUID(), UUID()]
    ///
    /// Note: Generates NEW UUIDs for each goal ID. These won't match
    /// the actual goal UUIDs without a stable mapping.
    ///
    /// TODO: Implement UUID mapping table to get actual goal UUIDs.
    private func parseGoalIDs(from json: String?) -> [UUID] {
        guard let json = json, !json.isEmpty else {
            return []
        }

        // Remove brackets and split by comma
        let cleaned = json
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            .replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else {
            return []
        }

        let idStrings = cleaned.split(separator: ",")

        // For each INTEGER ID, generate a UUID
        // TODO: Look up actual UUID from mapping table
        return idStrings.compactMap { _ in UUID() }
    }
}

// MARK: - Domain -> Database Conversion

extension GoalTerm {
    /// Convert clean domain model to database record
    ///
    /// Handles:
    /// - UUID domain ID -> uuid_id TEXT field (stable across fetches)
    /// - camelCase properties -> snake_case columns
    /// - [UUID] -> JSON array (LIMITATION: can't map UUIDs back to INTs)
    ///
    /// Dual ID System:
    /// - id INTEGER: Set to nil, database auto-increments (Python uses this)
    /// - uuid_id TEXT: Stores Swift's UUID as string (Swift uses this)
    ///
    /// LIMITATION: term_goals_by_id is set to nil because we can't map
    /// Swift UUIDs back to database INTEGER IDs without a mapping table.
    /// This means goal associations are lost when creating new terms from Swift.
    ///
    /// TODO: Implement UUID↔Int mapping to preserve associations.
    func toRecord() -> TermRecord {
        TermRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            title: title ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            term_number: termNumber,
            start_date: startDate,
            target_date: targetDate,
            term_goals_by_id: nil,  // LIMITATION: Can't map [UUID] -> [Int] yet
            reflection: reflection,
            created_at: Date(),
            updated_at: Date()
        )
    }
}
