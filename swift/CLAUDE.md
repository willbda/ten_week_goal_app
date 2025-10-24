# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swift implementation of the Ten Week Goal App using Swift 6.2 strict concurrency and GRDB for type-safe database operations. This port leverages Swift's protocol system and modern concurrency features while maintaining data compatibility with the Python version.

**Key Architectural Decision**: Uses GRDB's Codable integration for direct database-to-domain-model mapping, eliminating the need for a translation layer (Rhetorica).

The Swift and Python implementations share the same SQLite database format, ensuring data compatibility between languages.

## Essential Commands

### Building and Running
```bash
# Build the project
swift build

# Build without warnings
swift build -Xswiftc -suppress-warnings

# Run tests
swift test

# Run tests verbosely
swift test --verbose

# Run specific test
swift test --filter ActionTests

# Clean build artifacts
swift package clean

# Run LLM Playground (requires macOS 26+)
swift run LLMPlayground
```

### Development Workflow
```bash
# Update dependencies
swift package update

# Show resolved package dependencies
swift package show-dependencies

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## Project Structure

```
swift/
├── Sources/
│   ├── App/                  # SwiftUI views and UI layer
│   │   ├── DesignSystem.swift      # ✅ Central design tokens
│   │   ├── ContentView.swift       # ✅ Root navigation (macOS)
│   │   ├── iOS/                    # ✅ iOS-specific UI (planning phase)
│   │   │   ├── ContentView_iOS.swift       # TabView navigation
│   │   │   ├── GoalProgressActivity.swift  # Live Activities
│   │   │   ├── LiquidGlassDesignSystem.swift # iOS design tokens
│   │   │   └── LiquidGlassFormView.swift   # Adaptive forms
│   │   ├── Views/                  # Feature views
│   │   │   ├── Actions/            # Actions list/forms
│   │   │   ├── Goals/              # Goals list/forms
│   │   │   ├── Values/             # Values list/forms
│   │   │   └── Terms/              # Terms list/forms
│   │   └── GoalDocument.swift      # Document-based architecture
│   ├── LLMPlayground/       # ✅ Interactive prompt testing CLI
│   │   ├── Playground.swift        # Main CLI (macOS 26+)
│   │   ├── PlaygroundHelpers.swift # Prompt engineering utilities
│   │   ├── PromptLibrary.swift     # Example prompt collection
│   │   └── README.md               # Usage guide
│   ├── Models/              # Domain entities (protocol-oriented)
│   │   ├── Protocols.swift  # Core ontological protocols (public)
│   │   └── Kinds/           # Entity implementations
│   │       ├── Actions.swift      # ✅ GRDB integrated
│   │       ├── Goals.swift        # ✅ GRDB integrated
│   │       ├── Values.swift       # Needs GRDB integration
│   │       └── Terms.swift        # Needs GRDB integration
│   ├── Database/            # Infrastructure (Database operations)
│   │   ├── DatabaseManager.swift      # ✅ Actor with generic CRUD
│   │   ├── DatabaseConfiguration.swift # ✅ Path management
│   │   └── DatabaseError.swift        # ✅ Typed errors
│   └── BusinessLogic/       # Business logic (planned)
├── iOS-docs/                # ✅ iOS implementation planning docs
│   ├── iOS_IMPLEMENTATION_PLAN.md  # Complete iOS migration strategy
│   ├── LIQUID_GLASS_DESIGN.md      # iOS design philosophy
│   └── LIQUID_GLASS_IMPLEMENTATION.md # Technical implementation guide
├── Tests/
│   ├── ActionTests.swift    # 5 tests passing
│   └── GoalTests.swift      # 9 tests passing
├── Package.swift            # SPM configuration
├── SWIFTROADMAP.md          # Complete project roadmap
├── DESIGN_SYSTEM.md         # ✅ UI design system guide
└── CLAUDE.md                # This file
```

## Architecture: GRDB-Native Design

### Core Principle

**Embrace GRDB's type system** instead of Python's dictionary-based approach:

**Python**:
```python
Database → dict[str, Any] → StorageService → Domain Entity
           ↑ Runtime types, not Sendable
```

**Swift**:
```swift
Database → GRDB Row → Domain Entity (via Codable)
           ↑ Compile-time types, Sendable
