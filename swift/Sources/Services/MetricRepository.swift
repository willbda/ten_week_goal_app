// // MeasureRepository.swift
// // Service for querying normalized metric data
// //
// // Written by Claude Code on 2025-10-30
// //
// // PURPOSE:
// // Provides clean API for working with the normalized metrics system.
// // Handles joins between actions/goals and their metrics.
// // Encapsulates SQL complexity behind simple method calls.

// import Foundation
// import Models

// /// Repository for metric-related queries and operations
// ///
// /// This service handles the complexity of the 3NF normalized schema,
// /// providing simple methods for common metric operations.
// ///
// /// **Usage**:
// /// ```swift
// /// let repo = MeasureRepository()
// ///
// /// // Get all metrics for an action
// /// let measurements = await repo.getMeasuresForAction(myAction)
// ///
// /// // Record a new measurement
// /// await repo.recordMeasurement(
// ///     action: myAction,
// ///     metric: distanceMeasure,
// ///     value: 5.2
// /// )
// ///
// /// // Calculate goal progress
// /// let progress = await repo.calculateProgress(for: myGoal)
// /// ```
// @MainActor
// public class MeasureRepository: ObservableObject {

//     // MARK: - Measure Catalog Operations

//     /// Fetch all available metrics
//     public func getAllMeasures() async throws -> [Measure] {
//         return try await Measure.all()
//     }

//     /// Fetch metrics by type
//     public func getMeasures(ofType type: String) async throws -> [Measure] {
//         return try await Measure.filter(\.measureType == type)
//     }

//     /// Find or create a metric
//     public func findOrCreateMeasure(unit: String, type: String) async throws -> Measure {
//         // First try to find existing metric
//         if let existing = try await Measure.filter(\.unit == unit).first {
//             return existing
//         }

//         // Create new metric
//         let metric = Measure(
//             unit: unit,
//             measureType: type,
//             title: unit.capitalized
//         )
//         try await metric.insert()
//         return metric
//     }

//     // MARK: - Action Measures Operations

//     /// Get all metrics for an action with their values
//     public func getMeasuresForAction(_ action: Action) async throws -> [(
//         metric: Measure, value: Double
//     )] {
//         // Fetch all MeasuredActions for this action
//         let actionMeasures = try await MeasuredAction.filter(\.actionId == action.id)

//         // Fetch corresponding Measures
//         var results: [(metric: Measure, value: Double)] = []
//         for am in actionMeasures {
//             if let metric = try await Measure.find(am.measureId) {
//                 results.append((metric: metric, value: am.value))
//             }
//         }

//         return results
//     }

//     /// Record a measurement for an action
//     public func recordMeasurement(action: Action, metric: Measure, value: Double) async throws {
//         // Check if measurement already exists
//         let existing = try await MeasuredAction.filter(
//             \.actionId == action.id && \.measureId == metric.id
//         ).first

//         if let existing = existing {
//             // Update existing measurement
//             var updated = existing
//             updated.value = value
//             updated.createdAt = Date()
//             try await updated.update()
//         } else {
//             // Create new measurement
//             let measurement = MeasuredAction(
//                 actionId: action.id,
//                 measureId: metric.id,
//                 value: value
//             )
//             try await measurement.insert()
//         }
//     }

//     /// Remove a measurement from an action
//     public func removeMeasurement(action: Action, metric: Measure) async throws {
//         if let measurement = try await MeasuredAction.filter(
//             \.actionId == action.id && \.measureId == metric.id
//         ).first {
//             try await measurement.delete()
//         }
//     }

//     // MARK: - Goal Measures Operations

//     /// Get all target metrics for a goal
//     public func getMeasuresForGoal(_ goal: Goal) async throws -> [(
//         metric: Measure, targetValue: Double
//     )] {
//         // Fetch all ExpectationMeasures for this goal
//         let goalMeasures = try await ExpectationMeasure.filter(\.expectationId == goal.id)

//         // Fetch corresponding Measures
//         var results: [(metric: Measure, targetValue: Double)] = []
//         for gm in goalMeasures {
//             if let metric = try await Measure.find(gm.measureId) {
//                 results.append((metric: metric, targetValue: gm.targetValue))
//             }
//         }

