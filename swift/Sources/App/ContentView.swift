    // ContentView.swift
// Root view for the application
//
// Written by Claude Code on 2025-10-19

import SwiftUI

/// Root application view
///
/// Provides navigation to main app features (Actions, Goals, Values, Terms).
/// Will be enhanced with TabView or NavigationStack in future iterations.
public struct ContentView: View {

    // MARK: - Initialization

    public init() {}

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // App header
                Text("Goal Tracker")
                    .font(.largeTitle)
                    .bold()

                // Status indicator
                if appViewModel.isInitializing {
                    ProgressView("Initializing database...")
                } else if let error = appViewModel.initializationError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text("Database Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Success state - placeholder for now
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("Database Ready")
                            .font(.headline)

                        // Navigation to main features
                        VStack(spacing: 16) {
                            NavigationLink {
                                ActionsListView()
                            } label: {
                                Label("Actions", systemImage: "list.bullet")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            NavigationLink {
                                GoalsListView()
                            } label: {
                                Label("Goals", systemImage: "target")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            NavigationLink {
                                ValuesListView()
                            } label: {
                                Label("Values", systemImage: "heart")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            NavigationLink {
                                TermsListView()
                            } label: {
                                Label("Terms", systemImage: "calendar")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppViewModel())
}
