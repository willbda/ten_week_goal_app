// //
// //  DeduplicationService.swift
// //  Ten Week Goal App
// //
// //  Written by Claude Code on 2025-11-12
// //
// //  PURPOSE: Central service for coordinating duplicate detection across all entity types.
// //  Provides both proactive (form validation) and reactive (data hygiene) workflows.
// //
// //  RESPONSIBILITIES:
// //  - Coordinate LSH service and entity-specific detectors
// //  - Store duplicate candidates in database
// //  - Provide API for form validation
// //  - Support batch scanning for data hygiene
// //

// import Foundation
// import SQLiteData

// /// Central service for duplicate detection and management
// @MainActor
// public final class DeduplicationService {
//     // Dependencies
//     private let database: any DatabaseWriter
//     private let lshService: LSHService

//     // Entity-specific detectors
//     private let measureDetector = MeasureDetector()
//     private let valueDetector = PersonalValueDetector()
//     private let actionDetector = ActionDetector()

//     // Configuration
//     private let configuration: LSHConfiguration

//     public init(
//         database: any DatabaseWriter,
//         configuration: LSHConfiguration = .init()
//     ) {
//         self.database = database
//         self.configuration = configuration
//         self.lshService = LSHService(numHashes: configuration.numHashes)
//     }

//     // MARK: - Form Validation (Proactive)

//     /// Check if a new action would be a duplicate
//     public func checkActionDuplicate(
//         title: String?,
//         logTime: Date,
//         measurements: [(measureId: UUID, value: Double)]
//     ) async throws -> [DuplicateCandidate] {
//         // Create temporary action for comparison
//         let tempAction = Action(
//             id: UUID(),
//             title: title,
//             detailedDescription: nil,
//             freeformNotes: nil,
//             logTime: logTime,
//             durationMinutes: nil,
//             startTime: nil
//         )

//         // Fetch recent actions (within 1 hour window)
//         let oneHourAgo = logTime.addingTimeInterval(-3600)
//         let oneHourLater = logTime.addingTimeInterval(3600)

//         let recentActions = try await database.read { db in
//             try Action
//                 .filter { action in
//                     action.logTime >= oneHourAgo && action.logTime <= oneHourLater
//                 }
//                 .fetchAll(db)
//         }

//         // Find duplicates
//         let candidates = await actionDetector.findDuplicates(
//             for: tempAction,
//             in: recentActions,
//             using: lshService
//         )

//         // Store high-severity candidates for review
//         if !candidates.isEmpty {
//             try await storeCandidates(
//                 entityType: "action",
//                 baseEntityId: tempAction.id,
//                 candidates: candidates
//             )
//         }

//         return candidates
//     }

//     /// Check if a new measure would be a duplicate
//     public func checkMeasureDuplicate(unit: String) async throws -> [DuplicateCandidate] {
//         // Create temporary measure for comparison
//         let tempMeasure = Measure(
//             id: UUID(),
//             title: nil,
//             detailedDescription: nil,
//             freeformNotes: nil,
//             logTime: Date(),
//             unit: unit,
//             measureType: "",
//             canonicalUnit: nil,
//             conversionFactor: nil
//         )

//         // Fetch all existing measures
//         let existingMeasures = try await database.read { db in
//             try Measure.fetchAll(db)
//         }

//         // Find duplicates
//         let candidates = await measureDetector.findDuplicates(
//             for: tempMeasure,
//             in: existingMeasures,
//             using: lshService
//         )

//         return candidates
//     }

//     /// Check if a new personal value would be a duplicate
//     public func checkValueDuplicate(title: String) async throws -> [DuplicateCandidate] {
//         // Create temporary value for comparison
//         let tempValue = PersonalValue(
//             id: UUID(),
//             title: title,
//             detailedDescription: nil,
//             freeformNotes: nil,
//             logTime: Date(),
//             priority: 50,
//             valueLevel: .general,
//             lifeDomain: nil,
//             alignmentGuidance: nil
//         )

//         // Fetch all existing values
//         let existingValues = try await database.read { db in
//             try PersonalValue.fetchAll(db)
//         }

//         // Find duplicates
//         let candidates = await valueDetector.findDuplicates(
//             for: tempValue,
//             in: existingValues,
//             using: lshService
//         )

//         return candidates
//     }

//     // MARK: - Data Hygiene (Reactive)

//     /// Scan all entities for duplicates (background task)
//     public func scanForDuplicates() async throws -> DuplicateScanResult {
//         var result = DuplicateScanResult()

//         // Scan each entity type
//         result.actionDuplicates = try await scanActions()
//         result.measureDuplicates = try await scanMeasures()
//         result.valueDuplicates = try await scanValues()

//         // Store all candidates in database
//         try await storeAllCandidates(result)

//         return result
//     }

