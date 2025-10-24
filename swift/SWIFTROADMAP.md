# Swift Implementation Roadmap

## Status: Production-Ready macOS App with AI Assistant

Last Updated: October 24, 2025

---

## Recent Progress: Major Architecture Improvements (October 17-24, 2025)

### 🎉 Week Highlights (52 commits)

**Major Achievements:**
1. ✅ **Junction Table Migration** - Proper relational design for term-goal relationships
2. ✅ **AI Assistant Integration** - Foundation Models on-device LLM with data access tools
3. ✅ **Swift 6.2 Adoption** - Full strict concurrency compliance
4. ✅ **UUID Primary Keys** - Eliminated dual ID system (~1,088 lines removed)
5. ✅ **Design System** - Centralized design tokens with Liquid Glass materials
6. ✅ **Quick Add System** - Multiple entry points for rapid action logging
7. ✅ **App-wide Zoom** - Semantic zoom (50-200%) with keyboard shortcuts

---

### ✅ October 23, 2025: Database Architecture Refinement

#### Junction Table for Term-Goal Relationships
**Problem Solved:** JSON array storage (`term_goals_by_id`) lacked referential integrity

**Solution Implemented:**
- Created `term_goal_assignments` junction table (shared/schemas/)
- Composite primary key (term_uuid, goal_uuid)
- Foreign keys with CASCADE deletes
- Indexed for efficient bidirectional queries
- Migrated 8 existing assignments from JSON to relational model

**Benefits:**
- Type-safe GRDB associations for querying relationships
- Database-enforced referential integrity
- Efficient "find unassigned goals" queries
- Assignment ordering and audit timestamps

**Code Changes:**
- New: `TermGoalAssignment.swift` model with GRDB conformance
- Modified: `TermFormView`, `TermRowView`, `TermsViewModel` for junction table queries
- New: `TermIntegrationTests` (292 lines, comprehensive junction table testing)
- Modified: `GetTermsTool` to return term-goal associations via LLM

---

### ✅ October 23, 2025: AI Assistant Infrastructure

#### Foundation Models Integration (macOS 26.0+)
**New Capabilities:** On-device conversational AI with data exploration tools

**Core Components Added:**
1. **ConversationHistory Model** (`Sources/Models/Kinds/`)
   - GRDB persistence for chat exchanges
   - Session tracking and freeform notes
   - Schema: `conversation_history.sql`

2. **ConversationService** (`Sources/BusinessLogic/LLM/`)
   - Foundation Models session management
   - Tool invocation framework
   - Error handling (`ConversationError.swift`)
   - Model availability checking (`ModelAvailability.swift`)

3. **Data Access Tools** (4 tools for AI autonomy):
   - `GetGoalsTool`: Search by type, text, date range
   - `GetActionsTool`: Find with measurements, dates
   - `GetTermsTool`: Query ten-week terms and themes
   - `GetValuesTool`: Access personal values and priorities
   - All use `@Generable` for type-safe LLM integration

4. **SwiftUI Chat Interface** (`Sources/App/Views/Assistant/`)
   - `AssistantChatView`: Main chat interface
   - `ChatMessageRow`: Bubble-style message rendering
   - `ConversationViewModel`: @MainActor view model
   - Added to `ContentView` sidebar navigation

**Security Audit:**
- 2 CRITICAL issues identified and resolved (LLM_INTEGRATION_AUDIT.md)
- Removed fake Persistable conformance from ConversationHistory
- Proper migration handling for conversation_history table

---

### ✅ October 23, 2025: Swift 6.2 Strict Concurrency

#### Package.swift Modernization
**Adopted Swift 6.2** with strict concurrency features:
- Updated `swift-tools-version` from 6.0 to 6.2
- Enabled `.enableUpcomingFeature("StrictConcurrency")`
- Zero concurrency warnings in entire codebase

#### Concurrency Pattern Improvements
**Replaced unsafe `@unchecked Sendable` with `@MainActor` isolation:**
```swift
// OLD (unsafe):
@Observable
final class ZoomManager: @unchecked Sendable { }

// NEW (compiler-enforced):
@MainActor
@Observable
final class ZoomManager { }
```

