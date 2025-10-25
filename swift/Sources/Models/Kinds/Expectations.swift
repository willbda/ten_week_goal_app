// Expectations.swift
// Unified enum for goals, milestones, obligations, and aspirations
//
// Written by Claude Code on 2025-10-22
// Restored GRDB implementation on 2025-10-25 (enums with associated values require manual Codable)
//
// Uses Swift enum with associated values to model different types of expectations.
// Each case enforces its own required fields at compile time, while allowing
// storage in a single database table and unified collection type.
//
// Architecture:
// - Expectation: Top-level enum with 4 cases
// - Each case has an associated struct with type-specific fields
// - Custom Codable implementation for JSON storage
// - GRDB integration via manual Codable conformance

import Foundation
import GRDB

// MARK: - Expectation Enum

/// Unified type for personal goals, milestones, obligations, and aspirations
///
/// Uses Swift enum with associated values to enforce type-specific constraints
/// at compile time while maintaining a unified collection type.
///
/// **Types**:
/// - `.goal`: SMART goal with measurements, dates, and actionability
/// - `.milestone`: Point-in-time checkpoint toward a larger objective
/// - `.obligation`: External requirement with deadline and requestor
/// - `.aspiration`: Long-term, potentially vague desire
///
/// **Example**:
/// ```swift
/// let myGoals: [Expectation] = [
///     .goal(Goal(title: "Run 120km", ...)),
///     .milestone(Milestone(title: "Hit 50km by week 5", ...)),
///     .obligation(Obligation(title: "Submit quarterly report", ...))
/// ]
/// ```
public enum Expectation: Codable, Sendable, Identifiable {
    case goal(Goal)
    case milestone(Milestone)
    case obligation(Obligation)
    case aspiration(Aspiration)

    // MARK: - Associated Value Types

    /// SMART goal: Specific, Measurable, Achievable, Relevant, Time-bound
    ///
    /// Required fields enforce SMART criteria:
    /// - Specific: `title`
    /// - Measurable: `measurementUnit`, `measurementTarget`
    /// - Time-bound: `startDate`, `targetDate`
    /// - Relevant: `howRelevant`
    /// - Actionable: `howActionable`
    public struct Goal: Codable, Sendable, Identifiable, Hashable {
        public let id: UUID
        public var title: String
        public var description: String?

        // Measurable (required)
        public var measurementUnit: String
        public var measurementTarget: Double

        // Time-bound (required)
        public var startDate: Date
        public var targetDate: Date

        // SMART fields (required for full SMART compliance)
        public var howRelevant: String
        public var howActionable: String
        public var expectedTermLength: Int?  // e.g., 10 for 10-week term

        // Motivating
        public var priority: Int
        public var lifeDomain: String?

