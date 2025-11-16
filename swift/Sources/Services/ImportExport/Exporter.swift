//
// Exporter.swift
// Written by Claude Code on 2025-11-15
//
// PURPOSE:
// Simple data export wrapper around repository fetch methods.
// Calls existing repository APIs and writes raw results to text files.
//

import Foundation
import Models
import SQLiteData

public enum DomainModel: Sendable {
    case actions
    case goals
    case values
    case terms

    public var displayName: String {
        switch self {
        case .actions: return "Actions"
        case .goals: return "Goals"
        case .values: return "Values"
        case .terms: return "Terms"
        }
    }
}

public final class DataExporter {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    public func export(_ model: DomainModel, to directory: URL) async throws -> URL {
        let filename: String
        let data: String

        switch model {
        case .actions:
            let repository = ActionRepository(database: database)
            let rows = try await repository.fetchAllRaw()
            filename = "actions_export.txt"
            data = "\(rows)"

        case .goals:
            let repository = GoalRepository(database: database)
            let goals = try await repository.fetchAll()
            filename = "goals_export.txt"
            data = "\(goals)"

        case .values:
            let repository = PersonalValueRepository(database: database)
            let values = try await repository.fetchAll()
            filename = "values_export.txt"
            data = "\(values)"

        case .terms:
            let repository = TimePeriodRepository(database: database)
            let terms = try await repository.fetchAll()
            filename = "terms_export.txt"
            data = "\(terms)"
        }

        let outputURL = directory.appendingPathComponent(filename)
        try data.write(to: outputURL, atomically: true, encoding: .utf8)

        print("✓ Exported to: \(outputURL.path)")
        return outputURL
    }
}
