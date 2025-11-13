# Semantic Architecture (v0.7.5)
## Unified Semantic Layer for Ten Week Goal App

**Created:** 2025-11-12
**Status:** Foundation Complete
**Version:** 0.7.5 (Pre-Launch)
**Purpose:** Single source of truth for semantic infrastructure

---

## Executive Summary

The Ten Week Goal App's semantic layer provides **one unified service** for all semantic operations:
1. **Deduplication** - Enhanced duplicate detection with semantic awareness
2. **Search** - Semantic search capabilities (future Phase 2)
3. **LLM Integration** - RAG memory retrieval and tool context (Phase 2-3)

**Key Decision:** Build once, use everywhere. The `SemanticService` + `EmbeddingCache` architecture serves all three use cases.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ Deduplication  │  │    Search    │  │   LLM Tools     │ │
│  │   Detector     │  │   Service    │  │ (RAG context)   │ │
│  └────────┬───────┘  └──────┬───────┘  └────────┬────────┘ │
└───────────┼──────────────────┼───────────────────┼──────────┘
            │                  │                   │
            └──────────┬───────┴───────┬───────────┘
                       │               │
            ┌──────────▼───────────────▼──────────┐
            │     SemanticService (Core)          │
            │  - NLEmbedding wrapper              │
            │  - Cosine similarity                │
            │  - Text normalization               │
            └──────────┬──────────────────────────┘
                       │
            ┌──────────▼──────────┐
            │   EmbeddingCache    │
            │  - Database storage │
            │  - Lazy generation  │
            │  - Hash invalidation│
            └──────────┬──────────┘
                       │
            ┌──────────▼──────────┐
            │   SQLite Database   │
            │ semanticEmbeddings  │
            └─────────────────────┘
```

---

## Core Components

### 1. SemanticService.swift

**Purpose:** Core embedding generation and similarity calculation using NLEmbedding

**Key Methods:**
```swift
// Generate embedding for text
func generateEmbedding(for text: String) -> Result<SemanticEmbedding?, SemanticError>

// Calculate similarity between two embeddings
func similarity(between: SemanticEmbedding, and: SemanticEmbedding) -> Double

// Direct text-to-text similarity (on-the-fly embedding generation)
func textSimilarity(between: String, and: String) -> Result<Double, SemanticError>

// Find most similar embeddings from candidates
func findSimilar(to query: SemanticEmbedding,
                 in candidates: [SemanticEmbedding],
                 limit: Int,
                 threshold: Double) -> [(embedding, similarity)]
```

**Implementation Details:**
- Uses `NLEmbedding.sentenceEmbedding(for: .english)` for on-device embedding generation
- Cosine similarity calculation: `dot(a,b) / (||a|| * ||b||)`
- Text normalization: lowercase, trim whitespace, collapse multiple spaces
- SHA256 hashing for change detection
- Graceful degradation: Returns nil if NLEmbedding unavailable

**Performance:**
- Embedding generation: ~10-50ms per text
- Similarity calculation: <1ms (vector operations only)
- Dimensionality: Typically 64-128 dimensions (NLEmbedding model-dependent)

### 2. EmbeddingCache.swift

**Purpose:** Database persistence layer for semantic embeddings with lazy generation

**Key Methods:**
```swift
// Get cached embedding or generate new one
func getOrGenerateEmbedding(for text: String,
                            entityType: EntityType,
                            entityId: UUID) async throws -> SemanticEmbedding?

// Batch operations for multiple entities
func getOrGenerateEmbeddings(
    for entities: [(text, entityType, entityId)]
) async throws -> [SemanticEmbedding?]

