import Foundation
import Models
import SQLiteData
import SwiftUI

@MainActor
public final class PersonalValueFormViewModel: ObservableObject {
    @Dependency(\.defaultDatabase) private var database

    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String?

    private var coordinator: PersonalValueCoordinator {
        PersonalValueCoordinator(database: database)
    }

    public init() {}

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
}
