-- Values table: Track personal values and life areas in hierarchical structure
-- Written by Claude Code on 2025-10-11
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
-- Updated 2025-10-23 to migrate to UUID PRIMARY KEY (Phase 2 of UUID standardization)
-- Note: Table named "personal_values" since "values" is a SQL reserved keyword
--
-- Primary Key: uuid_id TEXT (both Python and Swift use UUID as primary identifier)
--
-- Inherits from PersistableEntity:
--   - uuid_id: PRIMARY KEY (UUID string in UPPERCASE format)
--   - title: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - log_time: When value was created
--
-- Values-specific fields:
--   - incentive_type: Class identifier for polymorphism ('general', 'major', 'highest_order', 'life_area')
--   - priority: 1-100 priority level (1 = highest)
--   - life_domain: Categorization (e.g., 'Physical Health')
--   - alignment_guidance: How this value shows up (optional, JSON or text)

CREATE TABLE IF NOT EXISTS personal_values (
  uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (e.g., "C7D4E8F9-2A1B-4C5D-8E9F-0A1B2C3D4E5F")
  title TEXT NOT NULL,                            -- Short identifier (e.g., "Companionship with Solène")
  description TEXT,                               -- Optional elaboration
  notes TEXT,                                     -- Freeform notes
  log_time TEXT NOT NULL,                         -- When created (ISO format)
  incentive_type TEXT NOT NULL,                   -- Type identifier: 'general', 'major', 'highest_order', 'life_area'
  priority INTEGER NOT NULL DEFAULT 50,           -- 1 = highest priority, 100 = lowest
  life_domain TEXT DEFAULT 'General',             -- Domain (e.g., 'Relationships', 'Health')
  alignment_guidance TEXT                         -- Optional: How value shows up (JSON or text)
);
