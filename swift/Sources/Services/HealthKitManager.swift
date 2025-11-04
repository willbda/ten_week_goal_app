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
                print("⚠️ HealthKit authorization not determined")
            @unknown default:
                authorizationStatus = .notDetermined
                print("⚠️ HealthKit authorization unknown")
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
    public func checkAuthorizationStatus() -> Bool {
        print("🔍 checkAuthorizationStatus called - isAvailable: \(isAvailable)")
        guard isAvailable else { return false }

        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        print("🔍 Authorization status: \(status)")

        // Map HKAuthorizationStatus to our AuthorizationStatus
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
            print("🔍 Status is notDetermined")
            return false
        case .sharingAuthorized:
            authorizationStatus = .authorized
            print("🔍 Status is authorized")
            return true
        case .sharingDenied:
            authorizationStatus = .denied
            print("🔍 Status is denied")
            return false
        @unknown default:
            authorizationStatus = .notDetermined
            print("🔍 Status is unknown: \(status.rawValue)")
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
    public func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout] {
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

        guard authorizationStatus == .authorized else {
            throw HealthKitError.notAuthorized
        }

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

        guard authorizationStatus == .authorized else {
            throw HealthKitError.notAuthorized
        }

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

        guard authorizationStatus == .authorized else {
            throw HealthKitError.notAuthorized
        }

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

        guard authorizationStatus == .authorized else {
            throw HealthKitError.notAuthorized
        }

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
