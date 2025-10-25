# Design System Guide

**Last Updated**: 2025-10-23
**Status**: ✅ Implemented and Active

## Overview

The Ten Week Goal App uses a centralized design system (`DesignSystem.swift`) to ensure visual consistency across all views. This document explains how to use and maintain the design system.

## Core Principle

**Never hard-code spacing, colors, or materials.**
Instead, use semantic tokens from `DesignSystem`.

```swift
// ❌ DON'T
.padding(16)
.background(Color.red)

// ✅ DO
.padding(DesignSystem.Spacing.md)
.background(DesignSystem.Colors.error)
```

## Design Tokens

### Spacing

Use semantic spacing constants instead of pixel values:

```swift
DesignSystem.Spacing.xxs    // 4pt  - Tiny gaps (badge padding)
DesignSystem.Spacing.xs     // 8pt  - Small gaps (row vertical spacing)
DesignSystem.Spacing.sm     // 12pt - Medium gaps (icon spacing)
DesignSystem.Spacing.md     // 16pt - Standard gaps (section padding)
DesignSystem.Spacing.lg     // 24pt - Large gaps (between major sections)
DesignSystem.Spacing.xl     // 32pt - Extra large (empty state padding)
DesignSystem.Spacing.xxl    // 48pt - Huge gaps (rare use)

// Special purpose
DesignSystem.Spacing.formPadding   // 20pt - Forms/modals
DesignSystem.Spacing.sheetPadding  // 24pt - Sheet presentations
```

**When to use each:**
- `.xxs` (4pt): Badge padding, tight inline elements
- `.xs` (8pt): List row vertical spacing, small gaps
- `.sm` (12pt): Icon-to-text spacing in HStacks
- `.md` (16pt): Default padding for sections
- `.lg` (24pt): Between major UI sections
- `.formPadding`: All Form views on macOS

### Colors

Use semantic color names that describe purpose, not appearance:

```swift
// Section colors
DesignSystem.Colors.actions  // Red - for action-related UI
DesignSystem.Colors.goals    // Orange - for goal-related UI
DesignSystem.Colors.values   // Blue - for values-related UI
DesignSystem.Colors.terms    // Purple - for terms-related UI

// State colors
DesignSystem.Colors.success  // Green - success states, active badges
DesignSystem.Colors.warning  // Orange - warnings, medium priority
DesignSystem.Colors.error    // Red - errors, high priority, overdue
DesignSystem.Colors.info     // Blue - informational, upcoming
```

**Examples:**
```swift
// Priority badge in GoalRowView
if goal.priority <= 10 {
    Text("HIGH")
        .background(DesignSystem.Colors.error)  // High priority = error color
}

// Life domain tag
Text(domain)
    .background(DesignSystem.Colors.goals.opacity(0.15))
    .foregroundStyle(DesignSystem.Colors.goals)
```

### Materials

Use semantic material constants for backgrounds:

```swift
DesignSystem.Materials.sidebar  // .ultraThinMaterial - Translucent sidebar
DesignSystem.Materials.detail   // .regularMaterial - Detail panes
DesignSystem.Materials.modal    // .regularMaterial - Modals/sheets
```

**Usage:**
```swift
// Sidebar background
List { }
    .background(DesignSystem.Materials.sidebar)

// Modal presentation
NavigationStack { }
    .presentationBackground(DesignSystem.Materials.modal)
```

### Corner Radius

```swift
DesignSystem.CornerRadius.xs    // 4pt  - Tiny elements
DesignSystem.CornerRadius.sm    // 8pt  - Small badges
DesignSystem.CornerRadius.md    // 12pt - Standard cards
DesignSystem.CornerRadius.lg    // 16pt - Large cards
DesignSystem.CornerRadius.xl    // 20pt - Sheet corners
DesignSystem.CornerRadius.round // ∞    - Perfect circles
```

### Typography

```swift
DesignSystem.Typography.sectionHeader  // .headline
DesignSystem.Typography.sectionFooter  // .caption
DesignSystem.Typography.formLabel      // .body
DesignSystem.Typography.formValue      // .body.monospacedDigit()
```

## View Modifiers

Reusable styling patterns as modifiers:

### FormSectionStyle

Clean list row styling for forms:

```swift
Section {
    TextField("Name", text: $name)
}
.formSectionStyle()  // Adds: hidden separator, clear background
```

