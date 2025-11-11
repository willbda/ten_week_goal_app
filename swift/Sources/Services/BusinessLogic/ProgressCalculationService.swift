//
// ProgressCalculationService.swift
// Written by Claude Code on 2025-11-10
//
// PURPOSE:
// Business logic service for goal progress calculations and status determination.
// Separates domain logic from data access (repository) and UI (view models).
//
// ARCHITECTURE PATTERN:
// **PERMANENT PATTERN**: Service layer for business logic
// - Repositories provide raw data (GoalProgressData)
// - Services apply business rules and calculations
// - ViewModels orchestrate services for UI
//
// This separation ensures:
// - Business logic is testable independently
// - Rules can change without touching database or UI
// - Complex calculations are centralized
//
// RESPONSIBILITIES:
// 1. Calculate progress status (on-track, behind, overdue)
// 2. Project completion dates based on current pace
// 3. Determine urgency and priority
// 4. Apply business rules for goal tracking
//

import Foundation
import Models

// MARK: - Domain Types

/// Progress status based on business rules
///
/// **PERMANENT PATTERN**: Domain enum for business logic
public enum ProgressStatus: String, Sendable {
    case complete = "complete"       // Goal achieved
    case onTrack = "on_track"        // Making expected progress
    case behind = "behind"           // Below expected progress
    case overdue = "overdue"         // Past deadline
    case notStarted = "not_started"  // No progress yet
}

/// Enriched goal progress with business calculations
///
/// **PERMANENT PATTERN**: Domain model with calculated properties
/// This is what the UI consumes - fully processed business data.
public struct GoalProgress: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let measureName: String
    public let measureUnit: String
    public let currentProgress: Double
    public let targetValue: Double
    public let percentComplete: Double
    public let status: ProgressStatus
    public let daysRemaining: Int?
    public let projectedCompletion: Date?
    public let dailyTargetRate: Double?  // How much per day to stay on track
    public let currentDailyRate: Double? // Current pace based on history

    // Public initializer for cross-module access
    public init(
        id: UUID,
        title: String,
        measureName: String,
        measureUnit: String,
        currentProgress: Double,
        targetValue: Double,
        percentComplete: Double,
        status: ProgressStatus,
        daysRemaining: Int?,
        projectedCompletion: Date?,
        dailyTargetRate: Double?,
        currentDailyRate: Double?
    ) {
        self.id = id
        self.title = title
        self.measureName = measureName
        self.measureUnit = measureUnit
        self.currentProgress = currentProgress
        self.targetValue = targetValue
        self.percentComplete = percentComplete
        self.status = status
        self.daysRemaining = daysRemaining
        self.projectedCompletion = projectedCompletion
        self.dailyTargetRate = dailyTargetRate
        self.currentDailyRate = currentDailyRate
    }

    // UI convenience properties
    public var isUrgent: Bool {
        if let days = daysRemaining {
            return days <= 7 && status != .complete
        }
        return false
    }

    public var statusColor: String {
        switch status {
        case .complete: return "green"
        case .onTrack: return "blue"
        case .behind: return "orange"
        case .overdue: return "red"
        case .notStarted: return "gray"
        }
    }
}

// MARK: - Service Implementation

/// Business logic service for progress calculations
///
/// **PERMANENT PATTERN**: Stateless service class
/// - NO @MainActor (pure business logic, no UI)
/// - Sendable for actor boundaries
/// - All methods are pure functions (no side effects)
public final class ProgressCalculationService: Sendable {

    public init() {}

    // MARK: - Main Calculation Method

    /// Transform raw progress data into enriched business objects
    ///
    /// **PERMANENT PATTERN**: Service method signature
    /// - Input: Raw data from repository
    /// - Output: Enriched domain objects for UI
    /// - Pure function (no side effects)
    public func calculateProgress(from data: [GoalProgressData]) -> [GoalProgress] {
        return data.map { calculateSingleProgress($0) }
    }

    /// Calculate progress for a single goal
    private func calculateSingleProgress(_ data: GoalProgressData) -> GoalProgress {
        // Determine status based on business rules
        let status = determineStatus(
            currentProgress: data.currentProgress,
            targetValue: data.targetValue,
            percentComplete: data.percentComplete,
            daysRemaining: data.daysRemaining
        )

        // Calculate daily rates (if dates available)
        let (dailyTarget, currentDaily) = calculateDailyRates(
            data: data,
            status: status
        )

        // Project completion date (if making progress)
        let projectedDate = projectCompletion(
            data: data,
            currentDailyRate: currentDaily
        )

        return GoalProgress(
            id: data.id,
            title: data.goalTitle,
            measureName: data.measureName,
            measureUnit: data.measureUnit,
            currentProgress: data.currentProgress,
            targetValue: data.targetValue,
            percentComplete: data.percentComplete,
            status: status,
            daysRemaining: data.daysRemaining,
            projectedCompletion: projectedDate,
            dailyTargetRate: dailyTarget,
            currentDailyRate: currentDaily
        )
    }

    // MARK: - Business Logic Methods

