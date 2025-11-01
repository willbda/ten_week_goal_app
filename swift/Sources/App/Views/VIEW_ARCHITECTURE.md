# View Architecture - Parity Plan
**Written by Claude Code on 2025-10-31**

## Current State Analysis

### What Works (Pre-Rearchitecture)

The app has **4 main sections** with full UI implementation:

1. **Actions** (1178 lines)
   - List view with sorting
   - Create/Edit forms
   - Quick add feature
   - Bulk matching to goals
   - Row display with measurements

2. **Goals** (855 lines)
   - List view with date sorting
   - Create/Edit forms with SMART criteria
   - Progressive disclosure (minimal → SMART)
   - Row display with progress

3. **Terms** (744 lines)
   - List view with term numbers
   - Create/Edit forms
   - Goal assignment in form
   - Row display with dates

4. **Values** (465 lines)
   - List view organized by type
   - Row display with priority

**Total**: ~3,242 lines of view code

---

## The Problem: Architecture Mismatch

### Old Architecture (What Views Expect)
```swift
// Single-model operations
let goal = Goal(
    title: "Run more",
    measurementUnit: "km",      // ❌ Doesn't exist in new model
    measurementTarget: 120.0,   // ❌ Doesn't exist in new model
    startDate: start,
    targetDate: end
)
viewModel.createGoal(goal)  // ❌ Saves one entity only
```

### New Architecture (What Database Needs)
```swift
// Multi-model entity graphs
let expectation = Expectation(title: "Run more", expectationType: .goal)
let goal = Goal(expectationId: expectation.id, startDate: start, targetDate: end)
let measure = ExpectationMeasure(expectationId: expectation.id, metricId: km, targetValue: 120.0)
let relevance = GoalRelevance(goalId: goal.id, valueId: health.id, alignmentStrength: 9)

coordinator.createGoal(expectation, goal, [measure], [relevance])  // ✅ Atomic transaction
```

---

## Parity Roadmap: What Needs to Be Built

### Phase 1: Core Infrastructure (Foundation)
**Goal**: Enable coordinator pattern, validation, basic multi-model CRUD

#### 1.1 Coordinators (New - ~600 lines)
```
Sources/Services/Coordinators/
├── ActionCoordinator.swift       # Assembles Action + MeasuredAction + ActionGoalContribution
├── GoalCoordinator.swift         # Assembles Expectation + Goal + ExpectationMeasure + GoalRelevance
├── TermCoordinator.swift         # Assembles TimePeriod + GoalTerm
└── ValueCoordinator.swift        # Simple - PersonalValue only
```

**Responsibilities**:
- Accept form data structs
- Validate via validators (Layer B)
- Assemble multi-model entity graphs
- Call repositories for atomic persistence

#### 1.2 Validators (New - ~400 lines)
```
Sources/Services/Validation/
├── ValidationError.swift         # User-facing error types
├── EntityValidator.swift         # Protocol
├── ActionValidator.swift         # Action + measurements + contributions
├── GoalValidator.swift           # Expectation + Goal + measures + relevance
└── TermValidator.swift           # TimePeriod + GoalTerm
```

**Responsibilities**:
- Form data validation (before model creation)
- Entity graph validation (after assembly)
- Business rule enforcement

#### 1.3 Repositories (Refactor - ~600 lines)
```
Sources/Services/Repositories/
├── ActionRepository.swift        # Action CRUD with measurements/contributions
├── GoalRepository.swift          # Expectation + Goal CRUD with measures/relevance
├── TermRepository.swift          # TimePeriod + GoalTerm CRUD
├── ValueRepository.swift         # PersonalValue CRUD
└── MeasureRepository.swift       # (Already exists - rename from MetricRepository)
```

**Responsibilities**:
- Transaction management (all-or-nothing writes)
- Query operations (fetch with joins)
- Database error mapping to ValidationError

**Total Phase 1**: ~1,600 lines

---

### Phase 2: ViewModels Refactor (Replace Direct DB Access)
**Goal**: ViewModels call coordinators instead of database

#### 2.1 ActionsViewModel (Refactor - existing 92 lines)
**Changes**:
- Remove direct database writes
- Add coordinator dependency
- Accept `ActionFormData` instead of `Action`
- Fetch related data (goals for matching, measures for display)

```swift
// Before (current)
func createAction(_ action: Action) async {
    try await database.write { db in
        try Action.upsert { action }.execute(db)
    }
}

// After (refactored)
func createAction(_ formData: ActionFormData) async {
    do {
        let action = try await coordinator.createAction(formData: formData)
        // Success - action and measurements saved atomically
    } catch let error as ValidationError {
        self.error = error
    }
}
```