### SheetStyle

Proper padding and materials for modal sheets:

```swift
NavigationStack {
    Form { }
}
.sheetStyle()  // Adds: modal material, padding (macOS), corner radius
```

### CardStyle

Accent-colored card backgrounds:

```swift
VStack {
    Text("Content")
}
.cardStyle(color: DesignSystem.Colors.goals)  // Orange-tinted card
```

## Reusable Components

### SectionHeader

Consistent section headers with optional icons:

```swift
// With icon
SectionHeader("Basic Info", icon: "info.circle")

// Without icon
SectionHeader("Measurements")
```

### EmptyStateView

Consistent empty state messages:

```swift
EmptyStateView(
    icon: "target",
    title: "No Goals Yet",
    message: "Set your first goal to start tracking",
    action: { showingAddGoal = true },
    actionLabel: "Add Goal"
)
```

## Common Patterns

### List Rows

All row views should use consistent spacing:

```swift
struct MyRowView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Title")
                    .font(.headline)

                Text("Subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}
```

### Form Views

All forms should have proper padding on macOS:

```swift
struct MyFormView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Info") { }
            }
            .formStyle(.grouped)
            #if os(macOS)
            .padding(DesignSystem.Spacing.formPadding)
            .frame(minWidth: 500, minHeight: 400)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .presentationBackground(DesignSystem.Materials.modal)
    }
}
```

### Status Badges

Consistent badge styling:

```swift
Text("ACTIVE")
    .font(.caption2)
    .fontWeight(.semibold)
    .padding(.horizontal, DesignSystem.Spacing.xs - 2)
    .padding(.vertical, DesignSystem.Spacing.xxs - 2)
    .background(DesignSystem.Colors.success)
    .foregroundStyle(.white)
    .clipShape(Capsule())
```

## Maintenance Guidelines

### When Adding New Views

1. **Never hard-code spacing**
   ```swift
   // ❌ DON'T
   .padding(8)

   // ✅ DO
   .padding(DesignSystem.Spacing.xs)
   ```

2. **Use semantic colors**
   ```swift
   // ❌ DON'T
   .background(Color.red)

   // ✅ DO
   .background(DesignSystem.Colors.error)
   ```

3. **Apply form padding on macOS**
   ```swift
   Form { }
       #if os(macOS)
       .padding(DesignSystem.Spacing.formPadding)
       #endif
   ```

4. **Use consistent materials**
   ```swift
   .presentationBackground(DesignSystem.Materials.modal)
   ```

### When Modifying Design

To change app-wide spacing or colors:

1. **Open `DesignSystem.swift`**
2. **Modify the token value** (e.g., `static let md: CGFloat = 20`)
3. **Build and run** - all views update automatically!

```swift
// Example: Make all medium spacing larger
enum Spacing {
    static let md: CGFloat = 20  // Changed from 16
}
// Now ALL views using .md get 20pt instead of 16pt
```

### Adding New Tokens

If you need a new spacing/color value:

1. Add it to `DesignSystem.swift`:
   ```swift
   enum Spacing {
       static let sidebarIcon: CGFloat = 44
   }
   ```

2. Use it in your views:
   ```swift
   Circle()
       .frame(width: DesignSystem.Spacing.sidebarIcon)
   ```

## Files Using Design System

**Row Views** (all consistent):
- `GoalRowView.swift` ✅
- `ActionRowView.swift` ✅
- `ValueRowView.swift` ✅
- `TermRowView.swift` ✅

**Form Views** (all have proper padding):
- `GoalFormView.swift` ✅
- `ActionFormView.swift` ✅
- `AddMeasurementSheet` (nested in ActionFormView) ✅

**Root Views**:
- `ContentView.swift` ✅ (uses spacing tokens, materials)

## Troubleshooting

### "I need padding but don't know which size"

Use this decision tree:
- Tiny gap between badge text and border? → `.xxs` (4pt)
- Vertical spacing in list rows? → `.xs` (8pt)
- Icon to text spacing? → `.sm` (12pt)
- Section padding? → `.md` (16pt)
- Form/modal padding? → `.formPadding` (20pt)
- Large visual separation? → `.lg` (24pt)

### "I need a color but don't know which semantic name"

