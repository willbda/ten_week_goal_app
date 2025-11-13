//
//  Dependencies+Semantic.swift
//  Ten Week Goal App
//
//  Written by Claude Code on 2025-11-12
//
//  PURPOSE: Dependency injection registration for semantic services
//  Registers SemanticService and EmbeddingCache into the app's dependency system
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

private enum SemanticServiceKey: DependencyKey {
    /// Live implementation - uses real NLEmbedding
    static let liveValue = SemanticService(language: .english)

    /// Test implementation - same as live (NLEmbedding works in tests)
    static let testValue = SemanticService(language: .english)

    /// Preview implementation - same as live for SwiftUI previews
    static let previewValue = SemanticService(language: .english)
}

// MARK: - Embedding Cache Dependency

extension DependencyValues {
    /// Embedding cache for persistent embedding storage
    public var embeddingCache: EmbeddingCache {
        get { self[EmbeddingCacheKey.self] }
        set { self[EmbeddingCacheKey.self] = newValue }
    }
}

private enum EmbeddingCacheKey: DependencyKey {
    /// Live implementation - uses real database and semantic service
    static let liveValue: EmbeddingCache = {
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.semanticService) var semanticService
        return EmbeddingCache(database: database, semanticService: semanticService)
    }()

    /// Test implementation - uses test database and semantic service
    static let testValue: EmbeddingCache = {
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.semanticService) var semanticService
        return EmbeddingCache(database: database, semanticService: semanticService)
    }()

    /// Preview implementation - uses preview database and semantic service
    static let previewValue: EmbeddingCache = {
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.semanticService) var semanticService
        return EmbeddingCache(database: database, semanticService: semanticService)
    }()
}

// MARK: - Usage Examples

/*

 Example 1: Using in a Coordinator

 public final class GoalCoordinator: Sendable {
     private let database: any DatabaseWriter

     // Inject semantic services
     @Dependency(\.semanticService) private var semanticService
     @Dependency(\.embeddingCache) private var embeddingCache

     public func create(from formData: GoalFormData) async throws -> Goal {
         // Check for duplicates using semantic similarity
         let detector = SemanticGoalDetector(
             embeddingCache: embeddingCache,
             semanticService: semanticService
         )

         let duplicates = try await detector.findDuplicates(
             for: formData.title,
             in: existingGoals,
             threshold: 0.75
         )

         // Handle duplicates...
     }
 }

 Example 2: Using in a ViewModel

 @Observable
 @MainActor
 final class GoalFormViewModel {
     @ObservationIgnored
     @Dependency(\.embeddingCache) var embeddingCache

     @ObservationIgnored
     @Dependency(\.semanticService) var semanticService

     func checkForDuplicates(_ title: String) async -> [DuplicateMatch] {
         // Use semantic services to check for duplicates
     }
 }

 Example 3: Testing with Dependency Overrides

 func testGoalCreation() async throws {
     // Override dependencies for testing
     await withDependencies {
         $0.semanticService = MockSemanticService()
         $0.embeddingCache = MockEmbeddingCache()
     } operation: {
         let coordinator = GoalCoordinator(database: testDB)
         let goal = try await coordinator.create(from: formData)
         // Assertions...
     }
 }

 */
