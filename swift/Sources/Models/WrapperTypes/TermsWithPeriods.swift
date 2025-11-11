//
// TermsWithPeriods.swift
// Created on 2025-11-10
//
// PURPOSE: FetchKeyRequest for querying GoalTerms with their TimePeriods
// PATTERN: Matches TimePeriodRepository.swift:125-138 (FetchAllTermsRequest)
// ARCHITECTURE: Part of Models/WrapperTypes (public API for @Fetch usage)
//

import Foundation
import SQLiteData

/// FetchKeyRequest for querying all terms with their time periods
///
/// This query performs a simple 1:1 JOIN between GoalTerms and TimePeriods,
/// returning results ordered by term number descending (most recent first).
///
/// **Usage in Views**:
/// ```swift
/// @Fetch(wrappedValue: [], TermsWithPeriods())
/// private var termsWithPeriods: [TermWithPeriod]
/// ```
///
/// **Pattern**: Simple JOIN with query builder (no complex SQL needed)
/// **Performance**: Single query, O(n) for n terms
/// **Type Safety**: Compile-time checking via query builder
public struct TermsWithPeriods: FetchKeyRequest {
    public typealias Value = [TermWithPeriod]

    public init() {}

    public func fetch(_ db: Database) throws -> [TermWithPeriod] {
        // Perform JOIN query (single database round-trip)
        let results = try GoalTerm.all
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        // Map tuples to wrapper type
        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}

// MARK: - Implementation Notes
//
// PATTERN MATCH: This implementation matches TimePeriodRepository.FetchAllTermsRequest
// exactly (lines 125-138 in TimePeriodRepository.swift). The only difference is:
// - Repository uses private struct inside Repository class
// - This is public struct in Models/WrapperTypes for @Fetch usage
//
// WHY QUERY BUILDER?
// - Simple 1:1 relationship (GoalTerm → TimePeriod)
// - Type-safe column references
// - No complex SQL needed
// - Proven pattern from production
//
// SWIFT 6 CONCURRENCY:
// - FetchKeyRequest is Sendable by default
// - Results (TermWithPeriod) are Sendable
// - Safe to use from @MainActor views with @Fetch