// Cache management
func invalidate(entityId: UUID, entityType: EntityType) async throws
func purgeOldEmbeddings(olderThan: Date) async throws -> Int
func getCacheStatistics() async throws -> CacheStatistics
```

**Caching Strategy:**
- **Lazy Generation:** Embeddings created on first access (deduplication check, search query, LLM tool call)
- **Hash-Based Invalidation:** When entity text changes, textHash changes → new embedding generated
- **Automatic Cleanup:** Old embeddings orphaned (purged by periodic maintenance)
- **No Foreign Keys:** Cache is ephemeral, can outlive entities

**Database Schema:**
```sql
CREATE TABLE semanticEmbeddings (
    id TEXT PRIMARY KEY,
    entityType TEXT NOT NULL,       -- 'goal', 'action', 'value', etc.
    entityId TEXT NOT NULL,
    textHash TEXT NOT NULL,         -- SHA256 of source text
    sourceText TEXT NOT NULL,
    embedding BLOB NOT NULL,        -- Serialized float32 array
    embeddingModel TEXT NOT NULL,   -- 'NLEmbedding-sentence-english'
    dimensionality INTEGER NOT NULL,
    generatedAt TEXT NOT NULL,
    logTime TEXT NOT NULL,
    UNIQUE(entityType, entityId, textHash)
);
```

### 3. Database Models

#### CachedEmbedding (@Table)
```swift
@Table("semanticEmbeddings")
public struct CachedEmbedding: DomainEntity {
    @Column("id") public let id: UUID
    @Column("entityType") public let entityType: String
    @Column("entityId") public let entityId: UUID
    @Column("textHash") public let textHash: String
    @Column("sourceText") public let sourceText: String
    @Column("embedding") public let embedding: Data  // Serialized float32[]
    @Column("embeddingModel") public let embeddingModel: String
    @Column("dimensionality") public let dimensionality: Int
    @Column("generatedAt") public let generatedAt: Date
    @Column("logTime") public let logTime: Date
}
```

#### SemanticEmbedding (Value Type)
```swift
public struct SemanticEmbedding: Sendable, Hashable {
    public let vector: [Double]
    public let sourceText: String
    public let textHash: String
    public let modelIdentifier: String
    public let generatedAt: Date
    public var dimensionality: Int { vector.count }
}
```

---

## Use Case 1: Enhanced Deduplication

### Current State (v0.6.0)
- **LSH-based detection:** MinHash signatures, Jaccard similarity
- **Syntactic matching:** Good for exact/near-exact text matches
- **Misses paraphrases:** "Run marathon" vs "Complete 26.2 miles" → low similarity

### Enhanced State (v0.7.5)
- **Hybrid scoring:** Combines LSH (syntactic) + Semantic (meaning)
- **Formula:** `composite = 0.6 * semantic + 0.4 * syntactic`
- **Better accuracy:** Catches paraphrases and conceptual duplicates

### Implementation Pattern
```swift
// In DuplicationDetector extension
public func enhancedSimilarity(
    _ text1: String,
    _ text2: String,
    using semanticService: SemanticService,
    embeddingCache: EmbeddingCache
) async throws -> Double {
    // Try semantic similarity first
    if let emb1 = try await embeddingCache.getOrGenerateEmbedding(
        for: text1, entityType: .goal, entityId: entity1.id
    ),
    let emb2 = try await embeddingCache.getOrGenerateEmbedding(
        for: text2, entityType: .goal, entityId: entity2.id
    ) {
        let semanticScore = semanticService.similarity(between: emb1, and: emb2)
        let syntacticScore = lsh.textSimilarity(text1, text2)

        // Hybrid scoring: semantic is primary, syntactic is secondary
        return 0.6 * semanticScore + 0.4 * syntacticScore
    }

    // Fallback to pure LSH if NLEmbedding unavailable
    return lsh.textSimilarity(text1, text2)
}
```

### Backwards Compatibility
- Graceful degradation if NLEmbedding unavailable (iOS 13+ but model may not be installed)
- Falls back to pure LSH similarity
- No breaking changes to existing DuplicationDetector protocol

---

## Use Case 2: Semantic Search (Future - Phase 2)

### Planned Feature (v0.8-v0.9)
User can search goals/actions/values by meaning:
- "Find goals about writing" → Returns goals with "author", "manuscript", "publish"
- "Show actions related to health" → Returns "workout", "nutrition", "sleep" actions

### Implementation Approach
```swift
// SearchService.swift (future)
public final class SearchService {
    func search(_ query: String,
                in entityType: EntityType,
                limit: Int = 10) async throws -> [SearchResult] {
        // 1. Generate query embedding
        let queryEmbedding = try await embeddingCache.getOrGenerateEmbedding(
            for: query, entityType: .conversation, entityId: UUID()
        )

        // 2. Fetch all cached embeddings for entity type
        let candidates = try await database.read { db in
            try CachedEmbedding
                .where { $0.entityType.eq(entityType.rawValue) }
                .fetchAll(db)
        }

        // 3. Calculate similarities
        let results = semanticService.findSimilar(
            to: queryEmbedding,
            in: candidates.compactMap { /* reconstruct embedding */ },
            limit: limit,
            threshold: 0.5  // Minimum 50% similarity
        )

        return results.map { /* map to SearchResult */ }
    }
}
```

### Performance Considerations
- **Linear scan:** O(n) for n embeddings (acceptable for <10,000 entities)
- **Future optimization:** Vector index (e.g., FAISS, Annoy) for >10,000 entities
- **Batch fetching:** Load all embeddings at once, compute similarities in-memory

---

## Use Case 3: LLM Integration (Phase 2-3)

### v0.7.5: Basic LLM (Current)
**Implemented:**
- Simple conversational goal setting
- 3 tools: GetActiveGoalsTool, GetPersonalValuesTool, CreateGoalTool
- Basic conversation storage (llmConversations + llmMessages tables)

**NOT Using Semantic Layer Yet:**
- Tools query database directly via FetchKeyRequest
- No RAG memory retrieval (Phase 2 feature)

### Phase 2: RAG Memory Retrieval (v0.8-v0.9)
**Planned:**
- RetrieveMemoryTool uses semantic search to find relevant context
- LLM asks: "What goals has the user set related to fitness?"
- Tool uses semantic search to find relevant goals/actions/values
- Returns top-k most similar items as context

**Implementation:**
```swift
struct RetrieveMemoryTool: Tool {
    func call(arguments: Arguments) async throws -> String {
        // 1. Embed query using SemanticService
        let queryEmbedding = try await embeddingCache.getOrGenerateEmbedding(
            for: arguments.query,
            entityType: .conversation,
            entityId: UUID()
        )

        // 2. Semantic search across all entity types
        let goals = try await searchEmbeddings(
            queryEmbedding, entityType: .goal, limit: 3
        )
        let actions = try await searchEmbeddings(
            queryEmbedding, entityType: .action, limit: 3
        )
        let values = try await searchEmbeddings(
            queryEmbedding, entityType: .value, limit: 2
        )

        // 3. Format as context for LLM
        return formatMemoryContext(goals, actions, values)
    }
}
```

### Phase 3: Advanced LLM Features (v1.0+)
- Values alignment analysis (AnalyzeValueAlignmentTool)
- Weekly reflection prompts (GenerateReflectionPromptsTool)
- Progressive summarization (context window management)
- Conversation persistence and resumption

---

## Database Schema (semantic_llm_schema.sql)

### Embedding Cache
```sql
CREATE TABLE semanticEmbeddings (
    id TEXT PRIMARY KEY,
    entityType TEXT NOT NULL CHECK(entityType IN
        ('goal', 'action', 'value', 'measure', 'term', 'conversation')),
    entityId TEXT NOT NULL,
    textHash TEXT NOT NULL,
    sourceText TEXT NOT NULL,
    embedding BLOB NOT NULL,
    embeddingModel TEXT NOT NULL,
    dimensionality INTEGER NOT NULL,
    generatedAt TEXT NOT NULL,
    logTime TEXT NOT NULL,
    UNIQUE(entityType, entityId, textHash)
);

