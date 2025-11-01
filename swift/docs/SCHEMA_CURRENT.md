# Current Database Schema - 3NF+ with Table Inheritance
**Status**: PRODUCTION (Matches Swift Models as of 2025-10-31)
**Written by**: Claude Code on 2025-10-31

## Executive Summary

This schema reflects the **actual implemented Swift models** in `Sources/Models/`, implementing:
- **Table inheritance** (Expectation → Goal/Milestone/Obligation)
- **Semantic separation** (TimePeriod vs GoalTerm)
- **Trait-based protocols** (Identifiable + Documentable + Timestamped)
- **Pure junction tables** with minimal fields
- **Full 3NF compliance** (no JSON, no redundancy)

## Architecture Layers

### Layer 1: Abstractions (DomainAbstraction = Identifiable + Documentable + Timestamped)
**Purpose**: Entities with full metadata - the foundation layer

These entities have complete documentation (id, title, detailedDescription, freeformNotes, logTime).

### Layer 2: Basics (DomainBasic = Identifiable)
**Purpose**: Lightweight working entities - what you interact with daily

These entities reference Abstractions via FK and add type-specific fields.

### Layer 3: Composits (DomainComposit = Identifiable)
**Purpose**: Pure relationships - database artifacts

These are junction tables with minimal fields (just id + FKs + relationship data).

---

## Abstraction Layer Entities

### 1. Action (Past-Oriented)
**Table**: `actions`
**Purpose**: Record what was done

```swift
struct Action: DomainAbstraction {
    // Documentable + Timestamped
    id: UUID
    title: String?              // "Morning run"
    detailedDescription: String?
    freeformNotes: String?
    logTime: Date

    // Action-specific
    durationMinutes: Double?    // 28.5
    startTime: Date?            // 2025-10-31T06:30:00Z
}
```

**Measurements**: Stored in `MeasuredAction` junction table

---

### 2. Expectation (Base for Goals/Milestones/Obligations)
**Table**: `expectations`
**Purpose**: Base entity for all expectations (table inheritance pattern)

```swift
struct Expectation: DomainAbstraction {
    // Documentable + Timestamped
    id: UUID
    title: String?              // "Spring into Running"
    detailedDescription: String?
    freeformNotes: String?
    logTime: Date

    // Expectation-specific
    expectationType: ExpectationType        // .goal | .milestone | .obligation
    expectationImportance: Int              // 1-10 (10 = most important)
    expectationUrgency: Int                 // 1-10 (10 = most urgent)
}
```

**Subtypes**: Goal, Milestone, Obligation (each has FK to expectations.id)

**ExpectationType Enum**:
- `goal`: Date range with action plan (self-directed work)
- `milestone`: Point-in-time checkpoint
- `obligation`: External commitment with deadline

**Default Importance/Urgency by Type**:
- Goals: Importance=8, Urgency=5 (self-directed, flexible timing)
- Milestones: Importance=5, Urgency=8 (time-sensitive markers)
- Obligations: Importance=2, Urgency=6 (external accountability)

---

### 3. Measure (Metrics Catalog)
**Table**: `measures`
**Purpose**: Catalog of measurement units

```swift
struct Measure: DomainAbstraction {
    // Documentable + Timestamped
    id: UUID
    title: String?              // "Distance"
    detailedDescription: String?
    freeformNotes: String?
    logTime: Date

    // Measure-specific
    unit: String                // "km", "hours", "occasions"
    measureType: String         // "distance", "time", "count"
    canonicalUnit: String?      // "meters", "seconds"
    conversionFactor: Double?   // 1000.0 for km→meters
}
```

**Examples**:
- `Measure(unit: "km", measureType: "distance", canonicalUnit: "meters", conversionFactor: 1000.0)`
- `Measure(unit: "hours", measureType: "time", canonicalUnit: "seconds", conversionFactor: 3600.0)`
- `Measure(unit: "occasions", measureType: "count")`

---

