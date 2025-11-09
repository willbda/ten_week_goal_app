-- expectations.sql
-- Database schema for expectations (goals, milestones, obligations, aspirations)
--
-- Written by Claude Code on 2025-10-22
--
-- Architecture:
-- - Single table stores all expectation types
-- - expectation_type column for efficient filtering
-- - data column stores JSON blob (JSONB in SQLite 3.45+)
-- - Separate uuid_id for primary key (extracted from JSON for efficiency)
--
-- Note: SQLite 3.45+ automatically uses JSONB (binary) format for JSON columns,
-- which is more space-efficient and faster to query than text JSON.

CREATE TABLE IF NOT EXISTS expectations (
    -- Primary key (extracted from JSON for efficiency)
    uuid_id TEXT PRIMARY KEY NOT NULL,

    -- Type discriminator for filtering
    expectation_type TEXT NOT NULL CHECK (
        expectation_type IN ('goal', 'milestone', 'obligation', 'aspiration')
    ),

    -- Full expectation data as JSON
    -- In SQLite 3.45+, this is automatically stored as JSONB (binary format)
    -- Contains the complete enum: {"type": "goal", "data": {...}}
    data TEXT NOT NULL,

    -- Timestamps
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indexes for efficient querying

-- Filter by type (most common query)
CREATE INDEX IF NOT EXISTS idx_expectations_type
    ON expectations(expectation_type);

-- Sort by creation date
CREATE INDEX IF NOT EXISTS idx_expectations_created
    ON expectations(created_at DESC);

-- Query by UUID (already covered by PRIMARY KEY, but explicit for clarity)
-- (SQLite automatically creates index for PRIMARY KEY)

-- ===== FUTURE OPTIMIZATION =====
-- If JSON queries become slow, add generated columns for common fields:
--
-- ALTER TABLE expectations ADD COLUMN title TEXT
--     GENERATED ALWAYS AS (json_extract(data, '$.data.title')) STORED;
--
-- ALTER TABLE expectations ADD COLUMN target_date TEXT
--     GENERATED ALWAYS AS (json_extract(data, '$.data.targetDate')) STORED;
--
-- ALTER TABLE expectations ADD COLUMN priority INTEGER
--     GENERATED ALWAYS AS (json_extract(data, '$.data.priority')) STORED;
--
-- CREATE INDEX idx_expectations_target_date ON expectations(target_date);
-- CREATE INDEX idx_expectations_priority ON expectations(priority DESC);
--
-- This would allow fast queries like:
-- SELECT * FROM expectations WHERE target_date < '2025-12-31' ORDER BY priority DESC;
-- ===== END FUTURE OPTIMIZATION =====
