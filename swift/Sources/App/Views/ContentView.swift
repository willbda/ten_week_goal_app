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
              // Tab 1: Actions (Sprint 1 - Complete)
              ActionsListView()
                  .tabItem {
                      Label("Actions", systemImage: "checkmark.circle")
                  }

              // Tab 2: Terms (UI only - no persistence)
              TermsPlaceholder()
                  .tabItem {
                      Label("Terms", systemImage: "calendar")
                  }

              // Tab 3: Goals (Future Sprint 2)
              PlaceholderTab(
                  icon: "target",
                  title: "Goals",
                  subtitle: "Coming in Sprint 2"
              )
              .tabItem {
                  Label("Goals", systemImage: "target")
              }

              // Tab 4: Values (Phase 3 - Complete)
              PersonalValuesListView()
              .tabItem {
                  Label("Values", systemImage: "heart.fill")
              }
          }
      }
  }

  // MARK: - Placeholder Views

  /// Placeholder for Terms tab (TermFormView exists but no list view yet)
  private struct TermsPlaceholder: View {
      @State private var showingForm = false

      var body: some View {
          NavigationStack {
              VStack(spacing: 20) {
                  Image(systemName: "calendar")
                      .font(.system(size: 60))
                      .foregroundStyle(.blue)

                  Text("Terms")
                      .font(.largeTitle)
                      .fontWeight(.bold)

                  Text("UI components ready")
                      .font(.subheadline)
                      .foregroundStyle(.secondary)

                  Button("Try Term Form") {
                      showingForm = true
                  }
                  .buttonStyle(.borderedProminent)
              }
              .navigationTitle("Terms")
              .sheet(isPresented: $showingForm) {
                  TermFormView { formData in
                      print("Term validated: \(formData.termNumber)")
                  }
              }
          }
      }
  }

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

