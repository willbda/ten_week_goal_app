# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status: Active Rearchitecture (v0.5.0)

**Current Phase**: Phase 3 - Repository/Service Layer (ready to start)
**Active Development**: Swift implementation only
**Python**: Archived (tagged v1.0-python, no longer developed)

The Swift codebase is undergoing a **complete 3NF database rearchitecture** with intentional breaking changes. Phases 1-2 (Schema & Models) complete. See `swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md` for comprehensive roadmap.

**Breaking**: Old ViewModels and Views have been removed - will be rebuilt in Phases 5-6.

---

## Swift Development Commands

### Building & Testing
```bash
cd swift/

# Build the package
swift build

# Run all tests
swift test

# Run specific test target
swift test --filter ModelTests

# Build for iOS/macOS (requires Xcode)
xcodebuild -scheme GoalTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Database Operations
```bash
# Create database from schema
sqlite3 goaltracker.db < Sources/Database/Schemas/schema_current.sql

# Verify schema structure
sqlite3 goaltracker.db ".schema"

# Run migration (when available)
sqlite3 goaltracker.db < Sources/Database/complete_migration.sql
```

### Code Quality
```bash
# Swift 6.2 strict concurrency enabled - expect warnings during rearchitecture
swift build --strict-concurrency=complete
```

---

## Architecture Overview

### Three-Layer Model Hierarchy

The Swift models follow a strict ontological hierarchy based on **purpose and abstraction level**:

**1. Abstractions/ (`Sources/Models/Abstractions/`)**
- **Protocol**: `DomainAbstraction` (full metadata: title, description, notes, logTime)
- **Purpose**: Abstract types that can be specialized
- **Examples**:
  - `Action` - Abstract doable activity
  - `Expectation` - Abstract future-oriented goal
  - `Measure` - Abstract unit of measurement (km, hours, count)
  - `PersonalValue` - Abstract motivator
  - `TimePeriod` - Abstract time span
- **Use**: Define high-level capabilities; can be refined into Basics

**2. Basics/ (`Sources/Models/Basics/`)**
- **Protocol**: `DomainBasic` (lightweight: just id + foreign keys)
- **Purpose**: Concrete working entities with specific purpose
- **Examples**:
  - `Goal` - Concrete expectation (references abstract Expectation)
  - `Milestone` - Concrete expectation variant
  - `Term` - Concrete 10-week period (references TimePeriod)
  - `ExpectationMeasure` - Defines target metrics for goals
- **Use**: Day-to-day entities users create/edit; reference Abstractions

**3. Composits/ (`Sources/Models/Composits/`)**
- **Protocol**: `DomainComposit` (minimal: id + 2+ foreign keys)
- **Purpose**: Pure junction tables for many-to-many relationships
- **Examples**:
  - `MeasuredAction` - Links Action → Measure → value
  - `GoalRelevance` - Links Goal → PersonalValue (why relevant)
  - `ActionGoalContribution` - Links Action → Goal (progress tracking)
  - `TermGoalAssignment` - Links Term → Goal (planning)
- **Use**: Relationship data only; no business logic

**Why This Hierarchy?**
- Abstractions = "What could exist" (ontology)
- Basics = "What does exist" (concrete instances)
- Composits = "How things relate" (relationships)

### Module Structure

```
swift/Sources/
├── Models/          # Domain entities (Abstractions/Basics/Composits)
├── Services/        # Data access (repositories, platform services)
├── Logic/           # Business rules (validation, calculations)
└── App/             # SwiftUI views and app entry point
```

**Dependencies**:
- Models: SQLiteData only (no other modules)
- Services: Models + SQLiteData
- Logic: Models only
- App: All modules + SQLiteData

### Database: 3NF Normalized

**Key changes from old schema**:
- ❌ JSON fields eliminated (`measuresByUnit` → `MeasuredAction` junction)
- ❌ 4 value tables consolidated → 1 `personalvalues` with `ValueLevel` enum
- ✅ Metrics are first-class entities (not JSON dictionaries)
- ✅ Explicit junction tables for all relationships
- ✅ Proper foreign keys and indexes

**Schema files**: `swift/Sources/Database/Schemas/`
- `schema_current.sql` - Complete production schema
- `abstractions.sql` - DomainAbstraction tables
- `basics.sql` - DomainBasic tables
- `composits.sql` - DomainComposit junction tables

---

## Development Workflow

### Current Phase: Building Repository Layer

**What's needed** (see `swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md` Phase 3):

1. **ActionRepository** - CRUD + find by metric, sum by metric
2. **GoalRepository** - CRUD + find with progress, find by term/value
3. **ValueRepository** - Find by level, find aligned goals
4. **ProgressCalculationService** - Calculate goal/term progress
5. **AlignmentService** - Value alignment scoring
6. **MetricAggregationService** - Totals, averages, trends

**Pattern**:
```swift
// Services depend on Models, return domain types
@MainActor
class ActionRepository: ObservableObject {
    func create(action: Action, measures: [(Measure, Double)]) async throws
    func findWithMeasures(id: UUID) async throws -> (Action, [MeasuredAction])
}
```

### Adding New Models

Models must conform to one of three protocols based on purpose:

```swift
// Abstraction (full metadata)
@Table
public struct MyAbstraction: DomainAbstraction, Sendable {
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date
    // + domain-specific fields
}

