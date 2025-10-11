-- Goals table: Track objectives with measurable targets and time windows
-- Written by Claude Code on 2025-10-10

CREATE TABLE IF NOT EXISTS goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,                  -- What you're trying to achieve
  target_value REAL,                          -- Numeric goal (e.g., 40.0)
  unit TEXT,                         -- Measurement unit (e.g., 'hours spent', 'km run')
  start_date TEXT ,                   -- Goal period start (ISO format: '2025-04-12')
  end_date TEXT,                      -- Goal period end (ISO format: '2025-06-21')
  relevance TEXT,                             -- Why this goal matters (optional)
  actionability TEXT,                         -- How to achieve it (optional)
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
