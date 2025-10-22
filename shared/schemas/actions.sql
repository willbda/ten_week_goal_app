-- Actions Table
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-18 to use UUID primary key for Swift compatibility
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
-- Updated 2025-10-21 to migrate Python to use UUID as primary identifier
--
-- Dual ID System (for backward compatibility):
--   - id: INTEGER PRIMARY KEY (auto-increments, legacy, deprecated for Python)
--   - uuid_id: TEXT UNIQUE (PRIMARY IDENTIFIER - both Python and Swift use this now)
--
-- Python now uses uuid_id for all CRUD operations (get_by_uuid, update_by_uuid, delete_by_uuid)
-- INTEGER id column maintained for backward compatibility with legacy code only
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
    title TEXT NOT NULL,                      -- Short identifier (e.g., "Morning run")
    description TEXT,                               -- Optional elaboration
    notes TEXT,                                     -- Freeform notes
    log_time TEXT NOT NULL,                         -- When logged (ISO format)
    measurement_units_by_amount TEXT,               -- JSON dict: {"km": 5.0, "minutes": 30}
    start_time TEXT,                                -- When action started (ISO format)
    duration_minutes REAL                           -- Duration in minutes
);

-- Index for Swift UUID lookups
CREATE INDEX idx_actions_uuid ON actions(uuid_id);