**Benefits:**
- Compile-time thread safety verification
- No runtime data races
- Clear actor isolation boundaries
- Documentation: DESIGN_SYSTEM.md, CLAUDE.md concurrency sections

---

### ✅ October 23, 2025: UUID Primary Key Migration

#### Eliminated Dual ID System
**Problem:** Tables had both `id INTEGER PRIMARY KEY` and `uuid_id TEXT UNIQUE`
- Caused UNIQUE constraint errors on Goal edits
- Required 1,088 lines of translation layer code

**Solution:**
1. **Database Migration** (`shared/database/migrate_to_uuid_primary_key.sql`)
   - Made `uuid_id TEXT PRIMARY KEY` in goals, terms, values tables
   - Migrated 9 goals, 3 terms, 6 values
   - Dropped `uuid_mappings` table

2. **Code Simplification** (deleted 6 files):
   - ActionRecord.swift (206 lines)
   - GoalRecord.swift (215 lines)
   - TermRecord.swift (192 lines)
   - ValueRecord.swift (282 lines)
   - UUIDMapper.swift (115 lines)
   - UUIDStabilityTests.swift (78 lines)

3. **Direct GRDB Conformance:**
   - All models now use GRDB protocols directly
   - `persistenceConflictPolicy = .replace` for INSERT OR REPLACE
   - Centralized UUID encoding strategy in `Protocols.swift`

**Results:**
- ✅ Goal editing works without errors
- ✅ ~900 lines of code removed
- ✅ Simpler architecture (no translation layer)

**Documentation:** UUID_MIGRATION_STATUS.md (detailed migration report)

---

### ✅ October 22-23, 2025: Database Stability & Concurrency

#### WAL Mode Configuration
**Enabled Write-Ahead Logging** for better concurrency:
- PRAGMA journal_mode = WAL
- PRAGMA synchronous = NORMAL
- Foreign keys enabled in GRDB configuration
- Proper checkpoint handling

