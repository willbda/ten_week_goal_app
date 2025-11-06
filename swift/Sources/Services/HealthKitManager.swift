// HealthKitManager.swift
// Service for managing HealthKit authorization and workout queries
//
// Written by Claude Code on 2025-10-27

#if os(iOS)
import Foundation
import HealthKit
import Observation

/// Manager for HealthKit operations (iOS only)
///
/// Provides a singleton interface for requesting HealthKit authorization
/// and querying workout data. Uses @Observable for SwiftUI reactivity.
///
/// Usage:
/// ```swift
/// let manager = HealthKitManager.shared
/// try await manager.requestAuthorization()
/// let workouts = try await manager.fetchWorkouts(for: Date())
/// ```
@Observable
@MainActor
public final class HealthKitManager {

    // MARK: - Singleton

    /// Shared instance for app-wide access
    public static let shared = HealthKitManager()

    // MARK: - Properties

    /// HealthKit store instance
    private let healthStore = HKHealthStore()

    /// Current authorization status
    public private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    /// Error from most recent operation
    public private(set) var error: Error?

    /// Whether HealthKit is available on this device
    public private(set) var isAvailable: Bool

    // MARK: - Types

    /// Authorization states for HealthKit access
    public enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    /// HealthKit-specific errors
    public enum HealthKitError: LocalizedError {
        case notAvailable
        case notAuthorized
        case invalidDate

        public var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .notAuthorized:
                return "HealthKit access has not been granted. Please enable in Settings."
            case .invalidDate:
                return "Invalid date provided for workout query"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        self.isAvailable = HKHealthStore.isHealthDataAvailable()
        if !isAvailable {
            self.authorizationStatus = .unavailable
        }

        print("🏥 HealthKitManager initialized (available: \(isAvailable))")
    }

    // MARK: - Authorization

    /// Mark that a query succeeded, indicating we have authorization
    /// This is the most reliable way to determine HealthKit access for read-only permissions
    internal func markQuerySucceeded() {
        if authorizationStatus != .authorized {
            print("✅ Query succeeded - marking as authorized")
            authorizationStatus = .authorized
        }
    }

    /// Request authorization to read workout, sleep, and mindfulness data from HealthKit
    ///
    /// Presents system authorization dialog to user. Updates `authorizationStatus`
    /// property on completion.
    ///
    /// - Throws: `HealthKitError.notAvailable` if HealthKit unavailable on device
    public func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let workoutType = HKObjectType.workoutType()

