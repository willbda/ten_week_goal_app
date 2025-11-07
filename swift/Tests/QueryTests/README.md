# Query Tests (FetchKeyRequest Pattern)

## Purpose
Answer the question: **Do queries fetch related data efficiently without N+1 problems?**

## Why These Tests Matter
Queries use FetchKeyRequest with JOINs to fetch multi-model data. The code *looks* like it does single queries, but:
- Does it actually execute one query or multiple?
- Are the JOINs correct (matching on right FKs)?
- Do we get orphaned data if relationships are broken?
- What happens with empty databases or missing relationships?

## Critical Unknowns From Reading Code
1. **N+1 Queries**: ActionsQuery claims single JOIN, but does it actually avoid N+1? (Need to count queries)
2. **JOIN Correctness**: Are we joining on the correct FKs? (Code shows intent, execution could differ)
3. **Null Handling**: What if Action has no measurements? Does query still work? (LEFT JOIN needed?)
4. **Performance**: With 100 actions, is query still fast? (Code looks efficient, but is it?)
5. **Wrapper Types**: Do wrapper types (ActionWithMeasurements) correctly combine related data?

## What We're NOT Testing
- ❌ That query files exist (obvious)
- ❌ That FetchKeyRequest protocol is implemented (compiler checks)
- ❌ That structs have expected fields (obvious from reading)

## What We ARE Testing
- ✅ **Single query execution**: Verify only 1 SQL query runs (no N+1)
- ✅ **Correct relationships**: Measurements belong to correct action (FK join works)
- ✅ **Empty handling**: Query works when no data exists (doesn't crash)
- ✅ **Null relationships**: Action with no measurements returns empty array, not nil
- ✅ **Performance**: 100+ entities fetch in <100ms
- ✅ **Ordering**: Results come back in expected order (termNumber DESC, logTime DESC)

## Test Files
- `ActionsQueryTests.swift` - "Does JOIN fetch Action+Measurements+Contributions in one query?"
- `GoalsQueryTests.swift` - "Does complex JOIN handle Goal+Expectation+Measures+Relevances?"
- `TermsQueryTests.swift` - "Does TimePeriod+GoalTerm JOIN work? Correct ordering?"
- `PersonalValuesQueryTests.swift` - "Does ordering by priority/valueLevel work correctly?"

## Key Questions Each File Answers

### ActionsQueryTests
- **Q**: How many SQL queries execute for ActionsWithMeasuresAndGoals? (Should be 1)
- **Q**: Do measurements correctly map to their parent action? (FK join accuracy)
- **Q**: What happens when Action has 0 measurements? (Empty array or error?)
- **Q**: What happens when Action has 0 goal contributions? (Handled gracefully?)
- **Q**: With 100 actions (300 measurements), is query still performant? (<100ms)

### GoalsQueryTests
- **Q**: Does GoalsWithDetails fetch all 4 related tables in one query?
- **Q**: Are ExpectationMeasure[] and GoalRelevance[] correctly grouped by goal?
- **Q**: What if Goal has no measures or no relevances? (Empty arrays?)
- **Q**: Does query handle TermGoalAssignment being optional? (may not be assigned to term)

### TermsQueryTests
- **Q**: Does TermsWithPeriods JOIN TimePeriod and GoalTerm correctly?
- **Q**: Are terms returned in termNumber DESC order? (Most recent first)
- **Q**: What if TimePeriod exists without GoalTerm? (Orphan data - should not happen, but test it)

### PersonalValuesQueryTests
- **Q**: Are values correctly ordered by priority?
- **Q**: Does grouping by valueLevel work in UI queries?
- **Q**: What if no values exist? (Empty result, not error)
