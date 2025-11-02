import Dependencies
import Foundation
import Models
import Observation
import SQLiteData
import Services
import SwiftUI

// ARCHITECTURE DECISION: Why @Observable instead of ObservableObject?
// CONTEXT: Swift 5.9+ introduced @Observable macro as modern replacement for ObservableObject
// BENEFITS:
//   - No @Published needed - all properties auto-tracked
//   - Better performance (fine-grained observation)
//   - Cleaner syntax (less boilerplate)
// TRADEOFF: @Observable only works on classes, not structs
//   Our models (PersonalValue) are structs (required by SQLiteData @Table macro)
//   So ViewModels serve as @Observable wrappers for struct models
// SEE: ARCHITECTURE_EVALUATION_20251102.md for full analysis
//
// ARCHITECTURE DECISION: @Observable + @Dependency Pattern
// PATTERN: Based on SQLiteData's ObservableModelDemo example
// KEY: Use @ObservationIgnored on @Dependency properties
// WHY: Prevents @Observable macro from trying to track dependency changes
// SEE: sqlite-data-main/Examples/CaseStudies/ObservableModelDemo.swift

@Observable
@MainActor
public final class PersonalValuesFormViewModel {
    public var isSaving: Bool = false
    public var errorMessage: String?

    // ARCHITECTURE DECISION: @ObservationIgnored + @Dependency
    // CONTEXT: @Observable macro conflicts with @Dependency unless ignored
    // PATTERN: From SQLiteData's ObservableModelDemo.swift:56-57
    // SOLUTION: Mark @Dependency with @ObservationIgnored
    // RESULT: Database dependency works, but changes aren't tracked (which is fine)
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    // ARCHITECTURE DECISION: No lazy properties with @Observable
    // CONTEXT: @Observable macro doesn't support lazy properties (compiler error)
    // SOLUTION: Create coordinator on-demand via computed property
    // TRADEOFF: Recreated each time, but coordinators are lightweight (just hold database ref)
    // ALTERNATIVE: Could store as @ObservationIgnored var, but then not lazy
    private var coordinator: PersonalValueCoordinator {
        PersonalValueCoordinator(database: database)
    }

    public init() {}

    // ARCHITECTURE DECISION: Individual parameters vs FormData object?
    // CURRENT: Individual parameters (mirrors ValueFormData fields)
    // ALTERNATIVE: Accept `ValueFormData` directly
    // WHY INDIVIDUAL PARAMS:
    //   - More ergonomic for SwiftUI forms (no wrapper object)
    //   - Clear what's required vs optional
    //   - Better autocomplete in Xcode
    // TRADEOFF: Duplicates field definitions (two places to update when adding fields)
    // FUTURE: If fields exceed 7-8 parameters, consider switching to ValueFormData object
    public func save(
        title: String,
        level: ValueLevel,
        priority: Int,
        description: String? = nil,
        notes: String? = nil,
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil
    ) async throws -> PersonalValue {
        isSaving = true
        defer { isSaving = false }

        let formData = ValueFormData(
            title: title,
            detailedDescription: description,
            freeformNotes: notes,
            valueLevel: level,
            priority: priority,
            lifeDomain: lifeDomain,
            alignmentGuidance: alignmentGuidance
        )

        do {
            let value = try await coordinator.create(from: formData)
            errorMessage = nil
            return value
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // TODO: Phase 4 - Add Update and Delete Operations
    // NEEDED: public func update(_ value: PersonalValue, with formData: ValueFormData) async throws
    // NEEDED: public func delete(_ value: PersonalValue) async throws
    // WHEN: Before editing existing values in ValueListView
    // PATTERN: Same error handling and isSaving state as save()
}
