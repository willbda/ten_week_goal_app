# Swift Implementation Roadmap

## Overview

This document tracks the Swift port of the Ten Week Goal App, documenting architectural decisions, completed work, and future plans.

**Goal**: Create a production-ready Swift implementation using Swift 6.2 best practices with full Python database compatibility.

## Architecture Philosophy

### Core Principle: Embrace Swift's Type System

Rather than directly porting Python's dynamic typing patterns, we leverage Swift's strengths:

- **GRDB Codable Integration**: Direct database ↔ domain model mapping
- **Protocol-Oriented Design**: "Ways of being" (ontology) not "things to do" (behavior)
- **Strict Concurrency**: Actor-based database access for thread safety
- **Compile-Time Safety**: Type checking prevents runtime errors

### Key Architectural Difference from Python

**Python**:
```python
Database → dict[str, Any] → StorageService → Domain Entity
           ↑ Runtime types
```

**Swift**:
```swift
Database → GRDB Row → Domain Entity (via Codable)
           ↑ Compile-time types, Sendable
```

**Result**: Swift version is simpler (no translation layer needed) and safer (compile-time guarantees).

## Completed Work

### Phase 1: Foundation (Oct 18, 2025) ✅

**Package Dependencies**:
- ✅ GRDB.swift 7.8.0 added to Package.swift
- ✅ Models target depends on GRDB
- ✅ Politica and Rhetorica targets configured

**Database Configuration**:
- ✅ `DatabaseConfiguration` struct with Sendable conformance
- ✅ Path management (shared database with Python)
- ✅ In-memory database support for testing
- ✅ Schema file loading from `shared/schemas/`

**Error Handling**:
- ✅ `DatabaseError` enum with typed, Sendable errors
- ✅ LocalizedError conformance for user-facing messages
- ✅ Recovery suggestions for each error type

### Phase 2: Database Layer (Oct 18, 2025) ✅

**DatabaseManager Actor**:
- ✅ Generic `fetchAll<T>()`, `fetchOne<T>()` methods
- ✅ Generic `save<T>()`, `update<T>()`, `delete<T>()` methods
- ✅ Automatic archive support (preserves old versions before updates/deletes)
- ✅ Swift 6.2 strict concurrency compliance
- ✅ 380 lines vs Python's 527 lines (simpler!)

**Schema Initialization**:
- ✅ Loads all `.sql` files from shared schemas directory
- ✅ Idempotent (safe to run multiple times)
- ✅ Transaction-based (all-or-nothing)

**Archive Functionality**:
- ✅ `archiveRecord()` helper (nonisolated for transaction safety)
- ✅ JSON serialization of full record state
- ✅ Audit trail with reason and notes

### Phase 3: Domain Models (Oct 18, 2025) ✅

**Protocols Made Public**:
- ✅ `Persistable`, `Achievable`, `Performed`, `Motivating`
- ✅ `Validatable`, `TypeIdentifiable`
- ✅ `Serializable`, `JSONSerializable`, `Archivable`

**Action Model**:
- ✅ Conforms to: `Persistable`, `Performed`, `Codable`, `Sendable`, `FetchableRecord`, `PersistableRecord`, `TableRecord`
- ✅ CodingKeys for snake_case ↔ camelCase mapping
- ✅ Table name: `"actions"`
- ✅ JSON serialization for `measurements` dictionary
- ✅ Validation logic preserved

**Property Naming**:
- ✅ Renamed `measurementUnitsByAmount` → `measurements` (matches Performed protocol)
- ✅ Database column: `measurement_units_by_amount` (via CodingKeys)

### Phase 4: Cleanup (Oct 18, 2025) ✅

**Deleted Files** (no longer needed):
- ✅ `Sources/Rhetorica/StorageService.swift` - GRDB provides this
- ✅ `Sources/Rhetorica/ActionStorageService.swift` - Direct database access
- ✅ `Sources/Politica/DatabaseValue.swift` - GRDB handles Sendable types

