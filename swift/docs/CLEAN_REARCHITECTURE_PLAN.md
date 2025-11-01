# Clean Rearchitecture Plan - No Backward Compatibility
**Date**: 2025-10-30
**Written by**: Claude Code

## Overview
This document outlines what's needed for a complete, clean transition to 3NF schema without maintaining backward compatibility. This assumes we're willing to start fresh with the new structure.

## Current State vs Clean State

### What We Have Now (Compromises)
1. **Legacy field support** in models (termUUID vs termId)
2. **Broken services** (MatchingService, ViewModels)
3. **Mixed paradigms** (some JSON, some normalized)
4. **Incomplete business logic migration**
5. **Views expecting old structure**

### What We Need (Clean Architecture)

## 1. Database Layer (✅ MOSTLY COMPLETE)

### Completed
- [x] 3NF schema design
- [x] Pure junction tables
- [x] Metrics catalog
- [x] Foreign key constraints
- [x] Proper indexes

### Still Needed
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

## 2. Model Layer (⚠️ PARTIALLY COMPLETE)

### Completed
- [x] Core entities (Action, Goal, Value, Term, Metric)
- [x] Junction tables (ActionMetric, GoalRelevance, etc.)
- [x] ValueLevel enum

### Still Needed
- [ ] **Remove ALL legacy support**
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

## 3. Repository/Service Layer (❌ INCOMPLETE)

### Completed
- [x] MetricRepository (basic CRUD)
- [x] GoalValidation (classification logic)

### Still Needed

#### Core Repositories
- [ ] **ActionRepository**
  ```swift
  class ActionRepository {
      func create(action: Action, metrics: [(Metric, Double)])
      func findWithMetrics(id: UUID) -> (Action, [ActionMetric])
      func findByMetric(metric: Metric) -> [Action]
      func sumByMetric(metric: Metric, dateRange: DateRange) -> Double
  }
  ```

- [ ] **GoalRepository**
  ```swift
  class GoalRepository {
      func create(goal: Goal, targets: [(Metric, Double)], values: [Value])
      func findWithProgress(id: UUID) -> GoalWithProgress
      func findByTerm(term: Term) -> [Goal]
      func findByValue(value: Value) -> [Goal]
  }
  ```

- [ ] **ValueRepository**
  ```swift
  class ValueRepository {
      func findByLevel(level: ValueLevel) -> [Value]
      func findAlignedGoals(value: Value) -> [Goal]
      func calculateAlignment(action: Action) -> [ValueAlignment]
  }
  ```

#### Business Services
- [ ] **ProgressCalculationService**
  ```swift
  class ProgressCalculationService {
      func calculateGoalProgress(goal: Goal) -> Progress
      func calculateTermProgress(term: Term) -> TermProgress
      func projectCompletion(goal: Goal) -> Date?
  }
  ```

- [ ] **AlignmentService**
  ```swift
  class AlignmentService {
      func scoreActionValueAlignment(action: Action, value: Value) -> Double
      func suggestValuesForGoal(goal: Goal) -> [Value]
      func findMisalignedGoals() -> [Goal]
  }
  ```

- [ ] **MetricAggregationService**
  ```swift
  class MetricAggregationService {
      func dailyTotals(metric: Metric) -> [DayTotal]
      func weeklyAverages(metric: Metric) -> [WeekAverage]
      func trends(metric: Metric) -> Trend
  }
  ```

## 4. ViewModel Layer (❌ NEEDS COMPLETE REWRITE)

### Current Problems
- Expect JSON measuresByUnit
- Direct model access instead of repositories
- No proper state management
- Assume flat Goal fields

### Needed ViewModels

- [ ] **ActionEntryViewModel**
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

- [ ] **GoalPlanningViewModel**
  ```swift
  @MainActor
  class GoalPlanningViewModel: ObservableObject {
      @Published var targets: [MetricTarget] = []
      @Published var alignedValues: [Value] = []
      @Published var smartStatus: GoalClassification

      func addTarget(metric: Metric, value: Double)
      func alignWithValue(_ value: Value, strength: Int)
      func validateSMART() -> [ValidationIssue]
  }
  ```

