# Semantic Similarity Research Report
## Swift and Apple Frameworks Analysis

**Date:** November 12, 2025  
**Project:** Ten Week Goal App  
**Thoroughness:** Medium - API documentation, Package.swift, and existing codebase patterns analyzed

---

## Executive Summary

The project already has **sophisticated similarity detection infrastructure** built from scratch using Locality-Sensitive Hashing (LSH) and MinHash algorithms. Apple provides **two specialized frameworks** for semantic similarity:

1. **NaturalLanguage.NLEmbedding** - Word and sentence embeddings with built-in distance metrics
2. **Foundation Models** - On-device LLM that can understand semantic meaning but doesn't provide direct embedding APIs

**Recommendation:** The existing LSH-based deduplication system is well-engineered and sufficient for production use. Consider NLEmbedding for future semantic search features, but it requires language-specific pre-trained models and is best for word-level comparisons.

---

## What Apple/Swift Already Provides

### 1. NaturalLanguage Framework (NLEmbedding) ✅

**Availability:** iOS 13+, macOS 10.15+ (backwards compatible, not iOS 26+ exclusive)

**Capabilities:**

#### Word Embeddings
```swift
// Create word embeddings for a specific language
if let wordEmbedding = NLEmbedding.wordEmbedding(for: .english) {
    // Get vector representation of a word
    let vector = wordEmbedding.vector(for: "goal")
    
    // Calculate distance between two words
    let distance = wordEmbedding.distance(
        between: "goal",
        and: "objective",
        distanceType: .cosine  // Options: cosine, cosineSimilarity
    )
    
    // Find similar words
    let nearestNeighbors = wordEmbedding.nearestNeighbors(
        for: "goal",
        maximumCount: 10
    )
}
```

#### Sentence Embeddings
```swift
// Create sentence embeddings
if let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) {
    // Get vector for complete sentence
    let vector = sentenceEmbedding.vector(
        for: "I want to run a marathon this year"
    )
    
    // Calculate distance between sentences
    let distance = sentenceEmbedding.distance(
        between: "I want to run a marathon",
        and: "My goal is to complete 26.2 miles"
    )
}
```

**Key Characteristics:**
- Pre-trained on language-specific models (English, Spanish, French, etc.)
- Returns vector representations as `[Double]` arrays
- Distance metrics: Cosine, Cosine Similarity
- Lightweight and fast (runs locally)
- No network required
- Returns nil if language model unavailable