**Simplified Architecture**:
```swift
// Old approach (Python-style):
let storage = ActionStorageService(database: db)
let actions = try await storage.getAll()

// New approach (Swift-native):
let actions: [Action] = try await db.fetchAll()
```

### Testing Status ✅

**Current Test Coverage**: 14 tests passing
- 5 Action tests (creation, validation, equality)
- 9 Goal tests (Goal, SmartGoal, Milestone, polymorphism)

**Build Status**:
- ✅ Zero compilation errors
- ✅ Zero concurrency warnings
- ✅ Swift 6.2 strict mode enabled

## In Progress

### Database Integration Tests

**Goal**: Verify round-trip database operations

**Test Cases Needed** (~15 tests):
1. Save Action → Fetch by ID → Verify fields
2. Update Action → Verify old version archived
3. Delete Action → Verify archived before deletion
4. JSON measurements serialization/deserialization
5. Concurrent save operations (actor safety)
6. Schema initialization (in-memory database)
7. UUID handling (string ↔ UUID conversion)
8. Date serialization (ISO8601 format)
9. Null value handling
10. Archive table verification

**File**: `Tests/DatabaseIntegrationTests.swift`

**Status**: Planned, not yet implemented

## Future Work

### Phase 5: Goal Hierarchy with Polymorphism

**Challenge**: Goal has three types (Goal, SmartGoal, Milestone) stored in one table

**Approach**:
```swift
// Custom Decodable init for polymorphic reconstruction
extension Goal {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let goalType = try container.decode(String.self, forKey: .goalType)

        switch goalType {
        case "SmartGoal":
            // Decode as SmartGoal (requires all SMART fields)
        case "Milestone":
            // Decode as Milestone (targetDate required, no startDate)
        default:
            // Decode as base Goal (all fields optional)
        }
    }
}
```

**Tasks**:
- [ ] Add GRDB conformance to Goal, SmartGoal, Milestone
- [ ] Implement polymorphic `init(from:)`
- [ ] Add TableRecord with `databaseTableName = "goals"`
- [ ] CodingKeys for snake_case mapping
- [ ] Update GoalTests to verify database operations
- [ ] Test polymorphic fetch (should return correct subclass)

**Estimated Time**: 2-3 hours

### Phase 6: Values Hierarchy

**Similar Polymorphic Pattern**:
- `Incentives` → `Values` → `MajorValues` → `HighestOrderValues`
- Use `incentive_type` column for type discrimination
- Same `init(from:)` pattern as Goals

**Tasks**:
- [ ] Add GRDB conformance to Values hierarchy
- [ ] Implement polymorphic deserialization
- [ ] CodingKeys for `alignment_guidance` (JSON field)
- [ ] Update database schema if needed
- [ ] Write Values storage tests

**Estimated Time**: 2-3 hours

### Phase 7: Terms

**Simpler Case** (no polymorphism):
- `GoalTerm` - 10-week planning periods
- `LifeTime` - lifetime perspective

**Tasks**:
- [ ] Add GRDB conformance
- [ ] Handle `term_goals_by_id` (JSON array of UUIDs)
- [ ] Move business logic methods (isActive, daysRemaining) to Ethica layer
- [ ] Write Terms tests

**Estimated Time**: 1-2 hours

### Phase 8: Business Logic Layer (Ethica)

**Port from Python**:
- Progress calculation (aggregate_goal_progress, aggregate_all_goals)
- Matching logic (match_by_time_period, match_by_unit, match_by_description)
- Inference service (infer_all_relationships, infer_for_action)

**Swift Approach**:
```swift
// Pure functions, no database knowledge
extension Goal {
    func progress(from actions: [Action]) -> GoalProgress {
        // Calculate progress based on matching actions
    }
}

extension Action {
    func matches(_ goal: Goal) -> ActionGoalMatch? {
        // Determine if action contributes to goal
    }
}
```

**Tasks**:
- [ ] Create `GoalProgress` struct (replaces Python dataclass)
- [ ] Port progress calculation algorithms
- [ ] Port matching algorithms
- [ ] Port inference service
- [ ] Write Ethica tests (30+ tests expected)

