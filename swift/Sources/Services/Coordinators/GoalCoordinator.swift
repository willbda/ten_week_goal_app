//
// GoalCoordinator.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Coordinates creation of Goal entities with full relationship graph
// ARCHITECTURE: Most complex coordinator - 5+ models atomically
// MODELS: Expectation + Goal + ExpectationMeasure[] + GoalRelevance[] + TermGoalAssignment?
//

import Foundation
import Models
import SQLiteData

/// Coordinates creation of Goal entities with atomic persistence.
///
/// ARCHITECTURE DECISION: Five-model atomic transaction
/// - Creates Expectation (base) + Goal (subtype) atomically
/// - Creates ExpectationMeasure[] records for each metric target
/// - Creates GoalRelevance[] records for each value alignment
/// - Optionally creates TermGoalAssignment if term specified
///
/// Validation Strategy:
/// - NO business logic validation (trusts caller)
/// - Database enforces: NOT NULL, foreign keys, CHECK constraints
/// - Relationship existence checked: Measures, Values, Terms must exist
/// - SMART validation deferred to Phase 2 validators
///
/// PATTERN: Multi-model coordinator (most complex in app)
/// Simpler than: None (this is the most complex)
/// More complex than: ActionCoordinator (3 models), TimePeriodCoordinator (2 models)
@MainActor
public final class GoalCoordinator: ObservableObject {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    /// Creates Goal with full relationship graph from form data.
    /// - Parameter formData: Validated form data with targets and alignments
    /// - Returns: Persisted Goal with generated ID
    /// - Throws: Database errors if constraints violated or referenced entities don't exist
    ///
    /// IMPLEMENTATION:
    /// 1. Validate measureIds exist in Measures table
    /// 2. Validate valueIds exist in PersonalValue table
    /// 3. Validate termId exists in GoalTerm table (if provided)
    /// 4. Insert Expectation (base entity, .goal type)
    /// 5. Insert Goal (subtype, FK to Expectation)
    /// 6. Insert ExpectationMeasure[] for each valid metric target
    /// 7. Insert GoalRelevance[] for each valid value alignment
    /// 8. Insert TermGoalAssignment if termId provided
    /// 9. Return Goal (caller accesses relationships via GoalsQuery)
    public func create(from formData: GoalFormData) async throws -> Goal {
        return try await database.write { db in
            // 1. Validate measureIds exist (if any targets provided)
            for target in formData.metricTargets where target.measureId != nil {
                let measureExists = try Measure.find(target.measureId!).fetchOne(db) != nil
                guard measureExists else {
                    throw CoordinatorError.measureNotFound(target.measureId!)
                }
            }

            // 2. Validate valueIds exist (if any alignments provided)
            for alignment in formData.valueAlignments where alignment.valueId != nil {
                let valueExists = try PersonalValue.find(alignment.valueId!).fetchOne(db) != nil
                guard valueExists else {
                    throw CoordinatorError.valueNotFound(alignment.valueId!)
                }
            }

            // 3. Validate termId exists (if provided)
            if let termId = formData.termId {
                let termExists = try GoalTerm.find(termId).fetchOne(db) != nil
                guard termExists else {
                    throw CoordinatorError.termNotFound(termId)
                }
            }

            // 4. Insert Expectation (base entity with .goal type)
            let expectation = try Expectation.insert {
                Expectation.Draft(
                    id: UUID(),
                    logTime: Date(),
                    title: formData.title.isEmpty ? nil : formData.title,
                    detailedDescription: formData.detailedDescription.isEmpty ? nil : formData.detailedDescription,
                    freeformNotes: formData.freeformNotes.isEmpty ? nil : formData.freeformNotes,
                    expectationType: .goal,
                    expectationImportance: formData.expectationImportance,
                    expectationUrgency: formData.expectationUrgency
                )
            }
            .returning { $0 }
            .fetchOne(db)!  // Safe: successful insert always returns value

            // 5. Insert Goal (subtype with FK to Expectation)
            let goal = try Goal.insert {
                Goal.Draft(
                    id: UUID(),
                    expectationId: expectation.id,
                    startDate: formData.startDate,
                    targetDate: formData.targetDate,
                    actionPlan: formData.actionPlan?.isEmpty == true ? nil : formData.actionPlan,
                    expectedTermLength: formData.expectedTermLength
                )
            }
            .returning { $0 }
            .fetchOne(db)!

            // 6. Insert ExpectationMeasure records for each valid metric target
            for target in formData.metricTargets where target.isValid {
                try ExpectationMeasure.insert {
                    ExpectationMeasure.Draft(
                        id: UUID(),
                        freeformNotes: target.notes?.isEmpty == true ? nil : target.notes,
                        expectationId: expectation.id,
                        measureId: target.measureId!,  // Already validated above
                        targetValue: target.targetValue,
                        createdAt: Date()
                    )
                }
                .execute(db)
            }

            // 7. Insert GoalRelevance records for each valid value alignment
            for alignment in formData.valueAlignments where alignment.isValid {
                try GoalRelevance.insert {
                    GoalRelevance.Draft(
                        id: UUID(),
                        goalId: goal.id,
                        valueId: alignment.valueId!,  // Already validated above
                        alignmentStrength: alignment.alignmentStrength,
                        relevanceNotes: alignment.relevanceNotes?.isEmpty == true ? nil : alignment.relevanceNotes,
                        createdAt: Date()
                    )
                }
                .execute(db)
            }

            // 8. Insert TermGoalAssignment if termId provided
            if let termId = formData.termId {
                try TermGoalAssignment.insert {
                    TermGoalAssignment.Draft(
                        id: UUID(),
                        termId: termId,
                        goalId: goal.id,
                        assignmentOrder: nil,  // Can be set later via term management
                        createdAt: Date()
                    )
                }
                .execute(db)
            }

            // 9. Return Goal (caller accesses full data via GoalsQuery)
            return goal
        }
    }

