# Documentation Status & Gap Analysis
**Created**: 2025-10-31
**Written by**: Claude Code

This document identifies divergences between project documentation, GitHub issues, and actual implementation status.

---

## Executive Summary

### Current Reality
- **Version**: 0.5.0-rearchitecture (per version.txt)
- **Branch**: experiment/rearchitecture-data-structures
- **Phase**: Database & Models Complete (Phases 1-2), Repository Layer Next (Phase 3)
- **Breaking Changes**: Intentional - 4 known broken components

### Key Findings
1. ✅ **GitHub Issue #7** is outdated - says "Phase 1 Active" but Phases 1-2 are complete
2. ⚠️ **README.md** describes old architecture with Python/Swift split - doesn't reflect 3NF rearchitecture
3. ✅ **VERSIONING.md** is accurate - acknowledges 0.5.0 with rearchitecture in progress
4. ✅ **ARCHITECTURE_REEVALUATION.md** is still relevant for open questions
5. ✅ **REARCHITECTURE_COMPLETE_GUIDE.md** is now the single source of truth (created today)

---

## Gap Analysis by Document

### 1. GitHub Issue #7: "Rearchitecture: Database Schema → Models → Protocols → ViewModels"

**Issue URL**: https://github.com/willbda/ten_week_goal_app/issues/7
**Status**: OPEN (created 2025-10-28)

#### What's Outdated
```
Current Phase: Phase 1 - Database Schema Design (active)
```

**Reality**: Phases 1-2 complete as of 2025-10-30

#### Checklist Divergence
Issue shows all tasks for Phases 1-2 as unchecked `[ ]`, but they're actually complete:

**Phase 1 Tasks** (Should be ✅):
- [x] Finalize core schema decisions (unified values ✅, metrics as entities ✅, pure junctions ✅)
- [x] Define metrics catalog structure (Metric model created ✅)
- [x] Design relationship tables (All 5 junction tables created ✅)
- [x] Swift implementation (Replaced Python migration ✅)
- [x] Document schema decisions (SCHEMA_FINAL.md, 3NF_MIGRATION_COMPLETE.md ✅)

**Phase 2 Tasks** (Should be ✅):
- [x] Created new model structs (Metric, MeasuredAction, GoalRelevance, ActionGoalContribution ✅)
- [x] Updated existing models (Action, Value, TermGoalAssignment ✅)
- [x] Updated @Table definitions (All using SQLiteData ✅)
- [x] CloudKit sync configuration (SyncEngine updated ✅)

#### Recommended Update
Update issue #7 with:
1. Change status to "Current Phase: Phase 3 - Repository/Service Layer (next)"
2. Mark Phases 1-2 tasks as complete
3. Link to new REARCHITECTURE_COMPLETE_GUIDE.md
4. Update with breaking changes list

---

### 2. README.md (Project Root)

**File**: `/README.md`
**Last Updated**: 2025-10-18 (per doc), 2025-10-19 (per git)

#### What's Outdated

**Section: "Core Concepts - What This Tracks"**
```markdown
- **Actions**: Daily activities with optional measurements (distance, duration, reps, etc.)
```
❌ **Reality**: Actions no longer have `measuresByUnit` JSON - measurements are in `MeasuredAction` junction table

**Section: "Implementation Status - Swift"**
```markdown
Swift (swift/): Active development
- Protocol-oriented architecture matching Python layers
- SQLite integration with GRDB.swift
- Native macOS/iOS planned with SwiftUI
```
❌ **Reality**:
- No longer using GRDB - migrated to SQLiteData
- No longer matching Python layers - 3NF schema is Swift-specific
- Python implementation effectively abandoned
- macOS/iOS apps exist and are functional (not "planned")

**Section: "Project Status"**
```markdown
- **Python**: On pause
- **Swift**: Active development (protocol-oriented refactor complete)
- **Shared**: Database schemas stable
- **Last Updated**: 2025-10-18
```
❌ **Reality**:
- Database schemas NOT stable - complete 3NF rearchitecture in progress
- Protocol-oriented refactor NOT complete - Phase 4 pending protocol redesign
- Python effectively abandoned (not just "on pause")