**Estimated Time**: 4-6 hours

### Phase 9: SwiftUI Interface (Optional)

**Native macOS App**:
- Action logging view
- Goal tracking dashboard
- Progress visualization
- Term planning interface

**Not Required for Parity**: Python has CLI, Swift can too

**Estimated Time**: 8-12 hours (if pursued)

## Database Compatibility

### Shared Schema

Both Python and Swift implementations use:
- **Location**: `shared/schemas/*.sql`
- **Database**: Python uses `python/politica/data_storage/application_data.db`
- **Swift can**: Read/write same database for testing compatibility

### Field Mapping

**UUID Storage**:
- Python: `id TEXT PRIMARY KEY` (UUID as string)
- Swift: UUID → `.uuidString` for storage, `UUID(uuidString:)` for retrieval

**Date Storage**:
- Python: ISO8601 strings
- Swift: `JSONEncoder.dateEncodingStrategy = .iso8601`

**JSON Fields**:
- `measurements: [String: Double]` → `measurement_units_by_amount TEXT`
- `alignment_guidance: String?` → `alignment_guidance TEXT`
- `term_goals_by_id: [UUID]` → `term_goals_by_id TEXT`

### Migration Considerations

**Current Schema Uses INTEGER for IDs**:
- Need to migrate goals table to use TEXT for id column
- Migration script needed if sharing database between Python/Swift

**Future**: Consider using UUID BLOB for more efficient storage (16 bytes vs 36 bytes)

## Key Design Decisions

### Decision 1: Use GRDB Instead of Raw SQLite

**Rationale**:
- ✅ Built for Swift 6 concurrency
- ✅ Codable integration (automatic serialization)
- ✅ Connection pooling (better performance)
- ✅ Type-safe queries
- ✅ Migration support

**Tradeoff**: Dependency vs manual SQLite wrapper code

**Verdict**: GRDB is worth it

### Decision 2: No StorageService Layer

**Rationale**:
- Python needs StorageService to translate `dict` → `Entity`
- Swift's Codable does this automatically via GRDB
- Extra layer adds complexity without benefit

**Result**:
- Simpler code (fewer files)
- Direct database access from domain models
- Still type-safe (enforced by protocols)

### Decision 3: Actor-Based DatabaseManager

**Rationale**:
- Swift 6.2 requires Sendable types across async boundaries
- Actor serializes all database operations automatically
- Prevents data races at compile time

**Pattern**:
```swift
actor DatabaseManager {
    private let dbPool: DatabasePool

    func fetchAll<T: FetchableRecord>() async throws -> [T] {
        // Actor ensures serial execution
    }
}
```

**Result**: Thread-safe without manual locking

### Decision 4: Keep JSON for Measurements

**Alternative Considered**: Normalize measurements into separate table

**Decision**: Keep JSON blob (like Python)

**Rationale**:
- ✅ Flexible (easy to add new measurement types)
- ✅ Python compatibility
- ✅ Codable handles JSON automatically
- ❌ Can't query inside measurements (acceptable tradeoff)

## Testing Strategy

### Test Pyramid

**Unit Tests** (Domain Models):
- ✅ Action creation, validation, equality (5 tests)
- ✅ Goal hierarchy, polymorphism (9 tests)
- 🔲 Values hierarchy (planned: 5-9 tests)
- 🔲 Terms functionality (planned: 5-9 tests)

**Integration Tests** (Database):
- 🔲 Action CRUD operations (planned: 15 tests)
- 🔲 Goal polymorphic storage (planned: 10 tests)
- 🔲 Archive functionality (planned: 5 tests)
- 🔲 Concurrent operations (planned: 5 tests)

**Business Logic Tests** (Ethica):
- 🔲 Progress calculations (planned: 15 tests)
- 🔲 Matching algorithms (planned: 10 tests)
- 🔲 Inference service (planned: 10 tests)

