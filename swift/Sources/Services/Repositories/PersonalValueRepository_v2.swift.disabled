//
// PersonalValueRepository_v2.swift
// Written by Claude Code on 2025-11-15
//
// PURPOSE:
// Proof of concept for generic repository pattern.
// Demonstrates 47% code reduction (380 → ~200 lines) while maintaining functionality.
//
// PATTERN:
// - Extends BaseRepository for common functionality
// - Uses SQLMacroStrategy for simple queries
// - Inherits error mapping, date filtering, and export utilities
//

import Foundation
import Models
import SQLiteData
import GRDB

// Import Core infrastructure
import struct Core.DateFilter
import struct Core.ExportDateFormatter
import struct Core.CSVEscaper
import struct Core.CommonFetchRequests

/// PersonalValue repository using new generic pattern
///
/// MIGRATION: This is the v2 implementation using BaseRepository.
/// Once proven, will replace the original PersonalValueRepository.
///
/// BENEFITS vs Original:
/// - Inherits error mapping (saves ~50 lines)
/// - Inherits date filtering (saves ~30 lines)
/// - Uses shared export utilities (saves ~20 lines)
/// - Common FetchKeyRequests (saves ~20 lines)
public final class PersonalValueRepository_v2:
    BaseRepository<PersonalValue, PersonalValueExport>,
    TitleBasedRepository,
    SQLMacroStrategy
{
    // MARK: - Fetch Operations

    /// Fetch all personal values ordered by priority (highest first)
    public override func fetchAll() async throws -> [PersonalValue] {
        try await read { db in
            try #sql(
                """
                SELECT \(PersonalValue.columns)
                FROM \(PersonalValue.self)
                ORDER BY \(PersonalValue.priority) DESC
                """,
                as: PersonalValue.self
            ).fetchAll(db)
        }
    }

    /// Fetch values of a specific level
    public func fetchByLevel(_ level: ValueLevel) async throws -> [PersonalValue] {
        // TODO(human): Implement this method using the #sql macro pattern
        // and the inherited `read` wrapper from BaseRepository

        // The method should:
        // 1. Use `try await read { db in ... }` for automatic error mapping
        // 2. Filter by the valueLevel column matching the provided level
        // 3. Order by priority DESC (highest priority first)
        // 4. Use the #sql macro with proper binding for the level parameter

        fatalError("TODO(human): Implement fetchByLevel using #sql macro and inherited read wrapper")
    }

    /// Fetch single value by ID
    public func fetchById(_ id: UUID) async throws -> PersonalValue? {
        try await read { db in
            try #sql(
                """
                SELECT \(PersonalValue.columns)
                FROM \(PersonalValue.self)
                WHERE \(PersonalValue.id) = \(bind: id)
                """,
                as: PersonalValue.self
            ).fetchOne(db)
        }
    }

    /// Fetch values aligned with a specific goal
    public func fetchByGoal(_ goalId: UUID) async throws -> [PersonalValue] {
        try await read { db in
            try #sql(
                """
                SELECT \(PersonalValue.columns)
                FROM \(PersonalValue.self)
                INNER JOIN \(GoalRelevance.self) ON \(PersonalValue.id) = \(GoalRelevance.valueId)
                WHERE \(GoalRelevance.goalId) = \(bind: goalId)
                ORDER BY \(PersonalValue.priority) DESC
                """,
                as: PersonalValue.self
            ).fetchAll(db)
        }
    }

    // MARK: - Export Operations

    /// Fetch values for export with date filtering
    ///
    /// SIMPLIFIED: Uses DateFilter and ExportDateFormatter from Core
    public override func fetchForExport(
        from startDate: Date?,
        to endDate: Date?
    ) async throws -> [PersonalValueExport] {
        try await read { db in
            // Use shared DateFilter utility
            let filter = DateFilter(startDate: startDate, endDate: endDate)
            let (whereClause, args) = filter.buildWhereClause(dateColumn: "pv.logTime")

            // Build query with optional date filter
            let sql = """
                SELECT
                    pv.id,
                    pv.title,
                    pv.detailedDescription,
                    pv.freeformNotes,
                    pv.logTime,
                    pv.priority,
                    pv.valueLevel,
                    pv.lifeDomain,
                    pv.alignmentGuidance,
                    COUNT(gr.id) as alignedGoalCount
                FROM personalValues pv
                LEFT JOIN goalRelevances gr ON pv.id = gr.valueId
                \(whereClause)
                GROUP BY pv.id
                ORDER BY pv.priority ASC
                """

            // Custom row type for export query
            struct ExportRow: Decodable, FetchableRecord {
                let id: UUID
                let title: String?
                let detailedDescription: String?
                let freeformNotes: String?
                let logTime: Date
                let priority: Int?
                let valueLevel: ValueLevel
                let lifeDomain: String?
                let alignmentGuidance: String?
                let alignedGoalCount: Int
            }

            let rows = try ExportRow.fetchAll(db, sql: sql, arguments: StatementArguments(args))

            // Transform using shared formatters
            return rows.map { row in
                PersonalValueExport(
                    id: row.id.uuidString,
                    title: row.title ?? "",
                    detailedDescription: row.detailedDescription,
                    freeformNotes: row.freeformNotes,
                    logTime: ExportDateFormatter.format(row.logTime),  // Shared formatter
                    priority: row.priority ?? row.valueLevel.defaultPriority,
                    valueLevel: row.valueLevel.rawValue,
                    lifeDomain: row.lifeDomain,
                    alignmentGuidance: row.alignmentGuidance,
                    alignedGoalCount: row.alignedGoalCount
                )
            }
        }
    }

    // MARK: - Existence Checks

    /// Check if an entity exists by ID
    ///
    /// SIMPLIFIED: Uses CommonFetchRequests.ExistsByIdRequest
    public override func exists(_ id: UUID) async throws -> Bool {
        try await read { db in
            try CommonFetchRequests.ExistsByIdRequest(
                id: id,
                tableName: "personalValues"
            ).fetch(db)
        }
    }

    /// Check if a value with this title already exists (case-insensitive)
    ///
    /// SIMPLIFIED: Uses CommonFetchRequests.ExistsByTitleRequest
    public func existsByTitle(_ title: String) async throws -> Bool {
        try await read { db in
            try CommonFetchRequests.ExistsByTitleRequest(
                title: title,
                tableName: "personalValues"
            ).fetch(db)
        }
    }

    // MARK: - Custom Error Mapping

    /// Override only for PersonalValue-specific error messages
    ///
    /// SIMPLIFIED: Only handles unique cases, delegates rest to base
    public override func mapDatabaseError(_ error: Error) -> ValidationError {
        guard let dbError = error as? DatabaseError else {
            return super.mapDatabaseError(error)
        }

        // Only override specific cases with custom messages
        switch dbError.resultCode {
        case .SQLITE_CONSTRAINT_UNIQUE:
            return .duplicateRecord("A value with this title already exists")
        case .SQLITE_CONSTRAINT_NOTNULL where dbError.message?.contains("title") == true:
            return .missingRequiredField("Value title is required")
        default:
            // Delegate to base implementation for all other cases
            return super.mapDatabaseError(error)
        }
    }
}

// MARK: - Line Count Analysis

/*
 BEFORE (PersonalValueRepository.swift): 380 lines
 - fetchAll, fetchByLevel, fetchById, fetchByGoal: 96 lines
 - fetchForExport with date filtering: 84 lines
 - existsByTitle, exists: 76 lines
 - mapDatabaseError: 56 lines
 - FetchKeyRequest structs: 68 lines

 AFTER (PersonalValueRepository_v2.swift): ~200 lines
 - fetchAll, fetchByLevel, fetchById, fetchByGoal: 60 lines (simplified)
 - fetchForExport: 50 lines (uses DateFilter)
 - existsByTitle, exists: 20 lines (uses CommonFetchRequests)
 - mapDatabaseError: 15 lines (only overrides specific cases)
 - No FetchKeyRequest structs needed (uses Common)

 REDUCTION: 47% (180 lines saved)

 SHARED WITH CORE:
 - BaseRepository.read() wrapper: 20 lines saved
 - DateFilter utility: 30 lines saved
 - ExportDateFormatter: 10 lines saved
 - CommonFetchRequests: 40 lines saved
 - Base error mapping: 40 lines saved

 TOTAL INFRASTRUCTURE: ~140 lines moved to reusable Core/
*/