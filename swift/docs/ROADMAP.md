# Swift Implementation Roadmap

## Status: Relationships Database Integration Complete (Phases 1-3) + iOS 26/macOS 26 Conformance Planning Complete

Last Updated: October 24, 2025

---

## Recent Progress: iOS 26 / macOS 26 Conformance (October 24, 2025)

### ✅ Conformance Plan Complete
- **Created**: `iOS-docs/IOS26_MACOS26_CONFORMANCE_PLAN.md` (comprehensive 4-phase migration strategy)
- **Based on**: Official Apple documentation (Adopting Liquid Glass, Materials HIG, SwiftUI APIs)
- **Platform Target**: iOS 26.0+ / macOS 26.0+ (removed backward compatibility)
- **Timeline**: 8-12 hours for full implementation

**Key Changes:**
1. Liquid Glass usage aligned with Apple guidelines (navigation/controls only, NOT content)
2. Migration to native `.glassEffect()` API (replace manual implementations)
3. Platform convergence: `.sidebarAdaptable`, unified APIs across iOS/macOS
4. Documentation cleanup: Deleted 10 outdated planning docs, established clear hierarchy

**Implementation Phases:**
- Phase 1: Foundation updates (Package.swift → iOS 26+/macOS 26+)
- Phase 2: Design system refactor (separate glass from materials)
- Phase 3: View updates (apply correct materials per Apple HIG)
- Phase 4: Cleanup and documentation

**Status**: Planning complete, ready for implementation

---

## Previous Progress: Relationship System (October 22, 2025)

### ✅ Phase 1: Relationship Data Models (Complete)
- Created `ActionGoalRelationship.swift` (200 lines)
  - MatchMethod enum (autoInferred, userConfirmed, manual)
  - MatchCriteria enum (period, unit, description)
  - Computed properties: isInferred, isConfirmed, isHighConfidence, isAmbiguous
  - Full validation logic
- Created `GoalValueAlignment.swift` (220 lines)
  - AssignmentMethod enum (autoInferred, userConfirmed, manual)
  - Computed properties: isInferred, isConfirmed, isStrongAlignment, isSpeculative, qualityScore
  - Distinguishes alignment strength (objective) from confidence (epistemic)
  - Full validation logic
- **Tests**: 30 passing (15 per model)

### ✅ Phase 2: Business Logic Layer (Complete)
- **MatchingService.swift** (~200 lines) - Stateless matching functions
  - `matchesOnPeriod(action:goal:)`: Time-based matching
  - `matchesOnUnit(action:goal:)`: Measurement compatibility
  - `matchesWithActionability(action:goal:)`: JSON keyword + unit validation
  - `calculateConfidence(periodMatch:actionabilityMatch:)`: Scoring
- **InferenceService.swift** (~150 lines) - Thread-safe actor
  - `inferMatches(actions:goals:)`: Batch action×goal inference
  - `filterAmbiguous(_:confidenceThreshold:)`: Filter by confidence
  - `createManualRelationship(action:goal:contribution:)`: User-created
  - `confirmRelationship(_:)`: Upgrade inferred→confirmed
- **Tests**: 37 passing (23 MatchingService + 14 InferenceService)

### ✅ Phase 3: Database Integration (Complete)
- **Schema Updates**
  - Updated `action_goal_progress.sql`: INTEGER→TEXT UUID foreign keys
  - Added `uuid_id TEXT PRIMARY KEY`
  - Foreign keys reference `actions(uuid_id)` and `goals(uuid_id)`
- **GRDB Conformance**
  - `ActionGoalRelationship`: FetchableRecord, PersistableRecord, TableRecord
    - CodingKeys for snake_case↔camelCase mapping
    - UUID encoding strategy (.uppercaseString)
    - Column enums for type-safe queries
  - `GoalValueAlignment`: Same GRDB pattern (ready for future use)
  - `Goal`: Minimal GRDB conformance added
    - `databaseTableName = "goals"`
    - UUID encoding strategy
- **Integration Tests**: 13 passing
  - Basic CRUD (save, fetch, update, delete via GRDB native methods)
  - Enum serialization (MatchMethod, MatchCriteria)
  - Array serialization (matchedOn as JSON)
  - Foreign key cascade deletes
  - Edge cases (empty arrays, zero/large values)

**Total New Tests**: 80 (30 model + 37 business logic + 13 integration)
**Test Suite Status**: 281 tests passing (was 201 before relationship work)

---

## Known Limitations & Design Notes

### Relationship Entities
- **Do NOT conform to `Persistable` protocol** (join tables, not domain entities)
- Use GRDB's native methods directly: `insert()`, `update()`, `delete()`
- Cannot use DatabaseManager's generic `save()` (requires Persistable)
- This is intentional - relationships are projections/cache, not core domain entities

