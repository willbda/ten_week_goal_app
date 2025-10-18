-- Actions Table
-- Updated 2025-10-16 to align with new categoriae structure
--
-- Inherits from PersistableEntity:
--   - common_name: Short identifier (required)
--   - description: Optional elaboration
--   - notes: Freeform notes
--   - log_time: When action was logged
--   - id: Database primary key
--
-- Action-specific fields:
--   - measurement_units_by_amount: JSON dict of measurements
--   - duration_minutes: How long the action took
--   - start_time: When action started (if tracked)

CREATE TABLE actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    common_name TEXT NOT NULL,                      -- Short identifier (e.g., "Morning run")
    description TEXT,                               -- Optional elaboration
    notes TEXT,                                     -- Freeform notes
    log_time TEXT NOT NULL,                         -- When logged (ISO format)
    measurement_units_by_amount TEXT,               -- JSON dict: {"km": 5.0, "minutes": 30}
    start_time TEXT,                                -- When action started (ISO format)
    duration_minutes REAL                           -- Duration in minutes
);
