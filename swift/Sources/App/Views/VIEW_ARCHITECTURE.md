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

##### Revised Phase 1.1 Plan: Coordinator Infrastructure

Implementation Decisions

Based on SQLiteData/GRDB research:

1. Validation: Basic only (defer SMART to Phase 2 validators)
2. Transactions: Use database.write { } for automatic atomicity
3. Error Recovery: Validate-then-execute, accept all-or-nothing on edge cases


Updated Coordinator Pattern
```swift
import Foundation
import SQLiteData

@MainActor
public final class [Entity]Coordinator: ObservableObject {
    // MARK: - Dependencies
    private let database: Database

    // MARK: - Published State
    @Published public var validationErrors: [CoordinatorError] = []

    // MARK: - Initialization
    public init(database: Database) {
        self.database = database
    }

    // MARK: - Core Operations

    /// Creates entity with all relationships atomically
    public func create(from formData: [Entity]FormData) async throws -> [Entity] {
        // 1. Basic validation (format, nil checks)
        let errors = validateBasic(formData)
        guard errors.isEmpty else {
            validationErrors = errors
            throw CoordinatorError.validationFailed(errors)
        }

        // 2. Validate relationships exist (fail fast)
        try await validateRelationships(formData)

        // 3. Atomic persistence via database.write
        return try await database.write { db in
            // All operations succeed or all roll back
            let primary = try insertPrimary(formData, db)
            try insertRelationships(primary.id, formData, db)
            return primary
        }
    }

    // MARK: - Validation

    private func validateBasic(_ formData: [Entity]FormData) -> [CoordinatorError] {
        // Format validation, nil checks, basic business rules
        // NO SMART validation, NO complex queries
    }

    private func validateRelationships(_ formData: [Entity]FormData) async throws {
        // Pre-check foreign keys exist
        // Throws CoordinatorError.relationNotFound if missing
    }

    // MARK: - Assembly

    private func insertPrimary(_ formData: [Entity]FormData, _ db: Database) throws -> [Entity] {
        // Insert primary entity, return with generated ID
    }

    private func insertRelationships(_ primaryId: UUID, _ formData: [Entity]FormData, _ db: Database) throws {
        // Insert junction table records
    }
}

```

Implementation Order (Revised)

1. ValueCoordinator (~100 lines, 2 hours)

Simplest: Single model, no relationships, establishes pattern


2. TermCoordinator (~150 lines, 3 hours)

Simple relationships: TimePeriod → GoalTerm (1:1)
```swift
@MainActor
public final class TermCoordinator: ObservableObject {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func create(from formData: TermFormData) async throws -> (TimePeriod, GoalTerm) {
        // 1. Basic validation
        let errors = validateBasic(formData)
        guard errors.isEmpty else {
            throw CoordinatorError.validationFailed(errors)
        }

        // 2. No relationships to validate

        // 3. Atomic insert of both models
        return try await database.write { db in
            // Insert TimePeriod first
            let timePeriod = try TimePeriod.insert {
                TimePeriod.Draft(
                    id: UUID(),
                    title: formData.title,
                    detailedDescription: formData.description,
                    freeformNotes: formData.notes,
                    logTime: Date(),
                    startDate: formData.startDate,
                    targetDate: formData.targetDate
                )
            }
            .returning()
            .fetchOne(db)!

            // Insert GoalTerm with foreign key
            let goalTerm = try GoalTerm.insert {
                GoalTerm.Draft(
                    id: UUID(),
                    timePeriodId: timePeriod.id,
                    termNumber: formData.termNumber
                )
            }
            .returning()
            .fetchOne(db)!

            return (timePeriod, goalTerm)
        }
    }

    private func validateBasic(_ formData: TermFormData) -> [CoordinatorError] {
        var errors: [CoordinatorError] = []

        if formData.termNumber < 1 {
            errors.append(.invalidFormat(field: "termNumber", expected: ">= 1"))
        }

        if formData.targetDate <= formData.startDate {
            errors.append(.invalidDateRange(start: formData.startDate, end: formData.targetDate))
        }

        return errors
    }
}
```

3. ActionCoordinator (~200 lines, 4 hours)

Multiple relationships: Action → MeasuredAction[] + ActionGoalContribution[]

