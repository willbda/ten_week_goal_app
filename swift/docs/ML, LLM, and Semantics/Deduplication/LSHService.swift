// //
// //  LSHService.swift
// //  Ten Week Goal App
// //
// //  Written by Claude Code on 2025-11-12
// //
// //  PURPOSE: Locality-Sensitive Hashing (LSH) implementation for efficient
// //  similarity detection using MinHash algorithm.
// //
// //  ALGORITHM:
// //  1. Shingle text into overlapping n-grams
// //  2. Generate MinHash signatures for each shingle set
// //  3. Calculate Jaccard similarity from signatures
// //
// //  PERFORMANCE: O(n) hashing, O(1) similarity comparison
// //

// import CryptoKit
// import Foundation

// /// Service for performing locality-sensitive hashing using MinHash
// public final class LSHService: Sendable {
//     /// Number of hash functions to use in MinHash signature
//     private let numHashes: Int

//     /// Random seeds for hash functions (precomputed for consistency)
//     private let hashSeeds: [UInt64]

//     /// Prime number for hash function (large 32-bit prime)
//     private let prime: UInt64 = 4_294_967_311

//     public init(numHashes: Int = 100) {
//         self.numHashes = numHashes

//         // Generate deterministic seeds using a fixed seed
//         var generator = SeededRandomGenerator(seed: 42)
//         let primeLocal = prime  // Capture local copy to avoid self reference
//         self.hashSeeds = (0..<numHashes * 2).map { _ in
//             UInt64.random(in: 1..<primeLocal, using: &generator)
//         }
//     }

//     // MARK: - Text Processing

//     /// Shingle text into overlapping n-grams
//     /// - Parameters:
//     ///   - text: Input text to shingle
//     ///   - size: Size of each shingle (default 3 characters)
//     /// - Returns: Set of unique shingles
//     public func shingle(_ text: String, size: Int = 3) -> Set<String> {
//         // Normalize text: lowercase, trim whitespace
//         let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

//         // Handle edge cases
//         guard normalized.count >= size else {
//             return normalized.isEmpty ? [] : [normalized]
//         }

//         // Generate overlapping shingles
//         var shingles = Set<String>()
//         let characters = Array(normalized)

//         for i in 0...(characters.count - size) {
//             let shingle = String(characters[i..<(i + size)])
//             shingles.insert(shingle)
//         }

//         return shingles
//     }

//     // MARK: - MinHash Algorithm

//     /// Generate MinHash signature for a set of shingles
//     /// - Parameter shingles: Set of text shingles
//     /// - Returns: MinHash signature (array of minimum hash values)
//     public func minHash(_ shingles: Set<String>) -> [UInt64] {
//         guard !shingles.isEmpty else {
//             return Array(repeating: UInt64.max, count: numHashes)
//         }

//         var signature = Array(repeating: UInt64.max, count: numHashes)

//         // For each shingle, compute all hash values
//         for shingle in shingles {
//             let shingleHash = hashString(shingle)

//             // Apply each hash function
//             for i in 0..<numHashes {
//                 let a = hashSeeds[i * 2]
//                 let b = hashSeeds[i * 2 + 1]

//                 // Universal hash function: h(x) = (ax + b) mod p
//                 let hashValue = (a &* shingleHash &+ b) % prime

//                 // Keep minimum value for this hash function
//                 signature[i] = min(signature[i], hashValue)
//             }
//         }

//         return signature
//     }

//     /// Calculate Jaccard similarity from two MinHash signatures
//     /// - Parameters:
//     ///   - sig1: First MinHash signature
//     ///   - sig2: Second MinHash signature
//     /// - Returns: Estimated Jaccard similarity (0.0 to 1.0)
//     public func similarity(_ sig1: [UInt64], _ sig2: [UInt64]) -> Double {
//         guard sig1.count == sig2.count, !sig1.isEmpty else {
//             return 0.0
//         }

//         // Count matching minimum values
//         let matches = zip(sig1, sig2).filter { $0.0 == $0.1 }.count

//         // Jaccard similarity estimate
//         return Double(matches) / Double(sig1.count)
//     }

//     // MARK: - Composite Operations

//     /// Calculate similarity between two text strings using MinHash
//     /// - Parameters:
//     ///   - text1: First text string
//     ///   - text2: Second text string
//     ///   - shingleSize: Size of shingles (default 3)
//     /// - Returns: Estimated similarity (0.0 to 1.0)
//     public func textSimilarity(_ text1: String, _ text2: String, shingleSize: Int = 3) -> Double {
//         let shingles1 = shingle(text1, size: shingleSize)
//         let shingles2 = shingle(text2, size: shingleSize)

//         // Short-circuit for identical or empty texts
//         if shingles1 == shingles2 {
//             return shingles1.isEmpty ? 0.0 : 1.0
//         }

//         let sig1 = minHash(shingles1)
//         let sig2 = minHash(shingles2)

//         return similarity(sig1, sig2)
//     }

