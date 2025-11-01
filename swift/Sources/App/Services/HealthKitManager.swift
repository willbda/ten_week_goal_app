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
final class HealthKitManager {

    // MARK: - Singleton

    /// Shared instance for app-wide access
    static let shared = HealthKitManager()

    // MARK: - Properties

    /// HealthKit store instance
    private let healthStore = HKHealthStore()

    /// Current authorization status
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    /// Error from most recent operation
    private(set) var error: Error?

    /// Whether HealthKit is available on this device
    private(set) var isAvailable: Bool

    // MARK: - Types

    /// Authorization states for HealthKit access
    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    /// HealthKit-specific errors
    enum HealthKitError: LocalizedError {
        case notAvailable
        case notAuthorized
        case invalidDate

        var errorDescription: String? {
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

    /// Request authorization to read workout data from HealthKit
    ///
    /// Presents system authorization dialog to user. Updates `authorizationStatus`
    /// property on completion.
    ///
    /// - Throws: `HealthKitError.notAvailable` if HealthKit unavailable on device
    func requestAuthorization() async throws {
        guard isAvailable else {
            print("❌ HealthKit not available on this device")
            throw HealthKitError.notAvailable
        }

        let workoutType = HKObjectType.workoutType()

        do {
            print("🏥 Requesting HealthKit authorization...")
            try await healthStore.requestAuthorization(
                toShare: [],  // Not writing data in this stage
                read: [workoutType]
            )

            // Check actual authorization status after request
            let status = healthStore.authorizationStatus(for: workoutType)
            switch status {
            case .sharingAuthorized:
                authorizationStatus = .authorized
                print("✅ HealthKit authorization granted")
            case .sharingDenied:
                authorizationStatus = .denied
                print("⚠️ HealthKit authorization denied")
            case .notDetermined:
                authorizationStatus = .notDetermined
                print("⚠️ HealthKit authorization status still undetermined")
            @unknown default:
                authorizationStatus = .notDetermined
                print("⚠️ HealthKit authorization status unknown")
            }
        } catch {
            self.error = error
            print("❌ HealthKit authorization failed: \(error)")
            throw error
        }
    }

    /// Check if authorization has been granted without requesting
    ///
    /// - Returns: True if user has authorized workout reading
    func checkAuthorizationStatus() -> Bool {
        guard isAvailable else { return false }

        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)

        let isAuthorized = status == .sharingAuthorized
        authorizationStatus = isAuthorized ? .authorized : .denied

        return isAuthorized
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
    func fetchWorkouts(for date: Date) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        guard authorizationStatus == .authorized else {
            throw HealthKitError.notAuthorized
        }

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
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout] {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        guard authorizationStatus == .authorized else {
            throw HealthKitError.notAuthorized
        }

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
                continuation.resume(returning: workouts)
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
final class HealthKitManager {
    static let shared = HealthKitManager()

    private init() {
        print("⚠️ HealthKit not available on macOS")
    }

    var authorizationStatus: AuthorizationStatus = .unavailable
    var isAvailable: Bool = false
    var error: Error?

    enum AuthorizationStatus {
        case unavailable
    }

    enum HealthKitError: Error {
        case notAvailable
    }

    func requestAuthorization() async throws {
        throw HealthKitError.notAvailable
    }

    func checkAuthorizationStatus() -> Bool {
        return false
    }
}
#endif
