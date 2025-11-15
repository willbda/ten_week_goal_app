//
// HealthKitImportService.swift
// Written by Claude Code on 2025-11-05
//
// PURPOSE:
// Converts HealthKit workouts to app Actions with measurements
//

#if os(iOS)
    import Foundation
    import Models
    import SQLiteData
    import Dependencies

    /// Service for importing HealthKit workouts as Actions
    ///
    /// Converts HealthWorkout → Action + MeasuredAction records
    /// - Duration → hours or minutes measurement
    /// - Distance → km measurement
    /// - Calories → kcal measurement
    ///
    /// ARCHITECTURE NOTE: Marked @MainActor because:
    /// - Uses @Dependency injection which requires main actor isolation
    /// - Performs database writes via ActionCoordinator (which may have @MainActor)
    /// - Typically called from UI context (import button actions)
    /// - Database operations are async but dependency resolution needs main actor
    @MainActor
    public final class HealthKitImportService {
        @Dependency(\.defaultDatabase) var database

        public init() {}

        /// Import a single workout as an Action
        /// - Parameter workout: HealthKit workout to import
        /// - Returns: Created Action with measurements
        /// - Throws: Database errors
        public func importWorkout(_ workout: HealthWorkout) async throws -> Action {
            return try await database.write { db in
                // 1. Create the Action
                let action = try Action.upsert {
                    Action.Draft(
                        title: workout.activityName,
                        detailedDescription: "Imported from Apple Health",
                        freeformNotes: nil,
                        durationMinutes: workout.duration / 60,  // Convert seconds to minutes as Double
                        startTime: workout.startDate,
                        logTime: workout.endDate,
                        id: UUID()
                    )
                }
                .returning { $0 }
                .fetchOne(db)!

                // 2. Find or create Measures
                let durationMeasure = try findOrCreateMeasure(
                    unit: workout.duration >= 3600 ? "hours" : "minutes",
                    measureType: "time",
                    in: db
                )

                // 3. Add duration measurement
                let durationValue =
                    workout.duration >= 3600
                    ? workout.duration / 3600  // Convert to hours
                    : workout.duration / 60  // Convert to minutes

                try MeasuredAction.upsert {
                    MeasuredAction.Draft(
                        id: UUID(),
                        actionId: action.id,
                        measureId: durationMeasure.id,
                        value: durationValue,
                        createdAt: Date()
                    )
                }
                .execute(db)

                // 4. Add distance measurement (if available)
                if let distanceMeters = workout.totalDistance {
                    let distanceMeasure = try findOrCreateMeasure(
                        unit: "km",
                        measureType: "distance",
                        in: db
                    )

                    try MeasuredAction.upsert {
                        MeasuredAction.Draft(
                            id: UUID(),
                            actionId: action.id,
                            measureId: distanceMeasure.id,
                            value: distanceMeters / 1000,  // Convert to km
                            createdAt: Date()
                        )
                    }
                    .execute(db)
                }

                // 5. Add calories measurement (if available)
                if let calories = workout.totalEnergyBurned {
                    let caloriesMeasure = try findOrCreateMeasure(
                        unit: "kcal",
                        measureType: "energy",
                        in: db
                    )

                    try MeasuredAction.upsert {
                        MeasuredAction.Draft(
                            id: UUID(),
                            actionId: action.id,
                            measureId: caloriesMeasure.id,
                            value: calories,
                            createdAt: Date()
                        )
                    }
                    .execute(db)
                }

                return action
            }
        }

        /// Import multiple workouts
        /// - Parameter workouts: Array of workouts to import
        /// - Returns: Array of created Actions
        /// - Throws: Database errors (rolls back all on failure)
        public func importWorkouts(_ workouts: [HealthWorkout]) async throws -> [Action] {
            var importedActions: [Action] = []

            for workout in workouts {
                let action = try await importWorkout(workout)
                importedActions.append(action)
            }

            return importedActions
        }

        // MARK: - Private Helpers

        /// Find existing measure or create new one
        /// - Note: Marked nonisolated because it's called from database.write closures
        nonisolated private func findOrCreateMeasure(
            unit unitValue: String,
            measureType typeValue: String,
            in db: Database
        ) throws -> Measure {
            // Fetch all measures and filter in Swift
            // SQLiteData's query builder doesn't support capturing external values in closures
            let allMeasures = try Measure.all.fetchAll(db)

            if let existing = allMeasures.first(where: {
                $0.unit == unitValue && $0.measureType == typeValue
            }) {
                return existing
            }

            // Create new measure
            return try Measure.upsert {
                Measure.Draft(
                    id: UUID(),
                    logTime: Date(),
                    title: unitValue.capitalized,
                    detailedDescription: "Measurement unit for \(typeValue)",
                    freeformNotes: nil,
                    unit: unitValue,
                    measureType: typeValue,  // Fixed: measureType not measureType
                    canonicalUnit: unitValue,  // For now, same as unit
                    conversionFactor: nil
                )
            }
            .returning { $0 }
            .fetchOne(db)!
        }
    }

#else
    // MARK: - macOS Stub

    import Foundation
    import Models

    @MainActor
    public final class HealthKitImportService {
        public init() {}

        public func importWorkout(_ workout: HealthWorkout) async throws -> Action {
            throw NSError(
                domain: "HealthKitImportService", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "HealthKit not available on macOS"
                ])
        }

        public func importWorkouts(_ workouts: [HealthWorkout]) async throws -> [Action] {
            throw NSError(
                domain: "HealthKitImportService", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "HealthKit not available on macOS"
                ])
        }
    }
#endif
