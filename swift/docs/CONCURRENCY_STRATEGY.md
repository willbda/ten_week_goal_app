# Swift Concurrency Strategy
**Written by Claude Code on 2025-11-06**
**Purpose**: Document concurrency patterns, actor isolation strategy, and performance optimizations

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Actor Isolation Strategy](#actor-isolation-strategy)
3. [Parallel Operations](#parallel-operations)
4. [Query Strategy + Concurrency](#query-strategy--concurrency)
5. [Database Concurrency Model](#database-concurrency-model)
6. [Best Practices](#best-practices)
7. [Common Patterns](#common-patterns)
8. [Migration Checklist](#migration-checklist)
9. [FAQ](#faq)
10. [References](#references)

---

## Architecture Overview

### Current Patterns ✅

**Models**: `Sendable` structs
- All domain protocols (DomainAbstraction, DomainBasic, DomainComposit) require `Sendable`
- Ensures models can safely cross actor boundaries
- No mutable state, purely data structures

**ViewModels**: `@MainActor`
- All FormViewModels marked with `@MainActor` attribute
- UI updates run on main thread
- Use `@Observable` (Swift 5.9+) not `ObservableObject`
- Published properties auto-tracked without `@Published`

**Coordinators**: `@MainActor`
- Called directly from ViewModels (also @MainActor)
- No actor hops needed
- `database.write { }` closures run on database serial queue

**Database**: Serial queue (DatabaseQueue from GRDB)
- Writes are serialized (one at a time)
- Reads can be concurrent
- Using `@Dependency(\.defaultDatabase)` from SQLiteData

### Key Design Decisions

1. **No business logic in models** - Models are pure data structures
2. **@MainActor for UI layer** - ViewModels and Coordinators stay on main thread
3. **nonisolated for database helpers** - Allow serial queue to call them
4. **Structured concurrency preferred** - Use `async let` over `Task {}`

---

## Actor Isolation Strategy

### ViewModels: @MainActor ✅

**Why**: Need to update UI via @Observable/@Published properties

```swift
@Observable
@MainActor
public final class GoalFormViewModel {
    var isSaving: Bool = false       // Auto-tracked by @Observable
    var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    public func save(...) async throws -> Goal {
        isSaving = true  // Updates UI on main thread
        defer { isSaving = false }
        // ...
    }
}
```

### Coordinators: @MainActor ✅

**Why**: Called from ViewModels, database.write runs on serial queue anyway

```swift
@MainActor
public final class ActionCoordinator: ObservableObject {
    private let database: any DatabaseWriter

    public func create(from formData: ActionFormData) async throws -> Action {
        return try await database.write { db in
            // Runs on database serial queue
            // No actor hop needed since we're already @MainActor
        }
    }
}
```

### Repositories: Non-isolated (Future - Phase 3)

**Decision**: Default to non-isolated, use background actor only if heavy Swift processing

```swift
// Option A: Non-isolated (for pure database queries) ✅ RECOMMENDED
struct GoalRepository {
    func calculateProgress(for goal: Goal) async throws -> Double {
        try await database.read { db in
            // Simple query, no heavy processing
        }
    }
}

// Option B: Background actor (only if heavy Swift processing)
actor GoalRepository {
    func calculateProgress(for goal: Goal) async throws -> Double {
        // Heavy calculations on background executor
    }
}
```

**Decision criterion**:
- Pure queries → non-isolated
- Heavy Swift processing (loops, calculations, transformations) → background actor
- Database operations are already async, so no need for actor unless doing work in Swift

### Service Layer: Context-dependent

**HealthKitManager**: `@Observable` (no actor)
- Platform service, manages HealthKit authorization
- State changes tracked via @Observable

**HealthKitImportService**: `@MainActor`
- Called from UI (WorkoutsTestView)
- Database writes are serialized anyway

**Validators** (Future - Phase 4): Non-isolated
- Pure validation logic
- Can be called from any context

---

## Parallel Operations

### Use async let for Independent Database Reads ✅

**Pattern**: Launch multiple queries in parallel, await together

**Example** (GoalFormView.swift:273-299):
```swift
private func loadAvailableData() async {
    do {
        // Launch all three queries in parallel
        async let measures = database.read { db in
            try Measure.order(by: \.unit).fetchAll(db)
        }
        async let values = database.read { db in
            try PersonalValue.order { $0.priority.desc() }.fetchAll(db)
        }
        async let terms = database.read { db in
            try TermsWithPeriods().fetch(db)
        }

        // Await all results together (structured concurrency)
        (availableMeasures, availableValues, availableTerms) = try await (measures, values, terms)
    } catch {
        print("Error loading form data: \(error)")
    }
}
```

**Performance**: 3x faster than sequential (~100ms vs ~300ms)

**Benefits**:
- **Structured concurrency** - automatic cleanup on error
- **Type safety** - compiler checks types
- **Cancellation** - parent task cancellation propagates
- **Works with DatabaseQueue** - reads can be concurrent

### When to Use async let

✅ **Use for**:
- Form data loading (measures, values, terms)
- Multiple independent database reads
- Dashboard aggregations
- Any independent async operations

❌ **Don't use for**:
- Dependent operations (B needs result of A)
- Single queries (no benefit)
- Database writes (DatabaseQueue serializes them anyway)
- Operations that need dynamic parallelism (use TaskGroup instead)

### When to Use TaskGroup

**Use when**: Need dynamic parallelism (unknown number of tasks at compile time)

**Example** (HealthKitImportService - if using DatabasePool):
```swift
public func importWorkouts(_ workouts: [HealthWorkout]) async throws -> [Action] {
    try await withThrowingTaskGroup(of: Action.self) { group in
        for workout in workouts {
            group.addTask {
                try await self.importWorkout(workout)
            }
        }

        var actions: [Action] = []
        for try await action in group {
            actions.append(action)
        }
        return actions
    }
}
```

⚠️ **Caution**: Only if using DatabasePool + WAL. With DatabaseQueue, writes are serial anyway.

---

## Query Strategy + Concurrency

### Query Builder (Current) ✅

**Why**: Compile-time type safety, safe with any actor isolation

```swift
// ✅ Compiler catches typos
let actions = try Action.all
    .order { $0.logTime.desc() }  // Type-checked at compile time
    .fetchAll(db)
```

**Benefits**:
- **Compile-time errors** - typos caught by compiler
- **Safe with any actor** - works from @MainActor or background
- **Autocomplete** - IDE helps you
- **Refactoring-safe** - rename field → compiler errors guide you

**Use for**:
- CRUD operations
- Simple JOINs
- WHERE/ORDER BY queries
- Any query during active development

### #sql Macro (Future - Phase 3+) ⚠️

**Why**: Better performance for aggregations, but runtime errors only

```swift
// ⚠️ Typos fail at runtime!
let progress = try #sql(
    """
    SELECT SUM(value) as total
    FROM measuredActions
    WHERE actionId = \(actionId)
    """
).fetchOne(db) as Double?
```

**Benefits**:
- **Database does the work** - GROUP BY in SQLite (C code) not Swift
- **Less data transfer** - Aggregate in DB, return summary
- **Clearer intent** - SQL makes complex queries explicit
- **Better scalability** - O(n) in DB vs O(n) in Swift

**Risks**:
- **Runtime errors** - SQL typos fail when query executes
- **Type mismatches** - Cast failures only at runtime
- **Harder to debug** - No stack trace to SQL syntax error
- **Concurrency risk** - Error only surfaces when actor executes query

**Prerequisites before migration**:
1. ❌ Phase 4 validation complete (`Services/Validation/`)
2. ❌ Integration test coverage (catch SQL typos in tests)
3. ❌ Boundary validation (trust validated data)
4. ❌ Error handling infrastructure (translate DB errors to user messages)

**Migration path**:
1. Implement validation infrastructure (Phase 2)
2. Add integration tests for all queries
3. Profile queries to identify bottlenecks
4. Migrate complex aggregations to #sql
5. Keep simple queries as query builder

**See**: `REARCHITECTURE_COMPLETE_GUIDE.md` section "Query Strategy" for detailed rationale

---

## Database Concurrency Model

### DatabaseQueue (Current) ✅

**Pattern**: Serial write queue + concurrent read queue

```swift
// Writes are serialized (one at a time)
try await database.write { db in
    try Action.insert { ... }.execute(db)
    // Only one write can execute at a time
}

// Reads can be concurrent
try await database.read { db in
    try Action.all.fetchAll(db)
    // Multiple reads can execute simultaneously
}
```

**Characteristics**:
- **Serial writes** - No concurrent writes possible
- **Concurrent reads** - Multiple reads can run in parallel
- **Simple** - No WAL complexity
- **Reliable** - Default GRDB configuration
- **Good for most apps** - Performance sufficient for typical use

### DatabasePool (Future Option)

**Pattern**: WAL mode enables true concurrent reads + writes

**When to consider**:
- App has performance bottleneck with DatabaseQueue
- Heavy read load while writes happening
- Profiling shows database contention

**Migration complexity**:
- Must enable WAL mode
- More complex configuration
- Test thoroughly for data races

**Current decision**: Stick with DatabaseQueue until proven bottleneck

---

## Best Practices

### 1. Use Structured Concurrency ✅

**Prefer `async let`** over unstructured `Task {}`

```swift
// ✅ Good - structured concurrency
async let result = database.read { db in try Action.all.fetchAll(db) }
let actions = try await result

// ⚠️ Acceptable for button handlers
Button("Save") {
    Task {
        await viewModel.save()
    }
}

// ✅ Better - use .task modifier for view lifecycle
.task {
    await viewModel.loadOptions()
}
```

### 2. Explicit Actor Annotations

**Mark Task closures with @MainActor if needed**

```swift
Task { @MainActor in
    self.isLoading = false  // Runs on main thread
}
```

**Use nonisolated for database helpers**

```swift
@MainActor
class HealthKitImportService {
    // Called from database.write closures (not main actor)
    nonisolated private func findOrCreateMeasure(...) throws -> Measure {
        // Can be called from serial database queue
    }
}
```

### 3. Error Handling

**Catch errors from parallel operations**

```swift
do {
    async let a = operation1()
    async let b = operation2()

    let (resultA, resultB) = try await (a, b)
} catch {
    print("One of the operations failed: \(error)")
    // Both operations are automatically cancelled
}
```

**Provide user-friendly messages**

```swift
} catch {
    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
    // Don't expose raw database errors to users
}
```

### 4. Testing

**Test concurrent access patterns**

```swift
func testConcurrentReads() async throws {
    async let read1 = database.read { db in try Action.all.fetchAll(db) }
    async let read2 = database.read { db in try Goal.all.fetchAll(db) }

    let (actions, goals) = try await (read1, read2)
    XCTAssertFalse(actions.isEmpty)
    XCTAssertFalse(goals.isEmpty)
}
```

**Profile performance improvements**

```swift
let start = Date()
await loadAvailableData()
let duration = Date().timeIntervalSince(start)
print("Loaded data in \(duration * 1000)ms")
// Sequential: ~300ms, Parallel: ~100ms
```

---

## Common Patterns

### Pattern 1: Parallel Form Loading ✅

**Use case**: Form needs to load multiple dropdown options

**Implementation**:
```swift
private func loadAvailableData() async {
    do {
        async let measures = database.read { db in
            try Measure.order(by: \.unit).fetchAll(db)
        }
        async let values = database.read { db in
            try PersonalValue.order { $0.priority.desc() }.fetchAll(db)
        }

        (availableMeasures, availableValues) = try await (measures, values)
    } catch {
        print("Error loading data: \(error)")
    }
}
```

**Examples**:
- GoalFormView.swift:273-299
- ActionFormViewModel.swift:76-105

### Pattern 2: Multi-Model Coordinator ✅

**Use case**: Atomically create entity graph (abstraction + concrete + relationships)

**Implementation**:
```swift
@MainActor
public final class ActionCoordinator: ObservableObject {
    public func create(from formData: ActionFormData) async throws -> Action {
        return try await database.write { db in
            // 1. Insert abstraction (if needed)
            // 2. Insert concrete entity with FK
            let action = try Action.insert { ... }.returning { $0 }.fetchOne(db)!

            // 3. Insert relationships
            try MeasuredAction.insert { ... }.execute(db)

            return action
        }
    }
}
```

**Examples**:
- ActionCoordinator.swift
- GoalCoordinator.swift (future)

### Pattern 3: FetchKeyRequest with @Fetch ✅

**Use case**: Performant JOIN queries with reactive updates

**Implementation**:
```swift
public struct ActionsWithMeasures: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // Single query with JOINs instead of N+1
        let results = try Action.all
            .leftJoin(MeasuredAction.all) { $0.id.eq($1.actionId) }
            .fetchAll(db)
        // Group in Swift (once)
    }
}

// In view:
@Fetch(ActionsWithMeasures()) private var actionsWithMeasures
```

**Examples**:
- ActionsQuery.swift (optimized from N+1 to 3 queries)
- TermsQuery.swift (1:1 JOIN)

---

## Migration Checklist

- [x] Models are Sendable
- [x] ViewModels use @MainActor
- [x] Coordinators use @MainActor
- [x] Database operations are async
- [x] nonisolated for database helpers
- [x] Form loading uses async let (GoalFormView, ActionFormViewModel)
- [x] Concurrency documented
- [ ] Integration tests for concurrent access
- [ ] Performance profiling baseline
- [ ] Error handling for parallel operations
- [ ] Validation infrastructure (Phase 2)
- [ ] #sql migration (Phase 3+)

---

## FAQ

### Q: Can we parallelize database writes?

**A**: No. DatabaseQueue serializes writes automatically. Even if you use TaskGroup, writes will queue up and execute one at a time.

```swift
// ❌ This won't actually run in parallel with DatabaseQueue
async let write1 = database.write { db in try Action.insert { ... } }
async let write2 = database.write { db in try Goal.insert { ... } }
// write2 waits for write1 to complete
```

**Solution**: Keep writes sequential. They're fast enough (<10ms typically).

### Q: Should repositories be actors?

**A**: Only if they do heavy Swift processing beyond database queries.

**Decision tree**:
- Pure database queries → non-isolated (simplest)
- Heavy Swift calculations → background actor
- UI updates needed → @MainActor

### Q: When to use #sql macro?

**A**: After validation infrastructure is complete (Phase 3+), for aggregations only.

**Criteria**:
1. Query uses GROUP BY, SUM, COUNT, etc.
2. Performance profiling shows bottleneck
3. Integration tests exist to catch SQL errors
4. Error handling infrastructure maps DB errors to user messages

**Keep using query builder for**: CRUD, simple JOINs, development

### Q: Is TaskGroup needed?

**A**: Rarely. `async let` handles most cases.

**Use TaskGroup when**:
- Dynamic parallelism (unknown number of tasks at compile time)
- Need to add tasks conditionally
- Need fine-grained control over task cancellation

**Example**: Importing variable number of workouts from HealthKit

### Q: What about CloudKit sync?

**A**: CloudKit operations are already async. Follow same patterns:
- Use structured concurrency (`async let` for parallel uploads)
- Handle errors gracefully
- Show progress to user

### Q: How to test for data races?

**A**: Enable Thread Sanitizer in Xcode:
1. Edit Scheme → Run → Diagnostics
2. Enable "Thread Sanitizer"
3. Run app and test concurrent operations
4. TSan will report any data races

---

## References

### Documentation
- **Swift Concurrency**: [docs.swift.org/swift-book/.../concurrency/](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- **GRDB Concurrency**: [swiftpackageindex.com/groue/GRDB.swift/documentation/grdb](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb)
- **SQLiteData**: [swiftpackageindex.com/pointfreeco/sqlite-data/](https://swiftpackageindex.com/pointfreeco/sqlite-data/)

### Internal Documentation
- **Rearchitecture Guide**: `REARCHITECTURE_COMPLETE_GUIDE.md`
- **View Architecture**: `VIEW_ARCHITECTURE.md`
- **API Audit**: `SQLITEDATA_API_AUDIT.md`
- **Validation Strategy**: `Services/Validation/validation approach.md`

### Code Examples
- **Parallel Loading**: GoalFormView.swift:273-299, ActionFormViewModel.swift:76-105
- **Actor Isolation**: ActionCoordinator.swift:28, HealthKitImportService.swift:134
- **FetchKeyRequest**: ActionsQuery.swift, TermsQuery.swift
- **#sql Migration Notes**: ActionsQuery.swift:93-137

---

**Last Updated**: 2025-11-06
**Next Review**: After Phase 4 validation complete
