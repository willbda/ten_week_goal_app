-- Values table: Track personal values and life areas in hierarchical structure
-- Written by Claude Code on 2025-10-11
-- Updated 2025-10-16 to align with new categoriae structure
-- Note: Table named "personal_values" since "values" is a SQL reserved keyword
--
-- Inherits from PersistableEntity:
--   - common_name: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - log_time: When value was created
--   - id: Database primary key
--
-- Incentives-specific fields:
--   - priority: 1-100 priority level
--   - life_domain: Categorization (e.g., 'Physical Health')
--   - type: Class name for polymorphism ('Values', 'MajorValues', 'HighestOrderValues', 'LifeAreas')
--   - alignment_guidance: How this value shows up (optional, JSON or text)

CREATE TABLE IF NOT EXISTS personal_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  common_name TEXT NOT NULL,                      -- Short identifier (e.g., "Companionship with Solène")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  log_time TEXT NOT NULL,                         -- When created (ISO format)
  incentive_type TEXT NOT NULL,                             -- Class name: 'Values', 'MajorValues', 'HighestOrderValues', 'LifeAreas'
  priority INTEGER NOT NULL DEFAULT 50,           -- 1 = highest priority, 100 = lowest
  life_domain TEXT DEFAULT 'General',             -- Domain (e.g., 'Relationships', 'Health')
  alignment_guidance TEXT                         -- Optional: How value shows up (JSON or text)
);
