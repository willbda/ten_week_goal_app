# Rearchitecture: Database Schema → Models → Protocols → ViewModels

**Labels**: `rearchitecture`, `database`, `breaking-change`, `multi-phase`

## Overview

Systematic rearchitecture of the app's data layer, starting with database schema design and progressing through Swift models, protocols, and viewmodels. This is guided by the principle that **classes in Swift should reflect natural hierarchies, not merely shared behaviors** (per Apple guidance), and that on Apple platforms we build with UI very close to data structures.

**Current Phase**: Phase 3 - Repository/Service Layer (ready to start)
**Last Update**: 2025-10-30 - Completed Phases 1-2, Created Master Plan
**Master Document**: 📘 See `docs/MASTER_REARCHITECTURE_PLAN.md` for consolidated documentation

## ⚠️ Breaking Changes Introduced (2025-10-30)

The 3NF normalization has intentionally broken several parts of the app:
1. **MatchingService** - References removed `measuresByUnit` and `measurementUnit`
2. **GoalFormView** - References removed Goal fields
3. **ActionsViewModel** - Expects JSON measuresByUnit
4. **GoalsViewModel** - References removed `goal.isSmart()` method

These are expected and will be fixed in Phases 3-6 as we build the service layer and update views.

---

## Guiding Principles

From `docs/20251025_plan.md`:

1. **Clarify database schemas as ontology** - What entities exist? What relationships matter?
2. **Define protocols and classes** - General patterns, attributes, and behaviors
3. **Define models in structs and classes** - Concrete implementations
4. **Extend protocols for separation of concerns** - Clean boundaries
5. **Define viewmodel protocols and classes** - UI state management

**Expected**: Each part of the app will break as we do this. This is intentional.

**Testing Philosophy**: Think carefully about how we test and what we test at each phase.

---

## Phase 1: Database Schema Design (✅ COMPLETED)

**Status**: Completed 2025-10-30

### Current Challenge: Schema Questions

From `docs/20251025_plan.md`, these are the core questions driving schema design:

#### Relationship Queries Needed
- "Show me all Actions that contribute to Goal X"
- "Show me all Goals in Term Y"
- "Show me Actions aligned with Value Z"
- "What Values does Goal X serve?"

#### Aggregation Queries Needed
- "Sum all Action measurements (km) toward Goal target (120 km)"
- "Show progress percentage for each Goal in current Term"
- "Count Actions per Value/LifeDomain over time period"

#### Hierarchy Questions
- Are Values/MajorValues/HighestOrderValues really different types, or different **priority levels** of the same type?
- Are Goal/Milestone really different types, or different **configurations** of the same type?

#### Temporal Queries Needed
- "Actions logged in date range"
- "Goals due in next 2 weeks"
- "Terms that overlap with date X"

### Current Schema Problems

**Problem 1**: 4 separate value tables with `polymorphicSubtype`
- Makes "get all my values regardless of priority" require UNION queries
- Hard to maintain, hard to query

**Problem 2**: No relationship tables
- No `action_goal_contributions` → can't query "which goals does this action serve?"
- No `goal_value_alignments` → can't query "which values does this goal align with?"

**Problem 3**: JSON dictionaries for structured data
- `measuresByUnit` in Action → requires JSON parsing, can't index, fragile
- Should be: metrics as first-class entities with proper relationships

**Problem 4**: Flat text for structured relationships
- `howGoalIsRelevant` (flat text) → should be structured goal-value alignments
- `howGoalIsActionable` (flat text) → should be structured measurement targets

### Design Iterations

Two schema designs have been explored:

#### schema_rearchitected.sql
- Metrics as first-class entities (not JSON)
- Unified values table (not 4 tables)
- Goals with computed `isSmart` column
- Explicit relationship tables
- Migration tested with Python script on 381 actions, 16 goals, 13 values

#### schema_uniform.md
- **Uniform Base** principle: All entities share Persistable fields
- Each entity adds only domain-specific fields
- Junction tables also conform to Persistable base
- Type discrimination via enum fields (not `polymorphicSubtype`)

### Phase 1 Tasks (COMPLETED 2025-10-30)

- [x] **Finalize core schema decisions**
  - ✅ Unified values table with `ValueLevel` enum
  - ✅ Metrics as first-class entities (`Metric` model)
  - ✅ Pure junction tables (no Persistable fields)

