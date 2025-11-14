# Versioning Strategy

**Current Version:** 0.6.5 (Repository + ViewModel pattern complete - 2025-11-13)
**Next Release:** 0.7.0 (Testing, refinement, CSV enhancements)
**Future Release:** 0.7.5 (Semantic foundation + basic LLM integration - pre-launch)

## Version History

| Version | Date | Milestone | Notes |
|---------|------|-----------|-------|
| 0.2.0 | - | Git history begins | Python implementation starts |
| 0.2.5 | - | Flask deployment | Python Flask API deployed |
| 0.3.0 | - | Swift journey begins | Initial Swift project setup |
| 0.5.0 | 2025-10-25 | Foundation complete, rearchitecture needed | SQLiteData working, protocols defined, but needs structural rethink |
| 0.6.0 | 2025-11-08 | Coordinator pattern complete | Phases 1-3 done: 3NF schema, models migrated, all 4 coordinators with full CRUD |
| **0.6.5** | **2025-11-13** | **Repository + ViewModel complete** | All 4 entities migrated to @Observable pattern, repositories with Sendable, query wrappers eliminated |
| **0.7.0** | **TBD** | **Testing + refinement** | Manual/automated testing, CSV enhancements, bug fixes |
| **0.7.5** | **TBD** | **Semantic foundation + basic LLM** | Unified semantic layer for deduplication/search/LLM, conversational goal setting |

## Current Implementation Focus

**Active:** Swift (iOS 26+ / macOS 26+)
**On Hold:** Python backend

The two implementations have diverged significantly and **no longer share a database**.

## Swift Milestones (v0.5.0 Honest Assessment)

### ✅ Proven Concepts
- SQLiteData integration works (@Table, @Column decorators)
- Protocol system compiles (temporal separation: Completable/Doable)
- Basic SwiftUI views functional (can test on phone)
- Database operations confirmed working

### ⚠️ Needs Rearchitecture
- **Data structures**: Too many optionals, dictionary→array conversion pain
- **Protocol system**: 9 protocols - unclear if solving problems or adding ceremony
- **SwiftUI integration**: Struct ↔ @State conversion is awkward
- **Design language**: Minimal/immature - no visual identity defined
- **Generalization**: Goal/Milestone separation might be over-engineered

### ❌ Not Started (Critical for 1.0)
- Design language definition (visual identity, component library)
- Accessibility (VoiceOver labels) - **CRITICAL**
- Dynamic Type support (migrate from custom zoom)
- Platform integrations (AppIntents, EventKit)
- Test suite (broken after database migration)

## Path to 1.0 (Revised - 7-Phase Rearchitecture + Semantic Layer)

**Based on**: [swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md](swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md)

```
0.5.0 - Phases 1-2 complete: Schema & Models ✅
0.6.0 - Phase 3: Coordinator pattern complete ✅ (current)
0.7.0 - Phase 4: Validation + Repository layer complete
0.7.5 - SEMANTIC FOUNDATION + BASIC LLM (pre-launch enhancement) 🆕
0.8.0 - Phases 5-6: ViewModels + Views (UI fully functional)
0.9.0 - Phase 7: Testing & Migration complete + Advanced semantic features
1.0.0 - First stable release (Swift only)
```

**Phase Timeline**:
- ✅ Phase 1-2 (Schema & Models): 2 weeks (complete)
- ✅ Phase 3 (Coordinators): 1 week (complete)
- 🚧 Phase 4 (Validation + Repositories): 3-4 weeks (in progress, see REPOSITORY_IMPLEMENTATION_PLAN.md)
- **🆕 v0.7.5 (Semantic Foundation)**: 24-28 hours (parallel to Phase 4)
- Phase 5 (ViewModels): 1 week
- Phase 6 (Views): 1 week
- Phase 7 (Testing/Migration): 1-2 weeks

**Estimated Time to 1.0**: 7-9 weeks from v0.6.0

### v0.7.5 Semantic Foundation Details

**Goal:** Build unified semantic infrastructure that serves deduplication, search, and LLM integration

**Deliverables:**
1. **SemanticService** - NLEmbedding wrapper for sentence embeddings + cosine similarity
2. **EmbeddingCache** - Database storage for semantic embeddings (semanticEmbeddings table)
3. **Enhanced DuplicationDetector** - Hybrid LSH + semantic similarity (catches paraphrases)
4. **Basic LLM Integration** - 3 tools (GetGoals, GetValues, CreateGoal) + conversational UI
5. **Database Schema** - semantic_llm_schema.sql (embeddings + conversation persistence)

