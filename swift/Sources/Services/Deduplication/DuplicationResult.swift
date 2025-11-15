//
//  DuplicationResult.swift
//  Ten Week Goal App
//
//  Written by Claude Code on 2025-11-12
//
//  PURPOSE: Shared types for semantic duplicate detection
//  Used by SemanticGoalDetector, SemanticActionDetector, SemanticValueDetector
//

import Foundation

// MARK: - Duplicate Match Result

/// Result of duplicate detection showing a potential match
public struct DuplicateMatch: Identifiable, Sendable {
    public let id = UUID()

    /// Entity ID of the potential duplicate
    public let entityId: UUID

    /// Title/name of the potential duplicate
    public let title: String

    /// Semantic similarity score (0.0 - 1.0)
    public let similarity: Double

    /// Entity type for context
    public let entityType: DuplicationEntityType

    /// Calculated severity based on similarity score
    public var severity: DuplicateSeverity {
        DuplicateSeverity.from(similarity: similarity)
    }

    /// Human-readable similarity percentage
    public var similarityPercentage: String {
        "\(Int(similarity * 100))%"
    }

    public init(
        entityId: UUID,
        title: String,
        similarity: Double,
        entityType: DuplicationEntityType
    ) {
        self.entityId = entityId
        self.title = title
        self.similarity = similarity
        self.entityType = entityType
    }
}

// Hashable conformance for DuplicateMatch
extension DuplicateMatch: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(entityId)
        hasher.combine(title)
        hasher.combine(similarity)
        hasher.combine(entityType)
    }

    public static func == (lhs: DuplicateMatch, rhs: DuplicateMatch) -> Bool {
        lhs.entityId == rhs.entityId &&
        lhs.title == rhs.title &&
        lhs.similarity == rhs.similarity &&
        lhs.entityType == rhs.entityType
    }
}

// MARK: - Duplicate Severity

/// Severity classification based on similarity score
public enum DuplicateSeverity: String, Sendable, CaseIterable {
    case exact = "Exact match"
    case high = "Very similar"
    case moderate = "Possibly similar"
    case low = "Somewhat similar"

    /// Determine severity from similarity score
    /// - Parameter similarity: Semantic similarity (0.0 - 1.0)
    /// - Returns: Appropriate severity level
    public static func from(similarity: Double) -> DuplicateSeverity {
        switch similarity {
        case 0.95...:
            return .exact
        case 0.85..<0.95:
            return .high
        case 0.75..<0.85:
            return .moderate
        case 0.50..<0.75:
            return .low
        default:
            return .low
        }
    }

    /// User-facing description
    public var description: String {
        switch self {
        case .exact:
            return "This appears to be an exact duplicate"
        case .high:
            return "This is very similar to an existing item"
        case .moderate:
            return "This might be similar to an existing item"
        case .low:
            return "This has some similarity to an existing item"
        }
    }

    /// Color hint for UI (semantic color names)
    public var colorHint: String {
        switch self {
        case .exact:
            return "red"
        case .high:
            return "orange"
        case .moderate:
            return "yellow"
        case .low:
            return "gray"
        }
    }

    /// Whether this severity should block creation
    public var shouldBlock: Bool {
        switch self {
        case .exact, .high:
            return true
        case .moderate, .low:
            return false
        }
    }
}

// MARK: - Entity Type

/// Entity types that support deduplication
/// Renamed to DuplicationEntityType to avoid conflicts with CachedEntityType
public enum DuplicationEntityType: String, Sendable, CaseIterable, Hashable {
    case goal
    case action
    case value
    case measure
    case term
    case conversation

    /// Human-readable name
    public var displayName: String {
        switch self {
        case .goal:
            return "Goal"
        case .action:
            return "Action"
        case .value:
            return "Personal Value"
        case .measure:
            return "Measure"
        case .term:
            return "Term"
        case .conversation:
            return "Conversation"
        }
    }

    // Note: CachedEntityType conversion removed - no longer needed with SemanticService
    // SemanticService.generateEmbedding() only needs text, not entity type
}

// MARK: - Similarity Thresholds

/// Configurable similarity thresholds for different use cases
public struct SimilarityThresholds: Sendable {
    /// Exact match threshold (typically 0.95+)
    public let exact: Double

    /// High similarity threshold (typically 0.85+)
    public let high: Double

    /// Moderate similarity threshold (typically 0.75+)
    public let moderate: Double

    /// Low similarity threshold (typically 0.50+)
    public let low: Double

    public init(exact: Double, high: Double, moderate: Double, low: Double) {
        self.exact = exact
        self.high = high
        self.moderate = moderate
        self.low = low
    }

    /// Default thresholds (balanced)
    public static let `default` = SimilarityThresholds(
        exact: 0.95,
        high: 0.85,
        moderate: 0.75,
        low: 0.50
    )

    /// Strict thresholds (for catalog entities like measures)
    public static let strict = SimilarityThresholds(
        exact: 0.98,
        high: 0.90,
        moderate: 0.80,
        low: 0.60
    )

    /// Relaxed thresholds (for user-generated content)
    public static let relaxed = SimilarityThresholds(
        exact: 0.90,
        high: 0.75,
        moderate: 0.65,
        low: 0.45
    )
}

// MARK: - Deduplication Configuration

/// Configuration for deduplication behavior
public struct DeduplicationConfig: Sendable {
    /// Minimum threshold for considering something a duplicate
    public let minimumThreshold: Double

    /// Whether to block creation on high-severity matches
    public let blockOnHighSeverity: Bool

    /// Maximum number of duplicate matches to return
    public let maxMatches: Int

    public init(
        minimumThreshold: Double = 0.75,
        blockOnHighSeverity: Bool = true,
        maxMatches: Int = 5
    ) {
        self.minimumThreshold = minimumThreshold
        self.blockOnHighSeverity = blockOnHighSeverity
        self.maxMatches = maxMatches
    }

    /// Default configuration for goals
    public static let goals = DeduplicationConfig(
        minimumThreshold: 0.75,
        blockOnHighSeverity: true,
        maxMatches: 5
    )

    /// Default configuration for actions
    public static let actions = DeduplicationConfig(
        minimumThreshold: 0.80,
        blockOnHighSeverity: false,  // Actions can be similar (e.g., daily runs)
        maxMatches: 3
    )

    /// Default configuration for values
    public static let values = DeduplicationConfig(
        minimumThreshold: 0.85,
        blockOnHighSeverity: true,
        maxMatches: 3
    )
}

// MARK: - Deduplication Error

/// Errors that can occur during duplicate detection
public enum DeduplicationError: Error, LocalizedError, Sendable {
    case semanticServiceUnavailable
    case embeddingGenerationFailed(text: String)
    case noCandidatesToCompare

    public var errorDescription: String? {
        switch self {
        case .semanticServiceUnavailable:
            return "Semantic similarity detection is unavailable on this device"
        case .embeddingGenerationFailed(let text):
            return "Failed to analyze text for similarity: \(text.prefix(50))..."
        case .noCandidatesToCompare:
            return "No existing items to compare against"
        }
    }
}
