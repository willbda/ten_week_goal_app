# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Ten Week Goal App** - A Swift-based iOS/macOS/visionOS application for goal tracking and personal development.

- **Primary Language**: Swift 6.2
- **Platforms**: iOS 26+, macOS 26+, visionOS 26+
- **Database**: SQLite with SQLiteData ORM
- **Architecture**: Three-layer domain model with coordinators and repositories
- **Current Version**: 0.6.0 (Check `version.txt` for latest)



### Version Management

```bash
# Bump version (updates version.txt and creates git tag)
./bump_version.sh <version> "<message>"

# Example:
./bump_version.sh 0.7.0 "feat: Complete validation layer integration"
```


## Architecture Overview

### Three-Layer Domain Model

The codebase uses a normalized, layered architecture:

1. **Abstraction Layer** (`Sources/Models/Abstractions/`)
   - Base entities with full metadata (Action, Expectation, TimePeriod, Measure, PersonalValue)
   - All implement: `DomainAbstraction: Identifiable + Documentable + Timestamped`

2. **Basic Layer** (`Sources/Models/Basics/`)
   - User-friendly entities that reference abstractions (Goal, Milestone, Obligation, Term)
   - Lightweight operational data implementing `DomainBasic`

3. **Composit Layer** (`Sources/Models/Composits/`)
   - Junction tables for many-to-many relationships
   - Pure foreign key relationships with metadata

### Service Architecture

**Coordinators** (`Sources/Services/Coordinators/`)
- Handle multi-model atomic writes
- Create complex entity graphs in single transactions
- Example: `GoalCoordinator` creates Expectation + Goal + ExpectationMeasure[] + GoalRelevance[]

**Validators** (`Sources/Services/Validation/`)
- Enforce business rules before database writes
- Two-phase validation: `validateFormData()` then `validateComplete()`
- Throw user-friendly `ValidationError` messages

**Repositories** (`Sources/Services/Repositories/`) - *In Progress*
- Abstract database queries from view layer
- Provide duplicate detection, pagination, filtering
- Map database errors to ValidationErrors

### Database Schema

The database uses 3NF normalization with three conceptual layers:

@swift/Sources/Database/Schemas/schema_current.sql


## Current Development Status

### Phase Progress (v0.6.0)
- ✅ Phase 1-2: Model compilation
- ✅ Phase 3: Coordinator pattern implementation
- 🚧 Phase 4: Validation layer integration (current)
- ⏳ Phase 5-6: Audit and Refactor ViewModels and Views
- ⏳ Phase 7: Testing

### Active Work Areas
1. **Repository Pattern** - Implementing query abstraction layer
2. **CSV Import/Export** - Enhanced parsing with quoted field support
3. **HealthKit Integration** - Live tracking service implementation
4. **Validation Integration** - Connecting validators to repositories
5. **Apple Foundation Model** - Planning for on-device llm usage

### Known Issues
- HealthKit data not flowing to staging table
- Repository layer skeletal (not fully implemented)
- Dashboard/analytics views not started

## Code Patterns and Conventions

### Creating Entities

Always use coordinators for multi-model writes:

```swift
// Good: Use coordinator for atomic multi-model creation
let coordinator = GoalCoordinator(database: database)
let goal = try await coordinator.create(from: formData)

// Bad: Direct database writes
try await database.write { db in
    try expectation.save(to: db)
    try goal.save(to: db)
}
```

### Validation Pattern

Two-phase validation ensures data integrity:

```swift
// Phase 1: Business rules (before write)
try validator.validateFormData(formData)

// Write to database via coordinator
let entity = try await coordinator.create(from: formData)

// Phase 2: Referential integrity (after write, optional)
try validator.validateComplete(entity)
```

### Query Pattern (SQLiteData)

Use SQLiteData's type-safe query patterns:

