-- SEMANTIC & LLM INFRASTRUCTURE SCHEMA
-- Written by Claude Code on 2025-11-12
--
-- PURPOSE: Foundation for semantic similarity, search, and LLM integration
--
-- DESIGN PRINCIPLES:
-- 1. Single embedding cache serves deduplication, search, and LLM RAG
-- 2. Simple conversation storage in v0.7.5, extensible for future phases
-- 3. Optimize for read-heavy workload (embeddings cached, rarely regenerated)

-- =============================================================================
-- SEMANTIC EMBEDDINGS CACHE
-- =============================================================================

-- Semantic Embeddings: Cached vector representations for similarity operations
-- Used by: DuplicationDetector (semantic matching), SearchService (semantic search),
--          LLM Tools (RetrieveMemoryTool for RAG)
CREATE TABLE semanticEmbeddings (
    id TEXT PRIMARY KEY,

    -- Entity reference
    entityType TEXT NOT NULL CHECK(entityType IN ('goal', 'action', 'value', 'measure', 'term', 'conversation')),
    entityId TEXT NOT NULL,

    -- Source text tracking (for cache invalidation)
    textHash TEXT NOT NULL,         -- SHA256 of source text (detect changes)
    sourceText TEXT NOT NULL,       -- Original text (for debugging/audit)

    -- Embedding data
    embedding BLOB NOT NULL,        -- Serialized float32 array from NLEmbedding
    embeddingModel TEXT NOT NULL,   -- 'NLEmbedding-sentence-english' (for future model migrations)
    dimensionality INTEGER NOT NULL, -- Vector size (for validation)

    -- Metadata
    generatedAt TEXT NOT NULL,
    logTime TEXT NOT NULL,

    -- Ensure one embedding per (entity, text) combination
    UNIQUE(entityType, entityId, textHash)
);

-- Indexes for fast lookups
CREATE INDEX idx_semantic_embeddings_entity ON semanticEmbeddings(entityType, entityId);
CREATE INDEX idx_semantic_embeddings_type ON semanticEmbeddings(entityType);
CREATE INDEX idx_semantic_embeddings_generated ON semanticEmbeddings(generatedAt);

-- =============================================================================
-- USAGE NOTES: semanticEmbeddings
-- =============================================================================
--
-- Cache Invalidation Strategy:
-- When entity text changes, textHash changes → new embedding generated
-- Old embeddings automatically orphaned (cleaned up by periodic purge)
--
-- Example: Goal title changes from "Run marathon" to "Complete 26.2 miles"
-- 1. New embedding generated with new textHash
-- 2. Old embedding remains until purge
-- 3. No foreign key cascade needed (cache is ephemeral)
--
-- Lazy Generation Pattern:
-- Embeddings generated on-demand during:
-- - Duplicate detection (when checking new entity)
-- - Semantic search (first query for entity type)
-- - LLM tool calls (when RetrieveMemoryTool queries)
--
-- Background Generation:
-- Optional batch process can pre-generate embeddings for:
-- - All existing goals/actions/values (one-time migration)
-- - New entities created in last 24 hours (daily cron)
--
-- =============================================================================

-- =============================================================================
-- LLM CONVERSATION STORAGE (v0.7.5 - Simple Version)
-- =============================================================================

-- LLM Conversations: Header records for conversation threads
-- Used by: GoalCoachViewModel, ValuesAlignmentCoachViewModel
CREATE TABLE llmConversations (
    id TEXT PRIMARY KEY,

    -- User and type
    userId TEXT NOT NULL,           -- For multi-user support (future)
    conversationType TEXT NOT NULL CHECK(conversationType IN (
        'goal_setting',             -- Conversational goal creation
        'reflection',               -- Weekly/daily reflection
        'values_alignment',         -- Values alignment analysis
        'general'                   -- Open-ended coaching
    )),

    -- Temporal tracking
    startedAt TEXT NOT NULL,
    lastMessageAt TEXT NOT NULL,

    -- Session management (for context window overflow handling)
    sessionNumber INTEGER NOT NULL DEFAULT 1,

    -- Lifecycle
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'archived', 'deleted')),

    logTime TEXT NOT NULL
);

CREATE INDEX idx_llm_conversations_user ON llmConversations(userId, status);
CREATE INDEX idx_llm_conversations_type ON llmConversations(conversationType, status);
CREATE INDEX idx_llm_conversations_active ON llmConversations(status, lastMessageAt);