#### UUID Case Normalization
**Fixed case mismatch issues:**
- Normalized all UUIDs to UPPERCASE (Swift's UUID() default)
- Deleted duplicate actions caused by lowercase vs UPPERCASE
- Action.databaseUUIDEncodingStrategy: .uppercaseString
- Database: Uppercased 189 action UUIDs + 9 goal UUIDs

#### Action CRUD Fixes
- Added `persistenceConflictPolicy(insert: .replace)` to Action model
- Now properly UPDATEs instead of failing with UNIQUE constraint
- `saveAction()` uses `action.save(db)` (handles INSERT OR REPLACE)

---

### ✅ October 22, 2025: Design System & UX

#### Centralized Design System
**Created:** `DesignSystem.swift` with semantic design tokens
- **Spacing:** xxs (4pt) → xxl (48pt) with zoom scaling
- **Colors:** Semantic colors for actions/goals/values/terms + states
- **Materials:** Liquid Glass patterns (.ultraThinMaterial, .regularMaterial)
- **Typography:** Explicit point sizes (headline, subheadline, caption, etc.)
- **ViewModifiers:** FormSectionStyle, SheetStyle, CardStyle
- **Components:** SectionHeader, EmptyStateView

**Typography Migration:** 64 replacements across 10 files
- Migrated from SwiftUI semantic fonts to DesignSystem.Typography
- All fonts scale with zoom level automatically

#### App-wide Zoom System
**ZoomManager:** @MainActor @Observable singleton
- Zoom range: 50-200% (adjustable in 10% increments)
- **Keyboard Shortcuts:**
  - Command-+: Zoom in
  - Command--: Zoom out
  - Command-0: Reset to 100%
- **Semantic Scaling:** All spacing, fonts, dimensions scale proportionally
- **Sharp Text:** Text re-renders at each zoom level (not bitmap scaled)

#### Quick Add System
**Three complementary entry points:**
1. **Duplicate from Rows:** Swipe/context menu on actions
2. **Log from Goals:** Swipe on goal → pre-filled action form
3. **Quick Add Section:** Horizontal scrolling cards
   - Shows recent actions + active goals
   - Persistent expand/collapse state
   - One-tap creation from templates

**Code:**
- `ActionFormView`: Added Mode enum (.create vs .edit)
- `ActionsListView`: Uses ActionFormState wrapper for atomic state
- `QuickAddSectionView`: 282 lines, horizontal card layout
- `BulkMatchingView`: Fast batch action-goal matching (291 lines)

#### Loading States & Form Sheets
**Fixed race condition** during app initialization:
- Added loading states to all sheet presentations
- Shows ProgressView while database initializes
- Prevents blank white modal sheets
- Applied to GoalsListView, ActionsListView, TermsListView

---

### ✅ October 17-21, 2025: Foundation (Previous Week)

#### Relationship System (Phases 1-3)
- ActionGoalRelationship & GoalValueAlignment models
- MatchingService & InferenceService business logic
- GRDB integration with foreign key constraints
- **Tests:** 80 new tests (30 model + 37 business logic + 13 integration)

#### Full Architecture Documentation
- SWIFT_6_2_IMPROVEMENTS.md (1,260 lines)
- DESIGN_SYSTEM.md (comprehensive design guidance)
- LIQUID_GLASS_NOTES.md (macOS UI patterns)
- LLM_INTEGRATION_AUDIT.md (security audit)

---

## Current Status Summary

### What Works Now
✅ **Full CRUD Operations:** Actions, Goals, Terms, Values
✅ **Action-Goal Matching:** Bulk matching view with auto-save
✅ **Term Management:** Junction table with proper relationships
✅ **AI Assistant:** On-device LLM with 4 data access tools
✅ **Design System:** Centralized tokens with Liquid Glass materials
✅ **App-wide Zoom:** Semantic zoom (50-200%) with keyboard shortcuts
✅ **Quick Add:** Three entry points for rapid action logging
✅ **Database:** WAL mode, foreign keys, UUID primary keys
✅ **Swift 6.2:** Strict concurrency, zero warnings
✅ **Testing:** Comprehensive test coverage across all layers

### Test Suite Status
**Total Tests:** 292+ passing (recent count from TermIntegrationTests addition)
- Model tests: 30+ (relationships)
- Business logic tests: 37+ (matching, inference)
- Integration tests: 13+ (GRDB, relationships)
- View tests: Comprehensive SwiftUI view tests
- Term integration: 292 lines of junction table tests

---

## Known Limitations & Design Notes

### Relationship Entities
- **Do NOT conform to `Persistable` protocol** (join tables, not domain entities)
- Use GRDB's native methods directly: `insert()`, `update()`, `delete()`
- Cannot use DatabaseManager's generic `save()` (requires Persistable)
- This is intentional - relationships are projections/cache, not core domain entities

### Goal GRDB Integration
- Minimal conformance added (table name + UUID encoding only)
- Full direct GRDB integration deferred
- Currently uses Record pattern (GoalRecord) in production code
- Full migration planned in future phase

### Swift 6 Concurrency Patterns
- Mutable captures in async closures require pre-capture: `let copy = mutable; try await { use copy }`
- GRDB methods don't mutate structs, so prefer `let` over `var`
- Tests demonstrate proper Swift 6 strict concurrency compliance

---

## Next Steps

### Immediate Priorities

#### 1. Python-Swift Database Coordination (HIGH PRIORITY)
**Problem:** Both implementations write to same database without coordination
- Python uses `shared/database/application_data.db` (configured but not created)
- Swift uses same path with WAL mode enabled
- No database currently exists at shared location
- Risk of write conflicts if both run simultaneously

**Recommended Solutions:** (See "Python Development Plans" section below)

#### 2. AI Assistant Testing & Refinement
**Current State:** Infrastructure complete but needs real-world testing
- Foundation Models integration functional
- 4 data access tools implemented
- Chat UI created but needs UX polish

**Tasks:**
- Test LLM tool invocations with real data
- Refine prompts for better conversation quality
- Add conversation history browsing UI
- Performance testing (latency, token usage)

#### 3. Progress Calculation UI
**Gap:** Business logic exists but no UI
- Swift has MatchingService & InferenceService
- Python has progress_aggregation.py (authoritative)
- No SwiftUI views for progress visualization

**Tasks:**
- Create GoalProgressView with completion metrics
- Visual progress bars (like Python CLI formatters)
- Action contribution breakdown per goal
- Confirm/reject inferred relationships UI

---

### Medium-Term Enhancements

#### 4. Values GRDB Conformance Completion
**Current State:** Partial implementation
- MajorValues, HighestOrderValues have GRDB conformances (Oct 23 fix)
- Polymorphic fetching works
- Still some incomplete fetch methods in DatabaseManager

**Tasks:**
- Complete all Values hierarchy fetch methods
- Add filtering by type and domain
- Integration tests for polymorphic Values storage

#### 5. Document-Based Architecture
**Status:** Partial implementation (GoalDocument.swift exists)
- `.tenweekgoal` file format defined (JSON)
- Import/export individual goals not fully wired

**Tasks:**
- Complete document read/write workflows
- Add export menu items
- Import goals from JSON files
- Drag-and-drop support

---

### Long-Term Vision

#### 6. iOS Companion App
**Foundation Ready:** All models are Sendable, database is SQLite
- Shared codebase (Models, Database, BusinessLogic targets)
- Need iOS-specific UI (compact layouts, gestures)
- CloudKit sync for multi-device support

#### 7. Progress Analytics & Insights
**Data Available:** All action/goal relationships tracked
- Historical trend analysis
- Burndown charts for goals
- Values alignment scoring over time
- Term retrospectives with metrics

#### 8. Calendar/Reminders Integration
**Status:** Deferred (explored Oct 22, see "Deferred Features")
- EventKit integration technical design complete
- Recommend one-way export to Reminders.app first
- Bidirectional sync requires conflict resolution

---

---

## Architecture Achievements

### Type-Safe Relationships
- Compile-time guarantees via GRDB protocols
- Automatic JSON serialization (matchedOn arrays, enum raw values)
- UUID stability across save/fetch cycles

### Swift 6 Strict Concurrency
- Zero concurrency warnings
- Actor isolation for thread safety (InferenceService)
- Sendable conformance throughout

### Separation of Concerns
- Models: Pure data structures
- BusinessLogic: Stateless functions + coordination actors
- Database: Persistence via GRDB
- Tests: Comprehensive coverage at each layer

### Python Compatibility
- Same SQLite schema (shared/schemas/*.sql)
- Compatible data types (TEXT UUIDs, JSON fields)
- Matching business logic (ported from Python's ethica layer)

---

## File Summary

**New Files Created**:
- `Sources/Models/Relationships/ActionGoalRelationship.swift` (200 lines)
- `Sources/Models/Relationships/GoalValueAlignment.swift` (220 lines)
- `Sources/BusinessLogic/MatchingService.swift` (200 lines)
- `Sources/BusinessLogic/InferenceService.swift` (150 lines)
- `Tests/ModelTests/Relationships/ActionGoalRelationshipTests.swift` (345 lines, 15 tests)
- `Tests/ModelTests/Relationships/GoalValueAlignmentTests.swift` (346 lines, 15 tests)
- `Tests/BusinessLogicTests/MatchingServiceTests.swift` (300 lines, 23 tests)
- `Tests/BusinessLogicTests/InferenceServiceTests.swift` (250 lines, 14 tests)
- `Tests/IntegrationTests/RelationshipGRDBTests.swift` (570 lines, 13 tests)

**Modified Files**:
- `shared/schemas/action_goal_progress.sql` (UUID foreign keys)
- `Sources/Models/Kinds/Goals.swift` (added GRDB conformance)
- `Package.swift` (added BusinessLogic target)

**Total Lines Added**: ~2,531 lines of production code + tests

---

## Deferred Features

### Calendar & Reminders Integration (Explored Oct 22, 2025)
**Status**: Deferred for future consideration

**Explored Approaches**:
- **Option A**: One-way export to Apple Reminders.app (simpler, leverages native UI)
- **Option B**: Custom in-app calendar with two-way EventKit sync (complex, fully integrated)
- **Option C**: Hybrid read-only calendar view with editing in Reminders.app

**Key Insights**:
- EventKit provides read/write API, not automatic sync engine
- iCloud syncs Calendar/Reminders across devices, but NOT between apps
- Identity mapping (Goal UUID ↔ EKCalendarItem identifier) requires custom tracking
- Conflict resolution logic needed for bidirectional sync

**Decision**: Deferred until core functionality is complete. If implemented, recommend starting with Option A (export to Reminders) for simplicity.

**Resources**: See calendar sync schema draft (deleted Oct 22) for potential database structure

---

## Python Development Plans

### Context: Multi-Language Architecture

The project currently has TWO implementations sharing ONE database:
- **Python:** Mature v1.0 (90 tests passing, CLI + Flask API)
- **Swift:** Active development (292+ tests passing, macOS app with AI)
- **Shared Database:** `shared/database/application_data.db`
  - Currently doesn't exist (needs initialization)
  - Python configured to use it (config.toml)
  - Swift configured to use it (DatabaseConfiguration.default)

### Critical Issue: Write Conflict Risk

**Problem:**
1. Python writes with default journal mode (DELETE or WAL via pragma)
2. Swift enables WAL mode explicitly in GRDB configuration
3. Both create database if it doesn't exist
4. No coordination if both run simultaneously
5. Schema evolution could diverge

**Database Location Status:**
```bash
shared/database/application_data.db  # Does NOT exist yet
python/politica/data_storage/        # OLD location (deprecated in config)
```

---

### Plan A: Read-Only Python Mode (Recommended for Short-Term)

**Goal:** Let Swift own the database, Python provides read-only analysis/reporting

**Advantages:**
- ✅ Zero write conflicts (Python never writes)
- ✅ Swift's WAL mode benefits reads (no blocking)
- ✅ Simple to implement (remove write operations from Python)
- ✅ Python can still provide CLI reporting, analytics
- ✅ Flask API can serve read-only endpoints

**Implementation Steps:**

1. **Create Database with Swift** (if not exists)
   ```bash
   # Run Swift app once to initialize database
   # OR manually: sqlite3 shared/database/application_data.db < shared/schemas/*.sql
   ```

2. **Update Python politica/database.py:**
   ```python
   # Add read-only connection flag
   def get_db_connection_readonly():
       """Get read-only connection for reporting/analysis"""
       conn = sqlite3.connect(
           f"file:{DB_PATH}?mode=ro",
           uri=True,
           check_same_thread=False
       )
       conn.row_factory = sqlite3.Row
       return conn

   # Disable all write operations
   def insert(*args, **kwargs):
       raise NotImplementedError(
           "Python is in read-only mode. Use Swift app for writes."
       )
   ```

3. **Update Python CLI/Flask for read-only:**
   - Keep: `list`, `show`, `progress` commands (read-only)
   - Remove: `create`, `edit`, `delete` commands
   - Add warning message: "Use Swift app for creating/editing data"

4. **Python Use Cases (Read-Only):**
   - Analytics dashboards (Flask API)
   - Progress reports (CLI)
   - Data exports (CSV, JSON)
   - Automated email reports
   - CI/CD analytics scripts

**Timeline:** 2-3 hours

---

### Plan B: Database Locking Coordination (Medium Complexity)

**Goal:** Both implementations can write, coordinated via file locks

**Advantages:**
- ✅ Both implementations fully functional
- ✅ Works across processes (Swift app + Python CLI)
- ✅ Prevents simultaneous writes

**Disadvantages:**
- ⚠️ Complex error handling (lock acquisition failures)
- ⚠️ User experience issues (CLI blocks while Swift app open)
- ⚠️ Not cross-platform (different lock mechanisms)

**Implementation:**

1. **Create shared lock file:**
   ```python
   # python/politica/database_lock.py
   import fcntl  # Unix only
   from contextlib import contextmanager

   LOCK_FILE = Path("shared/database/application_data.db.lock")

   @contextmanager
   def database_write_lock(timeout=5):
       """Acquire exclusive lock for database writes"""
       lock_file = open(LOCK_FILE, 'w')
       try:
           fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
           yield
       except BlockingIOError:
           raise DatabaseLockError(
               "Database is in use by another process. "
               "Close Swift app and try again."
           )
       finally:
           fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
           lock_file.close()
   ```

2. **Wrap all Python write operations:**
   ```python
   def insert(table, data):
       with database_write_lock():
           # existing insert logic
   ```

3. **Swift DatabaseManager (add locking):**
   ```swift
   // Use NSFileCoordinator for file locking
   // More complex, requires refactoring DatabaseManager init
   ```

**Timeline:** 1-2 days (includes error handling, testing)

---

### Plan C: Separate Databases with Periodic Sync (Complex)

**Goal:** Each implementation has its own database, sync periodically

**Advantages:**
- ✅ Zero runtime conflicts (independent databases)
- ✅ Each can optimize for their access patterns
- ✅ Can evolve schemas independently

**Disadvantages:**
- ❌ Data inconsistency between syncs
- ❌ Complex sync logic (conflict resolution)
- ❌ Doubles storage requirements
- ❌ Confusing user experience (which database is "truth"?)

**Not Recommended** - Adds complexity without clear benefits

---

### Plan D: Migrate Python to Sync API Client (Long-Term Vision)

**Goal:** Python becomes client of Swift app's hypothetical HTTP API

**Advantages:**
- ✅ Single source of truth (Swift owns all data)
- ✅ Python can run remotely (CI/CD servers)
- ✅ Clear separation of concerns
- ✅ Swift can enforce business rules centrally

**Disadvantages:**
- ❌ Requires building Swift HTTP API (not currently planned)
- ❌ Python needs network access (complicates CLI usage)
- ❌ Latency for local operations

**Implementation:**
1. Add HTTP API to Swift app (Vapor or Hummingbird framework)
2. Update Python to call API instead of direct database access
3. Handle authentication, network errors

**Timeline:** 1-2 weeks for full implementation

---

### Recommended Approach: Hybrid Strategy

**Phase 1 (This Week): Plan A - Read-Only Python**
- Fastest to implement (2-3 hours)
- Eliminates write conflicts immediately
- Python still useful for analytics

**Phase 2 (Next Month): Evaluate Need for Python Writes**
- If Python writes are essential → Implement Plan B (locking)
- If read-only is sufficient → Keep Plan A, enhance analytics

**Phase 3 (Future): Consider Plan D**
- If Swift app becomes user-facing product → Add HTTP API
- Python becomes automation/integration layer

---

### Immediate Action Items

**For Swift Development:**
1. ✅ **No changes needed** - Current implementation is correct
2. Consider: Add `--init-db` CLI flag to manually initialize database
3. Consider: Database migration scripts for schema changes

**For Python Development:**
1. **Create database** (choose one):
   ```bash
   # Option 1: Run Swift app (creates database automatically)
   # Option 2: Manual initialization
   cd shared/database
   cat ../schemas/*.sql | sqlite3 application_data.db
   ```

2. **Implement Plan A** (read-only mode):
   - Mark write functions as deprecated/disabled
   - Update CLI to show "read-only mode" warning
   - Keep analytics/reporting functionality
   - Update Flask API for read-only endpoints

3. **Update Documentation:**
   - CLAUDE.md: Explain multi-language architecture
   - python/README.md: Note read-only mode
   - Add database initialization guide

**Timeline:** 3-4 hours for full Python read-only implementation

---

### Schema Compatibility Notes

**Current Schema Alignment:**
- ✅ Actions: Compatible (uuid_id primary key)
- ✅ Goals: Compatible (uuid_id primary key, polymorphism via goal_type)
- ✅ Terms: Compatible (uuid_id primary key)
- ✅ Values: Compatible (uuid_id primary key, polymorphism via value_type)
- ✅ Action-Goal Relationships: Compatible (junction table)
- ✅ Term-Goal Assignments: **NEW in Swift** (junction table)
  - Python doesn't use this yet (still expects term_goals_by_id JSON)
  - **Action Required:** Update Python to query junction table

**Python Schema Updates Needed:**
1. Remove references to `term_goals_by_id` column (now uses junction table)
2. Update term queries to JOIN term_goal_assignments
3. Update conversation_history schema (new in Swift, Oct 23)

**Files to Update:**
- `python/rhetorica/storage_service.py` (TermStorageService)
- `python/interfaces/cli/cli.py` (term commands)
- SQL queries in politica/database.py