CREATE INDEX idx_semantic_embeddings_entity ON semanticEmbeddings(entityType, entityId);
CREATE INDEX idx_semantic_embeddings_type ON semanticEmbeddings(entityType);
```

### LLM Conversations (v0.7.5 - Simple Version)
```sql
CREATE TABLE llmConversations (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    conversationType TEXT NOT NULL CHECK(conversationType IN
        ('goal_setting', 'reflection', 'values_alignment', 'general')),
    startedAt TEXT NOT NULL,
    lastMessageAt TEXT NOT NULL,
    sessionNumber INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN
        ('active', 'archived', 'deleted')),
    logTime TEXT NOT NULL
);

CREATE TABLE llmMessages (
    id TEXT PRIMARY KEY,
    conversationId TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN
        ('user', 'assistant', 'system', 'tool_call', 'tool_response')),
    content TEXT NOT NULL,
    structuredDataJSON TEXT,
    toolName TEXT,
    timestamp TEXT NOT NULL,
    sessionNumber INTEGER NOT NULL DEFAULT 1,
    isArchived INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (conversationId) REFERENCES llmConversations(id) ON DELETE CASCADE
);
```

---

## Performance Characteristics

### Embedding Generation
| Operation | Latency | Notes |
|-----------|---------|-------|
| Generate single embedding | 10-50ms | NLEmbedding inference |
| Batch generate (10 texts) | 100-500ms | Parallelized |
| Cache hit | <1ms | Database read only |
| Cache miss | 10-50ms | Generate + cache write |

### Similarity Calculation
| Operation | Latency | Notes |
|-----------|---------|-------|
| Cosine similarity (2 vectors) | <0.1ms | Pure math, very fast |
| Compare 1 query vs 100 candidates | <10ms | Linear scan |
| Compare 1 query vs 1000 candidates | <100ms | Still acceptable |

### Cache Performance
| Metric | Value | Notes |
|--------|-------|-------|
| Embedding size (serialized) | 256-512 bytes | float32 array |
| Cache size (1000 embeddings) | ~250-500 KB | Negligible |
| Cache hit rate (steady state) | >80% | After first week of use |
| Purge frequency | Weekly | Delete embeddings >30 days old |

---

## Migration Strategy

### From Current State (v0.6.0)
**No breaking changes:**
- Existing LSH deduplication continues to work
- New semantic layer is opt-in enhancement
- Graceful degradation if NLEmbedding unavailable

### Database Migration
```sql
-- Add semantic_llm_schema.sql tables to existing database
-- No foreign keys to existing tables (cache is independent)
-- No changes to existing schema_current.sql tables
```

### Code Migration
```swift
// Before (v0.6.0): Pure LSH
let similarity = lsh.textSimilarity(title1, title2)