### Goal GRDB Integration
- Minimal conformance added (table name + UUID encoding only)
- Full direct GRDB integration deferred
- Currently uses Record pattern (GoalRecord) in production code
- Full migration planned in future phase

### Swift 6 Concurrency Patterns
- Mutable captures in async closures require pre-capture: `let copy = mutable; try await { use copy }`
- GRDB methods don't mutate structs, so prefer `let` over `var`
- Tests demonstrate proper Swift 6 strict concurrency compliance

---

## Next Steps

### Phase 4: Service/API Layer (~2 hours)
**Goal**: Public API for relationship operations

- Create `RelationshipService` actor
- Implement methods:
  - `inferAndSaveMatches(actions:goals:) async -> [ActionGoalRelationship]`
  - `getRelationshipsForGoal(id:) async -> [ActionGoalRelationship]`
  - `getRelationshipsForAction(id:) async -> [ActionGoalRelationship]`
  - `confirmRelationship(id:) async -> ActionGoalRelationship`
  - `deleteRelationship(id:) async`
- Integration tests (coordinate InferenceService + DatabaseManager)

### Phase 5: View Models (~2 hours)
**Goal**: SwiftUI bindings for relationship UI

- GoalProgressViewModel
  - Display progress metrics for a goal
  - Show contributing actions
  - Confirm/reject inferred relationships
- ActionMatchesViewModel
  - Show which goals an action contributes to
  - Edit/delete relationships

### Phase 6: Full Goal GRDB Integration (future)
**Goal**: Eliminate Record translation layer

- Remove GoalRecord
- Direct GRDB conformance (like Action)
- Polymorphic storage (Goal/Milestone/SmartGoal)
- Update DatabaseManager methods

---

## Architecture Achievements

### Type-Safe Relationships
- Compile-time guarantees via GRDB protocols
- Automatic JSON serialization (matchedOn arrays, enum raw values)
- UUID stability across save/fetch cycles

### Swift 6 Strict Concurrency
- Zero concurrency warnings
- Actor isolation for thread safety (InferenceService)
- Sendable conformance throughout

### Separation of Concerns
- Models: Pure data structures
- BusinessLogic: Stateless functions + coordination actors
- Database: Persistence via GRDB
- Tests: Comprehensive coverage at each layer

### Python Compatibility
- Same SQLite schema (shared/schemas/*.sql)
- Compatible data types (TEXT UUIDs, JSON fields)
- Matching business logic (ported from Python's ethica layer)

---

## File Summary

**New Files Created**:
- `Sources/Models/Relationships/ActionGoalRelationship.swift` (200 lines)
- `Sources/Models/Relationships/GoalValueAlignment.swift` (220 lines)
- `Sources/BusinessLogic/MatchingService.swift` (200 lines)
- `Sources/BusinessLogic/InferenceService.swift` (150 lines)
- `Tests/ModelTests/Relationships/ActionGoalRelationshipTests.swift` (345 lines, 15 tests)
- `Tests/ModelTests/Relationships/GoalValueAlignmentTests.swift` (346 lines, 15 tests)
- `Tests/BusinessLogicTests/MatchingServiceTests.swift` (300 lines, 23 tests)
- `Tests/BusinessLogicTests/InferenceServiceTests.swift` (250 lines, 14 tests)
- `Tests/IntegrationTests/RelationshipGRDBTests.swift` (570 lines, 13 tests)

**Modified Files**:
- `shared/schemas/action_goal_progress.sql` (UUID foreign keys)
- `Sources/Models/Kinds/Goals.swift` (added GRDB conformance)
- `Package.swift` (added BusinessLogic target)

**Total Lines Added**: ~2,531 lines of production code + tests

---

## Deferred Features

### Calendar & Reminders Integration (Explored Oct 22, 2025)
**Status**: Deferred for future consideration

**Explored Approaches**:
- **Option A**: One-way export to Apple Reminders.app (simpler, leverages native UI)
- **Option B**: Custom in-app calendar with two-way EventKit sync (complex, fully integrated)
- **Option C**: Hybrid read-only calendar view with editing in Reminders.app

**Key Insights**:
- EventKit provides read/write API, not automatic sync engine
- iCloud syncs Calendar/Reminders across devices, but NOT between apps
- Identity mapping (Goal UUID ↔ EKCalendarItem identifier) requires custom tracking
- Conflict resolution logic needed for bidirectional sync

**Decision**: Deferred until core functionality is complete. If implemented, recommend starting with Option A (export to Reminders) for simplicity.

**Resources**: See calendar sync schema draft (deleted Oct 22) for potential database structure