- [x] **Define metrics catalog structure**
  - ✅ Created `Metric` model with unit, metricType fields
  - ✅ Type grouping via `metricType` (distance, time, count)
  - ✅ Unit conversion support via `canonicalUnit` & `conversionFactor`

- [x] **Design relationship tables**
  - ✅ `MeasuredAction`: action → metric → value (measurements)
  - ✅ `GoalMetric`: goal → metric → targetValue (targets)
  - ✅ `GoalRelevance`: goal → value → alignment (why relevant)
  - ✅ `ActionGoalContribution`: action → goal (progress tracking)
  - ✅ `TermGoalAssignment`: term → goal (updated to pure junction)

- [x] **Swift implementation** (replaced Python migration)
  - ✅ All models compile with SQLiteData
  - ✅ Database migrations in TenWeekGoalApp.swift
  - ✅ MetricRepository service for queries

- [x] **Document schema decisions**
  - ✅ Unified values: Single table with enum discrimination
  - ✅ Metrics as entities: No JSON parsing, proper indexes
  - ✅ Junction tables: Pure DB artifacts, no business fields

**Deliverable**: ✅ 3NF normalized schema with Swift models

---

## Phase 2: Swift Model Alignment (COMPLETED WITH PHASE 1)

**Status**: ✅ Completed 2025-10-30 - Models created during Phase 1

Note: Phase 2 was completed simultaneously with Phase 1 since we implemented
the 3NF normalization directly in Swift rather than Python migration.

### Current State (OLD Models)

**Action.swift**:
```swift
@Table
struct Action: Persistable, Doable {
    var measuresByUnit: [String: Double] = [:]  // ❌ JSON
    var durationMinutes: Double?
    var startTime: Date?
}
```

**Goal.swift**:
```swift
@Table
struct Goal: Persistable, Completable, Polymorphable {
    var measurementUnit: String?              // ❌ Flat field
    var measurementTarget: Double?            // ❌ Flat field
    var howGoalIsRelevant: String?            // ❌ Flat text
    var howGoalIsActionable: String?          // ❌ Flat text
    var polymorphicSubtype: String = "goal"   // ❌ String type discrimination
}
```

**Values** (4 separate structs):
```swift
@Table struct Values { ... }
@Table struct MajorValues { ... }
@Table struct HighestOrderValues { ... }
@Table struct LifeAreas { ... }
```

### Target State (Aligned with Schema)

Will depend on Phase 1 decisions, but likely:

**New Model Structs**:
- `Metric.swift` - Catalog of units (km, hours, reps)
- `MeasuredAction.swift` - Action measurements (junction)
- `GoalMetric.swift` - Goal targets (junction)
- `GoalRelevance.swift` - Goal-value alignments (junction)

**Updated Model Structs**:
- `Action.swift` - Remove `measuresByUnit`, keep action-specific fields
- `Goal.swift` - Remove flat fields, add `goalType: GoalType` enum
- `PersonalValue.swift` - Unified struct with `valueLevel: ValueLevel` enum

### Phase 2 Completed Tasks (2025-10-30)

- [x] Created new model structs:
  - ✅ `Metric.swift` - Unit catalog
  - ✅ `MeasuredAction.swift` - Action measurements
  - ✅ `GoalRelevance.swift` - Goal-value alignments
  - ✅ `ActionGoalContribution.swift` - Action-goal progress

- [x] Updated existing models:
  - ✅ `Action.swift` - Removed measuresByUnit JSON
  - ✅ `Value.swift` - Unified with ValueLevel enum
  - ✅ `TermGoalAssignment.swift` - Renamed fields for consistency

- [x] Updated `@Table` definitions:
  - ✅ All models use SQLiteData @Table macro
  - ✅ ValueLevel conforms to QueryRepresentable & QueryBindable

- [x] CloudKit sync configuration:
  - ✅ Updated TenWeekGoalApp.swift SyncEngine with new models

**Deliverable**: ✅ Swift models match 3NF database schema

---

## Phase 3: Protocol Redesign (NOT STARTED)

**Status**: Waiting for Phase 2 completion

Redesign protocols based on actual schema patterns and query needs.

### Current Protocols (Protocols.swift)

```swift
protocol Persistable { ... }      // ✅ Keep - uniform base
protocol Completable { ... }      // ? Review - future-oriented entities
protocol Measurable { ... }       // ? Review - measurement-capable entities

// Removed (already):
// protocol Doable
// protocol Motivating
// protocol Polymorphable
```

