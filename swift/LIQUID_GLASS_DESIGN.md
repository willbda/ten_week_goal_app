# Liquid Glass Design System
**Ten Week Goal App - iOS 26 Design Language**

**Created:** October 24, 2025
**Platform:** iOS 26+ (iPhone 18 / iPad Pro M8)
**Design Philosophy:** Depth, Translucency, Fluidity

---

## Design Philosophy

**Liquid Glass** is a design language that emphasizes depth, translucency, and fluid motion. Every surface feels like frosted glass floating in 3D space, with subtle depth cues and light play creating a tactile, premium experience.

### Core Principles

1. **Depth Through Layers** - Every UI element exists on a distinct Z-plane
2. **Adaptive Translucency** - Materials respond to content and context behind them
3. **Fluid Motion** - Animations feel like liquid flowing through glass
4. **Light Play** - Subtle gradients and reflections suggest light sources
5. **Contextual Blur** - Background blur intensity adapts to content importance

---

## Visual Language

### Material Hierarchy

```swift
// Primary Materials (iOS 26+)
.ultraThinLiquid      // 2% opacity, heavy blur - floating cards
.thinLiquid           // 5% opacity, strong blur - primary surfaces
.regularLiquid        // 10% opacity, medium blur - secondary surfaces
.thickLiquid          // 20% opacity, light blur - elevated surfaces
.ultraThickLiquid     // 40% opacity, minimal blur - modal overlays
```

### Depth System

```
Z-Index Hierarchy:
├── Z-0: Background (adaptive gradient)
├── Z-1: Content wells (-2pt inset shadow)
├── Z-2: Cards (+4pt elevation shadow)
├── Z-3: Floating actions (+8pt elevation)
├── Z-4: Sheets (+16pt elevation)
└── Z-5: Alerts/Modals (+32pt elevation)
```

### Color Palette

**Adaptive Colors** (respond to light/dark mode + vibrancy):
- **Surface Tints**: Subtle color washes on glass surfaces
  - Actions: `.red.opacity(0.08)` over glass
  - Goals: `.orange.opacity(0.08)` over glass
  - Values: `.blue.opacity(0.08)` over glass
  - Terms: `.purple.opacity(0.08)` over glass
  - Assistant: `.indigo.opacity(0.08)` over glass

**Accent System**:
- Primary: Dynamic color extracted from wallpaper (iOS 26 feature)
- Secondary: Complementary color (auto-generated)
- Tertiary: Analogous color (auto-generated)

---

## Component Library

### 1. LiquidGlassCard

The fundamental building block - a translucent card with depth.

**Anatomy:**
```
┌─────────────────────────────┐
│  ╔═══════════════════════╗  │ ← Outer glow (subtle)
│  ║                       ║  │
│  ║   Content Area        ║  │ ← Glass surface
│  ║   (adaptive blur)     ║  │
│  ║                       ║  │
│  ╚═══════════════════════╝  │ ← Inner shadow (depth)
└─────────────────────────────┘
```

**Properties:**
- **Elevation**: 0-5 (controls shadow depth)
- **Blur Radius**: 10-50pt (controls glass thickness)
- **Tint Color**: Optional color wash
- **Border**: 0.5pt hairline with gradient (light edge, dark edge)
- **Corner Radius**: Continuous curve (16-32pt)

**Interactive States:**
- Idle: Standard elevation
- Hover: +2pt elevation, increased blur
- Pressed: -1pt elevation, decreased blur
- Disabled: 50% opacity, no elevation

### 2. LiquidGlassButton

Pressable glass surface with haptic feedback.

**Variants:**
- **Primary**: Thick glass with vibrant tint
- **Secondary**: Thin glass with subtle tint
- **Tertiary**: Ultra-thin glass, borderless
- **Destructive**: Red tint with warning icon

**Interaction:**
- Tap: Scale down to 0.95, reduce blur, haptic (.soft)
- Release: Spring back with fluid animation (0.4s, spring response: 0.3)

### 3. FluidTabBar

Bottom navigation with liquid morphing indicator.

