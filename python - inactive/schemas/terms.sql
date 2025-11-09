-- Terms table: Time-bounded planning horizons for goal organization
-- Written by Claude Code on 2025-10-13
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
-- Updated 2025-10-23 to migrate to UUID PRIMARY KEY (Phase 2 of UUID standardization)
-- Updated 2025-10-23 to remove term_goals_by_id (migrated to term_goal_assignments junction table)
--
-- A term is a structured planning period (typically 10 weeks) that provides:
-- - Temporal scaffolding for related goals
-- - Rhythmic reflection points
-- - Context for priority decisions
--
-- Primary Key: uuid_id TEXT (both Python and Swift use UUID as primary identifier)
--
-- Inherits from IndependentEntity:
--   - uuid_id: PRIMARY KEY (UUID string in UPPERCASE format)
--   - title: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--
-- Term-specific fields:
--   - term_number: Sequential identifier (must be unique)
--   - start_date, target_date: Time bounds
--   - reflection: Post-term notes
--   - created_at, updated_at: Timestamps
--
-- Goal assignments: Use term_goal_assignments junction table (many-to-many relationship)

CREATE TABLE IF NOT EXISTS terms (
  uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (e.g., "B3F21A45-7C92-4D5E-9B10-8A1E3F4D6C2A")
  title TEXT NOT NULL,                            -- Short identifier (e.g., "Term 1: Health Focus")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  term_number INTEGER NOT NULL UNIQUE,            -- Sequential identifier (1, 2, 3, etc.)
  start_date TEXT NOT NULL,                       -- First day of term (ISO format)
  target_date TEXT NOT NULL,                      -- Last day of term (ISO format)
  theme TEXT,                                     -- Optional theme/focus for this term
  reflection TEXT,                                -- Post-term reflection
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Index for efficient lookup of active terms by date
CREATE INDEX IF NOT EXISTS idx_terms_dates ON terms(start_date, target_date);

-- Index for finding terms by number
CREATE INDEX IF NOT EXISTS idx_terms_number ON terms(term_number);
