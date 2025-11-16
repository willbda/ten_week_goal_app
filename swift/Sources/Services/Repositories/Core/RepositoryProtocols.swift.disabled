//
// RepositoryProtocols.swift
// Written by Claude Code on 2025-11-15
//
// PURPOSE:
// Core protocol hierarchy for repository abstraction layer.
// Defines common interfaces for all repositories while allowing flexibility
// in implementation patterns (JSON aggregation, #sql macros, query builders).
//
// DESIGN:
// - Repository: Base protocol with essential operations
// - Capability protocols: Add specific behaviors (title checks, date filtering)
// - Strategy protocols: Define query pattern contracts
//

import Foundation
import Models
import SQLiteData

// MARK: - Base Repository Protocol

/// Base repository protocol that all repositories must conform to
///
/// PATTERN: Protocol-based design allows flexibility while enforcing consistency.
/// Each repository must provide Entity and ExportType but can choose query strategy.
public protocol Repository: Sendable {
    /// The primary entity type this repository manages
    associatedtype Entity

    /// The export format for CSV/JSON serialization
    associatedtype ExportType: Codable, Sendable

    /// Database writer instance (injected dependency)
    var database: any DatabaseWriter { get }

    // MARK: - Core Operations (Required)

    /// Fetch all entities from the database
    func fetchAll() async throws -> [Entity]

    /// Check if an entity exists by ID
    func exists(_ id: UUID) async throws -> Bool

    // MARK: - Export Operations (Required)

    /// Fetch entities in denormalized export format
    /// - Parameters:
    ///   - from: Optional start date for filtering
    ///   - to: Optional end date for filtering
    /// - Returns: Array of export-ready entities
    func fetchForExport(from: Date?, to: Date?) async throws -> [ExportType]

    // MARK: - Error Mapping (Required)

    /// Map database errors to user-friendly validation errors
    /// - Parameter error: The database error to map
    /// - Returns: A ValidationError with appropriate user message
    func mapDatabaseError(_ error: Error) -> ValidationError
}

// MARK: - Capability Protocols

/// Repository that supports title-based existence checks
///
/// USAGE: PersonalValueRepository, GoalRepository (via Expectation title)
public protocol TitleBasedRepository: Repository {
    /// Check if an entity with this title already exists (case-insensitive)
    /// - Parameter title: The title to check
    /// - Returns: true if an entity with this title exists
    func existsByTitle(_ title: String) async throws -> Bool
}

/// Repository that supports date range filtering
///
/// USAGE: ActionRepository, GoalRepository, TimePeriodRepository
public protocol DateFilterableRepository: Repository {
    /// Fetch entities within a date range
    /// - Parameter range: The date range to filter by
    /// - Returns: Entities that fall within the date range
    func fetchByDateRange(_ range: ClosedRange<Date>) async throws -> [Entity]
}

/// Repository that supports fetching entities by related entity
///
/// USAGE: Multiple relationships across repositories
public protocol RelationshipRepository: Repository {
    /// The type of the related entity
    associatedtype RelatedEntity

    /// Fetch entities related to a specific entity ID
    /// - Parameter id: The ID of the related entity
    /// - Returns: Entities related to the given ID
    func fetchByRelated(_ id: UUID) async throws -> [Entity]
}

// MARK: - Advanced Capability Protocols

/// Repository that manages many-to-many relationships via junction tables
///
/// USAGE: GoalRepository (goals ↔ values), ActionRepository (actions ↔ goals)
public protocol ManyToManyRepository: Repository {
    /// The junction table entity type
    associatedtype JunctionEntity

    /// The entity on the other side of the relationship
    associatedtype RelatedEntity

    /// Fetch related entities for a given entity ID
    /// - Parameter entityId: The source entity ID
    /// - Returns: Array of related entities
    func fetchRelated(for entityId: UUID) async throws -> [RelatedEntity]

    /// Create a relationship between two entities
    /// - Parameters:
    ///   - from: Source entity ID
    ///   - to: Target entity ID
    func addRelationship(from: UUID, to: UUID) async throws

    /// Remove a relationship between two entities
    /// - Parameters:
    ///   - from: Source entity ID
    ///   - to: Target entity ID
    func removeRelationship(from: UUID, to: UUID) async throws
}

/// Repository that supports aggregation queries (counts, sums, etc.)
///
/// USAGE: ActionRepository (totalByMeasure, countByGoal)
public protocol AggregationRepository: Repository {
    /// Aggregation result type (e.g., Double for sums, Int for counts)
    associatedtype AggregationResult

    /// Perform an aggregation query
    /// - Parameters:
    ///   - type: The type of aggregation (sum, count, avg, etc.)
    ///   - field: The field to aggregate
    ///   - filter: Optional filter conditions
    /// - Returns: The aggregation result
    func aggregate(
        _ type: AggregationType,
        field: String,
        filter: AggregationFilter?
    ) async throws -> AggregationResult
}

// MARK: - Supporting Types

/// Types of aggregation operations
public enum AggregationType {
    case sum
    case count
    case average
    case minimum
    case maximum
}

/// Filter conditions for aggregation queries
public struct AggregationFilter {
    public let field: String
    public let value: any DatabaseValueConvertible
    public let comparison: ComparisonOperator

    public enum ComparisonOperator {
        case equal
        case notEqual
        case greaterThan
        case greaterThanOrEqual
        case lessThan
        case lessThanOrEqual
        case between(lower: any DatabaseValueConvertible, upper: any DatabaseValueConvertible)
    }

    public init(field: String, value: any DatabaseValueConvertible, comparison: ComparisonOperator) {
        self.field = field
        self.value = value
        self.comparison = comparison
    }
}

// MARK: - Protocol Extensions

/// Default implementations for common repository operations
public extension Repository {
    /// Check if any entities exist
    func isEmpty() async throws -> Bool {
        let all = try await fetchAll()
        return all.isEmpty
    }

    /// Count total entities
    func count() async throws -> Int {
        let all = try await fetchAll()
        return all.count
    }
}

/// Default implementations for title-based repositories
public extension TitleBasedRepository {
    /// Check if a title is available (not taken)
    func isTitleAvailable(_ title: String) async throws -> Bool {
        let exists = try await existsByTitle(title)
        return !exists
    }
}

/// Default implementations for date filterable repositories
public extension DateFilterableRepository {
    /// Fetch entities from the last N days
    func fetchRecent(days: Int) async throws -> [Entity] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        return try await fetchByDateRange(startDate...endDate)
    }

    /// Fetch entities from a specific month
    func fetchByMonth(year: Int, month: Int) async throws -> [Entity] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startDate = Calendar.current.date(from: components),
              let endDate = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return []
        }

        return try await fetchByDateRange(startDate...endDate)
    }
}