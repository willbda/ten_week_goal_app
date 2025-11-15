//
//  SemanticConfiguration.swift
//  Sources/Models/SemanticTypes
//
//  Written by Claude Code on 2025-11-14
//
//  PURPOSE: Configuration for semantic similarity and search features
//  PATTERN: Immutable configuration struct with defaults
//
//  RESPONSIBILITIES:
//  - Define similarity thresholds for duplicate detection
//  - Configure search result limits
//  - Feature flags for semantic capabilities
//

import Foundation

/// Configuration for semantic similarity and search operations
public struct SemanticConfiguration: Sendable {

    // MARK: - Properties

    /// Minimum cosine similarity for duplicate detection (0.0-1.0)
    /// Default: 0.75 (75% similar)
    /// - 0.90+: Near-identical (typo-level differences)
    /// - 0.75-0.89: Very similar (likely duplicate)
    /// - 0.60-0.74: Similar (related concepts)
    /// - <0.60: Different topics
    public let similarityThreshold: Double

    /// Maximum number of results for semantic search
    /// Default: 10
    public let maxResults: Int

    /// Enable semantic search features
    /// Default: true (disable for debugging or performance testing)
    public let enableSemanticSearch: Bool

    /// Cache embeddings for future reuse
    /// Default: true (significant performance improvement)
    public let enableCaching: Bool

    /// Model name for NLEmbedding
    /// Default: "NLEmbedding-sentence-english"
    public let embeddingModel: String

    // MARK: - Initialization

    public init(
        similarityThreshold: Double = 0.75,
        maxResults: Int = 10,
        enableSemanticSearch: Bool = true,
        enableCaching: Bool = true,
        embeddingModel: String = "NLEmbedding-sentence-english"
    ) {
        self.similarityThreshold = similarityThreshold
        self.maxResults = maxResults
        self.enableSemanticSearch = enableSemanticSearch
        self.enableCaching = enableCaching
        self.embeddingModel = embeddingModel
    }

    // MARK: - Presets

    /// Default configuration for production use
    public static let `default` = SemanticConfiguration()

    /// Strict duplicate detection (90% similarity threshold)
    public static let strict = SemanticConfiguration(
        similarityThreshold: 0.90,
        maxResults: 5
    )

    /// Relaxed duplicate detection (60% similarity threshold)
    public static let relaxed = SemanticConfiguration(
        similarityThreshold: 0.60,
        maxResults: 20
    )

    /// Testing configuration (semantic features disabled)
    public static let testing = SemanticConfiguration(
        enableSemanticSearch: false,
        enableCaching: false
    )
}