```

### No Rhetorica Layer Needed

**Key Insight**: GRDB's `FetchableRecord` + `PersistableRecord` + `Codable` provides automatic serialization. Domain models communicate directly with the database.

```swift
// Old approach (would need translation layer):
let storage = ActionStorageService(database: db)
let actions = try await storage.getAll()

// New approach (direct GRDB):
let actions: [Action] = try await db.fetchAll()
```

## Core Ontology Protocols

All protocols are now **public** for cross-module access.

### Temporal Protocols

**Persistable** - Things that exist in the database (ONGOING)
```swift
public protocol Persistable: Identifiable, Equatable {
    var id: UUID { get set }
    var friendlyName: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
    var logTime: Date { get set }  // Non-optional: all entities have creation time
}
```

**Achievable** - Future-oriented targets (FUTURE)
```swift
public protocol Achievable {
    var targetDate: Date? { get set }
    var measurementUnit: String? { get set }
    var measurementTarget: Double? { get set }
    var startDate: Date? { get set }
}
```

**Performed** - Past-oriented actions (PAST)
```swift
public protocol Performed {
    var measurements: [String: Double]? { get set }
    var durationMinutes: Double? { get set }
    var startTime: Date? { get set }
}
```

**Motivating** - Values and priorities (TIMELESS)
```swift
public protocol Motivating {
    var priority: Int { get set }
    var lifeDomain: String? { get set }
}
```

### Infrastructure Protocols

- **Validatable**: Structural self-validation (`isValid()`)
- **TypeIdentifiable**: Polymorphic storage support (goalType, incentiveType)
- **Serializable**, **JSONSerializable**: API support
- **Archivable**: Soft-delete capability

### What Doesn't Belong in Protocols

❌ Calculations (progress, completion percentage) → Ethica layer
❌ Matching logic (action-goal relationships) → Ethica layer
❌ Business rules (is active? days remaining?) → Ethica layer
❌ Relationships between entities → Separate relationship entities

## Current Implementation Status

### ✅ Phase 1-4: Foundation Complete (Oct 18, 2025)

**Models Layer**:
- ✅ 9 public protocols (Persistable, Achievable, Performed, Motivating, etc.)
- ✅ Action with GRDB conformance (FetchableRecord, PersistableRecord, TableRecord)
- ✅ Goal hierarchy (Goal, SmartGoal, Milestone) - domain models ready
- ✅ Values hierarchy (Values, MajorValues, HighestOrderValues) - domain models ready
- ✅ Terms (GoalTerm, LifeTime) - domain models ready

**Politica Layer (Database)**:
- ✅ DatabaseManager actor with generic CRUD operations
- ✅ DatabaseConfiguration with Sendable conformance
- ✅ DatabaseError with typed, Sendable errors
- ✅ Schema initialization from `shared/schemas/` directory
- ✅ Automatic archiving (preserves old versions before updates/deletes)
- ✅ Swift 6.2 strict concurrency compliance
- ✅ 380 lines vs Python's 527 lines (simpler!)

**GRDB Integration**:
- ✅ GRDB.swift 7.8.0 dependency added
- ✅ Action conforms to FetchableRecord, PersistableRecord, TableRecord
- ✅ CodingKeys for snake_case ↔ camelCase mapping
- ✅ JSON serialization for `measurements` dictionary
- ✅ TableRecord.databaseTableName = "actions"

**Testing**:
- ✅ 14/14 tests passing (5 Action + 9 Goal)
- ✅ Zero build errors
- ✅ Zero Swift 6 concurrency warnings
- ✅ In-memory database support for fast testing

**Cleanup**:
- ✅ Deleted StorageService.swift (GRDB provides this)
- ✅ Deleted ActionStorageService.swift (direct database access)
- ✅ Deleted DatabaseValue.swift (GRDB handles Sendable types)

### 🚧 Phase 5-8: Next Steps

**Immediate**:
1. Write database integration tests for Action CRUD
2. Add GRDB conformance to Goal hierarchy (polymorphic storage)
3. Add GRDB conformance to Values hierarchy
4. Add GRDB conformance to Terms

**Business Logic**:
5. Port Ethica layer (progress calculations, matching algorithms)
6. Write Ethica tests (30+ tests)

**Target**: 90+ tests matching Python implementation

## GRDB Patterns

### Entity with GRDB Conformance

```swift
import Foundation
import GRDB

