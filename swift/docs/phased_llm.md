
# Key Architectural Findings

## Current State

1. LLM Module is well-structured but has:
  - Mixed tool patterns (explicit Tool protocol vs @Tool attribute)
  - Missing tool implementations (GetProgressTool, AnalyzeAlignmentTool)
  - References to semantic service that may or may not exist
2. Repository Layer is solid with:
  - Consistent Swift 6 patterns (Sendable, async/await)
  - Multiple query patterns optimized for different use cases
  - Two LLM repositories (EmbeddingCacheRepository,
ConversationRepository)

## Critical Conflicts

1. Semantic Infrastructure Duplication: I read files from
/Sources/Services/Semantics/ (Nov 12) at the start, which has:
  - SemanticService(language:) - synchronous API
  - EmbeddingCache - separate caching layer
  - But repositories reference types that don't exist (EmbeddingVector,
EmbeddingCacheEntry)
2. Missing Type Definitions: EmbeddingCacheRepository won't compile
without:
  - EmbeddingVector
  - EmbeddingCacheEntry
3. No Integration: LLM repositories exist but aren't used anywhere yet
                                                                          
## questions:

### Which semantic infrastructure implementation should we use as the  foundation? → 
Nov 14 /Semantic/ - Modern async/await with integrated caching

### Where should we define the missing embedding types (EmbeddingVector, EmbeddingCacheEntry)? → 

Let's split the difference somewhat and go for : `Sources/Models/SemanticTypes`

### How should we handle the missing LLM tools (GetProgressTool,  AnalyzeAlignmentTool)? → 

Stub with placeholders but make sure we have inline comments indicating what it's a placeholder for. if it's an entire file of placeholders append Placeholder in the name so that it's clear. 

### Which Tool pattern should we standardize on? → 

For LLM tools I'm referincing docomentation here: 
https://developer.apple.com/documentation/foundationmodels/tool 
https://developer.apple.com/documentation/foundationmodels/expanding-ge
neration-with-tool-calling 
https://developer.apple.com/documentation/foundationmodels 

check these as needed with the doc fetcher skill

