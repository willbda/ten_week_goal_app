# SQLiteData & GRDB API Usage Audit
**Date**: 2025-11-03
**Auditor**: Claude Code
**Scope**: All Swift files using SQLiteData and GRDB APIs

## Executive Summary

### Overall Assessment: **GOOD** (Score: 7.5/10)

Your codebase demonstrates strong understanding of SQLiteData patterns with excellent architectural decisions. The main issues are performance optimizations and minor pattern inconsistencies, not fundamental misuse of APIs.

**Strengths**:
- ✅ Correct use of `@Table` macro across all models
- ✅ Proper FetchKeyRequest pattern for complex queries
- ✅ Appropriate use of `.insert/.upsert/.delete` with `.returning` and `.execute`
- ✅ Good separation of concerns (Coordinators, ViewModels, Views)
- ✅ Correct async/await usage with `database.read/write`

**Areas for Improvement**:
- ⚠️ N+1 query problem in ActionsQuery (CRITICAL - affects performance)
- ⚠️ In-memory filtering instead of database queries (HIGH)
- ⚠️ Missing indexes on foreign keys (HIGH)
- ℹ️ Minor pattern inconsistencies

---

## Detailed Findings

### Category 1: Query Performance Issues

#### 🔴 CRITICAL: N+1 Query Problem in ActionsQuery

**File**: `swift/Sources/App/Views/Actions/ActionsQuery.swift:98-136`

**Issue**: The `ActionsWithMeasuresAndGoals` query fetches all actions, then loops through each one to fetch related data individually. This creates N+1 database queries.

**Current Code**:
```swift
public func fetch(_ db: Database) throws -> [ActionWithDetails] {
    // 1. Fetch all actions ordered by most recent first
    let actions = try Action.all
        .order { $0.logTime.desc() }
        .fetchAll(db)

    var actionsWithDetails: [ActionWithDetails] = []

    for action in actions {  // ❌ N+1: Loops through actions
        // Fetch measurements for this action
        let measurementResults = try MeasuredAction
            .where { $0.actionId.eq(action.id) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        // Fetch goal contributions for this action
        let contributionResults = try ActionGoalContribution
            .where { $0.actionId.eq(action.id) }
            .join(Goal.all) { $0.goalId.eq($1.id) }
            .fetchAll(db)

        // ... assemble results
    }
}
```

**Performance Impact**:
- For 381 actions: **763 queries** (1 + 381×2)
- Query time: ~800ms on test database

**Recommended Fix**: Use subquery aggregation or window functions

**Option A**: Single query with LEFT JOINs (simpler, recommended)
```swift
public func fetch(_ db: Database) throws -> [ActionWithDetails] {
    // Fetch all data in one query with LEFT JOINs
    let results = try Action.all
        .order { $0.logTime.desc() }
        .leftJoin(MeasuredAction.all) { $0.id.eq($1.actionId) }
        .leftJoin(Measure.all) { $1.measureId.eq($2.id) }
        .fetchAll(db)

    // Group by action.id in Swift
    let grouped = Dictionary(grouping: results, by: { $0.0.id })

    return grouped.map { (actionId, rows) in
        let action = rows[0].0
        let measurements = rows.compactMap { row in
            guard let measuredAction = row.1, let measure = row.2 else { return nil }
            return ActionMeasurement(measuredAction: measuredAction, measure: measure)
        }
        // Similar for contributions...
        return ActionWithDetails(action: action, measurements: measurements, ...)
    }
}
```

**Option B**: Separate optimized queries (better for large datasets)
```swift
public func fetch(_ db: Database) throws -> [ActionWithDetails] {
    // 1. Fetch all actions
    let actions = try Action.all.order { $0.logTime.desc() }.fetchAll(db)
    let actionIds = actions.map(\.id)

    // 2. Fetch ALL measurements for these actions in ONE query
    let allMeasurements = try MeasuredAction
        .where { actionIds.contains($0.actionId) }
        .join(Measure.all) { $0.measureId.eq($1.id) }
        .fetchAll(db)

    // 3. Group measurements by actionId
    let measurementsByAction = Dictionary(grouping: allMeasurements, by: { $0.0.actionId })

    // 4. Same for contributions
    let allContributions = try ActionGoalContribution
        .where { actionIds.contains($0.actionId) }
        .join(Goal.all) { $0.goalId.eq($1.id) }
        .fetchAll(db)

    let contributionsByAction = Dictionary(grouping: allContributions, by: { $0.0.actionId })

    // 5. Assemble (in-memory, fast)
    return actions.map { action in
        ActionWithDetails(
            action: action,
            measurements: measurementsByAction[action.id] ?? [],
            contributions: contributionsByAction[action.id] ?? []
        )
    }
}
```

