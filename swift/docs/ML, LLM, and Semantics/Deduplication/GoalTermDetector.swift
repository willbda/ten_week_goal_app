// //
// //  GoalTermDetector.swift
// //  Ten Week Goal App
// //
// //  Written by Claude Code on 2025-11-12
// //
// //  PURPOSE: Simple duplicate detection for GoalTerm entities.
// //  Term numbers should be unique - "Term 5" shouldn't appear twice.
// //

// import Foundation
// import SQLiteData

// /// Detector for GoalTerm entities (strict matching on termNumber)
// public final class GoalTermDetector: DuplicationDetector, Sendable {
//     public typealias Entity = GoalTerm

//     public init() {}

//     public func extractSemanticContent(_ entity: GoalTerm) -> [String] {
//         // Term number is the primary identifier
//         // Include theme if present for additional context
//         var fields = [String(entity.termNumber)]

//         if let theme = entity.theme {
//             fields.append(theme)
//         }

//         return fields
//     }

//     public func thresholds() -> SimilarityThresholds {
//         // Very strict for term numbers - they should be unique
//         return SimilarityThresholds(
//             exact: 1.0,
//             high: 0.95,
//             moderate: 0.80,
//             low: 0.60
//         )
//     }

//     public func fieldWeights() -> [Double]? {
//         // Term number is much more important than theme
//         return [0.8, 0.2]  // termNumber, theme
//     }

//     public func checkFormData<FormData>(
//         _ formData: FormData,
//         against existingEntities: [GoalTerm],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // Implementation when we have GoalTermFormData
//         return []
//     }

//     /// Override to provide custom duplicate detection based on term numbers
//     public func findDuplicates(
//         for entity: GoalTerm,
//         in candidates: [GoalTerm],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         var duplicates: [DuplicateCandidate] = []

//         for candidate in candidates where candidate.id != entity.id {
//             // Exact match on term number is always a duplicate
//             if candidate.termNumber == entity.termNumber {
//                 duplicates.append(
//                     DuplicateCandidate(
//                         entityId: candidate.id,
//                         similarity: 1.0,
//                         severity: .exact,
//                         message: "Term \(entity.termNumber) already exists"
//                     ))
//             }
//             // Check for similar themes if term numbers differ
//             else if let theme1 = entity.theme,
//                 let theme2 = candidate.theme,
//                 !theme1.isEmpty && !theme2.isEmpty
//             {
//                 let themeSimilarity = lshService.textSimilarity(theme1, theme2)
//                 if themeSimilarity >= 0.8 {
//                     duplicates.append(
//                         DuplicateCandidate(
//                             entityId: candidate.id,
//                             similarity: themeSimilarity * 0.5,  // Reduce weight since term numbers differ
//                             severity: .low,
//                             message: "Term \(candidate.termNumber) has a similar theme"
//                         ))
//                 }
//             }
//         }

//         return duplicates.sorted { $0.similarity > $1.similarity }
//     }
// }

// // Extension for GoalTerm semantic content
// extension GoalTerm: SemanticHashable {
//     public var semanticContent: [String] {
//         var fields = [String(termNumber)]
//         if let theme = theme {
//             fields.append(theme)
//         }
//         return fields
//     }
// }