struct Action: Persistable, Performed, Codable, Sendable,
               FetchableRecord, PersistableRecord, TableRecord {
    var id: UUID
    var friendlyName: String?
    var measurements: [String: Double]?
    var durationMinutes: Double?
    var startTime: Date?
    var logTime: Date

    // TableRecord
    static let databaseTableName = "actions"

    // Codable keys for snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case friendlyName = "friendly_name"
        case measurements = "measurement_units_by_amount"
        case durationMinutes = "duration_minutes"
        case startTime = "start_time"
        case logTime = "log_time"
    }

    func isValid() -> Bool {
        // Validation logic
    }
}
```

### DatabaseManager Usage

```swift
import Politica
import Models

// Initialize (in-memory for tests, file-based for production)
let db = try await DatabaseManager(configuration: .inMemory)

// Fetch all
let actions: [Action] = try await db.fetchAll()

// Fetch by ID
if let action = try await db.fetchOne(Action.self, id: someUUID) {
    print(action.friendlyName ?? "")
}

// Save (generates UUID if new)
var action = Action(friendlyName: "Run")
try await db.save(&action)
print(action.id) // Now has UUID

// Update (automatically archives old version)
action.measurements = ["km": 10.0]
try await db.save(&action) // Detects existing ID, updates

// Delete (automatically archives before deletion)
try await db.delete(Action.self, id: action.id)
```

### Custom SQL Queries

```swift
// Fetch with custom SQL
let runs: [Action] = try await db.fetch(
    Action.self,
    sql: "SELECT * FROM actions WHERE friendly_name LIKE ?",
    arguments: ["%run%"]
)
```

### Polymorphic Storage (Goals)

```swift
// Custom Decodable init for polymorphism
extension Goal {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let goalType = try container.decode(String.self, forKey: .goalType)

        switch goalType {
        case "SmartGoal":
            // Decode as SmartGoal (all SMART fields required)
            self = try SmartGoal(from: decoder)
        case "Milestone":
            // Decode as Milestone (targetDate required, no startDate)
            self = try Milestone(from: decoder)
        default:
            // Decode as base Goal (all fields optional)
            // ... base Goal decoding
        }
    }
}
```

## Database Compatibility

### Shared Database Format

**Location**: `../python/politica/data_storage/application_data.db`
**Schemas**: `../shared/schemas/*.sql`

### Field Mappings

**Naming Convention**:
- Swift: camelCase (`friendlyName`, `logTime`, `measurements`)
- Database: snake_case (`friendly_name`, `log_time`, `measurement_units_by_amount`)
- Mapping: CodingKeys enum

**Data Types**:
- UUID: TEXT in database (`.uuidString` for storage)
- Date: TEXT in database (ISO8601 via `JSONEncoder.dateEncodingStrategy`)
- JSON: TEXT in database (automatic Codable serialization)

**Example**:
```swift
enum CodingKeys: String, CodingKey {
    case id
    case friendlyName = "friendly_name"
    case logTime = "log_time"
    case measurements = "measurement_units_by_amount" // JSON field
}
```

### JSON Fields

GRDB automatically serializes/deserializes JSON fields with Codable:

```swift
// In Swift
var measurements: [String: Double]? = ["km": 5.0, "minutes": 30]

// In database
measurement_units_by_amount TEXT: '{"km":5.0,"minutes":30}'

// Automatic bidirectional conversion!
```

## Testing Patterns

### Unit Tests (Domain Models)

```swift
import XCTest
@testable import Models

final class ActionTests: XCTestCase {
    func testMinimalActionCreation() {
        let action = Action(friendlyName: "Morning run")

        XCTAssertEqual(action.friendlyName, "Morning run")
        XCTAssertNotNil(action.id) // UUID auto-generated
        XCTAssertNotNil(action.logTime) // Defaults to Date()
    }

    func testMeasurementValidation() {
        var action = Action(friendlyName: "Run")
        action.measurements = ["km": -5.0]
        XCTAssertFalse(action.isValid()) // Negative values invalid
    }
}
```

### Integration Tests (Database)

```swift
import XCTest
@testable import Models
@testable import Politica

final class DatabaseIntegrationTests: XCTestCase {
    var database: DatabaseManager!

    override func setUp() async throws {
        // In-memory database for fast, isolated tests
        database = try await DatabaseManager(configuration: .inMemory)
    }

    func testActionRoundTrip() async throws {
        // Create and save
        var action = Action(friendlyName: "Test run")
        action.measurements = ["km": 5.0]
        try await database.save(&action)

        let savedID = action.id

        // Fetch back
        let retrieved = try await database.fetchOne(Action.self, id: savedID)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.friendlyName, "Test run")
        XCTAssertEqual(retrieved?.measurements?["km"], 5.0)
    }

    func testUpdateArchivesPreviousVersion() async throws {
        // Save initial version
        var action = Action(friendlyName: "Original")
        try await database.save(&action)

        // Update
        action.friendlyName = "Updated"
        try await database.save(&action)

        // TODO: Verify old version in archive table
    }
}
```

**Current Status**: 14/14 tests passing (unit tests only, integration tests planned)

## Code Style Conventions

### File Headers
```swift
// FileName.swift
// Brief description of purpose
//
// Written by Claude Code on YYYY-MM-DD
// Refactored by Claude Code on YYYY-MM-DD for GRDB integration
// Ported from Python implementation (path/to/python/file.py)
```

### Documentation
- Use Swift's doc comments (`///`) for public APIs
- Mark sections with `// MARK: -` for clarity
- Include parameter descriptions and return values
- Document protocol conformances

### Naming
- Classes/Structs: PascalCase (Action, Goal, SmartGoal)
- Properties: camelCase (friendlyName, measurementTarget)
- Functions: camelCase (isValid, fetchAll)
- Protocols: Adjectives (Persistable, Achievable, Performed, Motivating)

### Swift 6.2 Concurrency Patterns (CRITICAL)

**All `@Observable` UI state MUST use `@MainActor` for thread safety.**

**Correct Pattern** (UI-related singletons):
```swift
@MainActor
@Observable
class ZoomManager {
    var zoomLevel: CGFloat = 1.0
    func zoomIn() { /* mutations on main thread */ }
}
```

**Access from synchronous contexts**:
```swift
// In computed properties that can't be async (e.g., design tokens):
private static var zoom: CGFloat {
    MainActor.assumeIsolated {
        ZoomManager.shared.zoomLevel  // Safe: SwiftUI runs on main thread
    }
}
```

**What NOT To Do**:
```swift
// ❌ NEVER use @unchecked Sendable - disables ALL safety checks
@Observable
class BadManager: @unchecked Sendable {
    var state: Int  // Data race! No protection!
}

