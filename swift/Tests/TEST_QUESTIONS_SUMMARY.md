# Test Questions Summary

## What We've Created

**5 README files** explaining test philosophies:
- `ValidationTests/README.md` - Why validator tests matter
- `CoordinatorTests/README.md` - Why atomicity/FK tests matter
- `QueryTests/README.md` - Why N+1 prevention matters
- `ViewModelTests/README.md` - Why error propagation matters
- `EndToEndTests/README.md` - Why full-cycle tests matter

**5 Test scaffolds** with genuine question comments:
- `CoordinatorTests/PersonalValueCoordinatorTests.swift` - Simple CRUD atomicity
- `CoordinatorTests/ActionCoordinatorTests.swift` - 3-model atomicity
- `QueryTests/ActionsQueryTests.swift` - JOIN correctness + N+1 prevention
- `ViewModelTests/ActionFormViewModelTests.swift` - Error propagation
- `EndToEndTests/CRUDWorkflowTests.swift` - Full user workflows

---

## Questions Organized by Criticality

### 🔴 CRITICAL: Questions That Could Cause Data Loss

**If these aren't working, users lose data or see corrupted state**

#### Transaction Rollback (ActionCoordinator)
- **Q**: If MeasuredAction insert fails, is Action insert rolled back?
- **Why Critical**: Partial writes leave orphaned Actions without measurements
- **Test**: `ActionCoordinatorTests` - "Create: Rolls back Action if measurement FK invalid"

#### Cascade Delete Order (GoalCoordinator)
- **Q**: When deleting Goal, what order do we delete GoalRelevance, Goal, Expectation?
- **Why Critical**: Wrong order = FK violation, goal not deleted, orphaned data
- **Test**: `GoalCoordinatorTests` - "Delete: Cascades in correct order"

#### Update Completeness (All Coordinators)
- **Q**: When updating relationships, are old rows removed or do they accumulate?
- **Why Critical**: Old data accumulates, query returns stale + new data mixed
- **Test**: `CRUDWorkflowTests` - "Update goal targets → Old targets removed"

### 🟠 HIGH: Questions That Could Cause Incorrect Behavior

**If these aren't working, app appears functional but gives wrong results**

#### JOIN Correctness (ActionsQuery)
- **Q**: Do measurements actually belong to their parent action?
- **Why High**: Wrong JOIN = Action A shows Action B's measurements
- **Test**: `ActionsQueryTests` - "Measurements belong to correct parent action"

#### N+1 Query Problem (ActionsQuery)
- **Q**: Does query execute 1 query or N+1 queries?
- **Why High**: N+1 = slow app, doesn't scale beyond 100 actions
- **Test**: `ActionsQueryTests` - "Performance: Executes single query for multiple actions"

#### Error Propagation (ActionFormViewModel)
- **Q**: When coordinator throws ValidationError, does ViewModel set errorMessage?
- **Why High**: User sees no error, thinks save worked, data not actually saved
- **Test**: `ActionFormViewModelTests` - "Save: Sets errorMessage on ValidationError"

#### ID Preservation (All Coordinators)
- **Q**: Does update() preserve the original ID?
- **Why High**: New ID = duplicate entity, old entity orphaned
- **Test**: `PersonalValueCoordinatorTests` - "Update: Preserves original ID"

### 🟡 MEDIUM: Questions That Could Cause Confusion

**If these aren't working, app works but behaves unexpectedly**

#### Empty Relationship Handling (ActionsQuery)
- **Q**: What happens when Action has zero measurements?
- **Why Medium**: Query might return nil instead of empty array, causes UI confusion
- **Test**: `ActionsQueryTests` - "Query: Returns empty array for action with no measurements"

#### State Management (ActionFormViewModel)
- **Q**: Is isSaving false after save completes (both success and error)?
- **Why Medium**: Button stays disabled, user thinks save still running
- **Test**: `ActionFormViewModelTests` - "Save: Sets isSaving=false after completion"

#### Duplicate Detection (ActionCoordinator)
- **Q**: What happens if we try to create duplicate measurement (same measureId)?
- **Why Medium**: Unclear if duplicates are allowed or rejected
- **Test**: `ActionCoordinatorTests` - "Create: Rejects duplicate measurements"

### 🟢 LOW: Questions That Validate Edge Cases

**If these aren't working, app mostly works but fails on uncommon inputs**

#### Large Values (ActionCoordinator)
- **Q**: Can we create Action with very large measurement value (1 million)?
- **Why Low**: Rare, but could overflow
- **Test**: `ActionCoordinatorTests` - "Create: Handles large measurement values"

