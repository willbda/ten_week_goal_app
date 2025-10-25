# Swift 6.2 Language Features

**Platform Target:** iOS 26.0+ / macOS 26.0+
**Swift Version:** 6.2+
**Last Updated:** 2025-10-24

This guide covers Swift 6.2 language features applicable to the Ten Week Goal App. For UI/platform-specific patterns, see [IOS26_CONFORMANCE.md](./IOS26_CONFORMANCE.md).

---

## 🎯 Features We Should Use

### 1. Typed Throws

**Status:** Not yet implemented
**Priority:** HIGH
**Benefit:** Compile-time exhaustive error handling

```swift
// Define specific error type
public enum DatabaseOperationError: Error, Sendable {
    case queryFailed(sql: String, underlying: Error)
    case writeFailed(operation: String, table: String, underlying: Error)
    case recordNotFound(table: String, id: UUID)
    case validationFailed(reason: String)
}

// Apply typed throws
public func fetchAll<T>() async throws(DatabaseOperationError) -> [T] {
    // Compiler enforces this method only throws DatabaseOperationError
}

// Usage with exhaustive handling
do {
    let actions = try await database.fetchAll()
} catch .queryFailed(let sql, _) {
    // Handle query failure
} catch .recordNotFound(let table, let id) {
    // Handle not found
}
// Compiler ensures all cases handled!
```

**Files to Modify:**
- `Database/DatabaseManager.swift`
- `Database/DatabaseError.swift`

---

### 2. `nonisolated` for Read Operations

**Status:** Not yet implemented
**Priority:** HIGH
**Benefit:** 15-25% fewer context switches for read-heavy operations

```swift
public actor DatabaseManager {

    // Read operations run on caller's actor (no context switch)
    public nonisolated func fetchAll<T>() async throws -> [T] {
        try await dbPool.read { db in
            try T.fetchAll(db)
        }
    }

    // Write operations stay actor-isolated for safety
    public func save<T>(_ record: inout T) async throws {
        try await dbPool.write { db in
            try record.save(db)
        }
    }
}
```

**Why This Matters:**
- If a `@MainActor` view calls `fetchAll()`, it runs on MainActor (no thread hop)
- Significantly faster for UI-driven database queries
- Write operations remain serialized for data integrity

**Files to Modify:**
- `Database/DatabaseManager.swift` - Add `nonisolated` to all read methods

---

### 3. Protocol Default Implementations

**Status:** Partially implemented
**Priority:** MEDIUM
**Benefit:** Reduces boilerplate, consistent behavior

```swift
// In Protocols.swift
public extension Completable {
    /// Days remaining until target date
    var daysUntilTarget: Int? {
        guard let target = targetDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: target).day
    }

    /// Is this completable overdue?
    var isOverdue: Bool {
        guard let target = targetDate else { return false }
        return target < Date()
    }

    /// Has valid measurement criteria
    var hasMeasurementCriteria: Bool {
        measurementUnit != nil && measurementTarget != nil
    }
}

public extension Persistable {
    /// Display name (friendlyName or fallback)
    var displayName: String {
        friendlyName ?? detailedDescription ?? "Untitled"
    }
}
```

**Usage:** All conforming types automatically get these methods.

**Files to Modify:**
- `Models/Protocols.swift` - Add extensions with default implementations

---

### 4. `@Observable` Refinements

**Status:** Implemented
**Priority:** HIGH (for new ViewModels)
**Benefit:** 40-60% reduction in unnecessary view updates

```swift
@Observable
@MainActor
final class GoalsViewModel {
    // Tracked: causes view updates when changed
    private(set) var goals: [Goal] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // Computed: only triggers update if dependencies change
    var activeGoals: [Goal] {
        goals.filter { goal in
            if let targetDate = goal.targetDate {
                return targetDate > Date()
            }
            return true
        }
    }

    // View only updates when THIS property changes
    private(set) var searchQuery: String = ""

    var filteredGoals: [Goal] {
        searchQuery.isEmpty ? goals : goals.filter {
            $0.friendlyName?.localizedCaseInsensitiveContains(searchQuery) ?? false
        }
    }
}
```

**Pattern:** Use computed properties for derived state - views only update when the computed property's dependencies change, not every time the base array changes.

**Current Status:** Already used in ActionsViewModel, GoalsViewModel, etc.