//     /// Scan actions for duplicates
//     private func scanActions() async throws -> [(Action, [DuplicateCandidate])] {
//         let actions = try await database.read { db in
//             try Action.fetchAll(db)
//         }

//         var results: [(Action, [DuplicateCandidate])] = []

//         // Compare each action against all others
//         for (index, action) in actions.enumerated() {
//             // Only compare with actions that come after (avoid duplicate pairs)
//             let remainingActions = Array(actions.suffix(from: index + 1))

//             let candidates = await actionDetector.findDuplicates(
//                 for: action,
//                 in: remainingActions,
//                 using: lshService
//             )

//             if !candidates.isEmpty {
//                 results.append((action, candidates))
//             }
//         }

//         return results
//     }

//     /// Scan measures for duplicates
//     private func scanMeasures() async throws -> [(Measure, [DuplicateCandidate])] {
//         let measures = try await database.read { db in
//             try Measure.fetchAll(db)
//         }

//         var results: [(Measure, [DuplicateCandidate])] = []

//         for (index, measure) in measures.enumerated() {
//             let remainingMeasures = Array(measures.suffix(from: index + 1))

//             let candidates = await measureDetector.findDuplicates(
//                 for: measure,
//                 in: remainingMeasures,
//                 using: lshService
//             )

//             if !candidates.isEmpty {
//                 results.append((measure, candidates))
//             }
//         }

//         return results
//     }

//     /// Scan personal values for duplicates
//     private func scanValues() async throws -> [(PersonalValue, [DuplicateCandidate])] {
//         let values = try await database.read { db in
//             try PersonalValue.fetchAll(db)
//         }

//         var results: [(PersonalValue, [DuplicateCandidate])] = []

//         for (index, value) in values.enumerated() {
//             let remainingValues = Array(values.suffix(from: index + 1))

//             let candidates = await valueDetector.findDuplicates(
//                 for: value,
//                 in: remainingValues,
//                 using: lshService
//             )

//             if !candidates.isEmpty {
//                 results.append((value, candidates))
//             }
//         }

//         return results
//     }

//     // MARK: - Database Storage

//     /// Store duplicate candidates in database
//     private func storeCandidates(
//         entityType: String,
//         baseEntityId: UUID,
//         candidates: [DuplicateCandidate]
//     ) async throws {
//         try await database.write { db in
//             for candidate in candidates {
//                 // Create database record
//                 let record = DuplicateCandidateRecord(
//                     id: UUID(),
//                     entityType: entityType,
//                     entity1Id: baseEntityId,
//                     entity2Id: candidate.entityId,
//                     similarity: candidate.similarity,
//                     severity: candidate.severity.databaseValue,
//                     status: .pending,
//                     createdAt: Date()
//                 )

//                 // Insert or update (in case we've seen this pair before)
//                 try record.save(to: db)
//             }
//         }
//     }

//     /// Store all candidates from a scan
//     private func storeAllCandidates(_ result: DuplicateScanResult) async throws {
//         try await database.write { db in
//             // Store action duplicates
//             for (action, candidates) in result.actionDuplicates {
//                 for candidate in candidates {
//                     let record = DuplicateCandidateRecord(
//                         id: UUID(),
//                         entityType: "action",
//                         entity1Id: action.id,
//                         entity2Id: candidate.entityId,
//                         similarity: candidate.similarity,
//                         severity: candidate.severity.databaseValue,
//                         status: .pending,
//                         createdAt: Date()
//                     )
//                     try record.save(to: db)
//                 }
//             }

//             // Store measure duplicates
//             for (measure, candidates) in result.measureDuplicates {
//                 for candidate in candidates {
//                     let record = DuplicateCandidateRecord(
//                         id: UUID(),
//                         entityType: "measure",
//                         entity1Id: measure.id,
//                         entity2Id: candidate.entityId,
//                         similarity: candidate.similarity,
//                         severity: candidate.severity.databaseValue,
//                         status: .pending,
//                         createdAt: Date()
//                     )
//                     try record.save(to: db)
//                 }
//             }

//             // Store value duplicates
//             for (value, candidates) in result.valueDuplicates {
//                 for candidate in candidates {
//                     let record = DuplicateCandidateRecord(
//                         id: UUID(),
//                         entityType: "personalValue",
//                         entity1Id: value.id,
//                         entity2Id: candidate.entityId,
//                         similarity: candidate.similarity,
//                         severity: candidate.severity.databaseValue,
//                         status: .pending,
//                         createdAt: Date()
//                     )
//                     try record.save(to: db)
//                 }
//             }
//         }
//     }

//     // MARK: - Resolution Management

