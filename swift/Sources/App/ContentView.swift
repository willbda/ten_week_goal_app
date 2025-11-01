// ContentView.swift
// Root view for the application
//
// Written by Claude Code on 2025-10-19
// Refactored by Claude Code on 2025-10-20 for macOS NavigationSplitView
// Updated by Claude Code on 2025-10-23 for AI Assistant integration

import SwiftUI
import BusinessLogic
import SQLiteData

/// Root application view
/// Uses NavigationSplitView for persistent sidebar access.
public struct ContentView: View {

    // MARK: - Section Definition

    /// Main navigation sections
    enum Section: String, CaseIterable, Identifiable {
        case actions, goals, values, terms, assistant

        var id: String { rawValue }

        var title: String {
            switch self {
            case .assistant: return "AI Assistant"
            default: return rawValue.capitalized
            }
        }

        var subtitle: String {
            switch self {
            case .actions: return "Log progress"
            case .goals: return "10-week objectives and milestones"
            case .values: return "Stable principles"
            case .terms: return "Goal-setting periods"
            case .assistant: return "Reflect on your journey"
            }
        }

        var icon: String {
            switch self {
            case .actions: return "text.rectangle"
            case .goals: return "pencil.and.scribble"
            case .values: return "heart"
            case .terms: return "calendar"
            case .assistant: return "wand.and.stars"
            }
        }

        var accentColor: Color {
            switch self {
            case .actions: return .red.opacity(0.8)
            case .goals: return .orange.opacity(0.8)
            case .values: return .blue.opacity(0.8)
            case .terms: return .purple.opacity(0.8)
            case .assistant: return .indigo.opacity(0.8)
            }
        }
    }

    // MARK: - State

    @State private var selectedSection: Section? = .actions
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @Namespace private var sidebarAnimation
    @State private var aiAvailability = AIAssistantAvailability.shared

    // MARK: - Initialization

    public init() {
        print("🟢 ContentView init()")
    }

    // MARK: - Environment

    @Dependency(\.defaultSyncEngine) private var syncEngine


    // MARK: - Body

    public var body: some View {
        print("🟢 ContentView body accessed")
        return NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            sidebarContent
        } detail: {
            // Detail pane
            ZStack {
                detailContent
            }
            .animation(.smooth, value: selectedSection)
        }
        .background {
            Group {
                Button("Actions") { selectedSection = .actions }
                    .keyboardShortcut("1", modifiers: .command)

                Button("Goals") { selectedSection = .goals }
                    .keyboardShortcut("2", modifiers: .command)

                Button("Values") { selectedSection = .values }
                    .keyboardShortcut("3", modifiers: .command)

                Button("Terms") { selectedSection = .terms }
                    .keyboardShortcut("4", modifiers: .command)

                if aiAvailability.isAvailable {
                    Button("AI Assistant") { selectedSection = .assistant }
                        .keyboardShortcut("5", modifiers: .command)
                }

                Button("Sync Now") { forceSyncNow() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            .hidden()
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncNowRequested)) { _ in
            forceSyncNow()
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let zoom = ZoomManager.shared.zoomLevel

                let fullThreshold: CGFloat = 200 * zoom
                let textThreshold: CGFloat = 120 * zoom

                let textProgress = min(max((width - textThreshold) / (fullThreshold - textThreshold), 0), 1)
                let textOpacity = easeInOut(textProgress)

                let minIconSize: CGFloat = 20 * zoom
                let maxIconSize: CGFloat = 48 * zoom
                let iconSize = max(minIconSize, min(maxIconSize, width * 0.24))

                let cornerRadius = iconSize / 2

                let spacing = max(0, min(12 * zoom, (width - 80 * zoom) * 0.15))
                let iconFontSize = max(12 * zoom, iconSize * 0.42)

                let showText = width > 100 * zoom
                let visibleSections = Section.allCases.filter { section in
                    section != .assistant || aiAvailability.isAvailable
                }

                List(visibleSections, selection: $selectedSection) { section in
                    NavigationLink(value: section) {
                        HStack(spacing: spacing) {
                            ZStack {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(section.accentColor.opacity(0.15))
                                    .frame(width: iconSize, height: iconSize)
                                    .matchedGeometryEffect(
                                        id: "icon-\(section.rawValue)",
                                        in: sidebarAnimation,
                                        properties: .frame
                                    )

                                Image(systemName: section.icon)
                                    .font(.system(size: iconFontSize, weight: .medium))
                                    .foregroundStyle(section.accentColor)
                                    .symbolEffect(.scale.up, isActive: selectedSection == section)
                            }
                            .layoutPriority(1)
                            .frame(maxWidth: .infinity)

                            if showText {
                                HStack(spacing: 8 * zoom * textOpacity) {
                                    VStack(alignment: .leading, spacing: 2 * zoom) {
                                        Text(section.title)
                                            .font(DesignSystem.Typography.headline)
                                        Text(section.subtitle)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .opacity(textOpacity)
                                    .layoutPriority(0)

                                    Spacer(minLength: 0)

                                    if let count = activityCount(for: section) {
                                        Text("\(count)")
                                            .font(DesignSystem.Typography.caption.monospacedDigit())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6 * zoom)
                                            .padding(.vertical, 2 * zoom)
                                            .background(Capsule().fill(section.accentColor.opacity(0.8)))
                                            .opacity(textOpacity)
                                    }
                                }
                                .frame(minWidth: 0)
                            }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .animation(.smooth(duration: 0.25), value: width)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                }
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                
            }
            .navigationSplitViewColumnWidth(min: 60, ideal: 300, max: 400)
    }

    // MARK: - Easing Functions

    private func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    // MARK: - Activity Tracking

    private func activityCount(for section: Section) -> Int? {
        // TODO: Implement activity counts from database
        switch section {
        case .actions: return nil
        case .goals: return nil
        case .values: return nil
        case .terms: return nil
        case .assistant: return nil
        }
    }

    // MARK: - iCloud Sync

    /// Check iCloud sync status and log current state
    private func forceSyncNow() {
        print("🔄 iCloud Sync Status Check")
        print("─────────────────────────────────")
        print("  Running: \(syncEngine.isRunning ? "✅" : "❌")")
        print("  Sending changes: \(syncEngine.isSendingChanges ? "📤" : "💤")")
        print("  Fetching changes: \(syncEngine.isFetchingChanges ? "📥" : "💤")")
        print("  Synchronizing: \(syncEngine.isSynchronizing ? "🔄" : "⏸️")")
        print("─────────────────────────────────")

        if syncEngine.isRunning {
            print("ℹ️  Sync is active. Changes upload automatically:")
            print("   • In batches every 1-5 minutes")
            print("   • When you quit the app (⌘Q)")
            print("   • You can safely close this window")
        } else {
            print("⚠️  Sync engine is not running")
            print("   Try restarting the app")
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if let section = selectedSection {
            switch section {
            case .actions:
                ActionsListView()
            case .goals:
                GoalsListView()
            case .values:
                ValuesListView()
            case .terms:
                TermsListView()
            case .assistant:
                Text("Assistant Chat temporarily disabled")
                    .foregroundStyle(.secondary)
            }
        } else {
            welcomeView
        }
    }

    // MARK: - Status Views

    private var welcomeView: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.quaternary.opacity(0.3))
                    .frame(width: 120, height: 120)

                Image(systemName: "app.dashed")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
            }

            VStack(spacing: 8) {
                Text("Select a section to get started")
                    .font(.title2)
                    .foregroundStyle(.primary)

                Text("Use ⌘1-4 for quick navigation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
