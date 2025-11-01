// TenWeekGoalApp.swift
// Main SwiftUI App entry point for iOS/macOS
//
// Written by Claude Code on 2025-10-19
// Updated by Claude Code on 2025-10-30 (3NF normalized schema)

import SwiftUI
import SQLiteData
import GRDB
import Models

/// Main application entry point
///
/// Manages app lifecycle and provides root view with database access.
/// Uses SwiftUI's modern App lifecycle (iOS 14+/macOS 11+).
///
/// Note: No @main attribute - this is launched from AppRunner/main.swift
/// The activation policy is set in main.swift to ensure proper macOS GUI behavior.
public struct TenWeekGoalApp: App {

    // MARK: - Initialization

    public init() {
        print("🟢 TenWeekGoalApp init() started")

        // Configure SQLiteData with iCloud sync
        prepareDependencies {
            print("🟢 prepareDependencies block started")

            let dbPath = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("GoalTracker/application_data.db")

            print("🟢 Database path: \(dbPath.path)")

            do {
                try FileManager.default.createDirectory(
                    at: dbPath.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                print("🟢 Database directory created")
            } catch {
                print("❌ Failed to create database directory: \(error)")
                fatalError("Database initialization failed: \(error)")
            }

            let db: DatabaseQueue
            do {
                print("🟢 Creating DatabaseQueue...")
                db = try DatabaseQueue(path: dbPath.path)
                print("🟢 DatabaseQueue created successfully")

                print("🟢 Running database migrations...")
                var migrator = DatabaseMigrator()
                #if DEBUG
                migrator.eraseDatabaseOnSchemaChange = true
                #endif
                // Migration 1: Original schema (legacy support)
                migrator.registerMigration("Create initial tables") { db in
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "actions" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "measuresByUnit" TEXT,
                          "durationMinutes" REAL,
                          "startTime" TEXT,
                          "logTime" TEXT NOT NULL
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "goals" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "measurementUnit" TEXT,
                          "measurementTarget" REAL,
                          "startDate" TEXT,
                          "targetDate" TEXT,
                          "howGoalIsRelevant" TEXT,
                          "howGoalIsActionable" TEXT,
                          "expectedTermLength" INTEGER,
                          "polymorphicSubtype" TEXT
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "goalTerms" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "termNumber" INTEGER,
                          "startDate" TEXT,
                          "targetDate" TEXT,
                          "theme" TEXT,
                          "reflection" TEXT,
                          "polymorphicSubtype" TEXT
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "termGoalAssignments" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "termUUID" TEXT NOT NULL,
                          "goalUUID" TEXT NOT NULL,
                          "assignmentOrder" INTEGER,
                          "createdAt" TEXT NOT NULL
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "valueses" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "priority" INTEGER NOT NULL,
                          "lifeDomain" TEXT,
                          "polymorphicSubtype" TEXT
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "majorValueses" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "priority" INTEGER NOT NULL,
                          "lifeDomain" TEXT,
                          "alignmentGuidance" TEXT,
                          "polymorphicSubtype" TEXT
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "highestOrderValueses" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "priority" INTEGER NOT NULL,
                          "lifeDomain" TEXT,
                          "polymorphicSubtype" TEXT
                        ) STRICT
                        """
                    ).execute(db)

                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "lifeAreases" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "priority" INTEGER NOT NULL,
                          "lifeDomain" TEXT,
                          "polymorphicSubtype" TEXT
                        ) STRICT
                        """
                    ).execute(db)
                }

                // Migration 2: 3NF Normalized Schema
                migrator.registerMigration("Add 3NF normalized tables") { db in
                    // Create metrics catalog table
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "metrics" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "unit" TEXT NOT NULL,
                          "metricType" TEXT NOT NULL,
                          "canonicalUnit" TEXT,
                          "conversionFactor" REAL
                        ) STRICT
                        """
                    ).execute(db)

                    // Create action_metrics junction table
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "actionMetrics" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "actionId" TEXT NOT NULL,
                          "metricId" TEXT NOT NULL,
                          "value" REAL NOT NULL,
                          "recordedAt" TEXT NOT NULL,
                          FOREIGN KEY ("actionId") REFERENCES "actions"("id") ON DELETE CASCADE,
                          FOREIGN KEY ("metricId") REFERENCES "metrics"("id"),
                          UNIQUE("actionId", "metricId")
                        ) STRICT
                        """
                    ).execute(db)

                    // Create unified values table
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "values" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "priority" INTEGER NOT NULL DEFAULT 50,
                          "valueLevel" TEXT NOT NULL DEFAULT 'general',
                          "lifeDomain" TEXT,
                          "alignmentGuidance" TEXT
                        ) STRICT
                        """
                    ).execute(db)

                    // Create goal_metrics junction table (already have GoalMetric model)
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "goalMetrics" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "title" TEXT,
                          "detailedDescription" TEXT,
                          "freeformNotes" TEXT,
                          "logTime" TEXT NOT NULL,
                          "goalId" TEXT NOT NULL,
                          "metricId" TEXT NOT NULL,
                          "targetValue" REAL NOT NULL,
                          FOREIGN KEY ("goalId") REFERENCES "goals"("id") ON DELETE CASCADE,
                          FOREIGN KEY ("metricId") REFERENCES "metrics"("id"),
                          UNIQUE("goalId", "metricId")
                        ) STRICT
                        """
                    ).execute(db)

                    // Create goal_relevance junction table
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "goalRelevances" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "goalId" TEXT NOT NULL,
                          "valueId" TEXT NOT NULL,
                          "alignmentStrength" INTEGER,
                          "relevanceNotes" TEXT,
                          "createdAt" TEXT NOT NULL,
                          FOREIGN KEY ("goalId") REFERENCES "goals"("id") ON DELETE CASCADE,
                          FOREIGN KEY ("valueId") REFERENCES "values"("id") ON DELETE CASCADE,
                          UNIQUE("goalId", "valueId")
                        ) STRICT
                        """
                    ).execute(db)

                    // Create action_goal_contributions junction table
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "actionGoalContributions" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "actionId" TEXT NOT NULL,
                          "goalId" TEXT NOT NULL,
                          "contributionAmount" REAL,
                          "metricId" TEXT,
                          "createdAt" TEXT NOT NULL,
                          FOREIGN KEY ("actionId") REFERENCES "actions"("id") ON DELETE CASCADE,
                          FOREIGN KEY ("goalId") REFERENCES "goals"("id") ON DELETE CASCADE,
                          FOREIGN KEY ("metricId") REFERENCES "metrics"("id"),
                          UNIQUE("actionId", "goalId")
                        ) STRICT
                        """
                    ).execute(db)

                    // Update termGoalAssignments with proper foreign keys
                    try #sql(
                        """
                        CREATE TABLE IF NOT EXISTS "termGoalAssignments_new" (
                          "id" TEXT PRIMARY KEY NOT NULL,
                          "termId" TEXT NOT NULL,
                          "goalId" TEXT NOT NULL,
                          "assignmentOrder" INTEGER,
                          "createdAt" TEXT NOT NULL,
                          FOREIGN KEY ("termId") REFERENCES "goalTerms"("id") ON DELETE CASCADE,
                          FOREIGN KEY ("goalId") REFERENCES "goals"("id") ON DELETE CASCADE,
                          UNIQUE("termId", "goalId")
                        ) STRICT
                        """
                    ).execute(db)

                    // Migrate data from old termGoalAssignments if it exists
                    if try db.tableExists("termGoalAssignments") {
                        try #sql(
                            """
                            INSERT INTO "termGoalAssignments_new" ("id", "termId", "goalId", "assignmentOrder", "createdAt")
                            SELECT "id", "termUUID" as "termId", "goalUUID" as "goalId", "assignmentOrder", "createdAt"
                            FROM "termGoalAssignments"
                            """
                        ).execute(db)

                        try #sql("DROP TABLE IF EXISTS \"termGoalAssignments\"").execute(db)
                        try #sql("ALTER TABLE \"termGoalAssignments_new\" RENAME TO \"termGoalAssignments\"").execute(db)
                    }

                    // Create indexes for performance
                    try #sql("CREATE INDEX IF NOT EXISTS idx_action_metrics_action ON actionMetrics(actionId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_action_metrics_metric ON actionMetrics(metricId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_goal_metrics_goal ON goalMetrics(goalId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_goal_metrics_metric ON goalMetrics(metricId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_goal_relevance_goal ON goalRelevances(goalId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_goal_relevance_value ON goalRelevances(valueId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_contributions_action ON actionGoalContributions(actionId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_contributions_goal ON actionGoalContributions(goalId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_term_assignments_term ON termGoalAssignments(termId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_term_assignments_goal ON termGoalAssignments(goalId)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_values_level ON values(valueLevel)").execute(db)
                    try #sql("CREATE INDEX IF NOT EXISTS idx_metrics_type ON metrics(metricType)").execute(db)
                }

                // Migration 3: Remove measuresByUnit from actions (after data migration)
                migrator.registerMigration("Normalize actions table") { db in
                    // Check if measuresByUnit column exists
                    let columns = try db.columns(in: "actions")
                    if columns.contains(where: { $0.name == "measuresByUnit" }) {
                        // Create new actions table without measuresByUnit
                        try #sql(
                            """
                            CREATE TABLE IF NOT EXISTS "actions_normalized" (
                              "id" TEXT PRIMARY KEY NOT NULL,
                              "title" TEXT,
                              "detailedDescription" TEXT,
                              "freeformNotes" TEXT,
                              "durationMinutes" REAL,
                              "startTime" TEXT,
                              "logTime" TEXT NOT NULL
                            ) STRICT
                            """
                        ).execute(db)

                        // Copy data excluding measuresByUnit
                        try #sql(
                            """
                            INSERT INTO "actions_normalized" ("id", "title", "detailedDescription", "freeformNotes", "durationMinutes", "startTime", "logTime")
                            SELECT "id", "title", "detailedDescription", "freeformNotes", "durationMinutes", "startTime", "logTime"
                            FROM "actions"
                            """
                        ).execute(db)

                        // Drop old table and rename new one
                        try #sql("DROP TABLE IF EXISTS \"actions\"").execute(db)
                        try #sql("ALTER TABLE \"actions_normalized\" RENAME TO \"actions\"").execute(db)
                    }
                }

                try migrator.migrate(db)
                print("🟢 Database tables created successfully")
            } catch {
                print("❌ Failed to create DatabaseQueue: \(error)")
                fatalError("Database creation failed: \(error)")
            }
            $0.defaultDatabase = db
            print("🟢 defaultDatabase set")

            do {
                let syncEngine = try SyncEngine(
                    for: db,
                    privateTables: Action.self,
                    Goal.self,
                    GoalTerm.self,
                    TermGoalAssignment.self,
                    // Normalized models
                    Value.self,           // Unified values table
                    Metric.self,          // Metrics catalog
                    ActionMetric.self,    // Action measurements
                    GoalMetric.self,      // Goal targets
                    GoalRelevance.self,   // Goal-value alignments
                    ActionGoalContribution.self, // Action-goal progress
                    // Legacy models (for migration compatibility)
                    Models.Values.self,
                    MajorValues.self,
                    HighestOrderValues.self,
                    LifeAreas.self,
                    startImmediately: false
                )
                $0.defaultSyncEngine = syncEngine
                print("🟢 SyncEngine configured (not started yet)")

                Task {
                    do {
                        try await syncEngine.start()
                        print("✅ iCloud sync started successfully")
                    } catch {
                        print("⚠️ iCloud sync failed to start: \(error)")
                        print("   App will continue working locally without sync")
                    }
                }
            } catch {
                print("⚠️ Failed to initialize SyncEngine: \(error)")
                print("   App will continue working locally without sync")
            }
        }

        print("🟢 TenWeekGoalApp init() completed successfully")
    }

    // MARK: - Body

    public var body: some Scene {
        print("🟢 TenWeekGoalApp body accessed")
        return WindowGroup {
            ContentView()
                .environment(ZoomManager.shared)
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .textFormatting) {
                Button("Zoom In") {
                    ZoomManager.shared.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    ZoomManager.shared.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
                    ZoomManager.shared.resetZoom()
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandMenu("Sync") {
                Button("Sync Now") {
                    NotificationCenter.default.post(name: .syncNowRequested, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}
