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
        // Cardio
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
        case .rowing:
            return "Rowing"
        case .elliptical:
            return "Elliptical"
        case .stairClimbing:
            return "Stair Climbing"
        case .stepTraining:
            return "Step Training"

        // Strength
        case .functionalStrengthTraining:
            return "Strength Training"
        case .traditionalStrengthTraining:
            return "Weight Lifting"
        case .coreTraining:
            return "Core Training"
        case .flexibility:
            return "Flexibility"
        case .cooldown:
            return "Cooldown"
        case .highIntensityIntervalTraining:
            return "HIIT"
        case .jumpRope:
            return "Jump Rope"

        // Mind & Body
        case .yoga:
            return "Yoga"
        case .barre:
            return "Barre"
        case .pilates:
            return "Pilates"
        case .taiChi:
            return "Tai Chi"
        case .mindAndBody:
            return "Mind & Body"
        case .mixedCardio:
            return "Mixed Cardio"

        // Dance
        case .dance:
            return "Dance"
        case .danceInspiredTraining:
            return "Dance Training"

        // Team Sports
        case .americanFootball:
            return "American Football"
        case .australianFootball:
            return "Australian Football"
        case .baseball:
            return "Baseball"
        case .basketball:
            return "Basketball"
        case .cricket:
            return "Cricket"
        case .handball:
            return "Handball"
        case .hockey:
            return "Hockey"
        case .lacrosse:
            return "Lacrosse"
        case .rugby:
            return "Rugby"
        case .soccer:
            return "Soccer"
        case .softball:
            return "Softball"
        case .volleyball:
            return "Volleyball"

        // Racquet Sports
        case .badminton:
            return "Badminton"
        case .tennis:
            return "Tennis"
        case .tableTennis:
            return "Table Tennis"
        case .racquetball:
            return "Racquetball"
        case .squash:
            return "Squash"
        case .pickleball:
            return "Pickleball"

        // Water Sports
        case .surfingSports:
            return "Surfing"
        case .paddleSports:
            return "Paddle Sports"
        case .waterFitness:
            return "Water Fitness"
        case .waterPolo:
            return "Water Polo"
        case .waterSports:
            return "Water Sports"

        // Winter Sports
        case .snowSports:
            return "Snow Sports"
        case .skiing:
            return "Skiing"
        case .snowboarding:
            return "Snowboarding"
        case .skating:
            return "Skating"
        case .crossCountrySkiing:
            return "Cross Country Skiing"
        case .downhillSkiing:
            return "Downhill Skiing"
        case .skatingSports:
            return "Skating Sports"
        case .curling:
            return "Curling"

        // Combat Sports
        case .boxing:
            return "Boxing"
        case .kickboxing:
            return "Kickboxing"
        case .martialArts:
            return "Martial Arts"
        case .wrestling:
            return "Wrestling"
        case .fencing:
            return "Fencing"

        // Outdoor
        case .climbing:
            return "Climbing"
        case .equestrianSports:
            return "Equestrian"
        case .fishing:
            return "Fishing"
        case .hunting:
            return "Hunting"
        case .golf:
            return "Golf"

        // Other Activities
        case .archery:
            return "Archery"
        case .bowling:
            return "Bowling"
        case .cardioDance:
            return "Cardio Dance"
        case .discSports:
            return "Disc Sports"
        case .fitnessGaming:
            return "Fitness Gaming"
        case .gymnastics:
            return "Gymnastics"
        case .handCycling:
            return "Hand Cycling"
        case .play:
            return "Play"
        case .preparationAndRecovery:
            return "Preparation & Recovery"
        case .sailingAndBoating:
            return "Sailing"
        case .socialDance:
            return "Social Dance"
        case .stairs:
            return "Stairs"
        case .swimBikeRun:
            return "Triathlon"
        case .trackAndField:
            return "Track & Field"
        case .wheelchair:
            return "Wheelchair"
        case .wheelchairRunPace:
            return "Wheelchair Run"
        case .wheelchairWalkPace:
            return "Wheelchair Walk"

        // Transition & Misc
        case .transition:
            return "Transition"
        case .other:
            return "Other Activity"

        @unknown default:
            // Fallback for any future activity types
            return activityType.displayName
        }
    }

    /// SF Symbols icon name for activity type
    public var iconName: String {
        switch activityType {
        // Cardio
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
        case .rowing:
            return "figure.rowing"
        case .elliptical:
            return "figure.elliptical"
        case .stairClimbing, .stairs, .stepTraining:
            return "figure.stairs"

        // Strength & Training
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .coreTraining:
            return "figure.core.training"
        case .flexibility, .cooldown:
            return "figure.flexibility"
        case .highIntensityIntervalTraining:
            return "figure.highintensity.intervaltraining"
        case .jumpRope:
            return "figure.jumprope"

        // Mind & Body
        case .yoga:
            return "figure.yoga"
        case .pilates, .barre:
            return "figure.pilates"
        case .taiChi, .mindAndBody:
            return "figure.mind.and.body"
        case .mixedCardio:
            return "figure.mixed.cardio"

        // Dance
        case .dance, .danceInspiredTraining, .cardioDance, .socialDance:
            return "figure.dance"

        // Team Sports
        case .americanFootball:
            return "figure.american.football"
        case .australianFootball, .rugby:
            return "figure.rugby"
        case .baseball, .softball:
            return "figure.baseball"
        case .basketball:
            return "figure.basketball"
        case .soccer:
            return "figure.soccer"
        case .volleyball:
            return "figure.volleyball"
        case .hockey:
            return "figure.hockey"
        case .cricket:
            return "figure.cricket"
        case .handball, .lacrosse:
            return "figure.handball"

        // Racquet Sports
        case .badminton, .tennis, .tableTennis, .racquetball, .squash, .pickleball:
            return "figure.tennis"

        // Water Sports
        case .surfingSports:
            return "figure.surfing"
        case .paddleSports:
            return "figure.paddleboarding"
        case .waterFitness, .waterPolo, .waterSports:
            return "figure.water.fitness"

        // Winter Sports
        case .skiing, .downhillSkiing, .crossCountrySkiing:
            return "figure.skiing.downhill"
        case .snowboarding:
            return "figure.snowboarding"
        case .skating, .skatingSports:
            return "figure.skating"
        case .snowSports:
            return "snowflake"
        case .curling:
            return "figure.curling"

        // Combat Sports
        case .boxing:
            return "figure.boxing"
        case .kickboxing:
            return "figure.kickboxing"
        case .martialArts:
            return "figure.martial.arts"
        case .wrestling:
            return "figure.wrestling"
        case .fencing:
            return "figure.fencing"

        // Outdoor
        case .climbing:
            return "figure.climbing"
        case .equestrianSports:
            return "figure.equestrian.sports"
        case .fishing:
            return "figure.fishing"
        case .hunting:
            return "figure.hunting"
        case .golf:
            return "figure.golf"

        // Other Activities
        case .archery:
            return "figure.archery"
        case .bowling:
            return "figure.bowling"
        case .discSports:
            return "figure.disc.sports"
        case .fitnessGaming, .play:
            return "gamecontroller.fill"
        case .gymnastics:
            return "figure.gymnastics"
        case .handCycling:
            return "figure.hand.cycling"
        case .preparationAndRecovery:
            return "figure.cooldown"
        case .sailingAndBoating:
            return "sailboat.fill"
        case .swimBikeRun:
            return "figure.open.water.swim"
        case .trackAndField:
            return "figure.track.and.field"
        case .wheelchair, .wheelchairRunPace, .wheelchairWalkPace:
            return "figure.roll"

        // Misc
        case .transition:
            return "arrow.triangle.2.circlepath"
        case .other:
            return "figure.mixed.cardio"

        @unknown default:
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
