//  Protocols.swift
//  Core protocols as field contracts for database schema
//
//  Written by Claude Code on 2025-10-26

//
//  Design Principle: Protocols enforce FIELD CONTRACTS (compile-time safety)
//  Business logic (queries, calculations) lives in Repositories/Services

import Foundation
import SQLiteData

// MARK: - Core Field Contracts

/// Entities that exist in the database with persistent identity
///
/// **Field Contract:** All persistable entities must have these core fields.
/// This ensures schema consistency across all database tables.
/// **Used by:** Action, Goal, Value, Term, Metric (all @Table entities)
public protocol Persistable: Identifiable, Equatable, Sendable {
    var id: UUID { get set }
    var title: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
    var logTime: Date { get set }
}

/// Entities with target dates and measurable outcomes (future-oriented)
///
/// **Field Contract:** Completable entities must have measurement criteria.
/// This enables progress tracking via database queries.
///
/// **Schema Alignment:** Maps to goals table:
/// - measurementUnit (e.g., "km", "hours")
/// - measurementTarget (e.g., 120.0)
/// - startDate / targetDate
///
/// **Used by:** Goal (including SMART goals and milestones via goalType field)
public protocol Completable {
    var targetDate: Date? { get set }
    var measurementUnit: String? { get set }
    var measurementTarget: Double? { get set }
    var startDate: Date? { get set }
}

/// Entities that can have metrics attached (measurement-capable)
///
/// **Field Contract:** Measurable entities participate in the metrics system.
/// They can have relationships in the `action_metrics` table.
///
/// **Schema Alignment:**
/// - Entity has records in `action_metrics` junction table
/// - Links to `metrics` table (km, hours, occasions, etc)
///
/// **Marker Protocol:** No additional fields required beyond Persistable.
/// This is a capability marker, not a field requirement.
///
/// **Used by:** Action (can log km, hours, occasions, etc)
public protocol Measurable {}

// MARK: - Default Implementations

/// Default equality: two entities are equal if they have the same UUID
/// This represents identity (same database record), not value equality
extension Persistable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Design Rationale

/*
 WHAT PROTOCOLS PROVIDE:
 ✅ Compile-time field checking (Xcode catches missing fields)
 ✅ Enforces schema consistency across all entities
 ✅ Documents intent (Completable = has targets, Measurable = has metrics)
 ✅ Enables generic form sections (if built)

 WHAT PROTOCOLS DON'T PROVIDE:
 ❌ Business logic methods (those go in Services/Repositories)
 ❌ Database operations (@Table macro handles this)
 ❌ Validation (database constraints + service layer validation)
 ❌ Serialization (@Table + Codable handle this)

 DROPPED PROTOCOLS (from previous version):
 - Doable: measuresByUnit moved to action_metrics table, remaining fields Action-specific
 - Motivating: priority/lifeDomain are Value-specific fields, not a shared pattern
 - Polymorphable: replaced with enum fields (goalType, valueLevel)
 - Validatable: moved to service layer / database constraints
 - Serializable: @Table + Codable handle automatically

 TEMPORAL ORIENTATION:
 - Persistable = EXISTS (in database)
 - Completable = FUTURE (targets you work toward)
 - Measurable = PAST (measurements you logged)

 BUSINESS LOGIC BELONGS IN SERVICES:
 ```swift
 // ❌ DON'T do this:
 extension Completable {
     func calculateProgress() -> Double { ... }  // Can't work - needs database joins!
 }

 // ✅ DO this:
 class GoalRepository {
     func calculateProgress(for goal: Goal) async -> Double {
         // SELECT SUM(am.value) FROM action_metrics am
         // JOIN action_goal_contributions agc ...
     }
 }
 ```

 EXAMPLE: Protocol as Field Contract
 ```swift
 @Table
 struct Action: Persistable, Measurable {
     // Compiler enforces: ✓ has id, title, logTime
     // @Table generates:   ✓ CREATE TABLE actions (id TEXT, title TEXT, ...)
     // Measurable marks:   ✓ can have action_metrics relationships

     var id: UUID
     var title: String?
     var logTime: Date
     var durationMinutes: Double?  // Action-specific field
 }

 @Table
 struct Goal: Persistable, Completable {
     // Compiler enforces: ✓ has id, title, measurementUnit, targetDate
     // @Table generates:   ✓ CREATE TABLE goals (id TEXT, measurementUnit TEXT, ...)

     var id: UUID
     var title: String?
     var logTime: Date
     var measurementUnit: String?
     var measurementTarget: Double?
     var targetDate: Date?
     var goalType: String  // "goal" or "milestone" (enum, not polymorphic protocol)
 }
 ```
 */