### 4. PersonalValue (Unified Values)
**Table**: `personalvalues`
**Purpose**: Personal values and life areas (unified table replacing 4 legacy tables)

```swift
struct PersonalValue: DomainAbstraction {
    // Documentable + Timestamped
    id: UUID
    title: String?              // "Physical Health"
    detailedDescription: String?
    freeformNotes: String?
    logTime: Date

    // Value-specific
    priority: Int               // 1-100 (lower = higher priority)
    valueLevel: ValueLevel      // .general | .major | .highestOrder | .lifeArea
    lifeDomain: String?         // "Health", "Relationships", "Career"
    alignmentGuidance: String?  // "Regular exercise, meditation"
}
```

**ValueLevel Enum**:
- `general`: Things you affirm as important (default priority: 40)
- `major`: Actionable values appearing in actions/goals (default: 10)
- `highestOrder`: Abstract philosophical values (default: 1)
- `lifeArea`: Structural domains (default: 40)

---

### 5. TimePeriod (Pure Chronology)
**Table**: `timeperiods`
**Purpose**: Chronological boundaries without planning semantics

```swift
struct TimePeriod: DomainAbstraction {
    // Documentable + Timestamped
    id: UUID
    title: String?              // "Term 5 Period", "Q1 2026"
    detailedDescription: String?
    freeformNotes: String?
    logTime: Date

    // TimePeriod-specific
    startDate: Date             // 2025-03-01
    endDate: Date               // 2025-05-10 (70 days later)
}
```

**Design Principle**: TimePeriod is a chronological FACT. GoalTerm (Basic layer) adds planning semantics.

---

## Basic Layer Entities

### 6. Goal (Expectation Subtype)
**Table**: `goals`
**FK**: `expectationId` → `expectations.id`
**Purpose**: Self-directed objectives with date ranges

```swift
struct Goal: DomainBasic {
    id: UUID
    expectationId: UUID         // FK to Expectation

    // Goal-specific
    startDate: Date?            // When to start working
    targetDate: Date?           // When to achieve
    actionPlan: String?         // "Run 3x/week, increase 10% weekly"
    expectedTermLength: Int?    // 10 weeks
}
```

**Usage Pattern**:
1. Create `Expectation(title: "Spring into Running", expectationType: .goal)`
2. Create `Goal(expectationId: expectation.id, startDate: ..., targetDate: ...)`
3. Create `ExpectationMeasure(expectationId: expectation.id, measureId: km.id, targetValue: 120.0)`

---

### 7. Milestone (Expectation Subtype)
**Table**: `milestones`
**FK**: `expectationId` → `expectations.id`
**Purpose**: Point-in-time checkpoints

```swift
struct Milestone: DomainBasic {
    id: UUID
    expectationId: UUID         // FK to Expectation

    // Milestone-specific
    targetDate: Date            // Single checkpoint date
}
```

---

### 8. Obligation (Expectation Subtype)
**Table**: `obligations`
**FK**: `expectationId` → `expectations.id`
**Purpose**: External commitments with deadlines

```swift
struct Obligation: DomainBasic {
    id: UUID
    expectationId: UUID         // FK to Expectation

    // Obligation-specific
    deadline: Date              // When due
    requestedBy: String?        // "Board of Directors"
    consequence: String?        // "Delays grant disbursement"
}
```

---

### 9. GoalTerm (Planning Scaffold)
**Table**: `goalterms`
**FK**: `timePeriodId` → `timeperiods.id`
**Purpose**: Add planning semantics to TimePeriods

```swift
struct GoalTerm: DomainBasic {
    id: UUID
    timePeriodId: UUID          // FK to TimePeriod

    // Planning semantics
    termNumber: Int             // 5
    theme: String?              // "Health and momentum"
    reflection: String?         // Post-term reflection
    status: TermStatus?         // .planned | .active | .completed | ...
}
```

**TermStatus Enum**: `planned`, `active`, `completed`, `delayed`, `onHold`, `cancelled`

