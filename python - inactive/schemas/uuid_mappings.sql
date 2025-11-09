-- UUID Mappings Table
-- Written by Claude Code on 2025-10-19
--
-- Maps INTEGER database IDs to UUIDs for Swift/Python interoperability
--
-- Purpose:
-- - Database uses INTEGER AUTOINCREMENT ids (Python compatible)
-- - Swift domain models use UUID ids (type-safe, globally unique)
-- - This table provides stable bidirectional mapping
--
-- Strategy:
-- - First time Swift reads a record: generate UUID, insert mapping
-- - Subsequent reads: look up existing UUID from mapping
-- - This ensures UUID stability across fetches

CREATE TABLE IF NOT EXISTS uuid_mappings (
  entity_type TEXT NOT NULL,              -- Table name: 'actions', 'goals', 'personal_values', 'terms'
  database_id INTEGER NOT NULL,           -- The INTEGER id from the source table
  uuid TEXT NOT NULL,                     -- The UUID (as string) for Swift domain model
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,

  -- Composite primary key ensures one UUID per (entity_type, database_id)
  PRIMARY KEY (entity_type, database_id),

  -- Unique constraint ensures UUIDs aren't reused across entities
  UNIQUE (uuid)
);

-- Index for reverse lookups (UUID -> database_id)
CREATE INDEX IF NOT EXISTS idx_uuid_mappings_uuid ON uuid_mappings(uuid);

-- Index for entity type queries
CREATE INDEX IF NOT EXISTS idx_uuid_mappings_entity_type ON uuid_mappings(entity_type);