#### 2.2 GoalsViewModel (Refactor - existing 92 lines)
**Changes**:
- Accept `GoalFormData` instead of `Goal`
- Fetch Expectation + Goal + ExpectationMeasure together
- Handle multi-model display in list

```swift
// Before (current)
var goals: [Goal] { goalsQuery.sorted(...) }

// After (refactored)
struct GoalViewModel {
    let expectation: Expectation
    let goal: Goal
    let measures: [ExpectationMeasure]
    let relevances: [GoalRelevance]
}
var goals: [GoalViewModel] { ... }  // Fetch joined data
```

#### 2.3 TermsViewModel (Refactor - existing 132 lines)
**Changes**:
- Accept `TermFormData` instead of `GoalTerm`
- Fetch TimePeriod + GoalTerm together
- Handle goal assignments via junction table

#### 2.4 ValuesViewModel (Minor refactor - existing 202 lines)
**Changes**:
- Minimal - PersonalValue is single entity
- Update to use ValueRepository

**Total Phase 2**: ~520 lines (refactor existing)

---

### Phase 3: Forms Refactor (Multi-Model Input)
**Goal**: Forms collect data for entire entity graphs

#### 3.1 ActionFormView (Refactor - existing 409 lines)
**Breaking Changes**:
- Remove `action.measuresByUnit` → Use separate MeasurementItem picker
- Add goal contribution picker (which goals does this advance?)
- Update save logic to create `ActionFormData`

**New Sections**:
```swift
// Measurements (replaces inline measuresByUnit)
var measurementsSection: some View {
    Section("Measurements") {
        ForEach(measurements) { measurement in
            HStack {
                // Measure picker (from catalog)
                Picker("Unit", selection: $measurement.measureId) { ... }
                TextField("Value", value: $measurement.value, format: .number)
                Button("Remove") { measurements.remove(measurement) }
            }
        }
        Button("Add Measurement") { measurements.append(...) }
    }
}

// Goal Contributions (NEW)
var contributionsSection: some View {
    Section("Contributes To") {
        ForEach(availableGoals) { goal in
            Toggle(goal.title, isOn: binding(for: goal))
        }
    }
}
```

**Output**:
```swift
struct ActionFormData {
    var title: String?
    var description: String?
    var notes: String?
    var durationMinutes: Double?
    var startTime: Date?
    var measurements: [MeasurementInput]        // [(measureId, value)]
    var goalContributions: [ContributionInput]  // [(goalId, amount?)]
}
```

#### 3.2 GoalFormView (Major refactor - existing 386 lines)
**Breaking Changes**:
- Remove inline `measurementUnit`, `measurementTarget` fields
- Remove `howGoalIsRelevant`, `howGoalIsActionable` (old model)
- Add Expectation fields (importance, urgency - Eisenhower matrix)
- Add ExpectationMeasure repeating section (0 to many metrics)
- Add GoalRelevance section (value alignments)

**New Structure**:
```swift
// Tab 1: Core (Expectation + Goal)
var coreSection: some View {
    Section("What") {
        TextField("Title", text: $title)
        TextField("Description", text: $description)
        Picker("Importance", selection: $importance) { ... }  // 1-10
        Picker("Urgency", selection: $urgency) { ... }        // 1-10
    }

    Section("When") {
        DatePicker("Start Date", selection: $startDate)
        DatePicker("Target Date", selection: $targetDate)
        TextField("Action Plan", text: $actionPlan)
    }
}

// Tab 2: Measurements (ExpectationMeasure)
var measurementsSection: some View {
    Section("Targets") {
        ForEach(targets) { target in
            HStack {
                Picker("Metric", selection: $target.measureId) { ... }
                TextField("Target", value: $target.targetValue, format: .number)
                Button("Remove") { targets.remove(target) }
            }
        }
        Button("Add Target") { targets.append(...) }
    }
    .footer("Example: 120 km, 30 occasions, 20 hours")
}

// Tab 3: Values (GoalRelevance)
var valuesSection: some View {
    Section("Aligned Values") {
        ForEach(availableValues) { value in
            Toggle(value.title, isOn: binding(for: value))
            if selectedValues.contains(value) {
                Slider("Alignment Strength", value: $strength, in: 1...10)
            }
        }
    }
}
```

