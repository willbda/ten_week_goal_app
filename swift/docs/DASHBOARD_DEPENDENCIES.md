# Dashboard Implementation Dependencies

**Created:** 2025-11-10
**Current Version:** v0.6.5 (Validation layer complete)
**Target Version:** v0.8.0-v0.9.0 (Dashboard ready)

---

## Current Status

### ✅ Completed (v0.6.5)
- **Validation Layer** - Business rules enforcement, error mapping
- **Coordinator Pattern** - Multi-model atomic writes
- **Database Schema** - 3NF normalization with indexes
- **Query Infrastructure** - Indexes on all foreign keys, proven to handle complex JOINs

### 🚧 In Progress
- **Repositories** - Scaffolded but not fully implemented (ActionRepository, PersonalValueRepository partially done)

### ⏳ Not Started
- **Business Services** - ProgressCalculation, MetricAggregation, Alignment
- **DashboardViewModel** - Aggregated metrics presentation
- **Chart Components** - Visual data representation
- **Dashboard View** - UI composition

---

## Dependencies Analysis

### Critical Path: What Blocks Dashboard?

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Complete Repositories (BLOCKING)                   │
│ ├── GoalRepository (progress queries)                       │
│ ├── ActionRepository (aggregations)                         │
│ └── PersonalValueRepository (alignment queries)             │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 5: Build Business Services (BLOCKING)                 │
│ ├── ProgressCalculationService                              │
│ ├── MetricAggregationService                                │
│ └── AlignmentService                                         │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 6: DashboardViewModel (BLOCKING)                      │
│ └── Orchestrate services for dashboard data                 │
└─────────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 7: Dashboard UI (CAN START)                           │
│ ├── Chart components                                        │
│ ├── Progress visualizations                                 │
│ └── Layout composition                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Dependency 1: Complete Repositories (Phase 4)

### Why Needed
Dashboards require **aggregated queries** across multiple tables. Repositories provide clean, tested query APIs.

### Current State
**Scaffolded but incomplete:**
- ✅ `PersonalValueRepository.swift` - **COMPLETE** (simple, no complex queries)
- 🔄 `ActionRepository.swift` - **PARTIAL** (has complex queries, needs aggregations)
- 🔄 `GoalRepository.swift` - **SCAFFOLDED** (needs progress queries)
- 🔄 `TimePeriodRepository.swift` - **SCAFFOLDED** (needs term queries)

### What's Missing

#### GoalRepository (Priority 1)

**Dashboard needs these queries:**
```swift
// 1. All goals with progress percentage
func fetchAllWithProgress() async throws -> [GoalProgress]

// 2. Goals approaching deadlines (< 7 days)
func fetchUpcomingDeadlines() async throws -> [GoalWithDeadline]

// 3. Goals by status (on track, behind, complete)
func fetchByStatus(_ status: GoalStatus) async throws -> [Goal]

// 4. Goals by term (for term overview)
func fetchByTerm(_ termId: UUID) async throws -> [GoalWithProgress]
```

**Required SQL patterns:**
```sql
-- Progress calculation with status
SELECT
    goals.id,
    expectations.title,
    goals.targetDate,
    SUM(measuredActions.value) as current,
    expectationMeasures.targetValue as target,
    ROUND(SUM(measuredActions.value) / expectationMeasures.targetValue * 100, 1) as percent,
    CASE
        WHEN SUM(measuredActions.value) >= expectationMeasures.targetValue THEN 'complete'
        WHEN goals.targetDate < DATE('now') THEN 'overdue'
        WHEN ... THEN 'on_track'
        ELSE 'behind'
    END as status
FROM goals
-- ... complex JOIN and GROUP BY
```

**Reference:** See `SQL_QUERY_PATTERNS.md` Query 1 (Goal Progress Overview)

---

#### ActionRepository (Priority 2)

**Dashboard needs these aggregations:**
```swift
// 1. Activity summary for date range
func summarizeActivity(in range: ClosedRange<Date>) async throws -> ActivitySummary

// 2. Total by measure for dashboard widgets
func totalByMeasure(_ measureId: UUID, in range: ClosedRange<Date>) async throws -> Double

// 3. Daily/weekly breakdown for charts
func dailyTotals(measure: Measure, in range: ClosedRange<Date>) async throws -> [DayTotal]
```