**Behavior:**
- Selected tab: Thick glass bubble expands behind icon
- Transition: Bubble morphs fluidly between tabs (1.2s ease-in-out)
- Icons: SF Symbols with variable color (fill animates 0→100%)
- Badges: Small glass pills with number

**Layout:**
```
┌─────────────────────────────────────┐
│  ○     ◐     ●     ○     ○         │
│ Icon  Icon [Glass] Icon  Icon      │ ← Glass bubble follows selection
└─────────────────────────────────────┘
```

### 4. LiquidTextField

Input field with responsive glass background.

**States:**
- **Empty**: Thin glass, placeholder visible
- **Focused**: Thick glass expands, cursor appears, keyboard pushes up
- **Filled**: Regular glass, text visible
- **Error**: Red tint pulsates gently

**Features:**
- Auto-expanding height for multi-line
- Smart keyboard type detection
- Inline validation with icon
- Clear button (X) appears when filled

### 5. DepthScrollView

Scrollable container with parallax depth cues.

**Effects:**
- Background scrolls at 0.8x speed (parallax)
- Cards scroll at 1.0x speed (normal)
- Floating headers scroll at 1.2x speed (faster, creates depth)
- Blur increases at edges (top/bottom fade)

**Scroll Indicators:**
- Glass pill on right edge
- Fades in only when scrolling
- Haptic tick every 100pt scrolled

---

## Layout Patterns

### iPhone Layout

**Main Structure:**
```swift
ZStack {
    // Layer 0: Adaptive Background
    AdaptiveGradientBackground()

    // Layer 1: Content
    TabView {
        ActionsView()
            .liquidGlassContainer()

        GoalsView()
            .liquidGlassContainer()

        // ... other tabs
    }
    .fluidTabBarStyle() // Custom tab bar

    // Layer 2: Floating Quick Action
    FloatingActionButton()
        .position(x: screenWidth - 80, y: screenHeight - 120)
}
```

### iPad Layout

**Adaptive Split View:**
```swift
NavigationSplitView {
    // Sidebar: Translucent glass column
    LiquidGlassSidebar()
        .frame(width: 320)
} content: {
    // Middle column (iPad landscape only)
    ListDetailView()
        .liquidGlassContainer()
} detail: {
    // Detail view
    DetailContentView()
        .liquidGlassContainer()
}
```

---

## Animation Principles

### Timing Curves

**Standard:** `spring(response: 0.5, dampingFraction: 0.75)`
- Used for most UI transitions
- Natural, slightly bouncy feel

**Fluid:** `interpolatingSpring(mass: 1, stiffness: 100, damping: 15)`
- Used for morphing glass shapes
- Liquid-like, smooth overshoot

**Snap:** `spring(response: 0.3, dampingFraction: 0.9)`
- Used for button presses, toggles
- Quick, snappy, confident

### Keyframe Animations

**Card Appearance:**
```swift
KeyframeAnimator(initialValue: CardState.hidden) { state in
    // Card animates in
} keyframes: { _ in
    KeyframeTrack(\.opacity) {
        0.0 at 0.0
        1.0 at 0.3
    }
    KeyframeTrack(\.scale) {
        0.8 at 0.0
        1.05 at 0.3
        1.0 at 0.5
    }
    KeyframeTrack(\.blur) {
        20 at 0.0
        10 at 0.5
    }
}
```

### Transition Types

1. **Dissolve**: Fade opacity + slight scale (cards appearing/disappearing)
2. **Slide**: Horizontal/vertical with blur trail (navigation)
3. **Morph**: Shape interpolation (tab bar indicator)
4. **Ripple**: Circular expand from tap point (button press)
5. **Liquid**: Fluid deformation (drag-to-refresh)

---

## iOS 26 Exclusive Features

### 1. Live Activities - Goal Progress

**Lock Screen Widget:**
```
┌────────────────────────────────┐
│  🎯 Complete 50km running      │
│  ▓▓▓▓▓▓▓▓▓▓░░░░░░░░ 52%       │ ← Glass progress bar
│  26km / 50km  •  24km to go    │
└────────────────────────────────┘
```

