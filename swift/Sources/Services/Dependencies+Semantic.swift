//
//  Dependencies+Semantic.swift
//  Ten Week Goal App
//
//  Written by Claude Code on 2025-11-14
//
//  PURPOSE: Dependency injection registration for semantic services
//  Registers SemanticService with modern async API and integrated caching
//

import Dependencies
import Foundation

// MARK: - Semantic Service Dependency

extension DependencyValues {
    /// Semantic service for embedding generation and similarity calculation
    public var semanticService: SemanticService {
        get { self[SemanticServiceKey.self] }
        set { self[SemanticServiceKey.self] = newValue }
    }
}

@available(iOS 26.0, macOS 26.0, *)
private enum SemanticServiceKey: DependencyKey {
    /// Live implementation - uses real NLEmbedding with database caching
    static let liveValue: SemanticService = {
        @Dependency(\.defaultDatabase) var database
        return SemanticService(database: database, configuration: .default)
    }()

    /// Test implementation - uses test database with semantic features disabled
    static let testValue: SemanticService = {
        @Dependency(\.defaultDatabase) var database
        return SemanticService(database: database, configuration: .testing)
    }()

    /// Preview implementation - uses preview database with default configuration
    static let previewValue: SemanticService = {
        @Dependency(\.defaultDatabase) var database
        return SemanticService(database: database, configuration: .default)
    }()
}

// MARK: - Notes on Caching
//
// Embedding caching is now integrated directly into SemanticService via EmbeddingCacheRepository.
// No separate embeddingCache dependency needed - SemanticService handles caching internally.

// MARK: - Usage Examples

/*

 Example 1: Using in a Coordinator (Duplicate Detection)

 public final class GoalCoordinator: Sendable {
     private let database: any DatabaseWriter

     // Inject semantic service (optional for graceful degradation)
     @Dependency(\.semanticService) private var semanticService: SemanticService?

     public func create(from formData: GoalFormData) async throws -> Goal {
         // Check for semantic duplicates (falls back to exact matching if nil)
         guard let semantic = semanticService else {
             // Semantic service not available, use exact title matching
             return try await createWithExactMatching(formData)
         }

         // Generate embedding for new goal title
         guard let newEmbedding = try await semantic.generateEmbedding(for: formData.title) else {
             // NLEmbedding unavailable, fall back to exact matching
             return try await createWithExactMatching(formData)
         }

         // Check against existing goals
         let existingGoals = try await fetchExistingGoals()
         for existing in existingGoals {
             guard let existingEmbedding = try await semantic.generateEmbedding(for: existing.title) else {
                 continue  // Skip if embedding generation fails
             }

             let similarity = semantic.similarity(newEmbedding, existingEmbedding)
             if similarity >= 0.75 {
                 throw ValidationError(userMessage: "Goal '\(formData.title)' is very similar to existing goal '\(existing.title)' (similarity: \(Int(similarity * 100))%)")
             }
         }

         // No duplicates found, create goal
         return try await createGoal(formData)
     }
 }

 Example 2: Using in a ViewModel (Search)

 @Observable
 @MainActor
 final class GoalSearchViewModel {
     @ObservationIgnored
     @Dependency(\.semanticService) var semanticService: SemanticService?

     func searchSimilar(to query: String) async -> [Goal] {
         guard let semantic = semanticService,
               let queryEmbedding = try? await semantic.generateEmbedding(for: query) else {
             return []  // Fall back to empty results if semantic unavailable
         }

         let allGoals = try? await fetchAllGoals()
         var results: [(goal: Goal, similarity: Double)] = []

         for goal in allGoals ?? [] {
             guard let goalEmbedding = try? await semantic.generateEmbedding(for: goal.title) else {
                 continue
             }

             let score = semantic.similarity(queryEmbedding, goalEmbedding)
             if score >= 0.60 {  // Minimum threshold for relevance
                 results.append((goal, score))
             }
         }

         // Sort by similarity (highest first)
         return results
             .sorted { $0.similarity > $1.similarity }
             .map { $0.goal }
     }
 }

 Example 3: Direct Similarity Check (Convenience Method)

 @Dependency(\.semanticService) var semanticService: SemanticService?

 func areGoalsSimilar(_ title1: String, _ title2: String) async -> Bool {
     guard let semantic = semanticService else {
         return false
     }

     // Convenience method handles embedding generation + comparison
     return (try? await semantic.areSimilar(title1, title2, threshold: 0.75)) ?? false
 }

 Example 4: Testing with Dependency Overrides

 func testGoalDuplication() async throws {
     // Create test database with semantic support
     let testDB = try DatabaseQueue()

     await withDependencies {
         $0.defaultDatabase = testDB
         $0.semanticService = SemanticService(database: testDB, configuration: .testing)
     } operation: {
         let coordinator = GoalCoordinator(database: testDB)
         // Test duplicate detection...
     }
 }

 */
