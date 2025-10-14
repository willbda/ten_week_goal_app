-- Values table: Track personal values and life areas in hierarchical structure
-- Written by Claude Code on 2025-10-11
-- Note: Table named "personal_values" since "values" is a SQL reserved keyword

CREATE TABLE IF NOT EXISTS personal_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  value_name TEXT NOT NULL,                         -- Short name (e.g., "Companionship with Solène")
  description TEXT NOT NULL,                  -- Extended explanation of the value
  value_type TEXT NOT NULL,                   -- 'major', 'highest_order', 'general', 'life_area'
  priority INTEGER NOT NULL DEFAULT 50,       -- 1 = highest priority, 100 = lowest
  life_domain TEXT DEFAULT 'General',         -- Domain categorization (e.g., 'Physical Health', 'Relationships')
  alignment_guidance TEXT,                    -- Optional: How this value shows up in actions/goals (JSON or text)
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
