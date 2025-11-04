//
// HealthWorkout.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Display model for Apple Health workout data. Maps HKWorkout to app-friendly structure
// for UI consumption. This is NOT a database-persisted model - just a view layer helper.
//
// USAGE:
// ```swift
// let workout = HealthWorkout(from: hkWorkout)
// Text(workout.activityName)  // "Running"
// Text(workout.formattedDuration)  // "30:42"
// ```

#if os(iOS)
import Foundation
import HealthKit

/// Display model for Apple Health workouts
///
/// Maps HKWorkout properties to simple, formatted values for UI display.
/// Not persisted to database - ephemeral view data only.
public struct HealthWorkout: Identifiable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let activityType: HKWorkoutActivityType
    public let duration: TimeInterval  // seconds
    public let totalDistance: Double?  // meters (optional)
    public let totalEnergyBurned: Double?  // kcal (optional)

    // MARK: - Computed Properties

    /// User-friendly activity name ("Running", "Cycling", etc.)
    public var activityName: String {
        switch activityType {
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .walking:
            return "Walking"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        case .yoga:
            return "Yoga"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .traditionalStrengthTraining:
            return "Weight Lifting"
        case .elliptical:
            return "Elliptical"
        case .rowing:
            return "Rowing"
        case .stairClimbing:
            return "Stair Climbing"
        case .dance:
            return "Dance"
        default:
            // Fallback for any activity type not explicitly handled
            return activityType.displayName
        }
    }

    /// SF Symbols icon name for activity type
    public var iconName: String {
        switch activityType {
        case .running:
            return "figure.run"
        case .cycling:
            return "figure.outdoor.cycle"
        case .walking:
            return "figure.walk"
        case .swimming:
            return "figure.pool.swim"
        case .hiking:
            return "figure.hiking"
        case .yoga:
            return "figure.yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .elliptical:
            return "figure.elliptical"
        case .rowing:
            return "figure.rowing"
        case .stairClimbing:
            return "figure.stairs"
        case .dance:
            return "figure.dance"
        default:
            return "heart.fill"
        }
    }

    /// Formatted duration string: "30:42" or "1:15:22"
    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formatted distance string: "5.2 km" or "3.1 mi"
    public var formattedDistance: String? {
        guard let distance = totalDistance else { return nil }

        let kilometers = distance / 1000.0
        if kilometers >= 1.0 {
            return String(format: "%.1f km", kilometers)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

    /// Formatted calories: "387 kcal"
    public var formattedCalories: String? {
        guard let calories = totalEnergyBurned else { return nil }
        return String(format: "%.0f kcal", calories)
    }

    /// Summary line for display: "30:42 • 5.2 km • 387 kcal"
    public var summaryLine: String {
        var components: [String] = [formattedDuration]

        if let distance = formattedDistance {
            components.append(distance)
        }

        if let calories = formattedCalories {
            components.append(calories)
        }

        return components.joined(separator: " • ")
    }

    // MARK: - Initialization

    /// Create from HKWorkout
    public init(from workout: HKWorkout) {
        self.id = workout.uuid
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.activityType = workout.workoutActivityType
        self.duration = workout.duration

        // Extract distance if available
        if let distanceQuantity = workout.totalDistance {
            self.totalDistance = distanceQuantity.doubleValue(for: .meter())
        } else {
            self.totalDistance = nil
        }

        // Extract calories if available
        if let energyQuantity = workout.totalEnergyBurned {
            self.totalEnergyBurned = energyQuantity.doubleValue(for: .kilocalorie())
        } else {
            self.totalEnergyBurned = nil
        }
    }

    /// Manual initializer for testing/previews
    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        activityType: HKWorkoutActivityType,
        duration: TimeInterval,
        totalDistance: Double? = nil,
        totalEnergyBurned: Double? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.activityType = activityType
        self.duration = duration
        self.totalDistance = totalDistance
        self.totalEnergyBurned = totalEnergyBurned
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    /// Fallback display name for activity types not explicitly handled
    var displayName: String {
        // Convert enum to readable string
        // Example: HKWorkoutActivityType.running → "Running"
        let rawString = String(describing: self)
        return rawString.capitalized
    }
}

#else
// MARK: - macOS Stub

import Foundation

/// Stub for macOS (HealthKit not available)
public struct HealthWorkout: Identifiable, Sendable {
    public let id: UUID = UUID()
    public var activityName: String { "HealthKit not available on macOS" }
    public var iconName: String { "heart.slash" }
    public var formattedDuration: String { "--:--" }
    public var formattedDistance: String? { nil }
    public var formattedCalories: String? { nil }
    public var summaryLine: String { "Not available" }
}

#endif