**Architecture Decision:** Single semantic layer serves all use cases
- ✅ Deduplication: Hybrid scoring (60% semantic, 40% syntactic/LSH)
- ✅ Search: Semantic similarity queries (future - Phase 2)
- ✅ LLM Tools: RAG via RetrieveMemoryTool (future - Phase 2)

**Integration Points:**
- Uses existing Coordinators (GoalCoordinator, etc.) for validated writes
- Uses existing FetchKeyRequest patterns for database queries
- No new write paths, minimal risk to existing functionality

**Why v0.7.5 (not v0.8.0)?**
- Pre-launch enhancement, not part of core rearchitecture phases
- Can develop in parallel with Phase 4 (Validation + Repositories)
- Sets foundation for post-launch semantic features (v0.9+)

**Future Semantic Phases:**
- v0.8-0.9: Semantic search, RAG memory retrieval, conversation persistence
- v1.0+: Values alignment coach, reflection prompts, advanced LLM features


- First stable release
- **Criteria for 1.0:**
  - ✅ All tests passing
  - ✅ Accessibility complete (VoiceOver support)
  - ✅ Documentation up-to-date
  - ✅ At least one platform integration (AppIntents OR EventKit)
  - ✅ App Store ready

### When to bump MAJOR (1.0.0 → 2.0.0)
- Breaking changes (database schema changes)
- Major architectural rewrites
- Removing deprecated features

## Single Source of Truth

**File:** `version.txt` (project root)
**Content:** Plain text version number (e.g., `0.8.0`)

**Python reads from:** `python/version.py` → reads `../version.txt`
**Swift reads from:** `swift/Sources/App/Version.swift` → reads version.txt

## Bump Version Script

```bash
#!/bin/bash
# Usage: ./bump_version.sh 0.8.1 "Fix test suite after SQLiteData migration"

NEW_VERSION=$1
MESSAGE=$2

if [ -z "$NEW_VERSION" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: ./bump_version.sh <version> <message>"
    echo "Example: ./bump_version.sh 0.8.1 'Fix test suite'"
    exit 1
fi

# Update version.txt
echo "$NEW_VERSION" > version.txt

# Git commit and tag
git add version.txt
git commit -m "chore: Bump version to $NEW_VERSION

$MESSAGE"
git tag -a "v$NEW_VERSION" -m "v$NEW_VERSION - $MESSAGE"

echo "✓ Version bumped to $NEW_VERSION"
echo "Run 'git push && git push --tags' to publish"
```

## Current Status Summary (Updated 2025-11-13)

**Swift Implementation:** Phases 1-5 complete (v0.6.5)
- ✅ Phase 1: 3NF schema designed and tested
- ✅ Phase 2: Swift models migrated to SQLiteData
- ✅ Phase 3: Coordinator pattern complete (ActionCoordinator, GoalCoordinator, PersonalValueCoordinator, TimePeriodCoordinator)
- ✅ Phase 4: Validation + Repository layer (complete 2025-11-13)
  - ✅ Validation rules framework (ValidationRules.swift, ValidationUtilities.swift, ValidationError.swift)
  - ✅ All 4 repositories complete (Goal, Action, PersonalValue, TimePeriod)
  - ✅ Repository patterns established:
    - JSON Aggregation: Goals, Actions (1:many relationships, 2-3x faster)
    - #sql Macro: PersonalValues (simple entities)
    - Query Builder: Terms (simple 1:1 JOINs)
  - ✅ All repositories have Sendable conformance (Swift 6 compliant)
  - ✅ GoalCoordinator validation integration (two-phase: validateFormData → validateComplete)
- ✅ Phase 5: ViewModels refactor (complete 2025-11-13)
  - ✅ All 4 list ViewModels created (Goals, Actions, PersonalValues, Terms)
  - ✅ @Observable pattern throughout (no ObservableObject)
  - ✅ All views use @State (not @StateObject)
  - ✅ All query wrappers eliminated (Queries/ directory empty)
  - Reference: `swift/docs/JSON_AGGREGATION_MIGRATION_PLAN.md`
- ⏳ Phase 6: Views refinement & testing
- ⏳ Phase 7: Testing & Migration
- ❌ Design language: Liquid Glass foundation in place, refinement ongoing
- ❌ Accessibility: Not started (target: before 1.0)

**Python Implementation:** Archived
- Last stable: 0.2.5 (Flask deployment) - Tagged as v1.0-python
- No longer actively developed

**Breaking Changes**: Intentional during rearchitecture
- MatchingService, GoalFormView, ActionsViewModel, GoalsViewModel
- Will be fixed in Phases 3-6
