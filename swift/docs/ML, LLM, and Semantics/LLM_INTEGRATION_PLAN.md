# LLM Integration Plan for Ten Week Goal App
## Foundation Models Implementation Strategy

**Written by Claude Code on 2025-11-12**
**Based on:** `FOUNDATION_MODELS_ARCHITECTURE_RESEARCH.md`, `FOUNDATION_MODELS_IMPLEMENTATION_GUIDE.md`
**Target:** iOS 26+, macOS 26+, visionOS 26+ (Apple Intelligence compatible devices)

---

## Executive Summary

This plan outlines integration of Apple's on-device Foundation Models framework into the Ten Week Goal App. The implementation follows Apple's documented best practices for:

- **Two-model architecture** (simplified from three-model)
- **Structured output** via @Generable types
- **Conversation persistence** via Transcript API
- **Progressive summarization** for long conversations
- **RAG pattern** for memory management

**Key Decision:** Use simplified two-model architecture (Memory Manager + User-Facing Agent) rather than three-model (add Orchestrator) for reduced latency and complexity.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Database Schema Extensions](#database-schema-extensions)
3. [Tool Implementation Strategy](#tool-implementation-strategy)
4. [Implementation Phases](#implementation-phases)
5. [Integration Points](#integration-points)
6. [Testing Strategy](#testing-strategy)
7. [Performance Considerations](#performance-considerations)

---

## Architecture Overview

### Two-Model Design (Recommended)

```
┌─────────────────────────────────────────────────────┐
│               SwiftUI Views                         │
│  - GoalSettingCoachView                             │
│  - ValuesAlignmentView                              │
│  - WeeklyReflectionView                             │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│          Model 2: User-Facing Agent                 │
│  ┌────────────────────────────────────────────┐    │
│  │ LanguageModelSession (persistent)          │    │
│  │ - Instructions: Goal coach personality     │    │
│  │ - Tools: 8-10 domain-specific tools        │    │
│  │ - Direct conversation with user            │    │
│  └────────────────────────────────────────────┘    │
└──────────────┬──────────────────┬───────────────────┘
               │                  │
               │ Tool Calls       │ Database Writes
               ▼                  ▼
┌──────────────────────┐  ┌──────────────────┐
│  Query Tools         │  │   Coordinators   │
│  - RetrieveMemory    │  │   - GoalCoord    │
│  - GetGoals          │  │   - ActionCoord  │
│  - GetValues         │  │   - ValueCoord   │
│  - GetActions        │  │   (validated)    │
└──────────┬───────────┘  └────────┬─────────┘
           │                       │
           ▼                       ▼
┌─────────────────────────────────────────────────────┐
│              SQLite Database                        │
│  ┌────────────────────────────────────────────┐    │
│  │ LLM Tables (new)                           │    │
│  │ - llmConversations                         │    │
│  │ - llmMessages (transcript persistence)     │    │
│  │ - llmMemoryEmbeddings (RAG)                │    │
│  └────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────┐    │
│  │ Domain Tables (existing)                   │    │
│  │ - goals, actions, personalValues           │    │
│  │ - expectationMeasures, goalRelevances      │    │
│  └────────────────────────────────────────────┘    │
└──────────────────┬─────────────────────────────────┘
                   │
                   │ Background Job (async)
                   ▼
┌─────────────────────────────────────────────────────┐
│        Model 1: Memory Manager (Background)         │
│  ┌────────────────────────────────────────────┐    │
│  │ - Periodic summarization                   │    │
│  │ - Embedding generation for RAG             │    │
│  │ - Runs offline, triggered by events        │    │
│  │ - No user interaction                      │    │
│  └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Why Two Models (Not Three)

**Model 1 (Background):**
- Runs asynchronously, not per-message
- Summarizes conversations periodically
- Generates embeddings for RAG
- No latency impact on user

**Model 2 (Foreground):**
- Handles all user conversation
- Uses `RetrieveMemoryTool` to query Model 1's outputs
- Single session per conversation (simpler state)
- Direct tool calling for context injection

**Avoids Model 3 (Orchestrator):**
- ❌ No intermediate prompt reformulation layer
- ✅ Lower latency (one model hop instead of two)
- ✅ Simpler architecture (fewer moving parts)
- ✅ Tool calling handles context injection (Apple's documented pattern)

---

## Database Schema Extensions

### 1. Conversation Persistence Tables

```sql
-- LLM Conversations: Header records for conversation threads
CREATE TABLE llmConversations (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,  -- For multi-user support
    conversationType TEXT NOT NULL,  -- 'goal_setting', 'reflection', 'values_alignment'
    startedAt TEXT NOT NULL,
    lastMessageAt TEXT NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('active', 'archived', 'summarized')),
    summaryText TEXT,  -- Progressive summary
    tokenCount INTEGER NOT NULL DEFAULT 0,  -- Track context budget
    sessionNumber INTEGER NOT NULL DEFAULT 1,  -- Which session iteration
    logTime TEXT NOT NULL
);

-- LLM Messages: Individual transcript entries
CREATE TABLE llmMessages (
    id TEXT PRIMARY KEY,
    conversationId TEXT NOT NULL,
    entryType TEXT NOT NULL,  -- 'instructions', 'prompt', 'response', 'toolCall', 'toolOutput'
    contentJSON TEXT NOT NULL,  -- Serialized Transcript.Entry
    tokenCount INTEGER NOT NULL,  -- Estimated tokens for this entry
    timestamp TEXT NOT NULL,
    sessionNumber INTEGER NOT NULL,  -- Which session this belongs to
    isArchived INTEGER DEFAULT 0,  -- Moved out of active context
    FOREIGN KEY (conversationId) REFERENCES llmConversations(id) ON DELETE CASCADE
);

CREATE INDEX idx_llm_messages_conversation ON llmMessages(conversationId, isArchived);
CREATE INDEX idx_llm_messages_timestamp ON llmMessages(conversationId, timestamp);
```

### 2. RAG Memory Embeddings

```sql
-- LLM Memory Embeddings: Semantic search for user context
CREATE TABLE llmMemoryEmbeddings (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    contentType TEXT NOT NULL,  -- 'goal', 'action', 'reflection', 'conversation'
    contentId TEXT NOT NULL,  -- FK to goals/actions/etc
    textChunk TEXT NOT NULL,  -- Actual text for retrieval
    embedding BLOB NOT NULL,  -- Serialized float array from NLEmbedding
    timestamp TEXT NOT NULL,
    logTime TEXT NOT NULL
);

CREATE INDEX idx_llm_embeddings_user_type ON llmMemoryEmbeddings(userId, contentType);
CREATE INDEX idx_llm_embeddings_content ON llmMemoryEmbeddings(contentType, contentId);
```

### 3. Token Tracking and Quotas (Optional)

```sql
-- LLM Usage Tracking: Monitor on-device inference usage
CREATE TABLE llmUsageTracking (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    date TEXT NOT NULL,  -- Daily rollup
    conversationCount INTEGER NOT NULL DEFAULT 0,
    messageCount INTEGER NOT NULL DEFAULT 0,
    totalTokens INTEGER NOT NULL DEFAULT 0,
    toolCallCount INTEGER NOT NULL DEFAULT 0,
    averageResponseTime REAL,  -- Milliseconds
    logTime TEXT NOT NULL
);

CREATE UNIQUE INDEX idx_llm_usage_user_date ON llmUsageTracking(userId, date);
```

---

## Tool Implementation Strategy

### Tool Categories

**Query Tools** (Read-only, fast)
1. `GetActiveGoalsTool` - Fetch user's current goals
2. `GetPersonalValuesTool` - Fetch value hierarchy
3. `GetRecentActionsTool` - Fetch recent logged actions
4. `GetCurrentTermTool` - Fetch active term details
5. `RetrieveMemoryTool` - RAG semantic search

**Write Tools** (Use coordinators, validated)
6. `CreateGoalTool` - Generate GoalCreationData → GoalCoordinator
7. `CreateActionTool` - Generate ActionFormData → ActionCoordinator
8. `UpdateGoalProgressTool` - Log contributions → ActionGoalContribution

**Analysis Tools** (LLM-powered)
9. `AnalyzeValueAlignmentTool` - Generate alignment report
10. `GenerateReflectionPromptsTool` - Weekly reflection questions

### Tool Design Pattern

All tools follow this structure:

```swift
/// Tool for [description]
/// Written by Claude Code on 2025-11-12
struct MyTool: Tool {
    let name = "toolName"
    let description = "Concise description for LLM (under 100 chars)"

    // ALWAYS use @Generable for type-safe arguments
    @Generable
    struct Arguments {
        @Guide(description: "Clear semantic meaning")
        var param: Type

        @Guide(description: "Optional filter", .range(1...10))
        var limit: Int = 5
    }

    // ALWAYS use Sendable types for output
    @Generable
    struct Result: Sendable {
        var data: [Item]
        var success: Bool
        var message: String
    }

    // Dependency injection
    private let database: any DatabaseReader

    init(database: any DatabaseReader) {
        self.database = database
    }

    func call(arguments: Arguments) async throws -> Result {
        // Query database or call coordinator
        return try await database.read { db in
            // Type-safe SQLiteData queries
        }
    }
}
```

### Example: GetActiveGoalsTool

```swift
/// Retrieve user's active goals with filtering
/// Written by Claude Code on 2025-11-12
struct GetActiveGoalsTool: Tool {
    let name = "getActiveGoals"
    let description = "Retrieve active goals, optionally filtered by term or value alignment"

    @Generable
    struct Arguments {
        @Guide(description: "Optional term ID to filter by specific term")
        var termId: UUID?

        @Guide(description: "Optional value ID for value-aligned goals")
        var valueId: UUID?

        @Guide(description: "Maximum goals to return", .range(1...10))
        var limit: Int = 5
    }

    @Generable
    struct GoalSummary: Sendable {
        var id: UUID
        var title: String
        var targetDate: Date
        var alignedValues: [String]
        var currentProgress: String?
    }

    private let database: any DatabaseReader

    init(database: any DatabaseReader) {
        self.database = database
    }

    func call(arguments: Arguments) async throws -> [GoalSummary] {
        return try await database.read { db in
            var query = Goal
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .limit(arguments.limit)

            // Apply filters
            if let termId = arguments.termId {
                query = query
                    .join(TermGoalAssignment.all) { $0.id.eq($1.goalId) }
                    .where { $0[TermGoalAssignment.self].termId.eq(termId) }
            }

            if let valueId = arguments.valueId {
                query = query
                    .join(GoalRelevance.all) { $0.id.eq($1.goalId) }
                    .where { $0[GoalRelevance.self].valueId.eq(valueId) }
            }

            let goals = try query.fetchAll(db)

            // Assemble summaries
            return goals.map { goal in
                GoalSummary(
                    id: goal.id,
                    title: goal.expectation.title ?? "Untitled",
                    targetDate: goal.targetDate ?? Date(),
                    alignedValues: fetchAlignedValues(for: goal.id, in: db),
                    currentProgress: calculateProgress(for: goal, in: db)
                )
            }
        }
    }

    private func fetchAlignedValues(for goalId: UUID, in db: Database) -> [String] {
        // Bulk fetch to avoid N+1
        let relevances = try? GoalRelevance
            .where { $0.goalId.eq(goalId) }
            .join(PersonalValue.all) { $0.valueId.eq($1.id) }
            .fetchAll(db)
        return relevances?.map { $0.personalValue.title ?? "" } ?? []
    }

    private func calculateProgress(for goal: Goal, in db: Database) -> String? {
        // Aggregate action contributions
        let contributions = try? ActionGoalContribution
            .where { $0.goalId.eq(goal.id) }
            .fetchAll(db)

        let total = contributions?.reduce(0.0) { $0 + ($1.contributionAmount ?? 0) }
        return total.map { String(format: "%.1f total contribution", $0) }
    }
}
```

### Example: CreateGoalTool (Write Operation)

```swift
/// Create a new goal from LLM-generated data
/// Written by Claude Code on 2025-11-12
struct CreateGoalTool: Tool {
    let name = "createGoal"
    let description = "Create a new goal with measures and value alignment"

    @Generable
    struct Arguments {
        @Guide(description: "Clear, specific goal title")
        var title: String

        @Guide(description: "Detailed success criteria")
        var detailedDescription: String?

        @Guide(description: "Target completion date")
        var targetDate: Date

        @Guide(description: "Measurable targets", .count(1...5))
        var measures: [MeasureTarget]

        @Guide(description: "Aligned value IDs", .count(1...3))
        var alignedValueIds: [UUID]
    }

    @Generable
    struct MeasureTarget: Sendable {
        var measureName: String
        var targetValue: Double
        var unit: String
    }

    @Generable
    struct Result: Sendable {
        var goalId: UUID
        var success: Bool
        var message: String
    }

    private let database: any DatabaseWriter

    init(database: any DatabaseWriter) {
        self.database = database
    }

    func call(arguments: Arguments) async throws -> Result {
        // Convert to FormData
        let formData = GoalFormData(
            title: arguments.title,
            detailedDescription: arguments.detailedDescription,
            targetDate: arguments.targetDate,
            measures: arguments.measures.map { measure in
                // Map to ExpectationMeasureInput
                ExpectationMeasureInput(
                    measureId: lookupOrCreateMeasure(measure),
                    targetValue: measure.targetValue
                )
            },
            alignedValueIds: arguments.alignedValueIds
        )

        // Use coordinator for atomic write
        let coordinator = GoalCoordinator(database: database)

        do {
            let goal = try await coordinator.create(from: formData)
            return Result(
                goalId: goal.id,
                success: true,
                message: "Goal '\(arguments.title)' created successfully"
            )
        } catch let error as ValidationError {
            return Result(
                goalId: UUID(),  // Dummy ID
                success: false,
                message: "Validation failed: \(error.localizedDescription)"
            )
        }
    }

    private func lookupOrCreateMeasure(_ target: MeasureTarget) -> UUID {
        // Check if measure exists, create if not
        // This would use MeasureCoordinator
        // Simplified for example
        return UUID()
    }
}
```

### Example: RetrieveMemoryTool (RAG Pattern)

```swift
/// Semantic search over user's past goals, actions, and conversations
/// Written by Claude Code on 2025-11-12
struct RetrieveMemoryTool: Tool {
    let name = "retrieveMemory"
    let description = "Search user's past goals, actions, and conversations for relevant context"

    @Generable
    struct Arguments {
        @Guide(description: "Search query for semantic similarity")
        var query: String

        @Guide(description: "Number of memory chunks to retrieve", .range(1...5))
        var limit: Int = 3

        @Guide(description: "Filter by content type if needed")
        var contentType: String?  // 'goal', 'action', 'reflection', 'conversation'
    }

    private let database: any DatabaseReader

    init(database: any DatabaseReader) {
        self.database = database
    }

    func call(arguments: Arguments) async throws -> String {
        // 1. Embed the query using Natural Language framework
        let queryEmbedding = embedText(arguments.query)

        // 2. Cosine similarity search in database
        let relevantMemories = try await searchSimilarMemories(
            embedding: queryEmbedding,
            limit: arguments.limit,
            contentType: arguments.contentType
        )

        // 3. Return concatenated text chunks
        return relevantMemories
            .map { "[\($0.contentType)]: \($0.textChunk)" }
            .joined(separator: "\n\n")
    }

    private func embedText(_ text: String) -> [Float] {
        // Use Natural Language framework for on-device embedding
        import NaturalLanguage
        let embedding = NLEmbedding.sentenceEmbedding(for: .english)
        return embedding?.vector(for: text) ?? []
    }

    private func searchSimilarMemories(
        embedding: [Float],
        limit: Int,
        contentType: String?
    ) async throws -> [LLMMemoryEmbedding] {
        return try await database.read { db in
            var query = LLMMemoryEmbedding.all

            if let contentType = contentType {
                query = query.where { $0.contentType.eq(contentType) }
            }

            let allMemories = try query.fetchAll(db)

            // Calculate cosine similarity
            let scored = allMemories.map { memory in
                let memoryVector = deserializeEmbedding(memory.embedding)
                let similarity = cosineSimilarity(embedding, memoryVector)
                return (memory, similarity)
            }

            // Return top-k
            return scored
                .sorted { $0.1 > $1.1 }
                .prefix(limit)
                .map(\.0)
        }
    }

    private func deserializeEmbedding(_ data: Data) -> [Float] {
        return data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
    }
}
```

---

## Implementation Phases

### Phase 1: Foundation (2-3 weeks)

**Goal:** Basic conversational goal-setting with structured output

**Deliverables:**
- [ ] Database schema migration for LLM tables
- [ ] `GoalSettingCoachViewModel` with basic session management
- [ ] 3 query tools: `GetActiveGoalsTool`, `GetPersonalValuesTool`, `GetCurrentTermTool`
- [ ] 1 write tool: `CreateGoalTool` (using existing GoalCoordinator)
- [ ] @Generable types: `GoalCreationData`, `MeasureTarget`, `ValueAlignment`
- [ ] Availability checking UI (device eligibility, Apple Intelligence status)
- [ ] Basic conversational UI with message bubbles

**Success Criteria:**
- User can have a 5-10 message conversation to create a goal
- LLM queries active goals and values to provide context
- LLM generates structured `GoalCreationData` for review
- User reviews and confirms before database write
- Session state persists across view dismissal

**File Structure:**
```
Sources/
├── Services/
│   ├── LLM/
│   │   ├── Tools/
│   │   │   ├── GetActiveGoalsTool.swift
│   │   │   ├── GetPersonalValuesTool.swift
│   │   │   ├── GetCurrentTermTool.swift
│   │   │   └── CreateGoalTool.swift
│   │   ├── GenerableTypes/
│   │   │   ├── GoalCreationData.swift
│   │   │   └── MeasureTarget.swift
│   │   ├── Instructions/
│   │   │   └── GoalCoachInstructions.swift
│   │   └── ViewModels/
│   │       └── GoalSettingCoachViewModel.swift
├── Views/
│   └── LLM/
│       ├── GoalSettingCoachView.swift
│       └── Components/
│           ├── MessageBubbleView.swift
│           └── TypingIndicatorView.swift
└── Database/
    └── Schemas/
        └── llm_schema.sql
```

### Phase 2: Conversation Persistence (1-2 weeks)

**Goal:** Resume conversations and prevent context overflow

**Deliverables:**
- [ ] Transcript serialization/deserialization
- [ ] Conversation save/resume functionality
- [ ] Token counting and tracking
- [ ] Progressive summarization service (Model 1)
- [ ] Context window overflow handling
- [ ] Conversation history UI (list past conversations)

**Success Criteria:**
- User can exit and resume a conversation seamlessly
- Long conversations (20+ messages) trigger summarization
- Summary appears in new session context
- Old messages archived but retrievable
- Token budget never exceeded

**New Files:**
```
Sources/Services/LLM/
├── Persistence/
│   ├── ConversationPersistence.swift
│   ├── TranscriptSerializer.swift
│   └── TokenCounter.swift
├── Summarization/
│   ├── SummarizationService.swift
│   └── SummarizationInstructions.swift
└── ViewModels/
    └── ConversationHistoryViewModel.swift
```

### Phase 3: Memory & RAG (2-3 weeks)

**Goal:** Semantic search for long-term context

**Deliverables:**
- [ ] Natural Language framework integration for embeddings
- [ ] `RetrieveMemoryTool` with cosine similarity search
- [ ] Background embedding generation for goals, actions, conversations
- [ ] Memory indexing service (runs periodically)
- [ ] RAG query optimization (SQLite vector search)
- [ ] Memory dashboard UI (show what LLM knows)

**Success Criteria:**
- User asks "What goals have I set related to writing?" → LLM retrieves relevant past goals
- Embeddings generated for all new goals/actions automatically
- Search results ranked by semantic similarity
- Sub-200ms retrieval latency for 1000+ embeddings

**New Files:**
```
Sources/Services/LLM/
├── Memory/
│   ├── EmbeddingService.swift
│   ├── MemoryIndexer.swift
│   └── VectorSearch.swift
├── Tools/
│   └── RetrieveMemoryTool.swift
└── ViewModels/
    └── MemoryDashboardViewModel.swift
```

### Phase 4: Advanced Features (2-3 weeks)

**Goal:** Values alignment, reflection, analysis

**Deliverables:**
- [ ] `AnalyzeValueAlignmentTool` - Structured alignment report
- [ ] `GenerateReflectionPromptsTool` - Weekly reflection questions
- [ ] `GetRecentActionsTool` - Query recent logged actions
- [ ] Values alignment coach UI
- [ ] Weekly reflection flow
- [ ] Progress analysis dashboard

**Success Criteria:**
- LLM analyzes 30 days of actions and suggests better value alignment
- Weekly reflection questions personalized to user's goals
- Progress reports generated automatically

**New Files:**
```
Sources/Services/LLM/
├── Tools/
│   ├── AnalyzeValueAlignmentTool.swift
│   ├── GenerateReflectionPromptsTool.swift
│   └── GetRecentActionsTool.swift
├── Instructions/
│   ├── ValuesCoachInstructions.swift
│   └── ReflectionCoachInstructions.swift
└── ViewModels/
    ├── ValuesAlignmentCoachViewModel.swift
    └── WeeklyReflectionViewModel.swift
```

### Phase 5: Polish & Optimization (1-2 weeks)

**Goal:** Production-ready experience

**Deliverables:**
- [ ] Safety guardrails testing (refusal handling)
- [ ] Error recovery UX (retry, reformulate)
- [ ] Performance profiling (latency, token usage)
- [ ] Token optimization (concise tool descriptions)
- [ ] Batch processing for embeddings
- [ ] Analytics dashboard (usage patterns)

**Success Criteria:**
- Average response latency < 2 seconds
- Token usage < 2000 per conversation on average
- Graceful error handling for all edge cases
- Safety violations handled with clear user messaging

---

## Integration Points

### 1. Existing Coordinators

**Pattern:** Tools call existing coordinators for validated writes

```swift
// CreateGoalTool calls GoalCoordinator
struct CreateGoalTool: Tool {
    func call(arguments: Arguments) async throws -> Result {
        let formData = convertToFormData(arguments)
        let coordinator = GoalCoordinator(database: database)
        let goal = try await coordinator.create(from: formData)
        return Result(goalId: goal.id, success: true)
    }
}
```

**Benefits:**
- ✅ Reuses existing validation logic
- ✅ No new database write paths to test
- ✅ Atomic multi-model writes guaranteed

### 2. Existing Repositories (Future)

**Pattern:** Tools query repositories instead of raw database

```swift
// GetActiveGoalsTool uses GoalRepository
struct GetActiveGoalsTool: Tool {
    private let repository: GoalRepository

    func call(arguments: Arguments) async throws -> [GoalSummary] {
        return try await repository.fetchActive(
            termId: arguments.termId,
            valueId: arguments.valueId,
            limit: arguments.limit
        )
    }
}
```

**When:** After Phase 4 of repository implementation (see `REPOSITORY_IMPLEMENTATION_PLAN.md`)

### 3. Form Data Structures

**Pattern:** Reuse existing FormData types

```swift
// Tool arguments → FormData → Coordinator
let formData = GoalFormData(
    title: arguments.title,
    detailedDescription: arguments.detailedDescription,
    targetDate: arguments.targetDate,
    measures: arguments.measures.map { ... },
    alignedValueIds: arguments.alignedValueIds
)
```

**Benefits:**
- ✅ Single source of truth for form structure
- ✅ Type-safe mapping from LLM output
- ✅ Validation at form data level

### 4. SwiftUI Views

**Pattern:** ViewModels use @Observable + @MainActor

```swift
@Observable
@MainActor
final class GoalSettingCoachViewModel {
    var messages: [Message] = []
    var isSaving: Bool = false

    @ObservationIgnored
    private var session: LanguageModelSession?

    func sendMessage(_ text: String) async throws {
        // Automatic context switching: main → background → main
        let response = try await session?.respond(to: Prompt(text))
        messages.append(.assistant(response?.content ?? ""))
    }
}
```

**Integration:** New views alongside existing SwiftUI architecture

---

## Testing Strategy

### 1. Unit Tests

**Tool Testing:**
```swift
final class GetActiveGoalsToolTests: XCTestCase {
    func testBasicFetch() async throws {
        let database = InMemoryDatabase()
        // Seed test data
        try await seedGoals(database)

        let tool = GetActiveGoalsTool(database: database)
        let result = try await tool.call(arguments: .init(limit: 5))

        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result.allSatisfy { $0.title.count > 0 })
    }

    func testTermFiltering() async throws {
        // Test filtering by term ID
    }

    func testValueFiltering() async throws {
        // Test filtering by value alignment
    }
}
```

**Conversation Persistence:**
```swift
final class ConversationPersistenceTests: XCTestCase {
    func testSaveAndResume() async throws {
        let persistence = ConversationPersistence(database: database)

        // Create conversation
        let conversation = try await persistence.create(type: "goal_setting")

        // Add messages
        try await persistence.addMessage(
            conversationId: conversation.id,
            entry: .prompt(Prompt("Help me set a goal"))
        )

        // Resume
        let transcript = try await persistence.loadTranscript(for: conversation.id)
        XCTAssertEqual(transcript.entries.count, 1)
    }
}
```

**Summarization:**
```swift
final class SummarizationServiceTests: XCTestCase {
    func testSummarizeConversation() async throws {
        let service = SummarizationService(database: database)

        // Create long conversation (20 messages)
        let conversationId = try await createLongConversation()

        // Summarize
        let summary = try await service.summarize(conversationId: conversationId)

        XCTAssertLessThan(summary.count, 500)  // Summary should be concise
        XCTAssertTrue(summary.contains("goal"))  // Should mention goal
    }
}
```

### 2. Integration Tests

**End-to-End Conversation:**
```swift
final class GoalSettingConversationTests: XCTestCase {
    func testCompleteGoalSetting() async throws {
        let viewModel = GoalSettingCoachViewModel(database: database)

        // Start conversation
        viewModel.startConversation()

        // User message
        try await viewModel.sendMessage("I want to write more")

        // LLM should ask clarifying questions
        XCTAssertTrue(viewModel.messages.last?.content.contains("measure") ?? false)

        // Continue conversation
        try await viewModel.sendMessage("Track words written per week")

        // LLM should generate structured output
        let lastMessage = viewModel.messages.last
        XCTAssertTrue(lastMessage is StructuredGoalMessage)
    }
}
```

### 3. Performance Tests

**Token Usage:**
```swift
final class TokenUsageTests: XCTestCase {
    func testAverageConversationTokens() async throws {
        let viewModel = GoalSettingCoachViewModel(database: database)

        // Simulate 10-message conversation
        for i in 1...10 {
            try await viewModel.sendMessage("Message \(i)")
        }

        let conversation = try await fetchConversation(viewModel.conversationId)
        XCTAssertLessThan(conversation.tokenCount, 2000)  // Should stay under 2000
    }
}
```

**Latency:**
```swift
final class LatencyTests: XCTestCase {
    func testToolCallLatency() async throws {
        let tool = GetActiveGoalsTool(database: database)

        let start = Date()
        _ = try await tool.call(arguments: .init(limit: 10))
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.5)  // Should complete in < 500ms
    }
}
```

### 4. Safety Tests

**Guardrail Violations:**
```swift
final class SafetyTests: XCTestCase {
    func testRefusalHandling() async throws {
        let viewModel = GoalSettingCoachViewModel(database: database)

        do {
            // Attempt unsafe prompt
            try await viewModel.sendMessage("Generate harmful content")
            XCTFail("Should throw guardrail violation")
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            // Expected
        }
    }
}
```

---

## Performance Considerations

### 1. Latency Targets

**Tool Calls:**
- Simple fetch (GetGoals): < 100ms
- Complex join (GetRecentActions): < 300ms
- RAG search (RetrieveMemory): < 200ms
- Coordinator write (CreateGoal): < 500ms

**LLM Inference:**
- String response: 1-3 seconds
- Structured output: 2-4 seconds
- Multi-tool call: 3-6 seconds

**Total User Experience:**
- Simple question: < 3 seconds
- Complex generation: < 6 seconds
- Goal creation: < 8 seconds (includes DB write)

### 2. Token Optimization

**Tool Descriptions:**
- Keep under 100 characters
- Focus on semantics, not syntax
- Avoid redundant information

**Session Instructions:**
- 200-300 words maximum
- Structured bullet points
- Clear behavioral guidelines

**Generable Types:**
- Minimize nesting depth
- Short property names
- Use constraints to reduce schema size

### 3. Memory Management

**Conversation Lifecycle:**
- Active: Last 15 messages + summary
- Archived: Older messages (not in session context)
- Purged: After 90 days (user setting)

**Embedding Storage:**
- Store only last 1000 embeddings per user
- Rotate out oldest embeddings
- Prioritize recent + high-relevance content

**Database Size:**
- Estimate: 5-10 MB per user for 6 months
- Cleanup: Periodic purge of old conversations
- Export: Allow user to export/backup conversations

### 4. Concurrency

**Background Tasks:**
- Summarization: Run after conversation ends
- Embedding generation: Batch process nightly
- Memory indexing: Incremental updates

**Main Thread Protection:**
- All ViewModels @MainActor
- All Coordinators Sendable, no @MainActor
- Automatic context switching (Swift 6)

---

## Next Steps

### Immediate Actions (This Week)

1. **Database Migration:**
   - [ ] Create `llm_schema.sql` with conversation tables
   - [ ] Add migration script to existing schema updates
   - [ ] Test migration on development database

2. **Tool Scaffolding:**
   - [ ] Create `Sources/Services/LLM/Tools/` directory
   - [ ] Scaffold 4 initial tools with descriptive comments
   - [ ] Define @Generable types for arguments/results

3. **ViewModel Setup:**
   - [ ] Create `GoalSettingCoachViewModel.swift`
   - [ ] Implement basic session lifecycle
   - [ ] Add availability checking logic

4. **UI Prototype:**
   - [ ] Create `GoalSettingCoachView.swift`
   - [ ] Implement message bubble UI
   - [ ] Add typing indicator

### Research Questions to Validate

- [ ] Test Natural Language framework embedding quality on sample data
- [ ] Benchmark cosine similarity search performance with 1000+ embeddings
- [ ] Verify Transcript serialization works with complex tool calls
- [ ] Confirm @Generable nesting limits (how deep can we go?)
- [ ] Test concurrent tool calls (does Apple Intelligence serialize them?)

### Dependencies

**Phase 1 Blockers:**
- None (can start immediately)

**Phase 2 Blockers:**
- Phase 1 complete

**Phase 3 Blockers:**
- Phase 2 complete (need conversation persistence)

**Phase 4 Blockers:**
- Phase 3 complete (need RAG for values analysis)

---

## Appendix: Alternative Architectures Considered

### Three-Model Architecture (Rejected)

**Why Rejected:**
- Adds latency (two model hops instead of one)
- More complex state management
- Tool calling handles context injection natively
- No clear benefit over two-model design

**Would Reconsider If:**
- Need extremely complex prompt engineering per message
- Multi-user orchestration required
- Apple documents pattern as best practice

### Single-Model Architecture (Rejected)

**Why Rejected:**
- Can't do background summarization
- Can't do async embedding generation
- All processing blocks user conversation

**Use Case:** Only viable for very simple chatbot without memory

### Repository-First Approach (Deferred)

**Why Deferred:**
- Tools can query database directly initially
- Repository pattern not yet complete in app
- Can refactor tools to use repositories in Phase 4+

**Plan:** Move to repository-based tools after repository layer stabilizes

---

**Document Status:** Draft v1.0
**Review Date:** 2025-11-19
**Next Update:** After Phase 1 completion
