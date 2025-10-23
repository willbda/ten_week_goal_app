// ContentView.swift
// Root view for the application
//
// Written by Claude Code on 2025-10-19
// Refactored by Claude Code on 2025-10-20 for macOS NavigationSplitView

import SwiftUI

/// Root application view
/// Uses NavigationSplitView for persistent sidebar access.
public struct ContentView: View {

    // MARK: - Section Definition

    /// Main navigation sections
    enum Section: String, CaseIterable, Identifiable {
        case actions, goals, values, terms

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }

        var subtitle: String {
            switch self {
            case .actions: return "Log progress"
            case .goals: return "10-week objectives and milestones"
            case .values: return "Stable principles"
            case .terms: return "Goal-setting periods"
            }
        }

        var icon: String {
            switch self {
            case .actions: return "bolt.fill"
            case .goals: return "target"
            case .values: return "heart"
            case .terms: return "calendar"
            }
        }

        var accentColor: Color {
            switch self {
            case .actions: return .red.opacity(0.8)
            case .goals: return .orange.opacity(0.8)
            case .values: return .blue.opacity(0.8)
            case .terms: return .purple.opacity(0.8)
            }
        }
    }

    // MARK: - State

    @State private var selectedSection: Section? = .actions
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    // MARK: - Initialization

    public init() {}

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - Body

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            sidebarContent
        } detail: {
            // Detail pane
            ZStack {
                if appViewModel.isInitializing {
                    initializingView
                } else if let error = appViewModel.initializationError {
                    errorView(error: error)
                } else {
                    detailContent
                }
            }
            .animation(.smooth, value: selectedSection)
        }
        .background {
            // Hidden buttons for keyboard shortcuts
            Group {
                Button("Actions") { selectedSection = .actions }
                    .keyboardShortcut("1", modifiers: .command)

                Button("Goals") { selectedSection = .goals }
                    .keyboardShortcut("2", modifiers: .command)

                Button("Values") { selectedSection = .values }
                    .keyboardShortcut("3", modifiers: .command)

                Button("Terms") { selectedSection = .terms }
                    .keyboardShortcut("4", modifiers: .command)
            }
            .hidden()
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebarContent: some View {
            GeometryReader { geometry in
                let isCompact = geometry.size.width < 150

                List(Section.allCases, selection: $selectedSection) { section in
                    NavigationLink(value: section) {
                        if isCompact {
                            // Icon-only layout for narrow sidebar
                            ZStack {
                                Circle()
                                    .fill(section.accentColor.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: section.icon)
                                    .font(.title2)
                                    .foregroundStyle(section.accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            // Full layout with enhanced materials
                            HStack(spacing: 14) {
                                // Material-backed icon container
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(section.accentColor.opacity(0.15))
                                        .frame(width: 38, height: 38)

                                    Image(systemName: section.icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(section.accentColor)
                                        .symbolEffect(.scale.up, isActive: selectedSection == section)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(section.title)
                                        .font(.headline)
                                    Text(section.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Activity indicator
                                if let count = activityCount(for: section) {
                                    Text("\(count)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(section.accentColor.opacity(0.8)))
                                }
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                }
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .navigationTitle(isCompact ? "" : "Quests")
            }
            .navigationSplitViewColumnWidth(min: 60, ideal: 300)
    }

    // MARK: - Activity Tracking

    private func activityCount(for section: Section) -> Int? {
        // TODO(human): Implement activity counts from database
        // This should return actual counts based on your business logic:
        // - Actions: Count of today's actions
        // - Goals: Count of active goals
        // - Values: Count of defined values
        // - Terms: Current term week number
        switch section {
        case .actions: return nil
        case .goals: return nil
        case .values: return nil
        case .terms: return nil
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
            }
        } else {
            welcomeView
        }
    }

    // MARK: - Status Views

    private var welcomeView: some View {
        VStack(spacing: 24) {
            // Material-backed icon
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

    private var initializingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

            Text("Initializing database...")
                .font(.title2)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: 24) {
            // Error icon with material backing
            ZStack {
                Circle()
                    .fill(.red.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            VStack(spacing: 12) {
                Text("Database Error")
                    .font(.title)
                    .bold()

                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button("Retry") {
                    Task {
                        await appViewModel.initialize()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppViewModel())
}
