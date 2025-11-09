-- conversation_history.sql
-- Stores AI assistant conversation exchanges for the Ten Week Goal App
--
-- Written by Claude Code on 2025-10-23
--
-- This table maintains a complete history of interactions with the AI assistant,
-- organized by session_id (incremented on each app launch) for temporal grouping.

CREATE TABLE IF NOT EXISTS conversation_history (
    -- Primary key: UUID for unique identification
    id TEXT PRIMARY KEY NOT NULL,

    -- Session identifier: Groups conversations from the same app session
    -- Incremented on each new session (app launch)
    session_id INTEGER NOT NULL,

    -- User's input prompt
    prompt TEXT NOT NULL,

    -- AI assistant's response
    response TEXT NOT NULL,

    -- Timestamp of this interaction (ISO8601 format)
    created_at TEXT NOT NULL,

    -- Optional user notes about this conversation
    freeform_notes TEXT,

    -- Future fields for analytics:
    -- tokens_used INTEGER,
    -- user_rating INTEGER,
    -- tool_calls_json TEXT

    -- Constraint: session_id must be positive
    CHECK (session_id > 0)
);

-- Index for fetching conversations by session
CREATE INDEX IF NOT EXISTS idx_conversation_session
ON conversation_history(session_id);

-- Index for fetching conversations by date
CREATE INDEX IF NOT EXISTS idx_conversation_created
ON conversation_history(created_at DESC);

-- Composite index for session + date queries
CREATE INDEX IF NOT EXISTS idx_conversation_session_created
ON conversation_history(session_id, created_at DESC);
