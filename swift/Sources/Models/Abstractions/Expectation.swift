// Expectation.swift
// Base entity for all expectations (goals, milestones, obligations)
//
// Written by Claude Code on 2025-10-31
//
// ARCHITECTURE:
// - Expectation: Base table with shared fields
// - Goal/Milestone/Obligation: Subtype tables with FK to expectations
// - Uses table inheritance pattern (like SQL scheduled_tasks � lois/proposals)
//
// 3NF COMPLIANCE:
// - Base fields in expectations table only
// - Type-specific fields in subtype tables
// - No redundant data between base and subtypes
// - Foreign key relationships maintain integrity

import Foundation
import SQLiteData

// MARK: - ExpectationType Enum

/// Classification of expectation types
///
/// Determines which subtype table contains additional fields.
public enum ExpectationType: String, Codable, CaseIterable, Sendable, QueryRepresentable,
    QueryBindable
{
    case goal = "goal"  // Date range with action plan
    case milestone = "milestone"  // Point-in-time checkpoint
    case obligation = "obligation"  // External commitment with deadline

    /// Human-readable description
    public var description: String {
        switch self {
        case .goal:
            return "Goal"
        case .milestone:
            return "Milestone"
        case .obligation:
            return "Obligation"
        }
    }
}

// MARK: - Expectation Struct

/// Base entity for all expectations
///
/// **Database Table**: `expectations`
/// **Purpose**: Shared fields for goals, milestones, and obligations
///
/// **Design Pattern**: Table inheritance (base + subtypes)
/// - Base table: expectations (this struct)
/// - Subtype tables: goals, milestones, obligations
/// - Each subtype has FK to expectations.id
///
/// **Why this pattern?**
/// - 3NF compliant (no redundant data)
/// - Type-specific fields isolated
/// - Shared fields queried efficiently
/// - Extensible (add new types without touching base)
///
/// **Usage**:
/// ```swift
/// // Create base expectation
/// let expectation = Expectation(
///     title: "Spring into Running",
///     expectationType: .goal,
///     priority: 10
/// )
///
/// // Create goal subtype referencing it
/// let goal = Goal(
///     expectationId: expectation.id,
///     startDate: Date("2025-03-01"),
///     targetDate: Date("2025-05-10")
/// )
/// ```
@Table
public struct Expectation: DomainAbstraction {
    // MARK: - Required Fields (Persistable)

    public var id: UUID
    public var logTime: Date

    // MARK: - Core Content (Persistable)

    /// Human-readable name for this expectation
    public var title: String?

    /// Fuller explanation of what this represents
    public var detailedDescription: String?

    /// Additional notes or context
    public var freeformNotes: String?

    // MARK: - Classification

    /// Type of expectation (determines subtype table)
    public var expectationType: ExpectationType

    // MARK: - Eisenhower Matrix Dimensions

    /// How important is this expectation? (1-10, 10 = most important)
    /// Reflects intrinsic value and alignment with personal goals
    public var expectationImportance: Int

    /// How urgent is this expectation? (1-10, 10 = most urgent)
    /// Reflects time sensitivity and deadline pressure
    public var expectationUrgency: Int

    // MARK: - Initialization

    /// Create a new expectation
    ///
    /// - Parameters:
    ///   - title: Human-readable name
    ///   - detailedDescription: Fuller explanation
    ///   - freeformNotes: Additional notes
    ///   - expectationType: Classification (goal/milestone/obligation)
    ///   - expectationImportance: 1-10 (10 = most important). Defaults based on type.
    ///   - expectationUrgency: 1-10 (10 = most urgent). Defaults based on type.
    ///   - logTime: When created
    ///   - id: Unique identifier
    public init(
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        expectationType: ExpectationType,
        expectationImportance: Int? = nil,
        expectationUrgency: Int? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.logTime = logTime
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.expectationType = expectationType

        // Use defaults if not provided, or use Expectation's type-specific defaults
        self.expectationImportance = expectationImportance ?? Expectation.defaultImportance(for: expectationType)
        self.expectationUrgency = expectationUrgency ?? Expectation.defaultUrgency(for: expectationType)
    }
}

// MARK: - Convenience Methods

extension Expectation {
    /// Check if this is a goal type
    public var isGoal: Bool {
        expectationType == .goal
    }

    /// Check if this is a milestone type
    public var isMilestone: Bool {
        expectationType == .milestone
    }

    /// Check if this is an obligation type
    public var isObligation: Bool {
        expectationType == .obligation
    }

    /// Get default importance for this expectation type
    ///
    /// Based on systematic pattern:
    /// - Goals: Self-directed work (high importance)
    /// - Milestones: Progress checkpoints (medium importance)
    /// - Obligations: External commitments (low importance to you)
    public static func defaultImportance(for type: ExpectationType) -> Int {
        switch type {
        case .goal:
            return 8  // Self-directed, internally motivated
        case .milestone:
            return 5  // Time-based progress markers
        case .obligation:
            return 2  // External accountability (not your priorities)
        }
    }

    /// Get default urgency for this expectation type
    ///
    /// Based on systematic pattern:
    /// - Goals: Flexible timing (medium urgency)
    /// - Milestones: Time-sensitive checkpoints (high urgency)
    /// - Obligations: Fixed external deadlines (high urgency)
    public static func defaultUrgency(for type: ExpectationType) -> Int {
        switch type {
        case .goal:
            return 5  // Flexible timing, self-paced
        case .milestone:
            return 8  // Time-sensitive markers
        case .obligation:
            return 6  // Deadline-driven accountability
        }
    }
}
