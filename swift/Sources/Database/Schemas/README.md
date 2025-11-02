# Database Schema

SQL schema definition for the Ten Week Goal App database.

## File

### `schema_current.sql`
**Single source of truth** for the complete production schema.

Contains all tables organized by layer:
1. **Abstraction Layer** - Full metadata entities (DomainAbstraction)
   - Tables: actions, expectations, measures, personalValues, timePeriods
   - Fields: id + title + detailedDescription + freeformNotes + logTime + type-specific

2. **Basic Layer** - Lightweight working entities (DomainBasic)
   - Tables: goals, milestones, obligations, goalTerms, expectationMeasures
   - Fields: id + FK references + type-specific
   - Reference Abstractions via FK

3. **Composit Layer** - Pure junction tables (DomainComposit)
   - Tables: measuredActions, goalRelevances, actionGoalContributions, termGoalAssignments
   - Fields: id + multiple FK references + relationship data

4. **Staging Layer** - Apple SDK data ingestion
   - Table: appledata
   - Purpose: Raw JSON storage for HealthKit/EventKit responses

## Usage

### Create Database
```bash
sqlite3 mydb.db < schema_current.sql
```

### Verify Schema
```bash
sqlite3 mydb.db ".schema"
```

## Architecture

### Table Inheritance Pattern
```
Expectation (base)
├── Goal (subtype)
├── Milestone (subtype)
└── Obligation (subtype)
```

Each subtype has:
- Own table with FK to expectations.id
- Type-specific fields only
- Shares base fields from Expectation

### Semantic Separation
```
TimePeriod (chronological fact)
    ↓ referenced by
GoalTerm (planning scaffold)
```

TimePeriod = pure time span (start/end dates)
GoalTerm = planning semantics (theme, status, reflection)

## Key Design Principles

1. **3NF Compliance**: No redundancy, no multi-valued attributes
2. **Foreign Keys**: Enforce referential integrity
3. **UNIQUE Constraints**: Prevent duplicate relationships
4. **CHECK Constraints**: Enforce enum-like values
5. **ON DELETE Behavior**: CASCADE for cleanup, RESTRICT for catalogs

## Date Storage

All dates stored as TEXT in ISO 8601 format:
```
"2025-10-31T06:30:00Z"
```

Compatible with Swift Date encoding/decoding.

## Indexes

Indexes intentionally **not included** in these schemas.
Will be added separately once query patterns are established.

## Related Documentation

- `docs/SCHEMA_CURRENT.md` - Comprehensive schema documentation
- `Sources/Models/` - Swift model definitions (source of truth)

---

**Last Updated**: 2025-11-01
**Schema Organization**: Single file (schema_current.sql) - component files removed to prevent duplication
**Table Naming**: lowerCamelCase to match SQLiteData @Table macro convention