**Output**:
```swift
struct GoalFormData {
    // Expectation fields
    var title: String
    var description: String?
    var importance: Int       // 1-10
    var urgency: Int         // 1-10

    // Goal fields
    var startDate: Date
    var targetDate: Date
    var actionPlan: String?

    // ExpectationMeasure fields
    var targets: [MeasureTarget]  // [(measureId, targetValue)]

    // GoalRelevance fields
    var valueAlignments: [ValueAlignment]  // [(valueId, strength)]
}
```

#### 3.3 TermFormView (Refactor - existing 424 lines)
**Changes**:
- Add TimePeriod fields (title, startDate, endDate)
- Keep GoalTerm fields (termNumber, theme, reflection, status)
- Goal assignment via picker

**Output**:
```swift
struct TermFormData {
    // TimePeriod fields
    var periodTitle: String
    var periodStart: Date
    var periodEnd: Date

    // GoalTerm fields
    var termNumber: Int
    var theme: String?
    var reflection: String?
    var status: TermStatus

    // Junction table
    var goalIds: [UUID]
}
```

#### 3.4 ValueFormView (NEW - ~200 lines)
**Missing**: Values currently have no form - only list view!

```swift
struct ValueFormView: View {
    var body: some View {
        Form {
            Section("Identity") {
                TextField("Title", text: $title)
                TextField("Description", text: $description)
                Picker("Level", selection: $valueLevel) {
                    Text("General").tag(ValueLevel.general)
                    Text("Major").tag(ValueLevel.major)
                    Text("Highest Order").tag(ValueLevel.highestOrder)
                    Text("Life Area").tag(ValueLevel.lifeArea)
                }
            }

            Section("Organization") {
                TextField("Life Domain", text: $lifeDomain)
                TextField("Alignment Guidance", text: $alignmentGuidance)
                Stepper("Priority: \(priority)", value: $priority, in: 1...100)
            }
        }
    }
}
```

**Total Phase 3**: ~1,400 lines (refactor + new form)

---

### Phase 4: List Views Refactor (Display Multi-Model Data)
**Goal**: Show joined data from entity graphs

#### 4.1 ActionsListView (Minor refactor - existing 258 lines)
**Changes**:
- Display measurements from MeasuredAction
- Display goal contributions
- Show which goals this action advances

```swift
// Row display (enhanced)
ActionRowView(
    action: action,
    measurements: measurements[action.id] ?? [],
    contributions: contributions[action.id] ?? []
)
```

#### 4.2 GoalsListView (Moderate refactor - existing 276 lines)
**Changes**:
- Display Expectation title instead of Goal title
- Show ExpectationMeasures as targets
- Show progress (if measurements exist)
- Filter by term (show goals for current term)

```swift
// Row display (enhanced)
GoalRowView(
    expectation: expectation,
    goal: goal,
    measures: measures,
    progress: calculateProgress(goal, measures)
)
```

#### 4.3 TermsListView (Minor refactor - existing 134 lines)
**Changes**:
- Display TimePeriod dates
- Show assigned goals count

#### 4.4 ValuesListView (Minimal changes - existing 114 lines)
**Changes**:
- Group by valueLevel
- Show priority

**Total Phase 4**: ~782 lines (refactor existing)

---

### Phase 5: Row Views Refactor (Rich Display)
**Goal**: Display related data in rows

#### 5.1 ActionRowView (Refactor - existing 111 lines)
**Add**:
- Measurement chips (e.g., "5.2 km", "28 min")
- Goal contribution badges

#### 5.2 GoalRowView (Refactor - existing 97 lines)
**Add**:
- Target metrics display
- Progress bars (if measurable)
- Value alignment tags

#### 5.3 TermRowView (Minor changes - existing 178 lines)
**Add**:
- Goal count badge
- Status indicator

#### 5.4 ValueRowView (Minimal changes - existing 149 lines)
**Add**:
- Level badge
- Priority indicator

**Total Phase 5**: ~535 lines (refactor existing)

---

### Phase 6: Feature Parity (Advanced Features)
**Goal**: Restore advanced features from old architecture

#### 6.1 QuickAddSectionView (Refactor - existing 282 lines)
**Changes**:
- Update to use new Action model
- Support adding measurements inline

#### 6.2 BulkMatchingView (Refactor - existing 250 lines)
**Changes**:
- Create ActionGoalContribution records
- Support setting contribution amounts

#### 6.3 ListViewBuilder (Minimal changes - existing 264 lines)
**Changes**:
- Generic over ViewModel types

**Total Phase 6**: ~796 lines (refactor existing)

---

## Implementation Priority

### Sprint 1: Minimal Viable (Get something working)
**Goal**: Basic CRUD for one entity (Actions)

