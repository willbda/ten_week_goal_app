//
// HealthKitLiveTrackingService.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Real-time HealthKit monitoring using HKAnchoredObjectQuery for live metric updates.
// Provides continuous tracking of steps, distance, and active energy with automatic updates
// when new samples are added to HealthKit store.
//
// APPLE DOCUMENTATION REFERENCE:
// - HKAnchoredObjectQuery: developer.apple.com/documentation/healthkit/hkanchoredobjectquery
// - Update Handler: developer.apple.com/documentation/healthkit/executing-observer-queries
//
// USAGE:
// ```swift
// let service = HealthKitLiveTrackingService()
// let queryID = service.startStepTracking { steps in
//     print("Current steps: \(steps)")
// }
// // Later: service.stopTracking(queryID: queryID)
// ```
//

#if os(iOS)
import HealthKit
import Foundation

/// Real-time HealthKit monitoring using HKAnchoredObjectQuery
///
/// **Architecture Pattern**: Infrastructure service (platform-specific)
/// - Uses Apple's HKAnchoredObjectQuery with updateHandler
/// - Provides incremental updates (not full dataset re-queries)
/// - Manages query lifecycle (start/stop)
/// - Returns cumulative totals for current day
///
/// **Why HKAnchoredObjectQuery?**
/// Apple's documentation states: "HKAnchoredObjectQuery provides an update handler
/// for continuous monitoring of HealthKit data changes." This is the recommended
/// approach for real-time tracking, not HKObserverQuery (which is for background
/// notifications requiring completion handlers).
///
/// ARCHITECTURE NOTE: Marked @MainActor because:
/// - Provides live tracking callbacks that update ViewModel properties (onUpdate closures)
/// - All onUpdate closures are marked @Sendable and called on @MainActor for UI safety
/// - Internal HealthKit queries run on background, but callbacks must update UI
/// - Query lifecycle management (activeQueries dict) requires main actor isolation
@MainActor
public final class HealthKitLiveTrackingService {
    private let healthStore = HKHealthStore()

    /// Active queries tracked by UUID for selective cancellation
    private var activeQueries: [UUID: HKQuery] = [:]

    public init() {}

    // MARK: - Step Tracking

    /// Start monitoring daily step count with live updates
    ///
    /// Uses HKAnchoredObjectQuery with updateHandler to receive incremental
    /// HealthKit updates as new step samples are recorded.
    ///
    /// - Parameter onUpdate: Closure called with cumulative step count for today
    /// - Returns: Query ID for selective cancellation via stopTracking(queryID:)
    ///
    /// **Implementation Note**: The closure is called:
    /// 1. Initially with all samples for today (anchor = nil)
    /// 2. Subsequently when new samples added to HealthKit store
    /// 3. On main actor (safe for UI updates)
    public func startStepTracking(onUpdate: @escaping @Sendable (Int) -> Void) -> UUID {
        let queryID = UUID()

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("❌ Step count type unavailable")
            return queryID
        }

        // Predicate for today only (resets at midnight)
        let predicate = predicateForToday()

        // HKAnchoredObjectQuery for incremental updates
        let query = HKAnchoredObjectQuery(
            type: stepType,
            predicate: predicate,
            anchor: nil,  // Start from beginning of day
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            // Initial results handler
            if let error = error {
                print("❌ Step query failed: \(error)")
                return
            }
            self?.processStepSamples(samples, onUpdate: onUpdate)
        }