// ❌ NEVER put @MainActor on methods only
@Observable
class PartiallyWrong {
    @MainActor func update() { }  // Class should be @MainActor
}
```

**When To Use Each**:
- `@MainActor` on class: UI state, ViewModels, singletons (ZoomManager, AppViewModel)
- `actor`: Background work, database operations (InferenceService, ImageCache)
- `MainActor.assumeIsolated`: Synchronous access to main-actor state (design tokens)
- `@unchecked Sendable`: **Almost never** - only for custom synchronization primitives

**Audit Command** (find unsafe patterns):
```bash
grep -r "@unchecked Sendable" Sources/  # Should return ZERO results
grep -r "@Observable" Sources/ | grep -v "@MainActor"  # Check coverage
```

See `DESIGN_SYSTEM.md` "Swift 6.2 Concurrency Patterns" section for full explanation.

### Design System (CRITICAL)

**All UI code MUST use the centralized design system (`DesignSystem.swift`).**

See `DESIGN_SYSTEM.md` for complete guide. Quick reference:

**Never hard-code spacing or colors:**
```swift
// ❌ DON'T
.padding(16)
.background(Color.red)

// ✅ DO
.padding(DesignSystem.Spacing.md)
.background(DesignSystem.Colors.error)
```

**Common tokens:**
```swift
// Spacing
DesignSystem.Spacing.xxs          // 4pt - Badges
DesignSystem.Spacing.xs           // 8pt - Row spacing
DesignSystem.Spacing.md           // 16pt - Section padding
DesignSystem.Spacing.formPadding  // 20pt - Forms (macOS)

// Colors
DesignSystem.Colors.actions       // Red
DesignSystem.Colors.goals         // Orange
DesignSystem.Colors.values        // Blue
DesignSystem.Colors.terms         // Purple
DesignSystem.Colors.error         // Error states
DesignSystem.Colors.success       // Success states

