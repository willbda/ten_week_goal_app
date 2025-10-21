// ContentView.swift
// Root view for the application
//
// Written by Claude Code on 2025-10-19
// Refactored by Claude Code on 2025-10-20 for macOS NavigationSplitView

import SwiftUI

/// Root application view
///
/// Provides macOS-native sidebar navigation to main app features (Actions, Goals, Values, Terms).
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
            case .actions: return "Daily tasks and immediate steps"
            case .goals: return "10-week objectives and milestones"
            case .values: return "Core principles and priorities"
            case .terms: return "10-week planning periods"
            }
        }

        var icon: String {
            switch self {
            case .actions: return "bolt.fill"
            case .goals: return "target"
            case .values: return "heart.fill"
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

    // MARK: - Initialization

    public init() {}

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - Body

    public var body: some View {
        NavigationSplitView {
            // Sidebar
            sidebarContent
        } detail: {
            // Detail pane
            if appViewModel.isInitializing {
                initializingView
            } else if let error = appViewModel.initializationError {
                errorView(error: error)
            } else {
                detailContent
            }
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
                            Image(systemName: section.icon)
                                .font(.title)
                                .foregroundStyle(section.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        } else {
                            // Full layout with icon and text
                            HStack(spacing: 12) {
                                Image(systemName: section.icon)
                                    .font(.title2)
                                    .foregroundStyle(section.accentColor)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                Text(section.title)
                                    .font(.headline)
                                Text(section.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(isCompact ? "" : "Quests")
        }
        .navigationSplitViewColumnWidth(min: 60, ideal: 300)
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
        VStack(spacing: 20) {
            Image(systemName: "app.dashed")
                .font(.system(size: 72))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("Select a section to get started")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var initializingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Initializing database...")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red.opacity(0.8))

            Text("Database Error")
                .font(.title)
                .bold()

            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppViewModel())
}
