# Modern Swift 6.2 Quick Reference
**Created**: 2025-11-06
**Purpose**: Quick reference for Swift 6.2 and iOS 26+ patterns used in ten_week_goal_app

---

## Overview

This document provides quick reference for modern Swift 6.2 features and iOS 26+ patterns actively used in this codebase. For detailed architectural patterns, see [REARCHITECTURE_COMPLETE_GUIDE.md](REARCHITECTURE_COMPLETE_GUIDE.md).

**Platform Targets**:
- Swift 6.2 (Released September 15, 2025)
- iOS 26+ (Released September 15, 2025)
- macOS Tahoe 26+ (Released September 15, 2025)
- visionOS 26+ (Released September 15, 2025)

---

## Swift 6.2 Concurrency Features

### Sendable Protocol

**Purpose**: Mark types safe to transfer across concurrency domains (actor boundaries)

**All models in this app are Sendable**:
```swift
// From Protocols.swift:56-57
public protocol DomainAbstraction: Identifiable, Documentable,
    Timestamped, Equatable, Hashable, Sendable where ID == UUID {}

// All models conform
@Table
public struct Action: DomainAbstraction { ... }  // Sendable ✅
```

**Why**: Enables passing models between @MainActor ViewModels and database operations safely.

**Rules**:
- All stored properties must be Sendable
- Structs with Sendable fields are implicitly Sendable
- Classes require explicit conformance + immutability OR synchronization

**Documentation**: https://developer.apple.com/documentation/swift/sendable

---

### @MainActor Isolation

**Purpose**: Isolate types/functions to main thread (UI safety)

**Pattern**: All ViewModels are @MainActor, Coordinators are Sendable (NO @MainActor)
```swift
// From TimePeriodFormViewModel.swift:28-30
@Observable
@MainActor
public final class TimePeriodFormViewModel { ... }

// From ActionCoordinator.swift:28
public final class ActionCoordinator: Sendable { ... }
```

**Why NO @MainActor for Coordinators?** (Updated 2025-11-10):
- Database I/O should run in background (not on main thread)
- Coordinators are `Sendable` to safely cross actor boundaries
- Swift automatically switches context: main → background → main
- All coordinators have only `private let` immutable properties (thread-safe)

**Key files**: All `App/ViewModels/FormViewModels/*.swift`, all `Services/Coordinators/*.swift`

**Documentation**: https://developer.apple.com/documentation/swift/mainactor

---

### nonisolated Functions

**Purpose**: Allow @MainActor types to have functions callable from any context

**Pattern**: Database helper methods
```swift
// From HealthKitImportService.swift (line ~134)
@MainActor
class HealthKitImportService {
    // Called from database.write closures (not main actor)
    nonisolated private func findOrCreateMeasure(...) throws -> Measure {
        // Can be called from serial database queue
    }
}
```

**Why**: `database.write {}` closures run on database's serial queue, not main actor. Helper methods need `nonisolated` to be callable from both contexts.

**When to use**:
- Pure functions in @MainActor types
- Database query helpers
- Computation without state mutation

**Documentation**: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/

---

### Structured Concurrency (async let)

**Purpose**: Run multiple async operations in parallel, await all together

**Pattern**: Parallel database reads
```swift
// From GoalFormView.swift:273-299
private func loadAvailableData() async {
    do {
        // Launch 3 queries in parallel
        async let measures = database.read { db in
            try Measure.order(by: \.unit).fetchAll(db)
        }
        async let values = database.read { db in
            try PersonalValue.order { $0.priority.desc() }.fetchAll(db)
        }
        async let terms = database.read { db in
            try TermsWithPeriods().fetch(db)
        }

        // Await all results together
        (availableMeasures, availableValues, availableTerms) =
            try await (measures, values, terms)
    } catch {
        print("Error loading form data: \(error)")
    }
}
```

**Performance**: 3x faster than sequential (~100ms vs ~300ms)

**When to use**:
- Independent database reads (no shared state)
- Loading form data
- Multiple API calls

**Key files**: [GoalFormView.swift:273-299](../Sources/App/Views/FormViews/GoalFormView.swift), [ActionFormViewModel.swift:76-105](../Sources/App/ViewModels/FormViewModels/ActionFormViewModel.swift)

**Documentation**: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/

---

## SwiftUI Modern Patterns

### @Observable Macro (Swift 5.9+)

**Purpose**: Modern state observation (replaces ObservableObject + @Published)

**Pattern**: ViewModels use @Observable, NOT ObservableObject
```swift
// ✅ Modern pattern
@Observable
@MainActor
public final class TimePeriodFormViewModel {
    public var isSaving: Bool = false      // Auto-tracked, no @Published
    public var errorMessage: String?       // Auto-tracked, no @Published

    @ObservationIgnored  // Exclude from observation
    @Dependency(\.defaultDatabase) var database
}

// ❌ Legacy pattern (don't use)
class OldViewModel: ObservableObject {
    @Published var isSaving: Bool = false
}
```

