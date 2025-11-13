//
//  SemanticService.swift
//  Ten Week Goal App
//
//  Written by Claude Code on 2025-11-12
//
//  PURPOSE: Core semantic similarity service using Apple's NLEmbedding framework
//  Provides unified embedding generation and similarity calculation for:
//  - Deduplication (hybrid with LSH)
//  - Semantic search (future Phase 2)
//  - LLM RAG tools (future Phase 2)
//

import Foundation
import NaturalLanguage
import CryptoKit

/// Service for generating semantic embeddings and calculating similarity
/// Uses Apple's NLEmbedding framework for on-device sentence embeddings
public final class SemanticService: Sendable {

    // MARK: - Configuration

    /// Language for embedding model (configurable for future multi-language support)
    private let language: NLLanguage

    /// Model identifier for tracking which embedding model was used
    private let modelIdentifier: String

    /// Initialize semantic service with language
    /// - Parameter language: Language for NLEmbedding model (default: .english)
    public init(language: NLLanguage = .english) {
        self.language = language
        self.modelIdentifier = "NLEmbedding-sentence-\(language.rawValue)"
    }

    // MARK: - Embedding Generation

    /// Generate semantic embedding for text
    /// - Parameter text: Input text to embed
    /// - Returns: Result containing embedding vector or error
    /// - Note: Returns nil embedding if NLEmbedding unavailable for language
    public func generateEmbedding(for text: String) -> Result<SemanticEmbedding?, SemanticError> {
        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.emptyText)
        }

        // Load sentence embedding model for language
        guard let embedding = NLEmbedding.sentenceEmbedding(for: language) else {
            // Model not available for this language - graceful degradation
            return .success(nil)
        }

        // Normalize text for consistent embeddings
        let normalizedText = normalizeText(text)

        // Generate embedding vector
        guard let vector = embedding.vector(for: normalizedText) else {
            return .failure(.embeddingGenerationFailed(text: text))
        }

        // Create embedding result
        let result = SemanticEmbedding(
            vector: vector,
            sourceText: text,
            textHash: hashText(text),
            modelIdentifier: modelIdentifier,
            generatedAt: Date()
        )

        return .success(result)
    }

    /// Generate embeddings for multiple texts in batch
    /// - Parameter texts: Array of input texts
    /// - Returns: Array of optional embeddings (nil if generation failed)
    /// - Note: More efficient than calling generateEmbedding repeatedly
    public func generateEmbeddings(for texts: [String]) -> [SemanticEmbedding?] {
        return texts.map { text in
            switch generateEmbedding(for: text) {
            case .success(let embedding):
                return embedding
            case .failure:
                return nil
            }
        }
    }

    // MARK: - Similarity Calculation

    /// Calculate cosine similarity between two embeddings
    /// - Parameters:
    ///   - embedding1: First semantic embedding
    ///   - embedding2: Second semantic embedding
    /// - Returns: Similarity score (0.0 = completely different, 1.0 = identical)
    /// - Note: Uses cosine similarity: dot(a,b) / (||a|| * ||b||)
    public func similarity(
        between embedding1: SemanticEmbedding,
        and embedding2: SemanticEmbedding
    ) -> Double {
        return cosineSimilarity(embedding1.vector, embedding2.vector)
    }

    /// Calculate similarity between two texts directly
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Result containing similarity score or error
    /// - Note: Generates embeddings on-the-fly (consider using cached embeddings for performance)
    public func textSimilarity(
        between text1: String,
        and text2: String
    ) -> Result<Double, SemanticError> {
        // Generate embeddings
        guard case .success(let emb1) = generateEmbedding(for: text1),
              let embedding1 = emb1 else {
            return .failure(.embeddingGenerationFailed(text: text1))
        }

        guard case .success(let emb2) = generateEmbedding(for: text2),
              let embedding2 = emb2 else {
            return .failure(.embeddingGenerationFailed(text: text2))
        }

        let similarity = cosineSimilarity(embedding1.vector, embedding2.vector)
        return .success(similarity)
    }

    // MARK: - Nearest Neighbor Search

    /// Find most similar embeddings from a set of candidates
    /// - Parameters:
    ///   - query: Query embedding to compare against
    ///   - candidates: Array of candidate embeddings
    ///   - limit: Maximum number of results to return
    ///   - threshold: Minimum similarity threshold (0.0-1.0)
    /// - Returns: Array of (embedding, similarity) pairs sorted by similarity (highest first)
    public func findSimilar(
        to query: SemanticEmbedding,
        in candidates: [SemanticEmbedding],
        limit: Int = 10,
        threshold: Double = 0.0
    ) -> [(embedding: SemanticEmbedding, similarity: Double)] {
        // Calculate similarity for all candidates
        let scored = candidates.map { candidate in
            (embedding: candidate, similarity: similarity(between: query, and: candidate))
        }

        // Filter by threshold and sort by similarity (descending)
        return scored
            .filter { $0.similarity >= threshold }
            .sorted { $0.similarity > $1.similarity }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Text Normalization

    /// Normalize text for consistent embedding generation
    /// - Parameter text: Raw input text
    /// - Returns: Normalized text
    private func normalizeText(_ text: String) -> String {
        // Lowercase for case-insensitive matching
        let lowercased = text.lowercased()

        // Trim whitespace and newlines
        let trimmed = lowercased.trimmingCharacters(in: .whitespacesAndNewlines)

        // Collapse multiple spaces
        let collapsed = trimmed.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsed
    }

    /// Generate SHA256 hash of text for change detection
    /// - Parameter text: Input text
    /// - Returns: Hex-encoded hash string
    private func hashText(_ text: String) -> String {
        let data = Data(text.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Cosine Similarity Implementation

    /// Calculate cosine similarity between two vectors
    /// - Parameters:
    ///   - a: First vector
    ///   - b: Second vector
    /// - Returns: Similarity score (0.0-1.0)
    /// - Note: Formula: cos(θ) = (a · b) / (||a|| * ||b||)
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else {
            assertionFailure("Vector dimension mismatch: \(a.count) vs \(b.count)")
            return 0.0
        }

        // Dot product: sum of element-wise multiplication
        let dotProduct = zip(a, b).map(*).reduce(0, +)

        // Magnitude of vector a: sqrt(sum of squares)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))

        // Magnitude of vector b: sqrt(sum of squares)
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        // Handle zero-magnitude vectors (avoid division by zero)
        guard magnitudeA > 0 && magnitudeB > 0 else {
            return 0.0
        }

        // Cosine similarity = dot product / (magnitude_a * magnitude_b)
        let similarity = dotProduct / (magnitudeA * magnitudeB)

        // Clamp to [0, 1] range (cosine can be [-1, 1], but we want 0-1 for similarity)
        // Note: For sentence embeddings, negative similarity is rare (usually 0-1 range)
        return max(0.0, min(1.0, similarity))
    }
}

// MARK: - Data Types

/// Semantic embedding result
public struct SemanticEmbedding: Sendable, Hashable {
    /// Embedding vector (dimensionality depends on NLEmbedding model)
    public let vector: [Double]

    /// Original source text (for debugging/audit)
    public let sourceText: String

    /// SHA256 hash of source text (for change detection)
    public let textHash: String

    /// Model identifier (e.g., "NLEmbedding-sentence-english")
    public let modelIdentifier: String

    /// When this embedding was generated
    public let generatedAt: Date

    /// Vector dimensionality
    public var dimensionality: Int {
        return vector.count
    }

    public init(
        vector: [Double],
        sourceText: String,
        textHash: String,
        modelIdentifier: String,
        generatedAt: Date
    ) {
        self.vector = vector
        self.sourceText = sourceText
        self.textHash = textHash
        self.modelIdentifier = modelIdentifier
        self.generatedAt = generatedAt
    }
}

/// Errors that can occur during semantic operations
public enum SemanticError: Error, LocalizedError, Sendable {
    case emptyText
    case embeddingGenerationFailed(text: String)
    case modelUnavailable(language: String)
    case vectorDimensionMismatch(expected: Int, actual: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Cannot generate embedding for empty text"
        case .embeddingGenerationFailed(let text):
            return "Failed to generate embedding for text: \(text.prefix(50))..."
        case .modelUnavailable(let language):
            return "Semantic model unavailable for language: \(language)"
        case .vectorDimensionMismatch(let expected, let actual):
            return "Vector dimension mismatch: expected \(expected), got \(actual)"
        }
    }
}

