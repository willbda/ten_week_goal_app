import Foundation
import SQLiteData
import GRDB
import Models

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
        let dbPath: URL
        if ProcessInfo.processInfo.environment["USE_TEST_DB"] == "1" {
            dbPath = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("GoalTracker/testing.db")

            try FileManager.default.createDirectory(
                at: dbPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            print("⚠️ Using TEST database at: \(dbPath.path)")
        } else {
            dbPath = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("GoalTracker/application_data.db")

            try FileManager.default.createDirectory(
                at: dbPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }

        let db = try DatabaseQueue(path: dbPath.path)

        // Enable WAL mode - must be outside transaction
        try db.barrierWriteWithoutTransaction { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }

        // Initialize schema if tables don't exist yet
        try initializeSchema(db)

        return db
    }

    private static func initializeSchema(_ db: DatabaseQueue) throws {
        // Check if schema is already initialized
        let hasSchema = try db.read { db in
            try db.tableExists("actions")
        }

        guard !hasSchema else {
            print("✅ Database schema already exists")
            return
        }

        // Load schema SQL from bundle
        guard let schemaURL = Bundle.module.url(
            forResource: "schema_current",
            withExtension: "sql"
        ) else {
            throw DatabaseError.schemaFileNotFound
        }

        let schemaSql = try String(contentsOf: schemaURL, encoding: .utf8)

        // Execute schema creation
        try db.write { db in
            try db.execute(sql: schemaSql)
        }

        print("✅ Database schema initialized from schema_current.sql")
    }

    enum DatabaseError: Error {
        case schemaFileNotFound
    }

    private static func createSyncEngine(for db: DatabaseQueue) throws -> SyncEngine {
        return try SyncEngine(
            for: db,
            tables:
                Action.self,
                Expectation.self,
                Measure.self,
                PersonalValue.self,
                TimePeriod.self,
                Goal.self,
                Milestone.self,
                Obligation.self,
                GoalTerm.self,
                ExpectationMeasure.self,
                MeasuredAction.self,
                GoalRelevance.self,
                ActionGoalContribution.self,
                TermGoalAssignment.self
        )
    }
}
