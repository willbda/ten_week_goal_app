//
//  EmbeddingCache.swift
//  Ten Week Goal App
//
//  Written by Claude Code on 2025-11-12
//
//  PURPOSE: Database persistence layer for semantic embeddings
//  Provides caching of embeddings to avoid regeneration on every similarity check
//
//  PATTERN: Lazy generation with hash-based invalidation
//  - Embeddings generated on-demand during first similarity check
//  - Cached in semanticEmbeddings table with textHash for change detection
//  - Automatic invalidation when source text changes (hash mismatch)
//

import Foundation
import SQLiteData

/// Database model for cached semantic embeddings
@Table("semanticEmbeddings")
public struct CachedEmbedding: Identifiable, Sendable {
    @Column("id") public let id: UUID
    @Column("entityType") public let entityType: String
    @Column("entityId") public let entityId: UUID
    @Column("textHash") public let textHash: String
    @Column("sourceText") public let sourceText: String
    @Column("embedding") public let embedding: Data
    @Column("embeddingModel") public let embeddingModel: String
    @Column("dimensionality") public let dimensionality: Int
    @Column("generatedAt") public let generatedAt: Date
    @Column("logTime") public let logTime: Date

    public init(
        id: UUID = UUID(),
        entityType: String,
        entityId: UUID,
        textHash: String,
        sourceText: String,
        embedding: Data,
        embeddingModel: String,
        dimensionality: Int,
        generatedAt: Date = Date(),
        logTime: Date = Date()
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.textHash = textHash
        self.sourceText = sourceText
        self.embedding = embedding
        self.embeddingModel = embeddingModel
        self.dimensionality = dimensionality
        self.generatedAt = generatedAt
        self.logTime = logTime
    }
}

/// Service for caching and retrieving semantic embeddings from database
public final class EmbeddingCache: Sendable {

    // MARK: - Dependencies

    private let database: any DatabaseWriter
    private let semanticService: SemanticService

    // MARK: - Initialization

    public init(database: any DatabaseWriter, semanticService: SemanticService) {
        self.database = database
        self.semanticService = semanticService
    }

    // MARK: - Cache Operations

    /// Get or generate embedding for entity text
    /// - Parameters:
    ///   - text: Source text to embed
    ///   - entityType: Type of entity ('goal', 'action', 'value', etc.)
    ///   - entityId: UUID of the entity
    /// - Returns: Semantic embedding (from cache or freshly generated)
    /// - Throws: Database errors or embedding generation errors
    /// - Note: Uses lazy generation pattern - embedding created on first access
    public func getOrGenerateEmbedding(
        for text: String,
        entityType: CachedEntityType,
        entityId: UUID
    ) async throws -> SemanticEmbedding? {
        // Generate embedding with semantic service
        guard case .success(let embedding) = semanticService.generateEmbedding(for: text),
              let semanticEmbedding = embedding else {
            // NLEmbedding unavailable for language - return nil for graceful degradation
            return nil
        }

        // Check if cached embedding exists and is current
        if let cached = try await getCachedEmbedding(
            for: entityId,
            entityType: entityType,
            textHash: semanticEmbedding.textHash
        ) {
            return cached
        }

        // Cache new embedding
        try await cacheEmbedding(
            semanticEmbedding,
            entityType: entityType,
            entityId: entityId
        )

        return semanticEmbedding
    }

    /// Get embedding from cache if it exists and hash matches
    /// - Parameters:
    ///   - entityId: Entity UUID
    ///   - entityType: Entity type
    ///   - textHash: Expected text hash (for invalidation check)
    /// - Returns: Cached embedding if found and hash matches, nil otherwise
    private func getCachedEmbedding(
        for entityId: UUID,
        entityType: CachedEntityType,
        textHash: String
    ) async throws -> SemanticEmbedding? {
        return try await database.read { db in
            // Query cached embedding
            guard let cached = try CachedEmbedding
                .where({ $0.entityId.eq(entityId) && $0.entityType.eq(entityType.rawValue) })
                .fetchOne(db) else {
                return nil
            }

            // Check if hash matches (invalidate if text changed)
            guard cached.textHash == textHash else {
                // Text changed - cached embedding is stale
                return nil
            }

            // Deserialize vector from binary data
            guard let vector = SemanticEmbedding.deserializeVector(from: cached.embedding) else {
                // Deserialization failed - regenerate
                return nil
            }

            // Reconstruct semantic embedding
            return SemanticEmbedding(
                vector: vector,
                sourceText: cached.sourceText,
                textHash: cached.textHash,
                modelIdentifier: cached.embeddingModel,
                generatedAt: cached.generatedAt
            )
        }
    }