// After (v0.7.5): Hybrid semantic + LSH
let similarity = try await enhancedSimilarity(
    title1, title2,
    using: semanticService,
    embeddingCache: cache
)
// Falls back to LSH if semantic unavailable
```

---

## Testing Strategy

### Unit Tests
```swift
// SemanticService tests
func testEmbeddingGeneration()
func testCosineSimilarity()
func testTextNormalization()
func testGracefulDegradation()

// EmbeddingCache tests
func testLazyGeneration()
func testHashInvalidation()
func testBatchOperations()
func testCacheStatistics()

// Hybrid Deduplication tests
func testSemanticEnhancement()
func testFallbackToLSH()
func testParaphraseDetection()
```

### Integration Tests
```swift
// End-to-end deduplication
func testEnhancedDuplicateDetection() async throws {
    let detector = GoalDetector()
    let goal1 = createGoal(title: "Run a marathon")
    let goal2 = createGoal(title: "Complete 26.2 miles")

    let duplicates = try await detector.findDuplicates(
        for: goal1,
        in: [goal2],
        using: lshService,
        semanticService: semanticService,
        embeddingCache: cache
    )

    XCTAssertEqual(duplicates.count, 1)
    XCTAssertGreaterThan(duplicates[0].similarity, 0.7)  // High semantic match
}
```

### Performance Tests
```swift
func testEmbeddingCachePerformance() async throws {
    // Generate 1000 embeddings
    let texts = (1...1000).map { "Goal \($0)" }

    measure {
        let embeddings = try await cache.getOrGenerateEmbeddings(
            for: texts.map { ($0, .goal, UUID()) }
        )
    }

    // Should complete in <5 seconds for cold cache
    // Should complete in <500ms for warm cache
}
```

---

## Future Enhancements (Post-v0.7.5)

### Phase 2 (v0.8-v0.9): Advanced Semantic Features
- **Semantic Search:** User-facing search by meaning
- **RAG Memory:** RetrieveMemoryTool for LLM context injection
- **Background Indexing:** Pre-generate embeddings for all entities
- **Conversation Persistence:** Resume conversations across sessions

### Phase 3 (v1.0+): Advanced LLM Features
- **Values Alignment Coach:** AnalyzeValueAlignmentTool with structured reports
- **Reflection Prompts:** GenerateReflectionPromptsTool for weekly reflections
- **Progressive Summarization:** Context window management for long conversations
- **Multi-Language Support:** Extend SemanticService for Spanish, French, etc.

### Phase 4 (v1.1+): Optimization
- **Vector Index:** Replace linear scan with approximate nearest neighbor (ANN)
- **Quantization:** Compress embeddings (float32 → int8) for storage efficiency
- **Custom Embeddings:** Fine-tuned model for goal-setting domain (Mac training pipeline)
- **Incremental Updates:** Delta embeddings for partial text changes

---

## Design Decisions & Rationale

### Why NLEmbedding (Not Foundation Models)?
- ✅ Foundation Models don't expose embedding vectors (no RAG support)
- ✅ NLEmbedding is lightweight, fast, offline-capable
- ✅ Available iOS 13+, works on all devices
- ✅ Good enough for deduplication, search, and LLM RAG

### Why Hybrid LSH + Semantic (Not Pure Semantic)?
- ✅ LSH is fast (O(1) after signature generation)
- ✅ Semantic catches paraphrases LSH misses
- ✅ Hybrid scoring gets best of both worlds
- ✅ Graceful degradation if semantic unavailable

### Why Lazy Generation (Not Pre-compute All)?
- ✅ User may create 100 goals but only check duplicates for 10
- ✅ Saves computation and storage for unused embeddings
- ✅ Hash-based invalidation handles text changes elegantly
- ✅ Can always add background indexing later (Phase 2)

### Why Single Semantic Service (Not Multiple)?
- ✅ Deduplication, search, and LLM all need same embeddings
- ✅ One cache serves all use cases
- ✅ Consistent similarity calculation across features
- ✅ Simpler architecture, easier to maintain

---

## References

### Internal Documentation
- [LLM_INTEGRATION_PLAN.md](ML,%20LLM,%20and%20Semantics/LLM_INTEGRATION_PLAN.md) - Foundation Models implementation details
- [SEMANTIC_SIMILARITY_RESEARCH_20251112.md](ML,%20LLM,%20and%20Semantics/SEMANTIC_SIMILARITY_RESEARCH_20251112.md) - Research on Apple's semantic APIs
- [EMBEDDING_APPROACHES_COMPARISON.md](ML,%20LLM,%20and%20Semantics/EMBEDDING_APPROACHES_COMPARISON.md) - Comparison of embedding strategies
- [VERSIONING.md](/VERSIONING.md) - v0.7.5 roadmap and timeline

### Apple Documentation
- [NLEmbedding API Reference](https://developer.apple.com/documentation/naturallanguage/nlembedding)
- [Finding Similarities Between Pieces of Text](https://developer.apple.com/documentation/naturallanguage/finding-similarities-between-pieces-of-text)
- [Foundation Models Framework](https://developer.apple.com/documentation/foundationmodels)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-12
**Status:** Foundation Complete, LLM Basic Integration In Progress
**Next Review:** After Phase 2 (v0.8-v0.9) semantic search implementation
