# Repository Implementation Plan
**Created**: 2025-11-08
**Status**: Ready to implement
**Approach**: Validation + Repository integration (combined)

---

## Executive Summary

We're implementing **repositories (reads) + validator integration (writes) together** as a single unified change.

**Why together?**
- Repositories provide `existsByTitle()` for validators to use
- Coordinators need both: validators for business rules, repositories for existence checks
- Solves duplicate bug comprehensively

**Timeline**: 1 week for GoalRepository + validation integration

---

## What We Created (Skeletons)

✅ **5 Repository Files** (all in `Sources/Services/Repositories/`):
1. `GoalRepository.swift` - Priority 1
2. `ActionRepository.swift` - Priority 2
3. `PersonalValueRepository.swift` - Priority 3
4. `TimePeriodRepository.swift` - Priority 4
5. `README.md` - Documentation

All files have:
- Clear purpose statements
- Method signatures (fatalError placeholders)
- Dependency documentation

---

## Implementation Plan: GoalRepository First

### Phase 1: Implement GoalRepository (2 days)

**File**: `Sources/Services/Repositories/GoalRepository.swift`

**Tasks**:
1. Implement `fetchAll()` - Move logic from GoalsQuery
2. Implement `fetchActiveGoals()` - Move logic from ActiveGoals
3. Implement `existsByTitle()` - NEW (prevents duplicates)
4. Implement `mapDatabaseError()` - Friendly error messages

**Code to write**:
```swift
public func fetchAll() async throws -> [GoalWithDetails] {
    try await database.read { db in
        try GoalsQuery().fetch(db)
    }
}

public func existsByTitle(_ title: String) async throws -> Bool {
    try await database.read { db in
        try Expectation
            .where { $0.title.eq(title) && $0.expectationType.eq(.goal) }
            .exists(db)
    }
}

func mapDatabaseError(_ error: Error) -> ValidationError {
    guard let dbError = error as? DatabaseError else {
        return .databaseError(error.localizedDescription)
    }

    switch dbError {
    case .foreignKeyViolation(let details):
        if details.contains("measureId") {
            return .invalidMeasure("Measurement unit no longer exists. Please choose another.")
        }
        if details.contains("valueId") {
            return .invalidValue("Personal value was deleted. Please choose another.")
        }
        // etc...
    case .uniqueViolation:
        return .duplicateRecord("This goal already exists")
    case .notNull(let column):
        return .missingRequiredField("Field '\(column)' is required")
    default:
        return .databaseError(dbError.localizedDescription)
    }
}
```

---

### Phase 2: Update GoalCoordinator (1 day)

**File**: `Sources/Services/Coordinators/GoalCoordinator.swift`

**Tasks**:
1. Add repository dependency
2. Call GoalValidator.validateFormData()
3. Call repository.existsByTitle() (prevent duplicates)
4. Call GoalValidator.validateComplete()
5. Wrap errors with repository.mapDatabaseError()

**Changes**:
```swift
@MainActor
public final class GoalCoordinator: ObservableObject {
    private let database: any DatabaseWriter
    private let repository: GoalRepository  // NEW

    public init(database: any DatabaseWriter, repository: GoalRepository) {
        self.database = database
        self.repository = repository
    }

    // Convenience init for backward compatibility
    public convenience init(database: any DatabaseWriter) {
        self.init(
            database: database,
            repository: GoalRepository(database: database)
        )
    }

    public func create(from formData: GoalFormData) async throws -> Goal {
        let validator = GoalValidator()

        // Phase 1: Validate form data (NEW - was missing)
        try validator.validateFormData(formData)

        // Phase 1.5: Check duplicates (NEW - prevents bug)
        if try await repository.existsByTitle(formData.title) {
            throw ValidationError.duplicateRecord(
                "A goal named '\(formData.title)' already exists"
            )
        }

        // Phase 2: Assemble entities
        let expectation = Expectation(...)
        let goal = Goal(...)
        let measures = formData.metricTargets.map { ... }
        let relevances = formData.valueAlignments.map { ... }

        // Phase 3: Validate complete graph (NEW - was missing)
        try validator.validateComplete((expectation, goal, measures, relevances))

        // Phase 4: Persist with error mapping (ENHANCED)
        do {
            try await database.write { db in
                try expectation.insert(db)
                try goal.insert(db)
                for measure in measures {
                    try measure.insert(db)
                }
                for relevance in relevances {
                    try relevance.insert(db)
                }
                if let termId = formData.termId {
                    try TermGoalAssignment.insert { ... }.execute(db)
                }
            }
            return goal
        } catch {
            throw repository.mapDatabaseError(error)  // NEW - friendly errors
        }
    }
}
```

---

### Phase 3: Update GoalFormViewModel (1 day)

**File**: `Sources/App/ViewModels/FormViewModels/GoalFormViewModel.swift`

**Tasks**:
1. Remove direct database access
2. Use repository for reads
3. Handle ValidationError messages