**Required SQL patterns:**
```sql
-- Daily activity summary
SELECT
    DATE(logTime) as date,
    COUNT(DISTINCT id) as action_count,
    SUM(durationMinutes) as total_minutes
FROM actions
WHERE logTime >= :start AND logTime <= :end
GROUP BY DATE(logTime)
ORDER BY date DESC;
```

**Current State:**
- ✅ Has `fetchRecentActions()` (complex multi-table query)
- ✅ Has `totalByMeasure()` (aggregation)
- ❌ Missing daily/weekly aggregations
- ❌ Missing activity summary

---

#### PersonalValueRepository (Priority 3)

**Dashboard needs these queries:**
```swift
// Value alignment report
func calculateEngagement() async throws -> [ValueEngagement]
```

**Required SQL pattern:**
```sql
-- Value engagement score
SELECT
    personalValues.title,
    COUNT(DISTINCT goalRelevances.goalId) as goal_count,
    AVG(goalRelevances.alignmentStrength) as avg_alignment,
    COUNT(DISTINCT actionGoalContributions.actionId) as action_count,
    -- Engagement score calculation
    ROUND(goal_count * avg_alignment * action_count / 100.0, 2) as score
FROM personalValues
LEFT JOIN goalRelevances ...
GROUP BY personalValues.id;
```

**Current State:** ✅ **COMPLETE** - Has basic queries, can add this method

---

### Estimated Effort: 3-5 days

| Repository | Status | Effort | Priority |
|------------|--------|--------|----------|
| PersonalValue | ✅ Complete | - | Low |
| Action | 🔄 70% done | 1 day | High |
| Goal | 🔄 20% done | 2-3 days | **Critical** |
| TimePeriod | ⏳ Scaffolded | 1 day | Medium |

**Recommendation:** Focus on GoalRepository first (blocks most dashboard features).

---

## Dependency 2: Business Services (Phase 5)

### Why Needed
Repositories return raw data. Services apply **business logic** and **domain calculations**.

### Missing Services

#### ProgressCalculationService

**Purpose:** Calculate progress for goals/terms with complex logic

```swift
public struct GoalProgress {
    let goal: Goal
    let currentProgress: Double
    let targetValue: Double
    let percentComplete: Double
    let status: ProgressStatus
    let daysRemaining: Int
    let projectedCompletion: Date?
}

@MainActor
public final class ProgressCalculationService {
    private let goalRepository: GoalRepository
    private let actionRepository: ActionRepository

    // Calculate progress for single goal
    func calculateProgress(for goal: Goal) async throws -> GoalProgress

    // Calculate progress for all goals in term
    func calculateTermProgress(for term: Term) async throws -> TermProgress

    // Project completion date based on current pace
    func projectCompletion(for goal: Goal) async throws -> Date?
}
```

**Why Service Layer?**
- Complex calculation: current pace vs required pace
- Projection logic (linear regression on progress)
- Status determination (on track, behind, etc.)
- Reusable across dashboard widgets

**Estimated Effort:** 2 days

---

#### MetricAggregationService

**Purpose:** Time-series aggregations for charts

```swift
public struct DayTotal {
    let date: Date
    let value: Double
}

public struct Trend {
    let direction: TrendDirection  // up, down, steady
    let percentChange: Double
    let weeklyAverage: Double
}

@MainActor
public final class MetricAggregationService {
    private let actionRepository: ActionRepository

    // Daily totals for sparkline charts
    func dailyTotals(_ measure: Measure, in range: ClosedRange<Date>) async throws -> [DayTotal]

    // Weekly averages for trend analysis
    func weeklyAverages(_ measure: Measure, weeks: Int) async throws -> [WeekAverage]

    // Trend detection (up/down/steady)
    func analyzeTrend(_ measure: Measure, weeks: Int) async throws -> Trend
}
```

**Why Service Layer?**
- Chart data preparation (fill gaps, smooth outliers)
- Trend calculation (moving averages, momentum)
- Multiple time granularities (daily, weekly, monthly)

**Estimated Effort:** 2 days

---

#### AlignmentService

**Purpose:** Calculate value-goal alignment scores