> The "doc-fetcher" skill is running 
  Let me research the Foundation Models Tool API using doc-fetcher to understand the correct pattern.
  Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py search
    "Foundation Models Tool protocol" --limit 5)
  Search Results: Foundation Models Tool protocol
  … +81 lines (ctrl+o to expand)
   Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py fetch
    "https://developer.apple.com/documentation/foundationmodels/tool" --crawl
    --depth 1) ✓ Crawl complete!                                                    
      Pages fetched: 0
      Pages skipped: 1
    … +12 lines (ctrl+o to expand)

  ⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py search "Tool
    protocol @Tool attribute @Parameter" --domain "developer.apple.com"
    --limit 10)

  Search Results: Tool protocol @Tool attribute @Parameter
  … +122 lines (ctrl+o to expand)
  Bash(cd ~/.claude/skills/doc-fetcher && sqlite3 data/docs.db "SELECT heading,
    content FROM sections WHERE url =
    'https://developer.apple.com/documentation/foundation…)
⎿  Error: in prepare, no such column: url
      SELECT heading, content FROM sections WHERE url = 
    'https://developer.apple.com
                                    error here ---^

  ⏺ Read(~/Coding/REFERENCE/documents/appleDeveloper/foundationmodels/foundation-m
      odels.md)
  ⎿  Read 50 lines

  ⏺ Search(pattern: "**/*tool*.md", path:
        "~/Coding/REFERENCE/documents/appleDeveloper/foundationmodels")
  ⎿  Found 1 file (ctrl+o to expand)

  ⏺ Read(~/Coding/REFERENCE/documents/appleDeveloper/foundationmodels/tool.md)
  ⎿  Read 65 lines

  ⏺ Search(pattern: "**/*expanding*tool*.md", path:
        "~/Coding/REFERENCE/documents/appleDeveloper/foundationmodels")
  ⎿  Found 0 files 

  ⏺ Bash(ls -1 /Users/davidwilliams/Coding/REFERENCE/documents/appleDeveloper/foun
      dationmodels/)
  ⎿  foundation-models.md                                      
      generating-swift-data-structures-with-guided-generation.md
      improving-the-safety-of-generative-model-output.md
      … +7 lines (ctrl+o to expand)

  ⏺ Perfect! I now have the official Foundation Models Tool documentation. Let
    me present the comprehensive refactoring plan.
## Research Findings: Foundation Models Tool API

Based on the official Apple documentation at /Users/davidwilliams/Coding/REFERENCE/documents/appleDeveloper/foundationmodels/tool.md:

✅ Correct Tool Pattern (Official API)

protocol Tool<Arguments, Output> : Sendable

struct MyTool: Tool {
    let name = "toolName"
    let description = "What this tool does"

    @Generable
    struct Arguments {
        @Guide(description: "...", .range(1...10))
        let param: Int
    }

    func call(arguments: Arguments) async throws -> Output {
        // Implementation
    }
}

### Key Requirements:

- Must conform to Sendable
- name and description properties
- @Generable Arguments struct with @Guide properties
- call(arguments:) method (NOT perform())
- Output must be PromptRepresentable (String or @Generable types)

**Verdict**: GetGoalsTool and GetValuesTool are using the correct pattern. *Tools using @Tool attribute and perform() are using an incorrect/non-existent API.*

### Tool Conversion Matrix (Detailed Analysis)

**Total Tools**: 6 files in `/Sources/Logic/LLM/Tools/`

| File | Current Pattern | Method | Needs Conversion? | Effort |
|------|----------------|---------|-------------------|---------|
| **GetGoalsTool.swift** | ✅ Tool protocol | `call(arguments:)` | **No** | 0 min |
| **GetValuesTool.swift** | ✅ Tool protocol | `call(arguments:)` | **No** | 0 min |
| **CreateGoalTool.swift** | ❌ `@Tool` attribute | `perform()` | **Yes** | 30 min |
| **CheckDuplicateGoalTool.swift** | ❌ `@Tool` attribute | `perform()` | **Yes** | 20 min |
| **GetMeasuresTool.swift** | ❌ `@Tool` attribute | `perform()` | **Yes** | 15 min |
| **GetRecentActionsTool.swift** | ❌ `@Tool` attribute | `perform()` | **Yes** | 15 min |

**Total Conversion Time**: ~80 minutes (1.5 hours)

### Conversion Pattern Template

For each tool with `@Tool` attribute, apply this transformation:

**Before (Incorrect)**:
```swift
@Tool(description: "Create a new goal...")
public struct CreateGoalTool {
    @Parameter(description: "Goal title") var title: String
    @Parameter(description: "Description") var description: String?

    public func perform() async throws -> CreateGoalResponse {
        // Implementation using self.title, self.description
    }
}
```

**After (Correct)**:
```swift
public struct CreateGoalTool: Tool {
    public let name = "createGoal"
    public let description = "Create a new goal after validating it doesn't duplicate existing goals"

    @Generable
    public struct Arguments: Codable {
        @Guide(description: "Goal title (required)")
        let title: String

        @Guide(description: "Detailed description of what success looks like")
        let description: String?

        public init(title: String, description: String? = nil) {
            self.title = title
            self.description = description
        }
    }

    private let database: any DatabaseWriter

    public init(database: any DatabaseWriter) {
        self.database = database
    }

    public func call(arguments: Arguments) async throws -> CreateGoalResponse {
        // Implementation using arguments.title, arguments.description
    }
}
```

**Key Changes Checklist**:
1. ❌ Remove `@Tool` attribute → ✅ Add `: Tool` conformance
2. ✅ Add `name` property (string identifier for LLM)
3. ✅ Move `@Parameter` fields into `@Generable struct Arguments`
4. ❌ Change `@Parameter` → ✅ `@Guide`
5. ❌ Rename `perform()` → ✅ `call(arguments:)`
6. ❌ Access via `self.field` → ✅ Access via `arguments.field`

# Approved LLM & Semantic Infrastructure Refactoring Plan

## Context

  Two semantic implementations exist (Nov 12 vs Nov 14), LLM repositories
  reference missing types, and LLM tools use mixed patterns. Need to 
  standardize on modern patterns while maintaining architectural 
  consistency.

## Decisions

1. Semantic API: Nov 14 modern async/await with integrated caching
2. Type Location: Sources/Models/SemanticTypes/ (new module)
3. Missing Tools: Stub with placeholders, append "Placeholder" to filename
1. Tool Pattern: Explicit Tool protocol (GetGoalsTool pattern is correct)

## Plan Overview

### Phase 1: Define Core Semantic Types (New Module)

Create: Sources/Models/SemanticTypes/

1. **EmbeddingVector.swift** - Type-safe embedding wrapper with Float32 optimization

**Design Decision**: Use `[Float]` not `[Double]` for 50% storage savings.

**Rationale**:
- NLEmbedding returns `[Double]`, but embedding precision doesn't benefit from 64-bit
- Semantic similarity works fine with 32-bit floats
- SQLite BLOB storage: `Float = 4 bytes`, `Double = 8 bytes`
- For 768-dimension vector: `768 * 4 = 3KB` vs `768 * 8 = 6KB` per embedding
- **50% storage reduction** with negligible accuracy loss

**Complete Implementation**:
```swift
//
//  EmbeddingVector.swift
//  Sources/Models/SemanticTypes
//
//  PURPOSE: Type-safe wrapper for semantic embedding vectors
//  STORAGE: Optimized for BLOB serialization (Float32, not Float64)
//

import Foundation

/// Semantic embedding vector for similarity calculations
///
/// Wraps NLEmbedding output with type safety and serialization
/// Uses Float (32-bit) instead of Double (64-bit) for 50% storage savings
public struct EmbeddingVector: Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Embedding values (Float32 for storage efficiency)
    public let values: [Float]

    /// Computed dimensionality (matches NLEmbedding output)
    public var dimensionality: Int { values.count }

    // MARK: - Constants

    /// Expected dimensionality for NLEmbedding sentence model
    /// Source: Apple NLEmbedding documentation
    public static let expectedDimensionality = 768

    // MARK: - Initialization

    /// Create embedding vector from Float array
    /// - Parameter values: Embedding values (must be 768-dimensional)
    /// - Throws: ValidationError if dimensionality incorrect
    public init(values: [Float]) throws {
        guard values.count == Self.expectedDimensionality else {
            throw ValidationError(
                userMessage: "Invalid embedding dimensions: got \(values.count), expected \(Self.expectedDimensionality)"
            )
        }
        self.values = values
    }

    /// Create embedding vector from Double array (convert from NLEmbedding output)
    /// - Parameter doubles: NLEmbedding output (Double array)
    /// - Throws: ValidationError if dimensionality incorrect
    public init(from doubles: [Double]) throws {
        guard doubles.count == Self.expectedDimensionality else {
            throw ValidationError(
                userMessage: "Invalid embedding dimensions: got \(doubles.count), expected \(Self.expectedDimensionality)"
            )
        }
        // Convert Double → Float for storage efficiency
        self.values = doubles.map { Float($0) }
    }

    // MARK: - Serialization (for SQLite BLOB storage)

    /// Serialize to Data for database storage
    /// - Returns: Binary representation (3072 bytes for 768 dimensions)
    public func toData() -> Data {
        // Convert [Float] to contiguous memory block
        return values.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    /// Deserialize from Data
    /// - Parameter data: Binary representation from database
    /// - Returns: EmbeddingVector if valid, nil if corrupted
    public init?(from data: Data) {
        // Verify size matches expected dimensionality
        let expectedSize = Self.expectedDimensionality * MemoryLayout<Float>.size
        guard data.count == expectedSize else {
            return nil
        }

        // Convert Data → [Float]
        let floats = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }

        // Use throwing initializer (we know dimensions are correct)
        try? self.init(values: floats)
    }

    // MARK: - Equatable

    public static func == (lhs: EmbeddingVector, rhs: EmbeddingVector) -> Bool {
        lhs.values == rhs.values
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(values)
    }
}

// MARK: - Convenience Extensions

extension EmbeddingVector {
    /// Cosine similarity with another vector
    /// - Parameter other: Vector to compare against
    /// - Returns: Similarity score (0.0 = orthogonal, 1.0 = identical)
    public func cosineSimilarity(to other: EmbeddingVector) -> Double {
        guard self.dimensionality == other.dimensionality else {
            return 0.0  // Vectors must have same dimensions
        }

        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0

        for i in 0..<dimensionality {
            dotProduct += self.values[i] * other.values[i]
            norm1 += self.values[i] * self.values[i]
            norm2 += other.values[i] * other.values[i]
        }

        let denominator = sqrt(norm1) * sqrt(norm2)
        guard denominator > 0 else { return 0.0 }

        return Double(dotProduct / denominator)
    }
}
```

**Storage Calculation**:
```
Dimensions: 768
Float size: 4 bytes
Total per vector: 768 * 4 = 3,072 bytes (3 KB)

For 1000 goals: 3 MB embedding storage
For 10,000 goals: 30 MB embedding storage
```

2. **EmbeddingCacheEntry.swift** - Database entity for cached embeddings

  - Maps to semanticEmbeddings table
  - @Table("semanticEmbeddings") with @Column attributes
  - Matches schema from schema_current.sql
  - Uses EmbeddingVector.toData() for BLOB serialization

3. **SemanticConfiguration.swift** - Configuration for semantic features

   - similarityThreshold: Double = 0.75
   - maxResults: Int = 10
   - enableSemanticSearch: Bool = true

### Phase 2: Modern Semantic Service (Nov 14 Architecture)

Update: Sources/Services/Semantic/SemanticService.swift

1. API Signature:


  public init(database: any DatabaseWriter, configuration: 
  SemanticConfiguration = .default)
  public func generateEmbedding(for text: String) async throws -> 
  EmbeddingVector?
  public func similarity(_ a: EmbeddingVector, _ b: EmbeddingVector) -> Double

2. Integrated Caching - Use EmbeddingCacheRepository internally
3.  Async/Await - Background embedding generation
4.  Graceful Degradation - Returns nil when NLEmbedding unavailable

### Phase 3: Update Repositories to Use New Types

Update: Sources/Services/Repositories/EmbeddingCacheRepository.swift

1. Replace undefined types with new types from Models/SemanticTypes/
2. Update method signatures to return EmbeddingVector
3. Keep existing query patterns (raw SQL for batch operations)

### Phase 4: Standardize LLM Tools

**Time Estimate**: ~1.5 hours (was 3-4 hours)

Update: All tools in Sources/Logic/LLM/Tools/

1. **Convert 4 tools from @Tool to Tool protocol** (~80 minutes):
   - CreateGoalTool.swift (30 min) - Complex, has duplicate detection
   - CheckDuplicateGoalTool.swift (20 min) - Moderate complexity
   - GetMeasuresTool.swift (15 min) - Simpler conversion
   - GetRecentActionsTool.swift (15 min) - Simpler conversion

2. **Skip 2 tools already correct**:
   - GetGoalsTool.swift ✅ Already uses Tool protocol
   - GetValuesTool.swift ✅ Already uses Tool protocol

3. Consistent Pattern (All 6 tools):
```swift
public struct ToolName: Tool {
    let name = "toolName"
    let description = "..."

    @Generable
    public struct Arguments: Codable {
        @Guide(description: "...") let param: Type
    }

    public func call(arguments: Arguments) async throws -> Response { }
}
```

**Reference**: See "Tool Conversion Matrix" section above for detailed transformation pattern.

### Phase 5: Create Placeholder Tools

**Time Estimate**: ~20 minutes

Create: Sources/Logic/LLM/Tools/

**IMPORTANT**: Return helpful error messages, NOT empty results!

1. **GetProgressToolPlaceholder.swift**

```swift
//
//  GetProgressToolPlaceholder.swift
//  ten-week-goal-app
//
//  PLACEHOLDER: Not yet implemented
//  TODO: Implement progress analysis for reflection conversations
//
//  REQUIRED FOR: ConversationType.reflection
//  DEPENDENCIES: ActionRepository, GoalRepository
//  IMPLEMENTATION NOTES:
//    - Fetch recent actions (last 7 days)
//    - Calculate progress toward goal targets
//    - Identify trends (improving/declining)
//    - Suggest areas for reflection
//

import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public struct GetProgressToolPlaceholder: Tool {
    public let name = "getProgress"
    public let description = "[PLACEHOLDER] Analyze recent actions and calculate progress toward goals"

    @Generable
    public struct Arguments: Codable {
        @Guide(description: "Number of days to analyze")
        let days: Int

        @Guide(description: "Goal IDs to focus on (optional)")
        let goalIds: [String]?

        public init(days: Int = 7, goalIds: [String]? = nil) {
            self.days = days
            self.goalIds = goalIds
        }
    }

    public func call(arguments: Arguments) async throws -> String {
        // Return helpful message explaining limitation
        return """
        [PLACEHOLDER] Progress analysis not yet implemented.

        This feature will:
        - Track actions from the last \(arguments.days) days
        - Calculate progress toward goal targets
        - Identify trends and patterns
        - Suggest reflection prompts

        For now, please review your recent actions manually in the Actions list.
        Implementation planned for Phase 2.
        """
    }
}
```

2. **AnalyzeAlignmentToolPlaceholder.swift**

```swift
//
//  AnalyzeAlignmentToolPlaceholder.swift
//  ten-week-goal-app
//
//  PLACEHOLDER: Not yet implemented
//  TODO: Implement values alignment analysis
//
//  REQUIRED FOR: ConversationType.valuesAlignment
//  DEPENDENCIES: GoalRepository, PersonalValueRepository
//  IMPLEMENTATION NOTES:
//    - Compare goal alignments with declared values
//    - Identify value conflicts
//    - Suggest improvements for better alignment
//    - Calculate alignment strength distribution
//

import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public struct AnalyzeAlignmentToolPlaceholder: Tool {
    public let name = "analyzeAlignment"
    public let description = "[PLACEHOLDER] Analyze how well goals align with personal values"

    @Generable
    public struct Arguments: Codable {
        @Guide(description: "Goal IDs to analyze (optional, analyzes all if omitted)")
        let goalIds: [String]?

        @Guide(description: "Value IDs to focus on (optional)")
        let valueIds: [String]?

        public init(goalIds: [String]? = nil, valueIds: [String]? = nil) {
            self.goalIds = goalIds
            self.valueIds = valueIds
        }
    }

    public func call(arguments: Arguments) async throws -> String {
        return """
        [PLACEHOLDER] Values alignment analysis not yet implemented.

        This feature will:
        - Compare goals against your personal values
        - Identify misalignments and conflicts
        - Suggest goals that better serve your values
        - Calculate alignment strength distribution

        For now, please review goal-value alignments manually in the Goals list.
        Implementation planned for Phase 2.
        """
    }
}
```

**Benefits of This Pattern**:
- ✅ LLM can still use the tool (won't crash)
- ✅ User gets helpful explanation instead of empty data
- ✅ Clear indication this is temporary
- ✅ Documentation of what the real implementation should do
- ✅ Easy to find and replace (search for "Placeholder" in filename)

### Phase 6: Remove Legacy Semantic Infrastructure

Delete: Sources/Services/Semantics/ (Nov 12 implementation)

1. Remove SemanticService.swift (old synchronous API)
2. Remove EmbeddingCache.swift (replaced by EmbeddingCacheRepository)
3. Keep SemanticTypes.swift if it has useful utilities (merge into new location)

### Phase 7: Update Integration Points

Update files that reference semantic services:

1. Dependencies+Semantic.swift - Update to new API
// Old: SemanticService(language: .english)
// New: SemanticService(database: database, configuration: .default)
2. GoalCoordinator.swift - Update duplicate detection
  - Use new async generateEmbedding() API
  - Handle optional EmbeddingVector (graceful degradation)
3. SemanticGoalDetector.swift (if exists) - Update implementation
  - Use new repository patterns
  - Async/await throughout

### Phase 8: Database Migration

Create: Migration to add LLM tables (they're in schema but not applied)

1. Check if migration already exists in Sources/Database/Migrations/
2. If not, create migration for semanticEmbeddings, llmConversations, 
llmMessages
3. Test migration on development database

### Phase 9: Update Package.swift Dependencies

Verify: All targets have correct dependencies

1. Ensure Logic target imports Models (for SemanticTypes)
2. Ensure Services target imports Models (for SemanticTypes)
3. No circular dependencies

  File Changes Summary

  New Files (7)

  - Sources/Models/SemanticTypes/EmbeddingVector.swift
  - Sources/Models/SemanticTypes/EmbeddingCacheEntry.swift
  - Sources/Models/SemanticTypes/SemanticConfiguration.swift
  - Sources/Logic/LLM/Tools/GetProgressToolPlaceholder.swift
  - Sources/Logic/LLM/Tools/AnalyzeAlignmentToolPlaceholder.swift

  Modified Files (10+)

  - Sources/Services/Semantic/SemanticService.swift (Nov 14 
  implementation)
  - Sources/Services/Repositories/EmbeddingCacheRepository.swift
  - Sources/Logic/LLM/Tools/CreateGoalTool.swift (convert to Tool 
  protocol)
  - Sources/Logic/LLM/Tools/CheckDuplicateGoalTool.swift (convert to Tool
  protocol)
  - Sources/Logic/LLM/Tools/GetMeasuresTool.swift (convert to Tool 
  protocol)
  - Sources/Logic/LLM/Tools/GetRecentActionsTool.swift (convert to Tool 
  protocol)
  - Sources/Services/Coordinators/GoalCoordinator.swift (update semantic 
  API)
  - Sources/App/Dependencies+Semantic.swift (update initialization)
  - Package.swift (verify dependencies)

  Deleted Files (3+)

  - Sources/Services/Semantics/SemanticService.swift (Nov 12)
  - Sources/Services/Semantics/EmbeddingCache.swift (Nov 12)
  - Any other Nov 12 semantic files

## Success Criteria

  1. ✅ All code compiles with no errors
  2. ✅ All LLM tools use consistent Tool protocol pattern
  3. ✅ Semantic service uses modern async/await with integrated caching
  4. ✅ Missing types (EmbeddingVector, etc.) defined in Models
  5. ✅ Placeholder tools allow compilation but marked as incomplete
  6. ✅ No duplicate semantic implementations
  7. ✅ Swift 6 concurrency patterns throughout (Sendable, @MainActor, 
  async/await)

## Breaking Changes

### Breaking Changes Audit Results

**✅ GOOD NEWS**: Minimal breaking changes detected!

#### **Views - No Usage Found** ✅
```bash
grep -r "SemanticService" swift/Sources/App/Views/
# Result: No output - Views don't directly use semantic services
```

#### **ViewModels - No Usage Found** ✅
```bash
grep -r "EmbeddingCache" swift/Sources/App/ViewModels/
# Result: No output - ViewModels don't directly reference cache
```

#### **Tests - No Usage Found** ✅
```bash
grep -r "semantic" swift/Tests/
# Result: No output - No existing tests for semantic features
```

#### **ONLY Breaking Change**: Dependencies+Semantic.swift

**File**: `/Sources/Services/Dependencies+Semantic.swift`
**Lines Affected**: 26, 29, 32

**Current Code**:
```swift
static let liveValue = SemanticService(language: .english)
static let testValue = SemanticService(language: .english)
static let previewValue = SemanticService(language: .english)
```

**Required Change**:
```swift
static let liveValue: SemanticService = {
    @Dependency(\.defaultDatabase) var database
    return SemanticService(database: database, configuration: .default)
}()

static let testValue: SemanticService = {
    @Dependency(\.defaultDatabase) var database
    return SemanticService(database: database, configuration: .default)
}()

static let previewValue: SemanticService = {
    @Dependency(\.defaultDatabase) var database
    return SemanticService(database: database, configuration: .default)
}()
```

#### **LLM Tools - Already Handle Graceful Degradation** ✅

**CreateGoalTool.swift:149-152** already has:
```swift
@Dependency(\.semanticService) var semanticService: SemanticService?

guard let semantic = semanticService else {
    // Semantic service not available, do basic title matching
    let exactMatch = existingGoals.first { ... }
```

**CheckDuplicateGoalTool.swift:67-77** already has:
```swift
@Dependency(\.semanticService) var semanticService: SemanticService?

if let semantic = semanticService {
    return try await performSemanticCheck(...)
} else {
    // Fall back to exact matching
    return performExactCheck(existingGoals: existingGoals)
}
```

**Verdict**: ✅ **Tools already implement graceful degradation correctly!**

### Summary
- ✅ **1 file to update**: Dependencies+Semantic.swift (3 initialization closures)
- ✅ **0 Views affected**
- ✅ **0 ViewModels affected**
- ✅ **0 Tests affected**
- ✅ **LLM tools already handle optional semantic service**

# Here are critical things to know before you start:

Critical References

1. Schema for EmbeddingCacheEntry

When creating EmbeddingCacheEntry.swift, match this exact schema from
schema_current.sql:
```sql
CREATE TABLE semanticEmbeddings (
    id TEXT PRIMARY KEY,
    entityType TEXT NOT NULL,
    entityId TEXT NOT NULL,
    textHash TEXT NOT NULL,
    sourceText TEXT NOT NULL,
    embedding BLOB NOT NULL,        -- This is your EmbeddingVector.toData()
    embeddingModel TEXT NOT NULL,
    dimensionality INTEGER NOT NULL,
    generatedAt TEXT NOT NULL,
    logTime TEXT NOT NULL,
    UNIQUE(entityType, entityId, textHash)
);
```

2. Import Dependencies for New Types

// In Models/SemanticTypes/EmbeddingVector.swift
import Foundation  // For Data type

// In Models/SemanticTypes/EmbeddingCacheEntry.swift
import Foundation
import SQLiteData  // For @Table, @Column macros

3. Files That Will Break (Expect Compilation Errors)

After Phase 6 (deleting Nov 12 /Semantics/), these files will likely fail:
- GoalCoordinator.swift - Line ~200s, imports old SemanticService
- Dependencies+Semantic.swift - Initializes old API
- Any file importing Services.Semantics (search codebase for this)

Don't fix them until Phase 7 - just note the errors.

4. Testing Checkpoints

After Phase 1 (New types):
swift build --target Models
Should compile cleanly.

After Phase 4 (Standardize tools):
swift build --target Logic
Should compile (may have warnings about placeholder tools).

After Phase 7 (Integration):
swift build
Full build should succeed.

5. Existing Nov 12 Code to Reference

Before deleting /Semantics/, you may want to copy useful implementations:

From SemanticService.swift (Nov 12):
- cosineSimilarity() function (lines 195-220) - Copy to new SemanticService
- hashText() function (lines 178-185) - Useful for cache invalidation
- normalizeText() function (lines 163-176) - Text preprocessing

From EmbeddingCache.swift (Nov 12):
- Cache statistics logic (lines 245-265) - May want in
EmbeddingCacheRepository

6. Watch for Sendable Requirements

All new types must be Sendable for Swift 6:
public struct EmbeddingVector: Sendable { }
public struct EmbeddingCacheEntry: Sendable { }
public struct SemanticConfiguration: Sendable { }

7. Package.swift Changes Needed

You'll likely need to add Models to the Services target:
.target(
    name: "Services",
    dependencies: [
        "Models",  // ← Add this
        "Database",
        .product(name: "SQLiteData", package: "sqlite-data"),
    ]
)

Suggested Phase Order

I recommend this order for smoothest progression:
1. Phase 1 → Compile Models
2. Phase 9 → Update Package.swift dependencies
3. Phase 2 → Create new SemanticService (don't delete old yet)
4. Phase 3 → Update EmbeddingCacheRepository
5. Phase 4 → Standardize LLM tools
6. Phase 5 → Create placeholders
7. Phase 6 → NOW delete old Semantics/ (expect breaks)
8. Phase 7 → Fix integration points
9. Phase 8 → Database migration (if needed)

Quick Check Commands

# Find all files importing old semantic API
grep -r "import.*Semantics" swift/Sources/

# Find all references to old SemanticService
grep -r "SemanticService(language:" swift/Sources/

# Check current database schema
sqlite3 swift/testing.db ".schema semanticEmbeddings"

Ready when you are! Come back after each phase and I'll review your
implementation. Good luck! 🚀



