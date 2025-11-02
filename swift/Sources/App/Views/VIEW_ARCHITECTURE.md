# View Architecture - Parity Plan
**Written by Claude Code on 2025-10-31**
**Updated**: 2025-11-02 (PersonalValue Complete)

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

#### 1.1 Coordinators (~600 lines) - ✅ VALUE COMPLETE, 3 REMAINING

**Status Update (2025-11-02)**:
- ✅ **PersonalValueCoordinator** - Complete with @Observable pattern
- ✅ **CoordinatorError** - Renamed from CoordinatorErrorCoordinator
- ✅ **ValueFormData** - Complete
- ❌ **TermCoordinator** - Not started (~150 lines, 3 hours)
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

**Decision: Keep All Coordinators for Consistency**
- Even simple entities use coordinators (PersonalValue)
- Consistent pattern easier to understand than hybrid approach
- Can refactor to static methods later if feels overkill
- See ARCHITECTURE_EVALUATION_20251102.md for full analysis

---

#### 1.2 ViewModels (~400 lines) - ✅ VALUE COMPLETE, 3 REMAINING

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesFormViewModel** - Complete with @Observable
- ❌ **TermFormViewModel** - Not started
- ❌ **ActionFormViewModel** - Not started (ActionFormData exists, but no ViewModel)
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

#### 1.3 Form Views (~800 lines) - ✅ VALUE COMPLETE, 3 REMAINING

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesFormView** - Complete with FormScaffold
- ❌ **TermFormView** - Exists but needs ViewModel integration
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

#### 1.4 List Views (~400 lines) - ✅ VALUE COMPLETE, 3 REMAINING

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesListView** - Complete with @FetchAll
- ❌ **TermsListView** - Not started
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

#### 1.5 Row Views (~200 lines) - ✅ VALUE COMPLETE, 3 REMAINING

**Status Update (2025-11-02)**:
- ✅ **PersonalValuesRowView** - Complete with BadgeView template
- ❌ **TermRowView** - Needs update
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

| Component | Complete | Remaining | Total Lines |
|-----------|----------|-----------|-------------|
| **Coordinators** | ✅ 1/4 (PersonalValue) | 3 (Term, Action, Goal) | ~600 |
| **ViewModels** | ✅ 1/4 (PersonalValue) | 3 (Term, Action, Goal) | ~400 |
| **Form Views** | ✅ 1/4 (PersonalValue) | 3 (Term, Action, Goal) | ~800 |
| **List Views** | ✅ 1/4 (PersonalValue) | 3 (Term, Action, Goal) | ~400 |
| **Row Views** | ✅ 1/4 (PersonalValue) | 3 (Term, Action, Goal) | ~200 |
| **TOTAL** | **✅ ~500 lines** | **❌ ~2,000 lines** | **~2,400 lines** |

**Phase 1 Status**: 21% Complete (1/4 entities)

---

## Next Immediate Steps

### Recommended Order (Based on Complexity)

1. **TermCoordinator + Full Vertical Slice** (~8 hours)
   - TermCoordinator (2 models, simple FK)
   - TermFormViewModel
   - Update TermFormView to use ViewModel
   - TermsListView (new)
   - TermRowView (update)
   - **Result**: Term CRUD working end-to-end

2. **ActionCoordinator + Full Vertical Slice** (~12 hours)
   - ActionCoordinator (3 models, many-to-many)
   - ActionFormViewModel
   - Update ActionFormView to use ViewModel
   - Update ActionsListView for measurements
   - Update ActionRowView for measurements
   - **Result**: Action CRUD with measurements working

3. **GoalCoordinator + Full Vertical Slice** (~18 hours)
   - GoalCoordinator (5+ models, complex)
   - GoalFormViewModel
   - Major refactor GoalFormView (Expectation + targets + alignments)
   - Update GoalsListView for multi-model
   - Update GoalRowView for metrics
   - **Result**: Goal CRUD with full SMART criteria working

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

---

## Testing Status

**PersonalValue Tests**: ❌ Not written yet
- Need unit tests for PersonalValueCoordinator
- Need integration test for full create cycle
- Pattern will apply to other coordinators

**Remaining Tests**: ❌ All Phase 1 tests pending

---

## References

- **ARCHITECTURE_EVALUATION_20251102.md** - Full analysis of @Observable vs ObservableObject, coordinator pattern
- **REARCHITECTURE_COMPLETE_GUIDE.md** - Overall 7-phase roadmap
- **PersonalValueCoordinator.swift** - Reference implementation with inline docs
- **PersonalValuesFormViewModel.swift** - Reference ViewModel with @Observable pattern
- **PersonalValuesFormView.swift** - Reference view with FormScaffold usage

---

**Last Updated**: 2025-11-02 after PersonalValue vertical slice completion
