-- Action-Goal Progress Relationships
-- Stores derived relationships between actions and goals
-- This is a PROJECTION/CACHE, not source of truth - can be recalculated from actions + goals
-- Written by Claude Code on 2025-10-11
-- Updated by Claude Code on 2025-10-22 to use UUID foreign keys for Swift compatibility

CREATE TABLE IF NOT EXISTS action_goal_progress (
  uuid_id TEXT PRIMARY KEY,               -- PRIMARY KEY (e.g., "550e8400-...")
  action_id TEXT NOT NULL,                -- UUID of action (foreign key)
  goal_id TEXT NOT NULL,                  -- UUID of goal (foreign key)
  contribution REAL NOT NULL,             -- Amount this action contributes (e.g., 5.0 km)
  match_method TEXT NOT NULL,             -- 'auto_inferred', 'user_confirmed', 'manual'
  confidence REAL,                        -- Confidence score 0.0-1.0
  matched_on TEXT,                        -- JSON array: ["period", "unit", "description"]
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (action_id) REFERENCES actions(uuid_id) ON DELETE CASCADE,
  FOREIGN KEY (goal_id) REFERENCES goals(uuid_id) ON DELETE CASCADE,

  -- One action can contribute to multiple goals, but only once per goal
  UNIQUE(action_id, goal_id)
);

-- Index for querying progress by goal
CREATE INDEX IF NOT EXISTS idx_progress_by_goal ON action_goal_progress(goal_id, created_at);

-- Index for querying actions by match method (find all auto-inferred to review)
CREATE INDEX IF NOT EXISTS idx_progress_by_method ON action_goal_progress(match_method);