**Design Separation**:
- TimePeriod: Pure chronological fact (start/end dates)
- GoalTerm: Planning context (theme, status, reflection)

---

### 10. ExpectationMeasure (Measurement Targets)
**Table**: `expectationmeasures`
**Purpose**: Define measurable targets for expectations

```swift
struct ExpectationMeasure: DomainBasic {
    id: UUID

    // Relationship
    expectationId: UUID         // FK to Expectation (ANY type!)
    measureId: UUID             // FK to Measure
    targetValue: Double         // 120.0

    // Metadata
    freeformNotes: String?      // "Based on 10% weekly growth"
    createdAt: Date
}
```

**Special Note**: Works for Goals, Milestones, AND Obligations (not just goals!)

---

## Composit Layer (Junction Tables)

### 11. MeasuredAction
**Table**: `measuredactions`
**Purpose**: Link actions to their measurements

```swift
struct MeasuredAction: DomainComposit {
    id: UUID
    actionId: UUID              // FK to Action
    measureId: UUID             // FK to Measure
    value: Double               // 5.2 km
    createdAt: Date
}
```

**Replaces**: JSON `measuresByUnit` dictionary (now properly normalized)

---

### 12. GoalRelevance
**Table**: `goalrelevances`
**Purpose**: Link goals to values they serve

```swift
struct GoalRelevance: DomainComposit {
    id: UUID
    goalId: UUID                // FK to Goal
    valueId: UUID               // FK to PersonalValue
    alignmentStrength: Int?     // 1-10
    relevanceNotes: String?     // "Running supports health and vitality"
    createdAt: Date
}
```

**Replaces**: Flat text `howGoalIsRelevant` field

---

### 13. ActionGoalContribution
**Table**: `actiongoalcontributions`
**Purpose**: Track action progress toward goals

```swift
struct ActionGoalContribution: DomainComposit {
    id: UUID
    actionId: UUID              // FK to Action
    goalId: UUID                // FK to Goal
    contributionAmount: Double? // 5.2 km contributed
    measureId: UUID?            // FK to Measure
    createdAt: Date
}
```

---

### 14. TermGoalAssignment
**Table**: `termgoalassignments`
**Purpose**: Assign goals to terms

```swift
struct TermGoalAssignment: DomainComposit {
    id: UUID
    termId: UUID                // FK to GoalTerm
    goalId: UUID                // FK to Goal
    assignmentOrder: Int?       // Display order
    createdAt: Date
}
```

---

## Entity Relationship Diagram

```
Abstractions (Full Metadata):
┌─────────────┐  ┌──────────────┐  ┌─────────────┐  ┌────────────────┐  ┌─────────────┐
│   Action    │  │ Expectation  │  │   Measure   │  │ PersonalValue  │  │ TimePeriod  │
└─────────────┘  └──────────────┘  └─────────────┘  └────────────────┘  └─────────────┘
      │                 │                  │                  │                   │
      │          ┌──────┴──────┐          │                  │                   │
      │          │             │          │                  │                   │
Basics (Lightweight Entities):                               │                   │
      │    ┌──────────┐  ┌──────────┐  ┌──────────┐         │                   │
      │    │   Goal   │  │Milestone │  │Obligation│         │                   │
      │    └──────────┘  └──────────┘  └──────────┘         │                   │
      │          │                            │              │                   │
      │    ┌─────────────────┐                │              │           ┌────────────┐
      │    │ExpectationMeasure│──────────────┘              │           │ GoalTerm   │
      │    └─────────────────┘                               │           └────────────┘
      │                                                      │                   │
Composits (Junction Tables):                                │                   │
┌────────────────┐  ┌──────────────────┐  ┌────────────────┐  ┌──────────────────┐
│MeasuredAction  │  │ActionGoalContrib.│  │ GoalRelevance  │  │TermGoalAssign.   │
└────────────────┘  └──────────────────┘  └────────────────┘  └──────────────────┘
```

