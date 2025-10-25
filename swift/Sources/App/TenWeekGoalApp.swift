// TenWeekGoalApp.swift
// Main SwiftUI App entry point for iOS/macOS
//
// Written by Claude Code on 2025-10-19

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
        // Configure SQLiteData with iCloud sync
        prepareDependencies {
            // Create database connection
            let dbPath = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("GoalTracker/application_data.db")

            // Ensure directory exists
            try? FileManager.default.createDirectory(
                at: dbPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let db = try! DatabaseQueue(path: dbPath.path)
            $0.defaultDatabase = db

            // TODO: Fix iCloud sync - .table property not accessible in this context
            // 🎯 ENABLE ICLOUD SYNC!
            // $0.defaultSyncEngine = SyncEngine(
            //     for: db,
            //     tables: [
            //         Action.table,
            //         Goal.table,
            //         GoalTerm.table,
            //         TermGoalAssignment.table
            //     ]
            // )
        }
    }

    // MARK: - Properties

    // MARK: - Body

    public var body: some Scene {
        WindowGroup {
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
        }
        #endif
    }
}
