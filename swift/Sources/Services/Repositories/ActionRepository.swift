////
//// ActionRepository.swift
//// Written by Claude Code on 2025-11-08
////
//// PURPOSE:
//// Read coordinator for Action entities - centralizes query logic and existence checks.
//// Complements ActionCoordinator (writes) by handling all read operations.
////
//// RESPONSIBILITIES:
//// 1. Read operations - fetchAll(), fetchByDateRange(), fetchByGoal()
//// 2. Existence checks - exists() (prevent duplicate actions on same date)
//// 3. Error mapping - DatabaseError → ValidationError with user-friendly messages
////
//// USED BY:
//// - ActionFormViewModel (for loading available goals/measures)
//// - ActionCoordinator (for existence checks)
//// - DashboardViewModel (for recent actions display)
////
//// DEPENDS ON:
//// - Database (SQLiteData DatabaseWriter)
//// - Models (Action, MeasuredAction, ActionGoalContribution)
//// - Queries (ActionsQuery - will be moved here)
////
//
//import Foundation
//import Models
//import SQLiteData
//
//@MainActor
//public final class ActionRepository {
//    private let database: any DatabaseWriter
//
//    public init(database: any DatabaseWriter) {
//        self.database = database
//    }
//
//    // MARK: - Read Operations
//
//    /// Fetch all actions with measurements and goal contributions
//    public func fetchAll() async throws -> [ActionWithDetails] {
//        fatalError("TODO: Implement - move logic from ActionsQuery")
//    }
//
//    /// Fetch actions within a date range
//    public func fetchByDateRange(_ range: ClosedRange<Date>) async throws -> [ActionWithDetails] {
//        fatalError("TODO: Implement - filtered query")
//    }
//
//    /// Fetch actions contributing to a specific goal
//    public func fetchByGoal(_ goalId: UUID) async throws -> [ActionWithDetails] {
//        fatalError("TODO: Implement - JOIN through ActionGoalContribution")
//    }
//
//    // MARK: - Existence Checks
//
//    /// Check if an action exists by title and date
//    /// Used to prevent duplicate action entries
//    public func exists(title: String, on date: Date) async throws -> Bool {
//        fatalError("TODO: Implement - query Action table with date comparison")
//    }
//
//    /// Check if an action exists by ID
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
//        // - Foreign key violations (measureId, goalId)
//        // - Not null violations
//
//        return .databaseError(dbError.localizedDescription)
//    }
//}