        // Category types for sleep and mindfulness
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.notAvailable
        }

        // Set up the types we want to read
        let typesToRead: Set<HKObjectType> = [workoutType, sleepType, mindfulType]

        // Even though we're not writing, some iOS versions require non-nil write set
        let typesToWrite: Set<HKSampleType> = []  // Empty but not nil

        do {
            try await healthStore.requestAuthorization(
                toShare: typesToWrite,
                read: typesToRead
            )

            // After requesting, check workout authorization (most reliable indicator)
            let workoutStatus = healthStore.authorizationStatus(for: workoutType)

            if workoutStatus == .sharingAuthorized {
                // If workouts are authorized, assume sleep/mindfulness are too
                // (HealthKit shows all three in one dialog)
                authorizationStatus = .authorized
                print("✅ HealthKit authorization granted (workout status: authorized)")
            } else {
                // User either denied or closed the dialog
                // Try a query to verify - if it works, we have permission despite the status
                authorizationStatus = .notDetermined
                print("⚠️ Workout authorization status unclear (status: \(workoutStatus.rawValue))")
                print("   This is normal for category types. Try querying data to verify.")
            }
        } catch {
            self.error = error
            print("❌ HealthKit authorization failed: \(error)")
            authorizationStatus = .denied
            throw error
        }
    }

    /// Check if authorization has been granted without requesting
    ///
    /// NOTE: For privacy, HealthKit returns `.sharingDenied` for category types (sleep, mindfulness)
    /// even when permission hasn't been determined. This makes it unreliable for read-only access.
    ///
    /// For read-only HealthKit access, the recommended approach is:
    /// 1. Call requestAuthorization()
    /// 2. Attempt to query data
    /// 3. If query succeeds (even with 0 results), you have permission
    /// 4. If query fails with permission error, you're actually denied
    ///
    /// - Returns: True if we believe we have authorization (may be optimistic)
    public func checkAuthorizationStatus() -> Bool {
        print("🔍 checkAuthorizationStatus called - isAvailable: \(isAvailable)")
        guard isAvailable else { return false }

        let workoutType = HKObjectType.workoutType()

        // Only check workout status - it's more reliable
        let workoutStatus = healthStore.authorizationStatus(for: workoutType)
        print("🔍 Workout status: \(workoutStatus.rawValue)")

        // For read-only access, we treat "not determined" and "denied" the same way:
        // - If explicitly authorized, great!
        // - Otherwise, assume we need to request (or have been denied)
        if workoutStatus == .sharingAuthorized {
            authorizationStatus = .authorized
            print("🔍 Workouts authorized ✅ (assuming sleep/mindfulness also granted)")
            return true
        } else {
            // Could be denied OR not determined - can't tell the difference for category types
            authorizationStatus = workoutStatus == .sharingDenied ? .denied : .notDetermined
            print("🔍 Not authorized (status: \(authorizationStatus))")
            return false
        }
    }

    // MARK: - Queries

    /// Fetch all workouts for a specific date
    ///
    /// Queries HealthKit for workouts that started on the given date.
    /// Returns workouts sorted by start time (most recent first).
    ///
    /// - Parameter date: The date to query workouts for
    /// - Returns: Array of HKWorkout objects for that date
    /// - Throws:
    ///   - `HealthKitError.notAvailable` if HealthKit unavailable
    ///   - `HealthKitError.notAuthorized` if authorization not granted
    ///   - `HealthKitError.invalidDate` if date calculation fails
    public func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // Don't check authorization status - just try to query
        // If user denied permission, HealthKit will return empty results or error

        // Create date range for entire day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDate
        }

        print("🏥 Querying workouts from \(startOfDay) to \(endOfDay)")

        // Create predicate for date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: [.strictStartDate]
        )

        // Execute query using Swift concurrency
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { query, samples, error in
                if let error = error {
                    print("❌ Workout query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                print("✅ Found \(workouts.count) workouts")
                self.markQuerySucceeded()  // Query succeeded, we have permission
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch workouts for a date range
    ///
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of HKWorkout objects in the range
    /// - Throws: Same errors as `fetchWorkouts(for:)`
    public func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // Don't check authorization status - just try to query

        print("🏥 Querying workouts from \(startDate) to \(endDate)")

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { query, samples, error in
                if let error = error {
                    print("❌ Workout query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                print("✅ Found \(workouts.count) workouts")
                self.markQuerySucceeded()  // Query succeeded, we have permission
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Queries

    /// Fetch all sleep samples for a specific date
    ///
    /// Queries HealthKit for sleep analysis data that overlaps with the given date.
    /// Returns samples sorted by start time (most recent first).
    ///
    /// - Parameter date: The date to query sleep data for
    /// - Returns: Array of HKCategorySample objects for sleep analysis
    /// - Throws: Same errors as `fetchWorkouts(for:)`
    public func fetchSleep(for date: Date) async throws -> [HKCategorySample] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // Don't check authorization status - just try to query

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.notAvailable
        }

        // Create date range for entire day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDate
        }

        print("🏥 Querying sleep data from \(startOfDay) to \(endOfDay)")

        // Use .strictStartDate to get samples that start within the date range
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: []
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { query, samples, error in
                if let error = error {
                    print("❌ Sleep query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples as? [HKCategorySample] ?? []
                print("✅ Found \(sleepSamples.count) sleep samples")
                self.markQuerySucceeded()  // Query succeeded, we have permission
                continuation.resume(returning: sleepSamples)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch sleep samples for a date range
    ///
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of HKCategorySample objects for sleep analysis
    /// - Throws: Same errors as `fetchWorkouts(for:)`
    public func fetchSleep(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // Don't check authorization status - just try to query

        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.notAvailable
        }

        print("🏥 Querying sleep data from \(startDate) to \(endDate)")

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { query, samples, error in
                if let error = error {
                    print("❌ Sleep query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples as? [HKCategorySample] ?? []
                print("✅ Found \(sleepSamples.count) sleep samples")
                self.markQuerySucceeded()  // Query succeeded, we have permission
                continuation.resume(returning: sleepSamples)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Mindfulness Queries

    /// Fetch all mindfulness sessions for a specific date
    ///
    /// Queries HealthKit for mindful session data that started on the given date.
    /// Returns sessions sorted by start time (most recent first).
    ///
    /// - Parameter date: The date to query mindfulness data for
    /// - Returns: Array of HKCategorySample objects for mindful sessions
    /// - Throws: Same errors as `fetchWorkouts(for:)`
    public func fetchMindfulness(for date: Date) async throws -> [HKCategorySample] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // Don't check authorization status - just try to query

        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.notAvailable
        }

        // Create date range for entire day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw HealthKitError.invalidDate
        }

        print("🏥 Querying mindfulness data from \(startOfDay) to \(endOfDay)")

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: [.strictStartDate]
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { query, samples, error in
                if let error = error {
                    print("❌ Mindfulness query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                let mindfulSamples = samples as? [HKCategorySample] ?? []
                print("✅ Found \(mindfulSamples.count) mindfulness sessions")
                self.markQuerySucceeded()  // Query succeeded, we have permission
                continuation.resume(returning: mindfulSamples)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch mindfulness sessions for a date range
    ///
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of HKCategorySample objects for mindful sessions
    /// - Throws: Same errors as `fetchWorkouts(for:)`
    public func fetchMindfulness(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        // Don't check authorization status - just try to query

        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.notAvailable
        }

        print("🏥 Querying mindfulness data from \(startDate) to \(endDate)")

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { query, samples, error in
                if let error = error {
                    print("❌ Mindfulness query failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }

                let mindfulSamples = samples as? [HKCategorySample] ?? []
                print("✅ Found \(mindfulSamples.count) mindfulness sessions")
                self.markQuerySucceeded()  // Query succeeded, we have permission
                continuation.resume(returning: mindfulSamples)
            }

            healthStore.execute(query)
        }
    }
}

#else
// MARK: - macOS Stub

import Observation

/// Stub implementation for macOS (HealthKit not available)
@Observable
@MainActor
public final class HealthKitManager {
    public static let shared = HealthKitManager()

    private init() {
        print("⚠️ HealthKit not available on macOS")
    }

    public private(set) var authorizationStatus: AuthorizationStatus = .unavailable
    public private(set) var isAvailable: Bool = false
    public private(set) var error: Error?

    public enum AuthorizationStatus {
        case unavailable
    }

    public enum HealthKitError: Error {
        case notAvailable
    }

    public func requestAuthorization() async throws {
        throw HealthKitError.notAvailable
    }

    public func checkAuthorizationStatus() -> Bool {
        return false
    }
}
#endif