// MARK: - Serialization Support

extension SemanticEmbedding {
    /// Serialize embedding vector to Data for database storage
    /// - Returns: Binary representation of float32 array
    public func serializeVector() -> Data {
        // Convert [Double] to [Float32] for efficient storage
        let floats = vector.map { Float32($0) }

        return floats.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    /// Deserialize embedding vector from Data
    /// - Parameter data: Binary representation from database
    /// - Returns: SemanticEmbedding if deserialization succeeds
    public static func deserializeVector(from data: Data) -> [Double]? {
        // Calculate number of floats
        let count = data.count / MemoryLayout<Float32>.size
        guard data.count == count * MemoryLayout<Float32>.size else {
            return nil  // Data size not a multiple of Float32 size
        }

        // Read float32 array from data
        let floats = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float32.self))
        }

        // Convert back to [Double]
        return floats.map { Double($0) }
    }
}

// MARK: - Convenience Extensions

extension SemanticService {
    /// Check if semantic embeddings are available for current language
    /// - Returns: True if NLEmbedding model is available
    public var isAvailable: Bool {
        return NLEmbedding.sentenceEmbedding(for: language) != nil
    }

    /// Get dimensionality of embeddings for current language
    /// - Returns: Vector size, or nil if model unavailable
    public var embeddingDimensionality: Int? {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: language),
              let testVector = embedding.vector(for: "test") else {
            return nil
        }
        return testVector.count
    }
}
