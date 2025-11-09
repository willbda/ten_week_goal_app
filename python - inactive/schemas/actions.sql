-- Actions Table
-- Updated 2025-10-16 to align with new categoriae structure
-- Updated 2025-10-18 to use UUID primary key for Swift compatibility
-- Updated 2025-10-19 to support dual ID system (Python INTEGER + Swift UUID)
-- Updated 2025-10-21 to migrate Python to use UUID as primary identifier
-- Updated 2025-10-22 to make uuid_id the PRIMARY KEY for GRDB compatibility
--
-- Primary Key: uuid_id TEXT (both Python and Swift use this)
-- Legacy id INTEGER removed - no longer needed for backward compatibility
--
-- Inherits from Persistable protocol:
--   - title: Short identifier (maps to Swift title, Python title)
--   - description: Optional elaboration (maps to Swift detailedDescription)
--   - notes: Freeform notes (maps to Swift freeformNotes)
--   - log_time: When action was logged (maps to Swift logTime)
--
-- Action-specific fields:
--   - measurement_units_by_amount: JSON dict of measurements
--   - duration_minutes: How long the action took
--   - start_time: When action started (if tracked)

CREATE TABLE IF NOT EXISTS actions (
    uuid_id TEXT PRIMARY KEY,                       -- PRIMARY KEY (e.g., "550e8400-e29b-41d4-a716-446655440000")
    title TEXT,                                     -- Short identifier (e.g., "Morning run")
    description TEXT,                               -- Optional elaboration
    notes TEXT,                                     -- Freeform notes
    log_time TEXT NOT NULL,                         -- When logged (ISO format)
    measurement_units_by_amount TEXT,               -- JSON dict: {"km": 5.0, "minutes": 30}
    start_time TEXT,                                -- When action started (ISO format)
    duration_minutes REAL                           -- Duration in minutes
);
