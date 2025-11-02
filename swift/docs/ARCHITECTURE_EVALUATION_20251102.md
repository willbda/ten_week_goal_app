# Architecture Evaluation - November 2, 2025
**Written by Claude Code**

## Context

After committing 11 batches of rearchitecture work, I researched Apple's official SwiftUI documentation and Swift concurrency patterns to evaluate whether our current direction is appropriate.

---

## TL;DR - Critical Findings

### ✅ What's Working Well
1. **@Observable macro adoption** - Modern, not legacy ObservableObject
2. **Sendable models** - Properly thread-safe structs
3. **Separation of concerns** - Clear layers (Models, Services, Views)
4. **Template-based views** - Reusable components reduce duplication

### ⚠️ Potential Issues
1. **Coordinator pattern complexity** - May be over-engineering for SwiftUI
2. **@MainActor everywhere** - Could be limiting performance
3. **Missing @Observable on ViewModels** - Using old ObservableObject pattern
4. **Repository layer might be unnecessary** - SwiftUI prefers direct model access

### 🔴 Red Flags
1. **Fighting SwiftUI's data flow** - Adding layers Apple says to avoid
2. **No use of @Environment** - Missing key SwiftUI pattern
3. **Unclear value of Coordinators** - Duplicates ViewModel responsibilities
4. **Database.write from ViewModels** - Should models own persistence?

---

## Apple's Recommended Architecture

Based on documentation research:

### Modern SwiftUI Data Flow (2024+)

```swift
// 1. Models with @Observable
@Observable
class Library {
    var books: [Book] = []

    func addBook(_ book: Book) {
        books.append(book)
        // Persistence happens HERE, not in a coordinator
        Task { await save() }
    }

    private func save() async {
        // Direct database access from model
    }
}

// 2. Views use @State for ownership
struct LibraryView: View {
    @State private var library = Library()

    var body: some View {
        BookListView(library: library)
    }
}

// 3. Child views receive bindings or read-only access
struct BookListView: View {
    let library: Library  // Automatic observation!

    var body: some View {
        List(library.books) { book in
            Text(book.title)
        }
    }
}
```

**Key Points from Apple Docs**:
- "Connect to and observe reference model data in views by applying the @Observable() macro"
- "Instantiate an observable model data type directly in a view using a @State property"
- "SwiftUI implements many data management types as property wrappers"
- "Encapsulate view-specific data within your app's view hierarchy"

### What Apple Does NOT Recommend

From documentation analysis:
- ❌ ViewModels as intermediaries (no mention in modern SwiftUI docs)
- ❌ Repository pattern (prefers direct model access)
- ❌ Coordinators for persistence (models own their persistence)
- ❌ Separate form data types (use model properties directly with @State)

---

## Our Current Architecture vs. Apple's Guidance

### Layer Comparison

| Layer | Our Implementation | Apple's Pattern | Assessment |
|-------|-------------------|-----------------|------------|
| **Models** | `@Table` structs (Sendable) | `@Observable` classes | ⚠️ Structs can't be @Observable |
| **ViewModels** | `@MainActor class` with `ObservableObject` | Embedded in Views as `@State` | ⚠️ Using legacy pattern |
| **Coordinators** | Separate service objects | Don't exist in Apple docs | 🔴 Not idiomatic SwiftUI |
| **Views** | Template-based, form scaffolds | Direct model binding | ✅ Good templates, but... |
| **Data Flow** | View → ViewModel → Coordinator → DB | View → Model → DB | 🔴 Too many layers |

### Specific Issues

#### Issue 1: @Observable vs ObservableObject

**Our Code**:
```swift
// PersonalValueFormViewModel.swift
@MainActor
public final class PersonalValueFormViewModel: ObservableObject {  // ❌ Legacy
    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String?

    private lazy var coordinator: PersonalValueCoordinator = { ... }()
}
```

**Apple's Pattern** (from docs):
```swift
@Observable  // ✅ Modern
class PersonalValueForm {
    var isSaving: Bool = false
    var errorMessage: String?
    // No @Published needed with @Observable!
}
```

**Impact**: We're using the old Combine-based pattern when Swift 5.9+ has better options.

---

#### Issue 2: Coordinator Layer Adds Complexity

**Our Code**:
```swift
// 3 layers for one save operation:
PersonalValuesFormView
  → PersonalValueFormViewModel.save()
    → PersonalValueCoordinator.create()
      → database.write { PersonalValue.insert() }
```

**Apple's Pattern** (inferred from docs):
```swift
// 1 layer:
PersonalValueForm
  → PersonalValue.save()  // Model owns persistence
```

**Question**: What does the Coordinator actually do that couldn't be in PersonalValue itself?

