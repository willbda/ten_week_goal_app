# Final Database Schema - 3NF Normalized
**Status**: PRODUCTION
**Date**: 2025-10-30
**Written by**: Claude Code

## Executive Summary

This is the **definitive schema** for the Ten Week Goal App, implementing full 3NF normalization with:
- No JSON fields (all atomic values)
- Pure junction tables (minimal fields)
- Unified values table with enum discrimination
- Metrics as first-class entities
- Proper foreign key constraints

## Design Principles

1. **Entities have Persistable fields** - Business objects with meaning
2. **Junction tables are pure** - Database artifacts with minimal fields
3. **No multi-valued attributes** - Everything atomic
4. **Single source of truth** - No redundant data
5. **Query-optimized** - Indexed foreign keys, no JSON parsing

## Core Entities (Persistable)

All entities share these base fields:
- `id: UUID` - Primary key
- `title: String?` - Human-readable name
- `detailedDescription: String?` - Fuller explanation
- `freeformNotes: String?` - Additional notes
- `logTime: Date` - Creation timestamp

### Actions
**Purpose**: Record what was done (past-oriented)
```sql
actions:
  [Persistable fields]
  durationMinutes: Double?
  startTime: Date?
```

### Goals
**Purpose**: Define what to achieve (future-oriented)
```sql
goals:
  [Persistable fields]
  startDate: Date?
  targetDate: Date?
  actionPlan: String?       -- How to achieve it
  expectedTermLength: Int?  -- Planning horizon
```

### Values
**Purpose**: Personal values and life areas (unified table)
```sql
values:
  [Persistable fields]
  priority: Int                    -- 1-100 (lower = higher priority)
  valueLevel: String               -- 'general'|'major'|'highest_order'|'life_area'
  lifeDomain: String?              -- Category
  alignmentGuidance: String?       -- For major values
```

### Terms
**Purpose**: Planning periods (10-week cycles)
```sql
terms:
  [Persistable fields]
  termNumber: Int
  startDate: Date
  targetDate: Date
  theme: String?
  reflection: String?
```

### Metrics
**Purpose**: Catalog of measurement units
```sql
metrics:
  [Persistable fields]
  unit: String                     -- 'km', 'hours', 'occasions'
  metricType: String              -- 'distance', 'time', 'count'
  canonicalUnit: String?          -- For conversions
  conversionFactor: Double?       -- To canonical
```

## Junction Tables (Pure Database Artifacts)

Junction tables have minimal fields - just what's needed for the relationship.

### ActionMetric
**Purpose**: Link actions to their measurements
```sql
actionMetrics:
  id: UUID                        -- Required by SQLiteData
  actionId: UUID                  -- FK to actions
  metricId: UUID                  -- FK to metrics
  value: Double                   -- Measured value
  recordedAt: Date               -- When recorded
  UNIQUE(actionId, metricId)
```

### GoalMetric
**Purpose**: Define goal targets (what makes it measurable)
```sql
goalMetrics:
  id: UUID
  goalId: UUID                    -- FK to goals
  metricId: UUID                  -- FK to metrics
  targetValue: Double             -- Target to achieve
  [Optional Persistable fields for notes about the target]
  UNIQUE(goalId, metricId)
```

### GoalRelevance
**Purpose**: Link goals to values they serve
```sql
goalRelevances:
  id: UUID
  goalId: UUID                    -- FK to goals
  valueId: UUID                   -- FK to values
  alignmentStrength: Int?         -- 1-10 scale
  relevanceNotes: String?         -- Explanation
  createdAt: Date
  UNIQUE(goalId, valueId)
```

### ActionGoalContribution
**Purpose**: Track action progress toward goals
```sql
actionGoalContributions:
  id: UUID
  actionId: UUID                  -- FK to actions
  goalId: UUID                    -- FK to goals
  contributionAmount: Double?     -- How much contributed
  metricId: UUID?                 -- Which metric
  createdAt: Date
  UNIQUE(actionId, goalId)
```