```swift
public struct ValueAlignment {
    let value: PersonalValue
    let goalCount: Int
    let actionCount: Int
    let engagementScore: Double  // Composite metric
}

@MainActor
public final class AlignmentService {
    private let valueRepository: PersonalValueRepository
    private let goalRepository: GoalRepository

    // Calculate engagement for all values
    func calculateEngagement() async throws -> [ValueAlignment]

    // Find misaligned goals (low value alignment)
    func findMisalignedGoals() async throws -> [Goal]

    // Suggest values for goal
    func suggestValues(for goal: Goal) async throws -> [PersonalValue]
}
```

**Why Service Layer?**
- Complex scoring algorithm
- Machine learning potential (future)
- Recommendation logic

**Estimated Effort:** 1-2 days

---

### Total Services Effort: 5-6 days

---

## Dependency 3: DashboardViewModel (Phase 6)

### Why Needed
Orchestrates services and manages dashboard state.

### Implementation

```swift
@Observable
@MainActor
public final class DashboardViewModel {
    // State
    var isLoading = false
    var errorMessage: String?
    var lastRefreshed: Date?

    // Dashboard data
    var goalProgress: [GoalProgress] = []
    var valueAlignment: [ValueAlignment] = []
    var weeklyActivity: [DayTotal] = []
    var upcomingDeadlines: [GoalWithDeadline] = []

    // Services (injected)
    @ObservationIgnored
    private let progressService: ProgressCalculationService
    @ObservationIgnored
    private let aggregationService: MetricAggregationService
    @ObservationIgnored
    private let alignmentService: AlignmentService

    // Load all dashboard data
    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        async let progress = progressService.calculateProgress(for: currentTerm)
        async let alignment = alignmentService.calculateEngagement()
        async let activity = aggregationService.dailyTotals(measure: timeSpent, weeks: 2)
        async let deadlines = goalRepository.fetchUpcomingDeadlines()

        do {
            (goalProgress, valueAlignment, weeklyActivity, upcomingDeadlines) =
                try await (progress, alignment, activity, deadlines)
            lastRefreshed = Date()
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
        }
    }
}
```

**Estimated Effort:** 1-2 days (after services complete)

---

## Dependency 4: Dashboard UI Components (Phase 7)

### What's Needed

#### Chart Components

**Progress Ring:**
```swift
struct ProgressRingView: View {
    let progress: Double  // 0.0-1.0
    let status: ProgressStatus

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(statusColor, lineWidth: 10)
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
        }
    }
}
```

**Activity Sparkline:**
```swift
struct SparklineView: View {
    let data: [DayTotal]

    var body: some View {
        Canvas { context, size in
            // Draw line chart
        }
        .frame(height: 40)
    }
}
```

**Value Alignment Bar Chart:**
```swift
struct AlignmentBarView: View {
    let alignments: [ValueAlignment]

    var body: some View {
        ForEach(alignments) { alignment in
            HStack {
                Text(alignment.value.title)
                ProgressView(value: alignment.engagementScore / maxScore)
                Text("\(Int(alignment.engagementScore))")
            }
        }
    }
}
```

**Estimated Effort:** 3-4 days (if using native SwiftUI Charts framework)

---

#### Dashboard Layout

**Dashboard View:**
```swift
struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick stats
                QuickStatsRow(stats: viewModel.quickStats)

                // Goal progress cards
                GoalProgressSection(goals: viewModel.goalProgress)

                // Activity chart
                ActivityChartSection(activity: viewModel.weeklyActivity)

                // Value alignment
                ValueAlignmentSection(alignment: viewModel.valueAlignment)

                // Upcoming deadlines
                DeadlinesSection(deadlines: viewModel.upcomingDeadlines)
            }
            .padding()
        }
        .task {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
```

**Estimated Effort:** 2-3 days (composition and polish)

---

## Optional: Performance Optimizations

### Caching Strategy (If needed)

**Problem:** Dashboard queries might be slow with 100K+ actions

**Solution:** Cache aggregated results

```swift
@MainActor
public final class DashboardCache {
    private var cachedProgress: [GoalProgress]?
    private var cacheExpiry: Date?

    func getCachedProgress() -> [GoalProgress]? {
        guard let expiry = cacheExpiry, expiry > Date() else {
            return nil
        }
        return cachedProgress
    }

    func cacheProgress(_ progress: [GoalProgress], ttl: TimeInterval = 300) {
        cachedProgress = progress
        cacheExpiry = Date().addingTimeInterval(ttl)
    }
}
```

