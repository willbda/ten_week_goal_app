# Form Component Refactor Plan

**Status**: Planning phase complete, components sketched, existing files marked
**Date**: 2025-11-03
**Goal**: Systematic UI consistency across all forms

---

## Problem Statement

Forms have inconsistent UI due to scattered layout logic:

### Specific Issues (from screenshots)

1. **ActionFormView**: Measurement TextField pushed far right
   - Picker in HStack takes most space
   - Value field cramped at `.frame(width: 80)`
   - Poor alignment

2. **PersonalValuesFormView**: Centered but needs padding
   - Layout mostly good
   - Spacing/padding inconsistent with other forms

3. **TermFormView**: Good reference implementation ✅
   - Clean layout, proper spacing
   - Can serve as template

---

## Solution: Component Library

Extract layout logic into reusable components. Fix once, all forms benefit.

### Component Files Created

```
Sources/App/Views/Components/FormComponents/
├── MeasurementInputRow.swift      (Skeleton - 10 lines)
├── MultiSelectSection.swift       (Skeleton - 10 lines)
├── RepeatingSection.swift         (Skeleton - 10 lines)
├── TimingSection.swift            (Skeleton - 10 lines)
├── README.md                      (Documentation)
└── REFACTOR_PLAN.md              (This file)
```

All skeleton files compile ✅ (contain TODO placeholders)

### Existing Files Marked for Refactor

**ActionFormView.swift**:
```swift
// 🔧 PLANNED REFACTOR (2025-11-03):
// - Replace timingSection with TimingSection component
// - Replace measurementsSection with RepeatingSection<MeasurementInputRow>
// - Replace goalContributionsSection with MultiSelectSection
// - Extract buildFormData() helper pattern for template
```

**PersonalValuesFormView.swift**:
```swift
// 🔧 PLANNED REFACTOR (2025-11-03):
// - Ensure padding matches component library standards
// - Layout is already good (uses DocumentableFields)
// - May benefit from extracting value-specific sections to components
```

**TermFormView.swift**:
```swift
// ✅ FORM LAYOUT STATUS (2025-11-03):
// This form has good layout and spacing - can serve as reference.
// May benefit from TimingSection component if we add duration tracking.
// Currently uses DatePicker fields directly which is fine.
```

---

## Implementation Roadmap

### Phase 1: Implement Components (1 day)

1. **MeasurementInputRow** (2 hours)
   - Full-width Picker (not cramped in HStack)
   - Value TextField: `.frame(width: 100)` with proper alignment
   - Unit label: Show selected measure's unit
   - Remove button: Consistent styling
   - Test: Should fix ActionFormView alignment issue

2. **MultiSelectSection** (1.5 hours)
   - Generic over Item type
   - Toggle bindings for Set<UUID>
   - Empty state handling
   - Test: Replace goal picker in ActionFormView

3. **RepeatingSection** (1.5 hours)
   - Section wrapper with add button
   - Consistent spacing for items
   - Footer support
   - Test: Wrap measurements in ActionFormView

4. **TimingSection** (1 hour)
   - DatePicker + duration field
   - Consistent TextField sizing
   - Test: Replace timing section in ActionFormView

### Phase 2: Refactor ActionFormView (2 hours)

**Goal**: Fix the alignment issue visible in screenshot

**Before**:
```swift
// Custom layout - alignment problem
private var measurementsSection: some View {
    Section {
        ForEach($measurements, id: \.id) { $measurement in
            HStack {
                Picker(...) { ... }
                    .labelsHidden()  // Takes most space
                TextField(..., value: $measurement.value)
                    .frame(width: 80)  // Cramped!
                Button(...) { ... }  // Remove
            }
        }
    }
}
```

**After**:
```swift
// Using components - proper alignment
RepeatingSection(
    title: "Measurements",
    items: measurements,
    addButtonLabel: "Add Measurement",
    footer: "Track distance, time, count, or other metrics",
    onAdd: addMeasurement
) { measurement in
    MeasurementInputRow(
        measureId: binding(for: measurement.id).measureId,
        value: binding(for: measurement.id).value,
        availableMeasures: viewModel.availableMeasures,
        onRemove: { removeMeasurement(id: measurement.id) }
    )
}
```

**Validation**:
- Run app
- Open Edit Action
- Check: TextField NOT pushed far right ✅
- Check: Picker has full width ✅
- Check: Layout matches TermFormView reference ✅

### Phase 3: Review PersonalValuesFormView (1 hour)

**Goal**: Ensure padding consistency

**Tasks**:
- Compare spacing with ActionFormView (post-refactor)
- Apply same padding standards
- Test: All forms have consistent spacing

### Phase 4: Create FormTemplate.swift (30 min)

**Goal**: Copy/paste template for new forms

**Structure**:
```swift
// Shows component usage patterns
// Clear examples of each component
// Copy for new entities
```

### Phase 5: Test & Document (1 hour)

**Test scenarios**:
- Create action with measurements
- Edit action (check alignment)
- Create value (check padding)
- Create term (reference)

**Documentation**:
- Update README with usage examples
- Screenshot comparison (before/after)
- Mark refactor complete

---

## Success Criteria

- [ ] All 4 components implemented
- [ ] ActionFormView refactored (alignment fixed)
- [ ] PersonalValuesFormView padding consistent
- [ ] FormTemplate.swift created
- [ ] Build successful
- [ ] Manual testing passed
- [ ] Screenshots show improvement

---

## Current Build Status

✅ **Build Successful (2.24s)**

All skeleton files compile without errors. Components contain TODO placeholders.

```bash
[10/14] Compiling App MultiSelectSection.swift
[11/14] Compiling App RepeatingSection.swift
[12/14] Compiling App TimingSection.swift
[13/14] Compiling App MeasurementInputRow.swift
Build complete! (2.24s)
```

---

## Design Principles

1. **Layout in components** - Not in forms
2. **Styling is consistent** - Font, padding, colors
3. **Generic where possible** - Works with any data
4. **Composable** - Forms assemble components
5. **Single source of truth** - Change once, fixes everywhere

---

## Notes

- All existing forms still work (no breaking changes yet)
- Components are placeholders with clear TODOs
- Refactor comments guide implementation
- Can test other features while planning refactor
- TermFormView serves as reference for good layout

---

## Next Steps

When ready to implement:
1. Start with MeasurementInputRow (fixes main issue)
2. Test in ActionFormView
3. Proceed with other components
4. Final refactor and template creation

**Estimate**: 1-2 days for complete refactor