### TermGoalAssignment
**Purpose**: Assign goals to terms
```sql
termGoalAssignments:
  id: UUID
  termId: UUID                    -- FK to terms
  goalId: UUID                    -- FK to goals
  assignmentOrder: Int?           -- Display order
  createdAt: Date
  UNIQUE(termId, goalId)
```

## Query Examples

### Find all running actions (no JSON parsing!)
```sql
SELECT a.title, am.value as km, a.logTime
FROM actions a
JOIN actionMetrics am ON a.id = am.actionId
JOIN metrics m ON am.metricId = m.id
WHERE m.unit = 'km'
ORDER BY am.value DESC;
```

### Calculate goal progress
```sql
SELECT
  g.title,
  gm.targetValue,
  SUM(ac.contributionAmount) as actual,
  (SUM(ac.contributionAmount) / gm.targetValue * 100) as percentage
FROM goals g
JOIN goalMetrics gm ON g.id = gm.goalId
LEFT JOIN actionGoalContributions ac ON g.id = ac.goalId
GROUP BY g.id, gm.targetValue;
```

### Find goals aligned with a value
```sql
SELECT g.title, gr.alignmentStrength
FROM goals g
JOIN goalRelevances gr ON g.id = gr.goalId
WHERE gr.valueId = ?
ORDER BY gr.alignmentStrength DESC;
```

## Migration Path

1. **From JSON measuresByUnit**:
   - Parse JSON → Create Metric records → Create ActionMetric records

2. **From 4 value tables**:
   - UNION all → Single values table with valueLevel field

3. **From flat Goal fields**:
   - measurementUnit/Target → GoalMetric records
   - howGoalIsRelevant → GoalRelevance records

## Swift Model Mapping

| Database Table | Swift Model | Protocol |
|---------------|-------------|----------|
| actions | Action | Persistable |
| goals | Goal | Persistable |
| values | Value | Persistable |
| terms | Term | Persistable |
| metrics | Metric | Persistable |
| actionMetrics | ActionMetric | Identifiable |
| goalMetrics | GoalMetric | Persistable |
| goalRelevances | GoalRelevance | Identifiable |
| actionGoalContributions | ActionGoalContribution | Identifiable |
| termGoalAssignments | TermGoalAssignment | Identifiable |

## Indexes

```sql
-- Metric lookups
CREATE INDEX idx_action_metrics_action ON actionMetrics(actionId);
CREATE INDEX idx_action_metrics_metric ON actionMetrics(metricId);
CREATE INDEX idx_goal_metrics_goal ON goalMetrics(goalId);
CREATE INDEX idx_goal_metrics_metric ON goalMetrics(metricId);

-- Relationship queries
CREATE INDEX idx_goal_relevance_goal ON goalRelevances(goalId);
CREATE INDEX idx_goal_relevance_value ON goalRelevances(valueId);
CREATE INDEX idx_contributions_action ON actionGoalContributions(actionId);
CREATE INDEX idx_contributions_goal ON actionGoalContributions(goalId);
CREATE INDEX idx_term_assignments_term ON termGoalAssignments(termId);
CREATE INDEX idx_term_assignments_goal ON termGoalAssignments(goalId);

-- Type discrimination
CREATE INDEX idx_values_level ON values(valueLevel);
CREATE INDEX idx_metrics_type ON metrics(metricType);
```

## Why This Design?

1. **Full 3NF**: No redundancy, no anomalies
2. **Performance**: Indexed joins beat JSON parsing
3. **Type Safety**: Foreign keys ensure integrity
4. **Extensible**: Easy to add new metric types
5. **Queryable**: All relationships explicit
6. **Maintainable**: Clear separation of concerns

## Deprecated Files

The following exploratory schemas are deprecated:
- `schema_rearchitected.sql` - Early attempt, still had flat fields
- `schema_uniform.sql` - Over-engineered with full Persistable on junctions
- `schema_uniform.md` - Documentation for uniform approach
- Python migration scripts - Replaced by Swift implementation

This schema is implemented in production Swift models (2025-10-30).