////
//// PersonalValueRepository.swift
//// Written by Claude Code on 2025-11-08
////
//// PURPOSE:
//// Read coordinator for PersonalValue entities - centralizes query logic.
//// Complements PersonalValueCoordinator (writes) by handling all read operations.
////
//// RESPONSIBILITIES:
//// 1. Read operations - fetchAll(), fetchByLevel()
//// 2. Existence checks - existsByTitle() (prevent duplicate values)
//// 3. Error mapping - DatabaseError → ValidationError
////
//// USED BY:
//// - PersonalValuesFormViewModel (for loading values list)
//// - GoalFormView (for value alignment picker)
//// - PersonalValueCoordinator (for existence checks)
////
//// DEPENDS ON:
//// - Database (SQLiteData DatabaseWriter)
//// - Models (PersonalValue, ValueLevel enum)
//// - Queries (PersonalValuesQuery - will be moved here)
////
//
//import Foundation
//import Models
//import SQLiteData
//
//@MainActor
//public final class PersonalValueRepository {
//    private let database: any DatabaseWriter
//
//    public init(database: any DatabaseWriter) {
//        self.database = database
//    }
//
//    // MARK: - Read Operations
//
//    /// Fetch all personal values ordered by priority
//    public func fetchAll() async throws -> [PersonalValue] {
//        fatalError("TODO: Implement - move logic from PersonalValuesQuery")
//    }
//
//    /// Fetch values of a specific level (general, major, highest_order, life_area)
//    public func fetchByLevel(_ level: ValueLevel) async throws -> [PersonalValue] {
//        fatalError("TODO: Implement - filtered query")
//    }
//
//    /// Fetch values aligned with a specific goal
//    public func fetchByGoal(_ goalId: UUID) async throws -> [PersonalValue] {
//        fatalError("TODO: Implement - JOIN through GoalRelevance")
//    }
//
//    // MARK: - Existence Checks
//
//    /// Check if a value with this title already exists
//    public func existsByTitle(_ title: String) async throws -> Bool {
//        fatalError("TODO: Implement - query PersonalValue table")
//    }
//
//    /// Check if a value exists by ID
//    public func exists(_ id: UUID) async throws -> Bool {
//        fatalError("TODO: Implement - simple find query")
//    }
//
//    // MARK: - Error Mapping
//
//    /// Map database errors to user-friendly validation errors
//    func mapDatabaseError(_ error: Error) -> ValidationError {
//        guard let dbError = error as? DatabaseError else {
//            return .databaseError(error.localizedDescription)
//        }
//
//        // TODO: Implement specific error mapping
//
//        return .databaseError(dbError.localizedDescription)
//    }
//}