**Answer from our code**:
```swift
// PersonalValueCoordinator.swift
public func create(from formData: ValueFormData) async throws -> PersonalValue {
    return try await database.write { db in
        try PersonalValue.insert {
            PersonalValue.Draft(
                id: UUID(),
                title: formData.title,
                // ... map 8 fields
            )
        }
        .returning()
        .fetchOne(db)!
    }
}
```

**Analysis**: This is just field mapping + database call. Could be a static method on PersonalValue.

---

#### Issue 3: Models Can't Be @Observable

**Our Models**:
```swift
@Table
public struct PersonalValue: DomainAbstraction, Sendable {
    public var id: UUID
    public var title: String?
    // ...
}
```

**Problem**: `@Observable` only works on classes, not structs.

**Apple's Guidance**: Use classes for model data that needs observation.

**Our Constraint**: SQLiteData's `@Table` macro requires structs for value semantics.

**Conflict**: We're stuck between:
- SQLiteData's struct requirement (for database mapping)
- SwiftUI's class preference (for observation)

**Current "Solution"**: We wrap structs in ObservableObject ViewModels.

**Question**: Is this the right tradeoff, or should we rethink the model layer?

---

#### Issue 4: @MainActor Everywhere

**Our Code**:
```swift
@MainActor
public final class PersonalValueCoordinator: ObservableObject { ... }

@MainActor
public final class PersonalValueFormViewModel: ObservableObject { ... }
```

**Impact**: Forces all database operations onto main thread.

**Apple's Concurrency Guidance** (from docs):
- Actors isolate mutable state
- @MainActor for UI updates only
- Background actors for heavy computation/IO

**Question**: Should Coordinators be background actors to avoid blocking UI?

**Answer**: Depends on whether we trust SQLiteData's async/await to yield properly.

---

#### Issue 5: No Environment Usage

**Missing from our architecture**:
```swift
// Apple's recommended pattern for sharing state
@Environment(\.modelContext) private var modelContext  // SwiftData
@Environment(\.database) private var database  // Our equivalent?
```

**Our current approach**:
```swift
@Dependency(\.defaultDatabase) private var database
```

**Assessment**: We're using a custom dependency injection when SwiftUI has a built-in pattern.

**Consideration**: Is `@Dependency` from a third-party library? Should we use `@Environment` instead?

---

## Alternative Architecture: "Pure SwiftUI"

Based on Apple's documentation, here's what an idiomatic SwiftUI + SQLiteData app might look like:

### Option A: Models Own Persistence

```swift
// Models become smart, not passive data containers
@Table
public struct PersonalValue: DomainAbstraction, Sendable {
    public var id: UUID
    public var title: String?
    // ... other fields

    // Static methods for CRUD
    public static func create(
        title: String,
        level: ValueLevel,
        priority: Int,
        // ... other params
        in database: Database
    ) async throws -> PersonalValue {
        try await database.write { db in
            try PersonalValue.insert {
                PersonalValue.Draft(
                    id: UUID(),
                    title: title,
                    // ...
                )
            }
            .returning()
            .fetchOne(db)!
        }
    }

    public static func all(from database: Database) async throws -> [PersonalValue] {
        try await PersonalValue.all()
    }
}

// Views interact directly with models
struct PersonalValueFormView: View {
    @Environment(\.database) private var database
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var level: ValueLevel = .general
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            TextField("Title", text: $title)
            // ...
        }
        .toolbar {
            Button("Save") {
                Task {
                    do {
                        isSaving = true
                        _ = try await PersonalValue.create(
                            title: title,
                            level: level,
                            in: database
                        )
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isSaving = false
                }
            }
            .disabled(title.isEmpty || isSaving)
        }
    }
}
```

**Pros**:
- ✅ Fewer layers, clearer data flow
- ✅ Idiomatic SwiftUI (matches Apple docs)
- ✅ No ViewModels needed for simple forms
- ✅ Models are self-contained

**Cons**:
- ❌ Models have database dependency (testability?)
- ❌ Business logic in model layer (SMART validation where?)
- ❌ Multi-model transactions harder (Goal + ExpectationMeasure + GoalRelevance)

---

### Option B: Repository Pattern (Current Direction)

```swift
// Repository handles database operations
@MainActor
class PersonalValueRepository: ObservableObject {
    private let database: Database

    @Published var values: [PersonalValue] = []

    func create(_ value: PersonalValue) async throws {
        try await database.write { db in
            try value.insert(db)
        }
        try await loadAll()
    }

    func loadAll() async throws {
        values = try await PersonalValue.all()
    }
}

// ViewModels coordinate between View and Repository
@MainActor
class PersonalValueFormViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let repository: PersonalValueRepository

    func save(title: String, ...) async throws {
        let value = PersonalValue(title: title, ...)
        try await repository.create(value)
    }
}

// Views use ViewModels
struct PersonalValueFormView: View {
    @StateObject var viewModel: PersonalValueFormViewModel
    @State private var title = ""
    // ...
}
```

