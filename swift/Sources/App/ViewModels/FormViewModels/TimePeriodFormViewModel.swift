//
// TimePeriodFormViewModel.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: Generic ViewModel for TimePeriod creation (works with all specializations)
// ARCHITECTURE: Generic ViewModel, type-specific views provide specialization
//

import Dependencies
import Foundation
import Models
import Observation
import SQLiteData
import Services
import SwiftUI

/// Generic ViewModel for TimePeriod form operations.
///
/// ARCHITECTURE DECISION: Generic ViewModel + Type-Specific Views
/// - This ViewModel works with ANY TimePeriodSpecialization
/// - Type-specific views (TermFormView, YearFormView) wrap this with pre-configured type
/// - Keeps ViewModel simple, views handle user-friendly specialization
///
/// PATTERN: Based on PersonalValuesFormViewModel
/// - @Observable (not ObservableObject)
/// - @Dependency(\.defaultDatabase) with @ObservationIgnored
/// - Individual parameters (not FormData object) for ergonomic SwiftUI binding
@Observable
@MainActor
public final class TimePeriodFormViewModel {
    public var isSaving: Bool = false
    public var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    private var coordinator: TimePeriodCoordinator {
        TimePeriodCoordinator(database: database)
    }

    public init() {}

    /// Saves TimePeriod with specialization.
    /// - Parameters: Individual form fields (more ergonomic than FormData object)
    /// - Returns: Persisted TimePeriod
    /// - Throws: Database errors
    public func save(
        startDate: Date,
        targetDate: Date,
        specialization: TimePeriodSpecialization,
        title: String? = nil,
        description: String? = nil,
        notes: String? = nil
    ) async throws -> TimePeriod {
        isSaving = true
        defer { isSaving = false }

        let formData = TimePeriodFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            startDate: startDate,
            targetDate: targetDate,
            specialization: specialization
        )

        do {
            let timePeriod = try await coordinator.create(from: formData)
            errorMessage = nil
            return timePeriod
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // TODO: Phase 4 - Add Update and Delete
}