    /// Updates existing Goal with new form data.
    /// - Parameters:
    ///   - goal: Existing Goal to update
    ///   - expectation: Existing Expectation to update
    ///   - existingTargets: Current ExpectationMeasures to replace
    ///   - existingAlignments: Current GoalRelevances to replace
    ///   - existingAssignment: Current TermGoalAssignment to replace (if any)
    ///   - formData: New form data
    /// - Returns: Updated Goal
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION:
    /// 1. Update Expectation (preserve id and logTime)
    /// 2. Update Goal (preserve id)
    /// 3. Delete old ExpectationMeasures
    /// 4. Insert new ExpectationMeasures from formData
    /// 5. Delete old GoalRelevances
    /// 6. Insert new GoalRelevances from formData
    /// 7. Delete old TermGoalAssignment (if any)
    /// 8. Insert new TermGoalAssignment (if termId provided)
    /// 9. Return updated Goal
    ///
    /// NOTE: Replace strategy (delete + insert) rather than diff strategy for simplicity
    public func update(
        goal: Goal,
        expectation: Expectation,
        existingTargets: [ExpectationMeasure],
        existingAlignments: [GoalRelevance],
        existingAssignment: TermGoalAssignment?,
        from formData: GoalFormData
    ) async throws -> Goal {
        return try await database.write { db in
            // Validate new measureIds exist (if any)
            for target in formData.metricTargets where target.measureId != nil {
                let measureExists = try Measure.find(target.measureId!).fetchOne(db) != nil
                guard measureExists else {
                    throw CoordinatorError.measureNotFound(target.measureId!)
                }
            }

            // Validate new valueIds exist (if any)
            for alignment in formData.valueAlignments where alignment.valueId != nil {
                let valueExists = try PersonalValue.find(alignment.valueId!).fetchOne(db) != nil
                guard valueExists else {
                    throw CoordinatorError.valueNotFound(alignment.valueId!)
                }
            }

            // Validate new termId exists (if provided)
            if let termId = formData.termId {
                let termExists = try GoalTerm.find(termId).fetchOne(db) != nil
                guard termExists else {
                    throw CoordinatorError.termNotFound(termId)
                }
            }

            // 1. Update Expectation (preserve id and logTime)
            let updatedExpectation = try Expectation.upsert {
                Expectation.Draft(
                    id: expectation.id,  // Preserve ID
                    logTime: expectation.logTime,  // Preserve original logTime
                    title: formData.title.isEmpty ? nil : formData.title,
                    detailedDescription: formData.detailedDescription.isEmpty ? nil : formData.detailedDescription,
                    freeformNotes: formData.freeformNotes.isEmpty ? nil : formData.freeformNotes,
                    expectationType: .goal,
                    expectationImportance: formData.expectationImportance,
                    expectationUrgency: formData.expectationUrgency
                )
            }
            .returning { $0 }
            .fetchOne(db)!

            // 2. Update Goal (preserve id)
            let updatedGoal = try Goal.upsert {
                Goal.Draft(
                    id: goal.id,  // Preserve ID
                    expectationId: updatedExpectation.id,
                    startDate: formData.startDate,
                    targetDate: formData.targetDate,
                    actionPlan: formData.actionPlan?.isEmpty == true ? nil : formData.actionPlan,
                    expectedTermLength: formData.expectedTermLength
                )
            }
            .returning { $0 }
            .fetchOne(db)!

            // 3. Delete old ExpectationMeasures
            for target in existingTargets {
                try ExpectationMeasure.delete(target).execute(db)
            }

            // 4. Insert new ExpectationMeasures from formData
            for target in formData.metricTargets where target.isValid {
                try ExpectationMeasure.insert {
                    ExpectationMeasure.Draft(
                        id: UUID(),  // New ID for new record
                        freeformNotes: target.notes?.isEmpty == true ? nil : target.notes,
                        expectationId: updatedExpectation.id,
                        measureId: target.measureId!,
                        targetValue: target.targetValue,
                        createdAt: Date()
                    )
                }
                .execute(db)
            }

            // 5. Delete old GoalRelevances
            for alignment in existingAlignments {
                try GoalRelevance.delete(alignment).execute(db)
            }

            // 6. Insert new GoalRelevances from formData
            for alignment in formData.valueAlignments where alignment.isValid {
                try GoalRelevance.insert {
                    GoalRelevance.Draft(
                        id: UUID(),  // New ID for new record
                        goalId: updatedGoal.id,
                        valueId: alignment.valueId!,
                        alignmentStrength: alignment.alignmentStrength,
                        relevanceNotes: alignment.relevanceNotes?.isEmpty == true ? nil : alignment.relevanceNotes,
                        createdAt: Date()
                    )
                }
                .execute(db)
            }

            // 7. Delete old TermGoalAssignment (if any)
            if let existingAssignment = existingAssignment {
                try TermGoalAssignment.delete(existingAssignment).execute(db)
            }

            // 8. Insert new TermGoalAssignment (if termId provided)
            if let termId = formData.termId {
                try TermGoalAssignment.insert {
                    TermGoalAssignment.Draft(
                        id: UUID(),  // New ID for new record
                        termId: termId,
                        goalId: updatedGoal.id,
                        assignmentOrder: nil,
                        createdAt: Date()
                    )
                }
                .execute(db)
            }

            return updatedGoal
        }
    }

