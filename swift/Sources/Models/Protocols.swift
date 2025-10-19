//  Protocols.swift
//  Core ontological protocols for domain models
//
//  Created by David Williams on 10/18/25.
//  Refactored by Claude Code on 10/18/25
//
//  These protocols define "ways of being" (ontology), not "things to do" (behavior).
//  Business logic (calculations, matching, progress) belongs in separate layers.
//
//  Used by: Action, Goal, GoalTerm, Values, etc.

import Foundation

// MARK: - Core Ontology: "Ways of Being"

/// Things that exist in the database (have persistent identity)
///
/// Persistable entities are the foundation of the domain model.
/// They have:
/// - Unique identity (UUID) that persists across app sessions
/// - Creation timestamp (logTime)
/// - Descriptive metadata (names, descriptions, notes)
/// - Identity-based equality (same UUID = same entity, even if fields differ)
///
/// Used by: All storable entities (Action, Goal, Values, Terms, etc.)
public protocol Persistable: Identifiable, Equatable {
    var id: UUID { get set }
    var friendlyName: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
    var logTime: Date { get set }
}

public extension Persistable {
    /// Default equality: two entities are equal if they have the same UUID
    /// This represents identity (same database record), not value equality
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Things with targets you work toward (future-oriented)
///
/// Achievable entities represent aspirations, goals, milestones.
/// They have:
/// - Target dates (when you want to achieve them)
/// - Measurement criteria (units and target values)
/// - Optional start dates (for time-bounded goals)
///
/// Achievable things can be progressed toward, achieved, or forgone.
/// Progress calculation is business logic (Ethica layer), not part of this protocol.
///
/// Used by: Goal, Milestone, SmartGoal, potentially GoalTerm
public protocol Achievable {
    var targetDate: Date? { get set }
    var measurementUnit: String? { get set }
    var measurementTarget: Double? { get set }
    var startDate: Date? { get set }
}

/// Things you've done at moments in time (past-oriented)
///
/// Performed entities represent completed actions, logged activities.
/// They have:
/// - Measurements (what was accomplished: distance, duration, count, etc.)
/// - Timing information (when and for how long)
///
/// Performed things are factual records, not aspirations.
/// Matching performed actions to achievable goals is business logic (Ethica layer).
///
/// Used by: Action
public protocol Performed {
    var measurements: [String: Double]? { get set }
    var durationMinutes: Double? { get set }
    var startTime: Date? { get set }
}

/// Things that motivate and give meaning
///
/// Motivating entities represent personal values, life domains, priorities.
/// They have:
/// - Priority ranking (importance level)
/// - Life domain categorization (Health, Career, Relationships, etc.)
///
/// Used by: Incentives, Values, MajorValues, HighestOrderValues, LifeAreas
public protocol Motivating {
    var priority: Int { get set }
    var lifeDomain: String? { get set }
}

// MARK: - Infrastructure Protocols

/// Things that can validate their own structural consistency
///
/// Validatable entities have business rules about their internal state.
/// Examples:
/// - Actions: measurements must be positive, startTime requires duration
/// - Goals: targetDate must be after startDate, measurementTarget must be positive
/// - SmartGoal: all SMART criteria fields must be present
///
/// Note: This is structural validation, not business logic validation.
/// Used by: Action, Goal, SmartGoal, Milestone, etc.
public protocol Validatable {
    func isValid() -> Bool
}

/// Things with a type field for polymorphic database storage
///
/// TypeIdentifiable entities use single-table inheritance patterns.
/// The typeIdentifier field (e.g., "Goal", "SmartGoal", "Milestone") allows
/// storing subclasses in the same database table and reconstructing the
/// correct Swift type on retrieval.
///
/// Used by: Goal hierarchy (Goal/SmartGoal/Milestone), Values hierarchy (Incentives/Values/MajorValues)
public protocol TypeIdentifiable {
    var typeIdentifier: String { get }
}

/// Things that can be converted to/from dictionaries for storage/API
///
/// Serializable entities can be translated between domain models and storage formats.
/// This is the bridge between domain layer (Models) and translation layer (Rhetorica).
///
/// Used by: All Persistable entities when saving to database or sending via API
public protocol Serializable {
    func toDictionary() -> [String: Any]
    static func fromDictionary(_ dict: [String: Any]) -> Self?
}

/// Things that can be converted to/from JSON
///
/// JSONSerializable extends Serializable with string-based JSON encoding.
/// Used for API responses, file storage, data export.
///
/// Used by: Entities exposed via API endpoints
public protocol JSONSerializable: Serializable {
    func toJSON() -> String?
    static func fromJSON(_ json: String) -> Self?
}

/// Things that can be archived (soft-deleted)
///
/// Archivable entities support non-destructive deletion.
/// Archived entities are hidden from normal queries but preserved for audit trails.
///
/// Will be used by: All entities when archive functionality is implemented
public protocol Archivable {
    var isArchived: Bool { get set }
    var archivedAt: Date? { get set }
}

// MARK: - Design Notes

/*
 WHAT BELONGS HERE (Ontology - "Ways of Being"):
 ✅ Data fields that define what something IS
 ✅ Structural validation (is this entity self-consistent?)
 ✅ Infrastructure needs (serialization, type identification)

 WHAT DOESN'T BELONG HERE (Behavior - "Things to Do"):
 ❌ Calculations (progress, completion percentage)
 ❌ Matching logic (which actions contribute to which goals)
 ❌ Business rules (is this goal active? how many days remaining?)
 ❌ Relationships between entities

 Those behavioral concerns belong in:
 - Ethica layer: Business logic functions/extensions
 - Rhetorica layer: Translation/serialization implementations
 - Separate relationship entities: ActionGoalRelationship, etc.

 TEMPORAL ORIENTATION:
 - Achievable = FUTURE (targets, goals, what you want)
 - Performed = PAST (actions, what you did)
 - Motivating = TIMELESS (values, priorities, meaning)
 - Persistable = ONGOING (exists in the database)
 */