### Design Questions for Phase 3

1. **Do we need Completable?**
   - Now that measurements are in `goal_metrics`, what does Completable provide?
   - Is it just a marker: "has target dates"?

2. **Do we need Measurable?**
   - Actions can have metrics, but so can goals (targets)
   - Is this a useful capability marker?

3. **What about business logic?**
   - Protocols should be **field contracts** (compile-time safety)
   - Business logic should live in **Services/Repositories** (runtime queries)

### Phase 3 Tasks

- [ ] Review protocol usage patterns in Phase 2 models
- [ ] Identify: what protocols enforce field contracts vs business logic?
- [ ] Redesign protocols as pure field contracts
- [ ] Move any business logic to service layer
- [ ] Document protocol design decisions

**Deliverable**: Clean protocols that enforce schema contracts

---

## Phase 4: Repository/Service Layer (NOT STARTED)

**Status**: Waiting for Phase 3 completion

Build query and business logic layer over new schema.

### Services Needed

Based on query requirements:

**MetricRepository**:
- `fetchMetrics() -> [Metric]` - catalog of available metrics
- `fetchMetricsFor(action:) -> [MeasuredAction]` - measurements for action
- `addMetricTo(action:metric:value:)` - record measurement

**ProgressCalculator**:
- `calculateProgress(for goal:) -> (actual, target, percentage)`
- Uses: `action_metrics` + `action_goal_contributions` + `goal_metrics`
- Example: "Spring into Running" → 87km / 120km = 72.5%

**ValueAlignmentAnalyzer**:
- `goalsAlignedWith(value:) -> [Goal]` - via `goal_relevance`
- `valuesFor(goal:) -> [PersonalValue]` - reverse query
- `identifyGaps() -> [PersonalValue]` - values with no goals

**MetricAggregator**:
- `totalDistance() -> Double` - SUM all km metrics
- `totalTime(for period:) -> TimeInterval` - SUM hours/minutes
- `metricTrends(for metric:, over period:)` - time series data

### Phase 4 Tasks

- [ ] Create repository layer for each entity type
- [ ] Implement query methods needed by UI
- [ ] Add aggregation and calculation services
- [ ] Test with sample data
- [ ] Document service APIs

**Deliverable**: Services that answer all query questions

---

## Phase 5: ViewModel Layer (NOT STARTED)

**Status**: Waiting for Phase 4 completion

Build UI state management on top of services.

### ViewModel Patterns

**ActionsViewModel**:
- Fetches actions with their metrics (via ActionRepository)
- Exposes: `actions: [Action]`, `metrics: [MeasuredAction]`
- Handles: filtering, sorting, date ranges

**GoalsViewModel**:
- Fetches goals with progress (via ProgressCalculator)
- Exposes: `goals: [Goal]`, `progress: [UUID: Double]`
- Handles: SMART vs minimal goal display logic

**ValuesViewModel**:
- Fetches values with alignment (via ValueAlignmentAnalyzer)
- Exposes: `values: [PersonalValue]`, `alignments: [UUID: [Goal]]`
- Handles: value level filtering, gap identification

### Phase 5 Tasks

- [ ] Design ViewModel protocols (if needed)
- [ ] Implement ViewModels for each entity type
- [ ] Connect ViewModels to services
- [ ] Update Views to use ViewModels
- [ ] Test UI flows end-to-end

**Deliverable**: Working UI with clean separation of concerns

---

## Phase 6: View Updates (NOT STARTED)

**Status**: Waiting for Phase 5 completion

Update all views to work with new ViewModels and schema.

### Views to Update

- `ActionsListView` - Display metrics from relationship tables
- `ActionFormView` - Metric picker (from catalog)
- `GoalsListView` - Show progress calculations
- `GoalFormView` - Goal metrics picker, value alignment picker
- `ValuesListView` - Unified value list with level filtering
- `TermsListView` - Show goals in term

### Phase 6 Tasks

- [ ] Update all list views
- [ ] Update all form views
- [ ] Add metric picker UI
- [ ] Add value alignment UI
- [ ] Test all user flows

**Deliverable**: Fully functional UI on new architecture

---

## Phase 7: Testing & Polish (NOT STARTED)

**Status**: Waiting for Phase 6 completion