**In Views**: Use `@State`, not `@StateObject`
```swift
// ✅ Modern
@State private var viewModel = TimePeriodFormViewModel()

// ❌ Legacy
@StateObject private var viewModel = OldViewModel()
```

**Key files**: All `App/ViewModels/FormViewModels/*.swift` (15 files use @Observable)

**Documentation**: https://developer.apple.com/documentation/swiftui/model-data

---

### @Fetch for Reactive Lists

**Purpose**: Automatic UI updates when database changes

**Pattern**: Use with FetchKeyRequest for performant JOINs
```swift
// From TermsListView.swift
@Fetch(TermsWithPeriods()) private var termsWithPeriods

var body: some View {
    List {
        ForEach(termsWithPeriods) { termWithPeriod in
            TermRowView(
                term: termWithPeriod.term,
                timePeriod: termWithPeriod.timePeriod
            )
        }
    }
}
```

**Benefits**:
- Single JOIN query (no N+1)
- Automatic updates when data changes
- Type-safe (compile-time errors)

**See**: [FetchKeyRequest Pattern](#fetchkeyrequest-pattern) below

**Key files**: [TermsListView.swift](../Sources/App/Views/ListViews/TermsListView.swift), [PersonalValuesListView.swift](../Sources/App/Views/ListViews/PersonalValuesListView.swift)

---

## SQLiteData Patterns

### @Table Macro

**Purpose**: Compile-time schema generation, type-safe database operations

**Pattern**: All models use @Table
```swift
// From Action.swift:40-56
import SQLiteData

@Table
public struct Action: DomainAbstraction {
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var durationMinutes: Double?
    public var startTime: Date?
    public var logTime: Date
    public var id: UUID
}
```

**Generated**:
- `actions` table in database
- Type-safe insert/update/delete operations
- Automatic Codable conformance
- Column references for queries (`\.title`, `\.logTime`)

**Documentation**: https://swiftpackageindex.com/pointfreeco/sqlite-data/1.3.0/documentation/sqlitedata

---

### Query Builder (Type-Safe Queries)

**Purpose**: Compile-time type safety for database queries

**Pattern**: Use for JOINs, WHERE, ORDER BY
```swift
// From TermsQuery.swift
let results = try GoalTerm.all
    .order { $0.termNumber.desc() }
    .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
    .fetchAll(db)
```

**Benefits**:
- ✅ Compile-time errors (typos caught by compiler)
- ✅ Type-safe (can't join incompatible types)
- ✅ Refactor-friendly (renames propagate)
- ✅ Sufficient performance (~50ms for 381 actions)

**When NOT to use**: Complex aggregations with GROUP BY (see #sql below)

**Key files**: [TermsQuery.swift](../Sources/App/Views/Queries/TermsQuery.swift), [ActionsQuery.swift](../Sources/App/Views/Queries/ActionsQuery.swift)

**Documentation**: https://swiftpackageindex.com/pointfreeco/sqlite-data/1.3.0/documentation/sqlitedata/gettingstarted

---

### #sql Macro (Runtime SQL)

**Purpose**: Raw SQL with interpolation, better for complex aggregations

**Pattern**: Use for GROUP BY, SUM, aggregations (after validation infrastructure complete)
```swift
// Future pattern (not yet used, awaiting Phase 4 validation)
let progress = try #sql(
    """
    SELECT
        em.measureId,
        em.targetValue,
        COALESCE(SUM(ma.value), 0) as actual
    FROM expectationMeasures em
    LEFT JOIN actionGoalContributions agc ON agc.goalId = \(goalId)
    LEFT JOIN measuredActions ma ON ma.actionId = agc.actionId
    WHERE em.expectationId = \(expectationId)
    GROUP BY em.measureId, em.targetValue
    """
).fetchAll(db) as [ProgressRow]
```

**Trade-offs**:
- ✅ Better performance (aggregation in SQL, not Swift)
- ✅ Clearer intent for complex queries
- ❌ Runtime errors only (no compile-time safety)
- ❌ Requires strong validation layer

**Current status**: NOT YET USED - waiting for Phase 4 validation infrastructure

**Prerequisites** (see [CONCURRENCY_STRATEGY.md:219-284](CONCURRENCY_STRATEGY.md)):
- ❌ ActionValidator with Layer B + C validation
- ❌ GoalValidator with complete graph validation
- ❌ Repository error mapping (DB errors → ValidationError)
- ❌ Integration test coverage

**Documentation**: https://swiftpackageindex.com/pointfreeco/sqlite-data/1.3.0/documentation/sqlitedata/gettingstarted

---

### FetchKeyRequest Pattern

**Purpose**: Single performant JOIN query + reactive updates via @Fetch

**Pattern**: Define custom fetch request, use with @Fetch
```swift
// From TermsQuery.swift:39-79
public struct TermsWithPeriods: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> [TermWithPeriod] {
        let results = try GoalTerm.all
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}

// Wrapper type (must be Identifiable + Sendable)
public struct TermWithPeriod: Identifiable, Sendable {
    public let term: GoalTerm
    public let timePeriod: TimePeriod
    public var id: UUID { term.id }
}

// Use in view
@Fetch(TermsWithPeriods()) private var termsWithPeriods
```

**Benefits**:
- Single JOIN query (no N+1 problem)
- Reactive updates (@Fetch auto-refreshes)
- Encapsulated query logic (reusable)
- Type-safe wrapper type

**Key files**: [TermsQuery.swift](../Sources/App/Views/Queries/TermsQuery.swift), [ActionsQuery.swift](../Sources/App/Views/Queries/ActionsQuery.swift)

---

## Swift 6.2 New Features (Future Considerations)

### InlineArray (Swift 6.2)

**Purpose**: Fixed-size arrays stored on stack (no heap allocation)

**Pattern**:
```swift
// Example (not yet used in app)
struct Vector3D {
    var data: InlineArray<3, Double>  // 3 doubles on stack
}
```

**Benefits**:
- No heap allocation
- No reference counting
- Cache-friendly
- Compile-time size verification

**Potential use case**: Fixed-size metric arrays in hot paths

**Status**: ⏳ Not yet used, future optimization

**Documentation**: https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2

---

### Span (Swift 6.2)

**Purpose**: Safe alternative to buffer pointers for contiguous memory access

**Pattern**:
```swift
// Example (not yet used in app)
func processData(span: Span<UInt8>) {
    // Memory guaranteed valid during span lifetime
    for byte in span {
        // Process byte safely
    }
}
```

**Benefits**:
- Memory safety (bounds checking)
- No manual lifetime management
- Safer than UnsafeBufferPointer

**Potential use case**: HealthKit bulk data processing

**Status**: ⏳ Not yet used, future consideration

**Documentation**: https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2

---

## Common Patterns Quick Reference

### Creating @Observable ViewModels (Updated 2025-11-10)

```swift
@Observable
@MainActor
public final class MyFormViewModel {
    var isSaving: Bool = false
    var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    // Use lazy var with @ObservationIgnored for coordinator storage
    @ObservationIgnored
    private lazy var coordinator: MyCoordinator = {
        MyCoordinator(database: database)
    }()

    public func save(...) async throws -> Entity {
        isSaving = true
        defer { isSaving = false }

        let formData = MyFormData(...)

        do {
            let entity = try await coordinator.create(from: formData)
            errorMessage = nil
            return entity
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
```

**Key Pattern Changes**:
- ✅ Coordinator stored as `lazy var` (not computed property)
- ✅ Coordinator marked `@ObservationIgnored` (avoids @Observable conflicts)
- ✅ Automatic context switching: main → background (coordinator) → main

**Reference**: [TimePeriodFormViewModel.swift](../Sources/App/ViewModels/FormViewModels/TimePeriodFormViewModel.swift)

---

### Creating Sendable Coordinators (Updated 2025-11-10)

```swift
/// Database I/O service - runs in background
public final class MyCoordinator: Sendable {
    private let database: any DatabaseWriter  // MUST be `let` (immutable)

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    public func create(from formData: MyFormData) async throws -> Entity {
        return try await database.write { db in
            // 1. Insert abstraction
            let abstraction = try Abstraction.insert { ... }
                .returning { $0 }
                .fetchOne(db)!  // Safe: insert throws or returns

            // 2. Insert concrete entity with FK
            let entity = try Entity.insert {
                Entity.Draft(
                    id: UUID(),
                    abstractionId: abstraction.id,
                    ...
                )
            }
            .returning { $0 }
            .fetchOne(db)!

            // 3. Insert relationships
            try Relationship.insert { ... }.execute(db)

            return entity
        }
    }
}
```

**Key Requirements**:
- ✅ `Sendable` conformance (safe to pass from @MainActor ViewModels)
- ❌ NO `@MainActor` (database I/O runs in background)
- ✅ Only `private let` properties (immutable, thread-safe)
- ✅ All methods `async throws`

**Reference**: [TimePeriodCoordinator.swift](../Sources/Services/Coordinators/TimePeriodCoordinator.swift)

---

### Parallel Data Loading

```swift
private func loadFormData() async {
    do {
        async let data1 = database.read { try Entity1.all.fetchAll($0) }
        async let data2 = database.read { try Entity2.all.fetchAll($0) }
        async let data3 = database.read { try Entity3.all.fetchAll($0) }

        (self.data1, self.data2, self.data3) = try await (data1, data2, data3)
    } catch {
        print("Error: \(error)")
    }
}
```

**Reference**: [GoalFormView.swift:273-299](../Sources/App/Views/FormViews/GoalFormView.swift)

---

### FetchKeyRequest for JOINs

```swift
// 1. Define request
public struct MyJoinQuery: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> [MyResult] {
        let results = try Entity1.all
            .join(Entity2.all) { $0.entity2Id.eq($1.id) }
            .fetchAll(db)

        return results.map { (entity1, entity2) in
            MyResult(entity1: entity1, entity2: entity2)
        }
    }
}

// 2. Define wrapper
public struct MyResult: Identifiable, Sendable {
    public let entity1: Entity1
    public let entity2: Entity2
    public var id: UUID { entity1.id }
}

// 3. Use in view
@Fetch(MyJoinQuery()) private var results
```

**Reference**: [TermsQuery.swift](../Sources/App/Views/Queries/TermsQuery.swift)

---

## When to Fetch Current Documentation

**Trigger conditions** (use doc-fetcher skill):

1. **Unfamiliar SwiftUI APIs**
   - New view modifiers
   - Changed initialization patterns
   - Platform-specific behaviors (visionOS)

2. **Concurrency patterns**
   - Actor isolation rules
   - Sendable conformance errors
   - Task group usage

3. **SQLiteData syntax**
   - Query builder methods
   - #sql macro usage
   - FetchKeyRequest patterns

4. **Platform version features**
   - iOS 26 new APIs
   - macOS Tahoe specifics
   - Swift 6.2 language features

**How to fetch**:
```bash
cd ~/.claude/skills/doc-fetcher
python doc_fetcher.py search "your query"
```

**Pre-approved sources**:
- `developer.apple.com`
- `docs.swift.org`
- `swiftpackageindex.com`

**See**: [DOCUMENTATION_REFRESH_GUIDE.md](DOCUMENTATION_REFRESH_GUIDE.md) for detailed guidance

---

## Key Differences from Earlier Swift

### Swift 6.2 vs Swift 5.x

| Feature | Swift 5.x | Swift 6.2 |
|---------|-----------|-----------|
| Concurrency | Optional, warnings | Strict, required |
| @Observable | N/A | Replaces ObservableObject |
| Sendable | Optional conformance | Strictly enforced |
| Actor isolation | Implicit | Explicit (@MainActor) |
| InlineArray | N/A | New in 6.2 |
| Span | N/A | New in 6.2 |

### iOS 26 vs iOS 17

| Feature | iOS 17 | iOS 26 |
|---------|--------|--------|
| SwiftUI | Observation framework | Enhanced @Observable |
| SwiftData | @Model macro | Still available |
| Design language | Previous | "Liquid Glass" design |
| Platform number | Sequential (18 after 17) | Year-based (26 for 2025-2026) |

---

## Related Documentation

- [REARCHITECTURE_COMPLETE_GUIDE.md](REARCHITECTURE_COMPLETE_GUIDE.md) - Complete architectural overview
- [CONCURRENCY_STRATEGY.md](CONCURRENCY_STRATEGY.md) - Detailed concurrency patterns
- [DOCUMENTATION_REFRESH_GUIDE.md](DOCUMENTATION_REFRESH_GUIDE.md) - When/how to fetch docs
- [CLAUDE.md](../CLAUDE.md) - Project-specific guidance

---

## Official Documentation Links

### Swift Language
- **Swift 6.2 Release**: https://www.swift.org/blog/swift-6.2-released/
- **Concurrency Guide**: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/
- **Sendable Protocol**: https://developer.apple.com/documentation/swift/sendable

### SwiftUI
- **Model Data**: https://developer.apple.com/documentation/swiftui/model-data
- **Observable Macro**: https://developer.apple.com/documentation/Observation/Observable()
- **State Management**: https://developer.apple.com/documentation/swiftui/state

### SQLiteData
- **Package Index**: https://swiftpackageindex.com/pointfreeco/sqlite-data
- **Getting Started**: https://swiftpackageindex.com/pointfreeco/sqlite-data/1.3.0/documentation/sqlitedata/gettingstarted
- **Comparison with SwiftData**: https://swiftpackageindex.com/pointfreeco/sqlite-data/1.3.0/documentation/sqlitedata/comparisonwithswiftdata

---

**Last Updated**: 2025-11-06
**Maintained By**: Claude Code & David Williams
