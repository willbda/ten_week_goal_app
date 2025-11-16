//
// TimePeriodRepository.swift
// Written by Claude Code on 2025-11-08
// Implemented on 2025-11-10 following Swift 6 concurrency patterns
//
// PURPOSE:
// Read coordinator for TimePeriod/Term entities - centralizes query logic.
// Complements TimePeriodCoordinator (writes) by handling all read operations.
//
// RESPONSIBILITIES:
// 1. Read operations - fetchAll(), fetchCurrentTerm(), fetchByDateRange()
// 2. Existence checks - existsByTermNumber() for duplicate prevention
// 3. Error mapping - DatabaseError → ValidationError
//
// PATTERN:
// - Query builders for simple JOINs (GoalTerm + TimePeriod)
// - #sql for date range queries and aggregations
// - FetchKeyRequest for multi-step queries
//

import Foundation
import Models
import SQLiteData

// MARK: - Export Types

/// Denormalized, flat export format for Terms with TimePeriod data inlined
///
/// EXPORT PATTERN:
/// This struct is optimized for CSV/JSON export by flattening the Term + TimePeriod
/// relationship into a single record. All fields are optional to handle incomplete data.
///
/// USAGE:
/// ```swift
/// let exports = try await repository.fetchForExport(from: startDate, to: endDate)
/// let csvData = exports.map { $0.toCSVRow() }.joined(separator: "\n")
/// ```
public struct TermExport: Codable, Sendable {
    // MARK: - Term Identity
    public let id: UUID
    public let termNumber: Int

    // MARK: - Term Planning Data
    public let theme: String?
    public let reflection: String?
    public let status: String?  // TermStatus.rawValue

    // MARK: - TimePeriod Data (Inlined)
    public let timePeriodId: UUID
    public let timePeriodTitle: String?
    public let startDate: Date
    public let endDate: Date

    // MARK: - Associated Goals (Optional)
    public let assignedGoalIds: [UUID]?

    public init(
        id: UUID,
        termNumber: Int,
        theme: String?,
        reflection: String?,
        status: String?,
        timePeriodId: UUID,
        timePeriodTitle: String?,
        startDate: Date,
        endDate: Date,
        assignedGoalIds: [UUID]?
    ) {
        self.id = id
        self.termNumber = termNumber
        self.theme = theme
        self.reflection = reflection
        self.status = status
        self.timePeriodId = timePeriodId
        self.timePeriodTitle = timePeriodTitle
        self.startDate = startDate
        self.endDate = endDate
        self.assignedGoalIds = assignedGoalIds
    }
}

// REMOVED @MainActor: Repository performs database queries which are I/O
// operations that should run in background. Database reads should not block
// the main thread. ViewModels will await results on main actor as needed.
//
// SENDABLE: Conforms to Sendable for Swift 6 strict concurrency.
// Safe because:
// - Only immutable property (private let database)
// - All methods are async (thread-safe by nature)
// - Can be safely passed from @MainActor ViewModels to background tasks
public final class TimePeriodRepository: Sendable {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    // MARK: - Read Operations

