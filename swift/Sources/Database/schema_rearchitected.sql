-- Rearchitected Schema for Ten Week Goal App
-- Written by Claude Code on 2025-10-26
--
-- Design Principles:
-- 1. Metrics as first-class entities (not JSON dictionaries)
-- 2. Unified values table (not 4 separate tables)
-- 3. Goals with computed is_smart column
-- 4. Explicit relationship tables for queryability
-- 5. Every table queryable at a glance without complex parsing

-- ============================================================================
-- CORE ENTITIES
-- ============================================================================

-- Actions: Past-oriented records of what was done
CREATE TABLE IF NOT EXISTS actions (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Timing (optional)
  startTime TEXT,
  durationMinutes REAL
) STRICT;

-- Goals: Future-oriented targets
-- Supports both minimal goals and SMART goals
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Measurement (optional for minimal, required for SMART)
  measurementUnit TEXT,
  measurementTarget REAL,
  startDate TEXT,
  targetDate TEXT,

  -- SMART enhancement fields (optional)
  howGoalIsRelevant TEXT,
  howGoalIsActionable TEXT,
  expectedTermLength INTEGER,

  -- Goal type configuration
  goalType TEXT NOT NULL DEFAULT 'goal', -- 'goal' or 'milestone'

  -- Computed: Is this a SMART goal?
  -- A SMART goal has all measurement fields AND enhancement fields filled
  isSmart INTEGER GENERATED ALWAYS AS (
    CASE WHEN
      measurementUnit IS NOT NULL AND
      measurementTarget IS NOT NULL AND
      startDate IS NOT NULL AND
      targetDate IS NOT NULL AND
      howGoalIsRelevant IS NOT NULL AND
      howGoalIsActionable IS NOT NULL
    THEN 1 ELSE 0 END
  ) STORED
) STRICT;

-- Values: Personal values, life areas, and priorities
-- Unified table instead of 4 separate tables
CREATE TABLE IF NOT EXISTS "values" (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Priority and categorization
  priority INTEGER NOT NULL DEFAULT 50,
  valueLevel TEXT NOT NULL DEFAULT 'general', -- 'general', 'major', 'highest_order', 'life_area'
  lifeDomain TEXT,

  -- Only populated for major values
  alignmentGuidance TEXT
) STRICT;

-- Terms: Time horizons for planning (10-week periods)
CREATE TABLE IF NOT EXISTS terms (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  detailedDescription TEXT,
  freeformNotes TEXT,
  logTime TEXT NOT NULL,

  -- Term definition
  termNumber INTEGER NOT NULL,
  startDate TEXT NOT NULL,
  targetDate TEXT NOT NULL,

  -- Optional metadata
  theme TEXT,
  reflection TEXT
) STRICT;

-- ============================================================================
-- METRICS SYSTEM
-- ============================================================================

-- Metrics: First-class entities for measurements
-- Replaces the measuresByUnit JSON dictionary
CREATE TABLE IF NOT EXISTS metrics (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,              -- "Distance", "Duration", "Occasions"
  unit TEXT NOT NULL,               -- "km", "hours", "occasions"
  metricType TEXT,                  -- "distance", "time", "count" (for grouping)
  logTime TEXT NOT NULL,

  UNIQUE(name, unit)
) STRICT;

-- Action Metrics: Links actions to their measurements
CREATE TABLE IF NOT EXISTS action_metrics (
  id TEXT PRIMARY KEY NOT NULL,
  actionId TEXT NOT NULL,
  metricId TEXT NOT NULL,
  value REAL NOT NULL,
  recordedAt TEXT NOT NULL DEFAULT (datetime('now')),

  FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id) ON DELETE CASCADE,
  UNIQUE(actionId, metricId)
) STRICT;

-- ============================================================================
-- RELATIONSHIPS
-- ============================================================================

-- Term-Goal Assignments: Which goals belong to which terms
CREATE TABLE IF NOT EXISTS term_goal_assignments (
  id TEXT PRIMARY KEY NOT NULL,
  termId TEXT NOT NULL,
  goalId TEXT NOT NULL,
  assignmentOrder INTEGER,
  createdAt TEXT NOT NULL DEFAULT (datetime('now')),

  FOREIGN KEY (termId) REFERENCES terms(id) ON DELETE CASCADE,
  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  UNIQUE(termId, goalId)
) STRICT;

-- Action-Goal Contributions: Which actions contribute to which goals
CREATE TABLE IF NOT EXISTS action_goal_contributions (
  id TEXT PRIMARY KEY NOT NULL,
  actionId TEXT NOT NULL,
  goalId TEXT NOT NULL,

  -- Optional: How much did this action contribute?
  contributionAmount REAL,
  metricId TEXT,                    -- Which metric was contributed

  createdAt TEXT NOT NULL DEFAULT (datetime('now')),

  FOREIGN KEY (actionId) REFERENCES actions(id) ON DELETE CASCADE,
  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (metricId) REFERENCES metrics(id) ON DELETE SET NULL,
  UNIQUE(actionId, goalId)
) STRICT;

-- Goal-Value Alignments: Which goals align with which values
CREATE TABLE IF NOT EXISTS goal_value_alignments (
  id TEXT PRIMARY KEY NOT NULL,
  goalId TEXT NOT NULL,
  valueId TEXT NOT NULL,

  -- Optional: Strength of alignment (1-10)
  alignmentStrength INTEGER,
  notes TEXT,

  createdAt TEXT NOT NULL DEFAULT (datetime('now')),

  FOREIGN KEY (goalId) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (valueId) REFERENCES "values"(id) ON DELETE CASCADE,
  UNIQUE(goalId, valueId)
) STRICT;

-- ============================================================================
-- INDICES FOR COMMON QUERIES
-- ============================================================================

-- Find all actions with a specific metric
CREATE INDEX IF NOT EXISTS idx_action_metrics_metric ON action_metrics(metricId);
CREATE INDEX IF NOT EXISTS idx_action_metrics_action ON action_metrics(actionId);

-- Find all actions contributing to a goal
CREATE INDEX IF NOT EXISTS idx_action_goal_goal ON action_goal_contributions(goalId);
CREATE INDEX IF NOT EXISTS idx_action_goal_action ON action_goal_contributions(actionId);

-- Find all goals in a term
CREATE INDEX IF NOT EXISTS idx_term_goal_term ON term_goal_assignments(termId);
CREATE INDEX IF NOT EXISTS idx_term_goal_goal ON term_goal_assignments(goalId);

-- Find all goals aligned with a value
CREATE INDEX IF NOT EXISTS idx_goal_value_value ON goal_value_alignments(valueId);
CREATE INDEX IF NOT EXISTS idx_goal_value_goal ON goal_value_alignments(goalId);

-- Query by value level
CREATE INDEX IF NOT EXISTS idx_values_level ON "values"(valueLevel);

-- Query SMART goals
CREATE INDEX IF NOT EXISTS idx_goals_smart ON goals(isSmart);

-- Temporal queries
CREATE INDEX IF NOT EXISTS idx_actions_logtime ON actions(logTime);
CREATE INDEX IF NOT EXISTS idx_goals_dates ON goals(startDate, targetDate);
CREATE INDEX IF NOT EXISTS idx_terms_dates ON terms(startDate, targetDate);
