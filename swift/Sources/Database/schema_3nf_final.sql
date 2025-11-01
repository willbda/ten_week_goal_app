-- 3NF Final Schema for Ten Week Goal App
-- Status: PRODUCTION
-- Date: 2025-10-30
-- Written by: Claude Code
--
-- This is the definitive schema implementing full 3NF normalization.
-- Junction tables are pure database artifacts (minimal fields).
-- All multi-valued attributes eliminated (no JSON).

-- ============================================================================
-- CORE ENTITIES (with Persistable fields)
-- ============================================================================

-- Actions: Past-oriented records of what was done
CREATE TABLE IF NOT EXISTS actions (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Action-specific
  durationMinutes REAL,
  startTime TEXT
) STRICT;

-- Goals: Future-oriented targets
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Goal-specific
  startDate TEXT,
  targetDate TEXT,
  actionPlan TEXT,
  expectedTermLength INTEGER
) STRICT;

-- Values: Unified table for all value types
CREATE TABLE IF NOT EXISTS "values" (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Value-specific
  priority INTEGER NOT NULL DEFAULT 50,
  valueLevel TEXT NOT NULL DEFAULT 'general',
  lifeDomain TEXT,
  alignmentGuidance TEXT
) STRICT;

-- Terms: 10-week planning periods
CREATE TABLE IF NOT EXISTS terms (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Term-specific
  termNumber INTEGER NOT NULL,
  startDate TEXT NOT NULL,
  targetDate TEXT NOT NULL,
  theme TEXT,
  reflection TEXT
) STRICT;

-- Metrics: Catalog of measurement units
CREATE TABLE IF NOT EXISTS metrics (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Metric-specific
  unit TEXT NOT NULL,
  metricType TEXT NOT NULL,
  canonicalUnit TEXT,
  conversionFactor REAL,

  UNIQUE(unit)
) STRICT;

-- ============================================================================
-- JUNCTION TABLES (pure database artifacts)
-- ============================================================================

-- ActionMetric: Links actions to measurements
CREATE TABLE IF NOT EXISTS actionMetrics (
  id TEXT PRIMARY KEY NOT NULL,
  actionId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  value REAL NOT NULL,
  recordedAt TEXT NOT NULL,

  FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id),
  UNIQUE(actionId, metricId)
) STRICT;

-- GoalMetric: Defines goal targets
CREATE TABLE IF NOT EXISTS goalMetrics (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  goalId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  targetValue REAL NOT NULL,

  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id),
  UNIQUE(goalId, metricId)
) STRICT;

-- GoalRelevance: Links goals to values
CREATE TABLE IF NOT EXISTS goalRelevances (
  id TEXT PRIMARY KEY NOT NULL,
  goalId TEXT NOT NULL,
  valueId TEXT NOT NULL,
  alignmentStrength INTEGER,
  relevanceNotes TEXT,
  createdAt TEXT NOT NULL,

  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (valueId) REFERENCES "values"(id) ON DELETE CASCADE,
  UNIQUE(goalId, valueId)
) STRICT;

-- ActionGoalContribution: Tracks progress
CREATE TABLE IF NOT EXISTS actionGoalContributions (
  id TEXT PRIMARY KEY NOT NULL,
  actionId TEXT NOT NULL,
  goalId TEXT NOT NULL,
  contributionAmount REAL,
  metricId TEXT,
  createdAt TEXT NOT NULL,

  FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id),
  UNIQUE(actionId, goalId)
) STRICT;

-- TermGoalAssignment: Assigns goals to terms
CREATE TABLE IF NOT EXISTS termGoalAssignments (
  id TEXT PRIMARY KEY NOT NULL,
  termId TEXT NOT NULL,
  goalId TEXT NOT NULL,
  assignmentOrder INTEGER,
  createdAt TEXT NOT NULL,

  FOREIGN KEY (termId) REFERENCES terms(id) ON DELETE CASCADE,
  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  UNIQUE(termId, goalId)
) STRICT;

-- ============================================================================
-- INDEXES for performance
-- ============================================================================

-- Metric lookups
CREATE INDEX IF NOT EXISTS idx_action_metrics_action ON actionMetrics(actionId);
CREATE INDEX IF NOT EXISTS idx_action_metrics_metric ON actionMetrics(metricId);
CREATE INDEX IF NOT EXISTS idx_goal_metrics_goal ON goalMetrics(goalId);
CREATE INDEX IF NOT EXISTS idx_goal_metrics_metric ON goalMetrics(metricId);

-- Relationship queries
CREATE INDEX IF NOT EXISTS idx_goal_relevance_goal ON goalRelevances(goalId);
CREATE INDEX IF NOT EXISTS idx_goal_relevance_value ON goalRelevances(valueId);
CREATE INDEX IF NOT EXISTS idx_contributions_action ON actionGoalContributions(actionId);
CREATE INDEX IF NOT EXISTS idx_contributions_goal ON actionGoalContributions(goalId);
CREATE INDEX IF NOT EXISTS idx_term_assignments_term ON termGoalAssignments(termId);
CREATE INDEX IF NOT EXISTS idx_term_assignments_goal ON termGoalAssignments(goalId);

-- Type discrimination
CREATE INDEX IF NOT EXISTS idx_values_level ON "values"(valueLevel);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON metrics(metricType);