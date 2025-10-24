# iOS Implementation Plan
**Ten Week Goal App - iOS Migration Strategy**

**Status:** Planning Phase
**Created:** October 24, 2025
**Platform:** iOS 18+ (matching current macOS 15+ target)

---

## Executive Summary

The Swift codebase is **~80% ready for iOS deployment**. The architecture's clean separation between domain logic (Models, BusinessLogic), infrastructure (Database), and presentation (App/Views) means migrating to iOS primarily involves UI layer changes, not business logic rewrites.

**What's Already Platform-Agnostic:**
- ✅ All domain models (Action, Goal, Value, Term, Relationships)
- ✅ All business logic services (MatchingService, InferenceService)
- ✅ Database layer (DatabaseManager, GRDB integration, SQLite schemas)
- ✅ Core ViewModels (ActionsViewModel, GoalsViewModel, etc.)
- ✅ Design system tokens (with zoom scaling abstraction)

**What Needs iOS Adaptation:**
- ⚠️ Navigation pattern (NavigationSplitView → iOS-appropriate navigation)
- ⚠️ Form layouts and spacing (remove fixed widths, adapt for smaller screens)
- ⚠️ Keyboard handling (on-screen keyboard, toolbar, dismissal)
- ⚠️ Platform-specific features (ZoomManager, keyboard shortcuts, AI availability)
- ⚠️ Document handling (GoalDocument → iOS Files app integration)

---

## Architecture Analysis

### Current macOS Architecture (What We're Starting From)

```
TenWeekGoalApp (SwiftUI App)
├── AppRunner/main.swift (macOS-specific: NSApplication.setActivationPolicy)
├── App/
│   ├── TenWeekGoalApp.swift (#if os(macOS) window sizing, zoom commands)
│   ├── ContentView.swift (NavigationSplitView with responsive sidebar)
│   ├── AppViewModel.swift (platform-agnostic ✅)
│   ├── DesignSystem.swift (platform-agnostic ✅)
│   ├── ZoomManager.swift (macOS-specific zoom state)
│   └── Views/
│       ├── Actions/ (platform-agnostic ViewModels ✅, Forms need adaptation ⚠️)
│       ├── Goals/ (platform-agnostic ViewModels ✅, Forms need adaptation ⚠️)
│       ├── Values/ (platform-agnostic ViewModels ✅)
│       ├── Terms/ (platform-agnostic ViewModels ✅)
│       └── Assistant/ (macOS 26.0+, may not be available on iOS yet ⚠️)
├── Models/ (100% platform-agnostic ✅)
├── BusinessLogic/ (100% platform-agnostic ✅)
└── Database/ (100% platform-agnostic ✅)
```

### Test Coverage Status
- **281 tests passing** (60 model + 37 business logic + 13 GRDB integration + 171 other)
- All tests use platform-agnostic patterns
- Can run on both macOS and iOS simulators

---

## Phase-Based Implementation Plan

### Phase 1: Navigation Architecture Decision (Week 1)
**Goal:** Choose and prototype iOS navigation pattern

#### Option A: TabView (Recommended for v1.0)
**Pros:**
- Standard iOS pattern, immediately familiar to users
- Simple implementation (1 day)
- Works perfectly with 5 sections (Actions, Goals, Values, Terms, Assistant)
- Maintains parity with macOS sidebar functionality
- Easy to implement badge counts (activityCount already stubbed)

**Cons:**
- Less visual space compared to NavigationSplitView on iPad
- Harder to implement multi-column on iPad (but can use .tabViewStyle for iPad adaptation)

**Implementation:**
```swift
// iOS/ContentView.swift
TabView(selection: $selectedSection) {
    ActionsListView()
        .tabItem {
            Label("Actions", systemImage: "text.rectangle")
        }
        .tag(Section.actions)

    GoalsListView()
        .tabItem {
            Label("Goals", systemImage: "pencil.and.scribble")
        }
        .tag(Section.goals)

    // ... values, terms, assistant
}
.tint(currentSection.accentColor) // Dynamic tint based on selection
```

#### Option B: NavigationStack with Custom Tab Bar
**Pros:**
- More design flexibility
- Can create custom animations
- Better iPad support with conditional NavigationSplitView

