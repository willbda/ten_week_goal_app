-- Add UUID columns to all tables and generate UUIDs for existing records
-- Written by Claude Code on 2025-10-19

BEGIN TRANSACTION;

-- ============================================================
-- ACTIONS TABLE
-- ============================================================
ALTER TABLE actions ADD COLUMN uuid_id TEXT;

UPDATE actions SET uuid_id = lower(
    hex(randomblob(4)) || '-' ||
    hex(randomblob(2)) || '-' ||
    '4' || substr(hex(randomblob(2)), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' ||
    hex(randomblob(6))
) WHERE uuid_id IS NULL;

CREATE UNIQUE INDEX idx_actions_uuid ON actions(uuid_id);

-- ============================================================
-- GOALS TABLE
-- ============================================================
ALTER TABLE goals ADD COLUMN uuid_id TEXT;

UPDATE goals SET uuid_id = lower(
    hex(randomblob(4)) || '-' ||
    hex(randomblob(2)) || '-' ||
    '4' || substr(hex(randomblob(2)), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' ||
    hex(randomblob(6))
) WHERE uuid_id IS NULL;

CREATE UNIQUE INDEX idx_goals_uuid ON goals(uuid_id);

-- ============================================================
-- PERSONAL_VALUES TABLE
-- ============================================================
ALTER TABLE personal_values ADD COLUMN uuid_id TEXT;

UPDATE personal_values SET uuid_id = lower(
    hex(randomblob(4)) || '-' ||
    hex(randomblob(2)) || '-' ||
    '4' || substr(hex(randomblob(2)), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' ||
    hex(randomblob(6))
) WHERE uuid_id IS NULL;

CREATE UNIQUE INDEX idx_personal_values_uuid ON personal_values(uuid_id);

-- ============================================================
-- TERMS TABLE
-- ============================================================
ALTER TABLE terms ADD COLUMN uuid_id TEXT;

UPDATE terms SET uuid_id = lower(
    hex(randomblob(4)) || '-' ||
    hex(randomblob(2)) || '-' ||
    '4' || substr(hex(randomblob(2)), 2) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' ||
    hex(randomblob(6))
) WHERE uuid_id IS NULL;

CREATE UNIQUE INDEX idx_terms_uuid ON terms(uuid_id);

COMMIT;