    /// Determine goal status based on business rules
    ///
    /// **PERMANENT PATTERN**: Pure business logic function
    /// Rules:
    /// 1. Complete: currentProgress >= targetValue
    /// 2. Overdue: daysRemaining < 0
    /// 3. Not Started: currentProgress == 0
    /// 4. Behind: percentComplete < expected based on time elapsed
    /// 5. On Track: everything else
    private func determineStatus(
        currentProgress: Double,
        targetValue: Double,
        percentComplete: Double,
        daysRemaining: Int?
    ) -> ProgressStatus {
        // Rule 1: Check if complete
        if currentProgress >= targetValue {
            return .complete
        }

        // Rule 2: Check if overdue
        if let days = daysRemaining, days < 0 {
            return .overdue
        }

        // Rule 3: Check if not started
        if currentProgress == 0 {
            return .notStarted
        }

        // Rule 4: Check if behind schedule
        // **TEMPORARY**: Simple linear progress check
        // **FUTURE**: Factor in historical velocity, sprint cycles, etc.
        if let days = daysRemaining {
            // Calculate expected progress based on time elapsed
            // This would need startDate to be precise, using approximation for now
            let remainingPercent = 100.0 - percentComplete
            let daysPerPercent = Double(days) / remainingPercent

            // If we need more than 1 day per 1% and we're below 50%, we're behind
            if daysPerPercent < 1.0 && percentComplete < 50.0 {
                return .behind
            }
        }

        return .onTrack
    }

    /// Calculate daily rate targets
    ///
    /// **TEMPORARY**: Basic linear calculation
    /// **FUTURE**: Factor in work patterns, weekends, historical velocity
    private func calculateDailyRates(
        data: GoalProgressData,
        status: ProgressStatus
    ) -> (target: Double?, current: Double?) {
        guard status != .complete else {
            return (nil, nil)
        }

        // Calculate required daily rate to meet target
        var dailyTarget: Double? = nil
        if let days = data.daysRemaining, days > 0 {
            let remaining = data.targetValue - data.currentProgress
            dailyTarget = remaining / Double(days)
        }

        // Calculate current daily rate based on progress so far
        // **TEMPORARY**: Assumes linear progress from start
        // **FUTURE**: Use actual action history for accurate velocity
        var currentDaily: Double? = nil
        if let startDate = data.startDate {
            let daysSinceStart = Date.now.timeIntervalSince(startDate) / 86400
            if daysSinceStart > 0 {
                currentDaily = data.currentProgress / daysSinceStart
            }
        }

        return (dailyTarget, currentDaily)
    }

    /// Project completion date based on current pace
    ///
    /// **TEMPORARY**: Simple linear projection
    /// **FUTURE**: ML-based projection using historical patterns
    private func projectCompletion(
        data: GoalProgressData,
        currentDailyRate: Double?
    ) -> Date? {
        guard let rate = currentDailyRate,
              rate > 0,
              data.currentProgress < data.targetValue else {
            return nil
        }

        let remaining = data.targetValue - data.currentProgress
        let daysToComplete = remaining / rate

        return Calendar.current.date(
            byAdding: .day,
            value: Int(ceil(daysToComplete)),
            to: Date.now
        )
    }

    // MARK: - Aggregate Calculations

    /// Calculate overall progress statistics
    ///
    /// **FUTURE ENHANCEMENT**: Add to dashboard
    public func calculateAggregateStats(_ goals: [GoalProgress]) -> DashboardStats {
        let total = goals.count
        let completed = goals.filter { $0.status == .complete }.count
        let onTrack = goals.filter { $0.status == .onTrack }.count
        let behind = goals.filter { $0.status == .behind }.count
        let overdue = goals.filter { $0.status == .overdue }.count

        let overallCompletion = total > 0
            ? goals.reduce(0.0) { $0 + $1.percentComplete } / Double(total)
            : 0.0

        return DashboardStats(
            totalGoals: total,
            completedGoals: completed,
            onTrackGoals: onTrack,
            behindGoals: behind,
            overdueGoals: overdue,
            overallCompletionPercent: overallCompletion
        )
    }
}

// MARK: - Supporting Types

/// Aggregate statistics for dashboard
///
/// **FUTURE ENHANCEMENT**: Will be used in full dashboard
public struct DashboardStats: Sendable {
    public let totalGoals: Int
    public let completedGoals: Int
    public let onTrackGoals: Int
    public let behindGoals: Int
    public let overdueGoals: Int
    public let overallCompletionPercent: Double

    // Public initializer for cross-module access
    public init(
        totalGoals: Int,
        completedGoals: Int,
        onTrackGoals: Int,
        behindGoals: Int,
        overdueGoals: Int,
        overallCompletionPercent: Double
    ) {
        self.totalGoals = totalGoals
        self.completedGoals = completedGoals
        self.onTrackGoals = onTrackGoals
        self.behindGoals = behindGoals
        self.overdueGoals = overdueGoals
        self.overallCompletionPercent = overallCompletionPercent
    }

    public var completionRate: Double {
        totalGoals > 0 ? Double(completedGoals) / Double(totalGoals) * 100 : 0
    }
}

// MARK: - Implementation Notes

// SERVICE LAYER PATTERN
//
// This demonstrates the **PERMANENT** three-layer architecture:
// 1. Repository Layer: Data access (GoalRepository)
// 2. Service Layer: Business logic (ProgressCalculationService)
// 3. Presentation Layer: ViewModels and Views
//
// Benefits:
// - Business logic is independent of database schema
// - Easy to unit test without database
// - Can swap calculation strategies without touching UI
// - Centralized place for business rules
//
// TEMPORARY vs PERMANENT:
//
// Permanent patterns:
// - Service layer architecture
// - Separation of concerns
// - Pure functions for calculations
// - Domain types (GoalProgress, ProgressStatus)
//
// Temporary implementations (marked for enhancement):
// - Linear progress calculations (will add velocity tracking)
// - Simple status rules (will add ML predictions)
// - Basic daily rates (will factor in work patterns)