//     /// Generate a signature for composite content (multiple fields)
//     /// - Parameters:
//     ///   - fields: Array of field values to hash
//     ///   - weights: Optional weights for each field (default equal weights)
//     ///   - shingleSize: Size of shingles
//     /// - Returns: Weighted MinHash signature
//     public func compositeSignature(
//         fields: [String],
//         weights: [Double]? = nil,
//         shingleSize: Int = 3
//     ) -> [UInt64] {
//         guard !fields.isEmpty else {
//             return Array(repeating: UInt64.max, count: numHashes)
//         }

//         // Use equal weights if not provided
//         let fieldWeights =
//             weights ?? Array(repeating: 1.0 / Double(fields.count), count: fields.count)

//         // Combine shingles from all fields
//         var allShingles = Set<String>()
//         for (field, weight) in zip(fields, fieldWeights) {
//             let fieldShingles = shingle(field, size: shingleSize)

//             // Add field prefix for weighted importance (repeat based on weight)
//             let repetitions = max(1, Int(weight * 10))
//             for _ in 0..<repetitions {
//                 allShingles.formUnion(fieldShingles)
//             }
//         }

//         return minHash(allShingles)
//     }

//     // MARK: - Private Helpers

//     /// Hash a string to UInt64 using SHA256
//     private func hashString(_ string: String) -> UInt64 {
//         let data = Data(string.utf8)
//         let hash = SHA256.hash(data: data)

//         // Take first 8 bytes as UInt64
//         var result: UInt64 = 0
//         for (i, byte) in hash.prefix(8).enumerated() {
//             result |= UInt64(byte) << (i * 8)
//         }

//         return result
//     }
// }

// // MARK: - Seeded Random Generator

// /// Random number generator with fixed seed for reproducibility
// private struct SeededRandomGenerator: RandomNumberGenerator {
//     private var state: UInt64

//     init(seed: UInt64) {
//         self.state = seed
//     }

//     mutating func next() -> UInt64 {
//         // Linear congruential generator
//         state = state &* 2_862_933_555_777_941_757 &+ 3_037_000_493
//         return state
//     }
// }

// // MARK: - LSH Configuration

// /// Configuration for LSH similarity detection
// public struct LSHConfiguration: Sendable {
//     /// Number of hash functions (higher = more accurate, slower)
//     public let numHashes: Int

//     /// Shingle size for text processing
//     public let shingleSize: Int

//     /// Similarity thresholds for different severity levels
//     public let thresholds: SimilarityThresholds

//     public init(
//         numHashes: Int = 100,
//         shingleSize: Int = 3,
//         thresholds: SimilarityThresholds = .default
//     ) {
//         self.numHashes = numHashes
//         self.shingleSize = shingleSize
//         self.thresholds = thresholds
//     }
// }

// /// Similarity thresholds for duplicate detection
// public struct SimilarityThresholds: Sendable {
//     public let exact: Double  // Identical content
//     public let high: Double  // Very likely duplicate
//     public let moderate: Double  // Possible duplicate
//     public let low: Double  // Unlikely but notable

//     public init(
//         exact: Double = 1.0, high: Double = 0.85, moderate: Double = 0.70, low: Double = 0.50
//     ) {
//         self.exact = exact
//         self.high = high
//         self.moderate = moderate
//         self.low = low
//     }

//     public static let `default` = SimilarityThresholds()

//     /// Strict thresholds for catalog entities
//     public static let strict = SimilarityThresholds(
//         exact: 1.0,
//         high: 0.95,
//         moderate: 0.85,
//         low: 0.70
//     )

//     /// Relaxed thresholds for user content
//     public static let relaxed = SimilarityThresholds(
//         exact: 1.0,
//         high: 0.75,
//         moderate: 0.60,
//         low: 0.40
//     )
// }

// /// Severity level for duplicate detection
// public enum DuplicationSeverity: Sendable {
//     case exact  // Identical content (block)
//     case high  // Very likely duplicate (warn)
//     case moderate  // Possible duplicate (info)
//     case low  // Unlikely but notable (debug)
//     case none  // Not a duplicate

//     /// Determine severity from similarity score
//     public static func from(similarity: Double, thresholds: SimilarityThresholds) -> Self {
//         switch similarity {
//         case thresholds.exact:
//             return .exact
//         case thresholds.high..<thresholds.exact:
//             return .high
//         case thresholds.moderate..<thresholds.high:
//             return .moderate
//         case thresholds.low..<thresholds.moderate:
//             return .low
//         default:
//             return .none
//         }
//     }

//     /// Should this severity block form submission?
//     public var shouldBlock: Bool {
//         switch self {
//         case .exact:
//             return true
//         case .high, .moderate, .low, .none:
//             return false
//         }
//     }

//     /// User-facing message for this severity
//     public var message: String {
//         switch self {
//         case .exact:
//             return "This appears to be an exact duplicate"
//         case .high:
//             return "This is very similar to an existing item"
//         case .moderate:
//             return "This might be similar to an existing item"
//         case .low:
//             return "This has some similarity to an existing item"
//         case .none:
//             return ""
//         }
//     }
// }
