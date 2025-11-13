// //
// //  DuplicationDetector.swift
// //  Ten Week Goal App
// //
// //  Written by Claude Code on 2025-11-12
// //
// //  PURPOSE: Protocol and base implementation for entity-specific duplicate detection.
// //  Each entity type implements this protocol to define its semantic content extraction
// //  and similarity comparison logic.
// //

// import Foundation
// import SQLiteData

// /// Result of duplicate detection
// public struct DuplicateCandidate: Identifiable, Sendable {
//     public let id = UUID()
//     public let entityId: UUID
//     public let similarity: Double
//     public let severity: DuplicationSeverity
//     public let message: String

//     public init(entityId: UUID, similarity: Double, severity: DuplicationSeverity, message: String? = nil) {
//         self.entityId = entityId
//         self.similarity = similarity
//         self.severity = severity
//         self.message = message ?? severity.message
//     }
// }

// /// Protocol for entity-specific duplicate detection
// public protocol DuplicationDetector: Sendable {
//     associatedtype Entity: Identifiable where Entity.ID == UUID

//     /// Extract semantic content from entity for hashing
//     func extractSemanticContent(_ entity: Entity) -> [String]

//     /// Get field weights for composite hashing (optional)
//     func fieldWeights() -> [Double]?

//     /// Get similarity thresholds for this entity type
//     func thresholds() -> SimilarityThresholds

//     /// Find potential duplicates for a given entity
//     func findDuplicates(
//         for entity: Entity,
//         in candidates: [Entity],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate]

//     /// Check if form data would create a duplicate (before entity creation)
//     func checkFormData<FormData>(
//         _ formData: FormData,
//         against existingEntities: [Entity],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate]
// }

// // MARK: - Default Implementation

// extension DuplicationDetector {
//     /// Default field weights (equal for all fields)
//     public func fieldWeights() -> [Double]? {
//         return nil
//     }

//     /// Default thresholds
//     public func thresholds() -> SimilarityThresholds {
//         return .default
//     }

//     /// Default implementation of duplicate finding
//     public func findDuplicates(
//         for entity: Entity,
//         in candidates: [Entity],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // Extract semantic content and generate signature
//         let entityContent = extractSemanticContent(entity)
//         let entitySignature = lshService.compositeSignature(
//             fields: entityContent,
//             weights: fieldWeights()
//         )

//         var duplicates: [DuplicateCandidate] = []
//         let thresholds = self.thresholds()

//         // Compare against all candidates
//         for candidate in candidates where candidate.id != entity.id {
//             let candidateContent = extractSemanticContent(candidate)
//             let candidateSignature = lshService.compositeSignature(
//                 fields: candidateContent,
//                 weights: fieldWeights()
//             )

//             let similarity = lshService.similarity(entitySignature, candidateSignature)
//             let severity = DuplicationSeverity.from(similarity: similarity, thresholds: thresholds)

//             if severity != .none {
//                 duplicates.append(DuplicateCandidate(
//                     entityId: candidate.id,
//                     similarity: similarity,
//                     severity: severity
//                 ))
//             }
//         }

//         // Sort by similarity (highest first)
//         return duplicates.sorted { $0.similarity > $1.similarity }
//     }
// }

// // MARK: - Entity Hashers

// /// Protocol for extracting semantic content from entities
// public protocol SemanticHashable {
//     /// Extract fields that define semantic identity
//     var semanticContent: [String] { get }
// }

// // MARK: - Entity Extensions

// extension Action: SemanticHashable {
//     public var semanticContent: [String] {
//         // Include title, time window (±5 minutes), and measurement summary
//         var fields: [String] = []

//         // Title is primary field
//         if let title = title {
//             fields.append(title)
//         }

//         // Time rounded to 5-minute window
//         let calendar = Calendar.current
//         let rounded = calendar.dateInterval(of: .minute, for: logTime)?.start ?? logTime
//         let window = calendar.date(byAdding: .minute, value: (calendar.component(.minute, from: rounded) / 5) * 5, to: rounded) ?? rounded
//         fields.append(window.ISO8601Format())

//         // Description if present
//         if let description = detailedDescription {
//             fields.append(description)
//         }

//         return fields
//     }
// }

// extension PersonalValue: SemanticHashable {
//     public var semanticContent: [String] {
//         // For values, title is the primary identifier
//         var fields: [String] = []

//         if let title = title {
//             fields.append(title)
//         }

//         // Include level and domain for context
//         fields.append(valueLevel.rawValue)

//         if let domain = lifeDomain {
//             fields.append(domain)
//         }

//         return fields
//     }
// }

// extension Measure: SemanticHashable {
//     public var semanticContent: [String] {
//         // Unit is the primary identifier for measures
//         return [unit, measureType]
//     }
// }

// extension TimePeriod: SemanticHashable {
//     public var semanticContent: [String] {
//         // Date range defines a time period
//         let formatter = ISO8601DateFormatter()
//         formatter.formatOptions = [.withFullDate]

//         return [
//             formatter.string(from: startDate),
//             formatter.string(from: endDate)
//         ]
//     }
// }

// // MARK: - Concrete Detectors

// /// Detector for Measure entities (strict matching on unit)
// public final class MeasureDetector: DuplicationDetector {
//     public typealias Entity = Measure

//     public init() {}

//     public func extractSemanticContent(_ entity: Measure) -> [String] {
//         return entity.semanticContent
//     }

//     public func thresholds() -> SimilarityThresholds {
//         // Very strict for measures - unit names should be unique
//         return .strict
//     }

//     public func checkFormData<FormData>(
//         _ formData: FormData,
//         against existingEntities: [Measure],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // For measures, we need the form data to have a unit field
//         // This would be implemented when we have MeasureFormData
//         return []
//     }
// }

// /// Detector for PersonalValue entities
// public final class PersonalValueDetector: DuplicationDetector {
//     public typealias Entity = PersonalValue

//     public init() {}

//     public func extractSemanticContent(_ entity: PersonalValue) -> [String] {
//         return entity.semanticContent
//     }

//     public func thresholds() -> SimilarityThresholds {
//         // Moderately strict for values
//         return SimilarityThresholds(
//             exact: 1.0,
//             high: 0.90,
//             moderate: 0.75,
//             low: 0.60
//         )
//     }

//     public func checkFormData<FormData>(
//         _ formData: FormData,
//         against existingEntities: [PersonalValue],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // Implementation when we have PersonalValueFormData
//         return []
//     }
// }

// /// Detector for Action entities
// public final class ActionDetector: DuplicationDetector {
//     public typealias Entity = Action

//     public init() {}

//     public func extractSemanticContent(_ entity: Action) -> [String] {
//         return entity.semanticContent
//     }

//     public func thresholds() -> SimilarityThresholds {
//         // More relaxed for actions - repetition is common
//         return .relaxed
//     }

//     public func fieldWeights() -> [Double]? {
//         // Weight title more heavily than time
//         return [0.6, 0.3, 0.1] // title, time, description
//     }

//     public func checkFormData<FormData>(
//         _ formData: FormData,
//         against existingEntities: [Action],
//         using lshService: LSHService
//     ) async -> [DuplicateCandidate] {
//         // Implementation when we integrate with ActionFormData
//         return []
//     }
// }
