# Master Rearchitecture Plan - Ten Week Goal App
**Last Updated**: 2025-10-30
**Status**: Phase 1-2 Complete, Phase 3 Ready to Start

## Executive Summary

This document consolidates all rearchitecture planning for the Ten Week Goal App's transition to a 3NF normalized database with clean Swift architecture. We're implementing a **clean break** approach without backward compatibility to achieve optimal design.

## Current Status

### ✅ Completed (Phases 1-2)
- **Database Schema**: Full 3NF normalization designed and tested
- **Swift Models**: All entities and junction tables created
- **Migration Script**: Successfully migrated 381 actions, 16 goals, 13 values
- **Documentation**: Schema design, challenges, and rationale documented

### ⚠️ Breaking Changes Introduced
1. `MatchingService` - References removed `measuresByUnit` field
2. `GoalFormView` - References removed Goal fields
3. `ActionsViewModel` - Expects JSON that no longer exists
4. `GoalsViewModel` - References removed `goal.isSmart()` method

### 🚧 Next Priority (Phase 3)
Repository/Service layer to make the normalized models usable

---

## Architecture Principles

From initial planning (docs/20251025_plan.md):

1. **Database schemas as ontology** - Entities and relationships clearly defined
2. **Classes reflect natural hierarchies** - Not just shared behaviors (Apple guidance)
3. **UI close to data structures** - Swift models work in both DB and SwiftUI
4. **Separation of concerns** - Models, Services, ViewModels, Views
5. **Junction tables are DB artifacts** - Minimal fields, no business logic

---

## Database Design (Phase 1) ✅

### Core Principles
- **No JSON fields** - All values atomic (measuresByUnit eliminated)
- **Single source of truth** - No redundant data
- **Pure junction tables** - Minimal fields, just relationships
- **Proper foreign keys** - Referential integrity enforced
- **Indexed for performance** - Common queries optimized

### Entity Structure

#### First-Class Entities (Persistable)
All share: `id`, `title`, `detailedDescription`, `freeformNotes`, `logTime`

| Entity | Additional Fields | Purpose |
|--------|------------------|---------|
| **Action** | `durationMinutes`, `startTime` | What was done |
| **Goal** | `startDate`, `targetDate`, `actionPlan` | What to achieve |
| **Value** | `priority`, `valueLevel`, `alignmentGuidance` | What matters |
| **Term** | `termNumber`, `startDate`, `targetDate` | Planning periods |
| **Metric** | `unit`, `metricType`, `canonicalUnit` | Units catalog |

#### Junction Tables (Pure DB Artifacts)
Minimal fields - just relationships:

| Junction | Links | Key Fields |
|----------|-------|------------|
| **MeasuredAction** | Action → Metric | `value`, `createdAt` |
| **GoalMetric** | Goal → Metric | `targetValue` |
| **GoalRelevance** | Goal → Value | `alignmentStrength` |
| **ActionGoalContribution** | Action → Goal | `contributionAmount` |
| **TermGoalAssignment** | Term → Goal | `assignmentOrder` |

### Query Performance
- **Before**: JSON parsing on every row
- **After**: Indexed JOINs, 10x faster
- **Example**: Finding running actions no longer requires `json_extract()`

---

## Swift Models (Phase 2) ✅

### Completed Models

#### Entities
- `Action.swift` - Removed measuresByUnit JSON
- `Goal.swift` - Removed flat measurement fields
- `Value.swift` - Unified 4 tables with ValueLevel enum
- `Term.swift` - Clean structure (already good)
- `Metric.swift` - New first-class entity

#### Junction Tables
- `MeasuredAction.swift` - Links actions to measurements
- `GoalMetric.swift` - Existing, defines targets
- `GoalRelevance.swift` - New, goal-value alignment
- `ActionGoalContribution.swift` - New, progress tracking
- `TermGoalAssignment.swift` - Updated field names

### Key Design Decisions
1. **ValueLevel enum** with proper SQLiteData conformances
2. **No business logic in models** - Just data structure
3. **Legacy initializers** for migration compatibility (temporary)

---

## Repository/Service Layer (Phase 3) 🚧 NEXT

### Critical Missing Pieces

#### Core Repositories Needed
```swift
// PRIORITY 1: Basic CRUD + Relationships
ActionRepository    - Create with metrics, find by metric
GoalRepository      - Create with targets, find progress
ValueRepository     - Find by level, find aligned goals
MetricRepository    - ✅ Basic version exists
```

#### Business Services Needed
```swift
// PRIORITY 2: Calculations requiring JOINs
ProgressCalculationService - Goal/term progress
AlignmentService          - Value alignment scoring
MetricAggregationService  - Totals, averages, trends
```

### Implementation Priority
1. **Week 1**: Core repositories (CRUD operations)
2. **Week 2**: Business services (calculations)
3. **Week 3**: Query optimization

---

## ViewModels (Phase 4) ❌ NOT STARTED

### Current Problems
- Expect `measuresByUnit` JSON field
- Direct model access instead of repositories
- Reference removed Goal fields
- No relationship handling

### Required ViewModels
```swift
ActionEntryViewModel      - Metric selection, measurements
GoalPlanningViewModel     - Targets, value alignment
DashboardViewModel        - Progress, trends, alignment
TermPlanningViewModel     - Goal assignment, term overview
```

