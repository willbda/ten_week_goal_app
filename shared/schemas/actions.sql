-- Actions Table
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-18 to use UUID primary key for Swift compatibility
--
-- Inherits from Persistable protocol:
--   - id: UUID primary key (Swift UUID)
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
    id TEXT PRIMARY KEY,                            -- UUID as text (e.g., "550e8400-e29b-41d4-a716-446655440000")
    friendly_name TEXT NOT NULL,                    -- Short identifier (e.g., "Morning run")
    detailed_description TEXT,                      -- Optional elaboration
    freeform_notes TEXT,                            -- Freeform notes
    log_time TEXT NOT NULL,                         -- When logged (ISO format)
    measurement_units_by_amount TEXT,               -- JSON dict: {"km": 5.0, "minutes": 30}
    start_time TEXT,                                -- When action started (ISO format)
    duration_minutes REAL                           -- Duration in minutes
);