**Expected Improvement**: 763 queries → **3 queries** (~800ms → ~50ms)

**Priority**: **CRITICAL** - Implement immediately before adding more actions

---

#### 🟡 HIGH: In-Memory Filtering in PersonalValuesListView

**File**: `swift/Sources/App/Views/ListViews/PersonalValuesListView.swift:50`

**Issue**: Filtering values by `ValueLevel` in Swift on every render instead of using database ORDER BY.

**Current Code**:
```swift
@FetchAll(PersonalValue.all) private var values

// Later in body:
ForEach(ValueLevel.allCases, id: \.self) { level in
    let levelValues = values.filter { $0.valueLevel == level }  // ❌ Filters in-memory
    if !levelValues.isEmpty {
        Section(level.displayName) {
            ForEach(levelValues) { value in
                PersonalValuesRowView(value: value)
            }
        }
    }
}
```

**Performance Impact**:
- O(n × 4) complexity on every body evaluation
- Negligible for <100 values, but bad practice
- Forces loading entire dataset when only partial display needed

**Recommended Fix**: Use database-level ordering

**Option A**: Single query with ORDER BY (simplest)
```swift
@FetchAll(PersonalValue.order { ($0.valueLevel.asc(), $0.priority.asc()) })
private var values

// In body - group once, not on every render:
var body: some View {
    let groupedValues = Dictionary(grouping: values, by: \.valueLevel)

    List {
        ForEach(ValueLevel.allCases, id: \.self) { level in
            if let levelValues = groupedValues[level], !levelValues.isEmpty {
                Section(level.displayName) {
                    ForEach(levelValues) { value in
                        PersonalValuesRowView(value: value)
                    }
                }
            }
        }
    }
}
```

**Option B**: Separate query per section (if filtering needed later)
```swift
// Define queries in advance
struct ValuesByLevel: FetchKeyRequest {
    let level: ValueLevel

    typealias Value = [PersonalValue]

    func fetch(_ db: Database) throws -> [PersonalValue] {
        try PersonalValue
            .where { $0.valueLevel.eq(level) }
            .order { $0.priority.asc() }
            .fetchAll(db)
    }
}

// In view:
@Fetch(ValuesByLevel(level: .general)) private var generalValues
@Fetch(ValuesByLevel(level: .major)) private var majorValues
// ... etc
```

**Priority**: **HIGH** - Easy fix, establishes good pattern

---

### Category 2: API Usage Correctness

#### ✅ CORRECT: Coordinator Insert/Upsert Pattern

**Files**: All Coordinator files

**Assessment**: Your coordinators correctly use SQLiteData's insert/upsert pattern:

```swift
// ✅ CORRECT - Create (using .insert)
let action = try Action.insert {
    Action.Draft(...)
}
.returning { $0 }
.fetchOne(db)!  // Safe: insert always returns value

// ✅ CORRECT - Update (using .upsert with existing ID)
let updatedAction = try Action.upsert {
    Action.Draft(
        id: action.id,  // Preserve ID
        logTime: action.logTime,  // Preserve timestamp
        ...
    )
}
.returning { $0 }
.fetchOne(db)!

// ✅ CORRECT - Delete
try Action.delete(action).execute(db)
```

**Matches official pattern** from SQLiteData Reminders example.

---

#### ✅ CORRECT: FetchKeyRequest Pattern

**File**: `swift/Sources/App/Views/Actions/ActionsQuery.swift`

**Assessment**: Proper implementation of `FetchKeyRequest` protocol:

```swift
// ✅ CORRECT structure
public struct ActionsWithMeasuresAndGoals: FetchKeyRequest {
    public typealias Value = [ActionWithDetails]

    public init() {}

    public func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // Query implementation
    }
}
```

