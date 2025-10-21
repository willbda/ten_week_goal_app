-- Goals table: Track objectives with measurable targets and time windows
-- Written by Claude Code on 2025-10-10
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-17 to add polymorphic goal_type support
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
--
-- Dual ID System:
--   - id: INTEGER PRIMARY KEY (Python uses this, auto-increments)
--   - uuid_id: TEXT UNIQUE (Swift uses this, UUID string)
--
-- Inherits from PersistableEntity:
--   - common_name: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - log_time: When goal was created (maps to created_at for goals)
--
-- Goal-specific fields:
--   - goal_type: Class identifier for polymorphism (Goal, Milestone, SmartGoal)
--   - measurement_target, measurement_unit: What to measure
--   - start_date, target_date: Time bounds
--   - target_date: Specific date for Milestone goals
--   - how_goal_is_relevant, how_goal_is_actionable: SMART criteria
--   - expected_term_length: Planning horizon

CREATE TABLE IF NOT EXISTS goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,           -- Python uses this
  uuid_id TEXT UNIQUE,                            -- Swift uses this
  common_name TEXT NOT NULL,                      -- Short identifier (e.g., "Run 120km")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  log_time TEXT NOT NULL,                         -- When created (ISO format) - aliased as created_at
  goal_type TEXT NOT NULL DEFAULT 'Goal',         -- Class name: Goal, Milestone, SmartGoal
  measurement_target REAL,                        -- Numeric goal (e.g., 120.0)
  measurement_unit TEXT,                          -- Unit (e.g., 'km', 'hours')
  start_date TEXT,                                -- Goal period start (ISO format)
  target_date TEXT,                                  -- Goal period end (ISO format)
  how_goal_is_relevant TEXT,                      -- Why this goal matters
  how_goal_is_actionable TEXT,                    -- How to achieve it
  expected_term_length INTEGER                    -- Expected duration in weeks (e.g., 10)
);

-- Index for Swift UUID lookups
CREATE INDEX IF NOT EXISTS idx_goals_uuid ON goals(uuid_id);
