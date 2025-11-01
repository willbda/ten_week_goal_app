-- Apple Data Staging Table
-- Written by Claude Code on 2025-10-31
--
-- PURPOSE: Temporary storage for raw Apple SDK responses (HealthKit, EventKit)
-- STRATEGY: Ingest → Parse → Normalize → Purge
--
-- This table stores raw JSON from Apple SDKs, allowing:
-- 1. Incremental parsing (don't block on data fetch)
-- 2. Re-parsing with improved logic (fix bugs retroactively)
-- 3. Data archaeology (can extract new measures from old data)
-- 4. Audit trail (see exactly what Apple returned)

CREATE TABLE appledata (
    -- Identity
    id TEXT PRIMARY KEY,

    -- Source classification
    sourceSDK TEXT NOT NULL CHECK(sourceSDK IN ('HealthKit', 'EventKit')),
    dataType TEXT NOT NULL,          -- 'sleep', 'calories', 'workout', 'calendar', 'reminder'

    -- Temporal metadata
    fetchedAt TEXT NOT NULL,         -- When we fetched this from Apple
    startDate TEXT NOT NULL,         -- Data period start (for queries)
    endDate TEXT NOT NULL,           -- Data period end (for queries)

    -- Raw data storage
    rawJSON TEXT NOT NULL,           -- Complete Apple SDK response (encoded as JSON string)

    -- Processing state
    parsed BOOLEAN DEFAULT 0,        -- Has this been processed into normalized measures?
    parsedAt TEXT,                   -- When we parsed it
    parseError TEXT,                 -- If parsing failed, why?

    -- Lifecycle management
    purgeAfter TEXT,                 -- Auto-delete after this date
    logTime TEXT NOT NULL            -- Record creation timestamp
);

-- Index for finding unparsed data (batch processing)
CREATE INDEX idx_appledata_unparsed ON appledata(parsed, sourceSDK, dataType)
WHERE parsed = 0;

-- Index for purge cleanup (periodic deletion)
CREATE INDEX idx_appledata_purge ON appledata(purgeAfter)
WHERE purgeAfter IS NOT NULL;

-- Index for date range queries (re-fetch detection)
CREATE INDEX idx_appledata_dates ON appledata(sourceSDK, dataType, startDate, endDate);

-- Unique constraint: Don't store duplicate fetches
CREATE UNIQUE INDEX idx_appledata_unique_fetch ON appledata(sourceSDK, dataType, startDate, endDate);

-- =============================================================================
-- USAGE EXAMPLES
-- =============================================================================

-- Insert raw HealthKit sleep data
/*
INSERT INTO appledata (id, sourceSDK, dataType, fetchedAt, startDate, endDate, rawJSON, purgeAfter, logTime)
VALUES (
    lower(hex(randomblob(16))),
    'HealthKit',
    'sleep',
    datetime('now'),
    '2025-10-30 00:00:00',
    '2025-10-31 00:00:00',
    '[{"uuid":"ABC","startDate":"2025-10-30T23:00:00Z","endDate":"2025-10-31T07:30:00Z","value":"asleep"}]',
    datetime('now', '+7 days'),  -- Purge after 7 days
    datetime('now')
);
*/

-- Find unparsed records for processing
/*
SELECT id, sourceSDK, dataType, rawJSON
FROM appledata
WHERE parsed = 0
ORDER BY fetchedAt ASC
LIMIT 100;
*/

-- Mark as parsed after successful processing
/*
UPDATE appledata
SET parsed = 1, parsedAt = datetime('now')
WHERE id = ?;
*/

-- Purge old data (run daily)
/*
DELETE FROM appledata
WHERE purgeAfter < datetime('now')
  AND parsed = 1;  -- Only delete if successfully parsed
*/

-- Count unparsed records by type
/*
SELECT sourceSDK, dataType, COUNT(*) as unparsed_count
FROM appledata
WHERE parsed = 0
GROUP BY sourceSDK, dataType;
*/

-- Find parse errors
/*
SELECT id, sourceSDK, dataType, parseError, fetchedAt
FROM appledata
WHERE parseError IS NOT NULL
ORDER BY fetchedAt DESC;
*/

-- =============================================================================
-- PURGE POLICIES
-- =============================================================================
--
-- Recommended retention periods:
-- - Sleep data: 7 days (easily re-fetchable from HealthKit)
-- - Calories: 7 days (high frequency, low value)
-- - Exercise: 14 days (might want to review details)
-- - Mindfulness: 14 days (infrequent, nice to keep)
-- - Calendar: 30 days (harder to re-fetch if events deleted)
-- - Reminders: 30 days (completion history might change)
--
-- Override: User can manually extend retention or purge immediately
--
-- =============================================================================