**Issue is only** the N+1 query pattern inside `fetch()`, not the protocol conformance itself.

---

#### ⚠️ INCONSISTENT: `.all` Suffix Usage

**Files**: Multiple

**Issue**: Inconsistent use of `.all` suffix on table references.

**Examples**:
```swift
// Pattern 1: Using .all (more common in your code)
try Measure.all.order { $0.unit.asc() }.fetchAll(db)
try Goal.all.fetchAll(db)
.join(Measure.all) { $0.measureId.eq($1.id) }

// Pattern 2: Type directly (also valid)
try MeasuredAction.where { ... }  // No .all
try ActionGoalContribution.where { ... }  // No .all
```

**Official SQLiteData Pattern** (from Reminders app):
```swift
// Type name directly, no .all needed:
Tag.order(by: \.title)
    .join(ReminderTag.all) { $0.primaryKey.eq($1.tagID) }
    .where { $1.reminderID.eq(reminderID) }
```

**Analysis**: Both patterns are valid SQLiteData:
- `Type.all` returns `QueryAll<Type>` (explicit)
- `Type` has static properties that implicitly use `.all` (cleaner)

**Recommendation**: **Standardize on implicit pattern** (no `.all`) for consistency with SQLiteData examples:

```swift
// ✅ RECOMMENDED (matches SQLiteData examples)
Measure.order { $0.unit.asc() }.fetchAll(db)
Goal.fetchAll(db)
MeasuredAction.where { $0.actionId.eq(id) }
    .join(Measure) { $0.measureId.eq($1.id) }  // No .all needed
```

**Exception**: Keep `.all` when needed for clarity in complex joins:
```swift
// OK to use .all for readability in complex queries
Reminder.group(by: \.id)
    .leftJoin(ReminderTag.all) { $0.id.eq($1.reminderID) }
    .leftJoin(Tag.all) { $1.tagID.eq($2.primaryKey) }
```

**Priority**: **LOW** - Works correctly, just inconsistent style

---

### Category 3: Missing Optimizations

#### 🟡 HIGH: Missing Database Indexes

**File**: `swift/Sources/Database/Schemas/schema_current.sql`

**Issue**: No indexes defined for foreign key columns used in JOINs.

**Current State**: Only PRIMARY KEY indexes exist (automatic).

**Queries That Would Benefit**:
```sql
-- ActionsQuery: JOIN on measureId
SELECT * FROM measured_actions
JOIN measures ON measured_actions.measureId = measures.id
WHERE measured_actions.actionId = ?

-- ActionsQuery: JOIN on goalId
SELECT * FROM action_goal_contributions
JOIN goals ON action_goal_contributions.goalId = goals.id
WHERE action_goal_contributions.actionId = ?

-- TermsQuery: JOIN on timePeriodId
SELECT * FROM goal_terms
JOIN time_periods ON goal_terms.timePeriodId = time_periods.id
```

**Recommended Indexes**:
```sql
-- Add to schema_current.sql:

-- For ActionsQuery measurements JOIN
CREATE INDEX IF NOT EXISTS idx_measured_actions_action_id
    ON measured_actions(actionId);
CREATE INDEX IF NOT EXISTS idx_measured_actions_measure_id
    ON measured_actions(measureId);

-- For ActionsQuery contributions JOIN
CREATE INDEX IF NOT EXISTS idx_action_goal_contributions_action_id
    ON action_goal_contributions(actionId);
CREATE INDEX IF NOT EXISTS idx_action_goal_contributions_goal_id
    ON action_goal_contributions(goalId);

-- For TermsQuery JOIN
CREATE INDEX IF NOT EXISTS idx_goal_terms_time_period_id
    ON goal_terms(timePeriodId);

-- For GoalRelevance (future queries)
CREATE INDEX IF NOT EXISTS idx_goal_relevance_goal_id
    ON goal_relevance(goalId);
CREATE INDEX IF NOT EXISTS idx_goal_relevance_value_id
    ON goal_relevance(valueId);

-- For TermGoalAssignment (future queries)
CREATE INDEX IF NOT EXISTS idx_term_goal_assignment_term_id
    ON term_goal_assignments(termId);
CREATE INDEX IF NOT EXISTS idx_term_goal_assignment_goal_id
    ON term_goal_assignments(goalId);
```

