-- Values table: Track personal values and life areas in hierarchical structure
-- Written by Claude Code on 2025-10-11
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
-- Note: Table named "personal_values" since "values" is a SQL reserved keyword
--
-- Dual ID System:
--   - id: INTEGER PRIMARY KEY (Python uses this, auto-increments)
--   - uuid_id: TEXT UNIQUE (Swift uses this, UUID string)
--
-- Inherits from PersistableEntity:
--   - title: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - log_time: When value was created
--
-- Incentives-specific fields:
--   - priority: 1-100 priority level
--   - life_domain: Categorization (e.g., 'Physical Health')
--   - incentive_type: Class identifier for polymorphism ('general', 'major', 'highest_order', 'life_area')
--   - alignment_guidance: How this value shows up (optional, JSON or text)

CREATE TABLE IF NOT EXISTS personal_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,           -- Python uses this
  uuid_id TEXT UNIQUE,                            -- Swift uses this
  title TEXT NOT NULL,                      -- Short identifier (e.g., "Companionship with Solène")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  log_time TEXT NOT NULL,                         -- When created (ISO format)
  incentive_type TEXT NOT NULL,                   -- Type identifier: 'general', 'major', 'highest_order', 'life_area'
  priority INTEGER NOT NULL DEFAULT 50,           -- 1 = highest priority, 100 = lowest
  life_domain TEXT DEFAULT 'General',             -- Domain (e.g., 'Relationships', 'Health')
  alignment_guidance TEXT                         -- Optional: How value shows up (JSON or text)
);

-- Index for Swift UUID lookups
CREATE INDEX IF NOT EXISTS idx_personal_values_uuid ON personal_values(uuid_id);
