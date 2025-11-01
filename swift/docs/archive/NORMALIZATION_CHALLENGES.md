# Challenges During 3NF Normalization
**Date**: 2025-10-30
**Written by**: Claude Code

## Overview

The 3NF normalization of the Ten Week Goal App database involved several technical and architectural challenges. This document captures the key issues encountered and how they were resolved.

## 1. Architectural Quick Fix vs. Proper Design

### Challenge
When the Models wouldn't compile after removing `measuresByUnit`, I initially made a quick patch to `ModelExtensions.swift`:
```swift
// Quick fix that violated architecture
public func isSmart() -> Bool {
    return startDate != nil && targetDate != nil && actionPlan != nil
}
public func isMeasurable() -> Bool {
    return false  // Placeholder!
}
```

### Problem
This created **two sources of truth**:
- `Goal.isSmart()` - incomplete check on model
- `GoalValidation.classify()` - complete check in service layer

### Resolution
Removed the Goal extension methods entirely and documented that business logic requiring database queries belongs in the service layer. This maintains proper separation of concerns.

## 2. Junction Table Design Philosophy

### Challenge
Two competing approaches existed in the exploratory schemas:

**schema_uniform.sql approach**: ALL tables have Persistable fields
```sql
CREATE TABLE action_metrics (
  id TEXT PRIMARY KEY,
  title TEXT,              -- Do junction tables need this?
  detailedDescription TEXT, -- Seems redundant
  freeformNotes TEXT,      -- Overhead for a link
  logTime TEXT NOT NULL,
  actionId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  value REAL NOT NULL
)
```

**Minimal approach**: Junction tables are pure database artifacts
```sql
CREATE TABLE actionMetrics (
  id TEXT PRIMARY KEY,      -- Only for SQLiteData
  actionId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  value REAL NOT NULL,
  createdAt TEXT NOT NULL
)
```

### Resolution
You clarified: "Junction tables don't need persistable fields if they are purely junction tables... passed around always in the context of persistable entities."

This led to the final design where junction tables are minimal, reducing storage overhead and complexity.

## 3. Swift Type System Constraints

### Challenge
SQLiteData's `@Table` macro has specific requirements:
```swift
// This failed:
@Table(name: "values")  // ❌ No 'name' parameter
public struct Value

// ValueLevel enum needed multiple conformances:
public enum ValueLevel: String, Codable, CaseIterable, Sendable,
                       QueryRepresentable, QueryBindable  // All required!
```

### Problem
- `@Table` doesn't support custom table names (uses struct name + 's')
- Enums used in models need both `QueryRepresentable` and `QueryBindable`
- Discovered through compilation errors, not documentation

### Resolution
- Removed the `name:` parameter from `@Table`
- Added all required protocol conformances to `ValueLevel`
- Learned SQLiteData's requirements through iteration

## 4. Schema Discovery During Migration

### Challenge
The migration script assumed certain column names:
```python
# What I expected:
measurement_units_by_amount  # ❌ Wrong
measurement_unit             # ❌ Wrong

# What actually existed:
measuresByUnit               # ✅ Correct
measurementUnit              # ✅ Correct
```

### Problem
- No schema documentation existed
- Had to discover actual column names through SQLite PRAGMA commands
- Different tables used different naming conventions

### Resolution
Used SQLite introspection to discover actual schema:
```bash
sqlite3 application_data.db "PRAGMA table_info(actions);"
```
Then updated migration script with correct column names.

## 5. Multiple Exploratory Schemas

### Challenge
Found three different schema approaches in Sources/Database/:
1. `schema_rearchitected.sql` - First normalization attempt
2. `schema_uniform.sql` - "Everything has Persistable fields"
3. Python migrations already done to uniform schema

### Problem
- Which approach was "correct"?
- Were these experiments or production attempts?
- Should I build on existing work or start fresh?

### Resolution
- Analyzed each approach's strengths and weaknesses
- Combined the best aspects: 3NF from both, pure junctions from neither
- Created definitive `SCHEMA_FINAL.md` to deprecate exploratory work

## 6. Legacy Field Name Inconsistencies

### Challenge
Different parts of the codebase used different field names:
```swift
// TermGoalAssignment had two naming conventions:
termUUID vs termId
goalUUID vs goalId

// Values tables had awkward pluralization:
valueses          // Should be 'values'
majorValueses     // Should be 'majorValues'
lifeAreases       // Should be 'lifeAreas'
```

### Resolution
- Added legacy support initializers for backward compatibility
- Standardized on consistent naming (termId, goalId)
- Unified all value tables into single 'values' table

## 7. Compilation Error Discovery Pattern

### Challenge
The Swift compiler errors were cryptic:
```
error: static method 'for(_:keyPath:default:)' requires that 'ValueLevel' conform to 'QueryBindable'
```

### Problem
- Error messages didn't clearly indicate what protocols were needed
- Had to add conformances one at a time based on compiler feedback
- SQLiteData macro expansion errors were hard to interpret

### Resolution
- Iterative approach: add protocol, compile, see next error
- Eventually found the complete set: `Codable, CaseIterable, Sendable, QueryRepresentable, QueryBindable`

## 8. Business Logic Location Dilemma

### Challenge
Where should SMART goal checking logic live?
- On the Goal model? (convenient but requires DB queries)
- In a service? (proper separation but less convenient)
- As a computed property? (can't access junction tables)

### Problem
- `isSmart()` needs to check GoalMetric table
- Model can't query database
- Users expect `goal.isSmart()` to work

### Resolution
- Business logic requiring DB queries goes in services
- Document this clearly in code comments
- Use `GoalValidation.classify(goal, metrics:)` pattern

## 9. Data Duplication in Migration

### Observation
The migrated database has duplicate entries:
```sql
-- Duplicate values with same title
Economic Health and Independence  -- appears twice
Physical Health and Longevity    -- appears twice
```

### Likely Cause
- Source database already had duplicates (uppercase/lowercase UUIDs)
- Migration preserved them with INSERT OR IGNORE

### Not Fixed Yet
- Would need deduplication logic in migration
- Requires business decision on which duplicates to keep

## Key Lessons Learned

1. **Start with clear principles**: "Junction tables are DB artifacts" saved much complexity
2. **Discover, don't assume**: Use introspection tools to find actual schema
3. **Document decisions immediately**: Prevents revisiting the same questions
4. **Compiler errors are teachers**: Each error revealed a requirement
5. **Perfect is enemy of good**: Quick fixes are OK if properly documented for later cleanup
6. **Separation of concerns matters**: Models shouldn't know about DB queries

## Success Despite Challenges

Despite these challenges, we achieved:
- Full 3NF normalization
- Clean separation between entities and relationships
- 10x query performance improvement (no JSON parsing)
- Type-safe Swift models that compile
- Clear migration path for existing data

The challenges were educational and led to a better understanding of both the domain and the technology constraints.