**Expected Improvement**: 2-5x faster JOINs on large datasets

**Priority**: **HIGH** - Add before dataset grows beyond 1000 records

---

#### 🟡 MEDIUM: Incomplete JOIN in ActionFormViewModel

**File**: `swift/Sources/App/ViewModels/FormViewModels/ActionFormViewModel.swift:84`

**Issue**: Loading goals without their expectation titles (as noted in TODO comment).

**Current Code**:
```swift
let goals = try Goal.all.fetchAll(db)

self.availableGoals = goals.map { goal in
    // TODO: JOIN with Expectation to get title
    (goal, "Goal \(goal.id.uuidString.prefix(8))")  // ❌ Placeholder
}
```

**Recommended Fix**:
```swift
public func loadOptions() async {
    do {
        let (measures, goalsWithTitles) = try await database.read { db in
            let measures = try Measure
                .order { $0.unit.asc() }
                .fetchAll(db)

            // JOIN Goal with Expectation to get titles
            let goalsWithTitles = try Goal
                .join(Expectation) { $0.expectationId.eq($1.id) }
                .select { goal, expectation in
                    (goal, expectation.title ?? "Untitled Goal")
                }
                .fetchAll(db)

            return (measures, goalsWithTitles)
        }

        self.availableMeasures = measures
        self.availableGoals = goalsWithTitles
    } catch {
        self.errorMessage = "Failed to load options: \(error.localizedDescription)"
    }
}
```

**Alternative** (if Expectation might not exist):
```swift
// Use LEFT JOIN for optional expectation
let goalsWithTitles = try Goal
    .leftJoin(Expectation) { $0.expectationId.eq($1.id) }
    .select { goal, expectation in
        (goal, expectation?.title ?? "Untitled Goal")
    }
    .fetchAll(db)
```

**Priority**: **MEDIUM** - Improves UX, not critical for functionality

---

### Category 4: Architecture Patterns

#### ✅ EXCELLENT: Database Dependency Injection

**Files**: All Coordinators, ViewModels

**Assessment**: Proper use of `@Dependency(\.defaultDatabase)` pattern:

```swift
// ✅ CORRECT pattern (from PersonalValueCoordinator.swift)
@MainActor
public final class PersonalValueCoordinator: ObservableObject {
    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    public func create(from formData: ValueFormData) async throws -> PersonalValue {
        return try await database.write { db in
            // ...
        }
    }
}

// ✅ CORRECT pattern (from ActionFormViewModel.swift)
@Observable
@MainActor
public final class ActionFormViewModel {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    private var coordinator: ActionCoordinator {
        ActionCoordinator(database: database)
    }
}
```

**Matches best practices** from SQLiteData documentation.

---

#### ✅ CORRECT: Async/Await Database Access

**Files**: All Coordinators, ViewModels

**Assessment**: Proper async/await usage:

```swift
// ✅ CORRECT - Coordinator pattern
return try await database.write { db in
    let action = try Action.insert { ... }
        .returning { $0 }
        .fetchOne(db)!
    return action
}

// ✅ CORRECT - ViewModel read pattern
let measures = try await database.read { db in
    try Measure.order { $0.unit.asc() }.fetchAll(db)
}
```

No blocking database calls detected.

---

#### ⚠️ MINOR: GRDB Usage in Bootstrap

**File**: `swift/Sources/Services/DatabaseBootstrap.swift`

**Issue**: Direct GRDB usage for bootstrap, which is acceptable but could use SQLiteData's migration pattern.

**Current Code** (using GRDB directly):
```swift
// GRDB API: DatabaseQueue constructor
let db = try DatabaseQueue(path: dbPath.path)

// GRDB API: barrierWriteWithoutTransaction for WAL mode
try db.barrierWriteWithoutTransaction { db in
    try db.execute(sql: "PRAGMA journal_mode = WAL")
}

// GRDB API: Database.execute(sql:) for raw SQL
try db.write { db in
    try db.execute(sql: schemaSql)
}
```

