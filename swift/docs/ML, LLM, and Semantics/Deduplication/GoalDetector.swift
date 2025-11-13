// //
// //  GoalDetector.swift
// //  Ten Week Goal App
// //
// //  Written by Claude Code on 2025-11-12
// //
// //  PURPOSE: Complex duplicate detection for Goal entities.
// //  Goals require multi-table analysis including:
// //  - Expectation title (via expectationId)
// //  - Term assignments (via TermGoalAssignment)
// //  - Measure targets (via ExpectationMeasure)
// //
// //  COMPLEXITY: Goals can have the same title but be distinct if they're
// //  assigned to different terms or have different metrics.
// //

// import Foundation
// import SQLiteData

// /// Complex detector for Goal entities with multi-table analysis
// public final class GoalDetector: DuplicationDetector, Sendable {
//     public typealias Entity = Goal

//     private let database: any DatabaseReader

//     public init(database: any DatabaseReader) {
//         self.database = database
//     }

//     /// Extract semantic content from a goal (requires database lookups)
//     public func extractSemanticContent(_ entity: Goal) -> [String] {
//         // This simplified version just uses the goal ID
//         // The real comparison happens in findDuplicatesWithContext
//         return [entity.id.uuidString]
//     }

//     /// Find duplicates with full context loading
//     public func findDuplicates(
//         for goal: Goal,
//         in candidates: [Goal],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // Load full context for the target goal
//         guard let goalContext = try? await loadGoalContext(goal) else {
//             return []
//         }

//         var duplicates: [DuplicateCandidate] = []

//         // Compare against each candidate
//         for candidate in candidates where candidate.id != goal.id {
//             guard let candidateContext = try? await loadGoalContext(candidate) else {
//                 continue
//             }

//             // Calculate composite similarity
//             let similarity = calculateGoalSimilarity(
//                 goalContext,
//                 candidateContext,
//                 using: lshService
//             )

//             let severity = DuplicationSeverity.from(
//                 similarity: similarity,
//                 thresholds: thresholds()
//             )

//             if severity != .none {
//                 // Build detailed message
//                 let message = buildDuplicateMessage(
//                     goalContext,
//                     candidateContext,
//                     similarity: similarity
//                 )

//                 duplicates.append(DuplicateCandidate(
//                     entityId: candidate.id,
//                     similarity: similarity,
//                     severity: severity,
//                     message: message
//                 ))
//             }
//         }

//         return duplicates.sorted { $0.similarity > $1.similarity }
//     }

//     /// Check form data for duplicates (before goal creation)
//     public func checkFormData<FormData>(
//         _ formData: FormData,
//         against existingEntities: [Goal],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // This would be implemented when integrated with GoalFormData
//         // For now, return empty array
//         return []
//     }

//     /// Custom thresholds for goals (stricter due to complexity)
//     public func thresholds() -> SimilarityThresholds {
//         return SimilarityThresholds(
//             exact: 1.0,
//             high: 0.85,
//             moderate: 0.70,
//             low: 0.50
//         )
//     }

//     // MARK: - Private Helpers

//     /// Load full context for a goal (expectation, measures, terms)
//     private func loadGoalContext(_ goal: Goal) async throws -> GoalContext {
//         try await database.read { db in
//             // Load expectation details
//             guard let expectation = try Expectation
//                 .filter { $0.id == goal.expectationId }
//                 .fetchOne(db) else {
//                 throw ValidationError("Expectation not found for goal")
//             }

//             // Load measure targets
//             let measureTargets = try ExpectationMeasure
//                 .filter { $0.expectationId == goal.expectationId }
//                 .join(Measure.all) { $0.measureId.eq($1.id) }
//                 .fetchAll(db)

//             // Load term assignments
//             let termAssignments = try TermGoalAssignment
//                 .filter { $0.goalId == goal.id }
//                 .join(GoalTerm.all) { $0.termId.eq($1.id) }
//                 .fetchAll(db)

//             return GoalContext(
//                 goal: goal,
//                 expectation: expectation,
//                 measureTargets: measureTargets,
//                 termAssignments: termAssignments
//             )
//         }
//     }

//     /// Calculate similarity between two goal contexts
//     private func calculateGoalSimilarity(
//         _ context1: GoalContext,
//         _ context2: GoalContext,
//         using lshService: LSHService
//     ) -> Double {
//         var similarities: [Double] = []
//         var weights: [Double] = []

//         // 1. Title similarity (40% weight)
//         let titleSim = lshService.textSimilarity(
//             context1.expectation.title ?? "",
//             context2.expectation.title ?? ""
//         )
//         similarities.append(titleSim)
//         weights.append(0.4)

//         // 2. Term assignment similarity (30% weight)
//         let termSim = calculateTermSimilarity(
//             context1.termAssignments,
//             context2.termAssignments
//         )
//         similarities.append(termSim)
//         weights.append(0.3)

//         // 3. Measure target similarity (30% weight)
//         let measureSim = calculateMeasureSimilarity(
//             context1.measureTargets,
//             context2.measureTargets
//         )
//         similarities.append(measureSim)
//         weights.append(0.3)

//         // Weighted average
//         let totalWeight = weights.reduce(0, +)
//         let weightedSum = zip(similarities, weights).reduce(0) { $0 + ($1.0 * $1.1) }
//         return weightedSum / totalWeight
//     }

