# ViewModel Tests

## Purpose
Answer the question: **Do ViewModels correctly orchestrate coordinators and handle errors?**

## Why These Tests Matter
ViewModels are the UI's interface to the data layer. The code *looks* like it calls coordinators, but:
- Does error handling actually work? (errorMessage set correctly?)
- Are loading states managed properly? (isSaving toggled?)
- Do ViewModels assemble FormData correctly from individual params?
- What happens when coordinator throws?

## Critical Unknowns From Reading Code
1. **Error Propagation**: When coordinator throws ValidationError, does ViewModel catch it and set errorMessage? (Code shows try/catch, but does it work?)
2. **State Management**: Is isSaving always set to false in defer block? (Even on throw?)
3. **FormData Assembly**: Do individual params get correctly assembled into FormData struct? (Easy to miss a field)
4. **Coordinator Integration**: Does ViewModel actually call coordinator methods? (Could be stubbed)
5. **@Observable Behavior**: Do @Published... wait, we're using @Observable - does property observation work without @Published?

## What We're NOT Testing
- ❌ That ViewModel has save/update/delete methods (obvious from reading)
- ❌ That ViewModel uses @Observable (obvious from code)
- ❌ That coordinator property exists (obvious from reading)

## What We ARE Testing
- ✅ **Error handling**: Coordinator throws → errorMessage set, user sees it
- ✅ **Loading states**: isSaving true during operation, false after (even on error)
- ✅ **FormData assembly**: All fields from params correctly map to FormData
- ✅ **Coordinator calls**: ViewModel actually invokes coordinator.create/update/delete
- ✅ **Result propagation**: Coordinator returns entity → ViewModel returns it to view

## Test Files
- `ActionFormViewModelTests.swift` - "Does error handling work? Is FormData assembled correctly?"
- `GoalFormViewModelTests.swift` - "Complex FormData (5 models) assembled without field loss?"
- `TimePeriodFormViewModelTests.swift` - "Does specialization enum pass through correctly?"
- `PersonalValuesFormViewModelTests.swift` - "Simplest case - proves basic ViewModel pattern"

## Key Questions Each File Answers

### ActionFormViewModelTests
- **Q**: When save() called with valid data, does coordinator.create() get invoked?
- **Q**: When coordinator throws ValidationError, is errorMessage set?
- **Q**: Is isSaving false after save completes (both success and error)?
- **Q**: Are measurements and goalContributions correctly passed to ActionFormData?
- **Q**: Does update() preserve actionId when calling coordinator?

### GoalFormViewModelTests
- **Q**: Are all 5 model inputs (Expectation, Goal, Measures, Relevances, Term) assembled into GoalFormData?
- **Q**: When coordinator throws (invalid measureId), does error propagate correctly?
- **Q**: Does delete() handle complex cascade (5 models) without error?
- **Q**: Are targets (ExpectationMeasure inputs) correctly assembled from UI?
- **Q**: Are alignments (GoalRelevance inputs) correctly assembled with strength values?

### TimePeriodFormViewModelTests
- **Q**: Does specialization enum (.term(number) vs .year vs .custom) pass through correctly?
- **Q**: When saving Term, is termNumber correctly included in specialization?
- **Q**: Does update preserve TimePeriod.id and logTime?

### PersonalValuesFormViewModelTests
- **Q**: Does save() successfully create PersonalValue via coordinator?
- **Q**: When coordinator throws (e.g., duplicate title), does error display?
- **Q**: Is valueLevel enum correctly passed from UI to FormData?
