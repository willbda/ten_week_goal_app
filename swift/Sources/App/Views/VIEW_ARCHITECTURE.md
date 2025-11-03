# View Architecture - Parity Plan
**Written by Claude Code on 2025-10-31**
**Updated**: 2025-11-02 (PersonalValue + Term Complete with Full CRUD)

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

### Phase 1: Core Infrastructure (Foundation) ⚠️ IN PROGRESS
**Goal**: Enable coordinator pattern, validation, basic multi-model CRUD

#### 1.1 Coordinators (~600 lines) - ✅ 2/4 COMPLETE (PersonalValue + Term)

**Status Update (2025-11-02)**:
- ✅ **PersonalValueCoordinator** - Complete (create only, needs update/delete for parity)
- ✅ **TimePeriodCoordinator** - Complete with FULL CRUD (97 lines, 10 hours actual)
- ✅ **CoordinatorError** - Complete
- ✅ **ValueFormData** - Complete
- ✅ **TimePeriodFormData** - Complete
- ❌ **ActionCoordinator** - Not started (~200 lines, 4 hours)
- ❌ **GoalCoordinator** - Not started (~250 lines, 6 hours)

**Key Learnings from PersonalValue Implementation**:

1. **No Validation in Coordinators** (Decision Log Entry #1)
   - Coordinators trust caller (ViewModel)
   - Validation happens in ViewModels or Validators (Phase 2)
   - Database enforces schema constraints as final safety net
   - Result: Cleaner coordinators (~40 lines vs ~100 lines)

2. **@Observable Instead of ObservableObject** (Decision Log Entry #2)
   - Use `@Observable` macro (Swift 5.9+), not `ObservableObject`
   - No `@Published` needed - all properties auto-tracked
   - Use `@ObservationIgnored` with `@Dependency(\.defaultDatabase)`
   - Pattern from SQLiteData's ObservableModelDemo example

3. **@Dependency Works Well** (Decision Log Entry #3)
   - Using `@Dependency(\.defaultDatabase)` from DatabaseBootstrap
   - No need to switch to `@Environment` (SQLiteData's pattern)
   - ViewModels use computed property for coordinators (no lazy with @Observable)

4. **Force Unwrap is Safe After Insert** (Decision Log Entry #4)
   - `fetchOne(db)!` is safe after successful insert
   - Insert either throws or returns value (never returns nil)
   - No need for guard let after database.write { insert... }

**Updated Coordinator Pattern (Based on PersonalValue)**:
```swift
import Foundation
import SQLiteData

/// Coordinates creation of [Entity] with atomic persistence.
///
/// Validation Strategy:
/// - NO validation in coordinator (trusts caller)
/// - Database enforces: NOT NULL, foreign keys, CHECK constraints
/// - Business rules enforced by Validators (Phase 2)
@MainActor
public final class [Entity]Coordinator: ObservableObject {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    /// Creates [entity] from form data.
    /// - Parameter formData: Validated form data (validation is caller's responsibility)
    /// - Returns: Persisted [Entity] with generated ID
    /// - Throws: Database errors if constraints violated
    public func create(from formData: [Entity]FormData) async throws -> [Entity] {
        return try await database.write { db in
            try [Entity].insert {
                [Entity].Draft(
                    id: UUID(),
                    // ... map form data fields
                )
            }
            .returning()
            .fetchOne(db)!  // Safe: successful insert always returns value
        }
    }
}
```

**Revised Implementation Order**:

1. ✅ **PersonalValueCoordinator** (~42 lines, 2 hours) - COMPLETE
   - Simplest: Single model, no relationships
   - Establishes modern @Observable pattern
   - Proves database.write atomicity

2. ❌ **TermCoordinator** (~150 lines, 3 hours) - NEXT
   - Two models: TimePeriod + GoalTerm (1:1)
   - Simple foreign key relationship
   - Tests transaction rollback

3. ❌ **ActionCoordinator** (~200 lines, 4 hours)
   - Multiple relationships: Action + MeasuredAction[] + ActionGoalContribution[]
   - Many-to-many patterns
   - Validates relationship existence before insert

4. ❌ **GoalCoordinator** (~250 lines, 6 hours)
   - Most complex: Expectation + Goal + ExpectationMeasure[] + GoalRelevance[] + TermGoalAssignment?
   - 5+ models atomically
   - Full complexity test

**Decision #5: Ontological Purity in Data Layer (2025-11-02)**
**Context**: TimePeriod architecture design
**Decision**: Data layer (Coordinator/ViewModel) works with abstractions (TimePeriod), View layer provides user-friendly specializations (Terms, Years)
**Rationale**:
- Coordinator: `TimePeriodCoordinator` creates TimePeriod + GoalTerm/Year atomically
- ViewModel: `TimePeriodFormViewModel` accepts `TimePeriodSpecialization` enum
- Views: `TermFormView` wraps generic ViewModel with pre-configured `.term(number)`
- Navigation: Tab says "Terms" not "Time Periods" (user-friendly)
**Result**: Clean separation - ontological purity in data, user clarity in UI
**Pattern**: `TimePeriodSpecialization` enum with cases `.term(number)`, `.year(yearNumber)`, `.custom`

**Decision #6: Type-Specific Views + Generic ViewModel (2025-11-02)**
**Context**: How to handle TimePeriod specializations in UI
**Decision**: Generic ViewModel (`TimePeriodFormViewModel`), type-specific wrapper views (`TermFormView`, future `YearFormView`)
**Rationale**:
- ViewModel stays generic, reusable for all TimePeriod types
- Views provide user-friendly interface (no "select type" picker in v1.0)
- Easy to add new types (YearFormView) without changing ViewModel
- Users never see "Time Period" terminology in v1.0
**Result**: `TermFormView` pre-configures `specialization: .term(number)` when calling generic ViewModel

---

### Key Learnings from Term Implementation (2025-11-02)

**Term proves the multi-model coordinator pattern at scale:**

1. **Multi-Model Atomic Transactions** (2 models)
   ```swift
   return try await database.write { db in
       // 1. Insert abstraction
       let timePeriod = try TimePeriod.upsert { ... }.returning { $0 }.fetchOne(db)!

       // 2. Insert specialization with FK
       try GoalTerm.upsert {
           GoalTerm.Draft(
               timePeriodId: timePeriod.id,  // FK to abstraction
               termNumber: number,
               status: .planned
           )
       }.execute(db)

       // 3. Return abstraction (caller accesses specialization via relationship)
       return timePeriod
   }
   ```
   - **Result**: Clean 1:1 relationship handling
   - **Applies to**: Goal (Expectation + Goal), Action (Action + Measurements)

2. **Full CRUD Lifecycle** (Decision Log Entry #9)
   - `create()` - Insert TimePeriod + GoalTerm atomically
   - `update()` - Update both entities, preserve IDs and logTime
   - `delete()` - Delete specialization first (FK dependency), then abstraction
   - **Pattern**: All future coordinators must implement full CRUD for parity

3. **FetchKeyRequest for Performant JOINs** (Decision Log Entry #7)
   ```swift
   public struct TermsWithPeriods: FetchKeyRequest {
       public func fetch(_ db: Database) throws -> [TermWithPeriod] {
           let results = try GoalTerm.all
               .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
               .fetchAll(db)
           return results.map { (term, timePeriod) in
               TermWithPeriod(term: term, timePeriod: timePeriod)
           }
       }
   }
   ```
   - Single JOIN query (no N+1)
   - Wrapper type (TermWithPeriod) for combined data
   - @Fetch auto-updates on database changes
   - Result: Performant, reactive list views

6. **Wrapper Types for Multi-Model Display** (Decision Log Entry #8)
   ```swift
   public struct TermWithPeriod: Identifiable, Sendable {
       public let term: GoalTerm
       public let timePeriod: TimePeriod
       public var id: UUID { term.id }
   }
   ```
   - Combines related models for display
   - Identifiable for List compatibility
   - Sendable for concurrency safety

5. **Edit Mode Pattern in Forms**
   ```swift
   public struct TermFormView: View {
       let termToEdit: (TimePeriod, GoalTerm)?  // Optional for edit mode

       var isEditMode: Bool { termToEdit != nil }
       var formTitle: String { isEditMode ? "Edit Term" : "New Term" }

       init(termToEdit: (TimePeriod, GoalTerm)? = nil) {
           if let (timePeriod, goalTerm) = termToEdit {
               // Initialize @State from existing data
               _termNumber = State(initialValue: goalTerm.termNumber)
               _startDate = State(initialValue: timePeriod.startDate)
               // ...
           } else {
               // Initialize with defaults
               _termNumber = State(initialValue: 1)
               _startDate = State(initialValue: Date())
               // ...
           }
       }
   }
   ```
   - Single form for create + edit
   - State initialization in init()
   - Conditional sections (reflection only shows in edit mode)

6. **List View Interactions Pattern**
   ```swift
   List {
       ForEach(items) { item in
           RowView(item)
               .onTapGesture { edit(item) }         // Tap → edit
               .swipeActions(edge: .trailing) {      // Right swipe → delete
                   Button(role: .destructive) { delete(item) }
               }
               .swipeActions(edge: .leading) {       // Left swipe → edit
                   Button { edit(item) }
                       .tint(.blue)
               }
       }
   }
   ```
   - Tap row to edit
   - Swipe right for delete (destructive)
   - Swipe left for edit (blue)
   - Empty state with helpful CTA

**Decision: Keep All Coordinators for Consistency**
- Even simple entities use coordinators (PersonalValue)
- Consistent pattern easier to understand than hybrid approach
- Can refactor to static methods later if feels overkill
- See ARCHITECTURE_EVALUATION_20251102.md for full analysis

---

#### 1.2 ViewModels (~400 lines) - ✅ 2/4 COMPLETE (PersonalValue + Term)

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesFormViewModel** - Complete (save only, needs update/delete)
- ✅ **TimePeriodFormViewModel** - Complete with save/update/delete (79 lines)
- ❌ **ActionFormViewModel** - Not started
- ❌ **GoalFormViewModel** - Not started

**Key Learnings from PersonalValue Implementation**:

1. **@Observable Pattern** (Modern Swift 5.9+)
   ```swift
   @Observable  // Not ObservableObject!
   @MainActor
   public final class PersonalValuesFormViewModel {
       var isSaving: Bool = false      // No @Published needed
       var errorMessage: String?

       @ObservationIgnored
       @Dependency(\.defaultDatabase) var database

       private var coordinator: PersonalValueCoordinator {
           PersonalValueCoordinator(database: database)
       }
   }
   ```

2. **View Uses @State, Not @StateObject**
   ```swift
   @State private var viewModel = PersonalValuesFormViewModel()  // Not @StateObject!
   ```

3. **Individual Parameters vs FormData Object**
   - ViewModels accept individual parameters (ergonomic for SwiftUI)
   - Assemble FormData internally before calling coordinator
   - Clear what's required vs optional

**Pattern for Remaining ViewModels**:
```swift
@Observable
@MainActor
public final class [Entity]FormViewModel {
    var isSaving: Bool = false
    var errorMessage: String?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    private var coordinator: [Entity]Coordinator {
        [Entity]Coordinator(database: database)
    }

    public init() {}

    public func save(/* individual params */) async throws -> [Entity] {
        isSaving = true
        defer { isSaving = false }

        let formData = [Entity]FormData(/* assemble */)

        do {
            let entity = try await coordinator.create(from: formData)
            errorMessage = nil
            return entity
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
```

---

#### 1.3 Form Views (~800 lines) - ✅ 2/4 COMPLETE (PersonalValue + Term)

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesFormView** - Complete (create only, needs edit mode)
- ✅ **TermFormView** - Complete with create + edit modes (184 lines)
- ❌ **ActionFormView** - Exists but needs ViewModel integration
- ❌ **GoalFormView** - Needs major refactor (multi-model)

**Key Learnings from PersonalValue Implementation**:

1. **FormScaffold Template Works Great**
   ```swift
   FormScaffold(
       title: "New Value",
       canSubmit: !title.isEmpty && !viewModel.isSaving,
       onSubmit: handleSubmit,
       onCancel: { dismiss() }
   ) {
       DocumentableFields(title: $title, detailedDescription: $description, freeformNotes: $notes)
       // ... sections
   }
   ```

2. **@State for ViewModel**
   ```swift
   @State private var viewModel = PersonalValuesFormViewModel()  // Not @StateObject
   ```

3. **Error Display in Form**
   ```swift
   if let error = viewModel.errorMessage {
       Section {
           Text(error)
               .foregroundStyle(.red)
       }
   }
   ```

4. **Async Save in Task**
   ```swift
   private func handleSubmit() {
       Task {
           do {
               _ = try await viewModel.save(/* params */)
               dismiss()
           } catch {
               // Error already set in viewModel.errorMessage
           }
       }
   }
   ```

---

#### 1.4 List Views (~400 lines) - ✅ 2/4 COMPLETE (PersonalValue + Term)

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesListView** - Complete (basic, needs tap/swipe)
- ✅ **TermsListView** - Complete with JOIN query, tap/swipe, empty state (101 lines)
- ❌ **ActionsListView** - Exists but needs refactor for measurements
- ❌ **GoalsListView** - Exists but needs refactor for multi-model

**Key Learnings from PersonalValue Implementation**:

1. **@FetchAll for Simple Lists (No ViewModel Needed)**
   ```swift
   @FetchAll(PersonalValue.all) private var values
   ```
   - Reactive: Updates automatically when database changes
   - No ViewModel boilerplate for simple lists
   - Memory efficient: SQLiteData handles pagination

2. **When to Use ViewModel for Lists**
   - Complex filtering/sorting logic
   - Multi-source data aggregation
   - Business logic coordination
   - Actions list will need ViewModel (measurement display)

3. **Navigation + Sheet Pattern**
   ```swift
   .toolbar {
       ToolbarItem(placement: .primaryAction) {
           Button {
               showingAddValue = true
           } label: {
               Label("Add Value", systemImage: "plus")
           }
       }
   }
   .sheet(isPresented: $showingAddValue) {
       NavigationStack {
           PersonalValuesFormView()
       }
   }
   ```

---

#### 1.5 Row Views (~200 lines) - ✅ 2 COMPLETE, 2 REMAINING

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesRowView** - Complete with BadgeView template
- ✅ **TermRowView** - Complete with multi-model display (term + timePeriod) (NEW)
- ❌ **ActionRowView** - Needs measurement display
- ❌ **GoalRowView** - Needs multi-metric display

**Key Learnings from PersonalValue Implementation**:

1. **Use Template Components**
   ```swift
   BadgeView(badge: Badge(text: "\(priority)", color: .secondary))
   BadgeView(badge: Badge(text: domain, color: .purple.opacity(0.8)))
   ```

2. **Simple, Focused Components**
   - Just display data, no business logic
   - Pass model directly, not ViewModel
   - Template-based styling for consistency

---

### Phase 1 Progress Summary

| Component | PersonalValue | Term | Action | Goal | Total Lines |
|-----------|---------------|------|--------|------|-------------|
| **Coordinator** | ✅ Create only | ✅ Full CRUD | ❌ | ❌ | ~600 |
| **ViewModel** | ✅ Save only | ✅ Save/Update/Delete | ❌ | ❌ | ~400 |
| **FormView** | ✅ Create only | ✅ Create + Edit | ❌ | ❌ | ~800 |
| **ListView** | ✅ Basic | ✅ + Tap/Swipe/Empty | ❌ | ❌ | ~400 |
| **RowView** | ✅ Basic | ✅ Multi-model | ❌ | ❌ | ~200 |
| **Query Helper** | N/A | ✅ JOIN FetchKeyRequest | ❌ | ❌ | ~200 |

**Lines Written**: ~1,100 lines ✅
**Lines Remaining**: ~1,600 lines ❌
**Phase 1 Status**: 50% Complete (2/4 entities)

**CRUD Parity Status**:
- **PersonalValue**: Create ✅ | Update ❌ | Delete ❌ | **Partial** (needs update/delete for parity)
- **Term**: Create ✅ | Update ✅ | Delete ✅ | **FULL PARITY** ⭐
- **Action**: Not started
- **Goal**: Not started

**Note**: Term achieves full parity with old app (create/edit/delete/list/empty state). PersonalValue needs update() and delete() added for full parity.

---

## Next Immediate Steps

### ✅ Completed
1. ~~**PersonalValueCoordinator + Vertical Slice**~~ ✅ COMPLETE (create only, ~6 hours)
2. ~~**TermCoordinator + Full Vertical Slice**~~ ✅ COMPLETE (full CRUD, ~10 hours)

### 🎯 Current Priority

**Option A: Complete PersonalValue CRUD** (2-3 hours)
- Add `update()` to PersonalValueCoordinator
- Add `delete()` to PersonalValueCoordinator
- Add `update()` and `delete()` to PersonalValuesFormViewModel
- Add tap/swipe to PersonalValuesListView
- Add edit mode to PersonalValuesFormView
- **Benefit**: Achieves full parity for Values (consistency with Term)
- **Drawback**: Delays Action/Goal progress

**Option B: Start ActionCoordinator** (12-15 hours)
- More complex: 3 models (Action + MeasuredAction[] + ActionGoalContribution[])
- Many-to-many relationships
- Relationship validation needed
- **Benefit**: Makes progress on complex entities
- **Drawback**: PersonalValue stays incomplete

**Recommendation**: Option A (complete PersonalValue) for consistency, THEN ActionCoordinator

### Recommended Order (Remaining Work)

1. **PersonalValue CRUD Completion** (~3 hours) - RECOMMENDED NEXT
   - Add update()/delete() to Coordinator
   - Add update()/delete() to ViewModel
   - Add tap/swipe to ListView
   - Add edit mode to FormView
   - **Result**: 2/4 entities with full parity

2. **ActionCoordinator + Full Vertical Slice** (~15 hours)
   - ActionCoordinator (3 models: Action + MeasuredAction[] + ActionGoalContribution[])
   - ActionFormViewModel (with update/delete)
   - Update ActionFormView (metric selection, goal contribution)
   - Update ActionsListView (measurement display, JOIN query)
   - Create ActionsQuery.swift (FetchKeyRequest pattern)
   - Update ActionRowView (display measurements)
   - **Result**: Action CRUD with measurements and goal tracking

3. **GoalCoordinator + Full Vertical Slice** (~20 hours)
   - GoalCoordinator (5 models: Expectation + Goal + ExpectationMeasure[] + GoalRelevance[] + TermGoalAssignment?)
   - GoalFormViewModel (with update/delete)
   - Major refactor GoalFormView (multi-metric targets, value alignments, term assignment)
   - Update GoalsListView (multi-model display, progress calculation)
   - Create GoalsQuery.swift (complex JOIN for Goal + Expectation + Measures + Relevances)
   - Update GoalRowView (multi-metric progress display)
   - **Result**: Goal CRUD with full SMART criteria and progress tracking

**Total Remaining Phase 1**: ~38 hours (~5 working days)

---

## Architecture Decisions Log

### Decision #1: No Validation in Coordinators (2025-11-02)
**Context**: PersonalValueCoordinator implementation
**Decision**: Coordinators trust callers; validation is ViewModel/Validator responsibility
**Rationale**:
- Cleaner separation of concerns
- Database enforces schema constraints as safety net
- Validators in Phase 2 will handle business rules
**Result**: Coordinators ~40 lines instead of ~100 lines

### Decision #2: Use @Observable, Not ObservableObject (2025-11-02)
**Context**: PersonalValuesFormViewModel implementation
**Decision**: Modern @Observable macro for ViewModels
**Rationale**:
- Swift 5.9+ pattern (not legacy Combine)
- No @Published boilerplate
- Better performance (fine-grained observation)
- Aligns with Apple's current guidance
**Result**: Cleaner ViewModel code, use @State in views (not @StateObject)

### Decision #3: Keep @Dependency (2025-11-02)
**Context**: Database injection strategy
**Decision**: Continue using @Dependency(\.defaultDatabase), not @Environment
**Rationale**:
- SQLiteData's established pattern (from ObservableModelDemo)
- Works well with @Observable + @ObservationIgnored
- No need to migrate to custom @Environment
**Result**: Consistent with SQLiteData examples

### Decision #4: Keep All Coordinators (2025-11-02)
**Context**: Architecture evaluation questioned coordinator necessity for simple entities
**Decision**: Use coordinators for all entities, even simple ones like PersonalValue
**Rationale**:
- Consistency easier than hybrid approach
- Can refactor later if feels overkill
- Pattern established, easy to replicate
- Complex entities (Goal) definitely need coordinators
**Result**: Clear pattern: Always use coordinator for persistence

### Decision #5: Ontological Purity in Data Layer (2025-11-02)
**Context**: TimePeriod/Term implementation - how to handle abstractions vs specializations
**Decision**: Coordinators work with abstractions (TimePeriod), not specializations (Term)
**Rationale**:
- TimePeriod is ontologically correct abstraction
- Specializations (Term, Year, Quarter) via enum pattern
- Views handle user-friendly naming ("Terms" not "Time Periods")
- Future-extensible without refactoring data layer
**Result**:
- TimePeriodCoordinator with specialization enum
- TermFormView wraps generic ViewModel with `.term(number)`
- Can add YearFormView later without coordinator changes

### Decision #6: Generic ViewModels + Type-Specific Views (2025-11-02)
**Context**: How to handle multiple specializations of same abstraction
**Decision**: Generic ViewModel, type-specific wrapper views
**Rationale**:
- TimePeriodFormViewModel works with ANY specialization
- TermFormView/YearFormView pre-configure specialization
- User never sees generic terminology in UI
- Avoids duplicating ViewModel logic per type
**Result**:
- TimePeriodFormViewModel (generic, 79 lines)
- TermFormView (specific, 184 lines, wraps generic)
- Easy to add YearFormView by wrapping same ViewModel

### Decision #7: FetchKeyRequest for JOIN Queries (2025-11-02)
**Context**: How to efficiently fetch related data for list views
**Decision**: Custom FetchKeyRequest types for multi-model queries
**Rationale**:
- Single JOIN query vs N+1 fetches (performant)
- Encapsulates query logic (reusable)
- Works with @Fetch for reactive updates
- Pattern from SQLiteData Reminders example
**Result**:
- TermsQuery.swift with TermsWithPeriods FetchKeyRequest
- TermWithPeriod wrapper type for combined data
- TermsListView uses @Fetch(TermsWithPeriods())
- Pattern to replicate for Actions/Goals

### Decision #8: Wrapper Types for Multi-Model Display (2025-11-02)
**Context**: How to pass related data to row views efficiently
**Decision**: Create Identifiable wrapper types combining multiple models
**Rationale**:
- Parent fetches efficiently via JOIN
- Child (row view) receives both models directly
- No database access in display components
- Type-safe, clear API
**Result**:
- TermWithPeriod struct wrapping GoalTerm + TimePeriod
- TermRowView(term: term, timePeriod: timePeriod)
- No relationship traversal or N+1 queries in row

### Decision #9: Full CRUD in Coordinators (2025-11-02)
**Context**: Initial implementation only had create(), missing update() and delete()
**Decision**: All coordinators must implement full CRUD (create/update/delete)
**Rationale**:
- Matches old app parity requirement
- Users need to edit and delete entities, not just create
- Atomic updates critical for multi-model entities
- Delete needs proper FK cascade handling
**Result**:
- TimePeriodCoordinator: create() + update() + delete()
- PersonalValueCoordinator: Only create() so far (TODO: add update/delete)
- Pattern: update() preserves IDs and logTime, delete() handles FK dependencies

---

## Testing Status

**Automated Tests**: ❌ None written yet
- PersonalValue: Need coordinator + ViewModel tests
- Term: Need coordinator + ViewModel + FetchKeyRequest tests
- Pattern will apply to Action/Goal

**Manual Testing Completed**:

**PersonalValue** ✅ Partial
- ✅ Create works via form
- ✅ List displays with badges
- ❌ Edit not implemented
- ❌ Delete not implemented

**Term** ✅ Full
- ✅ Create term via form
- ✅ Edit term via tap or swipe-left
- ✅ Delete term via swipe-right
- ✅ Empty state shows when no terms
- ✅ Form populates correctly in edit mode
- ✅ Theme/reflection/status fields work
- ✅ List updates reactively on changes
- ✅ Multi-model display (term number + dates + title)

---

## File Structure (Phase 1 Complete)

### Completed (PersonalValue + Term):
```
swift/Sources/
├── Services/Coordinators/
│   ├── PersonalValueCoordinator.swift       ✅ Create only (TODO: add update/delete)
│   ├── TimePeriodCoordinator.swift          ✅ Full CRUD (create/update/delete)
│   ├── CoordinatorError.swift               ✅
│   └── FormData/
│       ├── ValueFormData.swift              ✅
│       └── TimePeriodFormData.swift         ✅
├── App/ViewModels/FormViewModels/
│   ├── PersonalValuesFormViewModel.swift    ✅ Save only (TODO: add update/delete)
│   └── TimePeriodFormViewModel.swift        ✅ Save/Update/Delete
├── App/Views/
│   ├── PersonalValues/
│   │   ├── PersonalValuesFormView.swift     ✅ Create only (TODO: add edit mode)
│   │   ├── PersonalValuesListView.swift     ✅ Basic (TODO: add tap/swipe)
│   │   └── PersonalValuesRowView.swift      ✅
│   └── TimePeriods/
│       ├── TermFormView.swift               ✅ Create + Edit modes
│       ├── TermsListView.swift              ✅ Tap/Swipe/Empty state
│       ├── TermRowView.swift                ✅ Multi-model display
│       └── TermsQuery.swift                 ✅ FetchKeyRequest JOIN pattern
```

### Remaining (Action + Goal):
```
swift/Sources/
├── Services/Coordinators/
│   ├── ActionCoordinator.swift              ❌ TODO (~200 lines)
│   ├── GoalCoordinator.swift                ❌ TODO (~250 lines)
│   └── FormData/
│       ├── ActionFormData.swift             ✅ EXISTS (needs review)
│       └── GoalFormData.swift               ❌ TODO
├── App/ViewModels/FormViewModels/
│   ├── ActionFormViewModel.swift            ❌ TODO
│   └── GoalFormViewModel.swift              ❌ TODO
├── App/Views/
│   ├── Actions/
│   │   ├── ActionFormView.swift             🚧 EXISTS (needs ViewModel integration)
│   │   ├── ActionsListView.swift            🚧 EXISTS (needs measurement display)
│   │   ├── ActionRowView.swift              🚧 EXISTS (needs measurement display)
│   │   └── ActionsQuery.swift               ❌ TODO (JOIN Action+Measures)
│   └── Goals/
│       ├── GoalFormView.swift               🚧 EXISTS (needs major refactor)
│       ├── GoalsListView.swift              🚧 EXISTS (needs multi-model)
│       ├── GoalRowView.swift                🚧 EXISTS (needs metrics display)
│       └── GoalsQuery.swift                 ❌ TODO (JOIN Goal+Expectation+Measures)
```

---

## References

**Reference Implementations** (Use these as templates):
- **TimePeriodCoordinator.swift** ⭐ - Multi-model coordinator with FULL CRUD (create/update/delete)
- **TermsQuery.swift** ⭐ - FetchKeyRequest JOIN pattern for performant multi-model queries
- **TimePeriodFormViewModel.swift** ⭐ - Generic ViewModel with save/update/delete operations
- **TermFormView.swift** ⭐ - Edit mode support, state initialization pattern
- **TermsListView.swift** ⭐ - Tap/swipe interactions, empty state, @Fetch usage

**Earlier Implementations** (Simpler patterns):
- **PersonalValueCoordinator.swift** - Single-model coordinator (create only - needs update/delete)
- **PersonalValuesFormViewModel.swift** - @Observable pattern basics (save only - needs update/delete)
- **PersonalValuesFormView.swift** - FormScaffold usage (create only - needs edit mode)
- **PersonalValuesListView.swift** - Basic @FetchAll usage (needs tap/swipe)

**Architecture Documentation**:
- **ARCHITECTURE_EVALUATION_20251102.md** - @Observable vs ObservableObject analysis
- **REARCHITECTURE_COMPLETE_GUIDE.md** - Overall 7-phase roadmap

**SQLiteData Examples** (External references):
- sqlite-data-main/Examples/Reminders/Schema.swift - JOIN pattern inspiration
- sqlite-data-main/Examples/CaseStudies/ObservableModelDemo.swift - @Observable + @Dependency pattern

---

**Last Updated**: 2025-11-02 after PersonalValue + Term vertical slice completion (Term has full CRUD parity)