//     /// Mark a duplicate candidate as resolved
//     public func resolveDuplicate(
//         candidateId: UUID,
//         resolution: DuplicateResolution,
//         notes: String? = nil
//     ) async throws {
//         try await database.write { db in
//             // Fetch the candidate
//             guard var candidate = try DuplicateCandidateRecord
//                 .filter { $0.id == candidateId }
//                 .fetchOne(db) else {
//                 throw ValidationError("Duplicate candidate not found")
//             }

//             // Update resolution
//             candidate.status = resolution.status
//             candidate.resolution = resolution.rawValue
//             candidate.resolutionNotes = notes
//             candidate.resolvedAt = Date()

//             try candidate.save(to: db)
//         }
//     }

//     /// Get pending duplicates for review
//     public func getPendingDuplicates() async throws -> [DuplicateCandidateRecord] {
//         try await database.read { db in
//             try DuplicateCandidateRecord
//                 .filter { $0.status == .pending }
//                 .order { $0.similarity.desc() }
//                 .fetchAll(db)
//         }
//     }
// }

// // MARK: - Supporting Types

// /// Result of a full duplicate scan
// public struct DuplicateScanResult {
//     public var actionDuplicates: [(Action, [DuplicateCandidate])] = []
//     public var measureDuplicates: [(Measure, [DuplicateCandidate])] = []
//     public var valueDuplicates: [(PersonalValue, [DuplicateCandidate])] = []

//     public var totalDuplicates: Int {
//         actionDuplicates.reduce(0) { $0 + $1.1.count } +
//         measureDuplicates.reduce(0) { $0 + $1.1.count } +
//         valueDuplicates.reduce(0) { $0 + $1.1.count }
//     }

//     public var hasExactDuplicates: Bool {
//         let hasExactActions = actionDuplicates.contains { _, candidates in
//             candidates.contains { $0.severity == .exact }
//         }
//         let hasExactMeasures = measureDuplicates.contains { _, candidates in
//             candidates.contains { $0.severity == .exact }
//         }
//         let hasExactValues = valueDuplicates.contains { _, candidates in
//             candidates.contains { $0.severity == .exact }
//         }
//         return hasExactActions || hasExactMeasures || hasExactValues
//     }
// }

// /// Resolution options for duplicates
// public enum DuplicateResolution: String {
//     case mergedInto1 = "merged_into_1"
//     case mergedInto2 = "merged_into_2"
//     case keptBoth = "kept_both"
//     case deleted1 = "deleted_1"
//     case deleted2 = "deleted_2"

//     var status: DuplicateCandidateStatus {
//         switch self {
//         case .mergedInto1, .mergedInto2:
//             return .merged
//         case .keptBoth:
//             return .ignored
//         case .deleted1, .deleted2:
//             return .resolved
//         }
//     }
// }

// // MARK: - Database Model

// /// Database record for duplicate candidates
// @Table("duplicateCandidates")
// public struct DuplicateCandidateRecord: Identifiable, Sendable {
//     @Column("id") public var id: UUID
//     @Column("entityType") public var entityType: String
//     @Column("entity1Id") public var entity1Id: UUID
//     @Column("entity2Id") public var entity2Id: UUID
//     @Column("similarity") public var similarity: Double
//     @Column("severity") public var severity: String
//     @Column("status") public var status: DuplicateCandidateStatus
//     @Column("createdAt") public var createdAt: Date
//     @Column("reviewedAt") public var reviewedAt: Date?
//     @Column("resolvedAt") public var resolvedAt: Date?
//     @Column("resolution") public var resolution: String?
//     @Column("resolutionNotes") public var resolutionNotes: String?

//     public init(
//         id: UUID,
//         entityType: String,
//         entity1Id: UUID,
//         entity2Id: UUID,
//         similarity: Double,
//         severity: String,
//         status: DuplicateCandidateStatus,
//         createdAt: Date,
//         reviewedAt: Date? = nil,
//         resolvedAt: Date? = nil,
//         resolution: String? = nil,
//         resolutionNotes: String? = nil
//     ) {
//         self.id = id
//         self.entityType = entityType
//         self.entity1Id = entity1Id
//         self.entity2Id = entity2Id
//         self.similarity = similarity
//         self.severity = severity
//         self.status = status
//         self.createdAt = createdAt
//         self.reviewedAt = reviewedAt
//         self.resolvedAt = resolvedAt
//         self.resolution = resolution
//         self.resolutionNotes = resolutionNotes
//     }
// }

// /// Status of duplicate candidate
// public enum DuplicateCandidateStatus: String, Codable, Sendable {
//     case pending
//     case merged
//     case ignored
//     case resolved
// }

// // Extension for DuplicationSeverity database storage
// extension DuplicationSeverity {
//     var databaseValue: String {
//         switch self {
//         case .exact: return "exact"
//         case .high: return "high"
//         case .moderate: return "moderate"
//         case .low: return "low"
//         case .none: return "low" // Shouldn't be stored, but handle gracefully
//         }
//     }
// }
