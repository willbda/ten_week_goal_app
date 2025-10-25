// ValuesViewModel.swift
// State management for values list and operations
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Database
import Models

/// View model for values list and CRUD operations
///
/// Manages state for the values list view, including loading different types
/// of values (general values, major values, highest order values, life areas).
/// Uses @Observable for automatic view updates.
@Observable
@MainActor
final class ValuesViewModel {

    // MARK: - Properties

    /// Database manager for data operations
    private let database: DatabaseManager

    /// All general values loaded from database
    private(set) var generalValues: [Values] = []

    /// All major values loaded from database
    private(set) var majorValues: [MajorValues] = []

    /// All highest order values loaded from database
    private(set) var highestOrderValues: [HighestOrderValues] = []

    /// All life areas loaded from database
    private(set) var lifeAreas: [LifeAreas] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error state
    private(set) var error: Error?

    // MARK: - Initialization

    /// Create view model with database manager
    /// - Parameter database: Database manager for data operations
    init(database: DatabaseManager) {
        self.database = database
    }

    // MARK: - Loading

    /// Load all types of values from database
    ///
    /// Fetches general values, major values, highest order values, and life areas.
    /// Each type is sorted by priority (lower numbers = higher priority).
    func loadAllValues() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Load all types of values concurrently
            async let generalValuesTask = database.fetchGeneralValues()
            async let majorValuesTask = database.fetchMajorValues()
            async let highestOrderValuesTask = database.fetchHighestOrderValues()
            async let lifeAreasTask = database.fetchLifeAreas()

            // Wait for all results and sort by priority
            generalValues = try await generalValuesTask
                .sorted { $0.priority < $1.priority }
            
            majorValues = try await majorValuesTask
                .sorted { $0.priority < $1.priority }
            
            highestOrderValues = try await highestOrderValuesTask
                .sorted { $0.priority < $1.priority }
            
            lifeAreas = try await lifeAreasTask
                .sorted { $0.priority < $1.priority }

        } catch {
            self.error = error
            print("❌ Failed to load values: \(error)")
        }
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
    let values: [Values]
    
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