    /// Cache semantic embedding to database
    /// - Parameters:
    ///   - embedding: Semantic embedding to cache
    ///   - entityType: Entity type
    ///   - entityId: Entity UUID
    private func cacheEmbedding(
        _ embedding: SemanticEmbedding,
        entityType: CachedEntityType,
        entityId: UUID
    ) async throws {
        try await database.write { db in
            // Delete any existing cached embedding (UNIQUE constraint handles this too)
            try CachedEmbedding
                .delete()
                .where({ $0.entityId.eq(entityId) && $0.entityType.eq(entityType.rawValue) })
                .execute(db)

            // Insert new cached embedding
            try CachedEmbedding.insert {
                CachedEmbedding(
                    entityType: entityType.rawValue,
                    entityId: entityId,
                    textHash: embedding.textHash,
                    sourceText: embedding.sourceText,
                    embedding: embedding.serializeVector(),
                    embeddingModel: embedding.modelIdentifier,
                    dimensionality: embedding.dimensionality,
                    generatedAt: embedding.generatedAt
                )
            }.execute(db)
        }
    }

    // MARK: - Batch Operations

    /// Get or generate embeddings for multiple entities
    /// - Parameters:
    ///   - entities: Array of (text, entityType, entityId) tuples
    /// - Returns: Array of optional embeddings (nil if generation failed)
    /// - Note: More efficient than calling getOrGenerateEmbedding repeatedly
    public func getOrGenerateEmbeddings(
        for entities: [(text: String, entityType: CachedEntityType, entityId: UUID)]
    ) async throws -> [SemanticEmbedding?] {
        // Process in parallel for better performance
        return try await withThrowingTaskGroup(of: (Int, SemanticEmbedding?).self) { group in
            // Launch tasks for each entity
            for (index, entity) in entities.enumerated() {
                group.addTask {
                    let embedding = try await self.getOrGenerateEmbedding(
                        for: entity.text,
                        entityType: entity.entityType,
                        entityId: entity.entityId
                    )
                    return (index, embedding)
                }
            }

            // Collect results in original order
            var results: [(Int, SemanticEmbedding?)] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by index and return embeddings
            return results
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }

    // MARK: - Cache Management

    /// Invalidate cached embedding for entity (force regeneration on next access)
    /// - Parameters:
    ///   - entityId: Entity UUID
    ///   - entityType: Entity type
    public func invalidate(entityId: UUID, entityType: CachedEntityType) async throws {
        try await database.write { db in
            try CachedEmbedding
                .delete()
                .where({ $0.entityId.eq(entityId) && $0.entityType.eq(entityType.rawValue) })
                .execute(db)
        }
    }

    /// Get cache statistics
    /// - Returns: Cache statistics (total count, size, etc.)
    /// - Note: Cache grows naturally with entities. Post-v1.0, consider LRU eviction based on
    ///         actual usage patterns if storage becomes a concern (unlikely given small size).
    public func getCacheStatistics() async throws -> CacheStatistics {
        return try await database.read { db in
            let total = try CachedEmbedding.count().fetchOne(db) ?? 0

            // Calculate total size (approximate)
            let allEmbeddings = try CachedEmbedding.all.fetchAll(db)
            let totalBytes = allEmbeddings.reduce(0) { $0 + $1.embedding.count }

            // Count by entity type
            let byType = Dictionary(grouping: allEmbeddings) { $0.entityType }
                .mapValues { $0.count }

            return CacheStatistics(
                totalEmbeddings: total,
                totalBytes: totalBytes,
                countByEntityType: byType,
                oldestEmbedding: allEmbeddings.min(by: { $0.generatedAt < $1.generatedAt })?.generatedAt,
                newestEmbedding: allEmbeddings.max(by: { $0.generatedAt < $1.generatedAt })?.generatedAt
            )
        }
    }
}

// MARK: - Supporting Types

/// Entity types that can have cached embeddings
/// Note: This is defined in EmbeddingCache to avoid circular dependencies
/// If DuplicationResult.EntityType exists, use typealias to reference it
public enum CachedEntityType: String, Sendable, CaseIterable {
    case goal
    case action
    case value
    case measure
    case term
    case conversation
}

/// Cache statistics
public struct CacheStatistics: Sendable {
    public let totalEmbeddings: Int
    public let totalBytes: Int
    public let countByEntityType: [String: Int]
    public let oldestEmbedding: Date?
    public let newestEmbedding: Date?

    /// Average bytes per embedding
    public var averageBytesPerEmbedding: Double {
        guard totalEmbeddings > 0 else { return 0 }
        return Double(totalBytes) / Double(totalEmbeddings)
    }

    /// Total cache size in MB
    public var totalSizeMB: Double {
        return Double(totalBytes) / (1024.0 * 1024.0)
    }
}

// MARK: - Convenience Extensions

extension EmbeddingCache {
    /// Check if embedding exists for entity
    /// - Parameters:
    ///   - entityId: Entity UUID
    ///   - entityType: Entity type
    /// - Returns: True if cached embedding exists (regardless of hash)
    public func hasEmbedding(for entityId: UUID, entityType: CachedEntityType) async throws -> Bool {
        return try await database.read { db in
            let count = try CachedEmbedding
                .where({ $0.entityId.eq(entityId) && $0.entityType.eq(entityType.rawValue) })
                .count()
                .fetchOne(db) ?? 0
            return count > 0
        }
    }
}
