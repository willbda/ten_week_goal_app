# Swift 6 Concurrency Quick Reference
**Last Updated**: 2025-11-10
**Project**: ten_week_goal_app v0.6.0+

## TL;DR - What You Need to Know

### The Rules (Don't Overthink It)

1. **ViewModels**: `@Observable` + `@MainActor` ← Manages UI state
2. **Coordinators**: `Sendable`, NO `@MainActor` ← Database I/O in background
3. **Models**: Add `Sendable` ← Data passed between actors
4. **Coordinator Storage**: Use `lazy var` with `@ObservationIgnored` in ViewModels

### The Magic ✨

Swift handles context switching automatically:
```swift
func save() async throws {
    isSaving = true           // ← Main thread (UI)
    let x = try await coord.create(...)  // ← Background (I/O)
    isSaving = false          // ← Main thread (UI)
}
```

You don't write threading code. Swift does it for you.

---

## Quick Patterns

### Pattern 1: Coordinator (Service Layer)

```swift
/// Database I/O service - runs in background
public final class ActionCoordinator: Sendable {
    private let database: any DatabaseWriter  // MUST be `let` (immutable)

    public func create(from formData: ActionFormData) async throws -> Action {
        try await database.write { db in
            // Heavy I/O work - runs on background thread automatically
        }
    }
}
```

**Checklist**:
- [ ] `Sendable` conformance
- [ ] NO `@MainActor`
- [ ] NO `ObservableObject`
- [ ] Only `private let` properties
- [ ] All methods `async throws`

---

### Pattern 2: ViewModel (UI Layer)

```swift
/// UI state manager - runs on main thread
@Observable
@MainActor
public final class ActionFormViewModel {
    var isSaving: Bool = false  // Auto-tracked by @Observable

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    private lazy var coordinator: ActionCoordinator = {
        ActionCoordinator(database: database)
    }()

    func save(from formData: ActionFormData) async throws -> Action {
        isSaving = true
        let action = try await coordinator.create(from: formData)
        isSaving = false
        return action
    }
}
```

**Checklist**:
- [ ] `@Observable` macro
- [ ] `@MainActor` annotation
- [ ] Dependencies marked `@ObservationIgnored`
- [ ] Coordinator stored as `lazy var` with `@ObservationIgnored`
- [ ] Views use `@State`, NOT `@StateObject`

---

### Pattern 3: Data Types (Models)

```swift
/// Data passed between actors must be Sendable
public struct ActionWithDetails: Identifiable, Hashable, Sendable {
    public let action: Action
    public let measurements: [MeasuredActionWithMeasure]
}
```

**Checklist**:
- [ ] `Sendable` conformance
- [ ] All properties are also `Sendable`
- [ ] Struct or immutable class

---

## When Something Breaks

### Error: "sending 'self.coordinator' risks causing data races"

**Fix**: Add `Sendable` to coordinator:
```swift
- public final class MyCoordinator {
+ public final class MyCoordinator: Sendable {
```

**Why**: Coordinators cross actor boundaries (from `@MainActor` ViewModels to background).

---

### Error: "property 'coordinator' is not concurrency-safe"

**Fix**: Mark coordinator with `@ObservationIgnored`:
```swift
@ObservationIgnored
private lazy var coordinator: MyCoordinator = { ... }()
```

**Why**: `@Observable` macro conflicts with `lazy var` storage.

---

### Error: "cannot convert value of type '@MainActor' to expected argument type"

**Fix**: Remove `@MainActor` from coordinators:
```swift
- @MainActor
- public final class MyCoordinator: Sendable {
+ public final class MyCoordinator: Sendable {
```

**Why**: Coordinators should run database I/O in background, not on main thread.

---

## Research References

### If You Forget This...

**1. Why do coordinators need Sendable?**
- Read: Swift Language Guide → Concurrency → Sendable Types (lines 1449-1593)
- File: `/Users/davidwilliams/Coding/REFERENCE/documents/SwiftLanguage/02-LanguageGuide/18-Concurrency.md`

**2. When to use @MainActor?**
- Read: Swift Language Guide → Concurrency → The Main Actor (lines 987-1163)
- Same file as above

**3. How does @Observable work?**
- Use: `cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py search "Observable macro"`
- Fetch: `python doc_fetcher.py fetch "https://developer.apple.com/documentation/observation"`

**4. Why lazy var with @ObservationIgnored?**
- Read: Project docs → `swift/docs/CONCURRENCY_MIGRATION_20251110.md`
- Pattern: Avoids @Observable macro conflict with lazy storage

---

## Migration Checklist (For New Code)

When you create a new coordinator or ViewModel:

### New Coordinator
```bash
- [ ] Mark `Sendable`
- [ ] NO `@MainActor`
- [ ] NO `ObservableObject`
- [ ] Only `private let` properties
- [ ] Add doc comment explaining Sendable safety
```

### New ViewModel
```bash
- [ ] Mark `@Observable`
- [ ] Mark `@MainActor`
- [ ] Dependencies with `@ObservationIgnored`
- [ ] Coordinator as `lazy var` with `@ObservationIgnored`
- [ ] Views use `@State` (NOT `@StateObject`)
```

### New Model (Data Type)
```bash
- [ ] Mark `Sendable` if passed between actors
- [ ] Use struct or immutable class
- [ ] All properties are also Sendable
```

---

## Don't Panic! 🎯

If you see concurrency errors:
1. **Check Sendable**: Do coordinators have `: Sendable`?
2. **Check @MainActor**: Are coordinators missing `@MainActor`? (They should be!)
3. **Check @ObservationIgnored**: Is lazy coordinator marked?
4. **Read the error**: Swift 6 errors are verbose but helpful

99% of issues are missing `Sendable` or wrong `@MainActor` placement.

---

## Examples in Codebase

**Best Coordinator**: `swift/Sources/Services/Coordinators/PersonalValueCoordinator.swift`
- Simplest example with full documentation

**Best ViewModel**: `swift/Sources/App/ViewModels/FormViewModels/ActionFormViewModel.swift`
- Complete example with lazy coordinator pattern

**Complete Migration History**: `swift/docs/CONCURRENCY_MIGRATION_20251110.md`
- Full before/after, explains every decision

---

## The End Goal 🎉

With these patterns:
- ✅ Database I/O never blocks UI
- ✅ Automatic context switching (main → background → main)
- ✅ Type-safe actor isolation
- ✅ Compile-time concurrency checking
- ✅ Zero manual thread management
- ✅ Professional-grade concurrency

You write simple async/await code. Swift handles all the threading complexity.
