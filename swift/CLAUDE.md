# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swift implementation of the Ten Week Goal App - a personal goal tracking system with protocol-oriented architecture. This port uses Swift's protocol system to define ontological "ways of being" for domain entities, while maintaining data compatibility with the Python version.

The Swift and Python implementations share the same SQLite database format, ensuring data compatibility between languages.

## Essential Commands

### Building and Running
```bash
# Build the project
swift build

# Run tests
swift test

# Run tests verbosely
swift test --verbose

# Run specific test
swift test --filter ActionTests

# Run the demo app
swift run TenWeekGoalDemo

# Clean build artifacts
swift package clean
```

### Development Workflow
```bash
# Generate Xcode project (optional, for IDE development)
swift package generate-xcodeproj

# Update dependencies
swift package update

# Show resolved package dependencies
swift package show-dependencies
```

## Project Structure

```
swift/
├── Sources/
│   ├── Models/              # Domain entities (protocol-oriented)
│   │   ├── Protocols.swift  # Core ontological protocols
│   │   └── Categoriae/      # Entity implementations
│   │       ├── Actions.swift
│   │       ├── Goals.swift
│   │       ├── Values.swift
│   │       └── Terms.swift
│   ├── Ethica/              # Business logic (planned)
│   ├── Rhetorica/           # Translation layer (planned)
│   ├── Politica/            # Infrastructure/SQLite (planned)
│   └── Demo/
│       └── DemoApp.swift    # SwiftUI demo application
├── Tests/
│   ├── ActionTests.swift    # Action entity tests (5 tests)
│   └── GoalTests.swift      # Goal hierarchy tests (9 tests)
└── Package.swift            # Swift Package Manager configuration
```

## Architecture: Protocol-Oriented Ontology

The Swift implementation uses protocols to define "ways of being" rather than "things to do."

### Core Ontology Protocols

**Persistable** - Things that exist in the database
```swift
protocol Persistable: Identifiable, Equatable {
    var id: UUID { get set }
    var friendlyName: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
    var logTime: Date { get set }  // Non-optional: all entities have creation time
}
```

**Achievable** - Future-oriented targets (goals)
```swift
protocol Achievable {
    var targetDate: Date? { get set }
    var measurementUnit: String? { get set }
    var measurementTarget: Double? { get set }
    var startDate: Date? { get set }
}
```

**Performed** - Past-oriented actions (what you did)
```swift
protocol Performed {
    var measurements: [String: Double]? { get set }
    var durationMinutes: Double? { get set }
    var startTime: Date? { get set }
}
```

**Motivating** - Values and priorities
```swift
protocol Motivating {
    var priority: Int { get set }
    var lifeDomain: String? { get set }
}
```

### Infrastructure Protocols

- **Validatable**: Structural self-validation (`isValid()`)
- **TypeIdentifiable**: Polymorphic storage support (goalType, incentiveType)
- **Serializable**, **JSONSerializable**: Translation layer support
- **Archivable**: Soft-delete capability

### Temporal Orientation

The protocols reflect temporal nature:
- **Achievable** = FUTURE (targets, goals, what you want)
- **Performed** = PAST (actions, what you did)
- **Motivating** = TIMELESS (values, priorities, meaning)
- **Persistable** = ONGOING (exists in the database)

### What Doesn't Belong in Protocols

❌ Calculations (progress, completion percentage) → Ethica layer
❌ Matching logic (action-goal relationships) → Ethica layer
❌ Business rules (is active? days remaining?) → Ethica layer
❌ Relationships between entities → Separate relationship entities

## Current Implementation Status

### ✅ Implemented (Phase 2 - Protocol Refactoring Complete)

**Models/Protocols.swift**: Ontological protocol system (2025-10-18)
- 9 essential protocols (down from 17 over-engineered ones)
- Clear separation: ontology (what things ARE) vs behavior (what you DO)
- Infrastructure support for polymorphism, validation, serialization

**Models/Categoriae/Actions.swift**: Action entity
- `struct Action: Persistable, Performed`
- Measurements support via `measurements: [String: Double]?`
- Timing fields: `durationMinutes`, `startTime`
- Validation logic: positive measurements, startTime requires duration
- UUID-based equality via Persistable

**Models/Categoriae/Goals.swift**: Goal hierarchy (class-based inheritance)
- `class Goal: Persistable, Achievable, TypeIdentifiable`
- `class SmartGoal: Goal` - strict SMART validation
- `class Milestone: Goal` - point-in-time targets (no start date)
- Polymorphic `goalType` field for database storage