**Pros**:
- ✅ Clear separation of concerns
- ✅ Repository testable in isolation
- ✅ Published state for reactive updates
- ✅ Familiar to backend developers

**Cons**:
- ❌ Not idiomatic SwiftUI (not in Apple docs)
- ❌ More boilerplate (3 files per entity)
- ❌ @MainActor might limit performance
- ❌ Fighting SwiftUI's preferred patterns

---

### Option C: Hybrid (What We're Building?)

```swift
// Models: Passive data containers
@Table
public struct PersonalValue: DomainAbstraction, Sendable { ... }

// Coordinators: Handle complex multi-model operations
@MainActor
class GoalCoordinator {
    func createGoalWithMeasures(
        expectation: Expectation,
        goal: Goal,
        measures: [ExpectationMeasure],
        values: [PersonalValue]
    ) async throws {
        // Atomic multi-table transaction
        try await database.write { db in
            try expectation.insert(db)
            try goal.insert(db)
            for measure in measures {
                try measure.insert(db)
            }
            // Create GoalRelevance relationships
        }
    }
}

// Simple CRUD: Direct model access in views
// Complex operations: Coordinators
```

**Pros**:
- ✅ Flexibility for complex operations
- ✅ Simple cases stay simple
- ✅ Multi-model atomicity handled well

**Cons**:
- ❌ Inconsistent patterns (when to use coordinator vs not?)
- ❌ Still not in Apple docs
- ❌ Two ways to do things

---

## Key Questions for Evaluation

### 1. Do we need ViewModels at all?

**Apple's stance** (from docs): Use `@State` in views for local state, `@Observable` models for shared state.

**Our use case**: Forms with validation and async save operations.

**Analysis**:
- Simple forms (PersonalValue): Probably don't need ViewModel
- Complex forms (Goal with measures + values): ViewModel might help coordinate

**Verdict**: ⚠️ **Overusing ViewModels** - Most of our forms are simple enough for direct model interaction

---

### 2. What value do Coordinators provide?

**Current responsibilities**:
1. Field mapping (formData → model)
2. Calling database.write
3. Creating relationships

**Alternative**: Models could have static factory methods:
```swift
extension PersonalValue {
    static func create(from formData: ValueFormData, in db: Database) throws -> PersonalValue {
        // Same logic, but co-located with model
    }
}
```

**Verdict**: 🔴 **Coordinators add layer without clear benefit** - Consider consolidating into model static methods

---

### 3. Should models own persistence?

**Pro** (Active Record pattern):
```swift
let value = PersonalValue(title: "Health")
try await value.save()  // Model knows how to save itself
```

**Con** (Repository pattern):
```swift
let value = PersonalValue(title: "Health")
try await repository.save(value)  // Separation of concerns
```

**Apple's preference**: Not explicitly stated, but examples show models accessing environment:
```swift
class Book {
    func save(context: ModelContext) {
        context.insert(self)
    }
}
```

**Verdict**: ⚠️ **Unclear** - Apple uses dependency injection (ModelContext), we could do same with Database

---

### 4. Is @MainActor everywhere a problem?

**Current**: All ViewModels and Coordinators are @MainActor.

**Impact**: Database writes block main thread (even if async).

**SQLiteData behavior**: Need to verify whether `database.write` automatically dispatches to background queue.

**Alternative**: Background actor for coordinators:
```swift
actor PersonalValueCoordinator {  // Not @MainActor
    func create(...) async throws -> PersonalValue {
        // Runs on background actor
    }
}
```

**Then ViewModels use `await`**:
```swift
@MainActor
class PersonalValueFormViewModel {
    func save() async {
        let value = await coordinator.create()  // Crosses actor boundary
        dismiss()  // Back on main thread for UI
    }
}
```

**Verdict**: 🔴 **Potential performance issue** - Review SQLiteData threading model, consider background actors

---

### 5. Why not use @Environment instead of @Dependency?

**Current**:
```swift
@Dependency(\.defaultDatabase) private var database
```

**Alternative**:
```swift
@Environment(\.database) private var database
```

**Consideration**: `@Dependency` suggests we're using a third-party DI framework. Is that necessary?

**Apple's pattern**: @Environment for dependency injection.

**Verdict**: ⚠️ **Review dependency injection approach** - Might be over-engineered

---

## Concrete Recommendations

### Immediate (Phase 3)

1. **Convert ViewModels to @Observable**
   - Drop `ObservableObject` + `@Published`
   - Use `@Observable` macro
   - Remove `@MainActor` if not needed for UI

