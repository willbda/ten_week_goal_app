# Documentation Refresh Guide
**Created**: 2025-11-06
**Purpose**: Guide Claude Code on when and how to fetch current documentation for Swift 6.2 and iOS 26+

---

## Why This Guide Exists

**Challenge**: Claude's training data has a cutoff date (January 2025), which may not include:
- Swift 6.2 features (released September 15, 2025)
- iOS/macOS/visionOS 26 APIs (released September 15, 2025)
- Latest SQLiteData patterns (1.2.0+)
- Platform-specific behaviors and design patterns

**Solution**: Use the doc-fetcher skill to query verified, current documentation when uncertain.

---

## The Golden Rule

**When in doubt about API syntax, behavior, or availability → fetch docs first, implement second.**

Better to spend 30 seconds searching documentation than 10 minutes debugging based on outdated assumptions.

---

## Triggers: When to Fetch Documentation

### 1. Swift Language Features

**Fetch docs when**:
- Uncertain about Sendable conformance rules
- Actor isolation errors that don't make sense
- New Swift 6.2 features (InlineArray, Span, typed throws)
- Concurrency patterns (@MainActor, nonisolated, async let)
- Macro usage (@Observable, @Table, #sql)

**Example queries**:
```bash
cd ~/.claude/skills/doc-fetcher
python doc_fetcher.py search "Sendable conformance requirements"
python doc_fetcher.py search "MainActor nonisolated function"
python doc_fetcher.py search "async let structured concurrency"
```

**Pre-indexed**: Swift concurrency docs from docs.swift.org and developer.apple.com

---

### 2. SwiftUI APIs

**Fetch docs when**:
- Uncertain about view modifier availability
- Changed initialization patterns (State vs StateObject)
- @Observable vs ObservableObject usage
- @Fetch behavior and requirements
- Platform-specific view modifiers (visionOS, macOS)

**Example queries**:
```bash
python doc_fetcher.py search "Observable macro state management"
python doc_fetcher.py search "State property wrapper initialization"
python doc_fetcher.py search "SwiftUI List swipe actions"
```

**Pre-indexed**: SwiftUI docs from developer.apple.com

---

### 3. SQLiteData Patterns

**Fetch docs when**:
- Query builder method not working as expected
- #sql macro interpolation rules
- FetchKeyRequest implementation details
- Insert/Update/Delete return types
- Join syntax or relationship queries

**Example queries**:
```bash
python doc_fetcher.py search "SQLiteData Table macro"
python doc_fetcher.py search "SQLiteData query builder join"
python doc_fetcher.py search "SQLiteData insert returning"
```

**Pre-indexed**: SQLiteData docs from swiftpackageindex.com

---

### 4. Platform Version Features

**Fetch docs when**:
- Referencing iOS 26, macOS 26, visionOS 26 APIs
- "Liquid Glass" design language specifics
- Platform-specific behaviors
- Availability attributes (@available)

**Example queries**:
```bash
python doc_fetcher.py search "iOS 26 new features"
python doc_fetcher.py search "macOS 26 Tahoe"
python doc_fetcher.py search "visionOS 26 APIs"
```

**Note**: Some iOS 26 content may not be indexed yet. Use WebSearch as fallback.

---

### 5. Error Messages

**Fetch docs when**:
- Compiler error about concurrency/Sendable
- "Type does not conform to protocol" errors
- Deprecation warnings with migration path
- SQLiteData query compilation errors

**Example queries**:
```bash
python doc_fetcher.py search "Sendable conformance error"
python doc_fetcher.py search "MainActor function cannot be used"
```

---

## How to Use doc-fetcher Skill

### Basic Search

From project root:
```bash
cd ~/.claude/skills/doc-fetcher
python doc_fetcher.py search "your query here"
```

**Returns**: Relevant sections from indexed documentation with relevance scores

### Searching from Claude Code

Claude Code can invoke the skill directly:
```python
# In conversation context
Use doc-fetcher skill to search "async await patterns"
```

---

## Pre-Approved Documentation Sources

These domains are already approved and indexed (no approval needed):

### 1. Apple Developer Documentation
**Domain**: `developer.apple.com`
**Coverage**:
- Swift language reference
- SwiftUI APIs and guides
- Concurrency documentation
- Platform-specific APIs (iOS, macOS, visionOS)

**URL pattern**: `https://developer.apple.com/documentation/...`

---

### 2. Swift.org Language Guide
**Domain**: `docs.swift.org`
**Coverage**:
- Swift language guide
- Concurrency model
- Memory safety
- Language evolution proposals

**URL pattern**: `https://docs.swift.org/swift-book/...`

---

### 3. Swift Package Index
**Domain**: `swiftpackageindex.com`
**Coverage**:
- SQLiteData documentation
- Point-Free libraries
- Third-party Swift packages

**URL pattern**: `https://swiftpackageindex.com/pointfreeco/sqlite-data/...`

---

## Fetching New Documentation (If Needed)

If a specific page isn't indexed yet:

### Step 1: Check if fetch is needed
```bash
python doc_fetcher.py search "specific topic"
# If no results or outdated...
```

### Step 2: Fetch specific page
```bash
python doc_fetcher.py fetch "https://developer.apple.com/documentation/path/to/page"
```

### Step 3: Fetch with crawling (for comprehensive coverage)
```bash
python doc_fetcher.py fetch "https://developer.apple.com/documentation/swiftui/view" \
    --crawl --depth 2 --max-pages 20
```

**Note**: Crawling respects rate limits (2s between requests) and robots.txt

---

## Search Strategy Tips

### Use Specific Terms
```bash
# ❌ Too vague
python doc_fetcher.py search "how to use SwiftUI"

# ✅ Specific
python doc_fetcher.py search "SwiftUI Observable macro initialization"
```

### Use Technical Keywords
```bash
# ❌ Colloquial
python doc_fetcher.py search "making things thread safe"

# ✅ Technical
python doc_fetcher.py search "Sendable conformance actor isolation"
```

### Chain Related Concepts
```bash
python doc_fetcher.py search "MainActor nonisolated database"
python doc_fetcher.py search "async let parallel query performance"
```

---

## Query Expansion & Matching

The doc-fetcher uses intelligent query normalization:

**Input**: "how to use async await"
**Normalized**: "async await" (stop words removed)
**FTS5 Query**: `async OR await OR "async await" OR (async AND await)`

**Strategy**: OR-based for recall (find any match), BM25 ranking for precision (exact phrases score higher)

---

## Common Patterns & Examples

### Pattern 1: Concurrency Error
**Scenario**: Compiler error about Sendable conformance

**Action**:
```bash
python doc_fetcher.py search "Sendable conformance requirements Swift 6"
```

**Expected**: Rules for implicit/explicit Sendable conformance

---

### Pattern 2: SwiftUI API Uncertainty
**Scenario**: Not sure if `@State` or `@StateObject` for @Observable

**Action**:
```bash
python doc_fetcher.py search "Observable State StateObject initialization"
```

**Expected**: Documentation showing @State is correct for @Observable

---

### Pattern 3: SQLiteData Query
**Scenario**: Query builder join syntax not working

**Action**:
```bash
python doc_fetcher.py search "SQLiteData join query builder"
```

**Expected**: Examples of join syntax from SQLiteData docs

---

### Pattern 4: Platform Feature
**Scenario**: Checking if API is available in iOS 26

**Action**:
```bash
# Try doc-fetcher first
python doc_fetcher.py search "iOS 26 API availability"

# If no results, use WebSearch
# Claude will use WebSearch tool for current info
```

**Expected**: Release notes or API reference

---

## Integration with Development Workflow

### During Planning Phase
1. Review task requirements
2. Identify unfamiliar APIs or patterns
3. Fetch documentation BEFORE writing code
4. Verify assumptions with current docs

### During Implementation
1. Write code based on verified patterns
2. If compiler error occurs, fetch docs for error message
3. Update understanding, fix code
4. Document any surprising behaviors

### During Code Review
1. If pattern seems unusual, verify with docs
2. Check if using deprecated API (fetch migration guide)
3. Validate concurrency patterns with official docs

---

## Fallback: WebSearch for Very Recent Info

If doc-fetcher returns no results (topic too new):

```python
# Claude Code will use WebSearch tool
"iOS 26 release date and features"
"Swift 6.2 new features WWDC 2025"
```

**Use WebSearch for**:
- Release dates and timelines
- Very recent announcements (< 1 month)
- High-level overviews
- Community discussions

**Then fetch official docs** once URLs identified

---

## Statistics & Performance

View doc-fetcher stats:
```bash
python doc_fetcher.py stats
```

**Shows**:
- Active domains
- Total documents/sections indexed
- Total words indexed
- Recent fetches and searches

**Typical performance**:
- Search: <10ms for complex queries
- Fetch: ~500ms per page (with 2s rate limit)

---

## Troubleshooting

### No Results Found

**Try**:
1. Simplify query (fewer keywords)
2. Use technical terms (not colloquial)
3. Try related terms (e.g., "Observable" instead of "state management")
4. Fetch specific page if you know URL

### Outdated Results

**Try**:
1. Fetch latest version of page
2. Use `--crawl` to update section of docs
3. Cross-reference with WebSearch for very recent changes

### JavaScript-Heavy Sites

Apple Developer docs use Vue.js:
- doc-fetcher uses Playwright for JS rendering
- Waits for `#app-main` with 30s timeout
- Should "just work" for Apple/Swift docs

---

## Best Practices

### ✅ Do

- Search docs when uncertain about syntax
- Verify assumptions with current documentation
- Use specific technical terms
- Check both Apple and Swift.org sources
- Document findings in code comments
- Update CLAUDE.md if pattern is reusable

### ❌ Don't

- Assume training data is current
- Guess API availability
- Mix Swift 5.x and Swift 6.2 patterns
- Use deprecated APIs without migration path
- Skip verification for "obvious" patterns (iOS 26 is new!)

---

## Example: Complete Workflow

**Task**: Implement parallel data loading in ViewModel

**Step 1: Check documentation**
```bash
python doc_fetcher.py search "async let structured concurrency parallel"
```

**Step 2: Review results**
- Swift.org concurrency guide
- Apple docs on structured concurrency
- Examples with `async let`

**Step 3: Verify pattern**
```bash
python doc_fetcher.py search "MainActor async function parallel query"
```

**Step 4: Implement with confidence**
```swift
// Verified pattern from docs
@MainActor
func loadData() async {
    async let data1 = database.read { ... }
    async let data2 = database.read { ... }
    (self.data1, self.data2) = try await (data1, data2)
}
```

**Step 5: Document in code**
```swift
// Pattern: async let for parallel queries
// See: GoalFormView.swift:273-299
// Docs: https://docs.swift.org/swift-book/.../concurrency/
```

---

## Related Documentation

- [MODERN_SWIFT_REFERENCE.md](MODERN_SWIFT_REFERENCE.md) - Swift 6.2 patterns quick reference
- [CLAUDE.md](../CLAUDE.md) - Project-specific guidance
- [REARCHITECTURE_COMPLETE_GUIDE.md](REARCHITECTURE_COMPLETE_GUIDE.md) - Architectural overview

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│ WHEN IN DOUBT → FETCH DOCS FIRST                   │
├─────────────────────────────────────────────────────┤
│ Search: cd ~/.claude/skills/doc-fetcher            │
│         python doc_fetcher.py search "query"        │
│                                                     │
│ Pre-approved: • developer.apple.com                │
│               • docs.swift.org                      │
│               • swiftpackageindex.com               │
│                                                     │
│ Fetch new:    python doc_fetcher.py fetch "URL"    │
│                                                     │
│ Fallback:     WebSearch for very recent info       │
└─────────────────────────────────────────────────────┘
```

---

**Last Updated**: 2025-11-06
**Maintained By**: Claude Code & David Williams