```swift
@MainActor
public final class ActionCoordinator: ObservableObject {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func create(from formData: ActionFormData) async throws -> Action {
        // 1. Basic validation
        let errors = validateBasic(formData)
        guard errors.isEmpty else {
            throw CoordinatorError.validationFailed(errors)
        }

        // 2. Validate relationships exist
        try await validateRelationships(formData)

        // 3. Atomic insert
        return try await database.write { db in
            // Insert Action
            let action = try Action.insert {
                Action.Draft(
                    id: UUID(),
                    title: formData.title,
                    detailedDescription: formData.description,
                    freeformNotes: formData.notes,
                    logTime: Date(),
                    startTime: formData.startTime,
                    durationMinutes: formData.durationMinutes
                )
            }
            .returning()
            .fetchOne(db)!

            // Insert measurements
            if !formData.measurements.isEmpty {
                try MeasuredAction.insert {
                    formData.measurements.map { measurement in
                        MeasuredAction.Draft(
                            id: UUID(),
                            actionId: action.id,
                            measureId: measurement.measureId,
                            value: measurement.value,
                            createdAt: Date()
                        )
                    }
                }
                .execute(db)
            }

            // Insert goal contributions
            if !formData.goalContributions.isEmpty {
                try ActionGoalContribution.insert {
                    formData.goalContributions.map { contribution in
                        ActionGoalContribution.Draft(
                            id: UUID(),
                            actionId: action.id,
                            goalId: contribution.goalId,
                            contributionAmount: contribution.contributionAmount
                        )
                    }
                }
                .execute(db)
            }

            return action
        }
    }

    private func validateBasic(_ formData: ActionFormData) -> [CoordinatorError] {
        var errors: [CoordinatorError] = []

        if formData.title.isEmpty {
            errors.append(.missingRequiredField("title"))
        }

        if let duration = formData.durationMinutes, duration < 0 {
            errors.append(.invalidFormat(field: "durationMinutes", expected: ">= 0"))
        }

        for measurement in formData.measurements {
            if measurement.value < 0 {
                errors.append(.invalidFormat(field: "measurement.value", expected: ">= 0"))
            }
        }

        return errors
    }

    private func validateRelationships(_ formData: ActionFormData) async throws {
        try await database.read { db in
            // Validate all measures exist
            for measurement in formData.measurements {
                guard try Measure.find(measurement.measureId).fetchOne(db) != nil else {
                    throw CoordinatorError.measureNotFound(measurement.measureId)
                }
            }

            // Validate all goals exist
            for contribution in formData.goalContributions {
                guard try Goal.find(contribution.goalId).fetchOne(db) != nil else {
                    throw CoordinatorError.goalNotFound(contribution.goalId)
                }
            }
        }
    }
}

```
1. GoalCoordinator (~250 lines, 6 hours)

Most complex: Expectation → Goal → ExpectationMeasure[] + GoalRelevance[] + TermGoalAssignment?