// Materials
DesignSystem.Materials.sidebar    // .ultraThinMaterial
DesignSystem.Materials.modal      // .regularMaterial
```

**Form views pattern:**
```swift
NavigationStack {
    Form { }
        .formStyle(.grouped)
        #if os(macOS)
        .padding(DesignSystem.Spacing.formPadding)
        .frame(minWidth: 500, minHeight: 400)
        #endif
        .toolbar { }
}
.presentationBackground(DesignSystem.Materials.modal)
```

**Row views pattern:**
```swift
VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
    Text("Title").font(.headline)
    Text("Subtitle").foregroundStyle(.secondary)
}
.padding(.vertical, DesignSystem.Spacing.xxs)
```

## Platform Support

**Current**:
- macOS 14.0+ (development focus)
- Swift 6.2+ required

**Future**:
- iOS 13.0+ (all types platform-agnostic)
- watchOS 7.0+
- tvOS 13.0+

## Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0")
]
```

**Why GRDB over raw SQLite**:
- ✅ Built for Swift 6 concurrency
- ✅ Codable integration (automatic serialization)
- ✅ Connection pooling (better performance)
- ✅ Type-safe queries
- ✅ Migration support

## References

### Python Implementation
See `../python/` for the authoritative Python implementation with:
- 90 passing tests
- Complete CLI (25 commands)
- Flask API (27 endpoints)
- Full layer implementation

