-- Terms table: Time-bounded planning horizons for goal organization
-- Written by Claude Code on 2025-10-13
-- Updated 2025-10-16 to align with new categoriae structure
--
-- A term is a structured planning period (typically 10 weeks) that provides:
-- - Temporal scaffolding for related goals
-- - Rhythmic reflection points
-- - Context for priority decisions
--
-- Inherits from IndependentEntity (not PersistableEntity):
--   - common_name: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - id: Database primary key
--
-- Term-specific fields:
--   - term_number: Sequential identifier
--   - start_date, target_date: Time bounds
--   - term_goals_by_id: JSON array of goal IDs
--   - reflection: Post-term notes

CREATE TABLE IF NOT EXISTS terms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  common_name TEXT NOT NULL,                      -- Short identifier (e.g., "Term 1: Health Focus")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  term_number INTEGER NOT NULL,                   -- Sequential identifier (1, 2, 3, etc.)
  start_date TEXT NOT NULL,                       -- First day of term (ISO format)
  target_date TEXT NOT NULL,                         -- Last day of term (ISO format)
  term_goals_by_id TEXT,                          -- JSON array of goal IDs: "[1, 3, 5]"
  reflection TEXT,                                -- Post-term reflection
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

  -- Ensure term numbers are unique
  UNIQUE(term_number)
);

-- Index for efficient lookup of active terms by date
CREATE INDEX IF NOT EXISTS idx_terms_dates ON terms(start_date, target_date);

-- Index for finding terms by number
CREATE INDEX IF NOT EXISTS idx_terms_number ON terms(term_number);
