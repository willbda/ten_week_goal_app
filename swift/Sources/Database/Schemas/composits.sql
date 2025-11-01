-- COMPOSIT LAYER SCHEMA
-- Written by Claude Code on 2025-10-31
--
-- DomainComposit = Identifiable
-- Pure junction tables with id + FK references + relationship data

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