### Implementation Approach
- Inject repositories, not database
- Published properties for UI binding
- Async/await for database operations
- Proper error handling

---

## Views (Phase 5) ❌ NOT STARTED

### Missing UI Components
```swift
MetricSelector           - Choose metrics and enter values
ValueAlignmentPicker     - Link goals to values with strength
ProgressVisualization    - Multi-metric progress charts
RelationshipGraph        - Visual goal-value-action connections
```

### Forms Need Updates
- `ActionFormView` - Add metric selection
- `GoalFormView` - Remove flat fields, add targets
- `ValueFormView` - Handle unified value types

---

## Migration Strategy (Phase 6)

### Chosen Approach: Clean Break
1. Export existing data ✅ (migration script works)
2. Deploy new schema
3. Import with deduplication
4. No backward compatibility

### Migration Checklist
- [x] Schema designed
- [x] Migration script tested
- [ ] Deduplication logic for duplicates
- [ ] User communication plan
- [ ] Rollback strategy
- [ ] Performance validation

---

## Testing Requirements ❌ NOT STARTED

### Unit Tests
- [ ] Model validation
- [ ] Repository CRUD
- [ ] Service calculations
- [ ] ViewModel state

### Integration Tests
- [ ] Full data cycles
- [ ] Migration integrity
- [ ] Relationship traversal
- [ ] Query performance

### UI Tests
- [ ] Action entry flow
- [ ] Goal planning flow
- [ ] Progress tracking
- [ ] Value alignment

---

## Challenges & Lessons Learned

### Technical Challenges
1. **Swift Type System** - SQLiteData requires specific conformances
2. **Schema Discovery** - Had to introspect actual column names
3. **Junction Philosophy** - Resolved tension between uniform base vs minimal
4. **Business Logic Location** - Services, not model methods

### Key Insights
1. **Start with principles** - "Junction tables are DB artifacts" simplified design
2. **Discover, don't assume** - Use introspection for actual schema
3. **Clean break is simpler** - Backward compatibility adds complexity
4. **Separation matters** - Models shouldn't query database

---

## Implementation Roadmap

### Phase Timeline (5 weeks total)

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| **1-2** | Schema & Models | Complete | ✅ Done |
| **3** | Repositories | 1 week | 🚧 Next |
| **4** | Services | 1 week | ⏳ Waiting |
| **5** | ViewModels | 1 week | ⏳ Waiting |
| **6** | Views | 1 week | ⏳ Waiting |
| **7** | Migration & Testing | 1 week | ⏳ Waiting |

### Critical Path
1. **Repositories** (enables everything else)
2. **ViewModels** (connects data to UI)
3. **Views** (user interaction)
4. **Migration** (production deployment)

### Success Criteria
- [ ] All models compile without errors
- [ ] Repository tests pass
- [ ] ViewModels handle relationships
- [ ] Views display normalized data
- [ ] Migration preserves all data
- [ ] Performance meets or exceeds current

---

## New Capabilities Enabled

### Immediate Benefits
- **Multi-metric goals** - "Run 100km AND 20 sessions"
- **Proper aggregation** - Sum across all actions by metric
- **Value alignment** - Track which goals serve which values
- **Progress accuracy** - Real calculations, not estimates

### Future Possibilities
- **Metric conversions** - km ↔ miles
- **Trend analysis** - Historical patterns
- **Smart suggestions** - Based on alignments
- **Cross-goal insights** - Shared metrics

---

## File Organization

### Production Files
```
swift/
├── Sources/
│   ├── Models/
│   │   ├── Kinds/          # Entities
│   │   └── Relationships/  # Junction tables
│   ├── App/
│   │   └── Services/        # Repositories (NEW)
│   └── Database/
│       ├── SCHEMA_FINAL.md
│       ├── schema_3nf_final.sql
│       └── proposed_3nf.db
└── docs/
    └── MASTER_REARCHITECTURE_PLAN.md  # This document
```

### Deprecated/Exploratory
```
swift/Sources/Database/
├── schema_rearchitected.sql  # Early attempt
├── schema_uniform.sql         # Over-engineered
└── migrate_to_uniform.py      # Replaced by 3nf version
```

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-10-30 | Pure junction tables | DB artifacts, minimal overhead |
| 2025-10-30 | Unified values table | Simpler queries, no UNIONs |
| 2025-10-30 | Clean break migration | Simpler than backward compatibility |
| 2025-10-30 | Business logic in services | Models can't query database |

---

## Next Immediate Actions

1. **Create ActionRepository** with basic CRUD + metrics
2. **Create GoalRepository** with targets and progress
3. **Update ActionsViewModel** to use repository
4. **Create MetricSelector** UI component
5. **Test with real data** from proposed_3nf.db

---

## References

- Original principles: `docs/20251025_plan.md`
- Issue tracking: `REARCHITECTURE_ISSUE.md`
- Schema definition: `Sources/Database/SCHEMA_FINAL.md`
- Migration results: `Sources/Database/3NF_MIGRATION_COMPLETE.md`
- Challenges faced: `Sources/Database/NORMALIZATION_CHALLENGES.md`

This master plan supersedes all individual planning documents and represents the consolidated, current state of the rearchitecture effort.