# SQLiteData vs SwiftData Comparison

Source: https://swiftpackageindex.com/pointfreeco/sqlite-data/main/documentation/sqlitedata/comparisonwithswiftdata
Fetched: 2025-10-25

## Overview

SQLiteData can replace SwiftData for many kinds of apps, providing:
- Direct access to underlying SQLite schema
- Better integration outside SwiftUI views (UIKit, `@Observable` models, etc.)
- Struct-based models (vs SwiftData's class requirement)

## Key Architectural Differences

### Schema Definition

**SwiftData**: `@Model` macro (classes only)
**SQLiteData**: `@Table` macro from StructuredQueries (structs supported)

```swift
// SQLiteData
@Table
struct Item {
    let id: UUID
    let title: String
}

// SwiftData
@Model
class Item {
    let id: UUID
    let title: String

    init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}
```

Key differences:
- `@Table` works with structs; `@Model` requires classes
- `@Model` requires explicit initializers
- `@Model` doesn't need `id` field (uses `persistentIdentifier`)

### Data Fetching

**In Views**:
- SwiftData: `@Query` (view-only)
- SQLiteData: `@FetchAll` (works in views AND `@Observable` models)

**In `@Observable` Models**:
- SwiftData: Must recreate `@Query` functionality manually
- SQLiteData: `@FetchAll` works identically to views

```swift
// SQLiteData - works in @Observable models
@MainActor
@Observable
class ItemsModel {
    @ObservationIgnored
    @FetchAll var items: [Item]
}

// SwiftData - must manually implement observation
@MainActor
@Observable
class ItemsModel {
    var items: [Item] = []
    // Manual database observation code required
}
```

**Additional Property Wrappers**:
- `@FetchOne`: Fetch single value (aggregate queries)
- `@Fetch`: Multiple queries in single transaction
- No SwiftData equivalents

### Dynamic Queries (Critical Advantage)

**SQLiteData**: Single view with mutable query
```swift
struct ItemsView: View {
    @State var searchText = ""
    @FetchAll(
        .items.where(.title.contains(searchText))
    ) var items: [Item]

    var body: some View {
        List(items) { /* ... */ }
            .searchable(text: $searchText)
            .onChange(of: searchText) {
                $items.query = .items.where(.title.contains(searchText))
            }
    }
}
```

**SwiftData**: Requires two views (outer + inner)
```swift
// Outer view holds search state
struct ItemsView: View {
    @State var searchText = ""

    var body: some View {
        SearchResultsView(searchText: searchText)
            .searchable(text: $searchText)
    }
}

// Inner view recreated when searchText changes
struct SearchResultsView: View {
    let searchText: String
    @Query var items: [Item]

    init(searchText: String) {
        self.searchText = searchText
        _items = Query(filter: #Predicate { $0.title.contains(searchText) })
    }
}
```

**Why**: `@Query` state is immutable after initialization. Must recreate view to change query.

### CRUD Operations

Both use dependency injection pattern:
- SQLiteData: `@Dependency(\.defaultDatabase)`
- SwiftData: `@Environment(\.modelContext)`

```swift
// SQLiteData
@Dependency(\.defaultDatabase) var database

try await database.write { db in
    try db.insert(Item(title: "New"))
}

// SwiftData
@Environment(\.modelContext) var context

context.insert(Item(title: "New"))
try context.save()
```

### Associations (Major Philosophical Difference)

**SwiftData**: Object-Relational Mapping (ORM)
```swift
@Model
class Sport {
    @Relationship var teams: [Team]
}

// Usage - implicit queries
for sport in sports {
    print(sport.teams.count) // Query per sport!
}
```

Problems with ORM approach:
- Must use classes (reference semantics)
- Easy to execute many inefficient queries (N+1 problem)
- Loads unnecessary data into memory

**SQLiteData**: Direct SQL with joins
```swift
@FetchAll(
    .teams
        .join(.sports, on: .teams[.sportID] == .sports[.id])
        .select { ($0.sports, count: count($0.teams[.id])) }
        .groupBy(.sports[.id])
) var sportCounts: [(Sport, count: Int)]
```

Benefits:
- Single efficient query
- Only loads needed data
- Explicit performance characteristics
- Requires SQL knowledge (benefit!)

## Critical SwiftData Limitations

### 1. Booleans and Enums

**SwiftData limitations**:
- ❌ Cannot sort by boolean columns (Bool not Comparable)
- ❌ Cannot filter by enum columns (runtime crash!)
- Workaround: Model as integers (loses type safety)

**SQLiteData**: Full support
```swift
@FetchAll(
    .reminders
        .where(.priority == .high)
        .order(by: .isCompleted)
) var reminders: [Reminder]
```

### 2. Migrations

**Lightweight Migrations** (simple cases):
- SwiftData: Implicit, less code
- SQLiteData: Explicit with GRDB migrations

**Manual Migrations** (complex cases - most real-world scenarios):
- SwiftData: Extremely verbose, requires duplicating entire model types
- SQLiteData: Direct SQL, much simpler

Example: Adding unique constraint
- SwiftData: 7 complex steps, duplicate models, inefficient migration logic
- SQLiteData: 2 steps - delete duplicates via SQL, add index

From docs: "Real world apps tend to require complex logic when performing most migrations. One should optimize for manual migrations rather than lightweight."

### 3. CloudKit Support

Both support CloudKit sync, but:

**SwiftData limitations**:
- No unique constraints on columns
- All properties must be optional or have defaults
- All relationships must be optional

**SQLiteData limitations**:
- Unique constraints only for newly added columns (same distributed constraint issue)
- New columns must be nullable or have defaults
- New relationships must be nullable

SQLiteData also exposes underlying `CKRecord` types for direct CloudKit interaction.

## Platform Support

**SwiftData**: iOS 17+, macOS 14+, tvOS 17+, watchOS 10+

**SQLiteData**: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+

SQLiteData supports essentially any modern app today.

## Summary: When to Use Each

### Use SQLiteData when:
- ✅ Need `@Observable` model support (logic outside views)
- ✅ Dynamic queries are important (search, filtering)
- ✅ Want struct-based models (value semantics)
- ✅ Performance-critical queries (control SQL directly)
- ✅ Need booleans/enums in queries
- ✅ Complex migrations are expected
- ✅ UIKit integration required
- ✅ Broader platform support needed (iOS 13+)
- ✅ Want to learn/use SQL directly

### Use SwiftData when:
- ✅ Simple CRUD with minimal queries
- ✅ All logic lives in SwiftUI views
- ✅ Only need lightweight migrations
- ✅ Prefer implicit "magical" behavior
- ✅ Don't want to learn SQL
- ✅ iOS 17+ target is acceptable

## Ten Week Goal App Implications

**Current Architecture**: GRDB (similar philosophy to SQLiteData)

**Why GRDB/SQLiteData align with our goals**:
1. ✅ **Struct-based models**: Action, Goal, Value, Term are all structs
2. ✅ **Business logic in `@Observable` models**: ActionsViewModel, GoalsViewModel
3. ✅ **Complex queries**: Progress aggregation, relationship inference
4. ✅ **Performance**: Efficient joins for action-goal matching
5. ✅ **SQL control**: Direct schema management, explicit migrations
6. ✅ **Protocol-oriented design**: GRDB doesn't force class hierarchies

**SwiftData would be problematic because**:
- ❌ Would require converting all structs to classes
- ❌ No `@Query` support in ViewModels (would need manual implementation)
- ❌ Enum filtering crashes (Priority, LifeArea, GoalType)
- ❌ Complex manual migrations for polymorphic storage
- ❌ Hidden performance characteristics in relationship queries

**Conclusion**: Continuing with GRDB is the correct architectural choice for this project.
