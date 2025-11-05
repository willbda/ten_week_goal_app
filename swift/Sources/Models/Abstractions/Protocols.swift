//  Protocols.swift
//  Trait-based protocols for entity layers
//
//  Written by Claude Code on 2025-10-26
//  Updated by Claude Code on 2025-10-31 (refactored to trait-based composition)
//
//  DESIGN PRINCIPLE: Compose protocols from traits
//  - Identifiable: All entities have UUID
//  - Documentable: Full metadata (title, description, notes)
//  - Timestamped: Track creation time
//
//  Use semantic typealiases for clarity:
//  - Abstract = base entities with full metadata
//  - Basic = concrete working entities (reference abstracts)
//  - Composit = junction tables (minimal fields)
//
//  Business logic (queries, calculations) lives in Repositories/Services

import Foundation
import SQLiteData

// MARK: - Trait Protocols

/// All database entities must conform to Swift's Identifiable with UUID
/// This is required for SQLiteData and CloudKit synchronization
///
/// Note: We extend Swift.Identifiable (not redefine it) to work with SQLiteData

/// Entities that can be titled and described
///
/// **Used by**: Abstract base entities that need full documentation
/// (Expectation, TimePeriod, Action, Measure, PersonalValue)
public protocol Documentable {
    var title: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
}

/// Entities that track when they were created
///
/// **Used by**: Abstract base entities to record creation/logging time
public protocol Timestamped {
    var logTime: Date { get }
}

// MARK: - Semantic Typealiases

/// Abstract base entities with full metadata
///
/// Abstract entities are the foundation layer - they have complete documentation
/// and are typically not worked with directly in daily use.
///
/// **Examples**: Expectation, TimePeriod, Action, Measure, PersonalValue
///
/// **Fields**: id, title, detailedDescription, freeformNotes, logTime
public protocol DomainAbstraction: Identifiable, Documentable, Timestamped, Equatable, Hashable, Sendable
    where ID == UUID {}

/// Concrete working entities that reference abstracts
///
/// Basic entities are what you work with daily - they reference Abstract entities
/// for metadata and add type-specific fields.
///
/// **Examples**: Goal, Milestone, Obligation, GoalTerm
///
/// **Fields**: id + type-specific fields (startDate, deadline, etc.)
public protocol DomainBasic: Identifiable, Equatable, Hashable, Sendable
    where ID == UUID {}

/// Junction tables connecting entities
///
/// Composit entities are pure relationships - they link two or more entities
/// together with minimal metadata.
///
/// **Examples**: MeasuredAction, GoalRelevance, ActionGoalContribution
///
/// **Fields**: id + FK references + relationship data
public protocol DomainComposit: Identifiable, Equatable, Hashable, Sendable
    where ID == UUID {}

/// Default equality for Identifiable entities: two entities are equal if they have the same UUID
extension Identifiable where Self: Equatable, ID == UUID {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Design Rationale & Examples

/*
 TRAIT-BASED ARCHITECTURE:

 Instead of a monolithic Persistable protocol, we compose from traits:
 - Identifiable (id): All entities
 - Documentable (title, description, notes): Abstract entities only
 - Timestamped (logTime): Abstract entities only

 This allows:
 ✅ Precise contracts (Basic entities don't pretend to have title/description)
 ✅ Semantic clarity via typealiases (Abstract, Basic, Composit)
 ✅ Compile-time type checking
 ✅ No field duplication between layers

 LAYER EXAMPLES:

 // Abstractions/ - Full metadata entities
 @Table
 struct Expectation: Abstract {
     var id: UUID
     var title: String?
     var detailedDescription: String?
     var freeformNotes: String?
     var logTime: Date
     // + expectation-specific fields
 }

 // Basics/ - Daily working entities
 @Table
 struct Goal: Basic {
     var id: UUID
     var expectationId: UUID  // FK to abstract
     var startDate: Date      // Goal-specific
     var targetDate: Date
     // No title/description - gets from Expectation
 }

 // Composits/ - Junction tables
 @Table
 struct MeasuredAction: Composit {
     var id: UUID
     var actionId: UUID   // FK
     var measureId: UUID   // FK
     var value: Double    // Measurement
     // No metadata - pure relationship
 }

 TYPE SAFETY:

 func documentEntity<T: Abstract>(_ entity: T) {
     print(entity.title)  // ✓ Guaranteed to exist
     print(entity.logTime) // ✓ Guaranteed to exist
 }

 func processBasic<T: Basic>(_ entity: T) {
     print(entity.id)     // ✓ Has ID
     // entity.title      // ✗ Compile error - Basic doesn't have title
 }

 BUSINESS LOGIC BELONGS IN SERVICES:

 // ❌ DON'T do this:
 extension Basic {
     func fetchMetadata() -> String { ... }  // Can't work - needs database joins!
 }

 // ✅ DO this:
 class GoalRepository {
     func fetchWithExpectation(goal: Goal) async -> (Goal, Expectation) {
         // Proper async database query
     }
 }
 */