**Models/Categoriae/Values.swift**: Values hierarchy
- `class Incentives: Persistable, Motivating, TypeIdentifiable`
- `class Values: Incentives` - general values
- `class MajorValues: Values` - actionable values with alignment guidance
- `class HighestOrderValues: Values` - philosophical ideals
- `class LifeAreas: Incentives` - life domains (distinct from values)
- `struct PriorityLevel` - validated 1-100 priority

**Models/Categoriae/Terms.swift**: Time horizons
- `class GoalTerm: Persistable` - 10-week planning periods
- `class LifeTime` - lifetime perspective ("4,000 weeks" thinking)
- Note: Contains business logic methods (isActive, daysRemaining) that should move to Ethica

**Tests**: 14 passing tests
- **ActionTests.swift**: 5 tests (creation, validation, equality)
- **GoalTests.swift**: 9 tests (Goal, SmartGoal, Milestone, polymorphism)

**Demo/DemoApp.swift**: SwiftUI demonstration app
- macOS-native (simplified from cross-platform)
- Action creation and listing
- Shows domain model in action

### 🚧 Next Steps (Planned)
1. Write Values tests (planned)
2. Write Terms tests (planned)
3. Move business logic from Terms to Ethica layer
4. Implement SQLite infrastructure (Politica layer)
5. Port business logic (Ethica: progress calculations, matching algorithms)
6. Build translation layer (Rhetorica: storage services)
7. Create production SwiftUI interface

## Swift-Specific Patterns

### Entity Definition Pattern

**Struct with Protocols (Actions)**:
```swift
struct Action: Persistable, Performed {
    // Persistable properties
    var id: UUID = UUID()
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date = Date()

    // Performed properties
    var measurements: [String: Double]?
    var durationMinutes: Double?
    var startTime: Date?

    // Validation
    func isValid() -> Bool {
        // Measurements must be positive
        if let measurements = measurements {
            for (_, value) in measurements {
                if value <= 0 { return false }
            }
        }

        // startTime requires duration
        if startTime != nil && durationMinutes == nil {
            return false
        }

        return true
    }
}
```

**Class with Inheritance (Goals)**:
```swift
class Goal: Persistable, Achievable, TypeIdentifiable {
    // Persistable
    var id: UUID
    var friendlyName: String?
    var detailedDescription: String?
    var freeformNotes: String?
    var logTime: Date

    // Achievable
    var targetDate: Date?
    var measurementUnit: String?
    var measurementTarget: Double?
    var startDate: Date?

    // TypeIdentifiable
    var goalType: String { return "Goal" }

    // Goal-specific
    var howGoalIsRelevant: String?
    var howGoalIsActionable: String?
    var expectedTermLength: Int?

    func isValid() -> Bool {
        // Validate measurement and date constraints
    }
}

class SmartGoal: Goal {
    override var goalType: String { return "SmartGoal" }

    // Requires all SMART fields in init
    init(
        measurementUnit: String,  // Required!
        measurementTarget: Double,
        startDate: Date,
        targetDate: Date,
        howGoalIsRelevant: String,
        howGoalIsActionable: String
        // ...
    ) {
        super.init(/* ... */)
        validateSmartCriteria()  // Post-init validation
    }
}
```

### Testing Pattern (XCTest)
```swift
import XCTest
@testable import Models

final class ActionTests: XCTestCase {
    func testMinimalActionCreation() {
        let action = Action(friendlyName: "Morning run")

        XCTAssertEqual(action.friendlyName, "Morning run")
        XCTAssertNotNil(action.id) // UUID auto-generated
        XCTAssertNotNil(action.logTime) // Non-optional Date
    }

    func testEqualityBasedOnUUID() {
        let sharedID = UUID()
        let action1 = Action(id: sharedID, friendlyName: "Run")
        let action2 = Action(id: sharedID, friendlyName: "Sprint")

        // Same UUID = equal (via Persistable), even with different names
        XCTAssertEqual(action1, action2)
    }
}
```

## Database Compatibility

The Swift implementation will read/write to the same SQLite database as the Python version:

**Database Location (shared):**
- `../shared/schemas/*.sql` - SQL schema definitions
- When implemented, Swift will use: `../python/politica/data_storage/application_data.db`