        public init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            measurementUnit: String,
            measurementTarget: Double,
            startDate: Date,
            targetDate: Date,
            howRelevant: String,
            howActionable: String,
            expectedTermLength: Int? = nil,
            priority: Int = 80,
            lifeDomain: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.measurementUnit = measurementUnit
            self.measurementTarget = measurementTarget
            self.startDate = startDate
            self.targetDate = targetDate
            self.howRelevant = howRelevant
            self.howActionable = howActionable
            self.expectedTermLength = expectedTermLength
            self.priority = priority
            self.lifeDomain = lifeDomain
        }
    }

    /// Milestone: Point-in-time checkpoint
    ///
    /// Unlike goals (which have date ranges), milestones mark specific moments.
    /// `targetDate` is required, `startDate` is meaningless for a checkpoint.
    ///
    /// Example: "Reach 50km by week 5", "Complete chapter 3 by Nov 15"
    public struct Milestone: Codable, Sendable, Identifiable, Hashable {
        public let id: UUID
        public var title: String
        public var description: String?

        // Required: when this checkpoint should be reached
        public var targetDate: Date

        // Optional measurement
        public var measurementTarget: Double?
        public var measurementUnit: String?

        // Motivating
        public var priority: Int
        public var lifeDomain: String?

        public init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            targetDate: Date,
            measurementTarget: Double? = nil,
            measurementUnit: String? = nil,
            priority: Int = 30,  // Milestones are moderate priority
            lifeDomain: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.targetDate = targetDate
            self.measurementTarget = measurementTarget
            self.measurementUnit = measurementUnit
            self.priority = priority
            self.lifeDomain = lifeDomain
        }
    }

    /// Obligation: External requirement or commitment
    ///
    /// Things requested by others that you've agreed to do.
    /// Not intrinsically motivated (unlike goals), but important nonetheless.
    ///
    /// Example: "Submit quarterly report to board by Friday"
    public struct Obligation: Codable, Sendable, Identifiable, Hashable {
        public let id: UUID
        public var title: String
        public var description: String?

        // Required: deadline for this obligation
        public var deadline: Date

        // Context
        public var requestedBy: String?  // Who asked
        public var consequence: String?  // What happens if missed

        // Motivating
        public var priority: Int

        public init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            deadline: Date,
            requestedBy: String? = nil,
            consequence: String? = nil,
            priority: Int = 90  // Obligations are high priority (external accountability)
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.deadline = deadline
            self.requestedBy = requestedBy
            self.consequence = consequence
            self.priority = priority
        }
    }

    /// Aspiration: Long-term, potentially vague desire
    ///
    /// Things you want but haven't committed to achieving yet.
    /// No required fields beyond title - aspirations can be entirely open-ended.
    ///
    /// Example: "Write a book someday", "Learn to play piano"
    public struct Aspiration: Codable, Sendable, Identifiable, Hashable {
        public let id: UUID
        public var title: String
        public var description: String?

        // Optional context
        public var lifeDomain: String?
        public var priority: Int

        // Optional future planning
        public var targetDate: Date?  // If you eventually set a deadline

        public init(
            id: UUID = UUID(),
            title: String,
            description: String? = nil,
            lifeDomain: String? = nil,
            priority: Int = 50,
            targetDate: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.lifeDomain = lifeDomain
            self.priority = priority
            self.targetDate = targetDate
        }
    }

    // MARK: - Identifiable Conformance

    /// Unique identifier (delegates to associated value's ID)
    public var id: UUID {
        switch self {
        case .goal(let g): return g.id
        case .milestone(let m): return m.id
        case .obligation(let o): return o.id
        case .aspiration(let a): return a.id
        }
    }

    // MARK: - Codable Implementation

    /// Coding keys for JSON storage
    ///
    /// Stores enum as: `{"type": "goal", "data": {...}}`
    private enum CodingKeys: String, CodingKey {
        case type = "expectation_type"
        case data
    }

    /// Expectation type discriminator
    private enum ExpectationType: String, Codable {
        case goal
        case milestone
        case obligation
        case aspiration
    }

    /// Decode from JSON
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ExpectationType.self, forKey: .type)

        switch type {
        case .goal:
            let goal = try container.decode(Goal.self, forKey: .data)
            self = .goal(goal)
        case .milestone:
            let milestone = try container.decode(Milestone.self, forKey: .data)
            self = .milestone(milestone)
        case .obligation:
            let obligation = try container.decode(Obligation.self, forKey: .data)
            self = .obligation(obligation)
        case .aspiration:
            let aspiration = try container.decode(Aspiration.self, forKey: .data)
            self = .aspiration(aspiration)
        }
    }

    /// Encode to JSON
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .goal(let goal):
            try container.encode(ExpectationType.goal, forKey: .type)
            try container.encode(goal, forKey: .data)
        case .milestone(let milestone):
            try container.encode(ExpectationType.milestone, forKey: .type)
            try container.encode(milestone, forKey: .data)
        case .obligation(let obligation):
            try container.encode(ExpectationType.obligation, forKey: .type)
            try container.encode(obligation, forKey: .data)
        case .aspiration(let aspiration):
            try container.encode(ExpectationType.aspiration, forKey: .type)
            try container.encode(aspiration, forKey: .data)
        }
    }
}

// MARK: - Computed Properties (Shared Interface)

extension Expectation {
    /// Display title (delegates to associated value)
    public var title: String {
        switch self {
        case .goal(let g): return g.title
        case .milestone(let m): return m.title
        case .obligation(let o): return o.title
        case .aspiration(let a): return a.title
        }
    }

