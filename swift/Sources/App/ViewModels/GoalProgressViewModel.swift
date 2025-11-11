//
// GoalProgressViewModel.swift
// Written by Claude Code on 2025-11-10
//
// PURPOSE:
// ViewModel for goal progress dashboard - orchestrates repository and service layers.
// Manages UI state and coordinates data flow from database to view.
//
// ARCHITECTURE PATTERN:
// **PERMANENT PATTERN**: Modern Swift 6 ViewModel
// - @Observable for automatic UI updates (NOT ObservableObject)
// - @MainActor for UI thread safety
// - Lazy coordinator pattern for repository access
// - Service layer for business logic
//
// DATA FLOW:
// GoalRepository → ProgressCalculationService → GoalProgressViewModel → View
//

import Foundation
import Observation
import Dependencies
import Services
import Models

/// ViewModel for goal progress dashboard
///
/// **PERMANENT PATTERN**: Standard ViewModel architecture
/// - Uses @Observable (Swift 5.9+) not ObservableObject
/// - @MainActor ensures UI updates on main thread
/// - Coordinates between repository (data) and service (logic)
@Observable
@MainActor
public final class GoalProgressViewModel {

    // MARK: - Published State (Auto-observable)

    /// Processed goal progress data ready for UI
    var goalProgress: [GoalProgress] = []

    /// Aggregate statistics for dashboard summary
    var dashboardStats: DashboardStats?

    /// Loading state for UI feedback
    var isLoading = false

    /// Error message for user display
    var errorMessage: String?

    /// Last refresh timestamp
    var lastRefreshed: Date?

    /// Filter state (temporary - will enhance later)
    var showOnlyBehind = false

    /// Sort preference
    var sortBy: SortOption = .urgency

    // MARK: - Dependencies (Not observable)

    /// Database dependency
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database

    /// Repository for data access (lazy initialization)
    @ObservationIgnored
    private lazy var goalRepository: GoalRepository = {
        GoalRepository(database: database)
    }()

    /// Service for business logic
    @ObservationIgnored
    private let progressService = ProgressCalculationService()

    // MARK: - Initialization

    public init() {
        // Empty init - data loaded via .task modifier
    }

    // MARK: - Data Loading

    /// Load goal progress data
    ///
    /// **PERMANENT PATTERN**: Async data loading
    /// - Repository fetches raw data (background thread)
    /// - Service processes business logic
    /// - Updates published state (main thread)
    public func loadGoalProgress() async {
        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Fetch raw data from repository (runs in background)
            let rawProgressData = try await goalRepository.fetchAllWithProgress()

            // Step 2: Apply business logic via service
            let processedProgress = progressService.calculateProgress(from: rawProgressData)

            // Step 3: Calculate aggregate stats
            let stats = progressService.calculateAggregateStats(processedProgress)

            // Step 4: Update UI state (already on main actor)
            self.goalProgress = applyFiltersAndSort(processedProgress)
            self.dashboardStats = stats
            self.lastRefreshed = Date.now
            self.errorMessage = nil

        } catch {
            // Handle errors gracefully
            self.errorMessage = mapErrorMessage(error)
            self.goalProgress = []
            self.dashboardStats = nil
        }

        isLoading = false
    }

    /// Refresh data (pull-to-refresh)
    public func refresh() async {
        await loadGoalProgress()
    }

    // MARK: - Filtering and Sorting

    /// Apply current filters and sort preference
    ///
    /// **TEMPORARY**: Basic filtering
    /// **FUTURE**: Advanced filters (by term, value, date range)
    private func applyFiltersAndSort(_ goals: [GoalProgress]) -> [GoalProgress] {
        var filtered = goals

        // Apply filter
        if showOnlyBehind {
            filtered = filtered.filter {
                $0.status == .behind || $0.status == .overdue
            }
        }

        // Apply sort
        switch sortBy {
        case .urgency:
            // Sort by status urgency, then days remaining
            return filtered.sorted { a, b in
                if a.status != b.status {
                    return statusPriority(a.status) < statusPriority(b.status)
                }
                if let daysA = a.daysRemaining, let daysB = b.daysRemaining {
                    return daysA < daysB
                }
                return a.percentComplete < b.percentComplete
            }

        case .alphabetical:
            return filtered.sorted { $0.title < $1.title }

        case .percentComplete:
            return filtered.sorted { $0.percentComplete < $1.percentComplete }

        case .dueDate:
            return filtered.sorted { a, b in
                let dateA = a.daysRemaining ?? Int.max
                let dateB = b.daysRemaining ?? Int.max
                return dateA < dateB
            }
        }
    }

    /// Priority order for status (lower = more urgent)
    private func statusPriority(_ status: ProgressStatus) -> Int {
        switch status {
        case .overdue: return 1
        case .behind: return 2
        case .notStarted: return 3
        case .onTrack: return 4
        case .complete: return 5
        }
    }

    /// Toggle filter for behind/overdue goals
    public func toggleBehindFilter() {
        showOnlyBehind.toggle()
        goalProgress = applyFiltersAndSort(goalProgress)
    }

    /// Update sort preference
    public func updateSort(_ option: SortOption) {
        sortBy = option
        goalProgress = applyFiltersAndSort(goalProgress)
    }

    // MARK: - Error Handling

    /// Map errors to user-friendly messages
    ///
    /// **PERMANENT PATTERN**: Centralized error handling
    private func mapErrorMessage(_ error: Error) -> String {
        if let validationError = error as? ValidationError {
            return validationError.userMessage
        }

        // Generic database errors
        if error.localizedDescription.contains("database") {
            return "Unable to load goals. Please try again."
        }

        return "An unexpected error occurred: \(error.localizedDescription)"
    }

    // MARK: - Computed Properties

    /// Quick access to urgent goals
    var urgentGoals: [GoalProgress] {
        goalProgress.filter { $0.isUrgent }
    }

    /// Check if any goals need attention
    var hasGoalsNeedingAttention: Bool {
        goalProgress.contains { goal in
            goal.status == .behind || goal.status == .overdue
        }
    }

    /// Summary text for dashboard header
    var summaryText: String {
        guard let stats = dashboardStats else {
            return "No goals to display"
        }

        if stats.totalGoals == 0 {
            return "No goals created yet"
        }

        let behindCount = stats.behindGoals + stats.overdueGoals
        if behindCount > 0 {
            return "\(behindCount) goal\(behindCount == 1 ? "" : "s") need attention"
        }

        if stats.onTrackGoals > 0 {
            return "\(stats.onTrackGoals) goal\(stats.onTrackGoals == 1 ? "" : "s") on track"
        }

        if stats.completedGoals == stats.totalGoals {
            return "All goals complete! 🎉"
        }

        return "\(stats.completedGoals) of \(stats.totalGoals) complete"
    }
}