**Field Naming Conventions:**
- Swift uses camelCase: `friendlyName`, `logTime`, `measurements`
- Database uses snake_case: `friendly_name`, `log_time`, `measurement_units_by_amount`
- Rhetorica layer will handle conversion

**ID System:**
- Swift uses UUID (Swift best practice, offline-first)
- Database schema updated to TEXT PRIMARY KEY for UUIDs
- UUID provides global uniqueness, SwiftUI Identifiable compatibility

## Code Style Conventions

### File Headers
All new Swift files should include:
```swift
// FileName.swift
// Brief description of purpose
//
// Written by Claude Code on YYYY-MM-DD
// Refactored by Claude Code on YYYY-MM-DD
// Ported from Python implementation (path/to/python/file.py)
```

### Documentation
- Use Swift's doc comments (`///`) for public APIs
- Mark sections with `// MARK: -` for clarity
- Include parameter descriptions and return values
- Document protocol conformances and their purpose

### Naming
- Classes/Structs: PascalCase (Action, Goal, SmartGoal)
- Properties: camelCase (friendlyName, measurementTarget)
- Functions: camelCase (isValid, isTimeBound)
- Protocols: Adjectives (Persistable, Achievable, Performed, Motivating)
- Constants: camelCase or SCREAMING_SNAKE_CASE for globals

## Testing Philosophy

Follow Test-Driven Development (TDD):
1. Write test first (it should fail)
2. Write minimal code to pass test
3. Refactor while tests pass
4. Repeat

**Test Structure:**
- One test file per source file (or hierarchy)
- Consolidated tests: 5-9 focused tests per entity
- Use descriptive test names: `testMinimalActionCreation()`
- Test edge cases, validation logic, polymorphism
- Mirror Python test patterns for consistency

**Current Status**: 14/14 tests passing (5 Action + 9 Goal)

## Platform Support

**Minimum Versions (defined in Package.swift):**
- macOS 14.0+ (simplified to macOS-native for rapid development)

**Future Cross-Platform:**
- Core domain models are platform-agnostic
- Database layer will work on all Apple platforms
- Can add iOS support when needed

## Dependencies

Current dependencies (managed via Swift Package Manager):
- None yet (pure Swift for domain layer)

**Planned Dependencies:**
- SQLite.swift: For database operations (Politica layer)
- Potentially: swift-argument-parser (for CLI)

## References

### Python Implementation
See `../python/` for the authoritative Python implementation with:
- 90 passing tests
- Complete CLI (25 commands)
- Flask API (27 endpoints)
- Full layer implementation

### Project Documentation
- Project-level CLAUDE.md: `../CLAUDE.md`
- Architecture decisions: `../.documentation/architecture_decisions.md`
- Database schemas: `../shared/schemas/`

## Development Notes

### Recent Changes (2025-10-18)

**Protocol Refactoring Complete**:
- Simplified from 17 protocols to 9 essential ones
- Clear ontological focus: "ways of being" not "things to do"
- Removed behavioral protocols (Progressable, Matchable, etc.)
- Added temporal clarity (Achievable=future, Performed=past, Motivating=timeless)
- Made `logTime` non-optional for type safety
- Renamed module from "Categoriae" to "Models"
- Updated test imports to `@testable import Models`

**Key Insight**: Protocols should encode what data IS, not what you DO with it. Business logic (calculations, matching, progress) belongs in Ethica layer, not in domain protocols.

### Current Focus
The Swift port has completed Phase 2 (Protocol Ontology). Currently demonstrating:
- Protocol-oriented domain design
- Clear separation of concerns (ontology vs behavior)
- Class inheritance for Goal hierarchy (learning exercise)
- Struct + protocol composition for Actions
- Comprehensive validation patterns
- Test-driven development approach

### Next Priorities
1. Write Values tests (5-9 tests covering hierarchy)
2. Write Terms tests (5-9 tests covering GoalTerm and LifeTime)
3. Refactor Terms business logic to Ethica layer
4. Implement Politica layer with SQLite.swift
5. Port Ethica business logic (progress calculations)
6. Build Rhetorica translation layer

### Key Principles
- Protocol-oriented ontology: define "ways of being"
- Separate ontology (what things ARE) from behavior (what you DO)
- Leverage Swift's type system for compile-time safety
- Use modern Swift features (protocols, value types, optionals)
- Keep database format compatible between Swift/Python implementations
- Maintain architectural parity with Python version