---

### 5. Sendable Protocol Conformance

**Status:** Implemented
**Priority:** CRITICAL (already done)
**Benefit:** Swift 6 concurrency compliance

```swift
// All protocols crossing actor boundaries must be Sendable
public protocol Persistable: Identifiable, Equatable, Sendable {
    var id: UUID { get set }
    var friendlyName: String? { get set }
    // ...
}

public protocol Completable: Sendable {
    var targetDate: Date? { get set }
    // ...
}
```

**Status:** ✅ Already implemented in `Models/Protocols.swift`

---

## 🔧 Package.swift Configuration

Enable Swift 6.2 features at the package level:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GoalTracker",
    platforms: [
        .macOS(.v26),  // macOS 26+
        .iOS(.v26)     // iOS 26+
    ],
    targets: [
        .target(
            name: "Models",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances")
            ]
        ),
        .target(
            name: "Database",
            dependencies: ["Models", .product(name: "GRDB", package: "GRDB.swift")],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        ),
        .target(
            name: "App",
            dependencies: ["Models", "Database"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferIsolatedConformances")
            ]
        )
    ]
)
```

**Features Explained:**
- `StrictConcurrency`: Catches data races at compile time
- `NonisolatedNonsendingByDefault`: Reduces unnecessary context switches (20-30%)
- `InferIsolatedConformances`: Fixes `@MainActor` protocol conformance issues

---

## 🚀 Performance Optimizations

### Whole Module Optimization

**For Release builds only** (increases build time):

```swift
.target(
    name: "Database",
    swiftSettings: [
        .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release))
    ]
)
```

**Benefit:** 2-6x performance improvement for generic methods through cross-file inlining.

---

### Database Indexes

**Priority:** HIGH
**Impact:** 10-1000x speedup for filtered queries

```sql
-- In shared/schemas/indexes.sql
CREATE INDEX IF NOT EXISTS idx_goals_target_date ON goals(target_date);
CREATE INDEX IF NOT EXISTS idx_actions_log_time ON actions(log_time);
CREATE INDEX IF NOT EXISTS idx_values_priority ON personal_values(priority);
```

**Usage:**
```swift
// Uses idx_goals_target_date for fast filtering
let futureGoals = try await database.fetch(
    Goal.self,
    sql: "SELECT * FROM goals WHERE target_date > ? ORDER BY target_date",
    arguments: [Date()]
)
```

**Status:** Should be added to schema initialization.

---

## 📊 Implementation Priorities

| Feature | Priority | Status | Effort | Impact |
|---------|----------|--------|--------|--------|
| Sendable conformance | CRITICAL | ✅ Done | - | Concurrency compliance |
| `@Observable` refinements | HIGH | ✅ Done | - | View performance |
| Typed throws | HIGH | ⏸️ Not started | 2-3 hours | Error handling |
| `nonisolated` reads | HIGH | ⏸️ Not started | 1-2 hours | Database performance |
| Protocol extensions | MEDIUM | 🟡 Partial | 1-2 hours | Code reuse |
| Database indexes | HIGH | ⏸️ Not started | 30 min | Query performance |
| WMO (Release) | HIGH | ⏸️ Not started | 5 min | Overall performance |

---

## 🎓 Learning Resources

**Swift 6.2 Official:**
- [Swift 6.2 Language Guide](https://docs.swift.org/swift-book/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

**GRDB + Swift 6:**
- [GRDB Concurrency Guide](https://github.com/groue/GRDB.swift/blob/master/Documentation/Concurrency.md)

**Performance:**
- [Swift Performance](https://github.com/apple/swift/blob/main/docs/OptimizationTips.rst)

---

## 🔍 What's NOT in This Guide

This guide focuses on **Swift 6.2 language features**. For other topics:

- **UI/Platform patterns** → See [IOS26_CONFORMANCE.md](./IOS26_CONFORMANCE.md)
- **Design system** → See [DESIGN_SYSTEM.md](./DESIGN_SYSTEM.md)
- **Architecture** → See [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Project roadmap** → See [ROADMAP.md](./ROADMAP.md)

---

*This guide extracted from SWIFT_6_2_IMPROVEMENTS.md on 2025-10-24, focusing on language features applicable to iOS 26+/macOS 26+ development.*
