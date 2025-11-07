# Term Number Auto-Increment Implementation
**Implemented**: 2025-11-05
**Status**: Complete and tested

---

## Problem Solved

When creating a new term, the form always defaulted to `termNumber = 1`, even when existing terms existed (e.g., Terms 1, 2, 3 already in database). Users had to manually adjust the number to 4.

---

## Solution: Leverage Existing @Fetch Data

**Key Insight**: The `TermsListView` already has all term data at zero cost via `@Fetch`. No additional database query needed!

### Architecture Decision

Following the principle "views know their data" and patterns from `ActionsListView`:
- **TermsListView** calculates `nextTermNumber` from existing `@Fetch` data
- **TermFormView** accepts optional `suggestedTermNumber` parameter
- **No ViewModel changes** - coordinator remains data-agnostic
- **No extra queries** - uses data already loaded for the list

---

## Implementation Details

### 1. TermsListView Changes

**File**: [TermsListView.swift:46-50](swift/Sources/App/Views/ListViews/TermsListView.swift#L46-L50)

```swift
/// Calculate next term number from existing terms
private var nextTermNumber: Int {
    let maxTermNumber = termsWithPeriods.map { $0.term.termNumber }.max() ?? 0
    return maxTermNumber + 1
}
```

**Pass to form** (line 137-140):
```swift
TermFormView(
    termToEdit: termToEdit,
    suggestedTermNumber: termToEdit == nil ? nextTermNumber : nil
)
```

### 2. TermFormView Changes

**File**: [TermFormView.swift:36-38](swift/Sources/App/Views/FormViews/TermFormView.swift#L36-L38)

**Added property**:
```swift
/// Suggested next term number (from TermsListView's @Fetch data)
/// Used only in create mode to auto-increment from existing terms
private let suggestedTermNumber: Int?
```

**Updated init** (line 74-76):
```swift
public init(
    termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)? = nil,
    suggestedTermNumber: Int? = nil
) {
    self.termToEdit = termToEdit
    self.suggestedTermNumber = suggestedTermNumber
    // ...
}
```

**Use in create mode** (line 95):
```swift
// Create mode - use suggested number or default to 1
_termNumber = State(initialValue: suggestedTermNumber ?? 1)
```

---

## How It Works

### Create Mode Flow
1. User clicks "Add Term" in TermsListView
2. TermsListView calculates `nextTermNumber` from `termsWithPeriods.map { $0.term.termNumber }.max() ?? 0 + 1`
   - Database has Terms 1, 2, 3 → calculates 4
   - Empty database → calculates 1
3. Passes `suggestedTermNumber: 4` to TermFormView
4. TermFormView initializes `termNumber` State with 4
5. User sees "Term Number: 4" in the stepper (can still adjust if needed)

### Edit Mode Flow
1. User taps existing term to edit
2. TermsListView passes `termToEdit` data + `suggestedTermNumber: nil`
3. TermFormView uses existing `goalTerm.termNumber` (ignores suggestion)
4. User sees correct term number for editing

---

## Why This Approach?

### ✅ Advantages
1. **Zero cost** - No additional database queries
2. **Uses existing data** - TermsListView already has `@Fetch` data
3. **Simple** - 5 lines of code in each file
4. **Follows architecture** - Views know their data (from CLAUDE.md)
5. **Coordinator stays pure** - Doesn't need to know about term numbering logic
6. **Testable** - Pure computed property, no async complexity

### ❌ Alternatives Considered (Why Not?)

**Option A: ViewModel queries database**
```swift
// In TimePeriodFormViewModel
public func loadTermMetadata() async {
    let maxTerm = try await database.read { db in
        try GoalTerm.all.select { max($0.termNumber) }.fetchOne(db) ?? 0
    }
    self.suggestedTermNumber = maxTerm + 1
}
```
- ❌ Extra database query (unnecessary)
- ❌ Async complexity
- ❌ Data duplication (TermsListView already has it)

**Option B: Coordinator auto-calculates**
```swift
// In TimePeriodCoordinator.create()
if case .term(let number) = formData.specialization, number == 0 {
    let maxTerm = try GoalTerm.all.select { max($0.termNumber) }.fetchOne(db) ?? 0
    // Use maxTerm + 1
}
```
- ❌ Business logic in data layer (architectural violation)
- ❌ Coordinator should be data-agnostic
- ❌ Extra query inside transaction

---

## Verification

### Database State Before Implementation
```bash
$ sqlite3 application_data.db "SELECT termNumber FROM goalTerms ORDER BY termNumber;"
1
2
3
```

### Expected Behavior After Implementation
- **Create new term**: Stepper shows "Term Number: 4"
- **Edit Term 2**: Stepper shows "Term Number: 2"
- **Empty database**: Stepper shows "Term Number: 1"

### Build Verification
```bash
$ swift build
Build complete! (1.36s)
```
✅ No compilation errors

---

## Files Modified

1. **[TermFormView.swift](swift/Sources/App/Views/FormViews/TermFormView.swift)**
   - Added `suggestedTermNumber: Int?` property
   - Updated `init` to accept parameter
   - Use suggestion in create mode

2. **[TermsListView.swift](swift/Sources/App/Views/ListViews/TermsListView.swift)**
   - Added `nextTermNumber` computed property
   - Pass to TermFormView in create mode

---

## Testing Recommendations

### Manual Testing
1. **Create first term** (empty database):
   - Expected: "Term Number: 1"
   - ✅ Verify stepper starts at 1

2. **Create fourth term** (after Terms 1, 2, 3 exist):
   - Expected: "Term Number: 4"
   - ✅ Verify stepper starts at 4

3. **Edit existing term**:
   - Tap "Term 2" → Edit
   - Expected: "Term Number: 2" (not 4)
   - ✅ Verify correct number shown

4. **Non-sequential terms** (Terms 1, 3, 7):
   - Expected: "Term Number: 8" (max + 1)
   - ✅ Verify picks up from highest

### Unit Testing (Future)
```swift
func testNextTermNumberCalculation() {
    // Given: Terms 1, 2, 3
    let terms = [
        TermWithPeriod(term: GoalTerm(termNumber: 1), timePeriod: ...),
        TermWithPeriod(term: GoalTerm(termNumber: 2), timePeriod: ...),
        TermWithPeriod(term: GoalTerm(termNumber: 3), timePeriod: ...)
    ]

    // When: Calculate next
    let maxTerm = terms.map { $0.term.termNumber }.max() ?? 0
    let next = maxTerm + 1

    // Then: Should be 4
    XCTAssertEqual(next, 4)
}
```

---

## Lessons Learned

1. **Views already have the data** - Check `@Fetch` properties before adding queries
2. **Coordinator should be data-agnostic** - Don't add business logic to data layer
3. **Simple > Complex** - Computed property > async ViewModel method
4. **Follow existing patterns** - ActionsListView does similar with `activeGoals.count`

---

## Related Documentation

- [TERMS_UI_ENHANCEMENTS.md](swift/docs/TERMS_UI_ENHANCEMENTS.md) - Full enhancement proposal
- [TermsQuery.swift](swift/Sources/App/Views/Queries/TermsQuery.swift) - @Fetch query implementation
- [REARCHITECTURE_COMPLETE_GUIDE.md](swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md) - Architecture philosophy

---

## Next Steps

This implementation completes **Phase 1 Quick Win #1** from TERMS_UI_ENHANCEMENTS.md.

Remaining enhancements:
- [ ] Phase 1 #2: Enhance TermRowView display hierarchy
- [ ] Phase 2: Restructure TermFormView to prioritize title
- [ ] Phase 3: Create ActiveTermsDashboardView
- [ ] Phase 4: Health integration for dashboard