**Dynamic Island (Compact):**
```
[🎯 52%] ← Minimal goal indicator
```

**Dynamic Island (Expanded):**
```
┌──────────────────────────────────┐
│  🎯 Complete 50km running        │
│  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░ 52%        │
│  26km logged  •  24km remaining  │
│  [Log Progress]  [View Details]  │
└──────────────────────────────────┘
```

### 2. Spatial Depth (for devices with LiDAR)

**Parallax Response:**
- Tilt iPhone → Glass cards shift subtly creating depth
- Accelerometer + gyroscope detect orientation
- Cards at different Z-levels move at different rates
- Subtle shadow shifts suggest 3D space

### 3. Adaptive Refresh (Always-On Display)

**On AOD:**
- Show current term progress
- Show today's action count
- Minimal animation (breathing effect on progress ring)
- Ultra-low power mode (1Hz refresh)

### 4. Wallpaper Integration

**Color Extraction:**
```swift
// iOS 26 API (speculative)
let wallpaperColors = UIScreen.main.wallpaperColors
let primary = wallpaperColors.primary
let secondary = wallpaperColors.secondary

// Apply to glass tints
LiquidGlassCard()
    .tint(primary.opacity(0.1))
```

### 5. Haptic Canvas

**Rich Haptics:**
- Custom waveforms for different interactions
- Directional haptics (left/right swipe feels different)
- Intensity adapts to scroll speed
- Success/failure patterns for goal completion

---

## Accessibility Adaptations

### Reduce Transparency

When enabled:
- Glass materials → Solid backgrounds with subtle gradients
- Maintain color relationships
- Increase contrast by 20%
- Keep all depth cues via shadows only

### Increase Contrast

- Border weights: 0.5pt → 1.5pt
- Shadow opacity: 20% → 40%
- Text on glass: Add subtle stroke/halo for legibility

### Reduce Motion

- All springs → Linear ease-in-out (0.3s)
- No parallax effects
- No morphing transitions (use cross-dissolve)
- Maintain functional animations only

### Dynamic Type

- All glass cards expand to fit larger text
- Minimum tap targets: 44×44pt (maintained at all sizes)
- Layout adapts from horizontal → vertical at larger sizes

---

## Dark Mode Adaptations

### Light Mode
- Glass: White with 10-40% opacity
- Shadows: Black at 10% opacity
- Borders: Black at 5% (top), White at 10% (bottom) - simulates light from above
- Backgrounds: Soft gradients (white → light gray)

### Dark Mode
- Glass: White with 5-20% opacity (less opaque than light mode)
- Shadows: Black at 30% opacity (stronger shadows)
- Borders: White at 15% (top), Black at 20% (bottom) - light from above
- Backgrounds: Deep gradients (near-black → dark gray)
- **Special**: Subtle color boost to prevent muddiness (saturation +10%)

---

## Performance Considerations

### Optimization Strategies

1. **Layer Limits**
   - Max 3 levels of glass layering
   - Rasterize static glass surfaces
   - Use `drawingGroup()` for complex overlays

2. **Blur Budgets**
   - Max 2 simultaneous blur effects on screen
   - Pre-render blurred backgrounds when possible
   - Use `visualEffect` modifier (iOS 26) for performant blur

3. **Animation Budgets**
   - Limit to 60fps on older devices (iPhone 16)
   - Use 120fps ProMotion for flagship devices
   - Reduce particle effects on thermal throttling

4. **Shader Usage**
   - Custom Metal shaders for glass materials (10x faster than SwiftUI blur)
   - GPU-accelerated depth shadows
   - Compiled shader cache for instant load

---

## Code Samples (Preview)

### LiquidGlassCard Component

```swift
struct LiquidGlassCard<Content: View>: View {
    let elevation: CGFloat
    let tintColor: Color?
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background {
                ZStack {
                    // Base glass
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            if let tint = tintColor {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(tint.opacity(0.08))
                            }
                        }

                    // Border gradient (light edge)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            }
            .shadow(
                color: .black.opacity(0.1),
                radius: elevation * 2,
                y: elevation
            )
    }
}
```