2. **Evaluate Coordinator necessity**
   - For PersonalValue (simple): Move create() to static method on model
   - For Goal (complex multi-model): Keep coordinator for atomicity
   - Document when to use each pattern

3. **Add @Environment for database**
   - Remove custom `@Dependency` system
   - Use SwiftUI's built-in `@Environment(\.database)`

### Medium Term (Phase 4-5)

4. **Rethink ViewModel layer**
   - Simple forms: No ViewModel, just `@State` in View
   - Complex forms: ViewModel for business logic coordination
   - List views: Direct model array with `@State`

5. **Background actors for heavy operations**
   - Review SQLiteData threading
   - Move coordinators off @MainActor if safe
   - Keep ViewModels on @MainActor (for UI updates)

6. **Embrace SwiftUI patterns**
   - Use `@Observable` for shared model state
   - Use `@State` for view-local state
   - Use `@Binding` for child view communication
   - Use `@Environment` for dependency injection

### Long Term (Phase 6+)

7. **Consider Active Record for simple models**
   ```swift
   extension PersonalValue {
       func save(in database: Database) async throws {
           try await database.write { try self.insert() }
       }

       static func all(from database: Database) async throws -> [PersonalValue] {
           try await PersonalValue.all()
       }
   }
   ```

8. **Keep coordinators only for multi-model transactions**
   ```swift
   class GoalCoordinator {
       // Only for complex operations that span multiple models
       func createGoalWithMeasuresAndValues(...) async throws
   }
   ```

9. **Align with Apple's data flow philosophy**
   - Single source of truth
   - Views own their state
   - Models are observable
   - Minimal layers

---

## Risk Assessment

### If we continue current path:

**Low Risk**:
- ✅ Code will work
- ✅ Separation of concerns is clear
- ✅ Testability is good

**Medium Risk**:
- ⚠️ Fighting SwiftUI's preferred patterns
- ⚠️ More boilerplate than necessary
- ⚠️ Performance impact from @MainActor everywhere

**High Risk**:
- 🔴 Maintenance burden of extra layers
- 🔴 Harder for other developers to understand (non-standard)
- 🔴 Might need to refactor when Apple's patterns evolve

### If we pivot to simpler architecture:

**Benefits**:
- ✅ More idiomatic SwiftUI
- ✅ Less code to maintain
- ✅ Easier for new developers
- ✅ Better performance (fewer layers)

**Costs**:
- ❌ Rework already-written coordinators
- ❌ Need to figure out multi-model transactions
- ❌ Potential loss of separation of concerns

---

## Final Verdict

### Direction Assessment: ⚠️ **MIXED**

**What's good**:
- Database normalization is solid
- Template-based views are smart
- Separation of concerns is clear
- Testing infrastructure will be good

**What's concerning**:
- Adding layers that Apple doesn't recommend
- Using legacy ObservableObject instead of @Observable
- Coordinators might be solving a problem that doesn't need solving
- Performance implications of @MainActor everywhere

**Recommended action**:
1. **Pause Phase 3** before building more coordinators
2. **Prototype** a simple entity (PersonalValue) with direct model access
3. **Compare** code complexity and developer ergonomics
4. **Decide** which pattern feels more natural for this app
5. **Document** the chosen pattern clearly for consistency

---

## Research Sources

From doc-fetcher queries:

1. **Model data** (developer.apple.com/documentation/swiftui/model-data)
   - "Connect to and observe reference model data in views by applying the Observable() macro"
   - "Instantiate an observable model data type directly in a view using a State property"

2. **State** (developer.apple.com/documentation/swiftui/state)
   - "You can also store observable objects that you create with the Observable() macro in State"

3. **Observable()** (developer.apple.com/documentation/Observation/Observable())
   - "This macro adds observation support to a custom type and conforms the type to the Observable protocol"

4. **Sendable** (developer.apple.com/documentation/swift/sendable)
   - "Values of the type may have no shared mutable state, or they may protect that state with a lock or by forcing it to only be accessed from a specific actor"

5. **Concurrency** (docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
   - "A type that can be shared from one concurrency domain to another is known as a sendable type"

---

## Next Steps

**For David to consider**:

1. What's the goal of this architecture?
   - Maximum separation of concerns?
   - Idiomatic SwiftUI?
   - Enterprise-style patterns?
   - Testability above all?

2. What's the team situation?
   - Solo developer? → Simpler is better
   - Team of backend devs? → Repository pattern might fit
   - Teaching project? → Follow Apple's patterns

3. What's the performance requirement?
   - Hundreds of entities? → Current approach fine
   - Thousands? → Need to profile @MainActor impact

4. What's the long-term vision?
   - Maintain for years? → Follow Apple's patterns for future compatibility
   - Ship and iterate? → Current approach works

**Recommendation**: Let's discuss before proceeding with Phase 3 coordinator buildout.
