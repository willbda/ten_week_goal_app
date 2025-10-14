-- Terms table: Time-bounded planning horizons for goal organization
-- Written by Claude Code on 2025-10-13
--
-- A term is a structured planning period (typically 10 weeks) that provides:
-- - Temporal scaffolding for related goals
-- - Rhythmic reflection points
-- - Context for priority decisions

CREATE TABLE IF NOT EXISTS terms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  term_number INTEGER NOT NULL,                   -- Sequential identifier (Term 1, Term 2, etc.)
  start_date TEXT NOT NULL,                       -- First day of term (ISO format: '2025-10-13')
  end_date TEXT NOT NULL,                         -- Last day of term (ISO format: '2025-12-22')
  theme TEXT,                                     -- Optional focus area (e.g., "Health & Learning")
  goal_ids TEXT,                                  -- JSON array of goal IDs: "[1, 3, 5]"
  reflection TEXT,                                -- Post-term reflection notes
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

  -- Ensure term numbers are unique
  UNIQUE(term_number)
);

-- Index for efficient lookup of active terms by date
CREATE INDEX IF NOT EXISTS idx_terms_dates ON terms(start_date, end_date);

-- Index for finding terms by number
CREATE INDEX IF NOT EXISTS idx_terms_number ON terms(term_number);