- Is it for Actions section? → `.actions` (red)
- Is it for Goals section? → `.goals` (orange)
- Is it for Values section? → `.values` (blue)
- Is it for Terms section? → `.terms` (purple)
- Is it showing success/active? → `.success` (green)
- Is it showing an error/high priority? → `.error` (red)
- Is it informational? → `.info` (blue)

### "My modal has cramped text"

Make sure you're using:
```swift
#if os(macOS)
.padding(DesignSystem.Spacing.formPadding)
#endif
```

## Philosophy

The design system follows these principles:

1. **Semantic over literal**: Use `.error` not `.red`
2. **Consistent over custom**: Use tokens, not one-off values
3. **Maintainable over perfect**: Easy to change > perfectly custom
4. **Platform-aware**: macOS gets extra form padding, iOS doesn't

## Swift 6.2 Concurrency Patterns (WWDC 2025)

### ZoomManager Thread Safety

The `ZoomManager` singleton uses **Swift 6.2 best practices** for UI-related state:

**Pattern**: `@MainActor` class with `MainActor.assumeIsolated` reads

```swift
@MainActor
@Observable
class ZoomManager {
    var zoomLevel: CGFloat = 1.0
    func zoomIn() { /* mutations on MainActor */ }
}

// In design tokens:
private static var zoom: CGFloat {
    MainActor.assumeIsolated {
        ZoomManager.shared.zoomLevel  // Safe synchronous access
    }
}
```

**Why This Is Safe**:
1. ✅ All **writes** happen on `@MainActor` (zoom functions)
2. ✅ CGFloat **reads** are atomic (no partial reads)
3. ✅ Worst case: one frame uses stale zoom value (acceptable)
4. ✅ Alternative (making everything `async`) breaks SwiftUI's synchronous view body

**What NOT To Do**:
```swift
// ❌ NEVER use @unchecked Sendable
class ZoomManager: @unchecked Sendable {  // Disables ALL safety checks
    var zoomLevel: CGFloat  // Mutable state with no protection
}
```

**Why `@unchecked Sendable` Is Dangerous**:
- Disables compiler enforcement of thread safety
- Creates data races (concurrent reads during writes)
- No compile-time or runtime protection
- Only use for custom synchronization primitives (locks, atomics)

### Swift 6.2 Upgrade Path

**Current** (explicit annotations):
```swift
@MainActor
@Observable
class ZoomManager { }
```

**Future** (module-wide default isolation):
```swift
// In Package.swift:
swiftSettings: [.unsafeFlags(["-default-isolation", "MainActor"])]

// Then remove explicit @MainActor (inferred):
@Observable
class ZoomManager { }  // Implicitly @MainActor
```

This reduces annotation noise for SwiftUI apps where most code runs on main thread.

### When To Use Each Pattern

| Pattern | Use When | Example |
|---------|----------|---------|
| `@MainActor` class | UI state, singletons, SwiftUI models | ZoomManager, ViewModels |
| `actor` | Background work, independent tasks | DatabaseSync, ImageCache |
| `MainActor.assumeIsolated` | Synchronous access to main-actor state | Design token zoom access |
| `@unchecked Sendable` | **Almost never** - only for custom locks | OSAtomic, pthread_mutex |

### Auditing For Concurrency Issues

To find potential concurrency problems:

```bash
# Search for unsafe patterns
grep -r "@unchecked" Sources/
grep -r "nonisolated(unsafe)" Sources/

# Check for @MainActor coverage
grep -r "@Observable" Sources/ | grep -v "@MainActor"
```

**Red Flags**:
- `@Observable` without `@MainActor` (unless actor-based)
- `@unchecked Sendable` in application code
- Mutable state in non-isolated classes

### Further Reading

- [Swift 6.2 Concurrency Changes](https://www.donnywals.com/exploring-concurrency-changes-in-swift-6-2/)
- [Default Actor Isolation (SE-0466)](https://github.com/apple/swift-evolution/blob/main/proposals/0466-default-actor-isolation.md)
- [SwiftUI Views and @MainActor](https://fatbobman.com/en/posts/swiftui-views-and-mainactor/)

## Related Documentation

- `/swift/Sources/App/DesignSystem.swift` - Implementation
- `/swift/LIQUID_GLASS_NOTES.md` - Material design patterns
- `/swift/SWIFTROADMAP.md` - Project roadmap
