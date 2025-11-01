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
