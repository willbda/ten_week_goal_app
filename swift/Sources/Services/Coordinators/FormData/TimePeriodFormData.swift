//
// TimePeriodFormData.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Form data structure for creating TimePeriod entities with specializations
//

import Foundation
import Models

/// Specialization types for TimePeriod (ontologically pure)
public enum TimePeriodSpecialization: Sendable {
    case term(number: Int)
    case year(yearNumber: Int)
    case custom
    // Future: case quarter(number: Int), case sprint(number: Int)
}

/// Form data for creating/updating TimePeriod with appropriate specialization
public struct TimePeriodFormData: Sendable {
    // TimePeriod fields
    public let title: String?
    public let detailedDescription: String?
    public let freeformNotes: String?
    public let startDate: Date
    public let targetDate: Date
    public let specialization: TimePeriodSpecialization

    // GoalTerm-specific fields (used when specialization = .term)
    public let theme: String?
    public let reflection: String?
    public let status: TermStatus?

    public init(
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        startDate: Date,
        targetDate: Date,
        specialization: TimePeriodSpecialization,
        theme: String? = nil,
        reflection: String? = nil,
        status: TermStatus? = nil
    ) {
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.startDate = startDate
        self.targetDate = targetDate
        self.specialization = specialization
        self.theme = theme
        self.reflection = reflection
        self.status = status
    }
}
