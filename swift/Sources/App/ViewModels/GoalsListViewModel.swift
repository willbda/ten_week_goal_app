//
// GoalsListViewModel.swift
// Written by Claude Code on 2025-11-13
//
// PURPOSE:
// ViewModel for GoalsListView - manages goals list state and repository access.
// Eliminates @Fetch wrapper pattern in favor of direct repository access.
//
// ARCHITECTURE PATTERN:
// - @Observable for automatic UI updates (NOT ObservableObject)
// - @MainActor for UI thread safety
// - Lazy repository pattern for data access
// - Follows patterns from GoalProgressViewModel.swift and ActionFormViewModel.swift
//
// DATA FLOW:
// GoalRepository → GoalsListViewModel → GoalsListView
//

import Foundation
import Observation
import Dependencies
import Services
import Models

/// ViewModel for GoalsListView
///
/// **PATTERN**: Modern Swift 6 ViewModel
/// - Uses @Observable (Swift 5.9+) not ObservableObject
/// - @MainActor ensures UI updates on main thread
/// - Lazy repository pattern for efficient data access
///
/// **RESPONSIBILITIES**:
/// - Fetch goals from repository
/// - Handle loading/error states
/// - Provide data to view
/// - Manage delete operations
///
/// **USAGE**:
/// ```swift
/// @State private var viewModel = GoalsListViewModel()
///
/// .task {
///     await viewModel.loadGoals()
/// }
/// .refreshable {
///     await viewModel.loadGoals()
/// }
/// ```
@Observable
@MainActor
public final class GoalsListViewModel {

    // MARK: - Observable State (internal visibility)

    /// Goals data for display
    var goals: [GoalWithDetails] = []

    /// Loading state for UI feedback
    var isLoading: Bool = false

    /// Error message for user display
    var errorMessage: String?

    // MARK: - Computed Properties

    /// Whether there's an error to display
    var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Dependencies (not observable)

    /// Database dependency
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    /// Repository for data access (lazy initialization)
    @ObservationIgnored
    private lazy var repository: GoalRepository = {
        GoalRepository(database: database)
    }()

    // MARK: - Initialization

    public init() {}

    // MARK: - Data Loading

    /// Load all goals from repository
    ///
    /// Used for both initial load (.task) and refresh (.refreshable)
    /// Automatically updates observable properties which trigger UI updates.
    ///
    /// **Performance**: Single JSON aggregation query (1 database round trip)
    /// **Concurrency**: Runs on background thread via repository, returns to main actor
    public func loadGoals() async {
        isLoading = true
        errorMessage = nil

        do {
            goals = try await repository.fetchAll()
        } catch {
            errorMessage = "Failed to load goals: \(error.localizedDescription)"
            print("❌ GoalsListViewModel: \(error)")
        }

        isLoading = false
    }

    /// Delete a goal and reload the list
    ///
    /// - Parameter goalWithDetails: The goal to delete (includes full relationship graph)
    ///
    /// **Implementation**: Uses GoalCoordinator for atomic multi-table delete
    /// **Side Effects**: Reloads goals list after successful deletion
    public func deleteGoal(_ goalWithDetails: GoalWithDetails) async {
        isLoading = true
        errorMessage = nil

        do {
            // Use coordinator for atomic delete with cascading relationships
            // GoalWithDetails already contains all the data we need
            let coordinator = GoalCoordinator(database: database)
            try await coordinator.delete(
                goal: goalWithDetails.goal,
                expectation: goalWithDetails.expectation,
                targets: goalWithDetails.metricTargets.map(\.expectationMeasure),
                alignments: goalWithDetails.valueAlignments.map(\.goalRelevance),
                assignment: goalWithDetails.termAssignment
            )

            // Reload list after successful delete
            await loadGoals()
        } catch {
            errorMessage = "Failed to delete goal: \(error.localizedDescription)"
            print("❌ GoalsListViewModel: \(error)")
        }

        isLoading = false
    }
}