//         return results
//     }

//     /// Set a target metric for a goal
//     public func setGoalTarget(goal: Goal, metric: Measure, targetValue: Double) async throws {
//         // Check if target already exists
//         let existing = try await ExpectationMeasure.filter(
//             \.expectationId == goal.id && \.measureId == metric.id
//         ).first

//         if let existing = existing {
//             // Update existing target
//             var updated = existing
//             updated.targetValue = targetValue
//             try await updated.update()
//         } else {
//             // Create new target
//             let target = ExpectationMeasure(
//                 expectationId: goal.id,
//                 measureId: metric.id,
//                 targetValue: targetValue
//             )
//             try await target.insert()
//         }
//     }

//     // MARK: - Progress Calculation

//     /// Calculate progress for a goal based on contributing actions
//     public func calculateProgress(for goal: Goal) async throws -> GoalProgress {
//         // Get goal targets
//         let targets = try await getMeasuresForGoal(goal)

//         // Get contributing actions
//         let contributions = try await ActionGoalContribution.filter(\.goalId == goal.id)

//         var progressByMeasure: [UUID: (actual: Double, target: Double)] = [:]

//         // Calculate progress for each metric
//         for (metric, targetValue) in targets {
//             var actualValue: Double = 0.0

//             // Sum contributions for this metric
//             for contribution in contributions {
//                 if contribution.measureId == metric.id {
//                     actualValue += contribution.contributionAmount ?? 0
//                 }
//             }

//             progressByMeasure[metric.id] = (actual: actualValue, target: targetValue)
//         }

//         // Calculate overall percentage
//         var totalPercentage: Double = 0.0
//         if !progressByMeasure.isEmpty {
//             let percentages = progressByMeasure.values.map { actual, target in
//                 target > 0 ? (actual / target) * 100 : 0
//             }
//             totalPercentage = percentages.reduce(0, +) / Double(percentages.count)
//         }

//         return GoalProgress(
//             goalId: goal.id,
//             progressByMeasure: progressByMeasure,
//             overallPercentage: min(100, totalPercentage)
//         )
//     }

//     // MARK: - Aggregation Queries

//     /// Get total for a metric across all actions
//     public func totalForMeasure(_ metric: Measure) async throws -> Double {
//         let measurements = try await MeasuredAction.filter(\.measureId == metric.id)
//         return measurements.reduce(0) { $0 + $1.value }
//     }

//     /// Get total for a metric type across all actions
//     public func totalForMeasureType(_ type: String) async throws -> [(
//         metric: Measure, total: Double
//     )] {
//         let metrics = try await getMeasures(ofType: type)

//         var results: [(metric: Measure, total: Double)] = []
//         for metric in metrics {
//             let total = try await totalForMeasure(metric)
//             if total > 0 {
//                 results.append((metric: metric, total: total))
//             }
//         }

//         return results
//     }

//     /// Get metrics for actions in date range
//     public func metricsInDateRange(from startDate: Date, to endDate: Date) async throws
//         -> [MeasuredAction]
//     {
//         return try await MeasuredAction.filter(
//             \.createdAt >= startDate && \.createdAt <= endDate
//         )
//     }
// }

// // MARK: - Supporting Types

// /// Progress information for a goal
// public struct GoalProgress {
//     public let goalId: UUID
//     public let progressByMeasure: [UUID: (actual: Double, target: Double)]
//     public let overallPercentage: Double

//     /// Check if goal is complete
//     public var isComplete: Bool {
//         overallPercentage >= 100
//     }

//     /// Get progress for a specific metric
//     public func progress(for measureId: UUID) -> (actual: Double, target: Double)? {
//         progressByMeasure[measureId]
//     }

//     /// Get percentage for a specific metric
//     public func percentage(for measureId: UUID) -> Double {
//         guard let (actual, target) = progressByMeasure[measureId],
//             target > 0
//         else { return 0 }
//         return min(100, (actual / target) * 100)
//     }
// }
