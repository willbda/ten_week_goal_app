-- Goals table: Track objectives with measurable targets and time windows
-- Written by Claude Code on 2025-10-10

CREATE TABLE IF NOT EXISTS goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,                  -- What you're trying to achieve
  measurement_target REAL,                          -- Numeric goal (e.g., 40.0)
  measurement_unit TEXT,                                  -- Measurement unit (e.g., 'hours spent', 'km run')
  start_date TEXT,                            -- Goal period start (ISO format: '2025-04-12')
  end_date TEXT,                              -- Goal period end (ISO format: '2025-06-21')
  how_goal_is_relevant TEXT,                             -- Why this goal matters (optional)
  how_goal_is_actionable TEXT,                         -- How to achieve it (optional)
  expected_term_length INTEGER,               -- Expected duration in weeks (e.g., 10)
  created_at TEXT DEFAULT CURRENT_TIMESTAMP   -- When this goal was created
);