- [ ] **DashboardViewModel**
  ```swift
  @MainActor
  class DashboardViewModel: ObservableObject {
      @Published var activeGoals: [GoalWithProgress] = []
      @Published var recentActions: [ActionWithMetrics] = []
      @Published var valueAlignment: ValueAlignmentSummary

      func refreshDashboard() async
      func getMetricTrends(for period: DateRange) async
  }
  ```

## 5. View Layer (❌ NEEDS COMPLETE REWRITE)

### Current Problems
- Reference removed Goal fields (measurementUnit, measurementTarget)
- Expect flat structures instead of relationships
- No metric selection UI
- No value alignment UI

### Needed Views

- [ ] **MetricSelector**
  ```swift
  struct MetricSelector: View {
      @Binding var selectedMetrics: [(Metric, Double)]
      let availableMetrics: [Metric]

      var body: some View {
          // UI for selecting metrics and entering values
      }
  }
  ```

- [ ] **ValueAlignmentPicker**
  ```swift
  struct ValueAlignmentPicker: View {
      @Binding var alignments: [(Value, Int)]
      let availableValues: [Value]

      var body: some View {
          // UI for selecting values and alignment strength
      }
  }
  ```

- [ ] **ProgressVisualization**
  ```swift
  struct ProgressVisualization: View {
      let goal: Goal
      let progress: GoalProgress

      var body: some View {
          // Charts showing progress by metric
      }
  }
  ```

## 6. Migration Strategy (❌ NEEDS DECISION)

### Option A: Clean Break
1. Export existing data
2. Deploy new schema
3. Import with deduplication
4. No backward compatibility

### Option B: Parallel Run
1. Deploy new schema alongside old
2. Dual-write period
3. Migrate users gradually
4. Remove old schema after verification

### Option C: Versioned Migration
1. Version the database
2. Run migrations on app start
3. Support rollback if needed
4. Progressive enhancement

## 7. Testing Requirements (❌ NOT STARTED)

### Unit Tests Needed
- [ ] Model validation
- [ ] Repository CRUD operations
- [ ] Service business logic
- [ ] ViewModel state management

### Integration Tests Needed
- [ ] Database migrations
- [ ] Full CRUD cycles
- [ ] Relationship traversal
- [ ] Performance benchmarks

### UI Tests Needed
- [ ] Action entry flow
- [ ] Goal planning flow
- [ ] Progress tracking
- [ ] Value alignment

## 8. Documentation Needs (⚠️ PARTIAL)

### Completed
- [x] Schema documentation
- [x] Migration challenges

### Still Needed
- [ ] API documentation for repositories
- [ ] Service layer contracts
- [ ] ViewModel state diagrams
- [ ] User flow diagrams
- [ ] Query optimization guide

## 9. Performance Considerations

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

## 10. Feature Implications

### New Features Enabled by 3NF
- Multi-metric goals (e.g., "Run 100km AND 20 sessions")
- Metric conversions (km ↔ miles)
- Value alignment scoring
- Cross-goal metric aggregation
- Historical trend analysis

### Features That Need Rethinking
- Quick action entry (now needs metric selection)
- Goal templates (must include metric definitions)
- Import/Export (new structure)
- Sync strategy (more complex relationships)

## Summary: What's Really Needed

### Critical Path (Must Have)
1. **Repository Layer** - Complete CRUD + business logic
2. **ViewModels** - Complete rewrite for new structure
3. **Views** - Update all forms and displays
4. **Migration** - Clean data import strategy

### Important (Should Have)
1. **Testing** - At least integration tests
2. **Documentation** - API and user guides
3. **Performance** - Basic query optimization

### Nice to Have
1. **Advanced features** - Multi-metric goals, conversions
2. **Analytics** - Trend analysis, predictions
3. **Optimization** - Caching, denormalization

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

## Recommendation

**Go for the clean break.** The current schema has fundamental issues (JSON fields, redundant tables) that make backward compatibility expensive to maintain. A clean migration would:

1. Simplify the codebase
2. Enable better performance
3. Reduce long-term maintenance
4. Allow proper relationship modeling
5. Enable new features naturally

The migration script already works. The main effort is in the service/view layers, which need rewriting regardless.