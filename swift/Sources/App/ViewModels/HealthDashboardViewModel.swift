//
// HealthDashboardViewModel.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// ViewModel for real-time health metrics dashboard with live HealthKit tracking.
// Manages authorization, live queries, and state for step/distance/energy metrics.
//
// ARCHITECTURE PATTERN:
// - @Observable (Swift 5.9+, NOT ObservableObject)
// - @MainActor for UI-safe state updates
// - Dependencies injected via @Dependency macro
// - No business logic in ViewModel (just coordination)
//
// USAGE:
// ```swift
// @State private var viewModel = HealthDashboardViewModel()
//
// var body: some View {
//     Text("\(viewModel.dailySteps) steps")
//         .task {
//             await viewModel.requestAuthorizationAndStart()
//         }
//         .onDisappear {
//             viewModel.stopLiveTracking()
//         }
// }
// ```
//

import Foundation
import Observation
import Dependencies
import Services

// MARK: - Authorization Status Wrapper

/// Cross-platform authorization status
///
/// Wraps HealthKitManager.AuthorizationStatus for platform compatibility
public enum HealthAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

/// ViewModel for health metrics dashboard with live tracking
///
/// **State Management**: Uses @Observable (Swift 5.9+) for automatic UI updates
/// - No @Published needed (compiler generates observation automatically)
/// - Properties update SwiftUI views when changed
///
/// **Services**:
/// - HealthKitManager: Authorization and manual queries
/// - HealthKitLiveTrackingService: Real-time monitoring with HKAnchoredObjectQuery
///
/// **Lifecycle**:
/// 1. Init: Creates service instances
/// 2. requestAuthorizationAndStart(): Requests HealthKit permission
/// 3. startLiveTracking(): Starts HKAnchoredObjectQuery monitors
/// 4. stopLiveTracking(): Stops all queries (call on view disappear)
@Observable
@MainActor
public final class HealthDashboardViewModel {

    // MARK: - Published State (automatically observable)

    /// Current step count for today (cumulative)
    var dailySteps: Int = 0

    /// Current distance for today in kilometers
    var dailyDistance: Double = 0.0

    /// Current active energy burned in kcal
    var activeEnergy: Double = 0.0

    /// User's daily step goal (configurable)
    var stepGoal: Int = 10000

    /// Whether live tracking is active
    var isTracking: Bool = false

    /// Last time metrics were updated
    var lastUpdated: Date = .now

    /// HealthKit authorization status
    var authorizationStatus: HealthAuthorizationStatus = .notDetermined

    /// Error message for UI display
    var errorMessage: String?

    // MARK: - Services (not observable)

    /// Live tracking service for HKAnchoredObjectQuery monitoring
    @ObservationIgnored
    private let liveTrackingService = HealthKitLiveTrackingService()

    /// HealthKit manager for authorization and manual queries
    @ObservationIgnored
    private let healthKitManager = HealthKitManager.shared

    /// Active query IDs for selective cancellation
    @ObservationIgnored
    private var activeQueryIDs: [UUID] = []

    // MARK: - Initialization

    public init() {
        print("📊 HealthDashboardViewModel initialized")
    }

    // MARK: - Authorization

    /// Request HealthKit authorization and start live tracking if granted
    ///
    /// Call this from .task {} modifier on view appear.
    /// - Requests authorization for workouts, sleep, mindfulness, steps, distance, energy
    /// - Automatically starts live tracking if authorized
    /// - Updates authorizationStatus property
    public func requestAuthorizationAndStart() async {
        do {
            try await healthKitManager.requestAuthorization()
            authorizationStatus = mapAuthStatus(healthKitManager.authorizationStatus)

            if authorizationStatus == .authorized {
                print("✅ HealthKit authorized - starting live tracking")
                startLiveTracking()
            } else {
                print("⚠️ HealthKit not authorized: \(authorizationStatus)")
                errorMessage = "HealthKit access required for live tracking"
            }
        } catch {
            print("❌ Authorization failed: \(error)")
            errorMessage = "Failed to authorize HealthKit: \(error.localizedDescription)"
        }
    }

    /// Check if already authorized without prompting
    ///
    /// Call this on init to skip authorization prompt if already granted.
    /// - Returns: True if authorized, false otherwise
    public func checkExistingAuthorization() -> Bool {
        let isAuthorized = healthKitManager.checkAuthorizationStatus()
        authorizationStatus = mapAuthStatus(healthKitManager.authorizationStatus)
        return isAuthorized
    }

    // MARK: - Live Tracking