    /// Deletes Goal and all its relationships.
    /// - Parameters:
    ///   - goal: Goal to delete
    ///   - expectation: Associated Expectation to delete
    ///   - targets: Associated ExpectationMeasures to delete
    ///   - alignments: Associated GoalRelevances to delete
    ///   - assignment: Associated TermGoalAssignment to delete (if any)
    /// - Throws: Database errors if constraints violated
    ///
    /// IMPLEMENTATION:
    /// 1. Delete ExpectationMeasures first (FK dependency)
    /// 2. Delete GoalRelevances (FK dependency)
    /// 3. Delete TermGoalAssignment (FK dependency)
    /// 4. Delete Goal (FK to Expectation)
    /// 5. Delete Expectation last
    ///
    /// NOTE: Caller is responsible for fetching all relationships
    /// before deletion (via GoalsQuery). This ensures we know what we're deleting.
    public func delete(
        goal: Goal,
        expectation: Expectation,
        targets: [ExpectationMeasure],
        alignments: [GoalRelevance],
        assignment: TermGoalAssignment?
    ) async throws {
        try await database.write { db in
            // 1. Delete ExpectationMeasures first (have FK to Expectation)
            for target in targets {
                try ExpectationMeasure.delete(target).execute(db)
            }

            // 2. Delete GoalRelevances (have FK to Goal)
            for alignment in alignments {
                try GoalRelevance.delete(alignment).execute(db)
            }

            // 3. Delete TermGoalAssignment if exists (has FK to Goal)
            if let assignment = assignment {
                try TermGoalAssignment.delete(assignment).execute(db)
            }

            // 4. Delete Goal (has FK to Expectation)
            try Goal.delete(goal).execute(db)

            // 5. Delete Expectation last
            try Expectation.delete(expectation).execute(db)
        }
    }
}