### Documentation
- **SWIFTROADMAP.md**: Complete architecture and roadmap
- **../CLAUDE.md**: Project-level documentation
- **../shared/schemas/**: Database schemas

### External Resources
- [GRDB Documentation](https://github.com/groue/GRDB.swift)
- [Swift 6.2 Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Codable](https://developer.apple.com/documentation/swift/codable)

## Development Notes

### Recent Changes (2025-10-23)

**Design System & UI Architecture Complete**:
- ✅ Centralized design system (`DesignSystem.swift`) with semantic tokens
- ✅ Spacing tokens (xxs→xxl) replace all hard-coded padding values
- ✅ Semantic color system (actions/goals/values/terms + error/success/info)
- ✅ Material constants for consistent Liquid Glass usage
- ✅ ViewModifiers for reusable styling patterns
- ✅ All row views updated (GoalRowView, ActionRowView, ValueRowView, TermRowView)
- ✅ All form views updated with proper padding (ActionFormView, GoalFormView)
- ✅ Document-based architecture (GoalDocument.swift) for file-based workflows
- ✅ Infinite sidebar smoothness with continuous icon scaling
- ✅ Comprehensive design documentation (DESIGN_SYSTEM.md)

**Key UI Patterns**:
> SwiftUI uses ViewModifiers (not inheritance) for reusable styling. The design system provides semantic tokens that make the entire app's spacing/colors changeable from one file. This follows Apple HIG principles: semantic over literal, consistent over custom, maintainable over perfect.

**Code Metrics**:
- DesignSystem.swift: 200+ lines of reusable design infrastructure
- 6 view files updated with design tokens
- Net change: ~400 lines (design system + documentation)

**Files Created**:
- `DesignSystem.swift` - Central design tokens and modifiers
- `GoalDocument.swift` - Document-based architecture
- `DESIGN_SYSTEM.md` - Complete usage guide
- `LIQUID_GLASS_NOTES.md` - Material design patterns

### Previous Changes (2025-10-18)

**GRDB Architecture Refactoring Complete**:
- ✅ Eliminated StorageService translation layer (GRDB provides this)
- ✅ DatabaseManager uses generic `fetchAll<T>()`, `save<T>()` methods
- ✅ Action conforms to FetchableRecord, PersistableRecord, TableRecord
- ✅ All protocols made public for cross-module access
- ✅ CodingKeys for snake_case ↔ camelCase mapping
- ✅ Zero Swift 6 concurrency warnings
- ✅ 14/14 tests passing

**Key Architectural Insight**:
> GRDB's Codable integration eliminates the need for a translation layer. Domain models communicate directly with the database through protocol conformance. This makes the Swift version simpler than the Python version while being safer (compile-time types) and more concurrent (actor-based).

**Code Metrics**:
- DatabaseManager: 380 lines vs Python's 527 lines
- Net change: +782 lines (mostly documentation)
- Files deleted: 3 (StorageService, ActionStorageService, DatabaseValue)

### Current Focus

**Foundation Complete**:
- Protocol-oriented domain design ✅
- GRDB database integration ✅
- Swift 6.2 strict concurrency ✅
- Automatic archiving ✅

**Next Phase**:
1. Database integration tests
2. Polymorphic Goal storage
3. Values and Terms GRDB integration
4. Business logic layer (Ethica)

### Key Principles

- **Protocol-oriented ontology**: Define "ways of being" not "things to do"
- **Embrace GRDB**: Use native types instead of fighting the framework
- **Actor isolation**: Thread safety without manual locking
- **Codable everywhere**: Automatic serialization is powerful
- **Database compatibility**: Swift/Python can share the same database
- **Type safety**: Compile-time checking prevents runtime errors

### Timeline Estimate

See `SWIFTROADMAP.md` for detailed breakdown:
- **MVP**: 18-26 hours total (4 hours complete, 14-22 remaining)
- **stable**: 24-34 hours

## LLM Playground (Oct 24, 2025)

**Interactive CLI for Foundation Models prompt engineering and experimentation.**

### Overview

The LLM Playground provides a command-line interface for testing Foundation Models integration before building UI. It enables rapid prompt iteration with immediate feedback.

### Running the Playground

```bash
# Build and run (requires macOS 26+ with Foundation Models)
swift run LLMPlayground

# Interactive menu with options:
# 1. Send custom prompt
# 2. Use example prompts (20 curated examples)
# 3. View conversation history
# 4. Test tool calling (GetGoals, GetActions, GetTerms, GetValues)
# 5. Clear session
# 6. Benchmark prompts
```

### Features

- **Custom Prompts**: Test arbitrary prompts with tool calling
- **Example Library**: 20 pre-built prompts across 5 categories:
  - Reflective: Patterns and themes
  - Analytical: Metrics and breakdowns
  - Exploratory: Relationship discovery
  - Specific: Direct data queries
  - Creative: Narratives and unconventional approaches
- **Conversation History**: Session-based tracking with database persistence
- **Tool Testing**: Verify individual tool responses
- **Benchmarking**: Measure response times across multiple prompts

### Architecture Integration

The playground uses the same `ConversationService` that powers the Assistant chat in the main app, ensuring:
- **Consistent behavior**: Same tools, same prompts, same responses
- **Rapid prototyping**: Test prompt variations in seconds, not minutes
- **Database integration**: Uses GRDB with `conversation_history` table

### Use Cases

1. **Prompt Engineering**: Refine Assistant prompts before UI integration
2. **Tool Validation**: Verify GetGoals/GetActions/GetTerms/GetValues work correctly
3. **Response Analysis**: Compare different prompt phrasings
4. **Performance Benchmarking**: Measure response times for optimization

See `Sources/LLMPlayground/README.md` for complete documentation.

## iOS Implementation (Planning Phase)

**iOS adaptation of the macOS app is ready for development. See `iOS-docs/` for complete planning materials.**

### Status

- ✅ Architecture analyzed (~80% platform-agnostic)
- ✅ Design system created (Liquid Glass aesthetics)
- ✅ Implementation plan completed (phased approach)
- ✅ Example code written (ContentView_iOS, GoalProgressActivity, etc.)
- 🚧 Implementation pending (requires UI layer work only)

### Key Documents

- **iOS_IMPLEMENTATION_PLAN.md**: Complete migration strategy with phase-based approach
- **LIQUID_GLASS_DESIGN.md**: iOS design philosophy and principles
- **LIQUID_GLASS_IMPLEMENTATION.md**: Technical implementation guide

### What's Already Platform-Agnostic

All of these work on iOS without changes:
- ✅ All domain models (Action, Goal, Value, Term, Relationships)
- ✅ All business logic services (MatchingService, InferenceService)
- ✅ Database layer (DatabaseManager, GRDB, SQLite schemas)
- ✅ Core ViewModels (ActionsViewModel, GoalsViewModel, etc.)
- ✅ Design system tokens (with zoom scaling abstraction)

### What Needs iOS Adaptation

Platform-specific UI changes required:
- ⚠️ Navigation pattern (NavigationSplitView → TabView or NavigationStack)
- ⚠️ Form layouts and spacing (remove fixed widths, adapt for smaller screens)
- ⚠️ Keyboard handling (on-screen keyboard, toolbar, dismissal)
- ⚠️ Platform features (ZoomManager, keyboard shortcuts, AI availability checks)
- ⚠️ Document handling (GoalDocument → iOS Files app integration)

---

Last Updated: October 24, 2025
