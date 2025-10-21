-- Actions Table
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-18 to use UUID primary key for Swift compatibility
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
--
-- Dual ID System:
--   - id: INTEGER PRIMARY KEY (Python uses this, auto-increments)
--   - uuid_id: TEXT UNIQUE (Swift uses this, UUID string)
--
-- Inherits from Persistable protocol:
--   - friendly_name: Short identifier (maps to Swift friendlyName)
--   - detailed_description: Optional elaboration (maps to Swift detailedDescription)
--   - freeform_notes: Freeform notes (maps to Swift freeformNotes)
--   - log_time: When action was logged (maps to Swift logTime)
--
-- Action-specific fields:
--   - measurement_units_by_amount: JSON dict of measurements
--   - duration_minutes: How long the action took
--   - start_time: When action started (if tracked)

CREATE TABLE actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,           -- Python uses this
    uuid_id TEXT UNIQUE,                            -- Swift uses this (e.g., "550e8400-e29b-41d4-a716-446655440000")
    friendly_name TEXT NOT NULL,                    -- Short identifier (e.g., "Morning run")
    detailed_description TEXT,                      -- Optional elaboration
    freeform_notes TEXT,                            -- Freeform notes
    log_time TEXT NOT NULL,                         -- When logged (ISO format)
    measurement_units_by_amount TEXT,               -- JSON dict: {"km": 5.0, "minutes": 30}
    start_time TEXT,                                -- When action started (ISO format)
    duration_minutes REAL                           -- Duration in minutes
);

-- Index for Swift UUID lookups
CREATE INDEX idx_actions_uuid ON actions(uuid_id);
