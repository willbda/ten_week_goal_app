import Foundation
import SQLiteData
import GRDB  // ARCHITECTURE NOTE: Required for low-level database initialization
import Models

// ARCHITECTURE DECISION: Why GRDB import here?
// CONTEXT: DatabaseBootstrap needs low-level database setup APIs
// GRDB APIs REQUIRED (not exposed by SQLiteData):
//   - DatabaseQueue(path:) - Constructor to create database file
//   - barrierWriteWithoutTransaction - WAL mode setup outside transaction
//   - Database.tableExists() - Schema initialization check
//   - Database.execute(sql:) - Raw SQL execution for schema
// ALTERNATIVE: Could use DatabaseMigrator (see SQLiteData examples)
//   BUT: We already have schema_current.sql, so direct execute is simpler
// PATTERN: Bootstrap uses GRDB, rest of app uses SQLiteData
// SEE: sqlite-data-main/Examples/CaseStudies/SwiftUIDemo.swift:66-80 for migrator pattern

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

        // GRDB API: DatabaseQueue constructor
        let db = try DatabaseQueue(path: dbPath.path)

        // GRDB API: barrierWriteWithoutTransaction for WAL mode
        // ARCHITECTURE NOTE: WAL (Write-Ahead Logging) improves concurrency
        // MUST be set outside transaction, hence barrierWriteWithoutTransaction
        // SEE: https://www.sqlite.org/wal.html
        try db.barrierWriteWithoutTransaction { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }

        // Initialize schema if tables don't exist yet
        try initializeSchema(db)

        return db
    }

    private static func initializeSchema(_ db: DatabaseQueue) throws {
        // GRDB API: Database.tableExists() check
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

        // GRDB API: Database.execute(sql:) for raw SQL
        // ARCHITECTURE NOTE: We use direct SQL execution instead of DatabaseMigrator
        // REASON: schema_current.sql is our source of truth, simpler to execute directly
        // ALTERNATIVE: Could use DatabaseMigrator like SQLiteData examples
        //   migrator.registerMigration("v1") { db in try db.execute(sql: schemaSql) }
        //   Pro: Migration tracking, can add incremental migrations later
        //   Con: More boilerplate for our current single-schema approach
        // DECISION: Stick with direct execution until we need migration versioning
        try db.write { db in
            try db.execute(sql: schemaSql)
        }

        print("✅ Database schema initialized from schema_current.sql")
    }

    enum DatabaseError: Error {
        case schemaFileNotFound
    }

    private static func createSyncEngine(for db: DatabaseQueue) throws -> SyncEngine {
        // SyncEngine is from SQLiteData - handles CloudKit sync
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
