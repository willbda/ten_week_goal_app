-- Action-Goal Progress Relationships
-- Stores derived relationships between actions and goals
-- This is a PROJECTION/CACHE, not source of truth - can be recalculated from actions + goals
-- Written by Claude Code on 2025-10-11

CREATE TABLE IF NOT EXISTS action_goal_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action_id INTEGER NOT NULL,
  goal_id INTEGER NOT NULL,
  contribution REAL NOT NULL,              -- Amount this action contributes (e.g., 5.0 km)
  match_method TEXT NOT NULL,              -- 'auto_inferred', 'user_confirmed', 'manual'
  confidence REAL,                         -- Confidence score 0.0-1.0 (NULL for manual/confirmed)
  matched_on TEXT,                         -- What triggered the match (e.g., 'period+unit+description')
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
  FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,

  -- One action can contribute to multiple goals, but only once per goal
  UNIQUE(action_id, goal_id)
);

-- Index for querying progress by goal
CREATE INDEX IF NOT EXISTS idx_progress_by_goal ON action_goal_progress(goal_id, created_at);

-- Index for querying actions by match method (find all auto-inferred to review)
CREATE INDEX IF NOT EXISTS idx_progress_by_method ON action_goal_progress(match_method);
