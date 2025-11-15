//
//  EmbeddingVector.swift
//  Sources/Models/SemanticTypes
//
//  Written by Claude Code on 2025-11-14
//
//  PURPOSE: Type-safe wrapper for semantic embedding vectors
//  STORAGE: Optimized for BLOB serialization (Float32, not Float64)
//

import Foundation

/// Errors for embedding vector operations
public enum EmbeddingError: LocalizedError, Sendable {
    case invalidDimensions(got: Int, expected: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidDimensions(let got, let expected):
            return "Invalid embedding dimensions: got \(got), expected \(expected)"
        }
    }
}

/// Semantic embedding vector for similarity calculations
///
/// Wraps NLEmbedding output with type safety and serialization
/// Uses Float (32-bit) instead of Double (64-bit) for 50% storage savings
public struct EmbeddingVector: Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Embedding values (Float32 for storage efficiency)
    public let values: [Float]

    /// Computed dimensionality (matches NLEmbedding output)
    public var dimensionality: Int { values.count }

    // MARK: - Initialization

    /// Create embedding vector from Float array
    /// - Parameter values: Embedding values (any dimensionality accepted)
    public init(values: [Float]) {
        self.values = values
    }

    /// Create embedding vector from Double array (convert from NLEmbedding output)
    /// - Parameter doubles: NLEmbedding output (Double array)
    public init(from doubles: [Double]) {
        // Convert Double → Float for storage efficiency
        self.values = doubles.map { Float($0) }
    }

    // MARK: - Serialization (for SQLite BLOB storage)

    /// Serialize to Data for database storage
    /// - Returns: Binary representation (dimensionality × 4 bytes)
    public func toData() -> Data {
        // Convert [Float] to contiguous memory block
        return values.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    /// Deserialize from Data
    /// - Parameter data: Binary representation from database
    /// - Returns: EmbeddingVector if valid, nil if corrupted
    public init?(from data: Data) {
        // Verify data is valid Float array (size must be multiple of 4)
        guard data.count > 0, data.count % MemoryLayout<Float>.size == 0 else {
            return nil
        }

        // Convert Data → [Float]
        let floats = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }

        // Assign values (no dimension validation - accept any size)
        self.values = floats
    }

    // MARK: - Equatable

    public static func == (lhs: EmbeddingVector, rhs: EmbeddingVector) -> Bool {
        lhs.values == rhs.values
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(values)
    }
}

// MARK: - Convenience Extensions

extension EmbeddingVector {
    /// Cosine similarity with another vector
    /// - Parameter other: Vector to compare against
    /// - Returns: Similarity score (0.0 = orthogonal, 1.0 = identical)
    public func cosineSimilarity(to other: EmbeddingVector) -> Double {
        guard self.dimensionality == other.dimensionality else {
            return 0.0  // Vectors must have same dimensions
        }

        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0

        for i in 0..<dimensionality {
            dotProduct += self.values[i] * other.values[i]
            norm1 += self.values[i] * self.values[i]
            norm2 += other.values[i] * other.values[i]
        }

        let denominator = sqrt(norm1) * sqrt(norm2)
        guard denominator > 0 else { return 0.0 }

        return Double(dotProduct / denominator)
    }
}
