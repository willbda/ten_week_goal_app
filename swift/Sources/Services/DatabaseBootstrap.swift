// DatabaseBootstrap.swift
// Database initialization with CloudKit synchronization
//
// Written by Claude Code on 2025-10-31

import Foundation
import SQLiteData
import GRDB
import Models

/// Configures database and CloudKit sync at app startup
public enum DatabaseBootstrap {

    public static func configure() {
        prepareDependencies {
            do {
                let db = try createDatabase()
                $0.defaultDatabase = db
                $0.defaultSyncEngine = try createSyncEngine(for: db)
                print("✅ Database configured with CloudKit sync")
            } catch {
                fatalError("Failed to configure database: \(error)")
            }
        }
    }

    private static func createDatabase() throws -> DatabaseQueue {
        let dbPath = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("GoalTracker/application_data.db")

        try FileManager.default.createDirectory(
            at: dbPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let db = try DatabaseQueue(path: dbPath.path)

        // Enable WAL mode for better concurrency
        try db.write { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }

        return db
    }

    private static func createSyncEngine(for db: DatabaseQueue) throws -> SyncEngine {
        return try SyncEngine(
            for: db,
            tables:
                // Sync all 14 tables
                Action.self, Expectation.self, Measure.self, PersonalValue.self, TimePeriod.self,
                Goal.self, Milestone.self, Obligation.self, GoalTerm.self, ExpectationMeasure.self,
                MeasuredAction.self, GoalRelevance.self, ActionGoalContribution.self, TermGoalAssignment.self
        )
    }
}