**Key Relationships**:
- Actions → MeasuredAction → Measures (what was measured)
- Expectations → ExpectationMeasure → Measures (what to measure)
- Expectations ← Goal/Milestone/Obligation (table inheritance)
- Goals → GoalRelevance → PersonalValues (why relevant)
- Goals ← TermGoalAssignment → GoalTerms (when to achieve)
- Actions → ActionGoalContribution → Goals (progress tracking)
- GoalTerms → TimePeriods (chronological boundaries)

---

## Query Examples

### Find all running actions (no JSON parsing!)
```sql
SELECT a.title, ma.value as km, a.logTime
FROM actions a
JOIN measuredactions ma ON a.id = ma.actionId
JOIN measures m ON ma.measureId = m.id
WHERE m.unit = 'km'
ORDER BY ma.value DESC;
```

### Get goal with all metadata (table inheritance join)
```sql
SELECT
    e.title, e.detailedDescription,
    e.expectationImportance, e.expectationUrgency,
    g.startDate, g.targetDate, g.actionPlan
FROM expectations e
JOIN goals g ON e.id = g.expectationId
WHERE g.id = ?;
```

### Calculate goal progress
```sql
SELECT
    e.title,
    em.targetValue,
    SUM(ac.contributionAmount) as actual,
    (SUM(ac.contributionAmount) / em.targetValue * 100) as percentage
FROM expectations e
JOIN goals g ON e.id = g.expectationId
JOIN expectationmeasures em ON e.id = em.expectationId
LEFT JOIN actiongoalcontributions ac ON g.id = ac.goalId
WHERE e.expectationType = 'goal'
GROUP BY e.id, em.targetValue;
```

### Find goals aligned with a value
```sql
SELECT e.title, gr.alignmentStrength, gr.relevanceNotes
FROM expectations e
JOIN goals g ON e.id = g.expectationId
JOIN goalrelevances gr ON g.id = gr.goalId
WHERE gr.valueId = ?
ORDER BY gr.alignmentStrength DESC;
```

### Get active term with goals
```sql
SELECT
    gt.termNumber, gt.theme,
    tp.startDate, tp.endDate,
    e.title as goalTitle
FROM goalterms gt
JOIN timeperiods tp ON gt.timePeriodId = tp.id
JOIN termgoalassignments tga ON gt.id = tga.termId
JOIN goals g ON tga.goalId = g.id
JOIN expectations e ON g.expectationId = e.id
WHERE gt.status = 'active'
ORDER BY tga.assignmentOrder;
```

---

## Design Principles

### 1. Table Inheritance (Expectation → Subtypes)
**Pattern**: Base table + subtype tables with FK references
- Expectation: Shared fields (title, description, importance, urgency)
- Goal/Milestone/Obligation: Type-specific fields
- Avoids: NULL-heavy single table or redundant fields across types

### 2. Semantic Separation (TimePeriod vs GoalTerm)
**Pattern**: Chronological facts separated from planning semantics
- TimePeriod: Pure temporal boundaries (calendar periods)
- GoalTerm: Planning context (theme, status, reflection)
- Enables: Calendar periods without goal planning, reusable time spans

### 3. Trait-Based Protocols
**Pattern**: Compose from small traits instead of monolithic base
- Identifiable: All entities (just id)
- Documentable: Abstractions only (title, description, notes)
- Timestamped: Abstractions only (logTime)
- Avoids: Basic entities pretending to have fields they reference from Abstractions

### 4. Pure Junction Tables
**Pattern**: Minimal fields (id + FKs + relationship data)
- No redundant metadata (get from related entities)
- Single responsibility (just the relationship)
- Exception: ExpectationMeasure keeps freeformNotes (target rationale)

### 5. Metrics as First-Class Entities
**Pattern**: Catalog table instead of embedded strings
- Single source of truth for unit definitions
- Enables grouping by measureType
- Supports unit conversion
- Prevents typos and inconsistencies

---

## Migration from Legacy Schemas