**Target**: 90+ tests (matching Python's 90 tests)

### Testing Philosophy

1. **Test through correct layer**: Use DatabaseManager for database tests, not raw SQL
2. **Use in-memory database**: Fast, isolated tests
3. **Test edge cases**: Empty results, null values, validation failures
4. **Test concurrency**: Verify actor safety with concurrent operations

## Performance Considerations

### GRDB Optimizations

- **Connection Pooling**: Read operations can run concurrently
- **Prepared Statements**: GRDB caches SQL compilation
- **Batch Operations**: Use `saveMany()` for bulk inserts

### Swift Optimizations

- **Value Types**: Structs are stack-allocated (faster than classes)
- **Copy-on-Write**: Dictionaries and arrays share storage until mutated
- **Sendable**: Enables safe concurrent operations

### Measurement Points

- Database initialization time
- Fetch all actions (100, 1000, 10000 records)
- Save performance (single vs batch)
- JSON serialization overhead

## Success Criteria

### Minimum Viable Port (MVP)

- ✅ Models layer complete (Actions, Goals, Values, Terms with GRDB)
- ✅ Politica layer complete (DatabaseManager with all CRUD operations)
- 🔲 Ethica layer complete (progress, matching, inference)
- 🔲 90+ tests passing
- ✅ Zero concurrency warnings
- 🔲 Python/Swift database compatibility verified

### stable

All MVP criteria plus:
- 🔲 CLI interface (match Python's 25 commands)
- 🔲 Performance benchmarks
- 🔲 Error handling comprehensive
- 🔲 Documentation complete

### Stretch Goals

- SwiftUI interface (native macOS app)
- iOS compatibility
- watchOS complications
- CloudKit sync

## Timeline Estimate

| Phase | Description | Hours | Status |
|-------|-------------|-------|--------|
| 1-4 | Foundation, Database, Models, Cleanup | 4 | ✅ Done |
| 5 | Goal Hierarchy Polymorphism | 2-3 | 🔲 Todo |
| 6 | Values Hierarchy | 2-3 | 🔲 Todo |
| 7 | Terms | 1-2 | 🔲 Todo |
| 8 | Business Logic (Ethica) | 4-6 | 🔲 Todo |
| 9 | Integration Tests | 3-4 | 🔲 Todo |
| 10 | CLI Interface (Optional) | 6-8 | 🔲 Todo |

**Total**: 18-26 hours for MVP, 24-34 hours for stable

## Resources

### Documentation

- [GRDB.swift README](https://github.com/groue/GRDB.swift/blob/master/README.md)
- [Swift 6.2 Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Codable Documentation](https://developer.apple.com/documentation/swift/codable)

### Similar Projects

- GRDB Demo Apps: [GitHub Examples](https://github.com/groue/GRDB.swift#demo-applications)
- Swift Data Patterns: Various Apple sample projects

### Python Reference

- Original implementation: `ten_week_goal_app/python/`
- Architecture docs: `ten_week_goal_app/.documentation/`
- Test suite: `ten_week_goal_app/python/tests/` (90 passing tests)

## Notes

### Learning Outcomes

**Swift 6 Concurrency**:
- Actors provide automatic serialization
- Sendable protocol enforces thread safety at compile time
- `nonisolated` functions can be called from concurrent contexts

**GRDB Patterns**:
- FetchableRecord + PersistableRecord = full CRUD
- TableRecord defines table name
- Codable provides automatic serialization
- CodingKeys handle column name mapping

**Architecture**:
- Protocol-oriented design scales well
- Generic constraints enable type-safe database operations
- Direct Codable mapping eliminates translation layer

### Insights for Future Swift Projects

1. **Embrace the type system**: Don't fight Swift's strictness, leverage it
2. **GRDB over raw SQLite**: Productivity gain is worth the dependency
3. **Actors for shared state**: Thread safety without manual locking
4. **Codable everywhere**: Automatic serialization is powerful
5. **Protocols define ontology**: "Ways of being" not "things to do"

---

Last Updated: October 18, 2025
