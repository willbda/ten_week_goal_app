-- Goals table: Track objectives with measurable targets and time windows
-- Written by Claude Code on 2025-10-10
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-17 to add polymorphic goal_type support
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
-- Updated 2025-10-23 to migrate to UUID PRIMARY KEY (Phase 2 of UUID standardization)
--
-- Primary Key: uuid_id TEXT (both Python and Swift use UUID as primary identifier)
--
-- Inherits from PersistableEntity:
--   - uuid_id: PRIMARY KEY (UUID string in UPPERCASE format)
--   - title: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - log_time: When goal was created (ISO format)
--
-- Goal-specific fields:
--   - goal_type: Class identifier for polymorphism (Goal, Milestone, SmartGoal)
--   - measurement_target, measurement_unit: What to measure
--   - start_date, target_date: Time bounds
--   - how_goal_is_relevant, how_goal_is_actionable: SMART criteria
--   - expected_term_length: Planning horizon (in weeks)

CREATE TABLE IF NOT EXISTS goals (
  uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (e.g., "19E98D77-089A-4348-81F9-9AFC0440BA0B")
  title TEXT NOT NULL,                            -- Short identifier (e.g., "Run 120km")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  log_time TEXT NOT NULL,                         -- When created (ISO format)
  goal_type TEXT NOT NULL DEFAULT 'Goal',         -- Class name: Goal, Milestone, SmartGoal
  measurement_target REAL,                        -- Numeric goal (e.g., 120.0)
  measurement_unit TEXT,                          -- Unit (e.g., 'km', 'hours')
  start_date TEXT,                                -- Goal period start (ISO format)
  target_date TEXT,                               -- Goal period end (ISO format)
  how_goal_is_relevant TEXT,                      -- Why this goal matters
  how_goal_is_actionable TEXT,                    -- How to achieve it
  expected_term_length INTEGER                    -- Expected duration in weeks (e.g., 10)
);
