# Ten Week Goal App - Swift Implementation

A production-ready Swift port of the Ten Week Goal App using Swift 6.2 strict concurrency and GRDB for type-safe database operations.

## Quick Start

```bash
# Build the project
swift build

# Run tests (14 passing)
swift test

# Run specific test suite
swift test --filter ActionTests
```

## Architecture

### Modern Swift Design

This implementation leverages Swift's strengths rather than directly porting Python patterns:

- **GRDB Codable Integration**: Direct database ↔ domain model mapping
- **Protocol-Oriented Design**: Ontological protocols define "ways of being"
- **Swift 6.2 Actors**: Thread-safe database access without manual locking
- **Compile-Time Safety**: Type checking prevents runtime errors

### Simplified Architecture

**Python Version**:
```
Database → dict[str, Any] → StorageService → Domain Entity
           ↑ Runtime types
```

**Swift Version**:
```
Database → GRDB Row → Domain Entity (via Codable)
           ↑ Compile-time types, Sendable
```

**Result**: Swift version is simpler (no translation layer) and safer (compile-time guarantees).

## Architectural Layers

Following the Aristotelian naming convention:

### Models/ - Domain Entities
Protocol-oriented design with temporal clarity:
- **Persistable** = Things that exist in the database (ONGOING)
- **Achievable** = Future-oriented targets (FUTURE)
- **Performed** = Past-oriented actions (PAST)
- **Motivating** = Values and priorities (TIMELESS)

**Entities**:
- `Action` - Performed actions with measurements
- `Goal`, `SmartGoal`, `Milestone` - Achievable targets
- `Values`, `MajorValues`, `HighestOrderValues` - Motivating principles
- `GoalTerm`, `LifeTime` - Time horizons

### Politica/ - Infrastructure
Database operations with no knowledge of business logic:
- `DatabaseManager` - Actor-based CRUD operations
- `DatabaseConfiguration` - Path and schema management
- `DatabaseError` - Typed, Sendable error handling

**Pattern**:
```swift
let db = try await DatabaseManager()
let actions: [Action] = try await db.fetchAll()
var action = Action(friendlyName: "Run")
try await db.save(&action)
```

### Ethica/ - Business Logic (Planned)
Pure functions for calculations and matching:
- Progress calculations
- Action-goal matching algorithms
- Inference services

### Rhetorica/ - Translation Layer (Not Needed!)
**Key Insight**: GRDB's Codable integration eliminates the need for a separate translation layer. Domain models communicate directly with the database through protocol conformance.

## Database Integration

### GRDB.swift

Using GRDB 7.8.0 for:
- ✅ Swift 6.2 concurrency support
- ✅ Automatic Codable serialization
- ✅ Connection pooling
- ✅ Type-safe queries
- ✅ Migration support

### Shared Database Format

The Swift implementation reads/writes the same SQLite database as Python:
- **Location**: `../python/politica/data_storage/application_data.db`
- **Schemas**: `../shared/schemas/*.sql`
- **Format**: UUID as TEXT, dates as ISO8601, JSON for nested data

### Example: Action Storage

```swift
import Models
import Politica

// Create database manager
let db = try await DatabaseManager()

// Save an action with measurements
var action = Action(
    friendlyName: "Morning run",
    measurements: ["km": 5.0, "minutes": 30.0]
)
try await db.save(&action)
print(action.id) // UUID assigned

// Fetch all actions
let actions: [Action] = try await db.fetchAll()

// Fetch by ID
if let found = try await db.fetchOne(Action.self, id: action.id) {
    print(found.measurements?["km"] ?? 0)
}

// Update (automatically archives old version)
action.measurements?["km"] = 6.0
try await db.save(&action)

// Delete (automatically archives before deletion)
try await db.delete(Action.self, id: action.id)
```

## Implementation Status

### ✅ Phase 1-4: Foundation Complete (Oct 18, 2025)

**Domain Models**:
- ✅ 9 public protocols (Persistable, Achievable, Performed, etc.)
- ✅ Action with GRDB conformance and validation
- ✅ Goal hierarchy (Goal, SmartGoal, Milestone)
- ✅ Values hierarchy (Values, MajorValues, HighestOrderValues)
- ✅ Terms (GoalTerm, LifeTime)

**Database Layer**:
- ✅ DatabaseManager actor with generic CRUD operations
- ✅ Automatic archiving (preserves old versions)
- ✅ Schema initialization from shared `.sql` files
- ✅ Swift 6.2 strict concurrency compliance
- ✅ Zero concurrency warnings

**Testing**:
- ✅ 14/14 tests passing (5 Action + 9 Goal)
- ✅ Zero build errors
- ✅ In-memory database support for fast tests

**Code Quality**:
- ✅ 380-line DatabaseManager (vs Python's 527 lines)
- ✅ No translation layer needed
- ✅ Direct Codable integration

### 🚧 Phase 5-8: Next Steps

1. **Database Integration Tests** - Action CRUD round-trip tests
2. **Goal Polymorphic Storage** - Store/retrieve Goal subclasses correctly
3. **Values & Terms Storage** - Complete GRDB integration
4. **Business Logic** - Port Ethica layer (progress, matching, inference)

**Timeline**: 18-26 hours for MVP (see `SWIFTROADMAP.md`)

## Testing

### Current Coverage
```bash
swift test
# Test Suite 'ActionTests' passed at 2025-10-18
#   Executed 5 tests, with 0 failures in 0.001 seconds
# Test Suite 'GoalTests' passed at 2025-10-18
#   Executed 9 tests, with 0 failures in 0.001 seconds
```

### Test Philosophy
- **Unit Tests**: Domain model validation and logic
- **Integration Tests**: Database round-trip operations
- **Business Logic Tests**: Ethica calculations and matching

**Target**: 90+ tests (matching Python's test coverage)

## Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0")
]
```

## Platform Support

- **macOS 14.0+** (current focus)
- **iOS/watchOS** support ready (all core types are platform-agnostic)
- **Swift 6.2+** required

## Documentation

- **`SWIFTROADMAP.md`** - Complete project roadmap and architecture decisions
- **`CLAUDE.md`** - Development guide for Claude Code
- **`../CLAUDE.md`** - Project-level documentation
- **`../shared/schemas/`** - Database schemas

## Key Achievements

### Simpler Than Python
- No StorageService translation layer
- Generic `fetchAll<T>()` replaces type-specific methods
- Codable handles serialization automatically

### Safer Than Python
- Compile-time type checking (no runtime dict errors)
- Swift 6.2 concurrency prevents data races
- Sendable protocol ensures thread safety

### More Concurrent
- Actor-based database access
- Read operations can run in parallel
- Write operations automatically serialized

## Compatibility Notes

### Python Interoperability
Both implementations can share the same database:
- UUID format: String representation
- Dates: ISO8601 format
- JSON fields: Automatic Codable serialization
- Snake_case ↔ camelCase: Handled by CodingKeys

### Migration Considerations
- Current schema uses INTEGER for goal IDs (needs migration to TEXT for UUIDs)
- Action schema already uses TEXT for IDs
- Both implementations can coexist during migration

## Contributing

See `SWIFTROADMAP.md` for:
- Design decisions and rationale
- Future work breakdown
- Testing strategy
- Performance considerations

## References

- **Python Implementation**: `../python/` (90 tests, CLI, Flask API)
- **GRDB Documentation**: https://github.com/groue/GRDB.swift
- **Swift Concurrency**: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html

---

**Status**: Foundation complete, database layer operational, ready for business logic port.

Last Updated: October 18, 2025
