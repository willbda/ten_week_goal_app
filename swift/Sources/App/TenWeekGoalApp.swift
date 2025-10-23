// TenWeekGoalApp.swift
// Main SwiftUI App entry point for iOS/macOS
//
// Written by Claude Code on 2025-10-19

import SwiftUI
import Database

/// Main application entry point
///
/// Manages app lifecycle and provides root view with database access.
/// Uses SwiftUI's modern App lifecycle (iOS 14+/macOS 11+).
///
/// Note: No @main attribute - this is launched from AppRunner/main.swift
/// The activation policy is set in main.swift to ensure proper macOS GUI behavior.
public struct TenWeekGoalApp: App {

    // MARK: - Initialization

    public init() {}

    // MARK: - Properties

    /// Root app state management
    @State private var appViewModel = AppViewModel()

    // MARK: - Body

    public var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .environment(ZoomManager.shared)
                .task {
                    // Initialize database on app launch
                    await appViewModel.initialize()
                }
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