```swift
// CURRENT PATTERN: FetchKeyRequest with structured query builders
// Used throughout the codebase for complex joins
public struct ActionsWithMeasuresAndGoals: FetchKeyRequest {
    public typealias Value = [ActionWithDetails]

    public func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // Fetch with structured query builders (type-safe, preferred)
        let actions = try Action
            .order { $0.logTime.desc() }
            .fetchAll(db)

        let measurements = try MeasuredAction
            .where { actionIds.contains($0.actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        // Assemble and return composite result
        return actions.map { action in
            ActionWithDetails(action: action, measurements: measurements[action.id])
        }
    }
}

// Use @Fetch in views for automatic database observation
@Fetch(wrappedValue: [], ActionsWithMeasuresAndGoals())
private var actions: [ActionWithDetails]

// FUTURE PATTERN: #sql macro for complex aggregations (not yet implemented)
// Reserved for when validation layers are complete and we need raw SQL performance
// Example of what #sql would look like (from comments in codebase):
/*
let rows = try #sql("""
    SELECT actions.*, measures.*, goals.*
    FROM actions
    LEFT JOIN measuredActions ON actions.id = measuredActions.actionId
    LEFT JOIN measures ON measuredActions.measureId = measures.id
    ORDER BY actions.logTime DESC
    """, as: ActionRow.self).fetchAll(db)
*/

// Models use @Table and @Column macros from SQLiteData
@Table("goals")
public struct Goal: DomainBasic {
    @Column("id") public let id: UUID
    @Column("expectationId") public let expectationId: UUID
    @Column("startDate") public let startDate: Date
    @Column("targetDate") public let targetDate: Date
    // ...
}
```


## Important Files and Locations

- **Database Schema**: `swift/Sources/Database/Schemas/schema_current.sql`
- **Package Definition**: `swift/Package.swift`
- **Active Documentation**: `swift/docs/20251108.md`
- **Repository Plan**: `swift/docs/REPOSITORY_IMPLEMENTATION_PLAN.md`
- **Visual Design System**: `swift/docs/LIQUID_GLASS_VISUAL_SYSTEM.md`

## Development Guidelines

### Core Principles

1. **Atomic Multi-Model Operations**: Always use coordinators for writes involving multiple models
2. **Validation First**: Validate data before attempting database writes
3. **Type Safety**: Leverage SQLiteData's compile-time safety with @Table/@Column macros
4. **Error Handling**: Convert database errors to user-friendly ValidationErrors
5. **Async/Await**: All database operations must be async for thread safety
6. **No Direct SQL**: Use SQLiteData's structured queries instead of raw SQL strings

### Effective Development Practices

#### Scaffolding Before Implementation

When working on bigger features, scaffold first:

1. **Create all needed files with descriptive comments**:
```swift
// GoalRepository.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE: Abstract database queries for Goal entities
// PATTERN: Repository pattern for data access
//
// RESPONSIBILITIES:
// - Fetch goals with related entities (expectations, measures, relevances)
// - Check for duplicate titles before insert
// - Map database errors to ValidationErrors
// - Support pagination and filtering
//
// TODO: Implement after validation layer complete
```

2. **Why this works well**:
- Provides high-level planning before diving into details
- Creates clear reminders of work in progress
- Helps identify dependencies and integration points early
- Makes the architecture visible before implementation

**Example**: See how `Sources/Services/Repositories/` is scaffolded - each file has clear intent comments but minimal implementation, making the planned architecture clear.

#### Smart Commenting Strategy

**DO comment when**:
- Making a judgment call or trade-off decision
- After researching or problem-solving to get something working
- Explaining WHY not WHAT (the code shows what, comments explain why)
- Documenting assumptions that might not be obvious
- Marking TODOs with context about prerequisites

**DON'T over-comment**:
- Use descriptive variable/function names instead of comments
- Don't explain obvious Swift/SwiftUI patterns
- Avoid comments that just restate what the code does

**Good Example**:
```swift
// Use bulk queries to avoid N+1 problem (was 763 queries, now 3)
// Pattern from SyncUpDetail.swift:47 - .where { ids.contains($0.id) }
let allMeasurementResults = try MeasuredAction
    .where { actionIds.contains($0.actionId) }
    .join(Measure.all) { $0.measureId.eq($1.id) }
    .fetchAll(db)

// Group by action ID for O(1) lookup during assembly
let measurementsByAction = Dictionary(grouping: allMeasurementResults) { $0.actionId }
```