### From Flat Goals Table
**Before**: Single goals table with all fields
**After**: Expectation (base) + Goal (subtype) + ExpectationMeasure (targets)

```sql
-- OLD: goals table
goals:
    id, title, description, notes,
    startDate, targetDate, actionPlan,
    measurementUnit, measurementTarget,
    howGoalIsRelevant

-- NEW: 3 tables
expectations:
    id, title, detailedDescription, freeformNotes,
    expectationType, expectationImportance, expectationUrgency

goals:
    id, expectationId (FK),
    startDate, targetDate, actionPlan

expectationmeasures:
    id, expectationId (FK), measureId (FK),
    targetValue, freeformNotes
```

### From JSON measuresByUnit
**Before**: `{"km": 5.2, "minutes": 28}`
**After**: Multiple MeasuredAction records

```sql
-- OLD: actions table
actions:
    id, title, measuresByUnit: '{"km": 5.2, "minutes": 28}'

-- NEW: 2+ tables
actions:
    id, title

measuredactions:
    (id, actionId, measureId: km_uuid, value: 5.2)
    (id, actionId, measureId: min_uuid, value: 28)
```

### From 4 Value Tables
**Before**: values, majorvalues, highestordervalues, lifeareas
**After**: Single personalvalues table with valueLevel enum

```sql
-- OLD: 4 tables with different schemas
values: id, title, priority
majorvalues: id, title, priority, alignmentGuidance
highestordervalues: id, title
lifeareas: id, title, domain

-- NEW: 1 unified table
personalvalues:
    id, title, priority, valueLevel,
    lifeDomain, alignmentGuidance
```

---

## Indexes

```sql
-- Abstraction lookups
CREATE INDEX idx_expectations_type ON expectations(expectationType);
CREATE INDEX idx_measures_type ON measures(measureType);
CREATE INDEX idx_values_level ON personalvalues(valueLevel);

-- Junction table FKs (both directions)
CREATE INDEX idx_measured_actions_action ON measuredactions(actionId);
CREATE INDEX idx_measured_actions_measure ON measuredactions(measureId);
CREATE INDEX idx_expectation_measures_expectation ON expectationmeasures(expectationId);
CREATE INDEX idx_expectation_measures_measure ON expectationmeasures(measureId);
CREATE INDEX idx_goal_relevances_goal ON goalrelevances(goalId);
CREATE INDEX idx_goal_relevances_value ON goalrelevances(valueId);
CREATE INDEX idx_contributions_action ON actiongoalcontributions(actionId);
CREATE INDEX idx_contributions_goal ON actiongoalcontributions(goalId);
CREATE INDEX idx_term_assignments_term ON termgoalassignments(termId);
CREATE INDEX idx_term_assignments_goal ON termgoalassignments(goalId);

-- Subtype FKs
CREATE INDEX idx_goals_expectation ON goals(expectationId);
CREATE INDEX idx_milestones_expectation ON milestones(expectationId);
CREATE INDEX idx_obligations_expectation ON obligations(expectationId);
CREATE INDEX idx_goalterms_timeperiod ON goalterms(timePeriodId);

-- Status and temporal queries
CREATE INDEX idx_goalterms_status ON goalterms(status);
CREATE INDEX idx_timeperiods_dates ON timeperiods(startDate, endDate);
```

---

## Why This Design?

1. **Full 3NF+**: No redundancy, no anomalies, no JSON multi-valued attributes
2. **Performance**: Indexed joins outperform JSON parsing
3. **Type Safety**: Foreign keys enforce referential integrity
4. **Extensible**: Easy to add new expectation types or measure types
5. **Queryable**: All relationships are explicit and indexable
6. **Maintainable**: Clear separation of concerns across layers
7. **Semantic Clarity**: Table inheritance and separation patterns match domain concepts

---

## Comparison to Legacy Schemas

