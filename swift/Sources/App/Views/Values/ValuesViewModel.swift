// ValuesViewModel.swift
// State management for values list and operations
//
// Written by Claude Code on 2025-10-20
// Refactored by Claude Code on 2025-10-24 for SQLiteData @FetchAll

import SwiftUI
import SQLiteData
import Models

/// View model for values list and CRUD operations
///
/// Manages state for the values list view, including loading different types
/// of values (general values, major values, highest order values, life areas).
/// Uses @Observable + @FetchAll for automatic reactive database queries.
@Observable
@MainActor
final class ValuesViewModel {

    // MARK: - Properties (Reactive Database Queries)

    /// General values from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var generalValuesQuery: [Models.Values]

    /// Major values from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var majorValuesQuery: [MajorValues]

    /// Highest order values from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var highestOrderValuesQuery: [HighestOrderValues]

    /// Life areas from database (unsorted)
    @ObservationIgnored
    @FetchAll
    var lifeAreasQuery: [LifeAreas]

    /// Error state (for CRUD operations)
    private(set) var error: Error?

    // MARK: - Computed Properties (Sorted)

    /// General values sorted by priority (ascending)
    var generalValues: [Models.Values] {
        generalValuesQuery.sorted { $0.priority < $1.priority }
    }

    /// Major values sorted by priority (ascending)
    var majorValues: [MajorValues] {
        majorValuesQuery.sorted { $0.priority < $1.priority }
    }

    /// Highest order values sorted by priority (ascending)
    var highestOrderValues: [HighestOrderValues] {
        highestOrderValuesQuery.sorted { $0.priority < $1.priority }
    }

    /// Life areas sorted by priority (ascending)
    var lifeAreas: [LifeAreas] {
        lifeAreasQuery.sorted { $0.priority < $1.priority }
    }

    // MARK: - Initialization

    /// Create view model
    /// Note: @FetchAll properties automatically connect to database via prepareDependencies
    init() {
        // No database parameter needed - @FetchAll uses @Dependency(\.defaultDatabase)
    }

    // MARK: - Computed Properties

    /// All values combined into a single array for unified display
    var allValuesForDisplay: [(String, any ValueDisplayable)] {
        var combined: [(String, any ValueDisplayable)] = []
        
        if !highestOrderValues.isEmpty {
            combined.append(("Highest Order Values", HighestOrderValuesWrapper(values: highestOrderValues)))
        }
        
        if !majorValues.isEmpty {
            combined.append(("Major Values", MajorValuesWrapper(values: majorValues)))
        }
        
        if !generalValues.isEmpty {
            combined.append(("General Values", GeneralValuesWrapper(values: generalValues)))
        }
        
        if !lifeAreas.isEmpty {
            combined.append(("Life Areas", LifeAreasWrapper(values: lifeAreas)))
        }
        
        return combined
    }

    // MARK: - CRUD Operations

    /// Create new value (placeholder - specific save methods would need to be implemented)
    /// - Parameter value: Value to create
    func createValue<T>(_ value: T) async {
        // TODO: Implement when database save methods are available for different value types
        print("⚠️ Create value not yet implemented in database")
        self.error = NSError(
            domain: "ValuesViewModel", 
            code: 1001, 
            userInfo: [NSLocalizedDescriptionKey: "Create value functionality not yet implemented"]
        )
    }
}

// MARK: - Helper Protocols and Wrappers

/// Protocol for displaying different value types uniformly
protocol ValueDisplayable {
    var displayItems: [ValueDisplayItem] { get }
}

/// Individual value item for display
struct ValueDisplayItem: Identifiable {
    let id: UUID
    let title: String?
    let detailedDescription: String?
    let priority: Int
    let lifeDomain: String?
    let additionalInfo: String?
}

/// Wrapper for HighestOrderValues
struct HighestOrderValuesWrapper: ValueDisplayable {
    let values: [HighestOrderValues]
    
    var displayItems: [ValueDisplayItem] {
        values.map { value in
            ValueDisplayItem(
                id: value.id,
                title: value.title,
                detailedDescription: value.detailedDescription,
                priority: value.priority,
                lifeDomain: value.lifeDomain,
                additionalInfo: nil
            )
        }
    }
}

/// Wrapper for MajorValues
struct MajorValuesWrapper: ValueDisplayable {
    let values: [MajorValues]
    
    var displayItems: [ValueDisplayItem] {
        values.map { value in
            ValueDisplayItem(
                id: value.id,
                title: value.title,
                detailedDescription: value.detailedDescription,
                priority: value.priority,
                lifeDomain: value.lifeDomain,
                additionalInfo: value.alignmentGuidance
            )
        }
    }
}

/// Wrapper for general Values
struct GeneralValuesWrapper: ValueDisplayable {
    let values: [Models.Values]
    
    var displayItems: [ValueDisplayItem] {
        values.map { value in
            ValueDisplayItem(
                id: value.id,
                title: value.title,
                detailedDescription: value.detailedDescription,
                priority: value.priority,
                lifeDomain: value.lifeDomain,
                additionalInfo: nil
            )
        }
    }
}

/// Wrapper for LifeAreas
struct LifeAreasWrapper: ValueDisplayable {
    let values: [LifeAreas]
    
    var displayItems: [ValueDisplayItem] {
        values.map { value in
            ValueDisplayItem(
                id: value.id,
                title: value.title,
                detailedDescription: value.detailedDescription,
                priority: value.priority,
                lifeDomain: value.lifeDomain,
                additionalInfo: nil
            )
        }
    }
}
