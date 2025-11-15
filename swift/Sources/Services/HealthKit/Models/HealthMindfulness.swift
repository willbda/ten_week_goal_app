//
// HealthMindfulness.swift
// Written by Claude Code on 2025-11-04
//
// PURPOSE:
// Display model for Apple Health mindfulness data. Maps HKCategorySample (mindfulSession)
// to app-friendly structure for UI consumption. This is NOT a database-persisted model.
//
// USAGE:
// ```swift
// let session = HealthMindfulness(from: hkSample)
// Text(session.formattedDuration)  // "15 minutes"
// Text(session.timeOfDay)  // "Morning"
// ```

#if os(iOS)
import Foundation
import HealthKit

/// Display model for Apple Health mindfulness sessions
///
/// Maps HKCategorySample (mindfulSession) to simple, formatted values for UI display.
/// Not persisted to database - ephemeral view data only.
///
/// Mindfulness sessions represent periods of meditation, breathing exercises,
/// or other mindful activities tracked by the user.
public struct HealthMindfulness: Identifiable, Sendable {
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    public let duration: TimeInterval  // seconds

    // MARK: - Computed Properties

    /// User-friendly session name
    public var sessionName: String {
        "Mindful Session"
    }

    /// SF Symbols icon name
    public var iconName: String {
        "brain.fill"
    }

    /// Time of day classification for the session
    public var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: startDate)
        switch hour {
        case 0..<6:
            return "Night"
        case 6..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        case 17..<21:
            return "Evening"
        default:
            return "Night"
        }
    }

    /// Icon for time of day
    public var timeOfDayIcon: String {
        let hour = Calendar.current.component(.hour, from: startDate)
        switch hour {
        case 0..<6:
            return "moon.stars.fill"
        case 6..<12:
            return "sunrise.fill"
        case 12..<17:
            return "sun.max.fill"
        case 17..<21:
            return "sunset.fill"
        default:
            return "moon.fill"
        }
    }

    /// Duration category for visual grouping
    public var durationCategory: String {
        switch duration {
        case 0..<300:  // < 5 minutes
            return "Quick"
        case 300..<900:  // 5-15 minutes
            return "Short"
        case 900..<1800:  // 15-30 minutes
            return "Medium"
        default:  // 30+ minutes
            return "Long"
        }
    }

    /// Formatted duration: "15 minutes" or "1 hour 15 minutes"
    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return String(format: "%d hour%@ %d minute%@",
                            hours, hours == 1 ? "" : "s",
                            minutes, minutes == 1 ? "" : "s")
            } else {
                return String(format: "%d hour%@", hours, hours == 1 ? "" : "s")
            }
        } else {
            return String(format: "%d minute%@", minutes, minutes == 1 ? "" : "s")
        }
    }

    /// Short duration format: "15m" or "1h 15m"
    public var shortDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    /// Compact format: "15:00"
    public var compactDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Summary line for display: "15 minutes • Morning"
    public var summaryLine: String {
        "\(shortDuration) • \(timeOfDay)"
    }

    // MARK: - Initialization

    /// Create from HKCategorySample
    public init?(from sample: HKCategorySample) {
        // Only accept mindfulSession category type
        guard sample.categoryType.identifier == HKCategoryTypeIdentifier.mindfulSession.rawValue else {
            return nil
        }

        self.id = sample.uuid
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.duration = sample.endDate.timeIntervalSince(sample.startDate)
    }

    /// Manual initializer for testing/previews
    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        duration: TimeInterval
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
    }
}

// MARK: - Mindfulness Summary Helpers

extension Array where Element == HealthMindfulness {
    /// Total mindfulness time
    public var totalMindfulTime: TimeInterval {
        reduce(0) { $0 + $1.duration }
    }

    /// Average session duration
    public var averageSessionDuration: TimeInterval {
        guard !isEmpty else { return 0 }
        return totalMindfulTime / TimeInterval(count)
    }

    /// Formatted total time: "2h 30m"
    public var formattedTotalTime: String {
        let hours = Int(totalMindfulTime) / 3600
        let minutes = (Int(totalMindfulTime) % 3600) / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    /// Formatted average duration: "15m"
    public var formattedAverageDuration: String {
        let minutes = Int(averageSessionDuration) / 60
        return String(format: "%dm", minutes)
    }

    /// Sessions grouped by time of day
    public var sessionsByTimeOfDay: [String: [HealthMindfulness]] {
        Dictionary(grouping: self) { $0.timeOfDay }
    }

    /// Count by duration category
    public var countByDurationCategory: [String: Int] {
        reduce(into: [:]) { counts, session in
            counts[session.durationCategory, default: 0] += 1
        }
    }
}

#else
// MARK: - macOS Stub

import Foundation

/// Stub for macOS (HealthKit not available)
public struct HealthMindfulness: Identifiable, Sendable {
    public let id: UUID = UUID()
    public var sessionName: String { "HealthKit not available on macOS" }
    public var iconName: String { "brain.slash" }
    public var timeOfDay: String { "Unknown" }
    public var timeOfDayIcon: String { "questionmark" }
    public var durationCategory: String { "Unknown" }
    public var formattedDuration: String { "--:--" }
    public var shortDuration: String { "--:--" }
    public var compactDuration: String { "--:--" }
    public var summaryLine: String { "Not available" }
}

#endif