    /// Description text (delegates to associated value)
    public var description: String? {
        switch self {
        case .goal(let g): return g.description
        case .milestone(let m): return m.description
        case .obligation(let o): return o.description
        case .aspiration(let a): return a.description
        }
    }

    /// Priority level (delegates to associated value)
    public var priority: Int {
        switch self {
        case .goal(let g): return g.priority
        case .milestone(let m): return m.priority
        case .obligation(let o): return o.priority
        case .aspiration(let a): return a.priority
        }
    }

    /// Life domain (if applicable)
    public var lifeDomain: String? {
        switch self {
        case .goal(let g): return g.lifeDomain
        case .milestone(let m): return m.lifeDomain
        case .obligation: return nil  // Obligations don't have life domains
        case .aspiration(let a): return a.lifeDomain
        }
    }

    /// Whether this expectation has a deadline/target date
    public var hasDeadline: Bool {
        switch self {
        case .goal: return true
        case .milestone: return true
        case .obligation: return true
        case .aspiration(let a): return a.targetDate != nil
        }
    }

    /// The relevant deadline (if any)
    public var deadline: Date? {
        switch self {
        case .goal(let g): return g.targetDate
        case .milestone(let m): return m.targetDate
        case .obligation(let o): return o.deadline
        case .aspiration(let a): return a.targetDate
        }
    }

    /// Type name for display
    public var typeName: String {
        switch self {
        case .goal: return "Goal"
        case .milestone: return "Milestone"
        case .obligation: return "Obligation"
        case .aspiration: return "Aspiration"
        }
    }
}

// MARK: - Validation

extension Expectation.Goal {
    /// Validate SMART criteria
    public func validate() throws {
        if title.isEmpty {
            throw ValidationError.invalidValue(
                field: "title",
                value: "",
                reason: "Title cannot be empty"
            )
        }
        if measurementUnit.isEmpty {
            throw ValidationError.invalidValue(
                field: "measurementUnit",
                value: "",
                reason: "Unit cannot be empty"
            )
        }
        if measurementTarget <= 0 {
            throw ValidationError.invalidValue(
                field: "measurementTarget",
                value: String(measurementTarget),
                reason: "Target must be positive"
            )
        }
        if startDate >= targetDate {
            throw ValidationError.invalidValue(
                field: "dateRange",
                value: "\(startDate) to \(targetDate)",
                reason: "Start date must be before target date"
            )
        }
        if howRelevant.isEmpty {
            throw ValidationError.missingRequiredField(
                field: "howRelevant",
                context: "SMART goal requires relevance statement"
            )
        }
        if howActionable.isEmpty {
            throw ValidationError.missingRequiredField(
                field: "howActionable",
                context: "SMART goal requires actionability statement"
            )
        }
    }
}

extension Expectation.Milestone {
    /// Validate milestone requirements
    public func validate() throws {
        if title.isEmpty {
            throw ValidationError.invalidValue(
                field: "title",
                value: "",
                reason: "Title cannot be empty"
            )
        }
        // targetDate is required (enforced by type), no validation needed
    }
}

extension Expectation.Obligation {
    /// Validate obligation requirements
    public func validate() throws {
        if title.isEmpty {
            throw ValidationError.invalidValue(
                field: "title",
                value: "",
                reason: "Title cannot be empty"
            )
        }
        // deadline is required (enforced by type), no validation needed
    }
}

// MARK: - Factory Methods

extension Expectation {
    /// Create a SMART goal with validation
    ///
    /// Enforces SMART criteria:
    /// - Specific: requires title
    /// - Measurable: requires unit and target
    /// - Achievable: target must be positive
    /// - Relevant: requires relevance statement
    /// - Time-bound: requires start/target dates with valid range
    ///
    /// Example:
    /// ```swift
    /// let goal = try Expectation.goal(
    ///     title: "Run 120km in 10 weeks",
    ///     measurementUnit: "km",
    ///     measurementTarget: 120,
    ///     startDate: Date(),
    ///     targetDate: Date().addingTimeInterval(60*60*24*70),
    ///     howRelevant: "Improve cardiovascular health",
    ///     howActionable: "Run 3x per week, track with Strava"
    /// )
    /// ```
    public static func goal(
        title: String,
        description: String? = nil,
        measurementUnit: String,
        measurementTarget: Double,
        startDate: Date,
        targetDate: Date,
        howRelevant: String,
        howActionable: String,
        expectedTermLength: Int? = nil,
        priority: Int = 80,
        lifeDomain: String? = nil
    ) throws -> Expectation {
        let goal = Goal(
            title: title,
            description: description,
            measurementUnit: measurementUnit,
            measurementTarget: measurementTarget,
            startDate: startDate,
            targetDate: targetDate,
            howRelevant: howRelevant,
            howActionable: howActionable,
            expectedTermLength: expectedTermLength,
            priority: priority,
            lifeDomain: lifeDomain
        )

        try goal.validate()
        return .goal(goal)
    }

