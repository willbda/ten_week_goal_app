-- Uniform Database Schema for Ten Week Goal App
-- Written by Claude Code on 2025-10-27
--
-- Design Principle: All tables share identical base fields (Persistable)
-- Single Responsibility: Each table handles exactly one relationship

-- ============================================================================
-- FIRST-CLASS ENTITIES
-- ============================================================================

-- Actions: Past-oriented records of what was done
CREATE TABLE IF NOT EXISTS actions (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Action-specific fields
  startTime TEXT,
  durationMinutes REAL
) STRICT;

-- Goals: Future-oriented targets
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Goal-specific fields
  startDate TEXT,
  targetDate TEXT,
  goalType TEXT NOT NULL DEFAULT 'goal' -- 'goal' | 'milestone'
) STRICT;

-- Values: Personal values, life areas, priorities
CREATE TABLE IF NOT EXISTS "values" (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Value-specific fields
  priority INTEGER NOT NULL DEFAULT 50,
  valueLevel TEXT NOT NULL DEFAULT 'general', -- 'general' | 'major' | 'highest_order' | 'life_area'
  lifeDomain TEXT,
  alignmentGuidance TEXT
) STRICT;

-- Terms: Time horizons (10-week planning periods)
CREATE TABLE IF NOT EXISTS terms (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Term-specific fields
  termNumber INTEGER NOT NULL,
  startDate TEXT NOT NULL,
  targetDate TEXT NOT NULL,
  theme TEXT,
  reflection TEXT
) STRICT;

-- Metrics: Catalog of units of measure
CREATE TABLE IF NOT EXISTS metrics (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Metric-specific fields
  unit TEXT NOT NULL,
  metricType TEXT NOT NULL, -- 'distance' | 'time' | 'count' | 'mass'
  canonicalUnit TEXT
) STRICT;

-- ============================================================================
-- JUNCTION TABLES (RELATIONSHIPS)
-- ============================================================================

-- Action Metrics: Links actions to measurements (like invoice line items)
CREATE TABLE IF NOT EXISTS action_metrics (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Relationship fields
  actionId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  value REAL NOT NULL,
  recordedAt TEXT NOT NULL,

  FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id) ON DELETE CASCADE,
  UNIQUE(actionId, metricId)
) STRICT;

-- Goal Metrics: Defines how goal is actionable (measurement structure)
CREATE TABLE IF NOT EXISTS goal_metrics (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Relationship fields
  goalId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  targetValue REAL NOT NULL,

  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id) ON DELETE CASCADE,
  UNIQUE(goalId, metricId)
) STRICT;

-- Goal Relevance: Links goals to values (how goal is relevant)
CREATE TABLE IF NOT EXISTS goal_relevance (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Relationship fields
  goalId TEXT NOT NULL,
  valueId TEXT NOT NULL,
  alignmentStrength INTEGER,
  relevanceNotes TEXT,

  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (valueId) REFERENCES "values"(id) ON DELETE CASCADE,
  UNIQUE(goalId, valueId)
) STRICT;

-- Term Goal Assignments: Links terms to goals
CREATE TABLE IF NOT EXISTS term_goal_assignments (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Relationship fields
  termId TEXT NOT NULL,
  goalId TEXT NOT NULL,
  assignmentOrder INTEGER,

  FOREIGN KEY (termId) REFERENCES terms(id) ON DELETE CASCADE,
  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  UNIQUE(termId, goalId)
) STRICT;

-- ============================================================================
-- INDICES FOR COMMON QUERIES
-- ============================================================================

-- Junction table lookups
CREATE INDEX IF NOT EXISTS idx_action_metrics_action ON action_metrics(actionId);
CREATE INDEX IF NOT EXISTS idx_action_metrics_metric ON action_metrics(metricId);
CREATE INDEX IF NOT EXISTS idx_goal_metrics_goal ON goal_metrics(goalId);
CREATE INDEX IF NOT EXISTS idx_goal_metrics_metric ON goal_metrics(metricId);
CREATE INDEX IF NOT EXISTS idx_goal_relevance_goal ON goal_relevance(goalId);
CREATE INDEX IF NOT EXISTS idx_goal_relevance_value ON goal_relevance(valueId);
CREATE INDEX IF NOT EXISTS idx_term_goal_term ON term_goal_assignments(termId);
CREATE INDEX IF NOT EXISTS idx_term_goal_goal ON term_goal_assignments(goalId);

-- Type discrimination
CREATE INDEX IF NOT EXISTS idx_goals_type ON goals(goalType);
CREATE INDEX IF NOT EXISTS idx_values_level ON "values"(valueLevel);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON metrics(metricType);

-- Temporal queries
CREATE INDEX IF NOT EXISTS idx_actions_logtime ON actions(logTime);
CREATE INDEX IF NOT EXISTS idx_goals_dates ON goals(startDate, targetDate);
CREATE INDEX IF NOT EXISTS idx_terms_dates ON terms(startDate, targetDate);