**When to Implement:** Only if profiling shows >500ms dashboard load time

**Estimated Effort:** 1 day

---

## Implementation Timeline

### Recommended Sequence

```
Week 1: Complete Repositories
├── Day 1-2: GoalRepository (critical path)
├── Day 3: ActionRepository aggregations
└── Day 4: TimePeriodRepository

Week 2: Build Services
├── Day 1-2: ProgressCalculationService
├── Day 3-4: MetricAggregationService
└── Day 5: AlignmentService

Week 3: Dashboard Implementation
├── Day 1-2: DashboardViewModel
├── Day 3-5: UI Components (charts, layout)
└── Weekend: Polish and testing

Total: 3 weeks for complete dashboard
```

### Minimum Viable Dashboard (MVP Approach)

**If you want dashboard sooner (1 week):**

```
Phase 1 (3 days): Basic Dashboard
├── Complete GoalRepository.fetchAllWithProgress()
├── Simple ProgressCalculationService (just percent complete)
├── DashboardViewModel with goal progress only
└── Basic ProgressRingView components

Phase 2 (2 days): Add Activity
├── ActionRepository.dailyTotals()
├── Simple SparklineView
└── Activity section in dashboard

Phase 3 (Future): Full Features
├── Value alignment
├── Trend analysis
└── Recommendations
```

**MVP delivers:**
- Goal progress cards with percentage complete
- Weekly activity sparkline
- Upcoming deadlines list

**Defers:**
- Complex trend analysis
- Value alignment scoring
- Recommendation engine

---

## Dependency Summary

### Must Have (Blocking)
1. ✅ Database schema with indexes - **DONE**
2. ✅ Validation layer - **DONE**
3. 🚧 GoalRepository with progress queries - **IN PROGRESS** (2-3 days)
4. 🚧 ActionRepository aggregations - **IN PROGRESS** (1 day)
5. ⏳ ProgressCalculationService - **NOT STARTED** (2 days)
6. ⏳ DashboardViewModel - **NOT STARTED** (1-2 days)

### Should Have (Important)
7. ⏳ MetricAggregationService - **NOT STARTED** (2 days)
8. ⏳ AlignmentService - **NOT STARTED** (1-2 days)
9. ⏳ Chart components - **NOT STARTED** (3-4 days)

### Nice to Have (Polish)
10. ⏳ Liquid Glass visual system - **DOCUMENTED** (3-5 days)
11. ⏳ Dashboard caching - **OPTIONAL** (1 day)
12. ⏳ Advanced analytics - **POST-MVP**

---

## Risk Assessment

### High Risk
- **Complex SQL queries** - Mitigated by `SQL_QUERY_PATTERNS.md` reference
- **Performance at scale** - Mitigated by existing indexes, tested to 1M rows

### Medium Risk
- **Chart rendering performance** - Use native SwiftUI Charts (well-optimized)
- **Service layer complexity** - Keep services focused, single responsibility

### Low Risk
- **UI composition** - SwiftUI makes this straightforward
- **ViewModel integration** - Pattern already proven in form views

---

## Next Steps

### Immediate (This Week)
1. Complete `GoalRepository.fetchAllWithProgress()`
2. Add `ActionRepository` aggregation methods
3. Review `SQL_QUERY_PATTERNS.md` Query 1-2 for implementation guidance

### Short Term (Next Week)
4. Build `ProgressCalculationService`
5. Create `DashboardViewModel`
6. Basic dashboard UI (MVP)

### Medium Term (Week 3)
7. Add chart components
8. Implement full dashboard layout
9. Polish and accessibility

---

## References

- **SQL Patterns:** `swift/docs/SQL_QUERY_PATTERNS.md` (Query 1-6)
- **Repository Plan:** `swift/docs/REPOSITORY_IMPLEMENTATION_PLAN.md`
- **Roadmap:** `swift/docs/20251108.md` (Dashboard Requirements, line 376-395)
- **Visual System:** `swift/docs/LIQUID_GLASS_VISUAL_SYSTEM.md`

---

**Last Updated:** 2025-11-10
**Status:** Ready to begin GoalRepository implementation
**Blocking Item:** GoalRepository progress queries
