//
// GoalFormViewModel.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: @Observable ViewModel for Goal forms
// PATTERN: Like ActionFormViewModel, PersonalValuesFormViewModel
// METHODS: save(), update(), delete()
// USAGE: Used by GoalFormView, assembles GoalFormData, calls GoalCoordinator
//

import Dependencies
import Foundation
import Models
import Services
import SQLiteData

/// ViewModel for goal creation and editing
///
/// PATTERN: @Observable (not ObservableObject)
/// DEPENDENCY: Uses @Dependency(\.defaultDatabase) + @ObservationIgnored
/// COORDINATOR: Creates GoalCoordinator on demand
@Observable
@MainActor
public final class GoalFormViewModel {
    public var isSaving: Bool = false
    public var errorMessage: String?

    // Duplicate detection state (v0.7.5)
    public var showDuplicateWarning: Bool = false
    public var duplicateSimilarGoal: String?
    public var duplicateSimilarityPercent: Int?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    // ARCHITECTURE DECISION: Lazy stored property with @ObservationIgnored
    // CONTEXT: Swift 6 strict concurrency - coordinators are now non-isolated
    // PATTERN: Use lazy var with @ObservationIgnored for multi-method coordinator usage
    // WHY LAZY: Coordinator used in multiple methods (save, update, delete)
    // WHY @ObservationIgnored: Coordinators are stateless services, no observable state
    // RESULT: Coordinator created once on first use, safe across all async methods
    @ObservationIgnored
    private lazy var coordinator: GoalCoordinator = {
        GoalCoordinator(database: database)
    }()

    public init() {}

    /// Creates a new goal with full relationship graph
    /// - Parameters: Individual form fields
    /// - Returns: Created Goal
    /// - Throws: CoordinatorError if validation fails
    public func save(
        // Expectation fields
        title: String,
        detailedDescription: String,
        freeformNotes: String,
        expectationImportance: Int,
        expectationUrgency: Int,
        // Goal fields
        startDate: Date?,
        targetDate: Date?,
        actionPlan: String?,
        expectedTermLength: Int?,
        // Relationships
        metricTargets: [MetricTargetInput],
        valueAlignments: [ValueAlignmentInput],
        termId: UUID?
    ) async throws -> Goal {
        isSaving = true
        defer { isSaving = false }

        // Assemble form data
        let formData = GoalFormData(
            title: title,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            expectationImportance: expectationImportance,
            expectationUrgency: expectationUrgency,
            startDate: startDate,
            targetDate: targetDate,
            actionPlan: actionPlan,
            expectedTermLength: expectedTermLength,
            metricTargets: metricTargets,
            valueAlignments: valueAlignments,
            termId: termId
        )

        do {
            let goal = try await coordinator.create(from: formData)
            // Success - clear any previous errors/warnings
            errorMessage = nil
            showDuplicateWarning = false
            duplicateSimilarGoal = nil
            duplicateSimilarityPercent = nil
            return goal
        } catch let validationError as ValidationError {
            // Handle specific validation errors
            switch validationError {
            case .duplicateGoal(let title, let similarTo, let similarity):
                // Show duplicate-specific UI
                errorMessage = validationError.userMessage
                showDuplicateWarning = true
                duplicateSimilarGoal = similarTo
                duplicateSimilarityPercent = Int(similarity * 100)
            default:
                // Other validation errors
                errorMessage = validationError.userMessage
                showDuplicateWarning = false
            }
            throw validationError
        } catch {
            // Generic errors
            errorMessage = error.localizedDescription
            showDuplicateWarning = false
            throw error
        }
    }

    /// Updates an existing goal with new form data
    /// - Parameters: Existing goal data + new form fields
    /// - Returns: Updated Goal
    /// - Throws: CoordinatorError if validation fails
    public func update(
        // Existing data
        goalDetails: GoalWithDetails,
        // New form fields
        title: String,
        detailedDescription: String,
        freeformNotes: String,
        expectationImportance: Int,
        expectationUrgency: Int,
        startDate: Date?,
        targetDate: Date?,
        actionPlan: String?,
        expectedTermLength: Int?,
        metricTargets: [MetricTargetInput],
        valueAlignments: [ValueAlignmentInput],
        termId: UUID?
    ) async throws -> Goal {
        isSaving = true
        defer { isSaving = false }

        // Assemble form data
        let formData = GoalFormData(
            title: title,
            detailedDescription: detailedDescription,
            freeformNotes: freeformNotes,
            expectationImportance: expectationImportance,
            expectationUrgency: expectationUrgency,
            startDate: startDate,
            targetDate: targetDate,
            actionPlan: actionPlan,
            expectedTermLength: expectedTermLength,
            metricTargets: metricTargets,
            valueAlignments: valueAlignments,
            termId: termId
        )

        // Extract existing relationships for coordinator
        let existingTargets = goalDetails.metricTargets.map { $0.expectationMeasure }
        let existingAlignments = goalDetails.valueAlignments.map { $0.goalRelevance }

        do {
            let updatedGoal = try await coordinator.update(
                goal: goalDetails.goal,
                expectation: goalDetails.expectation,
                existingTargets: existingTargets,
                existingAlignments: existingAlignments,
                existingAssignment: goalDetails.termAssignment,
                from: formData
            )
            errorMessage = nil
            return updatedGoal
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Deletes a goal and all its relationships
    /// - Parameter goalDetails: Goal with all relationships to delete
    /// - Throws: CoordinatorError if deletion fails
    public func delete(goalDetails: GoalWithDetails) async throws {
        isSaving = true
        defer { isSaving = false }

        // Extract relationships for coordinator
        let targets = goalDetails.metricTargets.map { $0.expectationMeasure }
        let alignments = goalDetails.valueAlignments.map { $0.goalRelevance }

        do {
            try await coordinator.delete(
                goal: goalDetails.goal,
                expectation: goalDetails.expectation,
                targets: targets,
                alignments: alignments,
                assignment: goalDetails.termAssignment
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
