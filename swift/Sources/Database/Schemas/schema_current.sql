-- ABSTRACTION LAYER SCHEMA
-- Written by Claude Code on 2025-10-31
--
-- DomainAbstraction = Identifiable + Documentable + Timestamped
-- Full metadata entities with id, title, detailedDescription, freeformNotes, logTime

-- Actions: Record what was done (past-oriented)
CREATE TABLE actions (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    durationMinutes REAL,
    startTime TEXT
);

-- Expectations: Base table for goals/milestones/obligations (table inheritance)
CREATE TABLE expectations (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    expectationType TEXT NOT NULL CHECK(expectationType IN ('goal', 'milestone', 'obligation')),
    expectationImportance INTEGER NOT NULL,
    expectationUrgency INTEGER NOT NULL
);

-- Measures: Catalog of measurement units
CREATE TABLE measures (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    unit TEXT NOT NULL,
    measureType TEXT NOT NULL,
    canonicalUnit TEXT,
    conversionFactor REAL
);

-- PersonalValues: Unified values and life areas
CREATE TABLE personalValues (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    priority INTEGER NOT NULL,
    valueLevel TEXT NOT NULL CHECK(valueLevel IN ('general', 'major', 'highest_order', 'life_area')),
    lifeDomain TEXT,
    alignmentGuidance TEXT
);

-- TimePeriods: Pure chronological boundaries (no planning semantics)
CREATE TABLE timePeriods (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    startDate TEXT NOT NULL,
    endDate TEXT NOT NULL,
    CHECK(startDate <= endDate)
);
-- BASIC LAYER SCHEMA
-- Written by Claude Code on 2025-10-31
--
-- DomainBasic = Identifiable
-- Lightweight working entities with id + FK references + type-specific fields

-- Goals: Expectation subtype with date ranges and action plans
CREATE TABLE goals (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    startDate TEXT,
    targetDate TEXT,
    actionPlan TEXT,
    expectedTermLength INTEGER,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE
);

-- Milestones: Expectation subtype for point-in-time checkpoints
CREATE TABLE milestones (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    targetDate TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE
);

-- Obligations: Expectation subtype for external commitments
CREATE TABLE obligations (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    deadline TEXT NOT NULL,
    requestedBy TEXT,
    consequence TEXT,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE
);

-- GoalTerms: Planning scaffolds with state (references TimePeriod for dates)
CREATE TABLE goalTerms (
    id TEXT PRIMARY KEY,
    timePeriodId TEXT NOT NULL,
    termNumber INTEGER NOT NULL,
    theme TEXT,
    reflection TEXT,
    status TEXT CHECK(status IN ('planned', 'active', 'completed', 'delayed', 'on_hold', 'cancelled')),
    FOREIGN KEY (timePeriodId) REFERENCES timePeriods(id) ON DELETE CASCADE
);

-- ExpectationMeasures: Measurable targets for expectations
-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Uniqueness enforced at application level in repositories
CREATE TABLE expectationMeasures (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    targetValue REAL NOT NULL,
    freeformNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT
);
-- COMPOSIT LAYER SCHEMA
-- Written by Claude Code on 2025-10-31
--
-- DomainComposit = Identifiable
-- Pure junction tables with id + FK references + relationship data

-- MeasuredActions: Links actions to measurements
-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Uniqueness enforced at application level in repositories
CREATE TABLE measuredActions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    value REAL NOT NULL,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT
);

-- GoalRelevances: Links goals to values they serve
-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Uniqueness enforced at application level in repositories
CREATE TABLE goalRelevances (
    id TEXT PRIMARY KEY,
    goalId TEXT NOT NULL,
    valueId TEXT NOT NULL,
    alignmentStrength INTEGER CHECK(alignmentStrength BETWEEN 1 AND 10),
    relevanceNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (valueId) REFERENCES personalValues(id) ON DELETE CASCADE
);

-- ActionGoalContributions: Tracks action progress toward goals
-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Uniqueness enforced at application level in repositories
CREATE TABLE actionGoalContributions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    contributionAmount REAL,
    measureId TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT
);

-- TermGoalAssignments: Assigns goals to terms
-- Note: UNIQUE constraint removed for CloudKit sync compatibility
-- Uniqueness enforced at application level in repositories
CREATE TABLE termGoalAssignments (
    id TEXT PRIMARY KEY,
    termId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    assignmentOrder INTEGER,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (termId) REFERENCES goalTerms(id) ON DELETE CASCADE,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE
);
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
