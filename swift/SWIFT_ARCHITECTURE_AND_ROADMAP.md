# Swift Architecture & Implementation Roadmap

**Last Updated**: 2025-10-21
**Written by**: Claude Code with David Williams
**Swift Version**: 6.2
**GRDB Version**: 7.8.0

## Executive Summary

This document consolidates the Swift implementation architecture, completed work, and future refactoring plans for the Ten Week Goal App. Based on comprehensive research of Swift 6.2 patterns, GRDB documentation, and architectural analysis, we've identified opportunities to simplify the codebase while maintaining Python database compatibility.

**Current State**: 54 tests passing, zero concurrency warnings, functional but with architectural inconsistencies
**Goal**: Simplify architecture by eliminating translation layer (~700 lines), leverage GRDB's Codable integration, maintain clean separation of concerns

---

## Table of Contents

1. [Architecture Philosophy](#architecture-philosophy)
2. [Current Implementation Status](#current-implementation-status)
3. [Architectural Analysis](#architectural-analysis)
4. [GRDB Integration Patterns](#grdb-integration-patterns)
5. [Planned Refactoring](#planned-refactoring)
6. [Database Compatibility](#database-compatibility)
7. [Key Design Decisions](#key-design-decisions)
8. [Success Criteria](#success-criteria)

---

## Architecture Philosophy

### Core Principle: Idiomatic Swift with GRDB

The Swift implementation leverages type system strengths while maintaining database compatibility with Python:

```
Python:  Database → dict → StorageService → Domain Entity
         ↑ Runtime types, manual translation

Swift:   Database → GRDB Row → Domain Entity (Codable)
         ↑ Compile-time types, automatic translation
```

### Philosophical Naming Evolution

**Python (Aristotelian)**: categoriae (entities), ethica (business logic), rhetorica (translation), politica (infrastructure)

**Swift (Pragmatic)**: Models (domain), Database (infrastructure), Services (business logic when needed)

**Rationale**: Swift's protocol system encourages adjective-based thinking ("what things ARE") rather than noun-based categories. The Aristotelian naming broke down when protocols needed to describe capabilities rather than categories.

### Protocol Design: Ontology, Not Behavior

Protocols describe "ways of being" rather than "things to do":

- `Persistable` - Has identity and lifecycle
- `Recorded` - Data about completed actions (renamed from `Doable` - pending)
- `Completable` - Future-oriented targets with measurable completion
- `Motivating` - Provides purpose and alignment

**Note on Naming**: `Doable` → `Recorded` rename documented but not yet implemented, pending architectural stabilization.

---

## Current Implementation Status

### Package Structure

```
ten_week_goal_app/swift/
├── Package.swift                    # SPM manifest
├── Sources/
│   ├── Models/                      # Domain entities + protocols
│   │   ├── Protocols.swift          # Persistable, Recorded, Completable, Motivating
│   │   ├── Kinds/
│   │   │   ├── Actions.swift        # Action struct
│   │   │   ├── Goals.swift          # Goal, Milestone, SmartGoal
│   │   │   ├── Values.swift         # Value hierarchy (5 types)
│   │   │   └── Terms.swift          # GoalTerm, LifeTime
│   │   └── ModelExtensions.swift    # Validation logic
│   ├── Database/                    # GRDB infrastructure
│   │   ├── DatabaseManager.swift    # Actor-based database access (850 lines)
│   │   ├── DatabaseConfiguration.swift
│   │   ├── DatabaseError.swift
│   │   ├── Records/                 # Translation layer (TO BE REMOVED)
│   │   │   ├── ActionRecord.swift
│   │   │   ├── GoalRecord.swift
│   │   │   ├── ValueRecord.swift
│   │   │   └── TermRecord.swift
│   │   └── UUIDMapper.swift         # ID mapping (TO BE REMOVED)
│   ├── App/                         # SwiftUI views (prototype)
│   └── AppRunner/                   # macOS app entry point
├── Tests/                           # 54 tests passing
└── shared/schemas/                  # SQL schemas (shared with Python)
```

### Dependencies

- **GRDB.swift 7.8.0**: SQLite wrapper with Codable integration
- **Swift 6.2**: Strict concurrency enabled
- **Platform**: macOS 14+, iOS 17+ (targets set but focus is macOS)

### Test Coverage (54 tests, all passing)

- **Action Tests**: 5 tests (creation, validation, equality)
- **Goal Tests**: 9 tests (Goal, Milestone, SmartGoal validation)
- **Term Tests**: 22 tests (GoalTerm, LifeTime business logic)
- **Value Tests**: 18 tests (5 value types, hierarchy validation)

### Build Status

✅ Zero compilation errors
✅ Zero concurrency warnings
✅ Swift 6.2 strict concurrency compliance
⚠️ Architectural inconsistencies identified (see below)

---

## Architectural Analysis

### Problem: Inconsistent Architecture Claims vs Reality

**Documentation Claims** (SWIFTROADMAP.md):
> "Swift version is simpler (no translation layer needed)"

**Reality** (codebase):
- Has `ActionRecord`, `GoalRecord`, `ValueRecord`, `TermRecord` (~600 lines)
- Has `UUIDMapper` for INTEGER ↔ UUID translation (~116 lines)
- Has bidirectional conversion methods (`toDomain()`, `toRecord()`)

**Conclusion**: We **DO** have a translation layer (Rhetorica), whether documented or not.

### Architectural Layers (Current)

```
┌─────────────────────────────────────────┐
│  App (SwiftUI)                          │
│  - Views (prototype only)               │
└─────────────────────────────────────────┘
              ↓ uses
┌─────────────────────────────────────────┐
│  Models (Domain)                        │
│  - Action, Goal, Value, Term (structs)  │
│  - Protocols (Persistable, etc.)        │
└─────────────────────────────────────────┘
              ↓ translated by
┌─────────────────────────────────────────┐
│  Database/Records (Translation)         │ ← UNNECESSARY
│  - ActionRecord, GoalRecord, etc.       │
│  - toDomain(), toRecord() methods       │
│  - UUIDMapper (INTEGER ↔ UUID)          │
└─────────────────────────────────────────┘
              ↓ persisted by
┌─────────────────────────────────────────┐
│  DatabaseManager (Infrastructure)       │
│  - Actor-isolated GRDB access           │
│  - Entity-specific fetch/save methods   │
└─────────────────────────────────────────┘
              ↓ reads/writes
┌─────────────────────────────────────────┐
│  SQLite Database (Storage)              │
│  - Shared schemas (Python compatible)  │
└─────────────────────────────────────────┘
```

### Why Translation Layer Exists (But Shouldn't)

**Reason 1: Python Compatibility Assumption**
- Initially assumed INTEGER IDs needed for Python compatibility
- Created UUIDMapper to bridge UUID (Swift) ↔ INTEGER (Database)
- Actually: Python can use UUID TEXT columns just as easily

**Reason 2: Misunderstanding GRDB Patterns**
- Thought Record types were required for GRDB
- Didn't realize domain models can conform to `FetchableRecord + PersistableRecord` directly
- GRDB's Codable integration eliminates manual translation

**Result**: ~700 lines of unnecessary code

---

## GRDB Integration Patterns

### Official GRDB Pattern (from docs)

**Recommended Approach** (RecordRecommendedPractices.md):

```swift
// Domain model conforms to GRDB protocols directly
struct Action: Codable, Sendable, FetchableRecord, PersistableRecord, TableRecord {
    var id: UUID
    var friendlyName: String?
    var measuresByUnit: [String: Double]?
    var logTime: Date

    // CodingKeys for snake_case ↔ camelCase mapping
    enum CodingKeys: String, CodingKey {
        case id
        case friendlyName = "friendly_name"
        case measuresByUnit = "measurement_units_by_amount"
        case logTime = "log_time"
    }

    // Columns for type-safe queries (optional but recommended)
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let friendlyName = Column(CodingKeys.friendlyName)
        static let measuresByUnit = Column(CodingKeys.measuresByUnit)
        static let logTime = Column(CodingKeys.logTime)
    }

    // TableRecord conformance
    static let databaseTableName = "actions"
}

// No Record type needed!
// No manual init(row:) or encode(to:) needed!
// Codable provides everything automatically!
```

### UUID as Primary Key Pattern

**From GRDB docs** (README.md line 1392-1397):

> "UUID can be stored as 16-byte blobs:
> ```swift
> try db.create(table: "players") { t in
>     t.column("id", .blob).primaryKey()
> }
> ```
>
> GRDB can decode UUIDs from both blobs and strings like "E621E1F8-...""

**For this project**: Use TEXT storage (36 bytes) for human readability and Python compatibility, even though BLOB (16 bytes) is more efficient.

### Protocol Conformance Requirements

#### FetchableRecord
```swift
protocol FetchableRecord {
    init(row: Row) throws
}
```
- **Auto-implemented** by Codable conformance
- Enables: `fetchAll()`, `fetchOne()`, `fetchCursor()`, `fetchSet()`

#### PersistableRecord
```swift
protocol PersistableRecord: TableRecord, EncodableRecord {
    func didInsert(_ inserted: InsertionSuccess)
}
```
- **Auto-implemented** by Codable conformance
- **didInsert()** optional (used for INTEGER auto-increment, not needed for UUID)
- Enables: `insert()`, `update()`, `save()`, `delete()`, `upsert()`

#### TableRecord
```swift
protocol TableRecord {
    static var databaseTableName: String { get }
}
```
- **Must implement** (simple one-liner)
- Auto-derived from type name if not specified

### CodingKeys Pattern

**Purpose**: Map Swift camelCase properties to database snake_case columns

**Pattern**:
```swift
enum CodingKeys: String, CodingKey {
    case id                              // Same name: no mapping needed
    case friendlyName = "friendly_name"  // Maps friendlyName ↔ friendly_name
    case measuresByUnit = "measurement_units_by_amount"  // Complex mapping
}
```

**GRDB uses CodingKeys for**:
- Automatic `init(row:)` implementation (FetchableRecord)
- Automatic `encode(to:)` implementation (PersistableRecord)
- No manual translation code needed!

---

## Planned Refactoring

### Goal: Eliminate Translation Layer

**Delete ~700 lines**:
- ❌ `Database/Records/ActionRecord.swift`
- ❌ `Database/Records/GoalRecord.swift`
- ❌ `Database/Records/ValueRecord.swift`
- ❌ `Database/Records/TermRecord.swift`
- ❌ `Database/UUIDMapper.swift`
- ❌ `uuid_mappings` database table

**Add GRDB conformances to domain models**:
- ✅ Action → add `FetchableRecord, PersistableRecord, TableRecord`
- ✅ Goal/Milestone/SmartGoal → add GRDB conformances
- ✅ Value hierarchy → add GRDB conformances
- ✅ Term types → add GRDB conformances

**Simplify DatabaseManager**:
- ❌ Delete entity-specific methods (`fetchGoals()`, `saveAction()`, etc.)
- ✅ Keep generic methods only (`fetchAll<T>()`, `save<T>()`)
- Reduce from 850 lines → ~300 lines

### Phase-by-Phase Plan

#### Phase 1: Add UUID Column to Database Schema (1 hour)

**Goal**: Support UUID storage alongside INTEGER id

**Tasks**:
1. Add `uuid_id TEXT UNIQUE` column to all entity tables
2. Generate UUIDs for existing rows (if any test data exists)
3. Update schema files in `shared/schemas/`
4. Verify Python can read/write UUID column

**Migration Script** (example):
```sql
-- actions.sql
ALTER TABLE actions ADD COLUMN uuid_id TEXT UNIQUE;
UPDATE actions SET uuid_id = lower(hex(randomblob(16))) WHERE uuid_id IS NULL;

-- Repeat for goals, values, terms tables
```

**Outcome**: Database supports both INTEGER (Python legacy) and UUID (Swift native)

#### Phase 2: Add GRDB to Domain Models (2 hours)

**Goal**: Make domain models conform to GRDB protocols directly

**Tasks**:
1. Add GRDB import to Models target in Package.swift
2. Add conformances to Action.swift:
   ```swift
   struct Action: Persistable, Recorded, Codable, Sendable,
                  FetchableRecord, PersistableRecord, TableRecord
   ```
3. Add CodingKeys enum (already exists, verify completeness)
4. Add Columns enum (optional, for query builder)
5. Add `static let databaseTableName = "actions"`
6. Repeat for Goal, Value, Term types

**Test Strategy**:
- Start with Action (simplest case)
- Write integration test: `try await db.save(&action)`, verify round-trip
- Once working, apply pattern to other types

**Outcome**: Domain models can persist directly, no Record types needed

#### Phase 3: Update DatabaseManager (1 hour)

**Goal**: Use generic CRUD methods only

**Tasks**:
1. Update `fetchAll<T>()` to use `uuid_id` column instead of INTEGER id
2. Remove entity-specific methods:
   - ❌ `fetchGoals()` → use `fetchAll<Goal>()`
   - ❌ `saveAction(_ action:)` → use `save(&action)`
3. Update archive functionality to work with generic types
4. Update tests to use generic methods

**Example Before/After**:
```swift
// Before (entity-specific):
let goals = try await db.fetchGoals()
try await db.saveAction(action)

// After (generic):
let goals: [Goal] = try await db.fetchAll()
var mutableAction = action
try await db.save(&mutableAction)
```

**Outcome**: DatabaseManager shrinks to ~300 lines, fully generic

#### Phase 4: Delete Translation Layer (30 minutes)

**Goal**: Remove all Record types and UUID mapping

**Tasks**:
1. Delete `Database/Records/` directory
2. Delete `Database/UUIDMapper.swift`
3. Update tests to use domain models directly
4. Remove `uuid_mappings` table from schema
5. Run full test suite, verify all 54 tests pass

**Outcome**: ~700 lines of code deleted, architecture simplified

#### Phase 5: Documentation Update (30 minutes)

**Goal**: Align documentation with reality

**Tasks**:
1. Update this file with actual implementation
2. Update CLAUDE.md with simplified architecture
3. Document decision rationale
4. Add GRDB patterns reference

### Total Estimated Time: 5 hours

---

## Database Compatibility

### Shared Schema Location

**Path**: `ten_week_goal_app/shared/schemas/*.sql`

**Files**:
- `actions.sql` - Action table schema
- `goals.sql` - Goal table (supports Goal, Milestone, SmartGoal via `goal_type` column)
- `values.sql` - Values table (supports 5 types via `incentive_type` column)
- `terms.sql` - Terms table (GoalTerm, LifeTime)
- `archive.sql` - Audit trail for updates/deletes

### Field Mapping: Swift ↔ Database

| Swift Property | Database Column | Type | Notes |
|----------------|-----------------|------|-------|
| `id: UUID` | `uuid_id` | TEXT | Stored as string "E621E1F8-..." |
| `friendlyName` | `friendly_name` | TEXT | CodingKeys mapping |
| `measuresByUnit` | `measurement_units_by_amount` | TEXT | JSON dictionary |
| `logTime` | `log_time` | TEXT | ISO8601 string |
| `startTime` | `start_time` | TEXT | ISO8601 string (nullable) |

### Python ↔ Swift Interoperability

**Current State**:
- Python uses INTEGER `id` column (auto-increment)
- Swift uses UUID, mapped via `UUIDMapper` to INTEGER

**After Refactoring**:
- Both Python and Swift use `uuid_id TEXT` column
- Python generates UUIDs: `str(uuid.uuid4())`
- Swift generates UUIDs: `UUID()`
- INTEGER `id` column can be deprecated (or kept for legacy compatibility)

**Migration Path**:
```python
# Python update (minimal change)
import uuid

class Action:
    def __init__(self, description: str):
        self.id = str(uuid.uuid4())  # Changed from: assigned by database
        self.description = description
```

---

## Key Design Decisions

### Decision 1: Direct GRDB Conformance (Not Translation Layer)

**Question**: Should domain models conform to GRDB protocols directly, or use Record types?

**Answer**: Direct conformance

**Rationale**:
- ✅ **GRDB's recommended pattern** (per RecordRecommendedPractices.md)
- ✅ **Codable provides automatic serialization** (no manual `init(row:)` or `encode(to:)`)
- ✅ **Simpler codebase** (~700 lines eliminated)
- ✅ **Protocols are structural** (describe fields, not behavior)
- ✅ **No violation of separation of concerns** (infrastructure markers like Codable, Equatable)
- ❌ Domain models "know about" GRDB (acceptable: compile-time dependency, no runtime coupling)

**Verdict**: The separation of concerns argument for Record types is valid in principle but unnecessary in practice. GRDB protocols are **structural interfaces** (like Codable), not behavioral dependencies.

### Decision 2: UUID as Primary Key (Not INTEGER)

**Question**: Should we use INTEGER auto-increment or UUID for primary keys?

**Answer**: UUID

**Rationale**:
- ✅ **Idiomatic Swift** (generate at initialization, no database round-trip)
- ✅ **No mutation needed** (can use `PersistableRecord` not `MutablePersistableRecord`)
- ✅ **Python compatible** (TEXT storage works for both)
- ✅ **Distributed-system-friendly** (UUIDs are globally unique)
- ❌ Larger storage (36 bytes TEXT vs 8 bytes INTEGER, acceptable tradeoff)

**Implementation**:
```swift
struct Action {
    var id: UUID = UUID()  // Generated at init, not by database
}
```

### Decision 3: Actor-Based DatabaseManager (Not Locks)

**Question**: How to ensure thread-safe database access?

**Answer**: Actor wrapping GRDB's DatabasePool

**Rationale**:
- ✅ **Swift 6 concurrency model** (actors serialize access automatically)
- ✅ **Compile-time safety** (Sendable enforcement prevents data races)
- ✅ **No manual locking** (actor handles synchronization)
- ✅ **Clear async boundaries** (all database calls use `await`)

**Pattern**:
```swift
actor DatabaseManager {
    private let dbPool: DatabasePool

    func fetchAll<T: FetchableRecord & Sendable>() async throws -> [T] {
        try await dbPool.read { db in try T.fetchAll(db) }
    }
}
```

### Decision 4: Protocol Extensions for Business Logic

**Question**: Where should calculated properties like `progress` or `isComplete` live?

**Answer**: Protocol extensions (not database layer)

**Rationale**:
- ✅ **Single Responsibility Principle** (business logic separate from persistence)
- ✅ **Testable** (can test without database)
- ✅ **Reusable** (any Completable type gets default implementations)
- ✅ **Compile-time dispatch** (no runtime overhead)

**Pattern**:
```swift
extension Completable {
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    var isComplete: Bool { progress >= 1.0 }
}
```

### Decision 5: JSON Columns for Flexible Data

**Question**: Should `measurements: [String: Double]` be normalized into separate table or stored as JSON?

**Answer**: JSON column

**Rationale**:
- ✅ **Flexibility** (easy to add new measurement types without schema changes)
- ✅ **Python compatibility** (both use JSON TEXT storage)
- ✅ **Codable handles serialization** (automatic, zero-cost abstraction)
- ✅ **Matches Python pattern** (consistency across implementations)
- ❌ Can't query inside JSON efficiently (acceptable: we fetch all measurements anyway)

**Implementation**:
```swift
struct Action: Codable {
    var measuresByUnit: [String: Double]?
    // GRDB automatically serializes as JSON TEXT
}
```

---

## Success Criteria

### Minimum Viable Product (MVP)

- ✅ Domain models complete (Action, Goal, Value, Term with validation)
- ✅ Database layer functional (DatabaseManager with CRUD operations)
- ✅ 54+ tests passing
- ✅ Zero concurrency warnings
- 🔲 Translation layer eliminated (~700 lines deleted)
- 🔲 Generic CRUD only (no entity-specific DatabaseManager methods)
- 🔲 UUID column in database schema
- 🔲 Documentation accurate (this file)

### Production Ready

All MVP criteria plus:

- 🔲 Business logic layer (progress calculation, matching, inference)
- 🔲 90+ tests (match Python test coverage)
- 🔲 Python ↔ Swift database compatibility verified
- 🔲 Performance benchmarks documented
- 🔲 Error handling comprehensive

### Stretch Goals

- 🔲 CLI interface (parity with Python's 25 commands)
- 🔲 SwiftUI interface (native macOS app)
- 🔲 iOS compatibility
- 🔲 Swift Testing migration (from XCTest)

---

## Appendix A: GRDB Resources

### Official Documentation

**Local Paths** (in this project):
- Main README: `/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/.build/checkouts/GRDB.swift/README.md`
- Record Practices: `/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/.build/checkouts/GRDB.swift/GRDB/Documentation.docc/RecordRecommendedPractices.md`
- Migrations: `.../GRDB.swift/Documentation/Migrations.md`
- Concurrency: `.../GRDB.swift/Documentation/Concurrency.md`

**Online**:
- SwiftPackageIndex: https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/
- GitHub: https://github.com/groue/GRDB.swift

### Key Sections Referenced

- README lines 1658-2500: Complete Records section
- README lines 2586-2837: Codable Records with CodingKeys examples
- RecordRecommendedPractices lines 60-103: Basic record structure
- RecordRecommendedPractices lines 145-171: UUID vs INTEGER IDs

---

## Appendix B: Swift 6.2 Features Used

### Core Language Features

**Strict Concurrency** (Swift 6):
- ✅ Actor isolation (`DatabaseManager` is an actor)
- ✅ Sendable protocol (all domain models are `Sendable`)
- ✅ Async/await (all database operations)
- ✅ Compile-time data race prevention

**Type System** (Swift 6.2):
- ✅ Protocol composition (`Persistable, Recorded, Codable, Sendable, ...`)
- ✅ Generic constraints (`<T: FetchableRecord & Sendable>`)
- ✅ Associated types (in protocol definitions)
- ✅ Codable (automatic serialization)

**Not Currently Used** (but available):
- ⏭️ Typed throws (SE-0413) - consider for DatabaseError
- ⏭️ Swift Testing framework - consider migration from XCTest
- ⏭️ Approachable concurrency (SE-0466) - may reduce boilerplate
- ⏭️ SwiftUI enhancements - if building UI

### Performance Features (Not Yet Profiled)

- ⏭️ Whole Module Optimization (WMO) - enable for Release builds
- ⏭️ InlineArray - for fixed-size collections (if bottleneck found)
- ⏭️ Copy-on-Write - automatic for standard collections

**Strategy**: Profile first, optimize only proven bottlenecks.

---

## Appendix C: Lessons Learned

### Swift 6 Concurrency

**What Worked**:
- Actor-based database access is straightforward and safe
- Sendable protocol catches threading issues at compile time
- Async/await is clearer than completion handlers

**What Was Surprising**:
- No issues with actor isolation (zero warnings)
- GRDB works seamlessly with actors
- Protocol conformance simpler than expected

### GRDB Integration

**What Worked**:
- Codable integration is "magic" (truly zero boilerplate)
- CodingKeys pattern handles all column mapping
- Generic CRUD methods work for all types

**What Was Surprising**:
- Don't need Record types (Codable provides everything)
- UUID as TEXT works perfectly (no special handling needed)
- JSON columns "just work" with Codable dictionaries

### Architecture

**What Worked**:
- Protocol-oriented design scales well
- Value types (structs) avoid concurrency issues
- Generic constraints enable type-safe database operations

**What Didn't Work**:
- Translation layer added complexity without benefit
- UUIDMapper was solving a non-problem (could use TEXT UUIDs from start)
- Entity-specific DatabaseManager methods duplicated generic code

### Process

**What Worked**:
- Research first, code second (saved time by avoiding mistakes)
- Test-driven development caught issues early
- Incremental approach (Action first, then others)

**What Would Help Next Time**:
- Read GRDB docs thoroughly before designing architecture
- Trust Swift's type system (fight less, leverage more)
- Question assumptions about "necessary" complexity

---

**End of Document**

This roadmap will be updated as refactoring progresses. All architectural decisions are documented with rationale to support future maintainers (including future David).
