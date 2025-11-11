//
// TermWithPeriod.swift
// Moved from Views/Queries on 2025-11-10
//
// PURPOSE: Wrapper type combining GoalTerm + TimePeriod
// ARCHITECTURE: Part of Models layer (NOT Views layer)
// USAGE: Returned by TimePeriodRepository, passed to TermRowView
//

import Foundation

/// Combined GoalTerm + TimePeriod for efficient display
///
/// Fetched via single JOIN query in TimePeriodRepository.
/// Passed to TermRowView to avoid N+1 queries in list display.
public struct TermWithPeriod: Identifiable, Hashable, Sendable {
    public let term: GoalTerm
    public let timePeriod: TimePeriod

    public var id: UUID { term.id }

    public init(term: GoalTerm, timePeriod: TimePeriod) {
        self.term = term
        self.timePeriod = timePeriod
    }
}