//     /// Calculate similarity between term assignments
//     private func calculateTermSimilarity(
//         _ terms1: [(TermGoalAssignment, GoalTerm)],
//         _ terms2: [(TermGoalAssignment, GoalTerm)]
//     ) -> Double {
//         // Extract term numbers
//         let termNumbers1 = Set(terms1.map { $0.1.termNumber })
//         let termNumbers2 = Set(terms2.map { $0.1.termNumber })

//         // If both have no terms, they're not similar (different from both having same terms)
//         if termNumbers1.isEmpty && termNumbers2.isEmpty {
//             return 0.0
//         }

//         // Calculate Jaccard similarity of term sets
//         let intersection = termNumbers1.intersection(termNumbers2)
//         let union = termNumbers1.union(termNumbers2)

//         return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
//     }

//     /// Calculate similarity between measure targets
//     private func calculateMeasureSimilarity(
//         _ measures1: [(ExpectationMeasure, Measure)],
//         _ measures2: [(ExpectationMeasure, Measure)]
//     ) -> Double {
//         // Group by measure unit
//         let targets1 = Dictionary(grouping: measures1) { $0.1.unit }
//             .mapValues { $0.first?.0.targetValue ?? 0 }
//         let targets2 = Dictionary(grouping: measures2) { $0.1.unit }
//             .mapValues { $0.first?.0.targetValue ?? 0 }

//         // If both have no measures, they're not necessarily similar
//         if targets1.isEmpty && targets2.isEmpty {
//             return 0.5 // Neutral similarity
//         }

//         // Compare units and values
//         let allUnits = Set(targets1.keys).union(Set(targets2.keys))
//         var matchScore = 0.0

//         for unit in allUnits {
//             let value1 = targets1[unit] ?? 0
//             let value2 = targets2[unit] ?? 0

//             if value1 == value2 && value1 != 0 {
//                 matchScore += 1.0 // Exact match
//             } else if abs(value1 - value2) / max(value1, value2, 1) < 0.1 {
//                 matchScore += 0.8 // Within 10%
//             } else if targets1.keys.contains(unit) && targets2.keys.contains(unit) {
//                 matchScore += 0.3 // Same unit, different values
//             }
//         }

//         return matchScore / Double(allUnits.count)
//     }

//     /// Build detailed duplicate message
//     private func buildDuplicateMessage(
//         _ context1: GoalContext,
//         _ context2: GoalContext,
//         similarity: Double
//     ) -> String {
//         var components: [String] = []

//         // Title comparison
//         let title1 = context1.expectation.title ?? "Untitled"
//         let title2 = context2.expectation.title ?? "Untitled"
//         if title1.lowercased() == title2.lowercased() {
//             components.append("Same title: '\(title1)'")
//         } else {
//             components.append("Similar titles")
//         }

//         // Term comparison
//         let terms1 = context1.termAssignments.map { "Term \($0.1.termNumber)" }
//         let terms2 = context2.termAssignments.map { "Term \($0.1.termNumber)" }
//         if !terms1.isEmpty && !terms2.isEmpty {
//             if Set(terms1) == Set(terms2) {
//                 components.append("Same terms: \(terms1.joined(separator: ", "))")
//             } else {
//                 components.append("Overlapping terms")
//             }
//         }

//         // Measure comparison
//         let measures1 = context1.measureTargets.map { "\($0.0.targetValue) \($0.1.unit)" }
//         let measures2 = context2.measureTargets.map { "\($0.0.targetValue) \($0.1.unit)" }
//         if !measures1.isEmpty && !measures2.isEmpty {
//             if Set(measures1) == Set(measures2) {
//                 components.append("Same targets")
//             } else {
//                 components.append("Similar targets")
//             }
//         }

//         // Add similarity percentage
//         components.append(String(format: "(%.0f%% similar)", similarity * 100))

//         return components.joined(separator: " • ")
//     }
// }

// // MARK: - Supporting Types

// /// Full context for a goal including related entities
// private struct GoalContext {
//     let goal: Goal
//     let expectation: Expectation
//     let measureTargets: [(ExpectationMeasure, Measure)]
//     let termAssignments: [(TermGoalAssignment, GoalTerm)]
// }

// // MARK: - Goal Extension for Semantic Content

// extension Goal {
//     /// Generate semantic content including related entities
//     /// Note: This requires database access and should be called within GoalDetector
//     public func semanticContentWithContext(
//         expectation: Expectation,
//         measureTargets: [ExpectationMeasure],
//         termAssignments: [GoalTerm]
//     ) -> [String] {
//         var fields: [String] = []

//         // Title from expectation
//         if let title = expectation.title {
//             fields.append(title)
//         }

//         // Description from expectation
//         if let description = expectation.detailedDescription {
//             fields.append(description)
//         }

//         // Term assignments (sorted for consistency)
//         let termNumbers = termAssignments
//             .map { String($0.termNumber) }
//             .sorted()
//             .joined(separator: ",")
//         if !termNumbers.isEmpty {
//             fields.append("terms:\(termNumbers)")
//         }

//         // Date range
//         if let startDate = startDate {
//             fields.append("start:\(startDate.ISO8601Format())")
//         }
//         if let targetDate = targetDate {
//             fields.append("target:\(targetDate.ISO8601Format())")
//         }

//         return fields
//     }
// }
