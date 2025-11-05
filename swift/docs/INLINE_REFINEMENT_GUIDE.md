# Inline Refinement Guide

**Created**: 2025-11-03
**Status**: Planning complete, comments embedded in code
**Purpose**: Document the refinement pattern established for remaining vertical slices

---

## Summary

Based on discussion with consultant about SOC and form state management, we identified **one key refinement** for our existing pattern:

**Pass FormData to ViewModel (not individual parameters)**

This refinement:
- ✅ Reduces parameter count (7-8 params → 1 FormData object)
- ✅ Makes template creation cleaner
- ✅ Doesn't require architectural overhaul
- ✅ Aligns with our FormData DTO pattern

---

## Files with Inline Comments

### 1. ActionFormViewModel.swift

**Location**: Lines 143-149 (save method), Lines 203-209 (update method)

**Comment**:
```swift
/// 🔧 REFINEMENT NEEDED (2025-11-03):
/// This method takes 7 parameters - should take FormData instead:
/// ```
/// public func save(formData: ActionFormData) async throws -> Action
/// ```
/// View should call buildFormData() helper before passing here.
/// Pattern to follow: PersonalValueFormViewModel (when updated)
```

**Why**: Currently takes 7 individual parameters. Should take ActionFormData instead.

---

### 2. ActionFormView.swift

**Location**: Lines 217-249 (handleSubmit method)

**Comment**:
```swift
/// 🔧 REFINEMENT NEEDED (2025-11-03):
/// Should extract buildFormData() helper to reduce code duplication:
/// ```swift
/// private func buildFormData() -> ActionFormData {
///     let measurementInputs = measurements.compactMap { m in
///         guard let measureId = m.measureId, m.value > 0 else { return nil }
///         return MeasurementInput(measureId: measureId, value: m.value)
///     }
///     return ActionFormData(
///         title: title,
///         detailedDescription: detailedDescription,
///         freeformNotes: freeformNotes,
///         durationMinutes: durationMinutes,
///         startTime: startTime,
///         measurements: measurementInputs,
///         goalContributions: selectedGoalIds
///     )
/// }
///
/// private func handleSubmit() {
///     Task {
///         let formData = buildFormData()
///         if let action = actionToEdit {
///             try await viewModel.update(actionDetails: action, formData: formData)
///         } else {
///             try await viewModel.save(formData: formData)
///         }
///         dismiss()
///     }
/// }
/// ```
/// Pattern to establish: PersonalValuesFormView (when updated)
```

**Why**: Shows clean pattern with buildFormData() helper. Reduces duplication.

---

### 3. PersonalValueCoordinator.swift

**Location**: Lines 74-128 (TODO section)

**Comment**:
```swift
// TODO: Add Update and Delete (Next Task)
//
// 🎯 PATTERN TO FOLLOW (2025-11-03):
//
// /// Updates existing PersonalValue from form data
// /// - Parameters:
// ///   - value: Existing PersonalValue to update
// ///   - formData: New form data (FormData pattern - not individual params!)
// /// - Returns: Updated PersonalValue
// /// - Throws: Database errors if constraints violated
// ///
// /// IMPLEMENTATION:
// /// 1. Use .upsert (not .insert) with existing ID
// /// 2. Preserve id and logTime from existing value
// /// 3. Return updated value
// public func update(
//     value: PersonalValue,
//     from formData: ValueFormData
// ) async throws -> PersonalValue {
//     return try await database.write { db in
//         try PersonalValue.upsert {
//             PersonalValue.Draft(
//                 id: value.id,  // Preserve ID
//                 title: formData.title,
//                 detailedDescription: formData.detailedDescription,
//                 freeformNotes: formData.freeformNotes,
//                 logTime: value.logTime,  // Preserve original logTime
//                 priority: formData.priority,
//                 valueLevel: formData.valueLevel,
//                 lifeDomain: formData.lifeDomain,
//                 alignmentGuidance: formData.alignmentGuidance
//             )
//         }
//         .returning { $0 }
//         .fetchOne(db)!
//     }
// }
//
// /// Deletes PersonalValue
// /// - Parameter value: PersonalValue to delete
// /// - Throws: Database errors if constraints violated (e.g., GoalRelevances exist)
// ///
// /// IMPLEMENTATION:
// /// 1. Simple delete (no relationships to clean up for PersonalValue)
// /// 2. Database FK constraints will prevent deletion if GoalRelevances exist
// /// 3. For more complex entities (Action, Goal), see their coordinators for cascade pattern
// public func delete(value: PersonalValue) async throws {
//     try await database.write { db in
//         try PersonalValue.delete(value).execute(db)
//     }
// }
//
// PATTERN ESTABLISHED: FormData-based methods (not parameter explosion)
// SEE: ActionCoordinator.update() for multi-model delete pattern
// SEE: TimePeriodCoordinator.update() for similar single-model pattern
```

**Why**: Complete implementation guide for update/delete methods. Shows FormData pattern.

---

### 4. PersonalValuesFormView.swift

**Location**: Lines 39-54 (before struct declaration)

**Comment**:
```swift
// 🎯 NEXT TASK (2025-11-03): Add Edit Mode Support
//
// PATTERN TO FOLLOW: ActionFormView edit mode
// CHANGES NEEDED:
// 1. Add optional parameter: let valueToEdit: PersonalValue?
// 2. Add computed: var isEditMode: Bool { valueToEdit != nil }
// 3. Add computed: var formTitle: String { isEditMode ? "Edit Value" : "New Value" }
// 4. Update init() to populate @State vars from valueToEdit if present
// 5. Add buildFormData() helper (establishes pattern for template)
// 6. Update handleSubmit() to call update or save based on mode
//
// REFINED PATTERN:
// - buildFormData() helper reduces duplication
// - ViewModel takes FormData (not 7 parameters)
// - Clean, template-ready structure
//
```

**Why**: Step-by-step guide for adding edit mode. Establishes refined pattern.

---

## The Refined Pattern

### Coordinator Methods
```swift
// ✅ Good: Takes FormData
public func create(from formData: EntityFormData) async throws -> Entity
public func update(entity: Entity, from formData: EntityFormData) async throws -> Entity
public func delete(entity: Entity) async throws