### FluidTabBar

```swift
struct FluidTabBar: View {
    @Binding var selection: Tab
    @Namespace private var tabIndicator

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Button {
                    withAnimation(.interpolatingSpring(mass: 1, stiffness: 100, damping: 15)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title2)
                            .symbolVariant(selection == tab ? .fill : .none)

                        Text(tab.title)
                            .font(.caption2)
                    }
                    .foregroundStyle(selection == tab ? tab.color : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(.thickMaterial)
                                .overlay {
                                    Capsule()
                                        .fill(tab.color.opacity(0.15))
                                }
                                .matchedGeometryEffect(id: "TAB", in: tabIndicator)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
```

### AdaptiveGradientBackground

```swift
struct AdaptiveGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color(white: 0.05),
                    Color(white: 0.08),
                    Color(white: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [
                    Color(white: 0.95),
                    Color(white: 0.98),
                    Color(white: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
```

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Create `LiquidGlassDesignSystem.swift`
- [ ] Implement base materials (ultraThinLiquid → ultraThickLiquid)
- [ ] Build LiquidGlassCard component
- [ ] Create AdaptiveGradientBackground
- [ ] Test performance on iPhone 16 (baseline device)

### Phase 2: Navigation (Week 1-2)
- [ ] Implement FluidTabBar
- [ ] Build tab morphing animation
- [ ] Add haptic feedback
- [ ] Test on iPad (adaptive layout)

### Phase 3: Forms (Week 2)
- [ ] Create LiquidTextField component
- [ ] Build LiquidGlassButton variants
- [ ] Implement keyboard-aware layouts
- [ ] Add inline validation UI

### Phase 4: Advanced Features (Week 3)
- [ ] Implement DepthScrollView with parallax
- [ ] Add spatial depth (LiDAR devices)
- [ ] Create Live Activity for goal progress
- [ ] Integrate Dynamic Island compact/expanded states

### Phase 5: Polish (Week 3-4)
- [ ] Custom haptic patterns
- [ ] Advanced animations (keyframe sequences)
- [ ] Accessibility adaptations
- [ ] Performance optimization (shader compilation)

### Phase 6: Testing (Week 4)
- [ ] Test on all device sizes (SE → Pro Max)
- [ ] Test with Reduce Transparency enabled
- [ ] Test with Increase Contrast enabled
- [ ] Test at all Dynamic Type sizes
- [ ] Profile with Instruments (ensure 120fps)

---

## Design Inspiration

**Influences:**
- iOS 18+ glassmorphism evolution
- macOS translucent window chrome
- visionOS depth and materials
- Automotive HUD displays (depth + clarity)
- Liquid physics simulations

**Key References:**
- Apple HIG: Materials and Translucency
- WWDC 2024: "Design for Spatial Interfaces"
- WWDC 2025: "Advanced SwiftUI Animations"
- Microsoft Fluent Design (Acrylic material)

---

## Success Metrics

**Visual Quality:**
- [ ] All glass surfaces maintain 60fps (120fps on Pro devices)
- [ ] Blur radius never exceeds 50pt (performance ceiling)
- [ ] No more than 3 simultaneous glass layers
- [ ] All tap targets ≥ 44×44pt

**User Experience:**
- [ ] Navigation feels fluid (no janky transitions)
- [ ] Haptics enhance interactions (not distract)
- [ ] Information hierarchy clear at a glance
- [ ] Works beautifully in light + dark mode

**Accessibility:**
- [ ] Reduce Transparency mode fully functional
- [ ] VoiceOver describes all interactive elements
- [ ] Dynamic Type scales correctly (XS → XXXL)
- [ ] Contrast ratios meet WCAG AAA (7:1 for text)

---

**Document Version:** 1.0
**Last Updated:** October 24, 2025
**Design Lead:** Claude Code
**Target Platform:** iOS 26.0+ / iPadOS 26.0+
