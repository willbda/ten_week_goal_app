# Coordinator Tests

## Purpose
Answer the question: **Do coordinators maintain atomicity and referential integrity?**

## Why These Tests Matter
Coordinators orchestrate multi-model transactions. The code *looks* atomic (wrapped in `database.write {}`), but:
- Does rollback actually happen when one part fails?
- Are foreign key constraints enforced at runtime?
- Do cascade deletes work as expected?
- Is there a race condition when creating related models?

## Critical Unknowns From Reading Code
1. **Atomicity**: If inserting MeasuredAction fails, does Action creation roll back? (Not obvious from reading)
2. **FK Enforcement**: What happens if we try to link to a non-existent Measure? (Database should error, but does coordinator handle it?)
3. **Cascade Order**: When deleting Goal, what order do we delete GoalRelevance, Goal, Expectation? (Wrong order = FK violation)
4. **ID Generation**: Do generated UUIDs actually persist? (Could generate but not save)
5. **Update Semantics**: Does update preserve logTime? (Code shows intent, but does execution match?)

## What We're NOT Testing
- ❌ That coordinator has create/update/delete methods (obvious from reading)
- ❌ That database.write exists (SQLiteData responsibility)
- ❌ That models conform to Table protocol (compiler checks)

## What We ARE Testing
- ✅ **Transaction rollback**: Insert fails halfway, entire transaction rolled back
- ✅ **FK violations**: Attempt to link non-existent entity, get clear error
- ✅ **Cascade deletes**: Delete parent, verify children deleted in correct order
- ✅ **ID preservation**: Update doesn't change ID or logTime
- ✅ **Multi-model atomicity**: All 5 models in GoalCoordinator saved together or not at all

## Test Files
- `PersonalValueCoordinatorTests.swift` - "Simplest case: single model CRUD, proves basic pattern"
- `TimePeriodCoordinatorTests.swift` - "2-model atomicity: TimePeriod + GoalTerm together"
- `ActionCoordinatorTests.swift` - "3-model complexity: Action + MeasuredAction[] + contributions"
- `GoalCoordinatorTests.swift` - "5-model complexity: Most complex transaction, most failure modes"

## Key Questions Each File Answers

### PersonalValueCoordinatorTests
- **Q**: Does update preserve ID and logTime?
- **Q**: Does delete actually remove from database?
- **Q**: What happens on duplicate title? (If unique constraint exists)

### TimePeriodCoordinatorTests
- **Q**: Are TimePeriod and GoalTerm created atomically?
- **Q**: If GoalTerm insert fails, is TimePeriod rolled back?
- **Q**: Does specialization enum (.term vs .year) route correctly?
- **Q**: What's the cascade delete order? (GoalTerm first, then TimePeriod)

### ActionCoordinatorTests
- **Q**: Do multiple MeasuredAction rows get created atomically with Action?
- **Q**: If one measurement has invalid measureId, does entire transaction roll back?
- **Q**: Can we update measurements (add new, remove old) atomically?
- **Q**: Do ActionGoalContributions cascade delete when Action deleted?

### GoalCoordinatorTests
- **Q**: Are all 5 models (Expectation, Goal, ExpectationMeasure[], GoalRelevance[], TermGoalAssignment?) created atomically?
- **Q**: If ExpectationMeasure insert fails (invalid measureId), does entire transaction roll back?
- **Q**: If GoalRelevance insert fails (invalid valueId), does entire transaction roll back?
- **Q**: What's the correct delete cascade order for 5 models?
- **Q**: Does update preserve Expectation.logTime while updating Goal fields?
- **Q**: Can we add/remove measures and relevances atomically during update?
