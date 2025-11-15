# Domain Model Reference
**Ten Week Goal App - Comprehensive Entity Documentation**

Written by Claude Code on 2025-11-11

## Purpose

This document provides a complete structural reference for all entities in the domain model, including their attributes, database constraints, and relationships. This serves as the foundation for reasoning about **duplication semantics** - understanding which combinations of attributes uniquely identify entities in their domain context.

---

## Table of Contents

1. [Protocol Architecture](#protocol-architecture)
2. [Abstraction Layer](#abstraction-layer)
   - [Action](#action)
   - [Expectation](#expectation)
   - [Measure](#measure)
   - [PersonalValue](#personalvalue)
   - [TimePeriod](#timeperiod)
3. [Basic Layer](#basic-layer)
   - [Goal](#goal)
   - [Milestone](#milestone)
   - [Obligation](#obligation)
   - [GoalTerm](#goalterm)
   - [ExpectationMeasure](#expectationmeasure)
4. [Composit Layer](#composit-layer)
   - [MeasuredAction](#measuredaction)
   - [GoalRelevance](#goalrelevance)
   - [ActionGoalContribution](#actiongoalcontribution)
   - [TermGoalAssignment](#termgoalassignment)

---

## Protocol Architecture

### Layer Definitions

The domain model uses a three-layer architecture with trait-based protocol composition:

```swift
// TRAIT PROTOCOLS
protocol Documentable {
    var title: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
}

protocol Timestamped {
    var logTime: Date { get }
}

// LAYER PROTOCOLS (semantic typealiases)
typealias DomainAbstraction = Identifiable + Documentable + Timestamped + Equatable + Hashable + Sendable
typealias DomainBasic = Identifiable + Equatable + Hashable + Sendable
typealias DomainComposit = Identifiable + Equatable + Hashable + Sendable
```

### Protocol Semantics

| Protocol | Fields | Purpose | Examples |
|----------|--------|---------|----------|
| **DomainAbstraction** | `id`, `title`, `detailedDescription`, `freeformNotes`, `logTime` | Base entities with full metadata | Action, Expectation, Measure, PersonalValue, TimePeriod |
| **DomainBasic** | `id` + type-specific fields | Working entities that reference abstractions | Goal, Milestone, Obligation, GoalTerm, ExpectationMeasure |
| **DomainComposit** | `id` + FK references + relationship data | Junction tables for many-to-many relationships | MeasuredAction, GoalRelevance, ActionGoalContribution, TermGoalAssignment |

---

## Abstraction Layer

### Action

**Protocol**: `DomainAbstraction`
**Table**: `actions`
**Purpose**: Record what was done (past-oriented)

#### Struct Attributes

```swift
public struct Action: DomainAbstraction {
    // DomainAbstraction fields
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // Action-specific fields
    public var durationMinutes: Double?
    public var startTime: Date?
}
```

#### Table Schema

```sql
CREATE TABLE actions (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    durationMinutes REAL,
    startTime TEXT
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `logTime`: NOT NULL
- No UNIQUE constraints (multiple actions can have same title/description)

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Measure | many-to-many | MeasuredAction | "This action measured 5km" |
| → Goal | many-to-many | ActionGoalContribution | "This action contributed to goal X" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: None - actions can legitimately repeat (same title, same day)
- **Duplication Signal**: `title` + `logTime` (within 5 min) + similar measurements
- **High Volume**: Users log frequently (10-50/day)

---

### Expectation

**Protocol**: `DomainAbstraction`
**Table**: `expectations`
**Purpose**: Base table for goals/milestones/obligations (table inheritance)

#### Struct Attributes

```swift
public struct Expectation: DomainAbstraction {
    // DomainAbstraction fields
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // Expectation-specific fields
    public var expectationType: ExpectationType  // goal | milestone | obligation
    public var expectationImportance: Int        // 1-10
    public var expectationUrgency: Int           // 1-10
}

public enum ExpectationType: String {
    case goal, milestone, obligation
}
```

#### Table Schema

```sql
CREATE TABLE expectations (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    expectationType TEXT NOT NULL CHECK(expectationType IN ('goal', 'milestone', 'obligation')),
    expectationImportance INTEGER NOT NULL,
    expectationUrgency INTEGER NOT NULL
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `logTime`: NOT NULL
- `expectationType`: NOT NULL, CHECK constraint (goal | milestone | obligation)
- `expectationImportance`: NOT NULL (1-10)
- `expectationUrgency`: NOT NULL (1-10)

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Goal | one-to-one | Goal.expectationId | Subtype table for goals |
| → Milestone | one-to-one | Milestone.expectationId | Subtype table for milestones |
| → Obligation | one-to-one | Obligation.expectationId | Subtype table for obligations |
| → Measure | many-to-many | ExpectationMeasure | Measurable targets |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `title` + `expectationType` (weak - goals can share titles)
- **Duplication Signal**: Context-dependent (see Goal, Milestone, Obligation)
- **Subtype Pattern**: Base table for polymorphic expectations

---

### Measure

**Protocol**: `DomainAbstraction`
**Table**: `measures`
**Purpose**: Catalog of measurement units

#### Struct Attributes

```swift
public struct Measure: DomainAbstraction {
    // DomainAbstraction fields
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // Measure-specific fields
    public var unit: String             // "km", "hours", "occasions"
    public var measureType: String      // "distance", "time", "count"
    public var canonicalUnit: String?   // "meters", "seconds"
    public var conversionFactor: Double? // 1000.0 for km→m
}
```

#### Table Schema

```sql
CREATE TABLE measures (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    unit TEXT NOT NULL,
    measureType TEXT NOT NULL,
    canonicalUnit TEXT,
    conversionFactor REAL
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `logTime`: NOT NULL
- `unit`: NOT NULL
- `measureType`: NOT NULL
- No UNIQUE constraint on `unit` (could have multiple km measures with different descriptions)

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| ← Action | many-to-many | MeasuredAction | "Actions measured in this unit" |
| ← Expectation | many-to-many | ExpectationMeasure | "Goals targeting this unit" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `unit` (strong - "km" is unique)
- **Duplication Signal**: `unit` alone (case-insensitive)
- **Catalog Entity**: Low volume, predefined set

---

### PersonalValue

**Protocol**: `DomainAbstraction`
**Table**: `personalValues`
**Purpose**: Personal values and life areas

#### Struct Attributes

```swift
public struct PersonalValue: DomainAbstraction {
    // DomainAbstraction fields
    public var id: UUID
    public var title: String?  // Optional in protocol, but semantically required
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // PersonalValue-specific fields
    public var priority: Int?              // 1-100 (lower = higher priority)
    public var valueLevel: ValueLevel      // general | major | highest_order | life_area
    public var lifeDomain: String?         // "Health", "Career", etc.
    public var alignmentGuidance: String?  // "Regular exercise..."
}

public enum ValueLevel: String {
    case general, major, highestOrder = "highest_order", lifeArea = "life_area"
}
```

#### Table Schema

```sql
CREATE TABLE personalValues (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL CHECK(LENGTH(TRIM(title)) > 0),
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    priority INTEGER NOT NULL,
    valueLevel TEXT NOT NULL CHECK(valueLevel IN ('general', 'major', 'highest_order', 'life_area')),
    lifeDomain TEXT,
    alignmentGuidance TEXT
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `title`: NOT NULL, CHECK (non-empty after trim)
- `logTime`: NOT NULL
- `priority`: NOT NULL
- `valueLevel`: NOT NULL, CHECK constraint
- No UNIQUE constraint on `title` (though duplicates unlikely)

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| ← Goal | many-to-many | GoalRelevance | "Goals aligned with this value" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `title` (strong - values rarely share exact names)
- **Duplication Signal**: `title` alone (case-insensitive)
- **Low Volume**: Users define ~5-20 values total

---

### TimePeriod

**Protocol**: `DomainAbstraction`
**Table**: `timePeriods`
**Purpose**: Pure chronological boundaries (no planning semantics)

#### Struct Attributes

```swift
public struct TimePeriod: DomainAbstraction {
    // DomainAbstraction fields
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date

    // TimePeriod-specific fields
    public var startDate: Date
    public var endDate: Date
}
```

#### Table Schema

```sql
CREATE TABLE timePeriods (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    startDate TEXT NOT NULL,
    endDate TEXT NOT NULL,
    CHECK(startDate <= endDate)
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `logTime`: NOT NULL
- `startDate`: NOT NULL
- `endDate`: NOT NULL
- `CHECK`: startDate <= endDate

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| ← GoalTerm | one-to-many | GoalTerm.timePeriodId | "Terms using this period" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `startDate` + `endDate` (weak - can have overlapping periods)
- **Duplication Signal**: Exact date range match is suspicious
- **Temporal Fact**: Represents time spans independent of goals

---

## Basic Layer

### Goal

**Protocol**: `DomainBasic`
**Table**: `goals`
**Purpose**: Expectation subtype with date ranges and action plans

#### Struct Attributes

```swift
public struct Goal: DomainBasic {
    // DomainBasic fields
    public var id: UUID

    // Foreign key to base
    public var expectationId: UUID  // FK → expectations.id

    // Goal-specific fields
    public var startDate: Date?
    public var targetDate: Date?
    public var actionPlan: String?
    public var expectedTermLength: Int?  // weeks
}
```

#### Table Schema

```sql
CREATE TABLE goals (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    startDate TEXT,
    targetDate TEXT,
    actionPlan TEXT,
    expectedTermLength INTEGER,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `expectationId`: NOT NULL, FK → expectations(id) ON DELETE CASCADE
- All other fields: Optional (nullable)

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Expectation | many-to-one | expectationId | "Base metadata (title, description)" |
| → Measure | many-to-many | ExpectationMeasure → Expectation | "Measurable targets" |
| → PersonalValue | many-to-many | GoalRelevance | "Values this goal serves" |
| ← Action | many-to-many | ActionGoalContribution | "Actions contributing to this" |
| ← GoalTerm | many-to-many | TermGoalAssignment | "Terms this goal is assigned to" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: **Complex composite** - `title` + `termAssignment` + `metricTargets`
- **Duplication Signal**:
  - Same `Expectation.title` (from expectationId)
  - Same `TermGoalAssignment.termId` (assigned to same term)
  - Same `ExpectationMeasure` targets (same metrics with same values)
  - **Example**: "Run 100km" in Term 5 with 100km target vs. "Run 100km" in Term 6 = NOT duplicates
- **High Complexity**: Duplication requires multi-table analysis

---

### Milestone

**Protocol**: `DomainBasic`
**Table**: `milestones`
**Purpose**: Expectation subtype for point-in-time checkpoints

#### Struct Attributes

```swift
public struct Milestone: DomainBasic {
    // DomainBasic fields
    public var id: UUID

    // Foreign key to base
    public var expectationId: UUID  // FK → expectations.id

    // Milestone-specific fields
    public var targetDate: Date
}
```

#### Table Schema

```sql
CREATE TABLE milestones (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    targetDate TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `expectationId`: NOT NULL, FK → expectations(id) ON DELETE CASCADE
- `targetDate`: NOT NULL

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Expectation | many-to-one | expectationId | "Base metadata (title, description)" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `title` + `targetDate`
- **Duplication Signal**: Same title + same date = likely duplicate
- **Simple Semantics**: Easier than Goal (no term assignments, fewer metrics)

---

### Obligation

**Protocol**: `DomainBasic`
**Table**: `obligations`
**Purpose**: Expectation subtype for external commitments

#### Struct Attributes

```swift
public struct Obligation: DomainBasic {
    // DomainBasic fields
    public var id: UUID

    // Foreign key to base
    public var expectationId: UUID  // FK → expectations.id

    // Obligation-specific fields
    public var deadline: Date
    public var requestedBy: String?
    public var consequence: String?
}
```

#### Table Schema

```sql
CREATE TABLE obligations (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    deadline TEXT NOT NULL,
    requestedBy TEXT,
    consequence TEXT,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `expectationId`: NOT NULL, FK → expectations(id) ON DELETE CASCADE
- `deadline`: NOT NULL

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Expectation | many-to-one | expectationId | "Base metadata (title, description)" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `title` + `deadline` + `requestedBy`
- **Duplication Signal**: Same title + same deadline from same requester
- **Medium Complexity**: More context than Milestone, less than Goal

---

### GoalTerm

**Protocol**: `DomainBasic`
**Table**: `goalTerms`
**Purpose**: Planning scaffolds with state (references TimePeriod for dates)

#### Struct Attributes

```swift
public struct GoalTerm: DomainBasic {
    // DomainBasic fields
    public var id: UUID

    // Foreign key to temporal period
    public var timePeriodId: UUID  // FK → timePeriods.id

    // GoalTerm-specific fields
    public var termNumber: Int
    public var theme: String?
    public var reflection: String?
    public var status: TermStatus?  // planned | active | completed | delayed | on_hold | cancelled
}

public enum TermStatus: String {
    case planned, active, completed, delayed, onHold = "on_hold", cancelled
}
```

#### Table Schema

```sql
CREATE TABLE goalTerms (
    id TEXT PRIMARY KEY,
    timePeriodId TEXT NOT NULL,
    termNumber INTEGER NOT NULL,
    theme TEXT,
    reflection TEXT,
    status TEXT CHECK(status IN ('planned', 'active', 'completed', 'delayed', 'on_hold', 'cancelled')),
    FOREIGN KEY (timePeriodId) REFERENCES timePeriods(id) ON DELETE CASCADE
);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `timePeriodId`: NOT NULL, FK → timePeriods(id) ON DELETE CASCADE
- `termNumber`: NOT NULL
- `status`: CHECK constraint (enum values)
- **No UNIQUE constraint** on `termNumber` (removed for CloudKit sync)

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → TimePeriod | many-to-one | timePeriodId | "Chronological boundaries" |
| → Goal | many-to-many | TermGoalAssignment | "Goals assigned to this term" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: `termNumber` (strong - "Term 5" is unique)
- **Duplication Signal**: Same `termNumber`
- **Low Volume**: ~1-2 new terms per year

---

### ExpectationMeasure

**Protocol**: `DomainBasic`
**Table**: `expectationMeasures`
**Purpose**: Measurable targets for expectations (0 to many per expectation)

#### Struct Attributes

```swift
public struct ExpectationMeasure: DomainBasic {
    // DomainBasic fields
    public var id: UUID

    // Relationship fields
    public var expectationId: UUID  // FK → expectations.id
    public var measureId: UUID      // FK → measures.id

    // Measurement data
    public var targetValue: Double
    public var freeformNotes: String?
    public var createdAt: Date
}
```

#### Table Schema

```sql
CREATE TABLE expectationMeasures (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    targetValue REAL NOT NULL,
    freeformNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT
);

-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Was: UNIQUE(expectationId, measureId)
-- Now enforced at application level in repositories
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `expectationId`: NOT NULL, FK → expectations(id) ON DELETE CASCADE
- `measureId`: NOT NULL, FK → measures(id) ON DELETE RESTRICT
- `targetValue`: NOT NULL
- `createdAt`: NOT NULL
- **Application-level uniqueness**: (expectationId, measureId) should be unique

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Expectation | many-to-one | expectationId | "The expectation being measured" |
| → Measure | many-to-one | measureId | "The unit of measurement" |

#### Semantic Notes

- **Identity**: UUID (system-generated)
- **Natural Key**: (`expectationId`, `measureId`) - one target per measure per expectation
- **Duplication Signal**: Same expectation + same measure = duplicate (should update, not insert)
- **Part of Goal Identity**: ExpectationMeasures contribute to goal duplication semantics

---

## Composit Layer

### MeasuredAction

**Protocol**: `DomainComposit`
**Table**: `measuredActions`
**Purpose**: Links actions to their measurements

#### Struct Attributes

```swift
public struct MeasuredAction: DomainComposit {
    // DomainComposit fields
    public var id: UUID

    // Relationship fields
    public var actionId: UUID   // FK → actions.id
    public var measureId: UUID  // FK → measures.id

    // Measurement data
    public var value: Double
    public var createdAt: Date
}
```

#### Table Schema

```sql
CREATE TABLE measuredActions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    value REAL NOT NULL,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT
);

-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Was: UNIQUE(actionId, measureId)
-- Now enforced at application level

-- Indexes for performance
CREATE INDEX idx_measured_actions_action_id ON measuredActions(actionId);
CREATE INDEX idx_measured_actions_measure_id ON measuredActions(measureId);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `actionId`: NOT NULL, FK → actions(id) ON DELETE CASCADE
- `measureId`: NOT NULL, FK → measures(id) ON DELETE RESTRICT
- `value`: NOT NULL
- `createdAt`: NOT NULL
- **Application-level uniqueness**: (actionId, measureId) should be unique

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Action | many-to-one | actionId | "The action being measured" |
| → Measure | many-to-one | measureId | "The unit of measurement" |

#### Semantic Notes

- **Pure Junction**: No domain semantics beyond linking
- **Natural Key**: (`actionId`, `measureId`) - one value per measure per action
- **Part of Action Identity**: Measurements contribute to action duplication semantics

---

### GoalRelevance

**Protocol**: `DomainComposit`
**Table**: `goalRelevances`
**Purpose**: Links goals to values they serve

#### Struct Attributes

```swift
public struct GoalRelevance: DomainComposit {
    // DomainComposit fields
    public var id: UUID

    // Relationship fields
    public var goalId: UUID   // FK → goals.id
    public var valueId: UUID  // FK → personalValues.id

    // Relationship metadata
    public var alignmentStrength: Int?  // 1-10
    public var relevanceNotes: String?
    public var createdAt: Date
}
```

#### Table Schema

```sql
CREATE TABLE goalRelevances (
    id TEXT PRIMARY KEY,
    goalId TEXT NOT NULL,
    valueId TEXT NOT NULL,
    alignmentStrength INTEGER CHECK(alignmentStrength BETWEEN 1 AND 10),
    relevanceNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (valueId) REFERENCES personalValues(id) ON DELETE CASCADE
);

-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Was: UNIQUE(goalId, valueId)

-- Indexes for performance
CREATE INDEX idx_goal_relevances_goal_id ON goalRelevances(goalId);
CREATE INDEX idx_goal_relevances_value_id ON goalRelevances(valueId);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `goalId`: NOT NULL, FK → goals(id) ON DELETE CASCADE
- `valueId`: NOT NULL, FK → personalValues(id) ON DELETE CASCADE
- `alignmentStrength`: CHECK (1-10 range)
- `createdAt`: NOT NULL
- **Application-level uniqueness**: (goalId, valueId) should be unique

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Goal | many-to-one | goalId | "The goal being aligned" |
| → PersonalValue | many-to-one | valueId | "The value being served" |

#### Semantic Notes

- **Many-to-many Junction**: Goals can serve multiple values, values can be served by multiple goals
- **Natural Key**: (`goalId`, `valueId`) - one alignment per goal-value pair
- **Part of Goal Identity**: Value alignments MAY contribute to goal duplication semantics (debatable)

---

### ActionGoalContribution

**Protocol**: `DomainComposit`
**Table**: `actionGoalContributions`
**Purpose**: Tracks action progress toward goals

#### Struct Attributes

```swift
public struct ActionGoalContribution: DomainComposit {
    // DomainComposit fields
    public var id: UUID

    // Relationship fields
    public var actionId: UUID   // FK → actions.id
    public var goalId: UUID     // FK → goals.id

    // Contribution data
    public var contributionAmount: Double?
    public var measureId: UUID? // FK → measures.id
    public var createdAt: Date
}
```

#### Table Schema

```sql
CREATE TABLE actionGoalContributions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    contributionAmount REAL,
    measureId TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT
);

-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Was: UNIQUE(actionId, goalId)

-- Indexes for performance
CREATE INDEX idx_action_goal_contributions_action_id ON actionGoalContributions(actionId);
CREATE INDEX idx_action_goal_contributions_goal_id ON actionGoalContributions(goalId);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `actionId`: NOT NULL, FK → actions(id) ON DELETE CASCADE
- `goalId`: NOT NULL, FK → goals(id) ON DELETE CASCADE
- `measureId`: Nullable, FK → measures(id) ON DELETE RESTRICT
- `contributionAmount`: Nullable
- `createdAt`: NOT NULL
- **Application-level uniqueness**: (actionId, goalId) should be unique

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → Action | many-to-one | actionId | "The contributing action" |
| → Goal | many-to-one | goalId | "The goal being advanced" |
| → Measure | many-to-one | measureId | "The unit of contribution" |

#### Semantic Notes

- **Many-to-many Junction**: Actions can contribute to multiple goals, goals receive contributions from multiple actions
- **Natural Key**: (`actionId`, `goalId`) - one contribution record per action-goal pair
- **NOT Part of Duplication**: Contributions are consequences, not identity attributes

---

### TermGoalAssignment

**Protocol**: `DomainComposit`
**Table**: `termGoalAssignments`
**Purpose**: Assigns goals to planning terms

#### Struct Attributes

```swift
public struct TermGoalAssignment: DomainComposit {
    // DomainComposit fields
    public var id: UUID

    // Relationship fields
    public var termId: UUID  // FK → goalTerms.id
    public var goalId: UUID  // FK → goals.id

    // Assignment metadata
    public var assignmentOrder: Int?
    public var createdAt: Date
}
```

#### Table Schema

```sql
CREATE TABLE termGoalAssignments (
    id TEXT PRIMARY KEY,
    termId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    assignmentOrder INTEGER,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (termId) REFERENCES goalTerms(id) ON DELETE CASCADE,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE
);

-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Was: UNIQUE(termId, goalId)

-- Indexes for performance
CREATE INDEX idx_term_goal_assignments_term_id ON termGoalAssignments(termId);
CREATE INDEX idx_term_goal_assignments_goal_id ON termGoalAssignments(goalId);
```

#### Database Constraints

- `id`: PRIMARY KEY (UUID)
- `termId`: NOT NULL, FK → goalTerms(id) ON DELETE CASCADE
- `goalId`: NOT NULL, FK → goals(id) ON DELETE CASCADE
- `assignmentOrder`: Nullable
- `createdAt`: NOT NULL
- **Application-level uniqueness**: (termId, goalId) should be unique

#### Relationships

| Relationship | Type | Via | Purpose |
|--------------|------|-----|---------|
| → GoalTerm | many-to-one | termId | "The term this goal is assigned to" |
| → Goal | many-to-one | goalId | "The goal being assigned" |

#### Semantic Notes

- **Many-to-many Junction**: Goals can be assigned to multiple terms (e.g., "Ongoing health goal" in Term 5, 6, 7)
- **Natural Key**: (`termId`, `goalId`) - one assignment per term-goal pair
- **CRITICAL for Goal Identity**: Term assignment is a key component of goal duplication semantics

---

## Next Steps

With this structural reference, we can now:

1. **Map duplication semantics** - For each entity, identify which attribute combinations signal duplication
2. **Design detection services** - Build entity-specific duplicate detection logic
3. **Define similarity thresholds** - Determine what percentage similarity triggers warnings
4. **Implement UI flows** - Design user experience for duplicate warnings and overrides

**Ready to proceed with duplication semantics analysis?**
