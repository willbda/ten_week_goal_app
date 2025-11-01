# Implementation Quick Reference
**For**: Ten Week Goal App 3NF Rearchitecture
**Updated**: 2025-10-30

## 🎯 Current Focus: Phase 3 - Repository Layer

### What to Build Next

```swift
// WEEK 1 PRIORITY - Core Repositories
ActionRepository.swift
├── create(action:, metrics:)
├── findWithMetrics(id:)
├── findByMetric(metric:)
└── sumByMetric(metric:, dateRange:)

GoalRepository.swift
├── create(goal:, targets:, values:)
├── findWithProgress(id:)
├── findByTerm(term:)
└── findByValue(value:)

ValueRepository.swift
├── findByLevel(level:)
├── findAlignedGoals(value:)
└── calculateAlignment(action:)
```

## 📊 Database Quick Reference

### Entities (Have Persistable Fields)
```
actions       → No measuresByUnit JSON!
goals         → No measurementUnit/Target!
values        → Unified table with valueLevel
terms         → Clean structure
metrics       → New catalog entity
```

### Junction Tables (Minimal Fields)
```
actionMetrics      → action.id, metric.id, value
goalMetrics        → goal.id, metric.id, targetValue
goalRelevances     → goal.id, value.id, alignmentStrength
actionGoalContrib  → action.id, goal.id, contributionAmount
termGoalAssigns    → term.id, goal.id, assignmentOrder
```

## 🔴 Known Broken Code

| File | Issue | Fix in Phase |
|------|-------|--------------|
| MatchingService | Uses measuresByUnit | Phase 3 (Repository) |
| GoalFormView | Uses measurementUnit | Phase 5 (Views) |
| ActionsViewModel | Expects JSON | Phase 4 (ViewModels) |
| GoalsViewModel | Calls goal.isSmart() | Phase 4 (ViewModels) |

## ✅ What's Working

- All models compile
- Migration script works
- Database schema is solid
- Foreign keys enforced
- Indexes in place

## 🔧 Common Patterns

### Repository Pattern
```swift
@MainActor
class SomeRepository: ObservableObject {
    private let db: Database

    func findWithRelationships(id: UUID) async throws -> (Entity, [Related]) {
        // 1. Fetch entity
        let entity = try await Entity.find(id)

        // 2. Fetch relationships via junction
        let related = try await Junction.filter(\.entityId == id)

        // 3. Return tuple
        return (entity, related)
    }
}
```

### No Business Logic in Models
```swift
// ❌ WRONG - Model shouldn't query DB
extension Goal {
    func isSmart() -> Bool {
        // Can't access GoalMetric from here!
    }
}

// ✅ RIGHT - Service handles DB queries
class GoalValidation {
    func classify(goal: Goal, metrics: [GoalMetric]) -> Classification {
        // Can query database here
    }
}
```

### Junction Table Usage
```swift
// Creating relationships
let action = Action(...)
let metric = Metric.kilometers
let measurement = ActionMetric(
    actionId: action.id,
    metricId: metric.id,
    value: 5.2
)

// Querying relationships (in Repository)
let measurements = try await ActionMetric
    .filter(\.actionId == action.id)
    .including(required: \.metric)  // If GRDB associations setup
```

## 📁 File Locations

```
swift/
├── Sources/
│   ├── Models/
│   │   ├── Kinds/          ✅ Entities done
│   │   └── Relationships/  ✅ Junctions done
│   ├── App/
│   │   ├── Services/       🚧 Build repositories here
│   │   └── ViewModels/     ❌ Broken, fix in Phase 4
│   └── Database/
│       └── proposed_3nf.db ✅ Test data available
└── docs/
    └── MASTER_REARCHITECTURE_PLAN.md  📘 Full details
```

## 🚀 Next Steps Checklist

### This Week (Phase 3)
- [ ] Create ActionRepository with tests
- [ ] Create GoalRepository with tests
- [ ] Create ValueRepository with tests
- [ ] Update MetricRepository (exists but basic)
- [ ] Create integration test suite

### Next Week (Phase 4)
- [ ] Rewrite ActionsViewModel
- [ ] Rewrite GoalsViewModel
- [ ] Create DashboardViewModel
- [ ] Add proper state management

### Week 3 (Phase 5)
- [ ] Create MetricSelector component
- [ ] Update ActionFormView
- [ ] Update GoalFormView
- [ ] Add ProgressVisualization

## 💡 Key Insights

1. **Junction tables are pure** - Don't add Persistable fields
2. **Models can't query DB** - Use repositories
3. **Clean break is simpler** - No backward compatibility
4. **Repository first** - Everything depends on it
5. **Test with real data** - Use proposed_3nf.db

## 🔗 Related Docs

- Full plan: `MASTER_REARCHITECTURE_PLAN.md`
- Schema: `SCHEMA_FINAL.md`
- Challenges: `NORMALIZATION_CHALLENGES.md`
- Migration: `3NF_MIGRATION_COMPLETE.md`

## ⚡ Quick Commands

```bash
# Run migration
cd swift/Sources/Database
python3 migrate_to_3nf_final.py

# Check new schema
sqlite3 proposed_3nf.db ".schema"

# Test queries
sqlite3 proposed_3nf.db "SELECT * FROM metrics;"

# Build Swift
cd swift && swift build
```

Remember: **Repository layer is the critical path** - everything else is blocked until it exists!