| Aspect | schema_uniform.md | SCHEMA_FINAL.md | SCHEMA_CURRENT.md (This Doc) |
|--------|------------------|-----------------|------------------------------|
| **Goal Model** | Flat goals table | Flat goals table | Expectation (base) → Goal (subtype) |
| **Values** | 4 separate tables | 1 unified table | 1 unified PersonalValue |
| **Time** | Terms table | Terms table | TimePeriod + GoalTerm |
| **Metrics** | Flat metrics | Flat metrics | Measure (abstraction) |
| **Actions** | JSON measures | 3NF normalized | MeasuredAction junction |
| **Protocols** | Monolithic Persistable | Mixed approach | Trait-based composition |
| **Junction Fields** | Full Persistable | Minimal fields | Pure (id + FKs + data) |

**Status of Legacy Docs**:
- `schema_uniform.md`: Exploratory - over-engineered with Persistable on junctions
- `SCHEMA_FINAL.md`: Aspirational - didn't implement table inheritance
- `SCHEMA_CURRENT.md`: **PRODUCTION** - matches actual Swift models

---

## SQLite Table Definitions

```sql
-- Abstractions
CREATE TABLE actions (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    durationMinutes REAL,
    startTime TEXT
);

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

CREATE TABLE personalvalues (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    priority INTEGER NOT NULL,
    valueLevel TEXT NOT NULL CHECK(valueLevel IN ('general', 'major', 'highest_order', 'life_area')),
    lifeDomain TEXT,
    alignmentGuidance TEXT
);

CREATE TABLE timeperiods (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    startDate TEXT NOT NULL,
    endDate TEXT NOT NULL
);

-- Basics
CREATE TABLE goals (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    startDate TEXT,
    targetDate TEXT,
    actionPlan TEXT,
    expectedTermLength INTEGER,
    FOREIGN KEY (expectationId) REFERENCES expectations(id)
);

CREATE TABLE milestones (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    targetDate TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id)
);

CREATE TABLE obligations (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    deadline TEXT NOT NULL,
    requestedBy TEXT,
    consequence TEXT,
    FOREIGN KEY (expectationId) REFERENCES expectations(id)
);

CREATE TABLE goalterms (
    id TEXT PRIMARY KEY,
    timePeriodId TEXT NOT NULL,
    termNumber INTEGER NOT NULL,
    theme TEXT,
    reflection TEXT,
    status TEXT CHECK(status IN ('planned', 'active', 'completed', 'delayed', 'on_hold', 'cancelled')),
    FOREIGN KEY (timePeriodId) REFERENCES timeperiods(id)
);

CREATE TABLE expectationmeasures (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    targetValue REAL NOT NULL,
    freeformNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id),
    FOREIGN KEY (measureId) REFERENCES measures(id),
    UNIQUE(expectationId, measureId)
);

-- Composits
CREATE TABLE measuredactions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    value REAL NOT NULL,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id),
    FOREIGN KEY (measureId) REFERENCES measures(id),
    UNIQUE(actionId, measureId)
);

CREATE TABLE goalrelevances (
    id TEXT PRIMARY KEY,
    goalId TEXT NOT NULL,
    valueId TEXT NOT NULL,
    alignmentStrength INTEGER,
    relevanceNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (goalId) REFERENCES goals(id),
    FOREIGN KEY (valueId) REFERENCES personalvalues(id),
    UNIQUE(goalId, valueId)
);

CREATE TABLE actiongoalcontributions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    contributionAmount REAL,
    measureId TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id),
    FOREIGN KEY (goalId) REFERENCES goals(id),
    FOREIGN KEY (measureId) REFERENCES measures(id),
    UNIQUE(actionId, goalId)
);

CREATE TABLE termgoalassignments (
    id TEXT PRIMARY KEY,
    termId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    assignmentOrder INTEGER,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (termId) REFERENCES goalterms(id),
    FOREIGN KEY (goalId) REFERENCES goals(id),
    UNIQUE(termId, goalId)
);
```

---

**Last Updated**: 2025-10-31
**Source of Truth**: `/Sources/Models/` Swift files
**Database Format**: SQLite via SQLiteData framework