// ❌ Bad: Takes individual parameters
public func create(title: String, description: String, ...) async throws -> Entity
```

### ViewModel Methods
```swift
// ✅ Good: Takes FormData
public func save(formData: EntityFormData) async throws -> Entity
public func update(entity: Entity, formData: EntityFormData) async throws -> Entity

// ❌ Bad: Takes individual parameters (what ActionFormViewModel currently does)
public func save(title: String, description: String, ...) async throws -> Entity
```

### View Helper
```swift
// ✅ Add buildFormData() helper
private func buildFormData() -> EntityFormData {
    return EntityFormData(
        title: title,
        detailedDescription: detailedDescription,
        freeformNotes: freeformNotes,
        // ... other fields
    )
}

private func handleSubmit() {
    Task {
        let formData = buildFormData()  // Clean!
        if let entity = entityToEdit {
            try await viewModel.update(entity: entity, formData: formData)
        } else {
            try await viewModel.save(formData: formData)
        }
        dismiss()
    }
}
```

---

## Implementation Order

### Next: PersonalValue CRUD (2-3 hours)

1. **PersonalValueCoordinator**: Add update/delete methods
   - Follow pattern in inline comments
   - Takes FormData (not params)
   - Simple (no relationships to cascade)

2. **PersonalValuesFormViewModel**: Add update/delete methods
   - Takes FormData (not params)
   - Calls coordinator methods

3. **PersonalValuesFormView**: Add edit mode
   - Follow inline comment guide
   - Add buildFormData() helper
   - Clean pattern for template

### After: GoalCoordinator (1 day)

Apply same refined pattern to complex entity:
- create(from formData: GoalFormData)
- update(goal, from formData: GoalFormData)
- delete(goal, cascading relationships)

---

## Why This Works

### Architectural Soundness
- ✅ State in View is fine (Decision #1: no validation yet)
- ✅ FormData DTOs are our contract (already established)
- ✅ ViewModel handles operations (already established)
- ✅ Coordinator handles persistence (already established)

### Refinement Benefits
- ✅ Reduces parameter count (cleaner signatures)
- ✅ buildFormData() helper makes views cleaner
- ✅ Template-ready pattern
- ✅ No architectural overhaul needed

### What We Avoid
- ❌ Moving state to ViewModel (unnecessary until validation needed)
- ❌ Parameter explosion (7-8 params)
- ❌ Code duplication (buildFormData extracted)

---

## Build Status

✅ **All inline comments compile successfully**

No breaking changes introduced. Comments are pure documentation.

```bash
Build complete! (4.67s)
```

---

## Next Steps

1. ✅ Inline comments added (this document)
2. ⏳ Implement PersonalValue update/delete following comments
3. ⏳ Apply pattern to GoalCoordinator
4. ⏳ Create FormTemplate.swift showing refined pattern

---

## References

- **ActionCoordinator**: Multi-model pattern (Action + relationships)
- **TimePeriodCoordinator**: Two-model pattern (TimePeriod + GoalTerm)
- **PersonalValueCoordinator**: Single-model pattern (to be updated)

---

**Pattern established**: FormData-based methods, buildFormData() helper, clean vertical slices
