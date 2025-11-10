// Value.swift
// Unified domain entity for personal values and life areas
//
// Written by Claude Code on 2025-10-30
// Replaces separate Values, MajorValues, HighestOrderValues, and LifeAreas structs
// Part of 3NF normalization effort to eliminate redundant tables
//
// Values reflect a personal, intentional sense of how one's life should go.
// They provide context for evaluating alignment between actions and what matters.

import Foundation
import SQLiteData

// MARK: - ValueLevel Enum

/// Classification of value types
///
/// Replaces polymorphic subtypes with a clean enum approach.
/// This enables a single unified table while maintaining type distinction.
///
/// NOTE: QueryRepresentable + QueryBindable conformance required by SQLiteData's @Table macro.
/// See SQLiteData+ModelExtensions.swift for the implementation.
public enum ValueLevel: String, Codable, CaseIterable, Sendable, QueryRepresentable, QueryBindable {
    case general = "general"
    case major = "major"
    case highestOrder = "highest_order"
    case lifeArea = "life_area"

    /// Default priority for this value level
    public var defaultPriority: Int {
        switch self {
        case .general:
            return 40
        case .major:
            return 10
        case .highestOrder:
            return 1
        case .lifeArea:
            return 40
        }
    }

    /// Display name for UI presentation
    ///
    /// NOTE: This is domain knowledge (what each level means), so it lives in Models.
    /// ALTERNATIVE: Could move to View layer if we want Models to be purely data.
    /// TRADEOFF: Moving to Views means duplicating this knowledge if used in multiple views.
    /// DECISION: Keep here for now; reconsider in Phase 5 if UI needs diverge from domain names.
    public var displayName: String {
        switch self {
        case .general:
            return "General"
        case .major:
            return "Major Value"
        case .highestOrder:
            return "Highest Order"
        case .lifeArea:
            return "Life Area"
        }
    }
}

// MARK: - Unified Value Struct

/// Personal values that align with beliefs about what is worthwhile
///
/// This unified struct replaces four separate tables (Values, MajorValues,
/// HighestOrderValues, LifeAreas) for proper 3NF normalization.
///
/// **Value Levels**:
/// - **General**: Things you affirm as important (e.g., "Creativity", "Integrity")
/// - **Major**: Actionable values that should regularly appear in actions/goals
/// - **Highest Order**: Abstract philosophical values (e.g., "Eudaimonia", "Truth")
/// - **Life Area**: Domains that provide structure (e.g., "Career", "Health")
///
/// **3NF Benefits**:
/// - Single table for all value types (no redundancy)
/// - Type discrimination via enum (not string polymorphism)
/// - Simplified queries ("get all my values" is trivial)
/// - Consistent schema maintenance
///
/// **Usage**:
/// ```swift
/// // General value
/// let creativity = PersonalValue(
///     title: "Creativity",
///     valueLevel: .general,
///     priority: 30
/// )
///
/// // Major value with alignment guidance
/// let health = PersonalValue(
///     title: "Physical Health",
///     valueLevel: .major,
///     priority: 5,
///     alignmentGuidance: "Regular exercise, good nutrition, adequate sleep"
/// )
///
/// // Life area
/// let career = PersonalValue(
///     title: "Professional Development",
///     valueLevel: .lifeArea,
///     lifeDomain: "Career"
/// )
/// ```
@Table  // SQLiteData will use "personalvalues" as the table name (struct name lowercased + s)
public struct PersonalValue: DomainAbstraction {
    // MARK: - Core Identity (Persistable)

    public var id: UUID
    public var title: String?  // Optional to match Documentable protocol
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // MARK: - Value-specific Properties

    /// Priority level (1-100, lower number = higher priority)
    /// Optional - defaults to valueLevel.defaultPriority if not set
    public var priority: Int?

    /// Classification of this value
    public var valueLevel: ValueLevel

    /// Optional categorization domain
    /// Example: "Health", "Relationships", "Career"
    public var lifeDomain: String?

    /// How this value shows up in actions/goals (primarily for major values)
    /// Example: "Regular exercise, meditation, healthy eating"
    public var alignmentGuidance: String?

    // MARK: - Initialization

    /// Create a new value
    ///
    /// - Parameters:
    ///   - title: Human-readable name (required - matches DB NOT NULL constraint)
    ///   - detailedDescription: Fuller explanation
    ///   - freeformNotes: Additional notes
    ///   - priority: 1-100 (lower = higher priority)
    ///   - valueLevel: Classification (.general, .major, etc.)
    ///   - lifeDomain: Optional categorization
    ///   - alignmentGuidance: How this shows up (for major values)
    ///   - logTime: When created
    ///   - id: Unique identifier
    public init(
        title: String,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        priority: Int? = nil,
        valueLevel: ValueLevel = .general,
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil,
        logTime: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.logTime = logTime
        self.priority = priority ?? valueLevel.defaultPriority
        self.valueLevel = valueLevel
        self.lifeDomain = lifeDomain
        self.alignmentGuidance = alignmentGuidance
    }
}
