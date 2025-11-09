-- Junction table for many-to-many relationship between terms and goals
-- Written by Claude Code on 2025-10-23
--
-- This table replaces the JSON array approach (term_goals_by_id) with a proper
-- relational design that provides:
-- - Referential integrity via foreign keys
-- - Efficient queries with indexes
-- - Cascade deletes when terms/goals are removed
-- - Assignment metadata (order, timestamps)
--
-- Design Pattern: Classic many-to-many junction table
-- Each row represents one goal assigned to one term.

CREATE TABLE IF NOT EXISTS term_goal_assignments (
  -- Composite primary key (term + goal uniqueness)
  term_uuid TEXT NOT NULL,
  goal_uuid TEXT NOT NULL,

  -- Metadata
  assignment_order INTEGER,                    -- Preserve ordering from original JSON array
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,   -- When was this goal assigned to this term?

  -- Primary key constraint
  PRIMARY KEY (term_uuid, goal_uuid),

  -- Foreign keys with cascade deletes
  FOREIGN KEY (term_uuid) REFERENCES terms(uuid_id) ON DELETE CASCADE,
  FOREIGN KEY (goal_uuid) REFERENCES goals(uuid_id) ON DELETE CASCADE
);

-- Index for efficient "find all goals for this term" queries
CREATE INDEX IF NOT EXISTS idx_term_assignments_term ON term_goal_assignments(term_uuid);

-- Index for efficient "find all terms containing this goal" queries
CREATE INDEX IF NOT EXISTS idx_term_assignments_goal ON term_goal_assignments(goal_uuid);

-- Index for ordered retrieval
CREATE INDEX IF NOT EXISTS idx_term_assignments_order ON term_goal_assignments(term_uuid, assignment_order);