**Bad Example**:
```swift
// Set isSaving to true
isSaving = true

// Create a new goal
let goal = Goal()

// Add the goal to the array
goals.append(goal)
```

## Common Tasks

### Adding a New Entity Type

1. Create model in appropriate layer (`Abstractions/`, `Basics/`, or `Composits/`)
2. Add @Table and @Column attributes for SQLiteData
3. Create FormData structure in `Services/Coordinators/FormData/`
4. Implement Coordinator in `Services/Coordinators/`
5. Implement Validator in `Services/Validation/`
6. Create Repository in `Services/Repositories/` (when pattern is complete)
7. Add database migration if schema changes
8. Write tests for coordinator and validator


## Documentation Research with doc-fetcher

### When to Use doc-fetcher

The doc-fetcher skill is highly effective for researching API documentation and should be your first step when:
- Looking up Swift/SwiftUI APIs from developer.apple.com
- Researching SQLiteData or other package documentation
- Encountering JS-heavy documentation pages that can't be fetched directly
- Needing to understand modern patterns or recent API changes
- Cross-referencing concepts across different documentation sources

### How to Use doc-fetcher Effectively

```bash
# Search pre-indexed documentation (most efficient)
cd ~/.claude/skills/doc-fetcher
python doc_fetcher.py search "Observable @MainActor Swift 6" --limit 10

# Fetch and index new documentation
python doc_fetcher.py fetch "https://developer.apple.com/documentation/swiftui/observable" --crawl --depth 2

# For complex research questions, consider using an agent
# The agent can search with doc-fetcher and review pre-loaded data more efficiently
```

### Why doc-fetcher is Token-Efficient

- Pre-indexes documentation for fast searching
- Returns relevant snippets rather than full pages
- Handles JavaScript-rendered pages that normal fetch tools can't access
- Maintains a searchable database of previously fetched content
- Avoids redundant fetching of already-indexed pages

**Tip**: When researching unfamiliar APIs or checking if patterns have changed in recent iOS/macOS versions, always start with doc-fetcher rather than trying to fetch pages directly.

## Modern Swift/SwiftUI Patterns (iOS 26+, Swift 6.2)

### Critical Pattern Updates

The codebase targets iOS 26+ and should use modern patterns throughout:

#### 1. Observable Pattern (Use @Observable, NOT ObservableObject)

**Modern Pattern (Correct)**:
```swift
@Observable
@MainActor
public final class ActionFormViewModel {
    var isSaving: Bool = false  // No @Published needed
    var errorMessage: String?   // Auto-tracked by @Observable

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
}

// In View:
@State private var viewModel = ActionFormViewModel()  // NOT @StateObject
```

**Legacy Pattern (Avoid)**:
```swift
// DON'T DO THIS - ObservableObject is legacy
class OldViewModel: ObservableObject {
    @Published var isSaving = false  // Avoid @Published
}

// DON'T DO THIS - @StateObject is legacy
@StateObject private var viewModel = OldViewModel()
```

**Current Issues**: Coordinators still use `ObservableObject` pattern and should be migrated to `@Observable`.

#### 2. Concurrency (Swift 6 Strict Concurrency)

**Modern Pattern**:
```swift
// Use @MainActor for UI-bound types
@Observable
@MainActor
public final class ViewModel {
    // All properties are MainActor-isolated
}

// Use Sendable for cross-boundary types
public struct ActionWithDetails: Identifiable, Hashable, Sendable {
    // Safe to pass between isolation domains
}
```

**Key Rules**:
- Mark ViewModels with `@MainActor` to ensure UI updates on main thread
- Make data types `Sendable` when passed between actors
- Avoid capturing non-Sendable types in concurrent contexts

#### 3. Database Queries (SQLiteData FetchKeyRequest and @Fetch)

