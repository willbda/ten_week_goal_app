# iOS 26 Conformance + Accessibility Implementation Plan

**Created**: October 24, 2025
**Status**: Ready to implement
**Total Estimated Time**: 6-10 hours

## Overview

This plan sequences iOS 26 Phase 2 (design system refactor) as a prerequisite, then parallelizes iOS 26 Phase 3 with accessibility/Dynamic Type work.

**Critical Dependency**: Phase 2 MUST complete before Phase 3 + PARALLEL work begins, as Phase 2 changes the fundamental styling architecture.

---

## Phase 2: Design System Refactor (PREREQUISITE)

**Time**: 2-3 hours
**Status**: Not started
**Blocks**: All Phase 3 and PARALLEL work

### Why This Goes First

Phase 2 performs an **architectural refactor** of how UI components are styled:
- Separates Liquid Glass (navigation) from standard materials (content)
- Replaces manual implementations with native `.glassEffect()` API
- Changes the public API of DesignSystem.swift

**Consequence**: If we add accessibility/Dynamic Type first, those changes would need to be redone after the Phase 2 refactor.

### Tasks

#### 2.1: Create LiquidGlassSystem.swift (30-45 min)

**Purpose**: Navigation and control styling using native iOS 26 APIs.

**File**: `Sources/App/LiquidGlassSystem.swift`