1. ✅ ActionCoordinator (150 lines)
2. ✅ ActionValidator (100 lines)
3. ✅ ActionRepository (150 lines)
4. ✅ ActionFormData struct (50 lines)
5. ✅ Refactor ActionFormView to use formData (100 lines)
6. ✅ Refactor ActionsViewModel to use coordinator (50 lines)

**Output**: Can create Action + MeasuredAction atomically
**Lines**: ~600

---

### Sprint 2: Complete Actions + Start Goals
**Goal**: Full Action feature + Basic Goal CRUD

7. ✅ ActionRowView refactor (measurements display)
8. ✅ GoalCoordinator (200 lines)
9. ✅ GoalValidator (150 lines)
10. ✅ GoalRepository (200 lines)
11. ✅ GoalFormData struct (50 lines)

**Output**: Full Actions feature + skeleton Goal feature
**Lines**: ~700

---

### Sprint 3: Complete Goals
**Goal**: Full Goal feature parity

12. ✅ Refactor GoalFormView (major - Expectation + Goal + Measures + Relevance)
13. ✅ Refactor GoalsViewModel (fetch joined data)
14. ✅ Refactor GoalRowView (rich display)

**Output**: Full Goals feature with measurements and value alignment
**Lines**: ~600

---

### Sprint 4: Terms + Values
**Goal**: Complete all basic CRUD

15. ✅ TermCoordinator + Validator + Repository
16. ✅ Refactor TermFormView + ViewModel
17. ✅ ValueCoordinator + Repository (simple)
18. ✅ Create ValueFormView (NEW)
19. ✅ Refactor ValuesViewModel

**Output**: Full CRUD for all 4 entities
**Lines**: ~800

---

### Sprint 5: Advanced Features
**Goal**: Restore BulkMatching, QuickAdd, etc.

20. ✅ Refactor QuickAddSectionView
21. ✅ Refactor BulkMatchingView
22. ✅ Add progress tracking (goal progress calculations)

**Output**: Feature parity with old architecture
**Lines**: ~500

---

## Total Effort Estimate

| Phase | Description | Lines | Status |
|-------|-------------|-------|--------|
| Phase 1 | Core Infrastructure | ~1,600 | 🔴 Not started |
| Phase 2 | ViewModels Refactor | ~520 | 🔴 Not started |
| Phase 3 | Forms Refactor | ~1,400 | 🔴 Not started |
| Phase 4 | List Views Refactor | ~782 | 🔴 Not started |
| Phase 5 | Row Views Refactor | ~535 | 🔴 Not started |
| Phase 6 | Advanced Features | ~796 | 🔴 Not started |
| **TOTAL** | **Full Parity** | **~5,633 lines** | **0% complete** |

**Current Codebase**: 3,242 lines (old architecture)
**New Codebase**: ~5,633 lines (new architecture)
**Growth**: +74% (due to proper separation of concerns)

---

## What Works Today (Before Refactor)

✅ Navigation and layout
✅ List views render
✅ Forms open
✅ Basic CRUD (single entities only)
✅ Design system and materials

## What's Broken Today

❌ Forms try to save old model structure
❌ Can't create measurements (no junction tables)
❌ Can't create goal-action links (no junction tables)
❌ Can't see related data (no joins)
❌ No validation (data can be incomplete)
❌ GoalValidation.swift uses wrong classification model

---

## Decision Points

### Q1: Do we keep existing UI exactly?
**Option A**: Preserve existing layout/behavior exactly (more work)
**Option B**: Simplify forms as we refactor (less work, better UX)

**Recommendation**: Option B - use refactor as opportunity to improve

### Q2: Progressive or big bang?
**Option A**: Build complete new view layer, swap in when done
**Option B**: Refactor one section at a time (Actions → Goals → Terms → Values)

**Recommendation**: Option B - deliver value incrementally

### Q3: Keep disabled Assistant views?
**Option A**: Delete them (clean slate)
**Option B**: Keep for future re-implementation

**Recommendation**: Option A - delete, re-implement later if needed

---

## Next Steps

1. **Validate this plan** - Does this match your vision?
2. **Choose starting point** - Actions or Goals first?
3. **Set sprint goal** - Which sprint (1-5) for first milestone?
4. **Begin implementation** - Start with coordinators

---

## Open Questions

1. Should GoalFormView be tabbed (Core/Measurements/Values) or single scrolling form?
2. Do we keep QuickAdd as separate feature or integrate into main form?
3. Should BulkMatching be a sheet or dedicated view?
4. Do we want AI Assistant (ConversationHistory) re-enabled in this iteration?