// MARK: - Supporting Types

/// Sort options for goal list
public enum SortOption: String, CaseIterable {
    case urgency = "Urgency"
    case alphabetical = "A-Z"
    case percentComplete = "Progress"
    case dueDate = "Due Date"
}

// MARK: - Preview Support

#if DEBUG
extension GoalProgressViewModel {
    /// Create view model with mock data for previews
    ///
    /// **TEMPORARY**: Mock data for SwiftUI previews
    /// Will be replaced with preview database in future
    static var preview: GoalProgressViewModel {
        let vm = GoalProgressViewModel()

        // Create mock progress data
        vm.goalProgress = [
            GoalProgress(
                id: UUID(),
                title: "Run 120km",
                measureName: "Distance",
                measureUnit: "km",
                currentProgress: 45,
                targetValue: 120,
                percentComplete: 37.5,
                status: .behind,
                daysRemaining: 15,
                projectedCompletion: nil,
                dailyTargetRate: 5.0,
                currentDailyRate: 3.0
            ),
            GoalProgress(
                id: UUID(),
                title: "Read 12 Books",
                measureName: "Books",
                measureUnit: "books",
                currentProgress: 8,
                targetValue: 12,
                percentComplete: 66.7,
                status: .onTrack,
                daysRemaining: 30,
                projectedCompletion: Date().addingTimeInterval(86400 * 25),
                dailyTargetRate: 0.13,
                currentDailyRate: 0.15
            ),
            GoalProgress(
                id: UUID(),
                title: "Learn Swift",
                measureName: "Hours",
                measureUnit: "hours",
                currentProgress: 100,
                targetValue: 100,
                percentComplete: 100,
                status: .complete,
                daysRemaining: nil,
                projectedCompletion: nil,
                dailyTargetRate: nil,
                currentDailyRate: nil
            )
        ]

        vm.dashboardStats = DashboardStats(
            totalGoals: 3,
            completedGoals: 1,
            onTrackGoals: 1,
            behindGoals: 1,
            overdueGoals: 0,
            overallCompletionPercent: 68.1
        )

        vm.lastRefreshed = Date()

        return vm
    }

    /// Empty state for preview
    static var previewEmpty: GoalProgressViewModel {
        let vm = GoalProgressViewModel()
        vm.goalProgress = []
        vm.dashboardStats = DashboardStats(
            totalGoals: 0,
            completedGoals: 0,
            onTrackGoals: 0,
            behindGoals: 0,
            overdueGoals: 0,
            overallCompletionPercent: 0
        )
        return vm
    }

    /// Loading state for preview
    static var previewLoading: GoalProgressViewModel {
        let vm = GoalProgressViewModel()
        vm.isLoading = true
        return vm
    }
}
#endif

// MARK: - Implementation Notes

// VIEWMODEL PATTERN (PERMANENT)
//
// This demonstrates the production ViewModel pattern:
// 1. @Observable + @MainActor for UI state management
// 2. Lazy repository initialization with @ObservationIgnored
// 3. Service layer for business logic separation
// 4. Async/await for clean concurrent code
// 5. Centralized error handling
//
// DATA FLOW:
// 1. View calls loadGoalProgress() on appear
// 2. Repository fetches raw data (background thread)
// 3. Service applies business logic
// 4. ViewModel updates @Observable state (main thread)
// 5. SwiftUI automatically updates view
//
// TEMPORARY ELEMENTS:
// - Basic filtering (will add advanced filters)
// - Simple sorting (will add custom sort options)
// - Mock preview data (will use preview database)
//
// PERMANENT PATTERNS:
// - Three-layer architecture (Repository → Service → ViewModel)
// - @Observable pattern (not ObservableObject)
// - Lazy coordinator pattern
// - Async/await for data loading
// - Centralized error mapping