    /// Create a milestone checkpoint
    ///
    /// Milestones mark specific points in time, not date ranges.
    ///
    /// Example:
    /// ```swift
    /// let milestone = Expectation.milestone(
    ///     title: "Hit 50km by week 5",
    ///     targetDate: fiveWeeksFromNow,
    ///     measurementTarget: 50,
    ///     measurementUnit: "km"
    /// )
    /// ```
    public static func milestone(
        title: String,
        description: String? = nil,
        targetDate: Date,
        measurementTarget: Double? = nil,
        measurementUnit: String? = nil,
        priority: Int = 30,
        lifeDomain: String? = nil
    ) throws -> Expectation {
        let milestone = Milestone(
            title: title,
            description: description,
            targetDate: targetDate,
            measurementTarget: measurementTarget,
            measurementUnit: measurementUnit,
            priority: priority,
            lifeDomain: lifeDomain
        )

        try milestone.validate()
        return .milestone(milestone)
    }

    /// Create an external obligation
    ///
    /// Use for commitments requested by others.
    ///
    /// Example:
    /// ```swift
    /// let obligation = Expectation.obligation(
    ///     title: "Submit quarterly report",
    ///     deadline: friday,
    ///     requestedBy: "Board of Directors",
    ///     consequence: "Delayed approval for next quarter"
    /// )
    /// ```
    public static func obligation(
        title: String,
        description: String? = nil,
        deadline: Date,
        requestedBy: String? = nil,
        consequence: String? = nil,
        priority: Int = 90
    ) throws -> Expectation {
        let obligation = Obligation(
            title: title,
            description: description,
            deadline: deadline,
            requestedBy: requestedBy,
            consequence: consequence,
            priority: priority
        )

        try obligation.validate()
        return .obligation(obligation)
    }

    /// Create an aspiration
    ///
    /// Aspirations are open-ended desires without strict requirements.
    ///
    /// Example:
    /// ```swift
    /// let aspiration = Expectation.aspiration(
    ///     title: "Write a book someday",
    ///     lifeDomain: "Career",
    ///     priority: 40
    /// )
    /// ```
    public static func aspiration(
        title: String,
        description: String? = nil,
        lifeDomain: String? = nil,
        priority: Int = 50,
        targetDate: Date? = nil
    ) -> Expectation {
        let aspiration = Aspiration(
            title: title,
            description: description,
            lifeDomain: lifeDomain,
            priority: priority,
            targetDate: targetDate
        )

        // Aspirations have minimal requirements, no validation needed
        return .aspiration(aspiration)
    }
}

// MARK: - Query Helpers

extension Expectation {
    /// Fetch all expectations of a specific type
    ///
    /// Example:
    /// ```swift
    /// let goals = try await db.fetchGoals()
    /// let obligations = try await db.fetchObligations()
    /// ```
    public static func fetchByType(type: String) async throws -> [Expectation] {
        // GRDB query pattern (to be implemented)
        // Note: Requires decoding all Expectations and filtering by case
        fatalError("fetchByType not yet implemented for GRDB")
    }

    /// Fetch expectations with upcoming deadlines
    public static func fetchUpcoming(before: Date) async throws -> [Expectation] {
        // GRDB query pattern (to be implemented)
        // Note: This requires querying JSON, which is less efficient
        // Could be optimized with generated columns if needed
        fatalError("fetchUpcoming not yet implemented for GRDB")
    }
}