    /// Fetch all terms with their time periods
    ///
    /// Orders by term number descending (most recent first)
    public func fetchAll() async throws -> [TermWithPeriod] {
        do {
            return try await database.read { db in
                try FetchAllTermsRequest().fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch the current term (today's date falls within start/end)
    public func fetchCurrentTerm() async throws -> TermWithPeriod? {
        do {
            return try await database.read { db in
                try FetchCurrentTermRequest().fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch terms within a date range
    ///
    /// Returns terms whose time periods overlap with the given range
    public func fetchByDateRange(_ range: ClosedRange<Date>) async throws -> [TermWithPeriod] {
        do {
            return try await database.read { db in
                try FetchTermsByDateRangeRequest(range: range).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Fetch terms in denormalized export format
    ///
    /// Returns flat records with TimePeriod data inlined and optional goal assignments.
    /// Suitable for CSV/JSON export.
    ///
    /// - Parameters:
    ///   - startDate: Optional filter - include only terms whose periods end on or after this date
    ///   - endDate: Optional filter - include only terms whose periods start on or before this date
    /// - Returns: Array of denormalized term records
    ///
    /// **Date Filtering Logic**:
    /// - `from: Date` → Include terms where `timePeriod.endDate >= from`
    /// - `to: Date` → Include terms where `timePeriod.startDate <= to`
    /// - Both filters → Overlap logic (period intersects [from, to])
    /// - No filters → All terms
    ///
    /// **Example**:
    /// ```swift
    /// // Export last 6 months of terms
    /// let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
    /// let exports = try await repository.fetchForExport(from: sixMonthsAgo)
    /// ```
    public func fetchForExport(
        from startDate: Date? = nil,
        to endDate: Date? = nil
    ) async throws -> [TermExport] {
        do {
            return try await database.read { db in
                try FetchTermsForExportRequest(
                    startDate: startDate,
                    endDate: endDate
                ).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Existence Checks

    /// Check if a term with this number already exists
    public func existsByTermNumber(_ termNumber: Int) async throws -> Bool {
        do {
            return try await database.read { db in
                try ExistsByTermNumberRequest(termNumber: termNumber).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    /// Check if a term exists by ID
    public func exists(_ id: UUID) async throws -> Bool {
        do {
            return try await database.read { db in
                try ExistsByIdRequest(id: id).fetch(db)
            }
        } catch {
            throw mapDatabaseError(error)
        }
    }

    // MARK: - Error Mapping

    private func mapDatabaseError(_ error: Error) -> ValidationError {
        guard let dbError = error as? DatabaseError else {
            return .databaseConstraint(error.localizedDescription)
        }

        switch dbError.resultCode {
        case .SQLITE_CONSTRAINT_UNIQUE:
            return .duplicateRecord("This term number already exists")
        case .SQLITE_CONSTRAINT_NOTNULL:
            return .missingRequiredField("Required field is missing")
        case .SQLITE_CONSTRAINT_FOREIGNKEY:
            return .foreignKeyViolation("Referenced time period not found")
        case .SQLITE_CONSTRAINT:
            return .databaseConstraint(dbError.message ?? "Database constraint violated")
        default:
            return .databaseConstraint(dbError.localizedDescription)
        }
    }
}

// MARK: - Fetch Requests

/// Fetch all terms with their time periods
///
/// Simple 1:1 JOIN - uses query builder (no need for #sql)
private struct FetchAllTermsRequest: FetchKeyRequest {
    typealias Value = [TermWithPeriod]

    func fetch(_ db: Database) throws -> [TermWithPeriod] {
        let results = try GoalTerm.all
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}

/// Fetch current term (today's date within start/end range)
private struct FetchCurrentTermRequest: FetchKeyRequest {
    typealias Value = TermWithPeriod?

    func fetch(_ db: Database) throws -> TermWithPeriod? {
        let now = Date()

        // Fetch all terms + periods, then filter in Swift
        // (Simpler than complex date range query builder)
        let results = try GoalTerm.all
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        // Find term where now is between startDate and endDate
        return results
            .first { (_, timePeriod) in
                timePeriod.startDate <= now && timePeriod.endDate >= now
            }
            .map { (term, timePeriod) in
                TermWithPeriod(term: term, timePeriod: timePeriod)
            }
    }
}

/// Fetch terms within a date range
private struct FetchTermsByDateRangeRequest: FetchKeyRequest {
    typealias Value = [TermWithPeriod]
    let range: ClosedRange<Date>

    func fetch(_ db: Database) throws -> [TermWithPeriod] {
        // Fetch all, filter in Swift
        // (Overlap logic is complex for query builder: (start <= rangeEnd AND end >= rangeStart))
        let results = try GoalTerm.all
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        // Filter to terms whose periods overlap with the range
        return results
            .filter { (_, timePeriod) in
                // Ranges overlap if: start <= rangeEnd AND end >= rangeStart
                timePeriod.startDate <= range.upperBound && timePeriod.endDate >= range.lowerBound
            }
            .map { (term, timePeriod) in
                TermWithPeriod(term: term, timePeriod: timePeriod)
            }
            .sorted { $0.term.termNumber > $1.term.termNumber }
    }
}

/// Check if term number exists
private struct ExistsByTermNumberRequest: FetchKeyRequest {
    typealias Value = Bool
    let termNumber: Int

    func fetch(_ db: Database) throws -> Bool {
        let count = try #sql(
            """
            SELECT COUNT(*)
            FROM \(GoalTerm.self)
            WHERE \(GoalTerm.termNumber) = \(bind: termNumber)
            """,
            as: Int.self
        ).fetchOne(db) ?? 0
        return count > 0
    }
}

/// Check if term exists by ID
private struct ExistsByIdRequest: FetchKeyRequest {
    typealias Value = Bool
    let id: UUID

    func fetch(_ db: Database) throws -> Bool {
        try GoalTerm.find(id).fetchOne(db) != nil
    }
}

/// Fetch terms for export with denormalized TimePeriod data and goal assignments
///
/// EXPORT PATTERN:
/// 1. JOIN terms + time periods (get date boundaries)
/// 2. Bulk fetch goal assignments (avoid N+1)
/// 3. Apply date filters if provided
/// 4. Assemble denormalized TermExport records
private struct FetchTermsForExportRequest: FetchKeyRequest {
    typealias Value = [TermExport]

    let startDate: Date?
    let endDate: Date?

    func fetch(_ db: Database) throws -> [TermExport] {
        // Step 1: Fetch all terms + time periods (simple JOIN)
        let termPeriods = try GoalTerm.all
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        // Step 2: Apply date filtering if provided
        let filteredTermPeriods = termPeriods.filter { (term, timePeriod) in
            // Date overlap logic (like FetchTermsByDateRangeRequest)
            if let start = startDate, let end = endDate {
                // Both filters: period must overlap [start, end]
                return timePeriod.startDate <= end && timePeriod.endDate >= start
            } else if let start = startDate {
                // Only start filter: period.endDate >= start
                return timePeriod.endDate >= start
            } else if let end = endDate {
                // Only end filter: period.startDate <= end
                return timePeriod.startDate <= end
            } else {
                // No filters: include all
                return true
            }
        }

        // Step 3: Bulk fetch goal assignments (avoid N+1 problem)
        let termIds = filteredTermPeriods.map { $0.0.id }
        let allAssignments = try TermGoalAssignment.all
            .where { termIds.contains($0.termId) }
            .fetchAll(db)

        // Group by termId for O(1) lookup
        let assignmentsByTerm = Dictionary(
            grouping: allAssignments,
            by: { $0.termId }
        )

        // Step 4: Assemble denormalized export records
        return filteredTermPeriods.map { (term, timePeriod) in
            let goalIds = assignmentsByTerm[term.id]?
                .map { $0.goalId }
                .sorted { $0.uuidString < $1.uuidString }  // Deterministic order for testing

            return TermExport(
                id: term.id,
                termNumber: term.termNumber,
                theme: term.theme,
                reflection: term.reflection,
                status: term.status?.rawValue,
                timePeriodId: timePeriod.id,
                timePeriodTitle: timePeriod.title,
                startDate: timePeriod.startDate,
                endDate: timePeriod.endDate,
                assignedGoalIds: goalIds
            )
        }
    }
}

// MARK: - Implementation Notes

// QUERY PATTERN CHOICE
//
// TimePeriodRepository uses query builders for JOINs because:
// 1. Simple 1:1 relationship (GoalTerm + TimePeriod)
// 2. Query builder already optimal for this case
// 3. Type safety during development
// 4. Matches TermsQuery.swift pattern (proven in production)
//
// Uses #sql for:
// - Existence checks (COUNT queries)
// - Future aggregations if needed (goals per term, etc.)
//
// Date filtering done in Swift because:
// - Overlap logic is simpler to read in Swift
// - Query builder date comparison syntax is verbose
// - Performance fine for typical term counts (<100)
//
// SWIFT 6 CONCURRENCY
//
// - NO @MainActor: Database I/O should run in background
// - Repository is Sendable-safe (immutable state, final class)
// - ViewModels await results on main actor automatically
// - Pattern matches other repositories