```swift
@MainActor
public final class GoalCoordinator: ObservableObject {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func create(from formData: GoalFormData) async throws -> Goal {
        // 1. Basic validation
        let errors = validateBasic(formData)
        guard errors.isEmpty else {
            throw CoordinatorError.validationFailed(errors)
        }

        // 2. Validate relationships exist
        try await validateRelationships(formData)

        // 3. Atomic insert
        return try await database.write { db in
            // Insert Expectation
            let expectation = try Expectation.insert {
                Expectation.Draft(
                    id: UUID(),
                    title: formData.expectationData.title,
                    detailedDescription: formData.expectationData.description,
                    freeformNotes: formData.expectationData.notes,
                    logTime: Date(),
                    isMilestone: formData.expectationData.isMilestone,
                    isGoal: true
                )
            }
            .returning()
            .fetchOne(db)!

            // Insert Goal
            let goal = try Goal.insert {
                Goal.Draft(
                    id: UUID(),
                    expectationId: expectation.id,
                    actionPlan: formData.actionPlan,
                    startDate: formData.startDate,
                    targetDate: formData.targetDate
                )
            }
            .returning()
            .fetchOne(db)!

            // Insert target measures
            if !formData.targets.isEmpty {
                try ExpectationMeasure.insert {
                    formData.targets.map { target in
                        ExpectationMeasure.Draft(
                            id: UUID(),
                            expectationId: expectation.id,
                            measureId: target.measureId,
                            targetValue: target.targetValue
                        )
                    }
                }
                .execute(db)
            }

            // Insert value alignments
            if !formData.valueAlignments.isEmpty {
                try GoalRelevance.insert {
                    formData.valueAlignments.map { alignment in
                        GoalRelevance.Draft(
                            id: UUID(),
                            goalId: goal.id,
                            valueId: alignment.valueId,
                            alignmentStrength: alignment.alignmentStrength
                        )
                    }
                }
                .execute(db)
            }

            // Optional: Assign to term
            if let termId = formData.termAssignment {
                try TermGoalAssignment.insert {
                    TermGoalAssignment.Draft(
                        id: UUID(),
                        termId: termId,
                        goalId: goal.id,
                        assignmentOrder: 0 // Will need to calculate actual order
                    )
                }
                .execute(db)
            }

            return goal
        }
    }

    private func validateBasic(_ formData: GoalFormData) -> [CoordinatorError] {
        var errors: [CoordinatorError] = []

        if formData.expectationData.title.isEmpty {
            errors.append(.missingRequiredField("title"))
        }

        if let start = formData.startDate, let target = formData.targetDate, target <= start {
            errors.append(.invalidDateRange(start: start, end: target))
        }

        for target in formData.targets {
            if target.targetValue < 0 {
                errors.append(.invalidFormat(field: "target.targetValue", expected: ">= 0"))
            }
        }

        for alignment in formData.valueAlignments {
            if !(1...10).contains(alignment.alignmentStrength) {
                errors.append(.invalidFormat(field: "alignmentStrength", expected: "1-10"))
            }
        }

        return errors
    }

    private func validateRelationships(_ formData: GoalFormData) async throws {
        try await database.read { db in
            // Validate all measures exist
            for target in formData.targets {
                guard try Measure.find(target.measureId).fetchOne(db) != nil else {
                    throw CoordinatorError.measureNotFound(target.measureId)
                }
            }

            // Validate all values exist
            for alignment in formData.valueAlignments {
                guard try PersonalValue.find(alignment.valueId).fetchOne(db) != nil else {
                    throw CoordinatorError.valueNotFound(alignment.valueId)
                }
            }

            // Validate term exists if specified
            if let termId = formData.termAssignment {
                guard try GoalTerm.find(termId).fetchOne(db) != nil else {
                    throw CoordinatorError.termNotFound(termId)
                }
            }
        }
    }
}
```
---
Form Data Structs
```swift
// Sources/Services/Coordinators/FormData/CoordinatorFormData.swift



public struct TermFormData {
    public let termNumber: Int
    public let startDate: Date
    public let targetDate: Date
    public let title: String?
    public let description: String?
    public let notes: String?

    public init(
        termNumber: Int,
        startDate: Date,
        targetDate: Date,
        title: String? = nil,
        description: String? = nil,
        notes: String? = nil
    ) {
        self.termNumber = termNumber
        self.startDate = startDate
        self.targetDate = targetDate
        self.title = title
        self.description = description
        self.notes = notes
    }
}

public struct ActionFormData {
    public struct Measurement {
        public let measureId: UUID
        public let value: Double

        public init(measureId: UUID, value: Double) {
            self.measureId = measureId
            self.value = value
        }
    }

    public struct GoalContribution {
        public let goalId: UUID
        public let contributionAmount: Double?

        public init(goalId: UUID, contributionAmount: Double? = nil) {
            self.goalId = goalId
            self.contributionAmount = contributionAmount
        }
    }

    public let title: String
    public let description: String?
    public let notes: String?
    public let startTime: Date?
    public let durationMinutes: Int?
    public let measurements: [Measurement]
    public let goalContributions: [GoalContribution]

    public init(
        title: String,
        description: String? = nil,
        notes: String? = nil,
        startTime: Date? = nil,
        durationMinutes: Int? = nil,
        measurements: [Measurement] = [],
        goalContributions: [GoalContribution] = []
    ) {
        self.title = title
        self.description = description
        self.notes = notes
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.measurements = measurements
        self.goalContributions = goalContributions
    }
}

public struct GoalFormData {
    public struct ExpectationData {
        public let title: String
        public let description: String?
        public let notes: String?
        public let isMilestone: Bool

        public init(
            title: String,
            description: String? = nil,
            notes: String? = nil,
            isMilestone: Bool = false
        ) {
            self.title = title
            self.description = description
            self.notes = notes
            self.isMilestone = isMilestone
        }
    }

    public struct Target {
        public let measureId: UUID
        public let targetValue: Double

        public init(measureId: UUID, targetValue: Double) {
            self.measureId = measureId
            self.targetValue = targetValue
        }
    }

    public struct ValueAlignment {
        public let valueId: UUID
        public let alignmentStrength: Int

        public init(valueId: UUID, alignmentStrength: Int) {
            self.valueId = valueId
            self.alignmentStrength = alignmentStrength
        }
    }

    public let expectationData: ExpectationData
    public let actionPlan: String?
    public let startDate: Date?
    public let targetDate: Date?
    public let targets: [Target]
    public let valueAlignments: [ValueAlignment]
    public let termAssignment: UUID?

    public init(
        expectationData: ExpectationData,
        actionPlan: String? = nil,
        startDate: Date? = nil,
        targetDate: Date? = nil,
        targets: [Target] = [],
        valueAlignments: [ValueAlignment] = [],
        termAssignment: UUID? = nil
    ) {
        self.expectationData = expectationData
        self.actionPlan = actionPlan
        self.startDate = startDate
        self.targetDate = targetDate
        self.targets = targets
        self.valueAlignments = valueAlignments
        self.termAssignment = termAssignment
    }
}

```

