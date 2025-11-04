# FormScaffold Anti-Pattern

**Date**: 2025-11-03
**Issue**: FormScaffold breaks SwiftUI navigation hierarchy
**Status**: FIXED in GoalFormView

## The Problem

### What We Did Wrong

```swift
// FormScaffold.swift (ANTI-PATTERN):
public var body: some View {
    VStack(spacing: 0) {  // ← THIS BREAKS NAVIGATION!
        validationBannerView
        formContent  // Contains .navigationTitle, .toolbar
    }
}

// Usage (BROKEN):
NavigationStack {
    FormScaffold { ... }  // Returns VStack, breaks hierarchy
}
```

### Why It Failed

SwiftUI's navigation modifiers (`.navigationTitle`, `.toolbar`) must be **direct children** of NavigationStack. The VStack wrapper intercepted the hierarchy:

```
NavigationStack
  └─ VStack  ← Navigation context STOPS here!
      └─ Form with .navigationTitle  ← Can't reach NavigationStack!
```

## The Solution

### Proper SwiftUI Pattern

Forms should apply navigation modifiers **directly**:

```swift
// GoalFormView.swift (CORRECT):
public var body: some View {
    Form {
        // Sections with content
        DocumentableFields(...)
        Section("Priority") { ... }
        Section("Timeline") { ... }
    }
    .navigationTitle(formTitle)  // ← Direct modifier!
    .toolbar {                    // ← Direct modifier!
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { handleSubmit() }
                .disabled(!canSubmit)
        }
    }
}

// Parent provides NavigationStack:
.sheet(isPresented: $showingAddGoal) {
    NavigationStack {  // ← Parent wraps the form
        GoalFormView()
    }
}
```

## Key Principles from Apple Docs

Based on research from https://developer.apple.com/documentation/swiftui:

1. **Forms are views, not templates** - Each form describes itself directly
2. **Parent controls navigation** - ListView decides if form needs NavigationStack
3. **Modifiers apply directly** - No wrapper components intercepting hierarchy
4. **Composition over abstraction** - Share components (DocumentableFields), not scaffolds

## What SwiftUI Wants

- ✅ Direct view hierarchy
- ✅ Minimal abstraction layers
- ✅ Clear modifier chain
- ✅ Composition of small components
- ❌ Template wrappers that intercept modifiers
- ❌ VStack around navigation content
- ❌ Over-abstraction of patterns

## Migration

### Before (FormScaffold)
```swift
FormScaffold(
    title: formTitle,
    canSubmit: !title.isEmpty,
    onSubmit: handleSubmit,
    onCancel: { dismiss() }
) {
    // Form content
}
```

### After (Direct Form)
```swift
Form {
    // Form content
}
.navigationTitle(formTitle)
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
    }
    ToolbarItem(placement: .confirmationAction) {
        Button("Save") { handleSubmit() }
            .disabled(!canSubmit)
    }
}
```

## Benefits of Proper Pattern

1. **Navigation works** - Modifiers reach NavigationStack
2. **Platform-appropriate** - SwiftUI handles iOS/macOS differences
3. **Follows conventions** - Matches Apple documentation examples
4. **Less abstraction** - Simpler mental model
5. **Better debugging** - Clear view hierarchy in Xcode

## Lesson Learned

**Don't fight SwiftUI's declarative nature.** Wrapper abstractions that try to "simplify" forms often break the framework's design. Small, composable components (like `DocumentableFields`) are fine. Large templates that intercept the view hierarchy are anti-patterns.

## Files Fixed

- ✅ GoalFormView.swift - Refactored to use direct modifiers (2025-11-03)

## Files Still Using FormScaffold

- ⚠️ TermFormView.swift - TODO: Refactor to direct modifiers
- ⚠️ ActionFormView.swift - TODO: Refactor to direct modifiers
- ⚠️ PersonalValuesFormView.swift - TODO: Refactor to direct modifiers

**Next Steps**: Refactor remaining forms to follow the proper SwiftUI pattern.
