# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

### Building and Testing
```bash
# Build the Swift package (from swift/ directory)
swift build

# Build without warnings (common during development)
swift build -Xswiftc -suppress-warnings

# Run tests
swift test

# Run specific test
swift test --filter [TestName]

# Build via Xcode (if using GoalTracker.xcodeproj)
xcodebuild -scheme GoalTrackerApp -configuration Debug
```

### Database Operations
```bash
# Query the 3NF database directly (app sandbox location)
sqlite3 '/Users/davidwilliams/Library/Containers/WilliamsBD.GoalTrackerApp/Data/Library/Application Support/GoalTracker/application_data.db'

# Example: View all terms with their goals
sqlite3 '/Users/davidwilliams/Library/Containers/WilliamsBD.GoalTrackerApp/Data/Library/Application Support/GoalTracker/application_data.db' "SELECT * FROM goalTerms;"
```

---

## Architecture Overview

### Three-Layer Model Ontology

This app uses a **trait-based model architecture** with strict ontological layers:

**Abstractions/** (`Sources/Models/Abstractions/`)
- Protocol: `DomainAbstraction` (full metadata: title, description, notes, logTime)
- Purpose: Abstract entities that define **what could exist**
- Examples: `Expectation`, `Action`, `Measure`, `TimePeriod`, `PersonalValue`
- Fields: `id`, `title`, `detailedDescription`, `freeformNotes`, `logTime` + type-specific fields

**Basics/** (`Sources/Models/Basics/`)
- Protocol: `DomainBasic` (lightweight: id + foreign keys)
- Purpose: Concrete working entities that define **what does exist**
- Examples: `Goal` (references Expectation), `Term` (references TimePeriod)
- Fields: `id` + FK to abstraction + minimal type-specific fields

**Composits/** (`Sources/Models/Composits/`)
- Protocol: `DomainComposit` (minimal: id + 2+ foreign keys)
- Purpose: Pure junction tables that define **how things relate**
- Examples: `MeasuredAction`, `GoalRelevance`, `ActionGoalContribution`
- Fields: `id` + FK references + relationship-specific data only
- **NO business logic** - pure database artifacts

### Why This Hierarchy?
- Abstractions = ontological foundation (what could be)
- Basics = concrete instances (what is)
- Composits = relationships (how they connect)
- Separation enables: proper relationship modeling, clean querying, type-safe APIs

---

## Module Structure & Dependencies

```
swift/Sources/
├── Models/              # Domain entities (SQLiteData @Table structs)
│   ├── Abstractions/    # DomainAbstraction (Action, Expectation, etc.)
│   ├── Basics/          # DomainBasic (Goal, Term, etc.)
│   └── Composits/       # DomainComposit (MeasuredAction, GoalRelevance, etc.)
├── Services/            # Data access, coordinators, platform services
│   ├── Coordinators/    # Multi-model atomic transactions (Phase 1)
│   ├── Import/          # Legacy data import system
│   └── Validation/      # Three-layer validation (Phase 2 - TODO)
├── Logic/               # Business rules (validators, LLM integration)
└── App/                 # SwiftUI views, ViewModels, queries
    ├── ViewModels/      # @Observable ViewModels (FormViewModels, ImportViewModels)
    ├── Views/           # SwiftUI views organized by entity
    │   ├── Queries/     # FetchKeyRequest helpers for performant JOINs
    │   ├── FormViews/   # Entity creation/editing forms
    │   ├── ListViews/   # Entity list views with @Fetch
    │   ├── RowViews/    # List row display components
    │   ├── Components/  # Reusable UI components (FormScaffold, BadgeView, etc.)
    │   └── Templates/   # Shared UI patterns (DocumentableFields, ValidationFeedback)
    └── ContentView.swift
```

**Dependency Rules**:
- Models: SQLiteData only (no other modules)
- Services: Models + SQLiteData
- Logic: Models only (no database access)
- App: All modules + SQLiteData

---

## Database: 3NF Normalized Architecture

**Current State**: Undergoing active rearchitecture from JSON-based to fully normalized 3NF schema.

### Key Schema Principles
- ✅ **No JSON fields** - All values atomic (old `measuresByUnit` eliminated)
- ✅ **Single source of truth** - No redundant data
- ✅ **Pure junction tables** - Minimal fields, just relationships
- ✅ **Proper foreign keys** - Referential integrity enforced
- ✅ **Indexed for performance** - Common queries optimized

### Schema Files
- `Sources/Database/Schemas/schema_current.sql` - Production schema
- `Sources/Database/Schemas/README.md` - Schema layer explanation

### Example: Multi-Metric Goals
**Old schema (broken)**: `goal.measurementUnit = "km"`, `goal.measurementTarget = 120`
**New schema (normalized)**:
- Goal references Expectation (abstract)
- ExpectationMeasure table: `(expectationId, measureId, targetValue)`
- Enables: "Run 100km AND 20 sessions" (multi-metric goals)

---

## Coordinator Pattern (Phase 1 - In Progress)

**Purpose**: Atomically create multi-model entity graphs in single transactions.

### Pattern Structure
```swift
@MainActor
public final class [Entity]Coordinator: ObservableObject {
    private let database: any DatabaseWriter

    // Create: Insert abstraction + concrete + relationships atomically
    public func create(from formData: [Entity]FormData) async throws -> [Entity] {
        return try await database.write { db in
            // 1. Insert abstraction (if needed)
            let abstraction = try [Abstraction].insert { ... }.returning { $0 }.fetchOne(db)!

            // 2. Insert concrete entity with FK
            let entity = try [Entity].insert { ... }.returning { $0 }.fetchOne(db)!

            // 3. Insert relationships
            try [Relationship].insert { ... }.execute(db)

            return entity
        }
    }

    // Update: Update all related entities, preserve IDs and logTime
    public func update(...) async throws -> [Entity] { ... }

    // Delete: Handle FK dependencies (delete children first)
    public func delete(...) async throws { ... }
}
```

### Key Decisions
- **No validation in coordinators** - Trust caller (ViewModel)
- **Database enforces constraints** - NOT NULL, foreign keys, CHECK constraints
- **Full CRUD required** - create(), update(), delete() for parity with old app
- **Force unwrap after insert is safe** - insert() either throws or returns value

### Status
- ✅ **PersonalValueCoordinator** - Create only (TODO: add update/delete)
- ✅ **TimePeriodCoordinator** - Full CRUD (reference implementation)
- ✅ **ActionCoordinator** - Full CRUD (3 models atomically)
- ✅ **GoalCoordinator** - Full CRUD (most complex: 5+ models atomically)

**Reference**: `TimePeriodCoordinator.swift` for full CRUD pattern

---

## ViewModel Pattern (Modern @Observable)

**Use @Observable, NOT ObservableObject** (Swift 5.9+ pattern)

```swift
@Observable  // Not ObservableObject!
@MainActor
public final class [Entity]FormViewModel {
    var isSaving: Bool = false      // No @Published needed
    var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    // Computed property for coordinator (no lazy with @Observable)
    private var coordinator: [Entity]Coordinator {
        [Entity]Coordinator(database: database)
    }

    public init() {}

    // Individual parameters (ergonomic for SwiftUI), assemble FormData internally
    public func save(/* individual params */) async throws -> [Entity] {
        isSaving = true
        defer { isSaving = false }

        let formData = [Entity]FormData(/* assemble */)

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

**In Views**: Use `@State`, not `@StateObject`
```swift
@State private var viewModel = PersonalValuesFormViewModel()
```

---

## Query Strategy: Hybrid Query Builder + #sql

**Default**: Use SQLiteData Query Builder for type safety during active development
```swift
// Type-safe, compile-time errors, great for JOINs
let results = try GoalTerm.all
    .order { $0.termNumber.desc() }
    .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
    .fetchAll(db)
```

**When to use #sql**: Complex aggregations (GROUP BY, SUM) after validation infrastructure complete
```swift
// Better performance for aggregations, but runtime errors only
let progress = try #sql(
    """
    SELECT em.measureId, COALESCE(SUM(ma.value), 0) as actual
    FROM expectationMeasures em
    LEFT JOIN actionGoalContributions agc ON agc.goalId = \(goalId)
    LEFT JOIN measuredActions ma ON ma.actionId = agc.actionId
    GROUP BY em.measureId
    """
).fetchAll(db)
```

**Migration Prerequisites** (not yet ready):
- ❌ Phase 2 validation layers (Services/Validation/)
- ❌ Integration test coverage
- ❌ Layer B validation in coordinators
- ❌ Layer C error mapping in repositories

**See**: `ActionsQuery.swift:93-137` for detailed migration notes

---

## FetchKeyRequest Pattern for Performant JOINs

**Purpose**: Single query instead of N+1 fetches, works with @Fetch for reactivity

```swift
// Define FetchKeyRequest
public struct TermsWithPeriods: FetchKeyRequest {
    public func fetch(_ db: Database) throws -> [TermWithPeriod] {
        let results = try GoalTerm.all
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)
        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}

// Wrapper type for combined data
public struct TermWithPeriod: Identifiable, Sendable {
    public let term: GoalTerm
    public let timePeriod: TimePeriod
    public var id: UUID { term.id }
}

// Use in SwiftUI view with @Fetch
@Fetch(TermsWithPeriods()) private var termsWithPeriods
```

**Benefits**:
- Single JOIN query (performant)
- Reactive updates (@Fetch auto-refreshes)
- Encapsulated query logic (reusable)

**Examples**: `TermsQuery.swift`, `ActionsQuery.swift`

---

## Form Patterns

### FormScaffold Template
```swift
FormScaffold(
    title: "New [Entity]",
    canSubmit: !title.isEmpty && !viewModel.isSaving,
    onSubmit: handleSubmit,
    onCancel: { dismiss() }
) {
    DocumentableFields(title: $title, detailedDescription: $description, freeformNotes: $notes)
    // ... additional sections
}

private func handleSubmit() {
    Task {
        do {
            _ = try await viewModel.save(/* params */)
            dismiss()
        } catch {
            // Error already set in viewModel.errorMessage
        }
    }
}
```

### Edit Mode Pattern
```swift
public struct [Entity]FormView: View {
    let entityToEdit: ([Abstraction], [Entity])?  // Optional for edit mode

    var isEditMode: Bool { entityToEdit != nil }
    var formTitle: String { isEditMode ? "Edit [Entity]" : "New [Entity]" }

    init(entityToEdit: ([Abstraction], [Entity])? = nil) {
        if let (abstraction, entity) = entityToEdit {
            // Initialize @State from existing data
            _title = State(initialValue: abstraction.title ?? "")
            // ...
        } else {
            // Initialize with defaults
            _title = State(initialValue: "")
            // ...
        }
    }
}
```

### List View Interactions
```swift
List {
    ForEach(items) { item in
        RowView(item)
            .onTapGesture { edit(item) }         // Tap → edit
            .swipeActions(edge: .trailing) {      // Right swipe → delete
                Button(role: .destructive) { delete(item) }
            }
            .swipeActions(edge: .leading) {       // Left swipe → edit
                Button { edit(item) }
                    .tint(.blue)
            }
    }
}
```

---

## Three-Layer Validation Strategy (Phase 2 - TODO)

### Layer A: Real-time UI Validation
- **Where**: SwiftUI views, ViewModels
- **When**: As user types, before submission
- **Purpose**: Immediate feedback, enable/disable submit

### Layer B: Coordination Validation
- **Where**: Coordinator services
- **When**: After form submission, before database write
- **Purpose**: Enforce business rules, multi-model consistency
- **Services**: `ActionValidator`, `GoalValidator` in `Services/Validation/`

### Layer C: Database Validation
- **Where**: Repository layer
- **When**: During database.write()
- **Purpose**: Catch constraints, translate database errors to user-facing messages

**See**: `Services/Validation/validation approach.md` for complete strategy

---

## Rearchitecture Status (v0.5.0)

**Current Phase**: Phase 4 (Validation Layer) - Ready to Start

| Phase | Status | Description |
|-------|--------|-------------|
| 1-2 | ✅ Done | Schema & Models (3NF normalization complete) |
| 3 | ✅ Done | Coordinators (All 4 complete: PersonalValue, Term, Action, Goal) |
| 4 | 🚧 Next | Validation Layer (Services/Validation/) |
| 5 | ⏳ | Protocol Redesign |
| 6 | ⏳ | ViewModel Layer |
| 7 | ⏳ | View Updates |

**Reference Documentation**:
- `docs/REARCHITECTURE_COMPLETE_GUIDE.md` - Complete 7-phase roadmap
- `docs/CONCURRENCY_STRATEGY.md` - Actor isolation, parallel operations, query patterns
- `docs/SQLITEDATA_API_AUDIT.md` - Query performance analysis
- `docs/API_AUDIT_2025-11-03.md` - API usage audit
- `docs/MODERN_SWIFT_REFERENCE.md` - Swift 6.2 patterns quick reference

---

## Common Patterns

### Creating New Coordinators
1. Define FormData struct in `Services/Coordinators/FormData/`
2. Implement Coordinator with create(), update(), delete()
3. Use database.write { } for atomic transactions
4. Insert abstraction first, then concrete entity with FK
5. Force unwrap after insert is safe: `.fetchOne(db)!`

**Reference**: `TimePeriodCoordinator.swift` (97 lines, full CRUD)

### Creating New ViewModels
1. Use `@Observable` (not ObservableObject)
2. Use `@Dependency(\.defaultDatabase)` with `@ObservationIgnored`
3. Computed property for coordinator (no lazy)
4. Individual parameters in save(), assemble FormData internally
5. Handle errors with errorMessage property

**Reference**: `TimePeriodFormViewModel.swift`

### Creating New Forms
1. Use FormScaffold template
2. Edit mode via optional `entityToEdit` parameter
3. Initialize @State in init() based on edit mode
4. Use DocumentableFields for standard fields
5. Handle async save in Task block

**Reference**: `TermFormView.swift` (184 lines, create + edit)

### Creating New List Views
1. Use @Fetch with FetchKeyRequest for related data
2. Create wrapper type for multi-model display
3. ForEach with tap and swipe actions
4. Empty state with helpful CTA

**Reference**: `TermsListView.swift` (101 lines)

---

## Authorship Convention

When creating **new** files, add header comment:
```swift
//
// FileName.swift
// Written by Claude Code on 2025-MM-DD
//
// PURPOSE:
// Brief description of what this file does
//
```

Not needed for small edits to existing files.

---

## Important: What NOT to Do

### ❌ Don't Add Business Logic to Models
```swift
// ❌ Bad - models are data structures only
extension Goal {
    func calculateProgress() async -> Double { ... }
}

// ✅ Good - logic in services
class ProgressCalculationService {
    func calculateGoalProgress(_ goal: Goal) async -> Double { ... }
}
```

### ❌ Don't Validate in Coordinators
```swift
// ❌ Bad - coordinators trust callers
func create(from formData: GoalFormData) async throws -> Goal {
    guard !formData.title.isEmpty else { throw ValidationError.emptyTitle }
    // ...
}

// ✅ Good - validation in ViewModels or Validators (Phase 2)
// Coordinators only enforce: assemble entity graphs, atomic transactions
```

### ❌ Don't Use ObservableObject
```swift
// ❌ Bad - legacy Combine pattern
class MyViewModel: ObservableObject {
    @Published var title: String = ""
}

// ✅ Good - modern Swift 5.9+ pattern
@Observable
class MyViewModel {
    var title: String = ""  // No @Published needed
}
```

### ❌ Don't Create Forms Without Edit Mode Support
```swift
// ❌ Bad - separate create/edit forms (duplication)
struct CreateGoalForm: View { ... }
struct EditGoalForm: View { ... }

// ✅ Good - single form with optional edit mode
struct GoalFormView: View {
    let goalToEdit: (Expectation, Goal)?
    var isEditMode: Bool { goalToEdit != nil }
}
```

---

## Key Files to Reference

**Coordinator Patterns**:
- `TimePeriodCoordinator.swift` ⭐ - Full CRUD, 2 models (reference implementation)
- `ActionCoordinator.swift` - Full CRUD, 3 models (Action + MeasuredAction[] + ActionGoalContribution[])
- `GoalCoordinator.swift` ⭐ - Full CRUD, 5+ models (most complex: Expectation + Goal + ExpectationMeasure[] + GoalRelevance[] + TermGoalAssignment?)
- `PersonalValueCoordinator.swift` - Create only, 1 model (needs update/delete added)

**ViewModel Patterns**:
- `TimePeriodFormViewModel.swift` ⭐ - @Observable, save/update/delete
- `PersonalValuesFormViewModel.swift` - Basic @Observable pattern

**View Patterns**:
- `TermFormView.swift` ⭐ - Edit mode support, state initialization
- `TermsListView.swift` ⭐ - Tap/swipe interactions, empty state, @Fetch usage
- `TermsQuery.swift` ⭐ - FetchKeyRequest JOIN pattern

**Model Examples**:
- `Protocols.swift` - Trait-based protocol composition
- `Expectation.swift` - DomainAbstraction example
- `Goal.swift` - DomainBasic example
- `MeasuredAction.swift` - DomainComposit example

---

## Breaking Changes & Migration

**Status**: Intentional breaking changes during rearchitecture (v0.5.0)

**What's Broken**:
- ❌ **MatchingService** - References removed `measuresByUnit` JSON field
- ❌ **Old GoalFormView** - References removed flat `measurementUnit`, `measurementTarget` fields
- ❌ **ActionsViewModel** - Expects JSON measuresByUnit (being replaced)
- ❌ **GoalsViewModel** - References removed `isSmart()` method

**Why**: Transitioning from JSON-based to fully normalized 3NF schema. These will be rebuilt in Phases 3-6 with proper multi-model support.

**Migration Strategy**: Clean break (no backward compatibility) - simpler than maintaining dual schemas.

---

## Testing

### Run Tests
```bash
# All tests
swift test

# Specific test target
swift test --filter ValidationTests
swift test --filter BusinessLogicTests

# Single test
swift test --filter MatchingServiceTests
```

### Test Status
- **Validation Tests**: Placeholder directory (`Tests/ValidationTests/`)
- **Business Logic Tests**: Some exist (`Tests/BusinessLogicTests/`)
- **UI Tests**: Via Xcode project (`GoalTracker/GoalTrackerUITests/`)

**TODO**: Integration tests for coordinators, FetchKeyRequest queries, multi-model transactions

---

## Platform & Version Requirements

### Current Platform Targets
- **iOS**: 26+ (Released September 15, 2025)
- **macOS**: Tahoe 26+ (Released September 15, 2025)
- **visionOS**: 26+ (Released September 15, 2025)
- **Swift**: 6.2 (Released September 15, 2025)

### Key Dependencies
- **SQLiteData**: 1.2.0+ (Point-Free's type-safe GRDB wrapper)
  - Documentation: https://swiftpackageindex.com/pointfreeco/sqlite-data
  - Uses `@Table` macro for compile-time schema generation
  - Query builder for type-safe queries
  - `#sql` macro for complex aggregations (used selectively)

### Swift 6.2 Features Used
- ✅ **Strict Concurrency** - All models are `Sendable`, actor isolation enforced
- ✅ **@MainActor** - ViewModels and Coordinators isolated to main thread
- ✅ **@Observable Macro** - Modern state management (not ObservableObject)
- ✅ **Structured Concurrency** - `async let` for parallel operations
- ✅ **nonisolated** - Database helper methods callable from any context
- ⏳ **InlineArray** - Future optimization for fixed-size collections (Swift 6.2 feature)
- ⏳ **Span** - Future safe memory access (Swift 6.2 feature)

### When to Fetch Current Documentation

**IMPORTANT**: Claude's training data may not include the latest iOS 26/Swift 6.2 patterns. When uncertain about:
- SwiftUI APIs or view modifiers
- Swift 6.2 concurrency patterns
- SQLiteData query syntax
- Platform-specific behaviors

**Use the doc-fetcher skill**:
```bash
# From project root
cd ~/.claude/skills/doc-fetcher
python doc_fetcher.py search "your query here"
```

**Pre-approved documentation sources**:
- `developer.apple.com` - Apple Developer Documentation
- `docs.swift.org` - Swift Language Guide
- `swiftpackageindex.com` - Swift package documentation (including SQLiteData)

See `swift/docs/DOCUMENTATION_REFRESH_GUIDE.md` for detailed guidance on when and how to fetch fresh documentation.

---

## Documentation Navigation

**Start Here**:
- `docs/REARCHITECTURE_COMPLETE_GUIDE.md` - Complete roadmap and design rationale
- `docs/MODERN_SWIFT_REFERENCE.md` - Swift 6.2 patterns quick reference
- `docs/DOCUMENTATION_REFRESH_GUIDE.md` - When/how to fetch current docs
- `Sources/Models/Abstractions/Protocols.swift` - Model architecture explanation

**Architecture & Patterns**:
- `docs/CONCURRENCY_STRATEGY.md` - Actor isolation, parallel operations, query patterns
- `Services/Validation/validation approach.md` - Three-layer validation strategy (Phase 2)
- `Sources/Database/Schemas/README.md` - Schema layer explanation
- `docs/SQLITEDATA_API_AUDIT.md` - Query strategy and performance

**Implementation Guides**:
- `docs/TERMS_UI_ENHANCEMENTS.md` - Term implementation patterns
- `docs/TERM_AUTO_INCREMENT_IMPLEMENTATION.md` - Auto-increment strategy
- `docs/HEALTHKIT_IMPLEMENTATION.md` - HealthKit integration
- `docs/INLINE_REFINEMENT_GUIDE.md` - Code review and refinement practices

**Archived Context**:
- `docs/archive/` - Historical planning documents (consolidated into COMPLETE_GUIDE)
