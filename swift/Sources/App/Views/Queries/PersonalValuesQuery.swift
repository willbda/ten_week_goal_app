//
// PersonalValuesQuery.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Query for fetching PersonalValues (for consistency with Actions/Terms pattern)
//
// USAGE:
// Currently PersonalValuesListView uses @FetchAll(PersonalValue.all) directly.
// This file exists for pattern consistency and future extensibility.
//
// If we need to add JOINs or complex filtering in the future, this is where it goes.
//

import Foundation
import Models
import SQLiteData

/// Simple wrapper for PersonalValue queries
///
/// NOTE: Currently just returns PersonalValue.all, but provides a consistent
/// query pattern across all entities (Actions, Terms, PersonalValues)
public struct PersonalValuesQuery: FetchKeyRequest {
    public typealias Value = [PersonalValue]

    public init() {}

    public func fetch(_ db: Database) throws -> [PersonalValue] {
        // Simple query - just fetch all values ordered by priority
        return try PersonalValue.all
            .order { $0.priority.desc() }
            .fetchAll(db)
    }
}
