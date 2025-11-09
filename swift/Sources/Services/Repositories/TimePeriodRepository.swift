////
//// TimePeriodRepository.swift
//// Written by Claude Code on 2025-11-08
////
//// PURPOSE:
//// Read coordinator for TimePeriod/Term entities - centralizes query logic.
//// Complements TimePeriodCoordinator (writes) by handling all read operations.
////
//// RESPONSIBILITIES:
//// 1. Read operations - fetchAll(), fetchCurrentTerm(), fetchByDateRange()
//// 2. Existence checks - existsByTermNumber() (prevent duplicate term numbers)
//// 3. Error mapping - DatabaseError → ValidationError
////
//// USED BY:
//// - TermFormView (for loading available terms)
//// - GoalFormView (for term assignment picker)
//// - DashboardViewModel (for current term display)
////
//// DEPENDS ON:
//// - Database (SQLiteData DatabaseWriter)
//// - Models (TimePeriod, GoalTerm)
//// - Queries (TermsQuery - will be moved here)
////
//
//import Foundation
//import Models
//import SQLiteData
//
//@MainActor
//public final class TimePeriodRepository {
//    private let database: any DatabaseWriter
//
//    public init(database: any DatabaseWriter) {
//        self.database = database
//    }
//
//    // MARK: - Read Operations
//
//    /// Fetch all terms with their time periods
//    public func fetchAll() async throws -> [TermWithPeriod] {
//        fatalError("TODO: Implement - move logic from TermsQuery")
//    }
//
//    /// Fetch the current term (today's date falls within start/end)
//    public func fetchCurrentTerm() async throws -> TermWithPeriod? {
//        fatalError("TODO: Implement - date range query")
//    }
//
//    /// Fetch terms within a date range
//    public func fetchByDateRange(_ range: ClosedRange<Date>) async throws -> [TermWithPeriod] {
//        fatalError("TODO: Implement - date range query")
//    }
//
//    // MARK: - Existence Checks
//
//    /// Check if a term with this number already exists
//    public func existsByTermNumber(_ termNumber: Int) async throws -> Bool {
//        fatalError("TODO: Implement - query GoalTerm table")
//    }
//
//    /// Check if a term exists by ID
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
