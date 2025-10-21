// ValueRecord.swift
// Database transfer object for personal_values table
//
// Written by Claude Code on 2025-10-19
//
// Bridges between database schema and clean Value domain models.
// Handles polymorphism: one table stores 5 different value types.

import Foundation
import GRDB
import Models

/// Database representation of personal_values table
///
/// Maps database schema to 5 domain value types:
/// - Incentives (incentive_type = "incentive")
/// - Values (incentive_type = "general")
/// - LifeAreas (incentive_type = "life_area")
/// - MajorValues (incentive_type = "major")
/// - HighestOrderValues (incentive_type = "highest_order")
struct ValueRecord: Codable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Database Fields

    /// Database INTEGER primary key (auto-increment, used by Python)
    var id: Int64?

    /// UUID stored as TEXT (used by Swift, UNIQUE constraint in DB)
    /// This provides stable IDs across Swift fetches while maintaining
    /// Python compatibility (Python uses INTEGER id, Swift uses uuid_id)
    var uuid_id: String?

    /// Short identifier (maps to domain friendlyName)
    var common_name: String

    /// Optional elaboration (maps to domain detailedDescription)
    var description: String?

    /// Freeform notes (maps to domain freeformNotes)
    var notes: String?

    /// When created/logged (ISO format in DB)
    var log_time: Date

    /// Polymorphic type discriminator
    /// Values: "incentive", "general", "life_area", "major", "highest_order"
    var incentive_type: String

    /// Priority level (1 = highest, 100 = lowest)
    var priority: Int

    /// Life domain categorization (e.g., "Health", "Relationships")
    var life_domain: String?

    /// How this value shows up in actions/goals
    /// Only used by MajorValues
    var alignment_guidance: String?

    // MARK: - GRDB Configuration

    /// CodingKeys for database column mapping
    enum CodingKeys: String, CodingKey {
        case id
        case uuid_id
        case common_name
        case description
        case notes
        case log_time
        case incentive_type
        case priority
        case life_domain
        case alignment_guidance
    }

    /// Table name in database
    static let databaseTableName = "personal_values"
}

// MARK: - Database -> Domain Conversion

extension ValueRecord {
    /// Convert database record to appropriate domain value type
    ///
    /// Returns the correct domain type based on incentive_type:
    /// - "incentive" -> Incentives
    /// - "general" -> Values
    /// - "life_area" -> LifeAreas
    /// - "major" -> MajorValues
    /// - "highest_order" -> HighestOrderValues
    ///
    /// Returns `Any` because different calls return different types.
    /// Caller should cast to expected type or use type-specific methods below.
    func toDomain() -> Any {
        switch incentive_type {
        case "incentive":
            return toIncentives()
        case "general":
            return toValues()
        case "life_area":
            return toLifeAreas()
        case "major":
            return toMajorValues()
        case "highest_order":
            return toHighestOrderValues()
        default:
            // Unknown type - default to base Incentives
            return toIncentives()
        }
    }

    /// Convert to Incentives (base type)
    func toIncentives() -> Incentives {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return Incentives(
            friendlyName: common_name,
            detailedDescription: description,
            freeformNotes: notes,
            priority: priority,
            lifeDomain: life_domain,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }

    /// Convert to Values (general values)
    func toValues() -> Values {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return Values(
            friendlyName: common_name,
            detailedDescription: description,
            freeformNotes: notes,
            priority: priority,
            lifeDomain: life_domain,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }

    /// Convert to LifeAreas
    func toLifeAreas() -> LifeAreas {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return LifeAreas(
            friendlyName: common_name,
            detailedDescription: description,
            freeformNotes: notes,
            priority: priority,
            lifeDomain: life_domain,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }

    /// Convert to MajorValues (includes alignment_guidance)
    func toMajorValues() -> MajorValues {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return MajorValues(
            friendlyName: common_name,
            detailedDescription: description,
            freeformNotes: notes,
            priority: priority,
            lifeDomain: life_domain,
            alignmentGuidance: alignment_guidance,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }

    /// Convert to HighestOrderValues
    func toHighestOrderValues() -> HighestOrderValues {
        // Use uuid_id from database for stable IDs, or generate if missing
        let uuid = UUID(uuidString: uuid_id ?? "") ?? UUID()

        return HighestOrderValues(
            friendlyName: common_name,
            detailedDescription: description,
            freeformNotes: notes,
            priority: priority,
            lifeDomain: life_domain,
            logTime: log_time,
            id: uuid  // Stable UUID from database!
        )
    }
}

// MARK: - Domain -> Database Conversion

extension Incentives {
    /// Convert to database record
    func toRecord() -> ValueRecord {
        ValueRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            common_name: friendlyName ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            incentive_type: polymorphicSubtype,  // "incentive"
            priority: priority,
            life_domain: lifeDomain,
            alignment_guidance: nil
        )
    }
}

extension Values {
    /// Convert to database record
    func toRecord() -> ValueRecord {
        ValueRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            common_name: friendlyName ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            incentive_type: polymorphicSubtype,  // "general"
            priority: priority,
            life_domain: lifeDomain,
            alignment_guidance: nil
        )
    }
}

extension LifeAreas {
    /// Convert to database record
    func toRecord() -> ValueRecord {
        ValueRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            common_name: friendlyName ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            incentive_type: polymorphicSubtype,  // "life_area"
            priority: priority,
            life_domain: lifeDomain,
            alignment_guidance: nil
        )
    }
}

extension MajorValues {
    /// Convert to database record (includes alignment_guidance)
    func toRecord() -> ValueRecord {
        ValueRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            common_name: friendlyName ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            incentive_type: polymorphicSubtype,  // "major"
            priority: priority,
            life_domain: lifeDomain,
            alignment_guidance: alignmentGuidance
        )
    }
}

extension HighestOrderValues {
    /// Convert to database record
    func toRecord() -> ValueRecord {
        ValueRecord(
            id: nil,  // Let database auto-increment (Python compatibility)
            uuid_id: id.uuidString,  // Store Swift's UUID for stable fetches
            common_name: friendlyName ?? "",
            description: detailedDescription,
            notes: freeformNotes,
            log_time: logTime,
            incentive_type: polymorphicSubtype,  // "highest_order"
            priority: priority,
            life_domain: lifeDomain,
            alignment_guidance: nil
        )
    }
}