-- LLM Messages: Individual messages in conversation threads
-- Used by: Conversation persistence, UI rendering
CREATE TABLE llmMessages (
    id TEXT PRIMARY KEY,
    conversationId TEXT NOT NULL,

    -- Message content
    role TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system', 'tool_call', 'tool_response')),
    content TEXT NOT NULL,          -- User message, assistant response, or tool output

    -- Optional structured data (for tool calls and responses)
    structuredDataJSON TEXT,        -- Serialized @Generable types (GoalCreationData, etc.)
    toolName TEXT,                  -- If role='tool_call', which tool was invoked

    -- Metadata
    timestamp TEXT NOT NULL,
    sessionNumber INTEGER NOT NULL DEFAULT 1,

    -- Lifecycle
    isArchived INTEGER NOT NULL DEFAULT 0,  -- Moved out of active context window

    FOREIGN KEY (conversationId) REFERENCES llmConversations(id) ON DELETE CASCADE
);

CREATE INDEX idx_llm_messages_conversation ON llmMessages(conversationId, isArchived, timestamp);
CREATE INDEX idx_llm_messages_session ON llmMessages(conversationId, sessionNumber);

-- =============================================================================
-- USAGE NOTES: llmConversations + llmMessages
-- =============================================================================
--
-- Simple v0.7.5 Pattern:
-- - One conversation per goal-setting session
-- - All messages stored with role (user/assistant/tool_call/tool_response)
-- - No token counting yet (Phase 2 feature)
-- - No transcript serialization yet (Phase 2 feature)
--
-- Example Flow:
-- 1. User starts conversation → INSERT llmConversations
-- 2. User: "I want to write more" → INSERT llmMessages (role='user')
-- 3. LLM calls GetValuesTool → INSERT llmMessages (role='tool_call', toolName='getPersonalValues')
-- 4. Tool returns values → INSERT llmMessages (role='tool_response')
-- 5. LLM: "I see you value creativity..." → INSERT llmMessages (role='assistant')
--
-- Context Window Management (Phase 2):
-- When conversation exceeds 15 messages:
-- 1. Increment sessionNumber
-- 2. Mark old messages as isArchived=1
-- 3. Generate summary, store in new system message
-- 4. Continue with fresh context window
--
-- Conversation Resumption:
-- 1. Load llmMessages WHERE conversationId = X AND isArchived = 0
-- 2. Reconstruct Transcript from messages
-- 3. Create new LanguageModelSession with transcript
--
-- =============================================================================

-- =============================================================================
-- FUTURE SCHEMA EXTENSIONS (Phase 2+)
-- =============================================================================
--
-- Phase 2: Token Tracking & Summarization
-- ALTER TABLE llmConversations ADD COLUMN tokenCount INTEGER DEFAULT 0;
-- ALTER TABLE llmConversations ADD COLUMN summaryText TEXT;
-- ALTER TABLE llmMessages ADD COLUMN tokenCount INTEGER;
--
-- Phase 3: RAG & Memory Management
-- CREATE TABLE llmMemoryChunks (
--     id TEXT PRIMARY KEY,
--     userId TEXT NOT NULL,
--     contentType TEXT NOT NULL,
--     contentId TEXT NOT NULL,
--     textChunk TEXT NOT NULL,
--     embeddingId TEXT NOT NULL,
--     relevanceScore REAL,
--     FOREIGN KEY (embeddingId) REFERENCES semanticEmbeddings(id)
-- );
--
-- Phase 3: Usage Analytics
-- CREATE TABLE llmUsageTracking (
--     id TEXT PRIMARY KEY,
--     userId TEXT NOT NULL,
--     date TEXT NOT NULL,
--     conversationCount INTEGER DEFAULT 0,
--     messageCount INTEGER DEFAULT 0,
--     toolCallCount INTEGER DEFAULT 0,
--     averageResponseTime REAL
-- );
--
-- =============================================================================

-- =============================================================================
-- MIGRATION PATH FROM CURRENT SCHEMA
-- =============================================================================
--
-- This schema extends the existing schema_current.sql without modifying it.
-- No foreign keys to existing tables (semanticEmbeddings is a cache layer).
--
-- Integration points:
-- 1. semanticEmbeddings.entityId references goals.id, actions.id, personalValues.id
--    (no FK constraint - cache can outlive entities)
-- 2. LLM tools query existing tables via FetchKeyRequest patterns
-- 3. LLM CreateGoalTool uses GoalCoordinator (writes to goals + expectations tables)
--
-- =============================================================================
