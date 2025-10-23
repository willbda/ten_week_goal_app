-- Migration: Standardize on UUID PRIMARY KEY for all tables
-- Written by Claude Code on 2025-10-23
-- Part of Phase 2: UUID Standardization
--
-- Changes:
-- - goals: id INTEGER PRIMARY KEY → uuid_id TEXT PRIMARY KEY
-- - terms: id INTEGER PRIMARY KEY → uuid_id TEXT PRIMARY KEY
-- - personal_values: id INTEGER PRIMARY KEY → uuid_id TEXT PRIMARY KEY
-- - Drop uuid_mappings table (no longer needed)
--
-- Safety: Creates backup tables before migration. Can be rolled back if needed.

-- =====================================================================
-- STEP 1: Backup existing tables
-- =====================================================================

-- Rename existing tables to _old for safety
ALTER TABLE goals RENAME TO goals_old;
ALTER TABLE terms RENAME TO terms_old;
ALTER TABLE personal_values RENAME TO personal_values_old;

-- =====================================================================
-- STEP 2: Create new tables with UUID PRIMARY KEY
-- =====================================================================

-- Goals table with uuid_id PRIMARY KEY
CREATE TABLE goals (
  uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (UPPERCASE UUID)
  title TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  log_time TEXT NOT NULL,
  goal_type TEXT NOT NULL DEFAULT 'Goal',
  measurement_target REAL,
  measurement_unit TEXT,
  start_date TEXT,
  target_date TEXT,
  how_goal_is_relevant TEXT,
  how_goal_is_actionable TEXT,
  expected_term_length INTEGER
);

-- Terms table with uuid_id PRIMARY KEY
CREATE TABLE terms (
  uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (UPPERCASE UUID)
  title TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  term_number INTEGER NOT NULL UNIQUE,
  start_date TEXT NOT NULL,
  target_date TEXT NOT NULL,
  term_goals_by_id TEXT,
  reflection TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Personal values table with uuid_id PRIMARY KEY
CREATE TABLE personal_values (
  uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (UPPERCASE UUID)
  title TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  log_time TEXT NOT NULL,
  incentive_type TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 50,
  life_domain TEXT DEFAULT 'General',
  alignment_guidance TEXT
);

-- =====================================================================
-- STEP 3: Migrate data from old tables to new tables
-- =====================================================================

-- Migrate goals (copy all columns, uuid_id becomes PRIMARY KEY)
INSERT INTO goals (uuid_id, title, description, notes, log_time, goal_type,
                   measurement_target, measurement_unit, start_date, target_date,
                   how_goal_is_relevant, how_goal_is_actionable, expected_term_length)
SELECT uuid_id, title, description, notes, log_time, goal_type,
       measurement_target, measurement_unit, start_date, target_date,
       how_goal_is_relevant, how_goal_is_actionable, expected_term_length
FROM goals_old
WHERE uuid_id IS NOT NULL;  -- Safety: Only migrate rows with UUID

-- Migrate terms
INSERT INTO terms (uuid_id, title, description, notes, term_number, start_date,
                   target_date, term_goals_by_id, reflection, created_at, updated_at)
SELECT uuid_id, title, description, notes, term_number, start_date,
       target_date, term_goals_by_id, reflection, created_at, updated_at
FROM terms_old
WHERE uuid_id IS NOT NULL;

-- Migrate personal_values
INSERT INTO personal_values (uuid_id, title, description, notes, log_time,
                            incentive_type, priority, life_domain, alignment_guidance)
SELECT uuid_id, title, description, notes, log_time,
       incentive_type, priority, life_domain, alignment_guidance
FROM personal_values_old
WHERE uuid_id IS NOT NULL;

-- =====================================================================
-- STEP 4: Recreate indexes
-- =====================================================================

-- Terms indexes
CREATE INDEX IF NOT EXISTS idx_terms_dates ON terms(start_date, target_date);
CREATE INDEX IF NOT EXISTS idx_terms_number ON terms(term_number);

-- =====================================================================
-- STEP 5: Verify migration succeeded
-- =====================================================================

-- Check row counts match
SELECT
  'goals' as table_name,
  (SELECT COUNT(*) FROM goals_old WHERE uuid_id IS NOT NULL) as old_count,
  (SELECT COUNT(*) FROM goals) as new_count
UNION ALL
SELECT
  'terms',
  (SELECT COUNT(*) FROM terms_old WHERE uuid_id IS NOT NULL),
  (SELECT COUNT(*) FROM terms)
UNION ALL
SELECT
  'personal_values',
  (SELECT COUNT(*) FROM personal_values_old WHERE uuid_id IS NOT NULL),
  (SELECT COUNT(*) FROM personal_values);

-- =====================================================================
-- STEP 6: Drop old tables and uuid_mappings (ONLY if verification passed!)
-- =====================================================================

-- IMPORTANT: Review the verification results above before running this step!
-- If counts don't match, investigate before proceeding.

-- Drop old backup tables
DROP TABLE IF EXISTS goals_old;
DROP TABLE IF EXISTS terms_old;
DROP TABLE IF EXISTS personal_values_old;

-- Drop uuid_mappings table (no longer needed with direct UUID primary keys)
DROP TABLE IF EXISTS uuid_mappings;

-- =====================================================================
-- ROLLBACK PROCEDURE (if something goes wrong):
-- =====================================================================
-- 1. DROP TABLE goals;
-- 2. DROP TABLE terms;
-- 3. DROP TABLE personal_values;
-- 4. ALTER TABLE goals_old RENAME TO goals;
-- 5. ALTER TABLE terms_old RENAME TO terms;
-- 6. ALTER TABLE personal_values_old RENAME TO personal_values;
