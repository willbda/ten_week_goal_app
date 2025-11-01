# Uniform Database Schema Design
**Written by Claude Code on 2025-10-27**

## Design Principle: Uniform Base + Specific Extensions

All first-class entities share identical base fields (Persistable contract).
Each entity type adds only fields specific to its domain purpose.

---

## Base Fields (All Entities)

```
┌─────────────────────────────────────┐
│ PERSISTABLE BASE                    │
├─────────────────────────────────────┤
│ id                TEXT PRIMARY KEY  │
│ title             TEXT              │
│ detailedDescription TEXT            │
│ freeformNotes     TEXT              │
│ logTime           TEXT NOT NULL     │
└─────────────────────────────────────┘
```

---

## Actions (Past-Oriented: What Was Done)

**Responsibility**: Describes what was done (title, timing)

```
┌─────────────────────────────────────┐
│ actions                             │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ startTime         TEXT              │
│ durationMinutes   REAL              │
└─────────────────────────────────────┘
```

### action_metrics (Line Items)

**Responsibility**: Links actions to measurements (many per action)

```
┌─────────────────────────────────────┐
│ action_metrics                      │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ actionId (FK)     TEXT NOT NULL     │
│ metricId (FK)     TEXT NOT NULL     │
│ value             REAL NOT NULL     │
│ recordedAt        TEXT NOT NULL     │
└─────────────────────────────────────┘
```

---

## Goals (Future-Oriented: What To Achieve)

**Responsibility**: Describes what to achieve (title, timeframe)

```
┌─────────────────────────────────────┐
│ goals                               │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ startDate         TEXT              │
│ targetDate        TEXT              │
│ goalType          TEXT DEFAULT 'goal'│
└─────────────────────────────────────┘
```

**goalType**: 'goal' | 'milestone'

### goal_metrics (How Goal Is Actionable)

**Responsibility**: Defines measurement structure - what metrics, what targets

```
┌─────────────────────────────────────┐
│ goal_metrics                        │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ goalId (FK)       TEXT NOT NULL     │
│ metricId (FK)     TEXT NOT NULL     │
│ targetValue       REAL NOT NULL     │
│ notes             TEXT              │
└─────────────────────────────────────┘
```

### goal_relevance (How Goal Is Relevant)

**Responsibility**: Links goals to values with explanation

```
┌─────────────────────────────────────┐
│ goal_relevance                      │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ goalId (FK)       TEXT NOT NULL     │
│ valueId (FK)      TEXT NOT NULL     │
│ alignmentStrength INTEGER           │
│ relevanceNotes    TEXT              │
└─────────────────────────────────────┘
```

---

## Values (Intrinsic Priorities & Life Areas)

```
┌─────────────────────────────────────┐
│ values                              │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ priority          INTEGER           │
│ valueLevel        TEXT              │
│ lifeDomain        TEXT              │
│ alignmentGuidance TEXT              │
└─────────────────────────────────────┘
```

**valueLevel**: 'general' | 'major' | 'highest_order' | 'life_area'

---

## Terms (Time Horizons: 10-Week Planning Periods)

**Responsibility**: Describes planning periods (10-week terms)

```
┌─────────────────────────────────────┐
│ terms                               │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ termNumber        INTEGER NOT NULL  │
│ startDate         TEXT NOT NULL     │
│ targetDate        TEXT NOT NULL     │
│ theme             TEXT              │
│ reflection        TEXT               │
└─────────────────────────────────────┘
```

### term_goal_assignments

**Responsibility**: Links terms to goals

```
┌─────────────────────────────────────┐
│ term_goal_assignments               │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ termId (FK)       TEXT NOT NULL     │
│ goalId (FK)       TEXT NOT NULL     │
│ assignmentOrder   INTEGER           │
└─────────────────────────────────────┘
```

---

## Metrics (Catalog of Units of Measure)

**Responsibility**: Defines available units for measurement

```
┌─────────────────────────────────────┐
│ metrics                             │
├─────────────────────────────────────┤
│ [PERSISTABLE BASE]                  │
├─────────────────────────────────────┤
│ unit              TEXT NOT NULL     │
│ metricType        TEXT NOT NULL     │
│ canonicalUnit     TEXT              │
└─────────────────────────────────────┘
```

**metricType**: 'distance' | 'time' | 'count' | 'mass'
**Examples**:
- (id: uuid, title: "Distance", unit: "km", metricType: "distance", canonicalUnit: "meters")
- (id: uuid, title: "Duration", unit: "hours", metricType: "time", canonicalUnit: "seconds")
- (id: uuid, title: "Books Read", unit: "books", metricType: "count", canonicalUnit: null)

---

## Entity Relationships

```
                  ┌──────────────┐
                  │   metrics    │ (catalog of units/measures)
                  └──────────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
    ┌─────────────────┐   ┌─────────────────┐
    │ action_metrics  │   │  goal_metrics   │
    └─────────────────┘   └─────────────────┘
              │                     │
    ┌─────────────────┐   ┌─────────────────┐
    │    actions      │   │     goals       │
    └─────────────────┘   └─────────────────┘
                                   │
                          ┌────────┴────────┐
                          │                 │
                ┌─────────────────┐  ┌──────────────────┐
                │ goal_relevance  │  │ term_goal_assigns│
                └─────────────────┘  └──────────────────┘
                          │                 │
                  ┌───────────┐      ┌─────────┐
                  │  values   │      │  terms  │
                  └───────────┘      └─────────┘
```

**Relationship Summary**:
- Actions → action_metrics → metrics (what was measured)
- Goals → goal_metrics → metrics (what to measure)
- Goals → goal_relevance → values (why relevant)
- Terms → term_goal_assigns → goals (what to achieve this term)

---

## Key Design Decisions

1. **Single Responsibility**: Each table handles one relationship only
   - Actions describe actions (not measurements)
   - Goals describe goals (not measurements or relevance explanations)
   - Junction tables handle relationships

2. **Uniform Base**: All entities (including junction tables) share Persistable fields

3. **No Flat Text for Structure**:
   - "How goal is actionable" → `goal_metrics` table (structured measurement targets)
   - "How goal is relevant" → `goal_relevance` table (structured value linkages)

4. **Type Discrimination via Fields**: `goalType`, `valueLevel` (not `polymorphicSubtype`)

5. **Metrics Catalog**: `metrics` table as first-class catalog (not JSON dictionaries)

---

## Comparison: Before vs After

### Before (Current)
- Actions: 8 fields (including `measuresByUnit` JSON)
- Goals: 13 fields (including `howGoalIsRelevant`, `howGoalIsActionable` flat text)
- Values: 4 separate tables with different schemas
- Terms: 11 fields (including `polymorphicSubtype`)

### After (Proposed)
**First-Class Entities**:
- Actions: 7 fields (5 base + 2 specific)
- Goals: 8 fields (5 base + 3 specific)
- Values: 9 fields (5 base + 4 specific)
- Terms: 10 fields (5 base + 5 specific)
- Metrics: 8 fields (5 base + 3 specific)

**Junction Tables** (all with Persistable base):
- action_metrics: 9 fields (5 base + 4 relationship)
- goal_metrics: 8 fields (5 base + 3 relationship)
- goal_relevance: 9 fields (5 base + 4 relationship)
- term_goal_assignments: 8 fields (5 base + 3 relationship)

**Result**: All tables have identical base structure, clear single responsibility