**Cons:**
- More implementation work (2-3 days)
- Need to manage navigation state manually
- Custom UI requires more testing

#### Option C: Adaptive Navigation (NavigationSplitView on iPad, TabView on iPhone)
**Pros:**
- Best of both worlds
- iPad users get desktop-class experience
- iPhone users get mobile-optimized UI

**Cons:**
- More code complexity
- Need to test both code paths
- Potential state sync issues between patterns

**DECISION POINT:** Recommend **Option A (TabView)** for v1.0, then enhance to Option C in v1.1

**Deliverables:**
- [ ] Create `iOS/ContentView.swift` with TabView navigation
- [ ] Test navigation state persistence across tabs
- [ ] Implement badge counts using existing activityCount() stub
- [ ] Verify keyboard shortcuts removed (⌘1-4 don't make sense on iOS)

---

### Phase 2: Form & Layout Adaptation (Week 1-2)
**Goal:** Make all forms and lists work beautifully on iPhone and iPad

#### Changes Needed Per View

**ActionFormView.swift:**
```swift
// BEFORE (macOS):
.frame(minWidth: 500, minHeight: 400)
.padding(20)

// AFTER (iOS):
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { saveAction() }
        }
    }
#else
    .frame(minWidth: 500, minHeight: 400)
    .padding(20)
#endif
```

**Key Adaptations:**
- Remove fixed `.frame(minWidth:minHeight:)` on iOS
- Use `.navigationBarTitleDisplayMode(.inline)` for forms
- Add `.toolbar` items for Save/Cancel (instead of in-form buttons)
- Let SwiftUI handle form sizing naturally
- Add `.scrollDismissesKeyboard(.interactively)` on iOS

**List Views:**
- Keep current `List` + `NavigationLink` pattern (works on both platforms)
- Add `.listStyle(.insetGrouped)` on iOS for native look
- Swipe actions already implemented (keep as-is ✅)

**Deliverables:**
- [ ] Audit all 12 form views for platform-specific adaptations
- [ ] Add `#if os(iOS)` guards around macOS-specific modifiers
- [ ] Test on iPhone SE (smallest screen), iPhone 16 Pro Max, iPad Pro
- [ ] Verify all text fields are accessible with on-screen keyboard
- [ ] Add `.keyboardType` hints (.numberPad for numeric fields, .decimalPad for measurements)

---

### Phase 3: Keyboard Handling (Week 2)
**Goal:** Seamless on-screen keyboard experience

#### iOS Keyboard Toolbar
```swift
// Add to each TextField/TextEditor
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
            hideKeyboard()
        }
    }
}

// Utility extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
```

#### Smart Keyboard Types
- **Action description:** `.default` (supports autocorrect)
- **Measurements:** `.decimalPad` (numbers + decimal)
- **Goal targets:** `.numberPad` (whole numbers)
- **Dates:** Use native `DatePicker` (already implemented ✅)

**Deliverables:**
- [ ] Add keyboard toolbar to all text inputs
- [ ] Set appropriate `.keyboardType` for each field
- [ ] Test keyboard doesn't obscure form fields (SwiftUI should handle automatically)
- [ ] Add `.scrollDismissesKeyboard(.interactively)` to scrollable forms

---

### Phase 4: Platform-Specific Features (Week 2-3)
**Goal:** Handle macOS-only features gracefully on iOS

#### ZoomManager Strategy

**Option A: Remove on iOS** (Simplest)
```swift
#if os(macOS)
@Observable @MainActor
class ZoomManager { /* existing code */ }
#else
// iOS: No-op version, always returns 1.0
@Observable @MainActor
class ZoomManager {
    static let shared = ZoomManager()
    let zoomLevel: Double = 1.0
    func zoomIn() {}
    func zoomOut() {}
    func resetZoom() {}
}
#endif
```
- **Pros:** Simple, no code changes needed in DesignSystem
- **Cons:** Loses accessibility feature (but iOS has system-wide text sizing)

**Option B: Map to iOS Dynamic Type**
```swift
#if os(iOS)
@Observable @MainActor
class ZoomManager {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var zoomLevel: Double {
        // Map .large, .xLarge, etc. to 0.8-1.5 multiplier
    }
}
#endif
```
- **Pros:** Respects user's system accessibility settings
- **Cons:** More complex, need to test all Dynamic Type sizes

**DECISION POINT:** Recommend **Option A** for v1.0 (iOS users use system settings)

#### Keyboard Shortcuts
```swift
// TenWeekGoalApp.swift - Remove on iOS
#if os(macOS)
.commands {
    CommandGroup(replacing: .textFormatting) {
        // Zoom commands...
    }
}
#endif

// ContentView.swift - Remove shortcuts on iOS
#if os(macOS)
.background {
    Button("Actions") { selectedSection = .actions }
        .keyboardShortcut("1", modifiers: .command)
    // ... etc
}
#endif
```

#### AI Assistant Availability
```swift
// Already has version check, just need iOS guard
#if os(macOS)
@available(macOS 26.0, *)
actor ConversationService { /* ... */ }
#endif

// For iOS: Add when Apple Intelligence ships
#if os(iOS)
// @available(iOS XX.X, *) // TBD based on Apple's release
// actor ConversationService { /* ... */ }
#endif
```

**Deliverables:**
- [ ] Choose ZoomManager strategy (A or B)
- [ ] Add `#if os(macOS)` guards around keyboard shortcuts
- [ ] Add `#if os(macOS)` guards around window management commands
- [ ] Update AI Assistant to show "Coming Soon" badge on iOS if unavailable
- [ ] Test graceful degradation on iOS 18.0 without AI features

---

### Phase 5: Document Handling (Week 3)
**Goal:** Replace macOS DocumentGroup with iOS-compatible file operations

#### Current macOS Implementation
```swift
// GoalDocument.swift (macOS)
struct GoalDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.goal]
    var goal: Goal
    // ... init, read, write
}

// TenWeekGoalApp.swift (macOS)
DocumentGroup(newDocument: GoalDocument()) { file in
    GoalDocumentView(document: file.$document)
}
```

#### iOS Strategy

**Option A: Use DocumentGroup (Limited)**
- DocumentGroup works on iOS but UX is different
- Need to handle iCloud Drive permissions
- May feel clunky for quick goal entry

**Option B: In-App + Share Sheet** (Recommended)
```swift
// Replace DocumentGroup with standard CRUD + export
struct GoalsListView: View {
    // ... existing code

    .toolbar {
        Menu {
            Button("Export as JSON") {
                shareGoal(goal)
            }
            Button("Save to Files") {
                saveGoalToFiles(goal)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

func shareGoal(_ goal: Goal) {
    let json = try? JSONEncoder().encode(goal)
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(goal.title ?? "goal").json")
    try? json?.write(to: tempURL)

    let activityVC = UIActivityViewController(
        activityItems: [tempURL],
        applicationActivities: nil
    )
    // Present activity view controller
}
```

**Option C: iCloud CloudKit Sync** (v2.0 feature)
- Full multi-device sync
- Requires backend work
- Out of scope for v1.0

**DECISION POINT:** Recommend **Option B** for v1.0

**Deliverables:**
- [ ] Remove DocumentGroup from iOS target
- [ ] Add export/import via share sheet
- [ ] Test Files app integration (save to iCloud Drive)
- [ ] Implement import from JSON file (via Files picker)

---

### Phase 6: Xcode Project Setup (Week 3)
**Goal:** Create proper iOS target in Xcode workspace

#### Project Structure
```
TenWeekGoalApp.xcworkspace
├── TenWeekGoalApp (macOS)
│   ├── Target: Ten Week Goal (macOS)
│   ├── Bundle ID: com.tenweekgoal.macos
│   └── Info.plist (macOS-specific)
├── TenWeekGoalApp (iOS)
│   ├── Target: Ten Week Goal (iOS)
│   ├── Bundle ID: com.tenweekgoal.ios
│   └── Info.plist (iOS-specific)
└── Shared/ (Package.swift targets)
    ├── Models
    ├── BusinessLogic
    ├── Database
    └── App (conditionally compiled)
```

#### Info.plist Requirements (iOS)

**Required Keys:**
```xml
<key>CFBundleDisplayName</key>
<string>Ten Week Goal</string>

<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>LaunchIcon</string>
</dict>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arm64</string>
</array>

<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<!-- If using Files app integration -->
<key>UISupportsDocumentBrowser</key>
<true/>

<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Goal Document</string>
        <key>LSHandlerRank</key>
        <string>Owner</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>com.tenweekgoal.goal</string>
        </array>
    </dict>
</array>

<!-- Privacy descriptions (if needed later) -->
<key>NSUserActivityTypes</key>
<array>
    <string>com.tenweekgoal.view-goal</string>
</array>
```

**Build Settings:**
- Deployment Target: iOS 18.0
- Swift Language Version: Swift 6
- Strict Concurrency: On
- Architectures: arm64 (iPhone/iPad)

**Deliverables:**
- [ ] Create iOS target in Xcode (File → New → Target → iOS → App)
- [ ] Configure Info.plist with required keys
- [ ] Set up proper bundle IDs (separate for macOS/iOS)
- [ ] Configure code signing and provisioning profiles
- [ ] Test build on iOS Simulator (iPhone 16, iPad Pro)
- [ ] Verify all SPM dependencies resolve for iOS target

---

### Phase 7: Database Compatibility Testing (Week 4)
**Goal:** Ensure seamless data sharing between macOS and iOS

#### Database Locations

**macOS:**
```
~/Library/Application Support/com.tenweekgoal.macos/
└── application_data.db
```

**iOS:**
```
<App Sandbox>/Library/Application Support/
└── application_data.db
```

#### Sync Strategies

**Option A: iCloud Document Storage** (Simplest)
```swift
// DatabaseConfiguration.swift
#if os(iOS)
static let defaultDatabasePath: URL = {
    let containerURL = FileManager.default
        .url(forUbiquityContainerIdentifier: nil)?
        .appendingPathComponent("Documents")

    return containerURL?.appendingPathComponent("application_data.db")
        ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("application_data.db")
}()
#endif
```
- **Pros:** Built-in iCloud sync, no extra code
- **Cons:** User must have iCloud enabled, potential conflicts

**Option B: Manual Export/Import**
```swift
// Export database via share sheet
// Import database via file picker
// User manually transfers between devices
```
- **Pros:** Simple, no iCloud dependency
- **Cons:** Manual process, no automatic sync

**Option C: CloudKit Sync** (v2.0)
- Full multi-device automatic sync
- Requires CloudKit schema design
- Complex conflict resolution
- Out of scope for v1.0

**DECISION POINT:** Recommend **Option A** for v1.0, with Option B as fallback

#### Testing Checklist
- [ ] Create database on macOS, copy to iOS simulator, verify reads
- [ ] Create database on iOS, copy to macOS, verify reads
- [ ] Test UUID consistency across platforms
- [ ] Verify JSON measurement serialization (actions) works on both
- [ ] Test enum serialization (MatchMethod, AssignmentMethod, etc.)
- [ ] Verify foreign key cascades work identically
- [ ] Test schema initialization from shared/schemas/*.sql on iOS

**Edge Cases:**
- [ ] What happens if user has different schema versions on each platform?
- [ ] How to handle migration conflicts?
- [ ] What if iCloud is disabled?

---

### Phase 8: UI/UX Polish (Week 4-5)
**Goal:** Make iOS app feel native and delightful

#### iOS-Specific Enhancements

**1. Pull-to-Refresh**
```swift
List(actions) { action in
    ActionRowView(action: action)
}
.refreshable {
    await viewModel.loadActions()
}
```

**2. Swipe Actions** (Already implemented ✅)
```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        viewModel.deleteAction(action)
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

**3. Context Menus** (Already implemented ✅)
- Keep for long-press on iOS

**4. Search**
```swift
.searchable(text: $searchText, prompt: "Search actions...")
```

**5. Haptic Feedback**
```swift
// On action completion
let haptic = UINotificationFeedbackGenerator()
haptic.notificationOccurred(.success)

// On destructive action
let haptic = UIImpactFeedbackGenerator(style: .medium)
haptic.impactOccurred()
```

**6. Empty States** (Already implemented ✅)
- Current EmptyStateView works beautifully on iOS

**Deliverables:**
- [ ] Add pull-to-refresh to all list views
- [ ] Add search bars to Actions, Goals, Values, Terms lists
- [ ] Implement haptic feedback on key actions (save, delete, complete)
- [ ] Test empty states on iPhone (smaller screen)
- [ ] Add loading indicators during async operations
- [ ] Test dynamic type sizes (Accessibility → Larger Text)

---

### Phase 9: Testing & QA (Week 5)
**Goal:** Comprehensive testing across devices and iOS versions

#### Device Matrix
- **iPhone SE (3rd gen)**: Smallest screen (4.7")
- **iPhone 16**: Standard size (6.1")
- **iPhone 16 Pro Max**: Largest phone (6.9")
- **iPad Air**: Standard tablet (10.9")
- **iPad Pro 13"**: Largest tablet

#### Test Scenarios

**Core Functionality:**
- [ ] Create, edit, delete actions (all devices)
- [ ] Create, edit, delete goals (all types: Goal, Milestone, SmartGoal)
- [ ] Create, edit, delete values (all types)
- [ ] Create, edit, delete terms
- [ ] Assign goals to terms
- [ ] View action-goal matching results
- [ ] Test inference service (batch matching)

**Platform-Specific:**
- [ ] Verify no keyboard shortcuts appear (removed ⌘1-4)
- [ ] Test on-screen keyboard doesn't obscure inputs
- [ ] Verify forms scroll with keyboard visible
- [ ] Test rotation on all devices (Portrait ↔ Landscape)
- [ ] Test split-view multitasking on iPad
- [ ] Test slide-over on iPad

**Database:**
- [ ] Create data on macOS, open on iOS (verify reads)
- [ ] Create data on iOS, open on macOS (verify reads)
- [ ] Test iCloud sync (if implemented)
- [ ] Test schema migrations

**Accessibility:**
- [ ] Test VoiceOver navigation
- [ ] Test Dynamic Type (all sizes: XS → XXXL)
- [ ] Test with Reduce Motion enabled
- [ ] Test with Increase Contrast enabled
- [ ] Verify color contrast ratios meet WCAG AA

**Performance:**
- [ ] Load 100 actions (should be instant)
- [ ] Load 50 goals (should be instant)
- [ ] Run inference on 100 actions × 50 goals (~5000 comparisons, should be <1s)
- [ ] Test memory usage (should stay under 50MB)

---

### Phase 10: Deployment Preparation (Week 6)
**Goal:** Ready for TestFlight and App Store submission

#### App Store Assets

**Screenshots Required:**
- iPhone 6.9" (Pro Max): 2 required, up to 10 total
- iPhone 6.1" (16): 2 required, up to 10 total
- iPad Pro 13": 2 required, up to 10 total

**App Preview Videos:** (Optional but recommended)
- 15-30 seconds showcasing key features
- Show action logging, goal tracking, AI assistant

**App Icon:**
- 1024×1024 PNG (no transparency, no rounded corners)
- Design should reflect goal-tracking/productivity theme

**Privacy Policy:**
- Required if collecting any user data
- Detail database storage (local only vs iCloud)
- AI assistant data usage (if using Apple Intelligence)

#### App Store Listing

**Title:** "Ten Week Goal Tracker"

**Subtitle:** "Focused goal setting and progress tracking"

**Description (Template):**
```
ACHIEVE YOUR GOALS IN 10-WEEK SPRINTS

Ten Week Goal Tracker helps you set meaningful goals, track daily actions, and see real progress over focused 10-week periods.

KEY FEATURES:

📝 Log Actions
Track what you do each day with detailed measurements and notes.

🎯 Set Goals
Create specific, measurable goals with target dates and success criteria.

💎 Define Values
Connect your goals to what truly matters with your personal values.

📅 Plan in Terms
Organize your goals into focused 10-week periods.

🤖 AI Assistant (macOS)
Reflect on your journey with an AI companion that understands your goals.

📊 Track Progress
See exactly how your daily actions contribute to your long-term goals.

PHILOSOPHY:

Based on the principle that 10 weeks is the perfect timeframe—long enough to achieve meaningful progress, short enough to maintain focus.

PRIVACY:

Your data stays on your device. Optional iCloud sync keeps your goals in sync across all your Apple devices.
```

**Keywords:**
goals, productivity, tracking, habits, motivation, planner, progress, achievement, focus, terms

**Category:**
Primary: Productivity
Secondary: Health & Fitness (if you add health-related features)

#### TestFlight Beta

**Internal Testing (Week 6):**
- [ ] Add internal testers (up to 100)
- [ ] Distribute build via TestFlight
- [ ] Collect feedback via TestFlight feedback system
- [ ] Fix critical bugs

**External Testing (Week 7):**
- [ ] Submit for Beta App Review
- [ ] Add external testers (up to 10,000)
- [ ] Create public link for beta signup
- [ ] Monitor crash reports and feedback

#### App Review Preparation

**Demo Account:**
- Pre-populate with sample data (10 actions, 5 goals, 3 values, 1 term)
- Document login credentials in App Review Information

**Review Notes:**
```
This app is a personal goal tracking system.

KEY FEATURES TO TEST:
1. Create an action: Tap Actions tab → + button
2. Create a goal: Tap Goals tab → + button
3. View action-goal matching: Create action with measurement, create goal with same unit
4. AI Assistant (macOS only): Available on macOS 26.0+, shows "Coming Soon" on iOS

NO ACCOUNT REQUIRED: All data stored locally on device.

DEMO DATA INCLUDED: Sample actions and goals pre-loaded for review.
```

**Deliverables:**
- [ ] Generate all required screenshots
- [ ] Design and export app icon (1024×1024)
- [ ] Write app store description
- [ ] Create demo account with sample data
- [ ] Submit for TestFlight internal testing
- [ ] After internal testing: Submit for App Review

---

## Risk Assessment & Mitigation

### High-Risk Items

**Risk 1: Database Corruption During iCloud Sync**
- **Probability:** Medium
- **Impact:** High (data loss)
- **Mitigation:**
  - Implement database backup before any write
  - Add conflict resolution UI
  - Provide manual export as backup
  - Test extensively with intentional conflicts

**Risk 2: AI Assistant Not Available on iOS 18**
- **Probability:** High
- **Impact:** Medium (feature parity with macOS)
- **Mitigation:**
  - Design UI to gracefully hide unavailable features
  - Show "Coming Soon" badge with explanation
  - Focus marketing on core features (works without AI)

**Risk 3: Performance Issues with Large Datasets**
- **Probability:** Low
- **Impact:** Medium (poor UX)
- **Mitigation:**
  - Current architecture uses indexed queries (fast)
  - Implement pagination if list exceeds 100 items
  - Profile with Instruments on oldest supported device (iPhone SE)

### Medium-Risk Items

**Risk 4: Form Layout Issues on Smallest iPhone**
- **Probability:** Medium
- **Impact:** Low (usability on one device size)
- **Mitigation:**
  - Test on iPhone SE simulator religiously
  - Use ScrollView for tall forms
  - Implement keyboard-aware scrolling

**Risk 5: App Store Rejection for Minimal Functionality**
- **Probability:** Low
- **Impact:** High (delayed launch)
- **Mitigation:**
  - Ensure at least 5 core features are polished
  - Provide clear value proposition in description
  - Include screenshots showing real use cases

---

## Success Metrics

### Technical Metrics
- ✅ **100% test pass rate** on iOS target (currently 281 tests on macOS)
- ✅ **Zero compiler warnings** with Swift 6 strict concurrency
- ✅ **<100ms** launch time on iPhone 16
- ✅ **<1 second** for batch inference (100 actions × 50 goals)
- ✅ **<50MB** memory usage during normal operation

### User Experience Metrics
- ✅ **All core flows completable in <3 taps** (create action, create goal)
- ✅ **VoiceOver navigation functional** for all primary features
- ✅ **Dynamic Type support** for all text (XS → XXXL)
- ✅ **4.5+ star rating** on App Store (post-launch goal)

### Business Metrics
- ✅ **1,000 downloads** in first month (realistic for niche productivity app)
- ✅ **20% 7-day retention** (users return after 1 week)
- ✅ **10% create 5+ goals** (indicates serious usage)

---

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| **Phase 1: Navigation** | 3 days | iOS ContentView with TabView |
| **Phase 2: Forms** | 5 days | All 12 forms adapted for iOS |
| **Phase 3: Keyboard** | 2 days | Keyboard toolbar, smart types |
| **Phase 4: Platform Features** | 3 days | ZoomManager, shortcuts, AI handling |
| **Phase 5: Documents** | 3 days | Share sheet export/import |
| **Phase 6: Xcode Setup** | 2 days | iOS target, Info.plist, build |
| **Phase 7: Database** | 3 days | Compatibility testing, iCloud |
| **Phase 8: Polish** | 5 days | Search, haptics, refinements |
| **Phase 9: Testing** | 5 days | Device matrix, accessibility |
| **Phase 10: Deployment** | 5 days | TestFlight, App Store prep |
| **Total** | **6 weeks** | iOS app ready for App Store |

---

## Next Steps (Immediate Actions)

1. **Create iOS Branch**
   ```bash
   git checkout -b feature/ios-implementation
   ```

2. **Create iOS Target in Xcode**
   - Open Swift Package in Xcode
   - File → New → Target → iOS → App
   - Name: "Ten Week Goal (iOS)"
   - Bundle ID: com.tenweekgoal.ios

3. **Start Phase 1**
   - Create `Sources/App/iOS/ContentView_iOS.swift`
   - Implement TabView navigation
   - Test on iPhone 16 simulator

4. **Run Tests on iOS**
   ```bash
   swift test --destination 'platform=iOS Simulator,name=iPhone 16'
   ```

5. **Document Platform Differences**
   - Create `PLATFORM_DIFFERENCES.md`
   - Track all `#if os(iOS)` guards added
   - Maintain parity checklist

---

## Questions for Human Developer

1. **Navigation Preference:** Do you prefer TabView (simpler, standard) or adaptive NavigationSplitView on iPad?

2. **Zoom Feature:** Should we remove ZoomManager on iOS, or map it to Dynamic Type support?

3. **AI Assistant:** Acceptable to show "Coming Soon" on iOS, or should we hide the tab entirely?

4. **iCloud Sync:** Priority for v1.0, or defer to v1.1?

5. **TestFlight:** Do you want to invite external beta testers, or keep it internal only?

6. **Monetization:** Free app, or in-app purchase for premium features? (Current plan assumes free)

---

## Appendix A: Code Examples

### Platform-Specific View Example
```swift
// Sources/App/Views/Shared/AdaptiveContentView.swift

import SwiftUI

public struct AdaptiveContentView: View {
    @State private var selectedSection: Section? = .actions

    public var body: some View {
        #if os(iOS)
        iOSContent
        #elseif os(macOS)
        macOSContent
        #endif
    }

    #if os(iOS)
    private var iOSContent: some View {
        TabView(selection: $selectedSection) {
            ForEach(Section.allCases) { section in
                section.view
                    .tabItem {
                        Label(section.title, systemImage: section.icon)
                    }
                    .tag(section)
            }
        }
    }
    #endif

    #if os(macOS)
    private var macOSContent: some View {
        NavigationSplitView {
            // Existing sidebar code...
        } detail: {
            // Existing detail code...
        }
    }
    #endif
}
```

### Platform-Agnostic ViewModel Pattern
```swift
// Sources/App/Views/Actions/ActionsViewModel.swift

@MainActor @Observable
public class ActionsViewModel {
    // ✅ Already platform-agnostic
    // No changes needed for iOS

    private let database: DatabaseManager
    public private(set) var actions: [Action] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?

    public func loadActions() async {
        // Works identically on macOS and iOS
    }
}
```

### Conditional Compilation Example
```swift
// Sources/App/DesignSystem.swift

public enum Spacing {
    public static func scaled(_ base: CGFloat) -> CGFloat {
        #if os(macOS)
        return base * ZoomManager.shared.zoomLevel
        #else
        // iOS: Use system Dynamic Type scaling
        return base
        #endif
    }
}
```

---

## Appendix B: Useful Resources

**Official Apple Documentation:**
- [Human Interface Guidelines - iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [SwiftUI Platform Differences](https://developer.apple.com/documentation/swiftui/bringing-your-swiftui-app-to-macos)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

**GRDB for iOS:**
- [GRDB.swift Documentation](https://github.com/groue/GRDB.swift)
- [iOS Deployment](https://github.com/groue/GRDB.swift#installation)

**Testing:**
- [XCTest on iOS](https://developer.apple.com/documentation/xctest)
- [UI Testing Best Practices](https://developer.apple.com/videos/play/wwdc2021/10220/)

---

**Document Version:** 1.0
**Last Updated:** October 24, 2025
**Maintained By:** Claude Code
