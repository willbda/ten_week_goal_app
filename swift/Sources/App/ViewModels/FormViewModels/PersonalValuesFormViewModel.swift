import Foundation
import Models
import SQLiteData
import SwiftUI

@MainActor
public final class PersonalValueFormViewModel: ObservableObject {
    @Dependency(\.defaultDatabase) private var database

    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String?

    // FIXME: Performance Issue - Coordinator Re-creation
    // CURRENT: Creates new coordinator instance on EVERY access (computed property)
    // IMPACT: Memory churn, unnecessary allocations during save operations
    // FIX: Change to `private lazy var coordinator: PersonalValueCoordinator = { ... }()`
    // WHEN: Before Phase 4 (when update/delete methods added, this compounds)
    // IF NOT FIXED: App will work but wastes memory/CPU, especially with frequent saves
    private var coordinator: PersonalValueCoordinator {
        PersonalValueCoordinator(database: database)
    }

    public init() {}

    // NOTE: Parameter Design Choice
    // CURRENT: Individual parameters (mirrors ValueFormData fields)
    // ALTERNATIVE: Accept `ValueFormData` directly
    // TRADEOFF: Individual params are more ergonomic for SwiftUI forms,
    //           but duplicate field definitions (two places to update when adding fields)
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

