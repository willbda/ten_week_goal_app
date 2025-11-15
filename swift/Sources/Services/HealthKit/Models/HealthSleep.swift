//
// HealthSleep.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Display model for Apple Health sleep data. Maps HKCategorySample (sleepAnalysis)
// to app-friendly structure for UI consumption. This is NOT a database-persisted model.
//
// USAGE:
// ```swift
// let sleep = HealthSleep(from: hkSample)
// Text(sleep.stageName)  // "Deep Sleep"
// Text(sleep.formattedDuration)  // "2h 15m"
// ```

#if os(iOS)
import Foundation
import HealthKit

/// Display model for Apple Health sleep analysis
///
/// Maps HKCategorySample (sleepAnalysis) to simple, formatted values for UI display.
/// Not persisted to database - ephemeral view data only.
///
/// Sleep stages tracked by Apple Watch:
/// - Deep Sleep: Most restorative sleep stage
/// - Core Sleep: Light sleep
/// - REM Sleep: Rapid Eye Movement, dreaming stage
/// - Awake: Brief awakenings during night
/// - In Bed: Time in bed (tracked by iPhone or Apple Watch)
public struct HealthSleep: Identifiable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let stage: SleepStage
    public let duration: TimeInterval  // seconds

    // MARK: - Types

    /// Sleep stage classification
    public enum SleepStage: Sendable {
        case inBed
        case asleepUnspecified
        case awake
        case core
        case deep
        case rem

        /// Create from HKCategoryValueSleepAnalysis raw value
        init(from value: Int) {
            switch value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                self = .inBed
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                self = .asleepUnspecified
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                self = .awake
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                self = .core
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                self = .deep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                self = .rem
            default:
                self = .asleepUnspecified
            }
        }
    }

    // MARK: - Computed Properties

    /// User-friendly stage name
    public var stageName: String {
        switch stage {
        case .inBed:
            return "In Bed"
        case .asleepUnspecified:
            return "Asleep"
        case .awake:
            return "Awake"
        case .core:
            return "Core Sleep"
        case .deep:
            return "Deep Sleep"
        case .rem:
            return "REM Sleep"
        }
    }

    /// SF Symbols icon name for sleep stage
    public var iconName: String {
        switch stage {
        case .inBed:
            return "bed.double.fill"
        case .asleepUnspecified:
            return "moon.zzz.fill"
        case .awake:
            return "eye.fill"
        case .core:
            return "moon.stars.fill"
        case .deep:
            return "moon.fill"
        case .rem:
            return "brain.fill"
        }
    }

    /// Color for sleep stage visualization
    public var stageColor: String {
        switch stage {
        case .inBed:
            return "gray"
        case .asleepUnspecified:
            return "blue"
        case .awake:
            return "orange"
        case .core:
            return "teal"
        case .deep:
            return "indigo"
        case .rem:
            return "purple"
        }
    }

    /// Whether this is actual sleep (not just in bed or awake)
    public var isAsleep: Bool {
        switch stage {
        case .core, .deep, .rem, .asleepUnspecified:
            return true
        case .inBed, .awake:
            return false
        }
    }

    /// Formatted duration: "2h 15m" or "45m"
    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    /// Short duration format: "2:15" or "0:45"
    public var shortDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    // MARK: - Initialization

    /// Create from HKCategorySample
    public init?(from sample: HKCategorySample) {
        // Only accept sleepAnalysis category type
        guard sample.categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue else {
            return nil
        }

        self.id = sample.uuid
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.stage = SleepStage(from: sample.value)
        self.duration = sample.endDate.timeIntervalSince(sample.startDate)
    }

    /// Manual initializer for testing/previews
    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        stage: SleepStage,
        duration: TimeInterval
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.stage = stage
        self.duration = duration
    }
}

// MARK: - Sleep Summary Helpers

extension Array where Element == HealthSleep {
    /// Total time asleep (excludes awake and in bed time)
    public var totalSleepTime: TimeInterval {
        filter { $0.isAsleep }.reduce(0) { $0 + $1.duration }
    }

    /// Total time in bed
    public var totalInBedTime: TimeInterval {
        filter { $0.stage == .inBed }.reduce(0) { $0 + $1.duration }
    }

    /// Deep sleep duration
    public var deepSleepTime: TimeInterval {
        filter { $0.stage == .deep }.reduce(0) { $0 + $1.duration }
    }

    /// REM sleep duration
    public var remSleepTime: TimeInterval {
        filter { $0.stage == .rem }.reduce(0) { $0 + $1.duration }
    }

    /// Core sleep duration
    public var coreSleepTime: TimeInterval {
        filter { $0.stage == .core }.reduce(0) { $0 + $1.duration }
    }

    /// Formatted total sleep time: "7h 45m"
    public var formattedTotalSleep: String {
        let hours = Int(totalSleepTime) / 3600
        let minutes = (Int(totalSleepTime) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}

#else
// MARK: - macOS Stub

import Foundation

/// Stub for macOS (HealthKit not available)
public struct HealthSleep: Identifiable, Sendable {
    public let id: UUID = UUID()
    public enum SleepStage: Sendable {
        case unavailable
    }
    public var stageName: String { "HealthKit not available on macOS" }
    public var iconName: String { "moon.slash" }
    public var stageColor: String { "gray" }
    public var isAsleep: Bool { false }
    public var formattedDuration: String { "--:--" }
    public var shortDuration: String { "--:--" }
}

#endif