**Limitations:**
- Language-specific (must specify language upfront)
- Pre-trained models are fixed (can't fine-tune)
- Word/sentence embeddings are basic compared to transformer models
- No built-in duplicate detection or similarity threshold management
- Distance calculation is basic Euclidean/Cosine

### 2. Foundation Models Framework ✅

**Availability:** iOS 26+, macOS 26+, visionOS 26+ (requires Apple Intelligence)

**Semantic Understanding Capabilities:**

```swift
let model = SystemLanguageModel.default
let session = try await LanguageModelSession(systemVersion: model)

// Foundation Models can understand semantic meaning but don't expose embeddings directly
let response = try await session.complete(
    "Compare the semantic similarity between 'run a marathon' and 'complete 26.2 miles'"
)
// Returns: natural language response about semantic similarity
```

**Key Points:**
- Full semantic understanding of text meaning
- Can recognize paraphrases and conceptual similarity
- Multi-turn conversations preserve context
- **Does NOT provide embedding vectors directly**
- Can be used with Tool Calling to implement similarity detection
- Subject to 4096 token context window limit

**NOT Suitable For:**
- Direct embedding generation (no API for this)
- Real-time similarity scoring of large datasets
- High-throughput batch similarity operations

### 3. String Distance APIs (Foundation Framework) ❌

**Missing:** Swift does not provide built-in string distance algorithms like Levenshtein distance in Foundation. You must implement or use third-party libraries.

---

## What's in Package.swift Dependencies

```swift
dependencies: [
    .package(
        url: "https://github.com/pointfreeco/sqlite-data.git",
        from: "1.2.0"
    ),
]
```

**Current Packages:**
- **SQLiteData** - ORM for database operations, not ML/NLP related

**Missing:**
- No ML/NLP library dependencies
- No embedding libraries
- No string distance libraries (Levenshtein, phonetic matchers, etc.)
- Project uses custom implementations only

---

## Existing Code Analysis: Current Implementation

The project has **already implemented comprehensive semantic similarity detection** from first principles:

### Architecture Overview

```
Services/Deduplication/
├── LSHService.swift               (Core algorithm: MinHash + Locality-Sensitive Hashing)
├── DuplicationDetector.swift      (Protocol for entity-specific detection)
├── DeduplicationService.swift     (Central coordination service)
├── GoalDetector.swift             (Multi-table goal analysis)
├── GoalTermDetector.swift         (Term number deduplication)
└── (Extension files for specific entities)
```

### LSHService: MinHash Implementation ✅

**What it does:**
1. **Shingles** text into overlapping 3-grams (n-grams)
2. **Computes MinHash signatures** - probabilistic data structure for set similarity
3. **Estimates Jaccard similarity** from signature comparison
4. **Handles weighted fields** - different field importance for composite hashing

**Performance:**
- Text processing: O(n) where n = text length
- Similarity comparison: O(1) for pre-computed signatures
- Handles 100-hash functions by default

**Algorithm:**
```swift
// Example: Comparing "run" vs "jog"
let shingles1 = lsh.shingle("run", size: 3)        // {"run"}
let shingles2 = lsh.shingle("jog", size: 3)        // {"jog"}

let sig1 = lsh.minHash(shingles1)   // [hash values...]
let sig2 = lsh.minHash(shingles2)   // [hash values...]

let similarity = lsh.similarity(sig1, sig2)        // ~0.0 (very different)
```

### DuplicationDetector: Protocol-Based Design ✅

**Type-safe entity-specific implementation:**

```swift
public protocol DuplicationDetector {
    associatedtype Entity: Identifiable
    
    func extractSemanticContent(_ entity: Entity) -> [String]
    func fieldWeights() -> [Double]?
    func thresholds() -> SimilarityThresholds
    func findDuplicates(...) async -> [DuplicateCandidate]
    func checkFormData(...) async -> [DuplicateCandidate]
}
```

**Concrete Implementations:**
1. **MeasureDetector** - Unit matching (strict thresholds: 0.95+ for high)
2. **PersonalValueDetector** - Value title matching (moderate: 0.75+)
3. **ActionDetector** - Title/time/description matching (relaxed: 0.75+ for high)
4. **GoalDetector** - Multi-table analysis combining:
   - Title similarity (40% weight)
   - Term assignment overlap (30% weight)
   - Measure target similarity (30% weight)
5. **GoalTermDetector** - Term number exact matching

### Configurable Thresholds

```swift
public struct SimilarityThresholds: Sendable {
    public let exact: Double      // 1.0 - identical
    public let high: Double       // 0.85+ - very likely duplicate
    public let moderate: Double   // 0.70+ - possible duplicate
    public let low: Double        // 0.50+ - notable similarity
}

// Built-in configurations:
SimilarityThresholds.default     // Balanced thresholds
SimilarityThresholds.strict      // For catalog entities (0.95+)
SimilarityThresholds.relaxed     // For user content (0.75+)
```

### GoalDetector: Multi-Table Complexity Handling ✅

**Unique feature:** Handles Goals which require database joins to determine duplicates:

```swift
// Full context loading includes:
- Expectation title and description
- ExpectationMeasure targets (via JOIN)
- TermGoalAssignment relationships (via JOIN)

// Composite similarity calculation:
similarity = (0.4 * titleSim) + (0.3 * termSim) + (0.3 * measureSim)
```

### DeduplicationService: Central Coordination ✅

**Responsibilities:**
- Manages LSHService and entity-specific detectors
- Provides form validation API: `checkActionDuplicate()`, `checkValueDuplicate()`, etc.
- Batch scanning: `scanForDuplicates()` for data hygiene
- Stores candidates in database for review and resolution
- Tracks resolution: merged, ignored, deleted, kept both

---

## What's Missing / Gaps

### 1. Semantic Understanding (Not Text Similarity) ❌

**Problem:** Current system is syntactic/statistical, not semantic.

**Example limitation:**
```
Goal 1: "Complete a 26.2 mile marathon"
Goal 2: "Run 42 kilometers"

Current LSH: Low similarity (different text, different unit)
Human understanding: These are nearly identical (same distance)
Foundation Models: Would understand they're the same
```

**Why This Matters:** Goals and values should match on *meaning*, not just text patterns.

### 2. Language-Specific Semantic Matching ❌

Current LSH is language-agnostic but crude. NLEmbedding could provide better semantic matching:

```swift
// Current (LSH-based)
let sim = lsh.textSimilarity("run", "jog")      // ~0.0 (no word overlap)

// Better with NLEmbedding
if let embedding = NLEmbedding.wordEmbedding(for: .english) {
    let distance = embedding.distance(          // ~0.2 (semantically close)
        between: "run",
        and: "jog"
    )
}
```

### 3. No Pre-Computed Embedding Cache ❌

Every similarity check requires computing signatures/vectors. No caching of embeddings for:
- Frequently compared goal titles
- Common personal values
- Repeated measure names

### 4. Foundation Models Not Integrated ❌

Foundation Models could be used for:
- **High-confidence semantic matching** - "Is 'finish a marathon' the same as 'run 26.2 miles'?"
- **Smart deduplication UI** - "These seem related. Should I merge them?" with reasoning
- But requires careful context window management (4096 token limit)

### 5. No Multi-Language Support ❌

Current LSH works across languages but NLEmbedding is language-specific. App doesn't handle:
- Goals written in Spanish and English
- Values in mixed languages
- Phonetic similarity (accent-insensitive matching)

---

## Comparison: Build vs. Use Existing

### Current LSH Implementation

**Pros:**
✅ Language-agnostic (works for any text)  
✅ Deterministic (same results every run)  
✅ Fully controllable thresholds and weights  
✅ Works offline  
✅ Fast (O(1) comparisons after signature generation)  
✅ Already in production  
✅ Entity-type specific (can customize per entity)  

**Cons:**
❌ Syntactic, not semantic (text pattern matching)  
❌ Misses paraphrases and synonyms  
❌ No single semantic standard (different detectors have different logic)  
❌ Hard to explain to users why items are flagged as duplicates  

### NLEmbedding (Use Apple's)

**Pros:**
✅ Semantic similarity for words/sentences  
✅ Pre-trained on large corpora  
✅ Built into Foundation framework  
✅ Easy to use (3 lines of code)  
✅ Language-specific models for 10+ languages  

**Cons:**
❌ Language must be known upfront  
❌ Word embeddings only (can't easily compare long descriptions)  
❌ Pre-trained models can't be fine-tuned  
❌ No filtering/threshold system for duplicates  
❌ Older framework (iOS 13+, not cutting-edge)  

### Foundation Models (Use Apple's)

**Pros:**
✅ Full semantic understanding  
✅ Can explain duplicates in natural language  
✅ Multi-turn conversation  
✅ iOS 26+ only (latest tech)  

**Cons:**
❌ Doesn't provide embeddings directly  
❌ Slow for high-throughput comparisons  
❌ Device/availability dependent (Apple Intelligence)  
❌ 4096 token context limit  
❌ Overkill for simple duplicate detection  
❌ Privacy: requires user to enable Apple Intelligence  

### Build Custom Embedding (Not Recommended)

**Cons:**
❌ Significant engineering effort  
❌ Requires training data  
❌ Model deployment complexity  
❌ Size/performance trade-offs  
❌ Maintenance burden  

---

## Recommendations

### For Current Production (v0.6.0+)

**Status:** Keep existing LSH implementation ✅

The current deduplication system is well-engineered and production-ready. It provides:
- Entity-specific detection strategies
- Configurable thresholds
- Database storage of candidates for review
- Resolution workflow

**Enhancements to consider:**

1. **Add field weighting explanation** - Show users why items matched
   ```swift
   DuplicateCandidate.explanation = "Same title (40% match) + similar terms (30%)"
   ```

2. **Cache signatures** - Pre-compute minHash for frequent comparisons
   ```swift
   database.duplicateSignatureCache(entityType: "goal", entityId: uuid)
   ```

3. **Add goal-specific semantic rules** - Beyond LSH for obvious duplicates
   ```swift
   // "Complete 26.2 miles" == "Run a marathon" (hardcoded domain knowledge)
   ```

### For Future Phases

**Phase 1: NLEmbedding Integration (iOS 26+ only)**
- Use for sentence-level similarity in goal matching
- Fallback to LSH on older devices
- Implement smart goal suggestions
- Example: "Your goal is similar to existing goal X"

```swift
// Hybrid approach
func semanticSimilarity(_ text1: String, _ text2: String) -> Double {
    if let embedding = NLEmbedding.sentenceEmbedding(for: .english) {
        let distance = embedding.distance(
            between: text1,
            and: text2,
            distanceType: .cosine
        )
        return 1.0 - distance  // Convert distance to similarity
    } else {
        // Fallback to existing LSH
        return lshService.textSimilarity(text1, text2)
    }
}
```

**Phase 2: Foundation Models Integration (Advanced)**
- Use for goal recommendation and smart matching
- Example: Show "This action might contribute to Goal X because..." with AI reasoning
- Careful context window management required
- Optional feature (check Apple Intelligence availability)

**Phase 3: Language Support**
- Extend NLEmbedding usage to handle multi-language goals
- Detect language automatically via NLLanguageRecognizer
- Use appropriate embedding model per language

---

## API Quick Reference

### NaturalLanguage.NLEmbedding

```swift
import NaturalLanguage

// Word Embeddings
if let wordEmbed = NLEmbedding.wordEmbedding(for: .english) {
    let vector = wordEmbed.vector(for: "goal")           // [Double]?
    let dist = wordEmbed.distance(between: "goal", and: "objective")
    let neighbors = wordEmbed.nearestNeighbors(for: "goal", maximumCount: 5)
}

// Sentence Embeddings
if let sentenceEmbed = NLEmbedding.sentenceEmbedding(for: .english) {
    let vector = sentenceEmbed.vector(for: "I want to run a marathon")
    let dist = sentenceEmbed.distance(between: "...", and: "...", distanceType: .cosine)
}
```

### Foundation Models (For Reference)

```swift
import FoundationModels

let model = SystemLanguageModel.default
guard case .available = model.availability else { return }

let session = try await LanguageModelSession(systemVersion: model)
let response = try await session.complete(
    "Is 'run a marathon' similar to 'complete 26.2 miles'?"
)
```

---

## Reference Documentation

**Project Documentation:**
- `/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/docs/FOUNDATION_MODELS_IMPLEMENTATION_GUIDE.md`
- `/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/docs/DOMAIN_MODEL_REFERENCE.md`

**Apple Developer:**
- NLEmbedding: https://developer.apple.com/documentation/naturallanguage/nlembedding
- Finding Similarities: https://developer.apple.com/documentation/naturallanguage/finding-similarities-between-pieces-of-text
- Foundation Models: https://developer.apple.com/documentation/foundationmodels
- TN3193: Context Window Management: https://developer.apple.com/documentation/Technotes/tn3193-managing-the-on-device-foundation-model-s-context-window

**Indexed in doc-fetcher:**
```bash
# Search for similarity APIs
python doc_fetcher.py search "NLEmbedding distance method nearestNeighbors"

# Search for Foundation Models semantic capabilities
python doc_fetcher.py search "Foundation Models semantic understanding"
```

---

## Summary Table

| Feature | Apple NLEmbedding | Foundation Models | Current LSH | Build Custom |
|---------|-------------------|-------------------|-------------|--------------|
| **Semantic Understanding** | Good (word-level) | Excellent | Poor | Excellent |
| **Speed** | Fast | Slow | Very Fast | Depends |
| **Language Support** | Multi-language | Multi-language | Language-agnostic | Depends |
| **Fine-tuning** | No | No | N/A | Yes |
| **Device Availability** | iOS 13+ | iOS 26+ only | All | All |
| **Implementation Complexity** | Low | Medium | High (done) | Very High |
| **Current Status** | Available | Not integrated | Production ✅ | N/A |
| **Recommended For** | Future phases | Advanced UI | Now | Not recommended |