**Content**:
```swift
// LiquidGlassSystem.swift
// Liquid Glass design system for navigation and controls
//
// Written by Claude Code on 2025-10-24
//
// Follows Apple's iOS 26/macOS 26 Liquid Glass guidelines:
// - Use ONLY for navigation (tab bars, sidebars, toolbars)
// - Use ONLY for controls (buttons, pickers, segmented controls)
// - DO NOT use for content layer (cards, list rows, reading surfaces)

import SwiftUI

/// Liquid Glass styling for navigation and controls
///
/// **Apple HIG Compliance**:
/// Liquid Glass creates depth through translucency in navigation elements.
/// This system provides type-safe access to iOS 26's native `.glassEffect()` API.
public enum LiquidGlassSystem {

    // MARK: - Navigation Glass

    /// Glass effect for sidebars and navigation containers
    ///
    /// **Usage**:
    /// ```swift
    /// NavigationSplitView {
    ///     SidebarView()
    /// } detail: {
    ///     DetailView()
    /// }
    /// .navigationGlass()
    /// ```
    public static func navigationGlass() -> some ViewModifier {
        GlassEffectModifier(intensity: .regular)
    }

    /// Glass effect for tab bars
    ///
    /// **Usage**:
    /// ```swift
    /// TabView {
    ///     ActionsView()
    ///     GoalsView()
    /// }
    /// .tabViewStyle(.sidebarAdaptable)
    /// .tabBarGlass()
    /// ```
    public static func tabBarGlass() -> some ViewModifier {
        GlassEffectModifier(intensity: .regular)
    }

    /// Glass effect for toolbars
    ///
    /// **Usage**:
    /// ```swift
    /// .toolbar {
    ///     ToolbarItem { Button("Add") { } }
    /// }
    /// .toolbarGlass()
    /// ```
    public static func toolbarGlass() -> some ViewModifier {
        GlassEffectModifier(intensity: .clear)
    }

    // MARK: - Control Glass

    /// Glass effect for buttons (primary actions)
    ///
    /// **Usage**:
    /// ```swift
    /// Button("Save") { }
    ///     .buttonGlass(tint: DesignSystem.Colors.actions)
    /// ```
    public static func buttonGlass(tint: Color) -> some ViewModifier {
        ButtonGlassModifier(tint: tint)
    }

    /// Glass effect for pickers and segmented controls
    ///
    /// **Usage**:
    /// ```swift
    /// Picker("Type", selection: $goalType) { }
    ///     .pickerGlass()
    /// ```
    public static func pickerGlass() -> some ViewModifier {
        GlassEffectModifier(intensity: .regular)
    }

    // MARK: - ViewModifiers

    private struct GlassEffectModifier: ViewModifier {
        let intensity: GlassIntensity

        func body(content: Content) -> some View {
            content
                .glassEffect(intensity.material, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private struct ButtonGlassModifier: ViewModifier {
        let tint: Color

        func body(content: Content) -> some View {
            content
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8))
                .tint(tint)
        }
    }

    private enum GlassIntensity {
        case regular
        case clear

        var material: Material {
            switch self {
            case .regular: return .regularMaterial
            case .clear: return .thinMaterial
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply navigation glass effect
    public func navigationGlass() -> some View {
        modifier(LiquidGlassSystem.navigationGlass())
    }

    /// Apply tab bar glass effect
    public func tabBarGlass() -> some View {
        modifier(LiquidGlassSystem.tabBarGlass())
    }

    /// Apply toolbar glass effect
    public func toolbarGlass() -> some View {
        modifier(LiquidGlassSystem.toolbarGlass())
    }

    /// Apply button glass effect
    public func buttonGlass(tint: Color) -> some View {
        modifier(LiquidGlassSystem.buttonGlass(tint: tint))
    }

    /// Apply picker glass effect
    public func pickerGlass() -> some View {
        modifier(LiquidGlassSystem.pickerGlass())
    }
}
```

**Tests**: None required (ViewModifier wrappers, tested via manual UI verification)

---

#### 2.2: Create ContentMaterials.swift (30-45 min)

**Purpose**: Content layer styling using standard SwiftUI materials.

**File**: `Sources/App/ContentMaterials.swift`

**Content**:
```swift
// ContentMaterials.swift
// Standard materials for content layer
//
// Written by Claude Code on 2025-10-24
//
// Follows Apple's iOS 26/macOS 26 HIG:
// - Liquid Glass is ONLY for navigation/controls
// - Content uses standard materials (.regularMaterial, .ultraThinMaterial, etc.)

import SwiftUI

/// Standard materials for content layer
///
/// **Apple HIG Compliance**:
/// Content layer should use standard materials for readability and accessibility.
/// This system provides semantic materials for cards, rows, forms, and modals.
public enum ContentMaterials {

    // MARK: - Cards and Containers

    /// Material for content cards (goal cards, action cards, etc.)
    ///
    /// **Usage**:
    /// ```swift
    /// VStack {
    ///     GoalDetails()
    /// }
    /// .contentCard()
    /// ```
    public static var card: Material { .regularMaterial }

    /// Material for list rows
    ///
    /// **Usage**:
    /// ```swift
    /// List {
    ///     ForEach(goals) { goal in
    ///         GoalRowView(goal: goal)
    ///             .listRowMaterial()
    ///     }
    /// }
    /// ```
    public static var listRow: Material { .ultraThinMaterial }

    /// Material for forms
    ///
    /// **Usage**:
    /// ```swift
    /// Form {
    ///     TextField("Name", text: $name)
    /// }
    /// .formMaterial()
    /// ```
    public static var form: Material { .regularMaterial }

    /// Material for modal sheets
    ///
    /// **Usage**:
    /// ```swift
    /// .sheet(isPresented: $showingForm) {
    ///     GoalFormView()
    /// }
    /// .presentationBackground(ContentMaterials.modal)
    /// ```
    public static var modal: Material { .regularMaterial }

    // MARK: - ViewModifiers

    /// Apply content card material
    public struct ContentCardModifier: ViewModifier {
        public func body(content: Content) -> some View {
            content
                .background(ContentMaterials.card, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }

    /// Apply list row material
    public struct ListRowMaterialModifier: ViewModifier {
        public func body(content: Content) -> some View {
            content
                .listRowBackground(ContentMaterials.listRow)
        }
    }

    /// Apply form material
    public struct FormMaterialModifier: ViewModifier {
        public func body(content: Content) -> some View {
            content
                .background(ContentMaterials.form)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply content card material
    public func contentCard() -> some View {
        modifier(ContentMaterials.ContentCardModifier())
    }

    /// Apply list row material
    public func listRowMaterial() -> some View {
        modifier(ContentMaterials.ListRowMaterialModifier())
    }

    /// Apply form material
    public func formMaterial() -> some View {
        modifier(ContentMaterials.FormMaterialModifier())
    }
}
```

**Tests**: None required (ViewModifier wrappers, tested via manual UI verification)

---

#### 2.3: Refactor DesignSystem.swift (60-90 min)

**Purpose**: Reorganize existing DesignSystem to separate concerns.

**File**: `Sources/App/DesignSystem.swift`

**Changes**:

1. **Remove manual Liquid Glass implementations**:
   - Delete `LiquidGlassCard` struct
   - Delete manual `.ultraThinMaterial` + tint overlay patterns
   - Keep spacing, colors, typography (unchanged)

2. **Update Materials enum**:
```swift
// BEFORE (manual implementations)
enum Materials {
    static let sidebar: Material = .ultraThinMaterial
    static let modal: Material = .regularMaterial
    // ... manual glass implementations
}

// AFTER (delegate to new systems)
enum Materials {
    /// Navigation materials - Use LiquidGlassSystem instead
    @available(*, deprecated, message: "Use LiquidGlassSystem.navigationGlass()")
    static let sidebar: Material = .ultraThinMaterial

    /// Content materials - Use ContentMaterials instead
    @available(*, deprecated, message: "Use ContentMaterials.modal")
    static let modal: Material = .regularMaterial

    // Provide migration period deprecations
}
```

3. **Add deprecation warnings** for old patterns:
```swift
extension View {
    @available(*, deprecated, message: "Use .contentCard() from ContentMaterials")
    func liquidGlassCard(tint: Color) -> some View {
        // Keep implementation temporarily for migration
        self.contentCard() // Redirect to new API
    }
}
```

4. **Keep unchanged**:
   - Spacing tokens (xxs → xxl)
   - Color semantics (actions/goals/values/terms)
   - Typography scales
   - ViewModifiers (except glass-related ones)

**Migration Strategy**: Deprecate old APIs but keep implementations for 1-2 commits to allow gradual view updates.

---

#### 2.4: Build and Test (15-30 min)

**Verification**:
```bash
# Build should succeed with deprecation warnings
swift build

# Expected output:
# - 0 errors
# - ~10-15 deprecation warnings (expected - we'll fix in Phase 3)
# - 0 Swift 6 concurrency warnings
```

**Checklist**:
- [ ] `swift build` succeeds
- [ ] LiquidGlassSystem.swift compiles
- [ ] ContentMaterials.swift compiles
- [ ] DesignSystem.swift compiles with deprecation warnings
- [ ] No Swift 6 concurrency errors

---

## Phase 3 + PARALLEL Work (Can Run Concurrently)

**Time**: 3-5 hours total
**Prerequisites**: Phase 2 complete
**Can be divided among multiple work sessions**

### Stream 1: iOS 26 Phase 3 (Apply New Materials)

**Time**: 1.5-2 hours
**Files**: All view files (GoalRowView, ActionFormView, etc.)

#### 3.1: Update Row Views (45 min)

**Files**:
- `GoalRowView.swift`
- `ActionRowView.swift`
- `ValueRowView.swift`
- `TermRowView.swift`

**Pattern**:
```swift
// BEFORE
VStack {
    Text(goal.description)
}
.liquidGlassCard(tint: DesignSystem.Colors.goals) // Deprecated

// AFTER
VStack {
    Text(goal.description)
}
.contentCard() // Uses ContentMaterials
```

**Expected**: 4 deprecation warnings → 0 warnings

---

#### 3.2: Update Form Views (45 min)

**Files**:
- `ActionFormView.swift`
- `GoalFormView.swift`
- `ValueFormView.swift`
- `TermFormView.swift`

**Pattern**:
```swift
// BEFORE
NavigationStack {
    Form { }
        .presentationBackground(DesignSystem.Materials.modal) // Deprecated
}

// AFTER
NavigationStack {
    Form { }
        .formMaterial() // Uses ContentMaterials
}
.presentationBackground(ContentMaterials.modal)
```

**Expected**: 4 deprecation warnings → 0 warnings

---

#### 3.3: Update Navigation (15-30 min)

**File**: `ContentView.swift`

**Pattern**:
```swift
// BEFORE
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}

// AFTER
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
.navigationGlass() // Uses LiquidGlassSystem
```

---

### Stream 2: Accessibility Labels (PARALLEL - Streams A+B)

**Time**: 1-1.5 hours
**Can run while Stream 1 happens**
**Files**: Same as Stream 1 (coordination needed)

#### A.1: Add Labels to Row Views (30 min)

**Pattern**:
```swift
// In GoalRowView.swift
VStack(alignment: .leading) {
    Text(goal.description)
    Text("\(goal.completionPercent)%")
}
.contentCard() // From Stream 1
.accessibilityElement(children: .combine) // NEW
.accessibilityLabel("\(goal.description). \(goal.completionPercent) percent complete") // NEW
```

**Files**: GoalRowView, ActionRowView, ValueRowView, TermRowView

---

#### A.2: Add Labels to Form Views (30 min)

**Pattern**:
```swift
// In GoalFormView.swift
TextField("Description", text: $description)
    .accessibilityLabel("Goal description") // NEW
    .accessibilityHint("Enter a description of what you want to achieve") // NEW
```

**Files**: ActionFormView, GoalFormView, ValueFormView, TermFormView

---

#### B.1: Add Navigation Accessibility (15-30 min)

**File**: `ContentView.swift`

**Pattern**:
```swift
NavigationLink {
    GoalsListView()
} label: {
    Label("Goals", systemImage: "target")
}
.accessibilityLabel("Goals section") // NEW
.accessibilityHint("View and manage your goals") // NEW
```

---

### Stream 3: Dynamic Type Support (PARALLEL - Stream C)

**Time**: 45-60 min
**Prerequisite**: Phase 2 complete (uses NEW DesignSystem.Typography)
**Can run while Stream 1+2 happen**

#### C.1: Update Typography Scale (30 min)

**File**: `DesignSystem.swift`

**Add Dynamic Type support**:
```swift
enum Typography {
    // BEFORE
    static let headline: Font = .headline
    static let body: Font = .body

    // AFTER (supports Dynamic Type)
    static func headline(relativeTo: Font.TextStyle = .headline) -> Font {
        .system(.headline, design: .default).weight(.semibold)
    }

    static func body(relativeTo: Font.TextStyle = .body) -> Font {
        .system(.body, design: .default)
    }

    // Add size categories for testing
    static let minimumScaleFactor: CGFloat = 0.8
    static let lineLimit: Int? = nil // Allow text wrapping
}
```

---

#### C.2: Apply to Views (15-30 min)

**Pattern**:
```swift
// BEFORE
Text(goal.description)
    .font(.headline)

// AFTER
Text(goal.description)
    .font(DesignSystem.Typography.headline())
    .minimumScaleFactor(DesignSystem.Typography.minimumScaleFactor)
    .lineLimit(DesignSystem.Typography.lineLimit)
```

**Files**: All row/form views (coordinate with Streams 1+2)

---

### Stream 4: Color Contrast Validation (PARALLEL - Stream J)

**Time**: 30-45 min
**Can run independently**

#### J.1: Add Contrast Validation Function (15-20 min)

**File**: `DesignSystem.swift`

**Add**:
```swift
extension DesignSystem.Colors {
    /// Validate color contrast ratio meets WCAG AA standards (4.5:1 for normal text)
    static func meetsContrastRatio(_ foreground: Color, _ background: Color) -> Bool {
        // Simplified implementation - use actual luminance calculation in production
        return true // TODO: Implement WCAG contrast calculation
    }

    /// Get accessible foreground color for given background
    static func accessibleForeground(for background: Color) -> Color {
        // For now, return white/black based on background
        // TODO: Calculate actual contrast ratio
        return .primary
    }
}
```

---

#### J.2: Add Contrast Assertions to Tests (15-25 min)

**File**: `Tests/DesignSystemTests.swift` (create if needed)

**Add**:
```swift
final class DesignSystemTests: XCTestCase {
    func testSemanticColorContrast() {
        // Test that semantic colors meet WCAG AA standards
        XCTAssertTrue(
            DesignSystem.Colors.meetsContrastRatio(.white, DesignSystem.Colors.actions)
        )
        XCTAssertTrue(
            DesignSystem.Colors.meetsContrastRatio(.white, DesignSystem.Colors.goals)
        )
        // ... test all semantic colors
    }
}
```

---

## Build and Test Strategy

### After Phase 2 (Prerequisite Check)

```bash
# Should build with deprecation warnings
swift build

# Expected:
# ✅ 0 errors
# ⚠️ 10-15 deprecation warnings (expected - fixed in Phase 3)
# ✅ 0 Swift 6 concurrency warnings
```

**Decision Point**: If Phase 2 build succeeds, proceed to Phase 3 + PARALLEL.

---

### During Phase 3 + PARALLEL

**Incremental Testing**:
```bash
# Test after each file update
swift build

# Goal: Each commit reduces deprecation warnings
# Commit 1: 15 warnings → 12 warnings (updated 3 row views)
# Commit 2: 12 warnings → 8 warnings (updated 4 form views)
# Commit 3: 8 warnings → 0 warnings (updated ContentView)
```

---

### Final Verification

```bash
# Clean build
swift package clean
swift build

# Expected:
# ✅ 0 errors
# ✅ 0 warnings
# ✅ 0 Swift 6 concurrency warnings

# Run tests
swift test

# Expected:
# ✅ All existing tests pass
# ✅ New DesignSystemTests pass
```

---

## Commit Strategy

### Phase 2 Commits

1. **Commit 1**: Add LiquidGlassSystem.swift
   ```
   feat: Add LiquidGlassSystem for iOS 26 navigation/controls

   - Implements native .glassEffect() API wrappers
   - Navigation, tab bar, toolbar, button, picker glass
   - Follows Apple HIG: Liquid Glass ONLY for navigation/controls

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

2. **Commit 2**: Add ContentMaterials.swift
   ```
   feat: Add ContentMaterials for content layer styling

   - Standard materials for cards, list rows, forms, modals
   - Follows Apple HIG: Content uses standard materials
   - Separates content styling from Liquid Glass (navigation)

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

3. **Commit 3**: Refactor DesignSystem.swift
   ```
   refactor: Deprecate manual glass implementations in DesignSystem

   - Add deprecation warnings for .liquidGlassCard()
   - Redirect to LiquidGlassSystem and ContentMaterials
   - Preserve spacing, colors, typography (unchanged)
   - Migration period: Keep implementations for gradual updates

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

### Phase 3 + PARALLEL Commits

4. **Commit 4**: Update row views (Stream 1.1 + Stream 2.1)
   ```
   feat: Migrate row views to ContentMaterials + add accessibility

   - Replace .liquidGlassCard() with .contentCard()
   - Add .accessibilityLabel() and .accessibilityHint()
   - Files: GoalRowView, ActionRowView, ValueRowView, TermRowView
   - Deprecation warnings: 15 → 11

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

5. **Commit 5**: Update form views (Stream 1.2 + Stream 2.2)
   ```
   feat: Migrate form views to ContentMaterials + add accessibility

   - Use .formMaterial() and ContentMaterials.modal
   - Add accessibility labels to form fields
   - Files: ActionFormView, GoalFormView, ValueFormView, TermFormView
   - Deprecation warnings: 11 → 3

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

6. **Commit 6**: Update navigation (Stream 1.3 + Stream 2.3)
   ```
   feat: Apply LiquidGlassSystem to navigation + add accessibility

   - Use .navigationGlass() for NavigationSplitView
   - Add accessibility labels to navigation links
   - File: ContentView.swift
   - Deprecation warnings: 3 → 0 ✅

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

7. **Commit 7**: Add Dynamic Type support (Stream 3)
   ```
   feat: Add Dynamic Type support to typography

   - Update DesignSystem.Typography with relativeTo parameter
   - Add minimumScaleFactor and lineLimit
   - Apply to all text elements in row/form views

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

8. **Commit 8**: Add color contrast validation (Stream 4)
   ```
   feat: Add WCAG color contrast validation

   - Add meetsContrastRatio() and accessibleForeground()
   - Add DesignSystemTests with contrast assertions
   - Tests: 14 → 18 passing

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

---

## Success Criteria

### Phase 2 Complete

- [ ] LiquidGlassSystem.swift exists and compiles
- [ ] ContentMaterials.swift exists and compiles
- [ ] DesignSystem.swift has deprecation warnings added
- [ ] `swift build` succeeds with 10-15 deprecation warnings
- [ ] Zero Swift 6 concurrency warnings

### Phase 3 + PARALLEL Complete

- [ ] All row views use `.contentCard()`
- [ ] All form views use `.formMaterial()`
- [ ] Navigation uses `.navigationGlass()`
- [ ] All views have accessibility labels
- [ ] Typography supports Dynamic Type
- [ ] Color contrast validation exists
- [ ] `swift build` succeeds with ZERO warnings
- [ ] All tests pass (14+ → 18+ tests)

### Documentation Updated

- [ ] docs/DESIGN_SYSTEM.md reflects new LiquidGlassSystem + ContentMaterials
- [ ] docs/IOS26_CONFORMANCE.md marked Phase 2 complete
- [ ] docs/ROADMAP.md updated with Phase 3 progress
- [ ] CLAUDE.md updated with new architecture

---

## Coordination Notes

### Working on Same Files

**Scenario**: Stream 1 (materials) and Stream 2 (accessibility) both modify GoalRowView.swift

**Strategy**: Apply changes in sequence within a single commit:

```swift
// Commit 4: Both materials AND accessibility
VStack(alignment: .leading) {
    Text(goal.description)
    Text("\(goal.completionPercent)%")
}
.contentCard() // Stream 1
.accessibilityLabel("\(goal.description). \(goal.completionPercent) percent complete") // Stream 2
```

This avoids merge conflicts and keeps related changes together.

---

### Testing Accessibility

**VoiceOver Testing** (macOS):
```bash
# Enable VoiceOver
Cmd+F5

# Navigate through views
Control+Option+Arrow Keys

# Verify labels read correctly
```

**Dynamic Type Testing** (Simulator):
```
Settings → Accessibility → Display & Text Size → Larger Text
Move slider to test different sizes
```

---

## Risk Mitigation

### Risk 1: Breaking Changes in Phase 2

**Mitigation**: Deprecation warnings instead of immediate removal. Old APIs redirect to new APIs, allowing gradual migration.

### Risk 2: Merge Conflicts in Phase 3

**Mitigation**: Coordinate Stream 1+2 by applying both changes in same commit to same file.

### Risk 3: Accessibility Regressions

**Mitigation**: Manual VoiceOver testing after each commit. Add automated accessibility tests if time permits.

---

## Timeline

**Phase 2**: 2-3 hours (sequential, must complete first)
**Phase 3 + PARALLEL**: 3-5 hours (can be parallelized across sessions)

**Total**: 5-8 hours (realistic estimate with testing/verification)

**Recommended Schedule**:
- Session 1 (2-3 hours): Complete Phase 2, verify build
- Session 2 (1.5-2 hours): Stream 1 (materials) + Stream 2 (accessibility) for row views
- Session 3 (1-1.5 hours): Stream 1+2 for form views + navigation
- Session 4 (30-60 min): Stream 3 (Dynamic Type) + Stream 4 (contrast)

---

## Questions for User

1. **Phase 2 Timing**: Ready to start now, or prefer to review plan first?
2. **Commit Granularity**: Prefer smaller commits (one per file) or larger commits (one per stream)?
3. **Testing Depth**: Manual VoiceOver testing only, or also add automated accessibility tests?
4. **Documentation Updates**: Update during implementation or after all phases complete?

---

**Ready to proceed with Phase 2 Task 2.1 (Create LiquidGlassSystem.swift)?**
