# Database Schemas

SQL schema definitions for the Ten Week Goal App database.

## Files

### `schema_current.sql`
**Complete production schema** matching Swift models as of 2025-10-31.
Contains all tables with foreign keys and constraints. Use this for:
- Creating new databases
- Reference documentation
- Understanding complete schema structure

### Layer-Specific Files

**`abstractions.sql`**
- Entities with full metadata (DomainAbstraction)
- Tables: actions, expectations, measures, personalvalues, timeperiods
- 5 base fields + type-specific fields

**`basics.sql`**
- Lightweight working entities (DomainBasic)
- Tables: goals, milestones, obligations, goalterms, expectationmeasures
- Reference Abstractions via FK

**`composits.sql`**
- Pure junction tables (DomainComposit)
- Tables: measuredactions, goalrelevances, actiongoalcontributions, termgoalassignments
- Minimal fields (id + FKs + relationship data)

## Usage

### Create Complete Database
```bash
sqlite3 mydb.db < schema_current.sql
```

### Create Layer-by-Layer
```bash
sqlite3 mydb.db < abstractions.sql
sqlite3 mydb.db < basics.sql
sqlite3 mydb.db < composits.sql
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

**Last Updated**: 2025-10-31
**Swift Models Version**: Current production models
