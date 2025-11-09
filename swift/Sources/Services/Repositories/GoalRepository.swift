////
//// GoalRepository.swift
//// Written by Claude Code on 2025-11-08
////
//// PURPOSE:
//// Read coordinator for Goal entities - centralizes query logic and existence checks.
//// Complements GoalCoordinator (writes) by handling all read operations.
////
//// RESPONSIBILITIES:
//// 1. Read operations - fetchAll(), fetchActiveGoals(), fetchByTerm(), fetchByValue()
//// 2. Existence checks - existsByTitle() (used by GoalCoordinator to prevent duplicates)
//// 3. Error mapping - DatabaseError → ValidationError with user-friendly messages
////
//// USED BY:
//// - GoalFormViewModel (for loading available goals)
//// - GoalCoordinator (for existence checks before creating)
//// - DashboardViewModel (for active goals display)
////
//// DEPENDS ON:
//// - Database (SQLiteData DatabaseWriter)
//// - Models (Goal, Expectation, ExpectationMeasure, GoalRelevance)
//// - Queries (GoalsQuery, ActiveGoals - will be moved here)
////
//
//import Foundation
//import Models
//import SQLiteData
//
//@MainActor
//public final class GoalRepository {
//    private let database: any DatabaseWriter
//
//    public init(database: any DatabaseWriter) {
//        self.database = database
//    }
//
//    // MARK: - Read Operations
//
//    /// Fetch all goals with full relationship graph
//    public func fetchAll() async throws -> [GoalWithDetails] {
//        fatalError("TODO: Implement - move logic from GoalsQuery")
//    }
//
//    /// Fetch active goals (no target date or target date in future)
//    public func fetchActiveGoals() async throws -> [GoalWithDetails] {
//        fatalError("TODO: Implement - move logic from ActiveGoals query")
//    }
//
//    /// Fetch goals assigned to a specific term
//    public func fetchByTerm(_ termId: UUID) async throws -> [GoalWithDetails] {
//        fatalError("TODO: Implement - new query")
//    }
//
//    /// Fetch goals aligned with a specific personal value
//    public func fetchByValue(_ valueId: UUID) async throws -> [Goal] {
//        fatalError("TODO: Implement - new query")
//    }
//
//    // MARK: - Existence Checks (Used by GoalCoordinator)
//
//    /// Check if a goal with this title already exists
//    /// Used to prevent duplicate goals during creation (CSV import, manual entry)
//    public func existsByTitle(_ title: String) async throws -> Bool {
//        fatalError("TODO: Implement - query Expectation table")
//    }
//
//    /// Check if a goal exists by ID
//    public func exists(_ id: UUID) async throws -> Bool {
//        fatalError("TODO: Implement - simple find query")
//    }
//
//    // MARK: - Error Mapping
//
//    /// Map database errors to user-friendly validation errors
//    /// Called by GoalCoordinator when writes fail
//    func mapDatabaseError(_ error: Error) -> ValidationError {
//        guard let dbError = error as? DatabaseError else {
//            return .databaseError(error.localizedDescription)
//        }
//
//        // TODO: Implement specific error mapping
//        // - Foreign key violations (measureId, valueId, termId)
//        // - Unique violations
//        // - Not null violations
//
//        return .databaseError(dbError.localizedDescription)
//    }
//}