Comprehensive testing and quality improvements.

### Testing Strategy

**Unit Tests**:
- Model struct validation
- Protocol conformance
- Service query correctness

**Integration Tests**:
- Database migrations
- Repository queries
- ViewModel state management

**UI Tests**:
- Critical flows (add action, create goal)
- Form validation
- Progress calculations

**Performance Tests**:
- Query performance (old vs new)
- Large dataset handling
- CloudKit sync efficiency

### Accessibility (Pre-v1.0.0 Priority)

From `docs/20251025_plan.md`:
- "I do want to hold on to accessibility and make it a priority before v 1.0.0"

**Tasks**:
- [ ] VoiceOver testing
- [ ] Keyboard navigation
- [ ] Color contrast checks
- [ ] Semantic labels on form fields
- [ ] Dynamic type support

### Phase 7 Tasks

- [ ] Write comprehensive test suite
- [ ] Accessibility audit and fixes
- [ ] Performance profiling
- [ ] Migration validation (no data loss)
- [ ] Documentation updates

**Deliverable**: Production-ready rearchitected app

---

## Migration Strategy

### Development Approach

**Phase 1**: Design in isolation
- Experiment with schema designs
- Test with Python migration scripts
- Validate queries return expected results
- Document decisions

**Phases 2-3**: Non-breaking additions
- Add new models alongside old
- Keep old models working
- Test new models in isolation

**Phases 4-6**: Breaking changes
- Create feature branch
- Switch to new models
- Expect things to break (intentional)
- Fix piece by piece

**Phase 7**: Stabilization
- Comprehensive testing
- Bug fixes
- Performance tuning
- Merge to main

### Rollback Plan

- Keep old schema in `schema_old.sql` for reference
- Tag working commits at each phase
- Feature branch until Phase 7 complete
- If major issues: revert to last stable tag

---

## Open Questions & Considerations

From `docs/20251025_plan.md`:

### Concurrency & Threading
> "I'm not at all sure how to think about threading and concurrency."

**Considerations**:
- Models are `Sendable` structs ✅
- Should repositories be `@MainActor` or background actors?
- Where do we use `async/await`?
- How to handle concurrent writes to database?

### Polymorphism
> "I don't know about polymorphism right now. It was a learning exercise, but it might not be useful."

**Current thinking**:
- Enum fields instead of `polymorphicSubtype` strings
- `goalType: GoalType` enum (`.goal | .milestone`)
- `valueLevel: ValueLevel` enum (`.general | .major | .highestOrder | .lifeArea`)

### Testing Philosophy
> "This is a fine time to think again about how I test and what I test."

**Questions**:
- What level of testing is appropriate for each phase?
- Focus on integration tests (query correctness)?
- UI tests for critical flows only?
- Performance benchmarks?

### Remove Inference
> "Let's remove inference entirely for now"

**Action**: Defer inference services until rearchitecture complete

---

## Success Criteria

✅ **Phase 1**: Schema enables all required queries efficiently
✅ **Phase 2**: Swift models match schema exactly
✅ **Phase 3**: Protocols enforce field contracts cleanly
✅ **Phase 4**: Services answer all business logic questions
✅ **Phase 5**: ViewModels manage UI state effectively
✅ **Phase 6**: All views work with new architecture
✅ **Phase 7**: Tests pass, accessibility achieved, performance improved

---

## Files & Documentation

### Reference Documents
- `docs/20251025_plan.md` - Design thoughts and questions
- `Sources/Database/schema_uniform.md` - Uniform schema design
- `Sources/Database/schema_rearchitected.sql` - Rearchitected schema SQL
- `Sources/Database/migrate_to_rearchitected.py` - Python migration script

### Schema Files
- `Sources/Database/schema_old.sql` - Current production schema (baseline)
- `Sources/Database/schema_rearchitected.sql` - Candidate design with metrics
- `Sources/Database/schema_uniform.sql` - Candidate design with uniform base

### Sample Data
- `Sources/Database/sample_rearchitected.db` - Test database with migrated data
- Migration tested: 381 actions, 16 goals, 13 values, 5 metrics

---

## Related Issues

- #6 - Add Apple Health Workout Viewer (can integrate with metrics system after Phase 4)

---

**Repository**: https://github.com/willbda/ten_week_goal_app
**Current Phase**: 1 (Database Schema Design)
**Created**: 2025-10-27
