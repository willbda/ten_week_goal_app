# Archived Exploratory Schemas
**Status**: DEPRECATED - For historical reference only
**Current Schema**: See `SCHEMA_FINAL.md` and `schema_3nf_final.sql`

## Overview

This document explains the exploratory schemas that were created during the normalization process. These files are kept for historical reference but should NOT be used for implementation.

## Exploratory Attempts

### 1. schema_rearchitected.sql (2025-10-26)
**Status**: DEPRECATED - Early attempt

**What it tried**:
- First attempt at removing JSON
- Created metrics as entities
- Started normalizing relationships

**Problems**:
- Goals still had flat fields (measurementUnit, measurementTarget)
- Included computed columns (isSmart)
- Not fully normalized

**Lessons learned**:
- Computed fields don't belong in schema
- All measurements should be in junction tables

### 2. schema_uniform.sql (2025-10-27)
**Status**: DEPRECATED - Over-engineered

**What it tried**:
- "Uniform Base" principle - ALL tables have Persistable fields
- Even junction tables had title, description, notes, logTime
- Philosophical purity over practicality

**Problems**:
- Unnecessary overhead on junction tables
- Junction tables don't need business fields
- Storage waste and complexity

**Lessons learned**:
- Junction tables are pure database artifacts
- Minimal fields reduce complexity
- Don't over-engineer for consistency

### 3. migrate_to_uniform.py (2025-10-27)
**Status**: DEPRECATED - Replaced by migrate_to_3nf_final.py

**What it did**:
- Migrated to the uniform schema
- Created application_data_uniform.db
- Successfully extracted JSON

**Why deprecated**:
- Based on flawed uniform schema
- Junction tables too heavy
- Replaced by cleaner 3NF migration

## Current Production Schema

### schema_3nf_final.sql ✅ USE THIS
**Status**: PRODUCTION

**Key principles**:
- Pure junction tables (minimal fields)
- No JSON anywhere
- Proper foreign keys
- Optimized indexes

### migrate_to_3nf_final.py ✅ USE THIS
**Status**: PRODUCTION

**What it does**:
- Migrates to clean 3NF schema
- Creates proposed_3nf.db
- Handles all data transformation

## File Disposition

### Keep for Reference
- schema_rearchitected.sql - Shows evolution
- schema_uniform.sql - Documents what not to do
- MIGRATION_SUMMARY.md - Historical migration notes
- MANUAL_CORRECTIONS.md - Data cleanup history

### Active Production Files
- SCHEMA_FINAL.md - Definitive documentation
- schema_3nf_final.sql - Production schema
- migrate_to_3nf_final.py - Production migration
- proposed_3nf.db - Migrated data

## Why We Keep These Files

1. **Learning Trail** - Shows the evolution of thinking
2. **Anti-patterns** - Documents what didn't work
3. **Migration History** - Tracks data transformations
4. **Decision Rationale** - Explains why we chose the final design

## Important Note

**DO NOT USE EXPLORATORY SCHEMAS FOR NEW WORK**

All new development should use:
- `schema_3nf_final.sql` for database structure
- `SCHEMA_FINAL.md` for documentation
- `proposed_3nf.db` for test data

The exploratory schemas are kept only to understand how we arrived at the final design.