-- Current Database Schema - 3NF+ with Table Inheritance
-- Written by Claude Code on 2025-10-31
-- Matches Swift models in Sources/Models/
--
-- ARCHITECTURE:
-- - Abstractions: Full metadata entities (Documentable + Timestamped)
-- - Basics: Lightweight working entities (references to Abstractions)
-- - Composits: Pure junction tables (minimal fields)

-- =============================================================================
-- ABSTRACTION LAYER (DomainAbstraction)
-- Full metadata: id, title, detailedDescription, freeformNotes, logTime
-- =============================================================================

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
CREATE TABLE personalvalues (
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
CREATE TABLE timeperiods (
    id TEXT PRIMARY KEY,
    title TEXT,
    detailedDescription TEXT,
    freeformNotes TEXT,
    logTime TEXT NOT NULL,
    startDate TEXT NOT NULL,
    endDate TEXT NOT NULL,
    CHECK(startDate <= endDate)
);

-- =============================================================================
-- BASIC LAYER (DomainBasic)
-- Lightweight entities: id + FK references + type-specific fields
-- =============================================================================

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
CREATE TABLE goalterms (
    id TEXT PRIMARY KEY,
    timePeriodId TEXT NOT NULL,
    termNumber INTEGER NOT NULL,
    theme TEXT,
    reflection TEXT,
    status TEXT CHECK(status IN ('planned', 'active', 'completed', 'delayed', 'on_hold', 'cancelled')),
    FOREIGN KEY (timePeriodId) REFERENCES timeperiods(id) ON DELETE CASCADE
);

-- ExpectationMeasures: Measurable targets for expectations
CREATE TABLE expectationmeasures (
    id TEXT PRIMARY KEY,
    expectationId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    targetValue REAL NOT NULL,
    freeformNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (expectationId) REFERENCES expectations(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT,
    UNIQUE(expectationId, measureId)
);

-- =============================================================================
-- COMPOSIT LAYER (DomainComposit)
-- Pure junction tables: id + FK references + relationship data
-- =============================================================================

-- MeasuredActions: Links actions to measurements
CREATE TABLE measuredactions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    measureId TEXT NOT NULL,
    value REAL NOT NULL,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT,
    UNIQUE(actionId, measureId)
);

-- GoalRelevances: Links goals to values they serve
CREATE TABLE goalrelevances (
    id TEXT PRIMARY KEY,
    goalId TEXT NOT NULL,
    valueId TEXT NOT NULL,
    alignmentStrength INTEGER CHECK(alignmentStrength BETWEEN 1 AND 10),
    relevanceNotes TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (valueId) REFERENCES personalvalues(id) ON DELETE CASCADE,
    UNIQUE(goalId, valueId)
);

-- ActionGoalContributions: Tracks action progress toward goals
CREATE TABLE actiongoalcontributions (
    id TEXT PRIMARY KEY,
    actionId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    contributionAmount REAL,
    measureId TEXT,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    FOREIGN KEY (measureId) REFERENCES measures(id) ON DELETE RESTRICT,
    UNIQUE(actionId, goalId)
);

-- TermGoalAssignments: Assigns goals to terms
CREATE TABLE termgoalassignments (
    id TEXT PRIMARY KEY,
    termId TEXT NOT NULL,
    goalId TEXT NOT NULL,
    assignmentOrder INTEGER,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (termId) REFERENCES goalterms(id) ON DELETE CASCADE,
    FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
    UNIQUE(termId, goalId)
);

-- =============================================================================
-- NOTES
-- =============================================================================
--
-- FOREIGN KEY BEHAVIOR:
-- - ON DELETE CASCADE: When parent deleted, children auto-delete
--   (Used for entity-relationship cleanup)
-- - ON DELETE RESTRICT: Prevent deletion if children exist
--   (Used for catalog tables like measures to prevent orphaned references)
--
-- UNIQUE CONSTRAINTS:
-- - Prevent duplicate relationships in junction tables
-- - Examples: Can't measure same metric twice for one action
--             Can't assign same goal to term twice
--
-- CHECK CONSTRAINTS:
-- - Enforce enum-like values (expectationType, valueLevel, status)
-- - Enforce data validity (alignmentStrength 1-10, startDate <= endDate)
--
-- DATE STORAGE:
-- - TEXT format (ISO 8601: "2025-10-31T06:30:00Z")
-- - SQLite recommendation for date/time storage
-- - Compatible with Swift Date encoding/decoding
--
-- =============================================================================
