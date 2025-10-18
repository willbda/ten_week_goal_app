// Ontology.swift
// Base entity classes for domain model
//
// Written by Claude Code on 2025-10-17
// Ported from Python implementation (python/categoriae/ontology.py)
//
// Provides shared infrastructure (id, timestamps) that all entities inherit.
// Children differentiate by adding required fields that define their essence.

import Foundation

// MARK: - IndependentEntity

/// Base class for all entities with common identification fields
///
/// Provides the minimal shared structure: name, id, description, notes
class IndependentEntity {
    /// Primary identifier - short name for the entity
    var commonName: String

    /// Unique identifier assigned by database (nil for new entities)
    var id: Int?

    /// Optional detailed description
    var description: String?

    /// Freeform notes about the entity
    var notes: String?

    /// Initialize with required commonName, optional other fields
    init(
        commonName: String,
        id: Int? = nil,
        description: String? = nil,
        notes: String? = nil
    ) {
        self.commonName = commonName
        self.id = id
        self.description = description
        self.notes = notes
    }
}

// MARK: - PersistableEntity

/// Base class for entities that can be stored in database
///
/// Provides common persistence fields with defaults, allowing child classes
/// to add required fields first while maintaining proper field ordering.
///
/// Pattern: Children add required fields → inherit these defaulted fields → add optional fields
class PersistableEntity: IndependentEntity {
    /// When the entity was logged/created
    var logTime: Date

    /// Initialize with required commonName and optional logTime (defaults to now)
    init(
        commonName: String,
        id: Int? = nil,
        description: String? = nil,
        notes: String? = nil,
        logTime: Date = Date()
    ) {
        self.logTime = logTime
        super.init(
            commonName: commonName,
            id: id,
            description: description,
            notes: notes
        )
    }
}

// MARK: - DerivedEntity

/// Base class for relationships computed from existing entities
///
/// These are NOT source of truth - they can be recalculated from base entities.
/// Persisting them is purely for performance optimization and auditability.
///
/// Examples:
///   - An action contributing to a goal
///   - A goal aligned with a value
///   - An action reflecting a value
class DerivedEntity {
    // Base class for derived/computed relationships
    // Children will add specific relationship fields

    init() {
        // Placeholder - children will define their own initialization
    }
}