**Current SQLiteData Patterns in Use**:
```swift
// PATTERN 1: FetchKeyRequest with structured query builders (current approach)
public struct ActionsWithMeasuresAndGoals: FetchKeyRequest {
    public typealias Value = [ActionWithDetails]

    public func fetch(_ db: Database) throws -> [ActionWithDetails] {
        // Type-safe query builders (compile-time checked)
        let actions = try Action
            .order { $0.logTime.desc() }
            .fetchAll(db)

        // Bulk fetch with joins
        let measurements = try MeasuredAction
            .where { actionIds.contains($0.actionId) }
            .join(Measure.all) { $0.measureId.eq($1.id) }
            .fetchAll(db)

        return assembleResults(actions, measurements)
    }
}

// PATTERN 2: @Fetch property wrapper for automatic updates
@Fetch(wrappedValue: [], ActionsWithMeasuresAndGoals())
private var actions: [ActionWithDetails]

// PATTERN 3: Simple fetches with @FetchAll
@FetchAll(Goal.order(by: \.targetDate))
private var goals: [Goal]
```

**Future Pattern (When Validation Complete)**:
```swift
// #sql macro for complex aggregations (not yet in use)
// Will provide better performance for complex queries
let result = try #sql("""
    SELECT COUNT(*) as count, AVG(value) as average
    FROM measuredActions
    WHERE measureId = \(bind: measureId)
    GROUP BY actionId
    """, as: AggregateResult.self).fetchOne(db)
```

**Anti-Patterns to Avoid**:
```swift
// DON'T manually fetch without observation
.onAppear {
    actions = try await fetchActions()  // Won't auto-update
}

// DON'T use raw SQL strings without type safety
let results = try database.execute("SELECT * FROM actions")  // Unsafe

// DON'T use SwiftData's @Query (we use SQLiteData, not SwiftData)
@Query(sort: \Item.title) var items  // Wrong library!
```

#### 4. Dependency Injection

**Modern Pattern**:
```swift
// Use @Dependency with @ObservationIgnored
@Observable
class ViewModel {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
}
```

#### 5. Form Data Pattern

**Modern Pattern**:
```swift
// Use structured FormData types for complex forms
struct ActionFormData {
    var title: String = ""
    var measurements: [MeasurementInput] = []
}

// Pass to coordinators for atomic writes
let action = try await coordinator.create(from: formData)
```

### Pitfalls to Avoid

1. **Mixing Observable Patterns**: Don't use `@Published` with `@Observable` classes
2. **Wrong State Storage**: Use `@State` not `@StateObject` for @Observable classes
3. **Manual Database Observation**: Use `@Fetch` with FetchKeyRequest for automatic updates
4. **Raw SQL Without Type Safety**: Always use `#sql` macros instead of raw SQL strings
5. **Synchronous Database Access**: All database operations must be async
6. **Missing Sendable**: Add `Sendable` conformance to types passed between actors
7. **Missing MainActor**: ViewModels without `@MainActor` can cause UI updates off main thread
8. **Wrong Query Pattern**: Use `FetchKeyRequest` with `#sql` for complex joins, not manual queries

### Migration Checklist

When updating existing code:
- [ ] Replace `ObservableObject` with `@Observable`
- [ ] Remove all `@Published` properties
- [ ] Change `@StateObject` to `@State` in views
- [ ] Add `@MainActor` to ViewModels
- [ ] Add `Sendable` to data types
- [ ] Convert raw SQL to `#sql` macros for type safety
- [ ] Use `FetchKeyRequest` with `@Fetch` for complex queries
- [ ] Mark dependencies with `@ObservationIgnored`
- [ ] Ensure all models have `@Table` and `@Column` attributes

### Platform Features (iOS 26+, macOS 26+)

The app targets the latest platforms:
- iOS 26+ (latest)
- macOS 26+ (Tahoe)
- visionOS 26+

This enables use of:
- Latest Swift 6.2 language features
- Modern SwiftUI APIs
- Strict concurrency checking
- @Observable macro (Observation framework)
- Enhanced @Query and data flow patterns