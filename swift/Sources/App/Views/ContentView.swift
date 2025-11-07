//
  // ContentView.swift
  // Root view for TenWeekGoalApp
  //
  // Updated by Claude Code on 2025-11-01

  import SwiftUI

  /// Root view for the application
  ///
  /// Provides tab-based navigation to Actions and Terms features.
  /// Additional tabs (Goals, Values) will be added in future sprints.
  public struct ContentView: View {

      public init() {}

      public var body: some View {
          TabView {
              // Tab 1: Actions (Phase 1 Complete - Full CRUD)
              NavigationStack {
                  ActionsListView()
              }
              .tabItem {
                  Label("Actions", systemImage: "checkmark.circle")
              }

              // Tab 2: Terms (Phase 1 - Complete)
              NavigationStack {
                  TermsListView()
              }
              .tabItem {
                  Label("Terms", systemImage: "calendar")
              }

              // Tab 3: Goals (Future Sprint 2)
              NavigationStack {
                  GoalsListView()
              }.tabItem{
                  Label("Goals", systemImage: "target")

              }

              // Tab 4: Values (Phase 3 - Complete)
              NavigationStack {
                  PersonalValuesListView()
              }
              .tabItem {
                  Label("Values", systemImage: "heart.fill")
              }

              // Tab 5: Import (your addition - working)
              NavigationStack {
                  CSVExportImportView()
              }
              .tabItem {
                  Label("Import", systemImage: "arrow.2.circlepath.circle")
              }

              // Tab 6: Health (iOS only - HealthKit workouts)
              #if os(iOS)
              NavigationStack {
                  WorkoutsTestView()
              }
              .tabItem {
                  Label("Health", systemImage: "heart.text.square")
              }
              #endif
          }
      }
  }

  // MARK: - Placeholder Views

  /// Generic placeholder for future tabs
  private struct PlaceholderTab: View {
      let icon: String
      let title: String
      let subtitle: String

      var body: some View {
          NavigationStack {
              VStack(spacing: 20) {
                  Image(systemName: icon)
                      .font(.system(size: 60))
                      .foregroundStyle(.gray)

                  Text(title)
                      .font(.largeTitle)
                      .fontWeight(.bold)

                  Text(subtitle)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
              }
              .navigationTitle(title)
          }
      }
  }

  #Preview {
      ContentView()
  }