    /// Start live tracking for all health metrics
    ///
    /// Starts HKAnchoredObjectQuery monitors for:
    /// - Step count (HKQuantityTypeIdentifier.stepCount)
    /// - Distance (HKQuantityTypeIdentifier.distanceWalkingRunning)
    /// - Active energy (HKQuantityTypeIdentifier.activeEnergyBurned)
    ///
    /// **Important**: Only call after authorization granted.
    /// Queries auto-update when new HealthKit samples added.
    public func startLiveTracking() {
        guard !isTracking else {
            print("⚠️ Already tracking")
            return
        }

        // Start step tracking
        let stepQueryID = liveTrackingService.startStepTracking { [weak self] steps in
            Task { @MainActor in
                self?.dailySteps = steps
                self?.lastUpdated = .now
                print("📊 Steps updated: \(steps)")
            }
        }
        activeQueryIDs.append(stepQueryID)

        // Start distance tracking
        let distanceQueryID = liveTrackingService.startDistanceTracking { [weak self] distance in
            Task { @MainActor in
                self?.dailyDistance = distance
                self?.lastUpdated = .now
                print("📊 Distance updated: \(String(format: "%.1f", distance)) km")
            }
        }
        activeQueryIDs.append(distanceQueryID)

        // Start active energy tracking
        let energyQueryID = liveTrackingService.startActiveEnergyTracking { [weak self] energy in
            Task { @MainActor in
                self?.activeEnergy = energy
                self?.lastUpdated = .now
                print("📊 Energy updated: \(String(format: "%.0f", energy)) kcal")
            }
        }
        activeQueryIDs.append(energyQueryID)

        isTracking = true
        print("✅ Live tracking started (\(activeQueryIDs.count) queries)")
    }

    /// Stop live tracking for all metrics
    ///
    /// Call this from .onDisappear {} to prevent battery drain.
    /// Stops all active HKAnchoredObjectQuery monitors.
    public func stopLiveTracking() {
        guard isTracking else { return }

        liveTrackingService.stopAllTracking()
        activeQueryIDs.removeAll()
        isTracking = false

        print("⏹️ Live tracking stopped")
    }

    // MARK: - Manual Refresh

    /// Manually refresh current metrics (without live tracking)
    ///
    /// Useful for:
    /// - Initial data load before live tracking starts
    /// - Pull-to-refresh functionality
    /// - Verifying live tracking accuracy
    ///
    /// **Note**: This is a one-time query, not continuous monitoring.
    /// Use startLiveTracking() for real-time updates.
    public func refreshMetrics() async {
        // TODO: Implement manual queries using HealthKitManager
        // For now, live tracking handles all updates
        print("🔄 Manual refresh not yet implemented (use live tracking)")
    }

    // MARK: - Computed Properties

    /// Progress toward daily step goal (0.0 to 1.0+)
    var stepProgressPercentage: Double {
        Double(dailySteps) / Double(stepGoal)
    }

    /// Whether user has reached or exceeded step goal
    var hasReachedStepGoal: Bool {
        dailySteps >= stepGoal
    }

    /// Formatted distance string: "5.2 km"
    var formattedDistance: String {
        String(format: "%.1f km", dailyDistance)
    }

    /// Formatted active energy string: "387 kcal"
    var formattedActiveEnergy: String {
        String(format: "%.0f kcal", activeEnergy)
    }

    /// Formatted last updated time: "3:42 PM"
    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }

    /// Formatted step goal string: "10,000"
    var formattedStepGoal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: stepGoal)) ?? "\(stepGoal)"
    }

    /// Formatted daily steps string: "8,537"
    var formattedDailySteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: dailySteps)) ?? "\(dailySteps)"
    }

    // MARK: - Configuration

    /// Update daily step goal
    ///
    /// - Parameter goal: New step goal (must be > 0)
    ///
    /// TODO: Persist to UserDefaults or database
    public func updateStepGoal(_ goal: Int) {
        guard goal > 0 else {
            print("⚠️ Invalid step goal: \(goal)")
            return
        }

        stepGoal = goal
        print("✅ Step goal updated to \(goal)")

        // TODO: Save to UserDefaults
        // UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
    }

    // MARK: - Cleanup

    deinit {
        // Note: Can't access @MainActor properties from deinit
        // Caller should call stopLiveTracking() in onDisappear
        print("🧹 HealthDashboardViewModel deinit")
    }

    // MARK: - Private Helpers

    /// Map HealthKitManager.AuthorizationStatus to HealthAuthorizationStatus
    private func mapAuthStatus(_ status: HealthKitManager.AuthorizationStatus) -> HealthAuthorizationStatus {
        #if os(iOS)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .unavailable:
            return .unavailable
        }
        #else
        return .unavailable
        #endif
    }
}

// MARK: - Preview Support

#if DEBUG
extension HealthDashboardViewModel {
    /// Create view model with mock data for SwiftUI previews
    static var preview: HealthDashboardViewModel {
        let vm = HealthDashboardViewModel()
        vm.dailySteps = 8537
        vm.dailyDistance = 6.8
        vm.activeEnergy = 412
        vm.stepGoal = 10000
        vm.isTracking = true
        vm.authorizationStatus = .authorized
        vm.lastUpdated = Date()
        return vm
    }

    /// Create view model with goal reached for preview
    static var previewGoalReached: HealthDashboardViewModel {
        let vm = HealthDashboardViewModel()
        vm.dailySteps = 12847
        vm.dailyDistance = 10.2
        vm.activeEnergy = 687
        vm.stepGoal = 10000
        vm.isTracking = true
        vm.authorizationStatus = .authorized
        vm.lastUpdated = Date()
        return vm
    }

    /// Create view model with no data for preview
    static var previewEmpty: HealthDashboardViewModel {
        let vm = HealthDashboardViewModel()
        vm.authorizationStatus = .notDetermined
        return vm
    }
}
#endif