Testing Plan

Unit Tests (Per Coordinator)
```swift
import Testing
@testable import Services

@Suite("ValueCoordinator Tests")
struct ValueCoordinatorTests {
    let database: Database
    let coordinator: ValueCoordinator

    init() async throws {
        database = try await Database(path: ":memory:")
        coordinator = ValueCoordinator(database: database)
    }

    @Test("Creates value with valid form data")
    func testCreateValid() async throws {
        let formData = ValueFormData(
            title: "Health",
            description: "Physical wellbeing",
            level: .major,
            priority: 80
        )

        let value = try await coordinator.create(from: formData)

        #expect(value.title == "Health")
        #expect(value.valueLevel == .major)
        #expect(value.priority == 80)
    }

    @Test("Rejects empty title")
    func testRejectsEmptyTitle() async throws {
        let formData = ValueFormData(
            title: "",
            level: .general
        )

        await #expect(throws: CoordinatorError.self) {
            try await coordinator.create(from: formData)
        }
    }

    @Test("Rejects invalid priority")
    func testRejectsInvalidPriority() async throws {
        let formData = ValueFormData(
            title: "Health",
            level: .major,
            priority: 150
        )

        await #expect(throws: CoordinatorError.self) {
            try await coordinator.create(from: formData)
        }
    }
}
```
Integration Tests (Full Cycles)
```swift
@Suite("ActionCoordinator Integration Tests")
struct ActionCoordinatorIntegrationTests {
    let database: Database
    let coordinator: ActionCoordinator

    init() async throws {
        database = try await Database(path: ":memory:")
        coordinator = ActionCoordinator(database: database)

        // Seed test data
        try await seedMeasures()
        try await seedGoals()
    }

    @Test("Creates action with measurements and contributions")
    func testFullActionCreate() async throws {
        let formData = ActionFormData(
            title: "Morning run",
            startTime: Date(),
            durationMinutes: 45,
            measurements: [
                .init(measureId: kmMeasureId, value: 5.2),
                .init(measureId: sessionMeasureId, value: 1)
            ],
            goalContributions: [
                .init(goalId: runningGoalId, contributionAmount: 5.2)
            ]
        )

        let action = try await coordinator.create(from: formData)

        // Verify action created
        #expect(action.title == "Morning run")

        // Verify measurements persisted
        let measurements = try await database.read { db in
            try MeasuredAction
                .where { $0.actionId.eq(action.id) }
                .fetchAll(db)
        }
        #expect(measurements.count == 2)

        // Verify contributions persisted
        let contributions = try await database.read { db in
            try ActionGoalContribution
                .where { $0.actionId.eq(action.id) }
                .fetchAll(db)
        }
        #expect(contributions.count == 1)
    }

    @Test("Rolls back on invalid measure ID")
    func testRollbackOnInvalidMeasure() async throws {
        let formData = ActionFormData(
            title: "Bad action",
            measurements: [
                .init(measureId: UUID(), value: 10) // Non-existent measure
            ]
        )

        await #expect(throws: CoordinatorError.measureNotFound) {
            try await coordinator.create(from: formData)
        }

        // Verify no action was created
        let actions = try await database.read { db in
            try Action
                .where { $0.title.eq("Bad action") }
                .fetchAll(db)
        }
        #expect(actions.isEmpty)
    }
}
```

Revised Timeline

| Coordinator   | Implementation | Tests     | Total      |
|---------------|----------------|-----------|------------|
| Value         | 2 hours        | 1 hour    | 3 hours    |
| Term          | 3 hours        | 1.5 hours | 4.5 hours  |
| Action        | 4 hours        | 2 hours   | 6 hours    |
| Goal          | 6 hours        | 3 hours   | 9 hours    |
| Documentation | -              | -         | 2 hours    |
| TOTAL         | 15 hours       | 7.5 hours | 24.5 hours |

Estimate: ~3 working days



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