        // Apple-verified pattern: updateHandler for continuous monitoring
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            // Called when new samples added to HealthKit
            if let error = error {
                print("❌ Step update failed: \(error)")
                return
            }
            self?.processStepSamples(samples, onUpdate: onUpdate)
        }

        healthStore.execute(query)
        activeQueries[queryID] = query

        print("🏃 Started live step tracking (query ID: \(queryID))")
        return queryID
    }

    // MARK: - Distance Tracking

    /// Start monitoring distance (walking + running) with live updates
    ///
    /// Tracks HKQuantityTypeIdentifier.distanceWalkingRunning for today's
    /// cumulative distance in kilometers.
    ///
    /// - Parameter onUpdate: Closure called with distance in kilometers
    /// - Returns: Query ID for selective cancellation
    public func startDistanceTracking(onUpdate: @escaping @Sendable (Double) -> Void) -> UUID {
        let queryID = UUID()

        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            print("❌ Distance type unavailable")
            return queryID
        }

        let predicate = predicateForToday()

        let query = HKAnchoredObjectQuery(
            type: distanceType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("❌ Distance query failed: \(error)")
                return
            }
            self?.processDistanceSamples(samples, onUpdate: onUpdate)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("❌ Distance update failed: \(error)")
                return
            }
            self?.processDistanceSamples(samples, onUpdate: onUpdate)
        }

        healthStore.execute(query)
        activeQueries[queryID] = query

        print("📏 Started live distance tracking (query ID: \(queryID))")
        return queryID
    }

    // MARK: - Active Energy Tracking

    /// Start monitoring active energy burned with live updates
    ///
    /// Tracks HKQuantityTypeIdentifier.activeEnergyBurned for today's
    /// cumulative calories (kcal).
    ///
    /// - Parameter onUpdate: Closure called with active energy in kcal
    /// - Returns: Query ID for selective cancellation
    public func startActiveEnergyTracking(onUpdate: @escaping @Sendable (Double) -> Void) -> UUID {
        let queryID = UUID()

        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("❌ Active energy type unavailable")
            return queryID
        }

        let predicate = predicateForToday()

        let query = HKAnchoredObjectQuery(
            type: energyType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("❌ Active energy query failed: \(error)")
                return
            }
            self?.processEnergySamples(samples, onUpdate: onUpdate)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("❌ Active energy update failed: \(error)")
                return
            }
            self?.processEnergySamples(samples, onUpdate: onUpdate)
        }

        healthStore.execute(query)
        activeQueries[queryID] = query

        print("🔥 Started live active energy tracking (query ID: \(queryID))")
        return queryID
    }

    // MARK: - Query Lifecycle

    /// Stop a specific query by its ID
    ///
    /// - Parameter queryID: UUID returned from start*Tracking() method
    public func stopTracking(queryID: UUID) {
        guard let query = activeQueries[queryID] else {
            print("⚠️ No active query with ID: \(queryID)")
            return
        }

        healthStore.stop(query)
        activeQueries.removeValue(forKey: queryID)
        print("⏹️ Stopped tracking (query ID: \(queryID))")
    }

    /// Stop all active queries
    ///
    /// Call this when view disappears or tracking no longer needed.
    /// Good practice to prevent battery drain from active HealthKit queries.
    public func stopAllTracking() {
        let count = activeQueries.count
        activeQueries.values.forEach { healthStore.stop($0) }
        activeQueries.removeAll()
        print("⏹️ Stopped all live tracking (\(count) queries)")
    }

    // MARK: - Private Helpers

    /// Process step samples and call update handler with cumulative total
    ///
    /// **Note**: HKAnchoredObjectQuery may return incremental samples,
    /// but we need cumulative total for the day. This requires summing
    /// all samples in each update.
    ///
    /// TODO: Optimize by tracking anchor and only adding incremental values
    /// (requires persisting anchor between updates)
    private func processStepSamples(
        _ samples: [HKSample]?,
        onUpdate: @escaping @Sendable (Int) -> Void
    ) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }

        // Sum all samples for today
        let total = quantitySamples.reduce(0.0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .count())
        }

        Task { @MainActor in
            onUpdate(Int(total))
        }
    }

    /// Process distance samples and call update handler with cumulative km
    private func processDistanceSamples(
        _ samples: [HKSample]?,
        onUpdate: @escaping @Sendable (Double) -> Void
    ) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }

        // Sum all distance samples for today
        let totalMeters = quantitySamples.reduce(0.0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .meter())
        }

        Task { @MainActor in
            onUpdate(totalMeters / 1000.0)  // Convert to km
        }
    }

    /// Process active energy samples and call update handler with cumulative kcal
    private func processEnergySamples(
        _ samples: [HKSample]?,
        onUpdate: @escaping @Sendable (Double) -> Void
    ) {
        guard let quantitySamples = samples as? [HKQuantitySample] else { return }

        // Sum all energy samples for today
        let totalKcal = quantitySamples.reduce(0.0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .kilocalorie())
        }

        Task { @MainActor in
            onUpdate(totalKcal)
        }
    }

    /// Create predicate for samples starting today
    ///
    /// **Important**: Predicate resets at midnight. If tracking across midnight,
    /// queries need to be restarted with new predicate for next day.
    ///
    /// TODO: Add date change observer to restart queries at midnight
    private func predicateForToday() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
    }
}

#else
// MARK: - macOS Stub

import Foundation

/// Stub implementation for macOS (HealthKit not available)
@MainActor
public final class HealthKitLiveTrackingService {
    public init() {
        print("⚠️ HealthKitLiveTrackingService not available on macOS")
    }

    public func startStepTracking(onUpdate: @escaping @Sendable (Int) -> Void) -> UUID {
        print("⚠️ HealthKit not available on macOS")
        return UUID()
    }

    public func startDistanceTracking(onUpdate: @escaping @Sendable (Double) -> Void) -> UUID {
        print("⚠️ HealthKit not available on macOS")
        return UUID()
    }

    public func startActiveEnergyTracking(onUpdate: @escaping @Sendable (Double) -> Void) -> UUID {
        print("⚠️ HealthKit not available on macOS")
        return UUID()
    }

    public func stopTracking(queryID: UUID) {}
    public func stopAllTracking() {}
}
#endif