**Changes**:
```swift
@Observable
@MainActor
public final class GoalFormViewModel {
    public var isSaving: Bool = false
    public var errorMessage: String?
    public var availableGoals: [GoalWithDetails] = []  // NEW type

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    // NEW - use repository
    private var goalRepository: GoalRepository {
        GoalRepository(database: database)
    }

    private var coordinator: GoalCoordinator {
        GoalCoordinator(database: database, repository: goalRepository)
    }

    // BEFORE: Direct database query
    // public func loadAvailableGoals() async {
    //     let goals = try await database.read { db in
    //         try Goal.all.join(...).fetchAll(db)
    //     }
    // }

    // AFTER: Use repository
    public func loadAvailableGoals() async {
        do {
            availableGoals = try await goalRepository.fetchAll()
        } catch {
            errorMessage = "Failed to load goals: \(error.localizedDescription)"
        }
    }

    public func save(...) async throws {
        isSaving = true
        defer { isSaving = false }

        let formData = GoalFormData(...)

        do {
            _ = try await coordinator.create(from: formData)
        } catch let error as ValidationError {
            errorMessage = error.userMessage  // NEW - friendly message
            throw error
        }
    }
}
```

---

### Phase 4: Test Integration (1 day)

**Test Plan**:
1. ✅ CSV import of duplicate goal → clear error message
2. ✅ Manual entry of duplicate goal → clear error message
3. ✅ Invalid foreign key → clear error message
4. ✅ Missing required field → clear error message
5. ✅ Successful goal creation → no errors

**Test Code**:
```swift
// Test duplicate prevention
func testDuplicateGoalPrevention() async throws {
    let coordinator = GoalCoordinator(
        database: testDatabase,
        repository: GoalRepository(database: testDatabase)
    )

    // Create first goal
    let formData = GoalFormData(title: "Test Goal", ...)
    _ = try await coordinator.create(from: formData)

    // Try to create duplicate
    do {
        _ = try await coordinator.create(from: formData)
        XCTFail("Should have thrown duplicate error")
    } catch ValidationError.duplicateRecord(let message) {
        XCTAssertTrue(message.contains("already exists"))
    }
}
```

---

### Phase 5: Documentation Update (½ day)

**Files to update**:
1. `ARCHITECTURE_AS_IS_VS_PRINCIPLED.md` - Mark Phase 1 complete
2. `REARCHITECTURE_COMPLETE_GUIDE.md` - Update status
3. GitHub Issue #7 - Add completion note

---

## Timeline Summary

| Phase | Task | Duration | Cumulative |
|-------|------|----------|------------|
| 1 | Implement GoalRepository | 2 days | 2 days |
| 2 | Update GoalCoordinator | 1 day | 3 days |
| 3 | Update GoalFormViewModel | 1 day | 4 days |
| 4 | Test integration | 1 day | 5 days |
| 5 | Documentation | 0.5 days | 5.5 days |

**Total**: ~1 week for complete GoalRepository + validation integration

---

## Success Criteria

✅ **Duplicate Prevention Works**
- CSV re-import of same goal → error "Goal 'X' already exists"
- Manual entry of duplicate → same error
- No duplicate goals created

✅ **Validation Integrated**
- Empty title → error "Goal must have title or description"
- Invalid dates → error "Start date must be before target date"
- Invalid priority → error "Importance must be 1-10"

✅ **Error Messages User-Friendly**
- Foreign key violation → "Measurement unit no longer exists"
- Not null violation → "Field 'X' is required"
- No more "SQLITE_ERROR" shown to user

✅ **ViewModels Clean**
- No direct database access in GoalFormViewModel
- Uses repository for reads
- Uses coordinator for writes

---

## After GoalRepository Complete

**Then repeat for**:
1. ActionRepository (similar complexity, 5 days)
2. PersonalValueRepository (simpler, 2 days)
3. TimePeriodRepository (medium, 3 days)

**Total for all repositories**: ~3 weeks

---

## Open Questions

### Q1: Should repositories do writes or just reads?

**validation approach.md shows**: `repository.save()`
**Our plan**: Coordinators do writes, Repositories do reads

**Decision**: Keep writes in coordinators
- Coordinators already handle multi-model transactions well
- Repositories focus on queries and existence checks
- Simpler separation of concerns

**Action**: Update validation approach.md to reflect this

### Q2: Should we integrate validators first or repositories first?

**Decision**: Do BOTH together (as outlined above)
- Repositories provide existsByTitle() for validators
- Coordinators get both: validation + existence checks
- Single integrated change is cleaner than two separate phases

### Q3: Do we need dependency injection for repositories?

**Later**: Yes - will add @Dependency(\.goalRepository)
**Now**: No - create on-demand in ViewModels (simpler)

**After Phase 5**, add to ServiceContracts.swift:
```swift
extension DependencyValues {
    var goalRepository: GoalRepository {
        get { self[GoalRepositoryKey.self] }
        set { self[GoalRepositoryKey.self] = newValue }
    }
}
```

---

## Ready to Proceed?

All skeletons created. Ready to implement GoalRepository Phase 1.

**Next command**: Implement `GoalRepository.fetchAll()` and `GoalRepository.existsByTitle()`