// Basic (lightweight, references abstractions)
@Table
public struct MyBasic: DomainBasic, Sendable {
    public var id: UUID
    public var abstractionId: UUID  // FK to abstraction
    // + minimal domain fields
}

// Composit (junction table)
@Table
public struct MyComposit: DomainComposit, Sendable {
    public var id: UUID
    public var entityAId: UUID
    public var entityBId: UUID
    // + relationship-specific data only
}
```

**Place in correct directory**:
- Abstractions → `Sources/Models/Abstractions/`
- Basics → `Sources/Models/Basics/`
- Composits → `Sources/Models/Composits/`

### Testing Strategy

**Current state**: Most tests broken after model reorganization
**Priority**: Integration tests for repository layer (Phase 3)

```bash
# When tests are restored:
swift test --filter ModelTests       # Unit tests for models
swift test --filter ServiceTests     # Repository/service tests
swift test --filter IntegrationTests # Full data cycle tests
```

---

## Key Design Patterns

### 1. Separation of Concerns

**Models**: Pure data structures, no queries
```swift
// ✅ Good - just structure
struct Goal: DomainBasic {
    var id: UUID
    var expectationId: UUID
}

// ❌ Bad - queries in model
extension Goal {
    func fetchProgress() async throws -> Double { ... }
}
```

**Services**: Handle queries and business logic
```swift
// ✅ Good - service handles queries
class GoalRepository {
    func calculateProgress(for goal: Goal) async throws -> Double { ... }
}
```

### 2. Junction Tables Are Minimal

Composits have **no business logic**, just relationship data:

```swift
// ✅ Good - minimal junction
struct MeasuredAction: DomainComposit {
    var id: UUID
    var actionId: UUID
    var measureId: UUID
    var value: Double      // The measurement value
    var createdAt: Date    // When measured
}

// ❌ Bad - business logic in junction
struct MeasuredAction {
    func validate() -> Bool { ... }  // NO
    func convert(to unit: String) { ... }  // NO
}
```

### 3. ViewModels Come Later (Phase 5)

Current broken ViewModels have been removed. New pattern:

```swift
// Phase 5: ViewModels will use repositories
@MainActor
class ActionEntryViewModel: ObservableObject {
    private let actionRepo: ActionRepository
    private let metricRepo: MetricRepository

    @Published var availableMeasures: [Measure] = []

    func saveAction() async {
        try await actionRepo.create(action, measures: measurements)
    }
}
```

---

## Common Patterns & Idioms

### SQLiteData @Table Usage

All models use SQLiteData's `@Table` macro:

```swift
import SQLiteData

@Table
public struct MyModel: DomainAbstraction, Sendable {
    public var id: UUID = UUID()
    public var title: String?
    // ...
}
```

**Database operations** (examples from MetricRepository):
```swift
// Fetch all
let measures = try await Measure.all()

// Filter
let measures = try await Measure.filter(\.metricType == "distance")

// Find by ID
if let measure = try await Measure.find(id) { ... }

// Insert
try await measure.insert()

// Update
var updated = existing
updated.value = newValue
try await updated.update()

// Delete
try await measure.delete()
```

### Enum Conformance for Database Storage

Enums need QueryRepresentable and QueryBindable:

```swift
public enum ValueLevel: String, Codable, Sendable,
    CaseIterable, QueryRepresentable, QueryBindable {
    case general = "general"
    case major = "major"
    case highestOrder = "highest_order"
    case lifeArea = "life_area"

    // Required for SQLiteData
    public static let queryRepresentationType: QueryRepresentationType = .text
}
```

---

## Python Implementation (Archived)

**Status**: Effectively archived, tagged as v1.0-python
**Location**: `python/` directory
**Architecture**: Flask API + CLI using Aristotelian layer names (categoriae, ethica, politica, rhetorica)

Not actively developed. Focus on Swift implementation.

---

## Documentation Structure

**Primary docs**:
- `swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md` - Complete roadmap (Phases 1-7)
- `VERSIONING.md` - Version roadmap and phase timeline
- `DOCUMENTATION_STATUS.md` - Gap analysis and alignment

**Schema docs**:
- `swift/Sources/Database/Schemas/README.md` - Schema layer explanation
- `swift/docs/SCHEMA_CURRENT.md` - Current schema state

**Archived planning**:
- `swift/docs/archive/` - Historical planning documents (3 merged into COMPLETE_GUIDE)

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

## Current Priorities (Phase 3)

1. **Build repository layer** for Actions, Goals, Values
2. **Implement business services** for progress calculation and alignment
3. **Test with real data** from `proposed_3nf.db`
4. **Fix broken components** that reference old schema (MatchingService)

See `swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md` Phase 3 section for detailed requirements.
