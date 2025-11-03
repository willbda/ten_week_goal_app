//
// TermsQuery.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Custom query that JOINs GoalTerm + TimePeriod for efficient list display
// PATTERN: Based on SQLiteData's Reminders app Schema.swift JOIN examples
//

import Foundation
import Models
import SQLiteData

/// Combined GoalTerm + TimePeriod for list display
public struct TermWithPeriod: Identifiable, Sendable {
    public let term: GoalTerm
    public let timePeriod: TimePeriod

    public var id: UUID { term.id }

    public init(term: GoalTerm, timePeriod: TimePeriod) {
        self.term = term
        self.timePeriod = timePeriod
    }
}

/// Query that fetches GoalTerms with their related TimePeriods
///
/// **Architecture**: Single JOIN query instead of N+1 fetches
/// - Fetches GoalTerm + TimePeriod in one query
/// - Orders by termNumber descending (most recent first)
/// - Observable via @Fetch - updates automatically on database changes
///
/// **Usage**:
/// ```swift
/// @Fetch(TermsWithPeriods())
/// private var termsWithPeriods: [TermWithPeriod]
/// ```
public struct TermsWithPeriods: FetchKeyRequest {
    public typealias Value = [TermWithPeriod]

    public init() {}

    public func fetch(_ db: Database) throws -> [TermWithPeriod] {
        // Single JOIN query (not N+1)
        // Pattern from audit: SQLiteData returns [(GoalTerm, TimePeriod)] from join
        let results = try GoalTerm.all
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        // Map tuple results to our wrapper type
        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}

// MARK: - JOIN Helper Extension
//
// SQLiteData doesn't have BelongsTo/HasMany like GRDB
// Instead, use manual JOIN queries as shown in fetch() above
//
// Pattern from Reminders app:
//   - Define static computed properties that return JOIN queries
//   - Use .join() with column equality checks
//   - See Reminder.withTags in sqlite-data-main/Examples/Reminders/Schema.swift:73-76