#### Recommended Updates
1. Add section: "## 🚧 Major Rearchitecture in Progress (v0.5.0)"
2. Update "Core Concepts" to reflect 3NF normalized schema
3. Replace "SQLite integration with GRDB.swift" with "SQLiteData with CloudKit sync"
4. Add link to REARCHITECTURE_COMPLETE_GUIDE.md
5. Update "Last Updated" to 2025-10-31

---

### 3. VERSIONING.md

**File**: `/VERSIONING.md`
**Last Updated**: 2025-10-25

#### What's Accurate ✅
- Version: 0.5.0-rearchitecture ✅
- "⚠️ DOCUMENTATION FREEZE" warning ✅
- "Foundation complete, rearchitecture needed" ✅
- Breaking changes acknowledged ✅
- Honest assessment of completeness (~50%) ✅

#### What's Outdated
**Section: "Path to 1.0 (Revised)"**
```
0.5.0 - Current state (foundation works, needs rethink)
0.6.0 - Data structure simplification (fewer optionals, remove unnecessary protocols)
0.6.5 - SwiftUI integration patterns (ViewModels or better struct shapes)
0.7.0 - Design language defined (visual identity, component library)
```

❌ **Reality**: We've chosen 3NF normalization with clean break, not "simplification"

**Section: "Estimated Time to 1.0"**
```
Estimated Time to 1.0: 25-40 hours (accounting for rearchitecture)
- Rearchitecture (data + protocols): 8-12 hours
```

❌ **Reality**: Per REARCHITECTURE_COMPLETE_GUIDE.md, 5-7 weeks total (not hours)

#### Recommended Updates
1. Update version roadmap to match REARCHITECTURE_COMPLETE_GUIDE phases
2. Change time estimates from hours to weeks
3. Update "Current Status Summary" with Phase 1-2 completion
4. Add note about clean break migration strategy

---

### 4. ARCHITECTURE_REEVALUATION.md

**File**: `/ARCHITECTURE_REEVALUATION.md`
**Last Updated**: 2025-10-25

#### What's Still Relevant ✅
- Design questions about optionals, protocols, SwiftUI integration ✅
- "What feels wrong? What feels right?" questions ✅
- Protocol complexity analysis (9 protocols) ✅
- Dictionary → array pain points ✅

#### What's Resolved
- ✅ **Decided**: 3NF normalization (addressed dictionary pain)
- ✅ **Decided**: Clean break migration (addressed backward compatibility question)
- ✅ **Decided**: Metrics as first-class entities (addressed measuresByUnit JSON)
- ✅ **Decided**: Unified values table (addressed 4 tables complexity)

#### What's Still Open
- ❓ Protocol system redesign (Phase 4 pending)
- ❓ SwiftUI integration patterns (Phase 5 pending)
- ❓ Design language definition (deferred)
- ❓ Concurrency & threading approach (open question)

#### Recommended Action
- Keep document as-is - it's a valuable historical snapshot
- Link to REARCHITECTURE_COMPLETE_GUIDE.md for resolution status
- Update with "Status: Phase 1-2 decisions made, Phase 4+ questions still open"

---

### 5. GitHub Issue #6: "Add Apple Health Workout Viewer"

**Issue URL**: https://github.com/willbda/ten_week_goal_app/issues/6
**Status**: OPEN (created 2025-10-28)

#### Relationship to Rearchitecture
Issue states:
```
# Related Issues
- Can integrate with metrics system after Phase 4
```

✅ **Accurate** - HealthKit integration makes sense AFTER repository/service layer exists

#### Status
- ❌ No work started (Stage 1 not begun)
- ✅ Correctly positioned as "future enhancement"
- ✅ Well-documented multi-stage plan

#### Recommended Action
- No changes needed
- Defer until Phase 4 (Repository/Service Layer) complete
- Metrics system will enable better workout → action tracking

---

## Documentation Hierarchy (Current State)

### Primary Documents (Single Source of Truth)
1. **REARCHITECTURE_COMPLETE_GUIDE.md** (NEW - created 2025-10-31)
   - Merged MASTER_REARCHITECTURE_PLAN, REARCHITECTURE_ISSUE, CLEAN_REARCHITECTURE_PLAN
   - Current phase status
   - Implementation roadmap
   - Code examples

2. **version.txt** - Current version (0.5.0-rearchitecture)

3. **swift/Sources/Database/SCHEMA_FINAL.md** - 3NF schema definition

