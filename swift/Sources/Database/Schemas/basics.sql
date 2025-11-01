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
