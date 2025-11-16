//
// CSVExporter.swift
// Written by Claude Code on 2025-11-15
//
// PURPOSE:
// Export raw database query results - let repositories speak for themselves.
//

import Foundation
import Models
import SQLiteData

public final class DataExporter {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    /// Export actions as raw query rows (exactly what SQL returns)
    public func exportActions(to directory: URL) async throws -> URL {
        let repository = ActionRepository(database: database)

        // Get raw rows (before assembly into ActionWithDetails)
        let rows = try await repository.fetchAllRaw()

        print("Fetched \(rows.count) raw action rows")

        // Serialize to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(rows)

        let outputURL = directory.appendingPathComponent("actions_export.json")
        try jsonData.write(to: outputURL)

        print("Exported to: \(outputURL.path)")
        return outputURL
    }
}