### Supporting Documents (Context & History)
4. **VERSIONING.md** - Version history and roadmap (needs update)
5. **README.md** - Project overview (needs update)
6. **ARCHITECTURE_REEVALUATION.md** - Design questions (still relevant)
7. **swift/docs/20251025_plan.md** - Original design thinking (historical)

### Archived Documents
8. **swift/docs/archive/** - Old planning documents

### GitHub Issues
9. **Issue #7** - Rearchitecture tracking (needs update)
10. **Issue #6** - HealthKit feature (accurate, deferred)

---

## Recommended Update Priority

### High Priority (Update This Week)
1. **GitHub Issue #7** - Mark Phases 1-2 complete, update current phase
2. **README.md** - Add rearchitecture notice, fix outdated implementation details
3. **VERSIONING.md** - Align roadmap with REARCHITECTURE_COMPLETE_GUIDE phases

### Medium Priority (Update After Phase 3)
4. **ARCHITECTURE_REEVALUATION.md** - Add resolution status note
5. Create **CHANGELOG.md** - Track breaking changes

### Low Priority (Update Before 1.0)
6. **Python README** - Mark as archived/deprecated
7. **Swift ROADMAP** - Consolidate with REARCHITECTURE_COMPLETE_GUIDE

---

## Breaking Changes Log (For Users)

Current breaking changes (as of 0.5.0-rearchitecture):

1. **MatchingService** - References removed fields
   - `measuresByUnit` (now in MeasuredAction junction)
   - `measurementUnit` (now in GoalMetric junction)

2. **GoalFormView** - References removed fields
   - `measurementUnit`, `measurementTarget` (now in GoalMetric)
   - `howGoalIsRelevant`, `howGoalIsActionable` (now in GoalRelevance)

3. **ActionsViewModel** - Expects removed fields
   - `measuresByUnit` JSON dictionary

4. **GoalsViewModel** - Expects removed method
   - `goal.isSmart()` (will be in GoalValidation service)

**Migration Path**: Clean break - export old data, import into new schema (tested successfully)

---

## Action Items

### For GitHub
- [ ] Update Issue #7 status and checklist
- [ ] Consider adding labels: `phase-3-next`, `breaking-change`, `documentation`
- [ ] Add milestone: "v0.6.0 - Repository Layer Complete"

### For Documentation
- [ ] Update README.md with current architecture
- [ ] Update VERSIONING.md roadmap
- [ ] Add CHANGELOG.md for breaking changes
- [ ] Create MIGRATION_GUIDE.md for users

### For Code
- [ ] Start Phase 3: Repository/Service Layer (per REARCHITECTURE_COMPLETE_GUIDE)
- [ ] Fix broken components (MatchingService, ViewModels)
- [ ] Add Phase 3 tests

---

## Version Alignment Check

| Source | Version | Status | Notes |
|--------|---------|--------|-------|
| version.txt | 0.5.0-rearchitecture | ✅ Accurate | Reflects current state |
| VERSIONING.md | 0.5.0-rearchitecture | ✅ Accurate | Good description |
| README.md | 0.8.0 implied | ❌ Wrong | Says "protocol-oriented refactor complete" |
| Git tag | v1.0-python | ⚠️ Confusing | Only Python tagged, Swift untagged |
| Latest commit | 661e181 | ✅ Accurate | "Version 0.5.0-rearchitecture" message |

**Recommendation**: Create git tag `v0.5.0-rearchitecture` to match version.txt

---

## Summary

**What's Working**:
- REARCHITECTURE_COMPLETE_GUIDE.md is excellent single source of truth
- VERSIONING.md acknowledges current state honestly
- Breaking changes are documented
- Migration tested successfully

**What Needs Attention**:
1. GitHub Issue #7 outdated (still says Phase 1 active)
2. README.md describes old architecture
3. No git tag for 0.5.0-rearchitecture
4. Estimated time to 1.0 inconsistent (hours vs weeks)

**Recommended Next Actions**:
1. Update GitHub Issue #7 → "Phase 3 Next"
2. Add rearchitecture notice to README.md
3. Create git tag: `v0.5.0-rearchitecture`
4. Begin Phase 3: Repository Layer implementation

---

**Conclusion**: Documentation is mostly accurate at the detailed level (schema docs, migration docs) but needs synchronization at the high level (README, GitHub issue, version tags). The creation of REARCHITECTURE_COMPLETE_GUIDE.md today is a major step toward consolidation.
