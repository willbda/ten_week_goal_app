# End-to-End Tests

## Purpose
Answer the question: **Do complete user workflows work from UI intent to database persistence to query retrieval?**

## Why These Tests Matter
Individual components might work in isolation, but integration is where failures happen:
- ViewModel calls coordinator, but does data actually persist?
- Coordinator creates relationships, but do queries find them?
- Delete cascades, but do orphaned records remain?
- User updates entity, but do old relationships get cleaned up?

## Critical Unknowns From Reading Code
1. **Data Persistence**: ViewModel.save() returns success, but did data actually write to DB? (Could return cached object)
2. **Query Retrieval**: Coordinator creates Action+Measurements, but does ActionsQuery fetch them? (JOIN might be wrong)
3. **Cascade Integrity**: Delete action, but do MeasuredAction rows actually disappear? (CASCADE might not be configured)
4. **Update Atomicity**: Update goal targets, but do old ExpectationMeasure rows get removed? (Could accumulate)
5. **Cross-Component**: FormView → ViewModel → Coordinator → Database → Query → ListView - does data flow work end-to-end?

## What We're NOT Testing
- ❌ UI rendering (that's UI tests with Xcode UI Testing)
- ❌ That SwiftUI views exist (obvious from code)
- ❌ Individual component logic (tested in unit/integration tests)

## What We ARE Testing
- ✅ **Full data cycle**: Create → Query → Display (data makes round trip)
- ✅ **Relationship integrity**: Create with relationships → Query retrieves related data correctly
- ✅ **Cascade correctness**: Delete parent → Verify children gone, unrelated data preserved
- ✅ **Update completeness**: Update entity → Old data removed, new data present, no orphans
- ✅ **Complex workflows**: Multi-step user actions work as a sequence

## Test Files
Rather than pre-defining test files, let's identify **user workflows** and create tests for each:

## Critical User Workflows to Test

### Workflow Category: Basic CRUD
- **Create Entity**: User creates PersonalValue → Query retrieves it with all fields intact
- **Update Entity**: User updates PersonalValue.title → Query shows new title, old title gone
- **Delete Entity**: User deletes PersonalValue → Query returns empty, value truly gone

### Workflow Category: Relationships
- **Create with Relationships**: User logs Action with 2 measurements → Query fetches Action with both measurements
- **Update Relationships**: User updates Action to add 3rd measurement → Query shows all 3, no duplicates
- **Delete with Cascade**: User deletes Action → MeasuredAction and ActionGoalContribution rows gone, but Measure catalog intact

### Workflow Category: Multi-Model Entities
- **Create Goal**: User creates goal "Run 100km" with 2 targets + 1 value alignment → GoalsQuery fetches complete graph
- **Update Goal Targets**: User changes from 1 target to 3 targets → Old target removed, 3 new targets exist
- **Delete Goal**: User deletes goal → Expectation, Goal, ExpectationMeasure[], GoalRelevance[] all cascade deleted, but referenced Values/Measures intact

### Workflow Category: Cross-Entity
- **Action → Goal Progress**: User logs action contributing to goal → Goal progress can be calculated from ActionGoalContributions
- **Term → Goals**: User creates term and assigns 3 goals → TermsQuery shows term with 3 assigned goals
- **Value → Goals**: User creates value and aligns 2 goals to it → Value page shows 2 aligned goals

### Workflow Category: Edge Cases
- **Empty Database**: Query on empty database returns empty array, not error
- **Orphaned Relationships**: Action exists with MeasuredAction pointing to deleted Measure → FK constraint prevents or query handles gracefully?
- **Concurrent Updates**: Two updates to same entity → Last write wins? Or conflict error?

## Key Questions E2E Tests Answer

### Data Integrity
- **Q**: When I create an Action via ViewModel, can I immediately query it back?
- **Q**: When I update Goal targets, are old ExpectationMeasure rows actually deleted?
- **Q**: When I delete Action, are ALL related rows (measurements, contributions) cascade deleted?
- **Q**: Do related entities (Measures, Values) survive when consuming entities (Actions, Goals) are deleted?

### Workflow Completeness
- **Q**: Can I create a complete Goal (5 models) and retrieve all parts via GoalsQuery?
- **Q**: Can I update a multi-metric Goal without losing data or creating duplicates?
- **Q**: Can I delete a complex entity graph without leaving orphans?

### Real-World Scenarios
- **Q**: User creates goal, logs 5 actions contributing to it, then queries progress - does math work?
- **Q**: User creates term, assigns 3 goals, completes 1 goal, deletes another - does term reflect correct state?
- **Q**: User creates value, aligns 4 goals to it, deletes 2 goals - does value page show remaining 2?

## Test Organization Strategy
Instead of many small test files, create **workflow-based test suites**:

```
EndToEndTests/
  CRUDWorkflowTests.swift          // Basic create/update/delete cycles
  RelationshipWorkflowTests.swift  // Actions with measurements/contributions
  MultiModelWorkflowTests.swift    // Goals with 5-model graphs
  ProgressTrackingWorkflowTests.swift  // Action → Goal progress calculation
  CascadeDeleteWorkflowTests.swift // Delete parent, verify children handling
```

Each suite focuses on a **user goal**, not a component.