#### Long Strings (PersonalValueCoordinator)
- **Q**: Can we create with very long title (1000+ chars)?
- **Why Low**: Users rarely enter 1000-char titles
- **Test**: `PersonalValueCoordinatorTests` - "Create: Handles very long title (1000 chars)"

---

## Recommended Starting Points

### Option A: Start with CRITICAL Questions (Data Loss Prevention)
**Rationale**: If these fail, users lose data - highest priority
**Start with**:
1. `ActionCoordinatorTests` - Transaction rollback questions (~5 tests)
2. `CRUDWorkflowTests` - Update completeness questions (~3 tests)
3. **Total**: ~8 tests, 2-3 hours, prevents data loss

### Option B: Start with HIGH Questions (Correctness)
**Rationale**: If these fail, app gives wrong results - high user impact
**Start with**:
1. `ActionsQueryTests` - JOIN correctness + N+1 (~5 tests)
2. `ActionFormViewModelTests` - Error propagation (~3 tests)
3. `PersonalValueCoordinatorTests` - ID preservation (~2 tests)
4. **Total**: ~10 tests, 3-4 hours, ensures correct behavior

### Option C: Start with Full Vertical Slice (PersonalValue)
**Rationale**: Proves entire stack works for simplest entity
**Start with**:
1. `PersonalValueCoordinatorTests` - CRUD operations (~10 tests)
2. `PersonalValuesFormViewModelTests` - Error handling (~5 tests)
3. `CRUDWorkflowTests` - PersonalValue flows (~4 tests)
4. **Total**: ~19 tests, 4-5 hours, proves pattern works

### Option D: Start with Most Uncertain Code (GoalCoordinator)
**Rationale**: If 356-line GoalCoordinator works, everything simpler works too
**Start with**:
1. `GoalCoordinatorTests` - 5-model atomicity (~15 tests)
2. **Total**: ~15 tests, 5-6 hours, validates most complex component

---

## Test Maturity Levels

Each test can be implemented at different maturity levels:

### Level 1: Smoke Test (Minimal)
- **What**: Test succeeds without throwing
- **Example**: Create action, expect no error
- **Value**: Catches obvious breaks (syntax errors, missing methods)
- **Time**: 5-10 min per test

### Level 2: State Verification (Standard)
- **What**: Test operation + verify database state
- **Example**: Create action, query database, verify exists
- **Value**: Catches logic errors (data not persisted)
- **Time**: 15-20 min per test

### Level 3: Comprehensive (Thorough)
- **What**: Test operation + edge cases + error paths + performance
- **Example**: Create action, verify FK correctness, test rollback, measure query time
- **Value**: Catches edge cases and performance issues
- **Time**: 30-60 min per test

**Recommendation**: Start with Level 2 (State Verification) for critical questions, Level 1 for others.

---

## Decision Time: Which Tests Add Most Value?

### For Each Question, Ask:
1. **What breaks if this doesn't work?** (User impact)
2. **How obvious is this from reading code?** (Novelty of test)
3. **How confident are we this works?** (Risk)
4. **How expensive is it to test?** (Cost)

### Example Analysis: "Does update() preserve ID?"

1. **What breaks**: Duplicates + orphans (🔴 Critical)
2. **Obvious from code**: Yes, code shows `id: existingId`, but execution could differ (🟡 Medium novelty)
3. **Confidence**: Medium - code looks right but no proof (🟠 Medium risk)
4. **Cost**: Low - create, update, verify ID (🟢 ~15 min)

**Verdict**: HIGH VALUE - Critical impact, medium risk, low cost

### Example Analysis: "Can we handle 1000-char titles?"

1. **What breaks**: Title truncated or error (🟢 Low impact)
2. **Obvious from code**: Not obvious, but unlikely to fail (🟢 Low novelty)
3. **Confidence**: High - database should handle (🟢 Low risk)
4. **Cost**: Low - create with long string (🟢 ~10 min)

**Verdict**: LOW VALUE - Low impact, low risk, would still be nice to test later

---

## Next Steps

1. **Review this summary**
2. **Pick starting point** (Option A/B/C/D or custom)
3. **For each test question**:
   - Decide: Worth implementing? (High/Med/Low value)
   - Decide: What maturity level? (Smoke/Standard/Comprehensive)
4. **Implement tests incrementally**
5. **Update REARCHITECTURE_COMPLETE_GUIDE.md** with evidence as tests pass
