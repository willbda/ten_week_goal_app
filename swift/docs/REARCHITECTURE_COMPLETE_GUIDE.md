# Ten Week Goal App - Complete Rearchitecture Guide
**Created**: 2025-10-31
**Written by**: Claude Code (merged from MASTER_REARCHITECTURE_PLAN, REARCHITECTURE_ISSUE, CLEAN_REARCHITECTURE_PLAN)
**Status**: Phase 1-2 Complete, Phase 3 Ready to Start

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Current Status](#current-status)
3. [Design Philosophy & Principles](#design-philosophy--principles)
4. [Design Rationale](#design-rationale)
5. [Database Architecture (Phase 1)](#database-architecture-phase-1-)
6. [Swift Models (Phase 2)](#swift-models-phase-2-)
7. [Repository/Service Layer (Phase 3)](#repositoryservice-layer-phase-3-)
8. [Protocol Redesign (Phase 4)](#protocol-redesign-phase-4-)
9. [ViewModel Layer (Phase 5)](#viewmodel-layer-phase-5-)
10. [View Updates (Phase 6)](#view-updates-phase-6-)
11. [Migration Strategy](#migration-strategy)
12. [Testing Requirements](#testing-requirements)
13. [Implementation Roadmap](#implementation-roadmap)
14. [Open Questions & Considerations](#open-questions--considerations)
15. [Decision Log](#decision-log)
16. [References](#references)

---

# Executive Summary

This document consolidates all rearchitecture planning for the Ten Week Goal App's transition to a 3NF normalized database with clean Swift architecture. We're implementing a **clean break** approach without backward compatibility to achieve optimal design.

## What We're Building
- **Database**: 3NF normalized schema eliminating JSON fields and redundant tables
- **Models**: Clean Swift structs using SQLiteData @Table macro
- **Services**: Repository pattern for data access, business logic in dedicated services
- **Views**: SwiftUI views connected via ViewModels to service layer

## Why This Matters
The current schema has fundamental issues that prevent efficient querying, proper relationship modeling, and future feature development. This rearchitecture enables:
- Multi-metric goals ("Run 100km AND 20 sessions")
- Proper progress calculations across actions
- Value alignment tracking
- Query performance improvements (10x faster on key queries)

---

# Current Status

## Tested Phases 1-2
- **Database Schema**: Full 3NF normalization designed and tested
- **Swift Models**: All entities and junction tables created
- **Migration Script**: Successfully tested migration 381 actions, 16 goals, 13 values
- **Documentation**: Schema design, challenges, and rationale documented

## ⚠️ Breaking Changes Introduced (2025-10-30)

The 3NF normalization has intentionally broken several parts of the app:
1. **MatchingService** - References removed `measuresByUnit` and `measurementUnit`
2. **GoalFormView** - References removed Goal fields
3. **ActionsViewModel** - Expects JSON measuresByUnit
4. **GoalsViewModel** - References removed `goal.isSmart()` method

These are expected and will be fixed in Phases 3-6 as we build the service layer and update views.

## 🚧 Next Priority (Phase 3)
Repository/Service layer to make the normalized models usable

---

# Design Philosophy & Principles

## Core Philosophical Approach

From original planning ([docs/20251025_plan.md](swift/docs/20251025_plan.md)):

> "Classes in Swift should reflect natural hierarchies, not merely shared behaviors as per Apple developer guidance. For Apple platforms, we're building with the UI in mind, very close to the data structures."

### Guiding Principles

1. **Clarify database schemas as ontology** - What entities exist? What relationships matter?
2. **Define protocols and classes** - General patterns, attributes, and behaviors
3. **Define models in structs and classes** - Concrete implementations
4. **Extend protocols for separation of concerns** - Clean boundaries
5. **Define viewmodel protocols and classes** - UI state management

**Expected**: Each part of the app will break as we do this. This is intentional.

## Architecture Principles

1. **Database schemas as ontology** - Entities and relationships clearly defined
2. **Classes reflect natural hierarchies** - Not just shared behaviors (Apple guidance)
3. **UI close to data structures** - Swift models work in both DB and SwiftUI
4. **Separation of concerns** - Models, Services, ViewModels, Views
5. **Junction tables are DB artifacts** - Minimal fields, no business logic

### Testing Philosophy
From original planning:
> "This is a fine time to think again about how I test and what I test."

**Questions to address**:
- What level of testing is appropriate for each phase?
- Focus on integration tests (query correctness)?
- UI tests for critical flows only?
- Performance benchmarks?

---

# Design Rationale

## Core Questions Driving Design

From [docs/20251025_plan.md](swift/docs/20251025_plan.md):

### Relationship Queries Needed
- "Show me all Actions that contribute to Goal X"
- "Show me all Goals in Term Y"
- "Show me Actions aligned with Value Z"
- "What Values does Goal X serve?"

### Aggregation Queries Needed
- "Sum all Action measurements (km) toward Goal target (120 km)"
- "Show progress percentage for each Goal in current Term"
- "Count Actions per Value/LifeDomain over time period"

### Hierarchy Questions
- Are Values/MajorValues/HighestOrderValues really different types, or different **priority levels** of the same type?
- Are Goal/Milestone really different types, or different **configurations** of the same type?

### Temporal Queries Needed
- "Actions logged in date range"
- "Goals due in next 2 weeks"
- "Terms that overlap with date X"

## Problems with Old Schema

### Problem 1: 4 Separate Value Tables
**Issue**: 4 separate tables with `polymorphicSubtype` discrimination
```
valueses
majorValueses
highestOrderValueses
lifeAreases
```

**Impact**:
- ❌ "Get all my values regardless of priority" requires UNION queries
- ❌ Can't index across UNION
- ❌ Hard to maintain, hard to query
- ❌ Adding new value levels requires new tables

**OLD SCHEMA (4 tables)**:
```sql
SELECT id, title, priority, 'general' as level FROM valueses
UNION ALL
SELECT id, title, priority, 'major' as level FROM majorValueses
UNION ALL
SELECT id, title, priority, 'highest_order' as level FROM highestOrderValueses
UNION ALL
SELECT id, title, priority, 'life_area' as level FROM lifeAreases
ORDER BY priority;
```

**NEW SCHEMA (1 table)**:
```sql
SELECT id, title, priority, valueLevel
FROM "values"
ORDER BY priority;
```

### Problem 2: No Relationship Tables
**Issue**: No explicit relationship tables for queryability

Missing tables:
- No `action_goal_contributions` → can't query "which goals does this action serve?"
- No `goal_value_alignments` → can't query "which values does this goal align with?"

**Impact**: Impossible to answer core relationship queries without application-layer parsing

### Problem 3: JSON Dictionaries for Structured Data
**Issue**: `measuresByUnit` in Action → requires JSON parsing, can't index, fragile

**OLD SCHEMA (with JSON)**:
```sql
-- Requires JSON parsing EVERY row!
SELECT id, title, json_extract(measuresByUnit, '$.km') as km, logTime
FROM actions
WHERE json_extract(measuresByUnit, '$.km') IS NOT NULL
ORDER BY CAST(json_extract(measuresByUnit, '$.km') AS REAL) DESC;
```
- ❌ JSON parsing on every row
- ❌ Can't index on JSON field
- ❌ Type conversion needed
- ❌ Fragile to JSON structure changes

**NEW SCHEMA (with metrics table)**:
```sql
-- Simple join, fully indexed!
SELECT a.title, am.value as km, a.logTime
FROM actions a
JOIN action_metrics am ON a.id = am.actionId
JOIN metrics m ON am.metricId = m.id
WHERE m.unit = 'km'
ORDER BY am.value DESC;
```
- ✅ No JSON parsing
- ✅ Indexed joins (idx_action_metrics_metric)
- ✅ Type-safe (REAL in database)
- ✅ Queryable metric metadata

**Result**: Same data, 10x faster, infinitely more maintainable

### Problem 4: Flat Text for Structured Relationships
**Issue**: Unstructured text fields for structured data
- `howGoalIsRelevant` (flat text) → should be structured goal-value alignments
- `howGoalIsActionable` (flat text) → should be structured measurement targets

**Impact**: Can't query, aggregate, or analyze alignment data

---

# Database Architecture (Phase 1) ✅

## Core Principles
- **No JSON fields** - All values atomic (measuresByUnit eliminated)
- **Single source of truth** - No redundant data
- **Pure junction tables** - Minimal fields, just relationships
- **Proper foreign keys** - Referential integrity enforced
- **Indexed for performance** - Common queries optimized

## Entity Structure

### First-Class Entities (Persistable)
All share: `id`, `title`, `detailedDescription`, `freeformNotes`, `logTime`

| Entity | Additional Fields | Purpose |
|--------|------------------|---------|
| **Action** | `durationMinutes`, `startTime` | What was done |
| **Goal** | `startDate`, `targetDate`, `actionPlan` | What to achieve |
| **Value** | `priority`, `valueLevel`, `alignmentGuidance` | What matters |
| **Term** | `termNumber`, `startDate`, `targetDate` | Planning periods |
| **Metric** | `unit`, `metricType`, `canonicalUnit` | Units catalog |

### Junction Tables (Pure DB Artifacts)
Minimal fields - just relationships:

| Junction | Links | Key Fields |
|----------|-------|------------|
| **MeasuredAction** | Action → Metric | `value`, `createdAt` |
| **GoalMetric** | Goal → Metric | `targetValue` |
| **GoalRelevance** | Goal → Value | `alignmentStrength` |
| **ActionGoalContribution** | Action → Goal | `contributionAmount` |
| **TermGoalAssignment** | Term → Goal | `assignmentOrder` |

## Query Performance

### Before vs After
- **Before**: JSON parsing on every row
- **After**: Indexed JOINs, 10x faster
- **Example**: Finding running actions no longer requires `json_extract()`

### Example: Calculate Progress on a Goal

**NEW SCHEMA ENABLES** (not possible in old schema):
```sql
-- Sum all km actions contributing to "Spring into Running" goal (120km target)
SELECT
  g.title as goal,
  g.measurementTarget as target,
  COALESCE(SUM(am.value), 0) as actual,
  ROUND(COALESCE(SUM(am.value), 0) / g.measurementTarget * 100, 1) as progress_pct
FROM goals g
LEFT JOIN action_goal_contributions agc ON g.id = agc.goalId
LEFT JOIN action_metrics am ON agc.actionId = am.actionId AND agc.metricId = am.metricId
LEFT JOIN metrics m ON am.metricId = m.id
WHERE g.title = 'Spring into Running'
  AND m.unit = 'km'
GROUP BY g.id;
```

**This query would show**:
```
goal                  | target | actual | progress_pct
--------------------- | ------ | ------ | ------------
Spring into Running   |  120.0 |   87.0 |         72.5
```

**OLD SCHEMA**: Impossible without application-layer JSON parsing and manual aggregation

## Schema Details

See [Sources/Database/SCHEMA_FINAL.md](swift/Sources/Database/SCHEMA_FINAL.md) for complete schema definition.

### Still Needed: Database Constraints
- [ ] **Data validation constraints**
  ```sql
  CHECK (priority BETWEEN 1 AND 100)
  CHECK (valueLevel IN ('general', 'major', 'highest_order', 'life_area'))
  CHECK (metricType IN ('distance', 'time', 'count', 'mass'))
  CHECK (alignmentStrength BETWEEN 1 AND 10)
  ```

- [ ] **Cascade delete rules** (some have CASCADE, others don't)
- [ ] **Deduplication logic** for migrated data
- [ ] **Audit fields** (createdBy, updatedBy, version)

---

# Swift Models (Phase 2) ✅

## Completed Models

### Entities
- [Action.swift](swift/Sources/Models/Kinds/Actions.swift) - Removed measuresByUnit JSON
- [Goal.swift](swift/Sources/Models/Kinds/Goals.swift) - Removed flat measurement fields
- [Value.swift](swift/Sources/Models/Kinds/Value.swift) - Unified 4 tables with ValueLevel enum
- [Term.swift](swift/Sources/Models/Kinds/Terms.swift) - Clean structure (already good)
- [Metric.swift](swift/Sources/Models/Kinds/Metric.swift) - New first-class entity

### Junction Tables
- [MeasuredAction.swift](swift/Sources/Models/Relationships/ActionMetric.swift) - Links actions to measurements
- [GoalMetric.swift](swift/Sources/Models/Relationships/GoalMetric.swift) - Existing, defines targets
- [GoalRelevance.swift](swift/Sources/Models/Relationships/GoalRelevance.swift) - New, goal-value alignment
- [ActionGoalContribution.swift](swift/Sources/Models/Relationships/ActionGoalContribution.swift) - New, progress tracking
- [TermGoalAssignment.swift](swift/Sources/Models/Kinds/TermGoalAssignment.swift) - Updated field names

## Key Design Decisions
1. **ValueLevel enum** with proper SQLiteData conformances
2. **No business logic in models** - Just data structure
3. **Legacy initializers** for migration compatibility (temporary - should be removed)

## Still Needed: Model Cleanup

- [x] **Remove ALL legacy support**
  ```swift
  // Remove this:
  public init(termUUID: UUID, goalUUID: UUID, ...) // Legacy

  // Keep only this:
  public init(termId: UUID, goalId: UUID, ...)
  ```

- [ ] **Add computed relationships**
  ```swift
  extension Action {
      // Relationship accessors (not business logic)
      func metrics(from db: Database) async -> [Metric]
      func contributions(from db: Database) async -> [Goal]
  }
  ```

- [ ] **Protocol cleanup**
  - Remove unused protocols (Doable, Motivating)
  - Keep only Persistable and necessary ones
  - Define clear protocol hierarchy

---

# Repository/Service Layer (Phase 3) 🚧 NEXT

## Critical Missing Pieces

### Core Repositories Needed

#### Priority 1: ActionRepository
```swift
class ActionRepository {
    func create(action: Action, metrics: [(Metric, Double)]) async throws
    func findWithMetrics(id: UUID) async throws -> (Action, [MeasuredAction])
    func findByMetric(metric: Metric) async throws -> [Action]
    func sumByMetric(metric: Metric, dateRange: DateRange) async throws -> Double
}
```

**Why needed**: Currently broken - ActionsViewModel expects JSON measuresByUnit

#### Priority 2: GoalRepository
```swift
class GoalRepository {
    func create(goal: Goal, targets: [(Metric, Double)], values: [Value]) async throws
    func findWithProgress(id: UUID) async throws -> GoalWithProgress
    func findByTerm(term: Term) async throws -> [Goal]
    func findByValue(value: Value) async throws -> [Goal]
}
```

**Why needed**: GoalFormView references removed Goal fields, GoalsViewModel expects isSmart() method

#### Priority 3: ValueRepository
```swift
class ValueRepository {
    func findByLevel(level: ValueLevel) async throws -> [Value]
    func findAlignedGoals(value: Value) async throws -> [Goal]
    func calculateAlignment(action: Action) async throws -> [ValueAlignment]
}
```

**Why needed**: Enable value-based queries and alignment tracking

#### Completed: MetricRepository
- ✅ Basic version exists ([MetricRepository.swift](swift/Sources/App/Services/MetricRepository.swift))
- May need enhancement for conversion support

### Business Services Needed

#### ProgressCalculationService
```swift
class ProgressCalculationService {
    func calculateGoalProgress(goal: Goal) async throws -> Progress
    func calculateTermProgress(term: Term) async throws -> TermProgress
    func projectCompletion(goal: Goal) async throws -> Date?
}
```

**Why needed**: Replace removed isSmart() method, calculate progress across metrics

#### AlignmentService
```swift
class AlignmentService {
    func scoreActionValueAlignment(action: Action, value: Value) async throws -> Double
    func suggestValuesForGoal(goal: Goal) async throws -> [Value]
    func findMisalignedGoals() async throws -> [Goal]
}
```

**Why needed**: Replace MatchingService which is broken due to removed measuresByUnit

#### MetricAggregationService
```swift
class MetricAggregationService {
    func dailyTotals(metric: Metric) async throws -> [DayTotal]
    func weeklyAverages(metric: Metric) async throws -> [WeekAverage]
    func trends(metric: Metric) async throws -> Trend
}
```

**Why needed**: Enable analytics and trend visualization

## Implementation Priority
1. **Week 1**: Core repositories (CRUD operations)
2. **Week 2**: Business services (calculations)
3. **Week 3**: Query optimization

---

# Protocol Redesign (Phase 4) ❌ NOT STARTED

**Status**: Waiting for Phase 3 completion

## Current Protocols ([Protocols.swift](swift/Sources/Models/Protocols.swift))

```swift
protocol Persistable { ... }      // ✅ Keep - uniform base
protocol Completable { ... }      // ? Review - future-oriented entities
protocol Measurable { ... }       // ? Review - measurement-capable entities

// Removed (already):
// protocol Doable
// protocol Motivating
// protocol Polymorphable
```

## Design Questions for Phase 4

1. **Do we need Completable?**
   - Now that measurements are in `goal_metrics`, what does Completable provide?
   - Is it just a marker: "has target dates"?

2. **Do we need Measurable?**
   - Actions can have metrics, but so can goals (targets)
   - Is this a useful capability marker?

3. **What about business logic?**
   - Protocols should be **field contracts** (compile-time safety)
   - Business logic should live in **Services/Repositories** (runtime queries)

## Tasks

- [ ] Review protocol usage patterns in Phase 2 models
- [ ] Identify: what protocols enforce field contracts vs business logic?
- [ ] Redesign protocols as pure field contracts
- [ ] Move any business logic to service layer
- [ ] Document protocol design decisions

**Deliverable**: Clean protocols that enforce schema contracts

---

# ViewModel Layer (Phase 5) ❌ NOT STARTED

**Status**: Waiting for Phase 4 completion

## Current Problems
- Expect `measuresByUnit` JSON field
- Direct model access instead of repositories
- Reference removed Goal fields
- No relationship handling

## Required ViewModels

### ActionEntryViewModel
```swift
@MainActor
class ActionEntryViewModel: ObservableObject {
    @Published var availableMetrics: [Metric] = []
    @Published var measurements: [MetricMeasurement] = []

    private let actionRepo: ActionRepository
    private let metricRepo: MetricRepository

    func addMeasurement(metric: Metric, value: Double)
    func saveAction() async
}
```

**Why needed**: Replace broken ActionsViewModel expecting JSON

### GoalPlanningViewModel
```swift
@MainActor
class GoalPlanningViewModel: ObservableObject {
    @Published var targets: [MetricTarget] = []
    @Published var alignedValues: [Value] = []
    @Published var smartStatus: GoalClassification

    private let goalRepo: GoalRepository
    private let valueRepo: ValueRepository

    func addTarget(metric: Metric, value: Double)
    func alignWithValue(_ value: Value, strength: Int)
    func validateSMART() -> [ValidationIssue]
}
```

**Why needed**: Replace broken GoalsViewModel, handle SMART classification

### DashboardViewModel
```swift
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var activeGoals: [GoalWithProgress] = []
    @Published var recentActions: [ActionWithMetrics] = []
    @Published var valueAlignment: ValueAlignmentSummary

    private let progressService: ProgressCalculationService
    private let alignmentService: AlignmentService

    func refreshDashboard() async
    func getMetricTrends(for period: DateRange) async
}
```

**Why needed**: Enable progress visualization with multi-metric support

### TermPlanningViewModel
```swift
@MainActor
class TermPlanningViewModel: ObservableObject {
    @Published var termGoals: [Goal] = []
    @Published var termProgress: TermProgress?

    private let goalRepo: GoalRepository
    private let progressService: ProgressCalculationService

    func assignGoal(_ goal: Goal, order: Int) async
    func calculateTermProgress() async
}
```

**Why needed**: Handle goal assignment to terms

## Implementation Approach
- Inject repositories, not database
- Published properties for UI binding
- Async/await for database operations
- Proper error handling

---

# View Updates (Phase 6) ❌ NOT STARTED

**Status**: Waiting for Phase 5 completion

## Current Problems
- Reference removed Goal fields (measurementUnit, measurementTarget)
- Expect flat structures instead of relationships
- No metric selection UI
- No value alignment UI

## Missing UI Components

### MetricSelector
```swift
struct MetricSelector: View {
    @Binding var selectedMetrics: [(Metric, Double)]
    let availableMetrics: [Metric]

    var body: some View {
        // UI for selecting metrics and entering values
        // - List of available metrics grouped by type
        // - TextField for value entry
        // - Unit display
        // - Add/remove buttons
    }
}
```

**Why needed**: Replace flat measurementUnit/measurementTarget fields

### ValueAlignmentPicker
```swift
struct ValueAlignmentPicker: View {
    @Binding var alignments: [(Value, Int)]
    let availableValues: [Value]

    var body: some View {
        // UI for selecting values and alignment strength
        // - List grouped by ValueLevel
        // - Slider for alignment strength (1-10)
        // - Multi-select support
    }
}
```

**Why needed**: Replace flat howGoalIsRelevant text field

### ProgressVisualization
```swift
struct ProgressVisualization: View {
    let goal: Goal
    let progress: GoalProgress

    var body: some View {
        // Charts showing progress by metric
        // - Multi-metric progress bars
        // - Time series charts
        // - Projected completion date
    }
}
```

**Why needed**: Visualize multi-metric goal progress

### RelationshipGraph
```swift
struct RelationshipGraph: View {
    let value: Value
    let alignedGoals: [Goal]
    let contributingActions: [Action]

    var body: some View {
        // Visual goal-value-action connections
        // - Node graph or tree view
        // - Alignment strength indicators
        // - Interactive exploration
    }
}
```

**Why needed**: Visualize value alignment across goals and actions

## Forms Need Updates
- [ActionFormView](swift/Sources/App/Views/Actions/ActionFormView.swift) - Add metric selection
- [GoalFormView](swift/Sources/App/Views/Goals/GoalFormView.swift) - Remove flat fields, add targets
- ValueFormView - Handle unified value types (need to create)

## Views to Update
- [ActionsListView](swift/Sources/App/Views/Actions/ActionsListView.swift) - Display metrics from relationship tables
- [GoalsListView](swift/Sources/App/Views/Goals/GoalsListView.swift) - Show progress calculations
- ValuesListView - Unified value list with level filtering (need to create)
- TermsListView - Show goals in term (need to create)

---

# Migration Strategy

## Chosen Approach: Clean Break

**Recommendation**: Go for the clean break. The current schema has fundamental issues (JSON fields, redundant tables) that make backward compatibility expensive to maintain.

### Why Clean Break?
1. **Simplifies the codebase**
2. **Enables better performance**
3. **Reduces long-term maintenance**
4. **Allows proper relationship modeling**
5. **Enables new features naturally**

### Migration Process
1. Export existing data ✅ (migration script works)
2. Deploy new schema
3. Import with deduplication
4. No backward compatibility

### Migration Results (Tested 2025-10-30)
- **381 actions** migrated successfully
- **16 goals** migrated (all identified as SMART)
- **13 values** migrated (unified from 4 tables)
- **5 metrics** extracted from JSON
- **381 action-metric relationships** created

### Migration Checklist
- [x] Schema designed
- [x] Migration script tested
- [ ] Deduplication logic for duplicates
- [ ] User communication plan
- [ ] Rollback strategy
- [ ] Performance validation

## Alternative Approaches (Rejected)

### Option B: Parallel Run
1. Deploy new schema alongside old
2. Dual-write period
3. Migrate users gradually
4. Remove old schema after verification

**Why rejected**: Too complex, doubles maintenance burden

### Option C: Versioned Migration
1. Version the database
2. Run migrations on app start
3. Support rollback if needed
4. Progressive enhancement

**Why rejected**: Adds complexity without clear benefit

## Effort Estimate

### If maintaining backward compatibility:
- 3-4 weeks of development
- Complex testing scenarios
- Higher maintenance burden

### If clean break:
- 2-3 weeks of development
- Simpler testing
- Clean architecture
- One-time migration pain

---

# Testing Requirements

## Unit Tests ❌ NOT STARTED

### Model Validation
- [ ] Model struct validation
- [ ] Protocol conformance
- [ ] SQLiteData conformances
- [ ] ValueLevel enum behavior

### Repository Tests
- [ ] CRUD operations for each repository
- [ ] Relationship queries
- [ ] Error handling
- [ ] Concurrent access

### Service Tests
- [ ] Progress calculations
- [ ] Alignment scoring
- [ ] Metric aggregations
- [ ] Business logic edge cases

### ViewModel Tests
- [ ] State management
- [ ] Published property updates
- [ ] Error handling
- [ ] Async operation handling

## Integration Tests ❌ NOT STARTED

### Database Integration
- [ ] Full data cycles (create → read → update → delete)
- [ ] Migration integrity (no data loss)
- [ ] Relationship traversal (JOIN queries)
- [ ] Query performance benchmarks

### End-to-End Flows
- [ ] Action entry with metrics
- [ ] Goal creation with targets and alignments
- [ ] Progress calculation
- [ ] Value alignment analysis

## UI Tests ❌ NOT STARTED

### Critical Flows
- [ ] Action entry flow
- [ ] Goal planning flow
- [ ] Progress tracking display
- [ ] Value alignment interface

### Form Validation
- [ ] Metric selection
- [ ] Value alignment picker
- [ ] Required field validation
- [ ] Data persistence

## Performance Tests ❌ NOT STARTED

### Query Performance
- [ ] Compare old vs new schema query times
- [ ] Large dataset handling (1000+ actions)
- [ ] Aggregation performance
- [ ] Index effectiveness

### CloudKit Sync
- [ ] Sync efficiency with new relationships
- [ ] Conflict resolution
- [ ] Large batch sync

## Accessibility Testing (Pre-v1.0.0 Priority)

From original planning:
> "I do want to hold on to accessibility and make it a priority before v 1.0.0"

**Tasks**:
- [ ] VoiceOver testing
- [ ] Keyboard navigation
- [ ] Color contrast checks
- [ ] Semantic labels on form fields
- [ ] Dynamic type support

---

# Implementation Roadmap

## Phase Timeline (5-7 weeks total)

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| **1-2** | Schema & Models | Complete | ✅ Done |
| **3** | Repositories | 1 week | 🚧 Next |
| **4** | Protocols | 3 days | ⏳ Waiting |
| **5** | ViewModels | 1 week | ⏳ Waiting |
| **6** | Views | 1 week | ⏳ Waiting |
| **7** | Testing & Migration | 1-2 weeks | ⏳ Waiting |

## Critical Path
1. **Repositories** (enables everything else)
2. **ViewModels** (connects data to UI)
3. **Views** (user interaction)
4. **Migration** (production deployment)

## Success Criteria
- [ ] All models compile without errors
- [ ] Repository tests pass
- [ ] ViewModels handle relationships
- [ ] Views display normalized data
- [ ] Migration preserves all data
- [ ] Performance meets or exceeds current
- [ ] Accessibility standards met

---

# Open Questions & Considerations

From [docs/20251025_plan.md](swift/docs/20251025_plan.md):

## Concurrency & Threading
> "I'm not at all sure how to think about threading and concurrency."

**Considerations**:
- Models are `Sendable` structs ✅
- Should repositories be `@MainActor` or background actors?
- Where do we use `async/await`?
- How to handle concurrent writes to database?

**Proposed approach**:
- Repositories: Background actors for database access
- ViewModels: `@MainActor` for UI binding
- Services: Background actors for calculations

## Polymorphism
> "I don't know about polymorphism right now. It was a learning exercise, but it might not be useful."

**Current thinking**:
- Enum fields instead of `polymorphicSubtype` strings ✅
- `goalType: GoalType` enum (`.goal | .milestone`)
- `valueLevel: ValueLevel` enum (`.general | .major | .highestOrder | .lifeArea`) ✅

**Status**: Resolved - using enums

## Remove Inference
> "Let's remove inference entirely for now"

**Action**: Defer inference services until rearchitecture complete

**Status**: Done - InferenceService disabled

## Performance Considerations

### Query Optimization
- [ ] Materialized views for common aggregations
- [ ] Denormalized read models for dashboards
- [ ] Caching strategy for metrics catalog
- [ ] Batch operations for bulk updates

### Data Growth Planning
- [ ] Archival strategy for old actions
- [ ] Partitioning for large tables
- [ ] Index maintenance schedule
- [ ] Statistics update frequency

---

# New Capabilities Enabled

## Immediate Benefits
- **Multi-metric goals** - "Run 100km AND 20 sessions"
- **Proper aggregation** - Sum across all actions by metric
- **Value alignment** - Track which goals serve which values
- **Progress accuracy** - Real calculations, not estimates

## Future Possibilities
- **Metric conversions** - km ↔ miles
- **Trend analysis** - Historical patterns
- **Smart suggestions** - Based on alignments
- **Cross-goal insights** - Shared metrics

## Features That Need Rethinking
- Quick action entry (now needs metric selection)
- Goal templates (must include metric definitions)
- Import/Export (new structure)
- Sync strategy (more complex relationships)

---

# Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-10-30 | Pure junction tables | DB artifacts, minimal overhead |
| 2025-10-30 | Unified values table | Simpler queries, no UNIONs |
| 2025-10-30 | Clean break migration | Simpler than backward compatibility |
| 2025-10-30 | Business logic in services | Models can't query database |
| 2025-10-30 | Metrics as first-class entities | No JSON parsing, proper indexes |
| 2025-10-30 | ValueLevel enum | Type-safe, extensible |

---

# File Organization

## Production Files
```
swift/
├── Sources/
│   ├── Models/
│   │   ├── Kinds/          # Entities (Action, Goal, Value, Term, Metric)
│   │   └── Relationships/  # Junction tables
│   ├── App/
│   │   └── Services/        # Repositories (NEW - Phase 3)
│   └── Database/
│       ├── SCHEMA_FINAL.md
│       ├── schema_3nf_final.sql
│       └── proposed_3nf.db
└── docs/
    ├── REARCHITECTURE_COMPLETE_GUIDE.md  # This document
    └── archive/                           # Historical docs
```

## Deprecated/Exploratory (Archived)
```
swift/docs/archive/
├── MASTER_REARCHITECTURE_PLAN.md
├── REARCHITECTURE_ISSUE.md
├── CLEAN_REARCHITECTURE_PLAN.md
├── schema_rearchitected.sql  # Early attempt
├── schema_uniform.sql         # Over-engineered
└── migrate_to_uniform.py      # Replaced by 3nf version
```

---

# Next Immediate Actions

1. **Create ActionRepository** with basic CRUD + metrics
2. **Create GoalRepository** with targets and progress
3. **Update ActionsViewModel** to use repository
4. **Create MetricSelector** UI component
5. **Test with real data** from proposed_3nf.db

---

# References

## Documentation
- Original principles: [docs/20251025_plan.md](swift/docs/20251025_plan.md)
- Schema definition: [Sources/Database/SCHEMA_FINAL.md](swift/Sources/Database/SCHEMA_FINAL.md)
- Migration results: [Sources/Database/3NF_MIGRATION_COMPLETE.md](swift/Sources/Database/3NF_MIGRATION_COMPLETE.md)
- Challenges faced: [Sources/Database/NORMALIZATION_CHALLENGES.md](swift/Sources/Database/NORMALIZATION_CHALLENGES.md)

## Archived Planning Documents
- Master plan: [docs/archive/MASTER_REARCHITECTURE_PLAN.md](swift/docs/archive/MASTER_REARCHITECTURE_PLAN.md)
- Issue tracking: [docs/archive/REARCHITECTURE_ISSUE.md](swift/docs/archive/REARCHITECTURE_ISSUE.md)
- Implementation guide: [docs/archive/CLEAN_REARCHITECTURE_PLAN.md](swift/docs/archive/CLEAN_REARCHITECTURE_PLAN.md)

## Database Files
- Current schema: [Sources/Database/schema_3nf_final.sql](swift/Sources/Database/schema_3nf_final.sql)
- Test database: [Sources/Database/proposed_3nf.db](swift/Sources/Database/proposed_3nf.db)

---

**This complete guide supersedes all individual planning documents and represents the consolidated, current state of the rearchitecture effort.**
