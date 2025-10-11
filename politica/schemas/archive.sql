-- Archive table: Stores deleted/updated records for recovery and audit
-- Written by Claude Code on 2025-10-10

CREATE TABLE IF NOT EXISTS archive (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_table TEXT NOT NULL,           -- 'actions', 'goals', etc.
  source_id INTEGER,                    -- Original record ID (if known)
  record_data TEXT NOT NULL,            -- Full JSON of the archived record
  reason TEXT NOT NULL,                 -- 'delete', 'update', 'manual_archive'
  archived_at TEXT DEFAULT CURRENT_TIMESTAMP,
  archived_by TEXT DEFAULT 'system',    -- Could track which user/script
  notes TEXT                            -- Optional context about why archived
);

-- Index for faster lookups by source
CREATE INDEX IF NOT EXISTS idx_archive_source ON archive(source_table, source_id);
CREATE INDEX IF NOT EXISTS idx_archive_date ON archive(archived_at);