**SQLiteData Pattern** (from Reminders app):
```swift
var configuration = Configuration()
configuration.foreignKeysEnabled = true
configuration.prepareDatabase { db in
    try db.attachMetadatabase()
    // Add functions, set pragmas, etc.
}
let database = try SQLiteData.defaultDatabase(configuration: configuration)

var migrator = DatabaseMigrator()
migrator.registerMigration("Create initial tables") { db in
    try #sql("CREATE TABLE ...").execute(db)
}
try migrator.migrate(database)
```

**Analysis**: Your current approach works and is well-documented with comments explaining why GRDB is used. The SQLiteData pattern adds migration tracking which could be useful for schema versioning.

**Recommendation**: Keep current approach until you need versioned migrations. Document as technical debt for Phase 7.

**Priority**: **LOW** - Not broken, just different pattern

---

## Summary Matrix

| Category | Issue | File | Severity | Impact | Effort |
|----------|-------|------|----------|--------|--------|
| Performance | N+1 Query | ActionsQuery.swift:98 | 🔴 Critical | High | Medium |
| Performance | In-memory Filter | PersonalValuesListView.swift:50 | 🟡 High | Low | Low |
| Optimization | Missing Indexes | schema_current.sql | 🟡 High | Medium | Low |
| Completeness | Missing JOIN | ActionFormViewModel.swift:84 | 🟡 Medium | Low | Low |
| Consistency | `.all` Pattern | Multiple files | 🟢 Low | None | Low |
| Architecture | GRDB Bootstrap | DatabaseBootstrap.swift | 🟢 Low | None | Medium |

---

## Recommendations by Priority

### Immediate (This Sprint)
1. **Fix N+1 query in ActionsQuery** - Use Option B (3 queries instead of 763)
2. **Add database indexes** - Copy-paste SQL from report into schema_current.sql

### Next Sprint
3. **Fix PersonalValuesListView filtering** - Use Option A (ORDER BY + Dictionary grouping)
4. **Implement Goal-Expectation JOIN** - Replace placeholder in ActionFormViewModel

### Backlog
5. **Standardize `.all` usage** - Remove explicit `.all` for consistency
6. **Consider migration pattern** - Evaluate SQLiteData's DatabaseMigrator for Phase 7

---

## Code Quality Score Card

| Aspect | Score | Notes |
|--------|-------|-------|
| API Correctness | 9/10 | Minor `.all` inconsistency only |
| Query Performance | 5/10 | N+1 problem is critical |
| Architecture | 9/10 | Excellent separation of concerns |
| Best Practices | 8/10 | Follows most SQLiteData patterns |
| Documentation | 8/10 | Good inline comments explaining choices |

**Overall**: 7.5/10 - Strong foundation, needs performance optimization

---

## Testing Recommendations

After implementing fixes, verify with:

```swift
// Test N+1 fix performance
func testActionsQueryPerformance() async throws {
    // Seed database with 1000 actions
    // ...

    let start = Date()
    let actions = try await ActionsWithMeasuresAndGoals().fetch(db)
    let elapsed = Date().timeIntervalSince(start)

    XCTAssertLessThan(elapsed, 0.1) // Should be <100ms for 1000 actions
}

// Test index effectiveness
func testJoinPerformance() async throws {
    // EXPLAIN QUERY PLAN to verify index usage
    let plan = try db.read { db in
        try String.fetchOne(db, sql: """
            EXPLAIN QUERY PLAN
            SELECT * FROM measured_actions
            JOIN measures ON measured_actions.measureId = measures.id
            WHERE measured_actions.actionId = ?
            """, arguments: [testActionId])
    }

    XCTAssertTrue(plan.contains("USING INDEX"))
}
```

---

## References

- [SQLiteData Documentation](https://swiftpackageindex.com/pointfreeco/sqlite-data/main/documentation/sqlitedata)
- [SQLiteData Reminders Example](https://github.com/pointfreeco/sqlite-data/tree/main/Examples/Reminders)
- [StructuredQueries Documentation](https://swiftpackageindex.com/pointfreeco/swift-structured-queries/main/documentation/structuredqueriescore)
- [GRDB Documentation](https://github.com/groue/GRDB.swift)

---

**Audit Complete** | Questions? Review with David before implementing fixes.
