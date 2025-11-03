//
// ActionFormViewModel.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: ViewModel for Action forms (create + edit)
// PATTERN: @Observable with @Dependency, following TimePeriodFormViewModel
//

import Dependencies
import Foundation
import Models
import Observation
import Services
import SQLiteData

/// ViewModel for Action forms
///
/// **Pattern**: @Observable (not ObservableObject)
/// **Dependencies**: @Dependency(\.defaultDatabase) with @ObservationIgnored
/// **Responsibilities**:
/// - Load available Measures and Goals from database
/// - save() creates new Action + MeasuredAction[] + ActionGoalContribution[]
/// - update() updates existing Action + relationships
/// - delete() removes Action + cascading relationships
///
/// **Usage in View**:
/// ```swift
/// @State private var viewModel = ActionFormViewModel()
///
/// var body: some View {
///     ForEach(viewModel.availableMeasures) { measure in
///         // Measure picker
///     }
///
///     Button("Save") {
///         try await viewModel.save(...)
///     }
/// }
/// ```
@Observable
@MainActor
public final class ActionFormViewModel {
    // MARK: - Published State

    public var isSaving: Bool = false
    public var errorMessage: String?
    public var availableMeasures: [Measure] = []
    public var availableGoals: [(Goal, String)] = []  // (Goal, title from Expectation)

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    private var coordinator: ActionCoordinator {
        ActionCoordinator(database: database)
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Loading Data

    /// Loads available Measures and Goals from database
    ///
    /// Call this in .task or .onAppear modifier:
    /// ```swift
    /// .task {
    ///     await viewModel.loadOptions()
    /// }
    /// ```
    public func loadOptions() async {
        do {
            // Read from database (captures local variables, not self)
            let (measures, goals) = try await database.read { db in
                // Simple fetch - query builder is fine
                let measures = try Measure.all
                    .order { $0.unit.asc() }
                    .fetchAll(db)

                // TODO: Load goals with their expectation titles
                // CURRENT: Simplified version - just loading goals (shows goal.id as fallback)
                // NEEDED: JOIN with Expectation to get titles
                //
                // **Option A: Query Builder** (type-safe, good for development)
                // let goalsWithTitles = try Goal.all
                //     .join(Expectation.all) { $0.expectationId.eq($1.id) }
                //     .select { (goal, expectation) in
                //         (goal, expectation.title ?? "Untitled Goal")
                //     }
                //     .fetchAll(db)
                //
                // **Option B: #sql** (slightly cleaner with COALESCE)
                // struct GoalWithTitle: Decodable {
                //     let goal: Goal
                //     let title: String
                // }
                // let goalsWithTitles = try #sql(
                //     """
                //     SELECT g.*, COALESCE(e.title, 'Untitled Goal') as title
                //     FROM goals g
                //     JOIN expectations e ON g.expectationId = e.id
                //     ORDER BY e.title ASC
                //     """
                // ).fetchAll(db) as [GoalWithTitle]
                //
                // **Decision**: Either works. Query builder is safer during dev.
                // #sql would be better if we add more goal filtering (status, date range).
                //
                let goals = try Goal.all.fetchAll(db)

                return (measures, goals)
            }

            // Assign to @MainActor properties outside closure
            self.availableMeasures = measures
            self.availableGoals = goals.map { goal in
                // TODO: JOIN with Expectation to get title
                // For now, use placeholder
                (goal, "Goal \(goal.id.uuidString.prefix(8))")
            }
        } catch {
            self.errorMessage = "Failed to load options: \(error.localizedDescription)"
        }
    }

    // MARK: - Save (Create)

    /// Creates new Action with measurements and goal contributions
    ///
    /// - Parameters:
    ///   - title: Action title (required)
    ///   - description: Detailed description (optional)
    ///   - notes: Freeform notes (optional)
    ///   - durationMinutes: Duration in minutes (0 = not tracked)
    ///   - startTime: When the action occurred
    ///   - measurements: Array of (measureId, value) tuples
    ///   - goalContributions: Set of goal IDs this action contributes to
    /// - Returns: Created Action
    /// - Throws: CoordinatorError if validation fails or database error occurs
    ///
    /// 🔧 REFINEMENT NEEDED (2025-11-03):
    /// This method takes 7 parameters - should take FormData instead:
    /// ```
    /// public func save(formData: ActionFormData) async throws -> Action
    /// ```
    /// View should call buildFormData() helper before passing here.
    /// Pattern to follow: PersonalValueFormViewModel (when updated)
    public func save(
        title: String,
        description: String = "",
        notes: String = "",
        durationMinutes: Double = 0,
        startTime: Date,
        measurements: [(UUID, Double)],  // (measureId, value)
        goalContributions: Set<UUID> = []
    ) async throws -> Action {
        isSaving = true
        defer { isSaving = false }

        // Convert measurements to MeasurementInput
        let measurementInputs = measurements.map { (measureId, value) in
            MeasurementInput(measureId: measureId, value: value)
        }

        let formData = ActionFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            durationMinutes: durationMinutes,
            startTime: startTime,
            measurements: measurementInputs,
            goalContributions: goalContributions
        )

        do {
            let action = try await coordinator.create(from: formData)
            errorMessage = nil
            return action
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Update

    /// Updates existing Action with measurements and goal contributions
    ///
    /// - Parameters:
    ///   - actionDetails: Existing ActionWithDetails (from ActionsQuery)
    ///   - title: Updated title
    ///   - description: Updated description
    ///   - notes: Updated notes
    ///   - durationMinutes: Updated duration
    ///   - startTime: Updated start time
    ///   - measurements: Updated measurements (replaces all)
    ///   - goalContributions: Updated goal contributions (replaces all)
    /// - Returns: Updated Action
    /// - Throws: CoordinatorError or database errors
    ///
    /// 🔧 REFINEMENT NEEDED (2025-11-03):
    /// This method takes 8 parameters - should take FormData instead:
    /// ```
    /// public func update(actionDetails: ActionWithDetails, formData: ActionFormData) async throws -> Action
    /// ```
    /// View should call buildFormData() helper before passing here.
    /// Pattern to follow: PersonalValueFormViewModel (when updated)
    public func update(
        actionDetails: ActionWithDetails,
        title: String,
        description: String = "",
        notes: String = "",
        durationMinutes: Double = 0,
        startTime: Date,
        measurements: [(UUID, Double)],
        goalContributions: Set<UUID> = []
    ) async throws -> Action {
        isSaving = true
        defer { isSaving = false }

        // Convert measurements to MeasurementInput
        let measurementInputs = measurements.map { (measureId, value) in
            MeasurementInput(measureId: measureId, value: value)
        }

        let formData = ActionFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            durationMinutes: durationMinutes,
            startTime: startTime,
            measurements: measurementInputs,
            goalContributions: goalContributions
        )

        do {
            // Extract existing relationships from actionDetails
            let existingMeasurements = actionDetails.measurements.map { $0.measuredAction }
            let existingContributions = actionDetails.contributions.map { $0.contribution }

            let action = try await coordinator.update(
                action: actionDetails.action,
                measurements: existingMeasurements,
                contributions: existingContributions,
                from: formData
            )
            errorMessage = nil
            return action
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Delete

    /// Deletes Action and its relationships
    ///
    /// - Parameter actionDetails: ActionWithDetails to delete
    /// - Throws: Database errors
    public func delete(
        actionDetails: ActionWithDetails
    ) async throws {
        isSaving = true
        defer { isSaving = false }

        do {
            let existingMeasurements = actionDetails.measurements.map { $0.measuredAction }
            let existingContributions = actionDetails.contributions.map { $0.contribution }

            try await coordinator.delete(
                action: actionDetails.action,
                measurements: existingMeasurements,
                contributions: existingContributions
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
