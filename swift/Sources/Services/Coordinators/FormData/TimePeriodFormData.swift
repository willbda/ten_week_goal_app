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

/// Form data for creating TimePeriod with appropriate specialization
public struct TimePeriodFormData: Sendable {
    public let title: String?
    public let detailedDescription: String?
    public let freeformNotes: String?
    public let startDate: Date
    public let targetDate: Date
    public let specialization: TimePeriodSpecialization

    public init(
        title: String? = nil,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        startDate: Date,
        targetDate: Date,
        specialization: TimePeriodSpecialization
    ) {
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.startDate = startDate
        self.targetDate = targetDate
        self.specialization = specialization
    }
}
