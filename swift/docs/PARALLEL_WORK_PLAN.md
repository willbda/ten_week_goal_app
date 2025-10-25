# Parallel Work Plan - Ten Week Goal App

**Date:** October 24, 2025
**Purpose:** Break down audit findings into non-conflicting parallel tasks
**Estimated Total Time:** 30-35 hours (can be reduced to 8-10 hours with 3-4 developers)

---

## Work Streams Overview

Tasks are organized into **10 independent streams** that touch different files. Multiple developers can work on these simultaneously without merge conflicts.

### Dependency Graph

```
START
  │
  ├─[Stream I: Package Update]──────────┐
  │                                      │
  ├─[Stream A: Nav Accessibility]       │
  ├─[Stream B: Form Accessibility]      │
  ├─[Stream C: Dynamic Type]            │ (wait for I)
  ├─[Stream D: LogAction Intent]        │
  ├─[Stream E: Progress Intent]         │
  ├─[Stream F: EventKit]                │
  ├─[Stream G: Model Tests]             │
  ├─[Stream H: View Tests]              │
  └─[Stream J: Color Validation]        │
                                         │
                    ALL MERGE ◄──────────┘
```

---

## Stream A: Navigation & List Accessibility (2-3 hours)
**Owner:** Developer 1
**Files:** Navigation and list views only
**No conflicts with:** All other streams

### Files to Modify:
- `Sources/App/ContentView.swift`
- `Sources/App/Views/Actions/ActionsListView.swift`
- `Sources/App/Views/Goals/GoalsListView.swift`
- `Sources/App/Views/Values/ValuesListView.swift`
- `Sources/App/Views/Terms/TermsListView.swift`

### Tasks:

#### A1. ContentView Sidebar (30 min)
```swift
// ContentView.swift (Line 170-174)
Image(systemName: section.icon)
    .accessibilityLabel(section.title)
    .accessibilityHidden(showText) // Hide if text is visible

// Line 156-177 - Full NavigationLink
NavigationLink(value: section) {
    // HStack content
}
.accessibilityElement(children: showText ? .combine : .ignore)
.accessibilityLabel(showText ? nil : section.title)
.accessibilityHint("Navigate to \(section.title)")
.accessibilityAddTraits(.isButton)
```

#### A2. ActionsListView (30 min)
```swift
// Add to each action row
.accessibilityElement(children: .combine)
.accessibilityLabel("Action: \(action.title ?? "Untitled")")
.accessibilityValue(action.measurements.map { "\($0.value) \($0.key)" }.joined(separator: ", "))
.accessibilityHint("Tap to view or edit")

// Add to empty state
EmptyStateView(...)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("No actions logged. Tap the Add button to create your first action.")
```

#### A3. GoalsListView (30 min)
```swift
// Each goal row
.accessibilityElement(children: .combine)
.accessibilityLabel("Goal: \(goal.title ?? "Untitled")")
.accessibilityValue("\(goal.measurementTarget ?? 0) \(goal.measurementUnit ?? "")")
.accessibilityHint("Tap to view details and progress")
```

#### A4. ValuesListView (30 min)
```swift
// Each value row
.accessibilityElement(children: .combine)
.accessibilityLabel("Value: \(value.commonName)")
.accessibilityValue("Priority: \(value.priority)")
.accessibilityHint("Tap to view or edit")
```

#### A5. TermsListView (30 min)
```swift
// Each term row
.accessibilityElement(children: .combine)
.accessibilityLabel("Term \(term.termNumber)")
.accessibilityValue(term.theme ?? "No theme")
.accessibilityHint("Tap to view term details")
```

---

## Stream B: Form Accessibility (2-3 hours)
**Owner:** Developer 2
**Files:** Form views only
**No conflicts with:** All other streams

### Files to Modify:
- `Sources/App/Views/Actions/ActionFormView.swift`
- `Sources/App/Views/Goals/GoalFormView.swift`
- `Sources/App/Views/Terms/TermFormView.swift`
- `Sources/App/Views/Actions/QuickAddSectionView.swift`

### Tasks:

#### B1. ActionFormView Labels (45 min)
```swift
// Line 147-149 - Name field
TextField("Name", text: $title, axis: .vertical)
    .accessibilityLabel("Action name")
    .accessibilityHint("Enter a short name for this action")

// Line 151-152 - Description field
TextField("Description", text: $detailedDescription, axis: .vertical)
    .accessibilityLabel("Action description")
    .accessibilityHint("Provide more details about this action")

// Line 207-211 - Add Measurement button
Button {
    showingAddMeasurement = true
} label: {
    Label("Add Measurement", systemImage: "plus.circle.fill")
}
.accessibilityLabel("Add measurement")
.accessibilityHint("Opens a sheet to add quantitative data like distance or repetitions")

// Line 238-261 - Goal selection buttons
Button {
    toggleGoalSelection(goal.id)
} label: {
    // HStack content
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Goal: \(goal.title ?? "Untitled")")
.accessibilityValue(selectedGoalIds.contains(goal.id) ? "Selected" : "Not selected")
.accessibilityHint("Tap to toggle selection")
```

#### B2. GoalFormView Labels (45 min)
```swift
// Title field
TextField("Goal Title", text: $title)
    .accessibilityLabel("Goal title")
    .accessibilityHint("Enter what you want to achieve")

// Measurement fields
TextField("Unit", text: $measurementUnit)
    .accessibilityLabel("Measurement unit")
    .accessibilityHint("Enter the unit of measurement, like kilometers or pages")

TextField("Target", value: $measurementTarget, format: .number)
    .accessibilityLabel("Target value")
    .accessibilityHint("Enter the numeric target for this goal")

// Date pickers
DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
    .accessibilityLabel("Goal start date")

DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
    .accessibilityLabel("Goal target date")
```

#### B3. TermFormView Labels (30 min)
```swift
// Term number field
TextField("Term Number", value: $termNumber, format: .number)
    .accessibilityLabel("Term number")
    .accessibilityHint("Enter the term sequence number")

// Theme field
TextField("Theme", text: $theme)
    .accessibilityLabel("Term theme")
    .accessibilityHint("Enter an optional theme or focus area for this term")

// Date fields
DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
    .accessibilityLabel("Term start date")
```

#### B4. QuickAddSectionView (30 min)
```swift
// Quick add input field
TextField("Quick add action...", text: $quickAddText)
    .accessibilityLabel("Quick add action")
    .accessibilityHint("Type action description and press enter to log")

// Submit button
Button("Log") {
    submitQuickAction()
}
.accessibilityLabel("Log action")
.accessibilityHint("Save the quick action")
```

---

## Stream C: Dynamic Type Migration (2 hours)
**Owner:** Developer 3
**Files:** DesignSystem.swift only
**No conflicts with:** All other streams
**Dependency:** Should wait for Stream I if changing minimum iOS version

### File to Modify:
- `Sources/App/DesignSystem.swift`

### Tasks:

#### C1. Update Typography Enum (1 hour)
```swift
// CURRENT (Line 137-176) - Delete or comment out
enum Typography {
    private static let baseTitle: CGFloat = 28
    // ... all the fixed sizes
}

// NEW - Replace with system text styles
enum Typography {
    // System text styles (automatically support Dynamic Type)
    static var largeTitle: Font { .largeTitle }
    static var title: Font { .title }
    static var title2: Font { .title2 }
    static var title3: Font { .title3 }
    static var headline: Font { .headline }
    static var subheadline: Font { .subheadline }
    static var body: Font { .body }
    static var callout: Font { .callout }
    static var footnote: Font { .footnote }
    static var caption: Font { .caption }
    static var caption2: Font { .caption2 }

    // Custom styles with Dynamic Type support
    static var sectionHeader: Font { .headline }
    static var sectionFooter: Font { .caption }
    static var formLabel: Font { .body }
    static var formValue: Font { .body.monospacedDigit() }

    // For custom scaling, use ViewModifier
    static func scaled(_ style: Font, by factor: CGFloat) -> Font {
        // This could integrate with ZoomManager if needed
        style.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
```

#### C2. Update ZoomManager Integration (30 min)
```swift
// Add to ZoomManager (Line 35-56)
@Observable
@MainActor
final class ZoomManager {
    // ... existing code ...

    /// Apply zoom on top of Dynamic Type
    func scaleFont(_ font: Font) -> Font {
        // This allows zoom to work WITH Dynamic Type
        return font
            .scaleEffect(zoomLevel)
            // Or use a custom ViewModifier
    }
}
```

#### C3. Create Migration ViewModifier (30 min)
```swift
// Add at bottom of file
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    let baseStyle: Font.TextStyle

    func body(content: Content) -> some View {
        content
            .font(.system(baseStyle))
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}

extension View {
    func dynamicType(_ style: Font.TextStyle) -> some View {
        modifier(DynamicTypeModifier(baseStyle: style))
    }
}
```

---

## Stream D: LogActionIntent (3 hours)
**Owner:** Developer 4
**Files:** New files only
**No conflicts with:** All other streams

### Files to Create:
- `Sources/BusinessLogic/Intents/LogActionIntent.swift`
- `Sources/BusinessLogic/Intents/IntentModels.swift`
- `Sources/App/Info.plist` (update)

### Tasks:

#### D1. Create Intent Models (45 min)
```swift
// IntentModels.swift
import AppIntents
import Models

struct ActionEntity: AppEntity {
    let id: UUID
    let title: String
    let measurements: [String: Double]?

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Action"
    static var defaultQuery = ActionQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct ActionQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [ActionEntity] {
        // Fetch from database
    }

    func suggestedEntities() async throws -> [ActionEntity] {
        // Return recent actions
    }
}
```

#### D2. Create LogActionIntent (1.5 hours)
```swift
// LogActionIntent.swift
import AppIntents
import Models
import Database

struct LogActionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Action"
    static var description = IntentDescription("Log a new action to track your progress")

    @Parameter(title: "Description")
    var description: String

    @Parameter(title: "Measurement Value", optionalIntent: .required)
    var measurementValue: Double?

    @Parameter(title: "Measurement Unit", optionalIntent: .required)
    var measurementUnit: String?

    @Parameter(title: "Duration in minutes", optionalIntent: .required)
    var duration: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$description)") {
            \.$measurementValue
            \.$measurementUnit
            \.$duration
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Create action
        var action = Action(title: description)

        // Add measurements if provided
        if let value = measurementValue, let unit = measurementUnit {
            action.measuresByUnit = [unit: value]
        }

        // Add duration if provided
        action.durationMinutes = duration
        action.logTime = Date()

        // Save to database
        let database = try await DatabaseManager(configuration: .file)
        try await database.save(&action)

        return .result(
            dialog: "Logged: \(description)"
        )
    }
}
```

#### D3. Register Intent in App (45 min)
```swift
// Add to TenWeekGoalApp.swift
import AppIntents

struct TenWeekGoalShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogActionIntent(),
            phrases: [
                "Log action in \(.applicationName)",
                "Log \(\.$description) in \(.applicationName)",
                "Add \(\.$description) to \(.applicationName)"
            ],
            shortTitle: "Log Action",
            systemImageName: "text.badge.plus"
        )
    }
}
```

---

## Stream E: ShowProgressIntent (2 hours)
**Owner:** Developer 5
**Files:** New files only
**No conflicts with:** All other streams

### Files to Create:
- `Sources/BusinessLogic/Intents/ShowProgressIntent.swift`

### Tasks:

#### E1. Create ShowProgressIntent (2 hours)
```swift
// ShowProgressIntent.swift
import AppIntents
import Models
import BusinessLogic

struct ShowProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Goal Progress"
    static var description = IntentDescription("View your progress on goals")

    @Parameter(title: "Goal", optionalIntent: .required)
    var goal: GoalEntity?

    @Parameter(title: "Time Period", default: .currentTerm)
    var timePeriod: TimePeriod

    enum TimePeriod: String, AppEnum {
        case today = "today"
        case thisWeek = "this_week"
        case currentTerm = "current_term"
        case allTime = "all_time"

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Time Period"
        static var caseDisplayRepresentations: [TimePeriod: DisplayRepresentation] = [
            .today: "Today",
            .thisWeek: "This Week",
            .currentTerm: "Current Term",
            .allTime: "All Time"
        ]
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Fetch progress data
        let database = try await DatabaseManager(configuration: .file)

        let progress: String
        if let goalEntity = goal {
            // Specific goal progress
            let goalModel = try await database.fetchOne(Goal.self, id: goalEntity.id)
            let relationships = try await database.fetchRelationships(forGoal: goalEntity.id)
            let aggregated = ProgressAggregator.aggregate(goal: goalModel, relationships: relationships)

            progress = """
            Goal: \(goalModel.title ?? "Untitled")
            Progress: \(aggregated.completionPercentage)%
            Completed: \(aggregated.actualValue) / \(aggregated.targetValue) \(goalModel.measurementUnit ?? "")
            """
        } else {
            // All goals summary
            let allGoals = try await database.fetchGoals()
            let activeGoals = allGoals.filter { !$0.isComplete }

            progress = """
            Active Goals: \(activeGoals.count)
            View in the app for detailed progress
            """
        }

        return .result(
            dialog: IntentDialog(progress),
            view: ProgressSnippetView(text: progress)
        )
    }
}

struct ProgressSnippetView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .padding()
    }
}
```

---

## Stream F: EventKit Integration (3 hours)
**Owner:** Developer 6
**Files:** New service file only
**No conflicts with:** All other streams

### Files to Create:
- `Sources/BusinessLogic/Services/CalendarIntegration.swift`
- Update `Sources/App/Info.plist` for calendar permissions

### Tasks:

#### F1. Create CalendarIntegration Service (2 hours)
```swift
// CalendarIntegration.swift
import EventKit
import Models

@MainActor
class CalendarIntegration: ObservableObject {
    private let store = EKEventStore()
    @Published var hasAccess = false

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToEvents()
            await MainActor.run {
                self.hasAccess = granted
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    func syncGoalDeadline(_ goal: Goal) async throws {
        guard hasAccess else {
            _ = await requestAccess()
            guard hasAccess else {
                throw CalendarError.accessDenied
            }
        }

        // Check if event already exists
        let predicate = store.predicateForEvents(
            withStart: goal.targetDate?.addingTimeInterval(-86400) ?? Date(),
            end: goal.targetDate?.addingTimeInterval(86400) ?? Date(),
            calendars: nil
        )

        let existingEvents = store.events(matching: predicate)
            .filter { $0.notes?.contains("GoalID:\(goal.id)") ?? false }

        if existingEvents.isEmpty {
            // Create new event
            let event = EKEvent(eventStore: store)
            event.title = "Goal Deadline: \(goal.title ?? "Untitled")"
            event.startDate = goal.targetDate
            event.endDate = goal.targetDate?.addingTimeInterval(3600) // 1 hour duration
            event.isAllDay = false
            event.notes = """
                Goal: \(goal.title ?? "")
                Target: \(goal.measurementTarget ?? 0) \(goal.measurementUnit ?? "")
                GoalID:\(goal.id)
                """
            event.calendar = store.defaultCalendarForNewEvents

            // Add alert 1 week before
            event.alarms = [
                EKAlarm(relativeOffset: -604800) // 7 days before
            ]

            try store.save(event, span: .thisEvent)
        }
    }

    func createWeeklyReview(for term: GoalTerm) async throws {
        guard hasAccess else {
            _ = await requestAccess()
            guard hasAccess else {
                throw CalendarError.accessDenied
            }
        }

        // Create recurring weekly review
        let event = EKEvent(eventStore: store)
        event.title = "Ten Week Goal Review"
        event.startDate = term.startDate.addingTimeInterval(604800) // First review after 1 week
        event.endDate = event.startDate.addingTimeInterval(3600) // 1 hour
        event.calendar = store.defaultCalendarForNewEvents
        event.notes = "Review progress on your ten-week goals"

        // Weekly recurrence until term end
        let recurrenceEnd = EKRecurrenceEnd(end: term.targetDate)
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            end: recurrenceEnd
        )
        event.addRecurrenceRule(recurrenceRule)

        try store.save(event, span: .futureEvents)
    }
}

enum CalendarError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access is required to sync goal deadlines"
        }
    }
}
```

#### F2. Add Info.plist Entry (30 min)
```xml
<!-- Info.plist -->
<key>NSCalendarsUsageDescription</key>
<string>Ten Week Goal uses your calendar to sync goal deadlines and create review reminders.</string>

<key>NSCalendarsFullAccessUsageDescription</key>
<string>Ten Week Goal needs full calendar access to create and update goal-related events.</string>
```

#### F3. Add UI Toggle in Settings (30 min)
```swift
// Add to a SettingsView.swift
struct SettingsView: View {
    @StateObject private var calendar = CalendarIntegration()

    var body: some View {
        Form {
            Section("Integrations") {
                Toggle("Sync with Calendar", isOn: $calendarEnabled)
                    .onChange(of: calendarEnabled) { _, enabled in
                        if enabled {
                            Task {
                                await calendar.requestAccess()
                            }
                        }
                    }

                if calendarEnabled && calendar.hasAccess {
                    Button("Sync All Goal Deadlines") {
                        Task {
                            await syncAllGoals()
                        }
                    }
                }
            }
        }
    }
}
```

---

## Stream G: Model Test Migration (2 hours)
**Owner:** Developer 7
**Files:** Test files only
**No conflicts with:** All other streams

### Files to Modify:
- `Tests/ModelTests/ActionTests.swift`
- `Tests/ModelTests/GoalTests.swift`
- `Tests/ModelTests/ValueTests.swift`
- `Tests/ModelTests/TermTests.swift`

### Example Migration:

#### G1. Migrate ActionTests (30 min)
```swift
// OLD (XCTest)
import XCTest
@testable import Models

final class ActionTests: XCTestCase {
    func testMinimalActionCreation() {
        let action = Action(title: "Morning run")
        XCTAssertEqual(action.title, "Morning run")
        XCTAssertNotNil(action.id)
    }

    func testMeasurementValidation() {
        var action = Action(title: "Run")
        action.measuresByUnit = ["km": -5.0]
        XCTAssertFalse(action.isValid())
    }
}

// NEW (Swift Testing)
import Testing
@testable import Models

@Suite("Action Model Tests")
struct ActionTests {
    @Test("Minimal action can be created with just a title")
    func minimalActionCreation() {
        let action = Action(title: "Morning run")
        #expect(action.title == "Morning run")
        #expect(action.id != nil)
    }

    @Test("Negative measurements are invalid",
          arguments: [
              ["km": -5.0],
              ["reps": -10.0],
              ["pages": -1.0]
          ])
    func invalidMeasurements(measurements: [String: Double]) {
        var action = Action(title: "Test")
        action.measuresByUnit = measurements
        #expect(!action.isValid())
    }

    @Test("Positive measurements are valid",
          arguments: [
              ["km": 5.0],
              ["reps": 10.0],
              ["pages": 25.0]
          ])
    func validMeasurements(measurements: [String: Double]) {
        var action = Action(title: "Test")
        action.measuresByUnit = measurements
        #expect(action.isValid())
    }
}
```

#### G2-G4. Similarly migrate Goal, Value, Term tests (1.5 hours)

---

## Stream H: View Test Migration (1.5 hours)
**Owner:** Developer 8
**Files:** View test files only
**No conflicts with:** All other streams

### Files to Modify:
- `Tests/ViewTests/ActionRowViewTests.swift`
- `Tests/ViewTests/GoalRowViewTests.swift`
- `Tests/ViewTests/ValueRowViewTests.swift`
- `Tests/ViewTests/TermRowViewTests.swift`

---

## Stream I: Package Platform Update (30 min)
**Owner:** Developer 9
**Files:** Package.swift only
**No conflicts with:** All other streams
**Should be done FIRST if other streams need iOS 26 APIs**

### Task:

#### I1. Update Package.swift
```swift
// Package.swift (Line 8-11)
// OLD
platforms: [
    .macOS(.v15),
    .iOS(.v18)
]

// NEW
platforms: [
    .macOS(.v26),  // macOS 26.0+
    .iOS(.v26)     // iOS 26.0+
]
```

---

## Stream J: Color Contrast Validation (1.5 hours)
**Owner:** Developer 10
**Files:** DesignSystem.swift (colors only)
**No conflicts with:** Stream C if they coordinate sections

### Tasks:

#### J1. Validate Current Colors (45 min)
Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

Test combinations:
- Red (actions) on white background
- Orange (goals) on white background
- Blue (values) on white background
- Purple (terms) on white background
- All colors on dark mode backgrounds

#### J2. Adjust Colors for WCAG AA (45 min)
```swift
// DesignSystem.swift (Line 180-191)
enum Colors {
    // CURRENT (may not meet WCAG AA)
    static let actions = Color.red.opacity(0.8)

    // UPDATED (ensure 4.5:1 contrast ratio)
    static let actions = Color(red: 0.8, green: 0.1, blue: 0.1) // Darker red
    static let goals = Color(red: 0.9, green: 0.5, blue: 0.0)   // Darker orange
    static let values = Color(red: 0.0, green: 0.4, blue: 0.8)  // Darker blue
    static let terms = Color(red: 0.5, green: 0.2, blue: 0.7)   // Darker purple

    // Add high contrast variants
    static let actionsHighContrast = Color(red: 0.6, green: 0.0, blue: 0.0)
    // ... etc
}
```

---

## Merge Strategy

### Safe Parallel Execution
All 10 streams can run simultaneously because they touch different files:

| Stream | Files Modified | Can Run With |
|--------|---------------|--------------|
| A | List views | All others |
| B | Form views | All others |
| C | DesignSystem (typography) | All except J |
| D | New Intent files | All others |
| E | New Intent files | All others |
| F | New Calendar service | All others |
| G | Model test files | All others |
| H | View test files | All others |
| I | Package.swift | All others |
| J | DesignSystem (colors) | All except C |

### Coordination Points

**Only 2 coordination points needed:**

1. **Streams C & J** both modify `DesignSystem.swift`
   - Solution: Assign different sections (C: typography, J: colors)
   - Or: Do sequentially (30 min delay)

2. **Stream I** (Package update) should complete first IF:
   - Other streams need iOS 26-specific APIs
   - Currently not required for accessibility work

### Git Branch Strategy

```bash
# Each developer creates feature branch
git checkout -b feature/stream-a-nav-accessibility
git checkout -b feature/stream-b-form-accessibility
git checkout -b feature/stream-c-dynamic-type
# ... etc

# Work independently
# No merge conflicts since different files

# When complete, merge to develop
git checkout develop
git merge feature/stream-a-nav-accessibility
git merge feature/stream-b-form-accessibility
# ... etc

# Single integration test at end
swift test
```

---

## Time Estimates

### With 1 Developer (Sequential)
- Total: 30-35 hours
- Timeline: 4-5 days

### With 3 Developers (Parallel)
- Developer 1: Streams A + D + G (7.5 hours)
- Developer 2: Streams B + E + H (6.5 hours)
- Developer 3: Streams C + F + I + J (7 hours)
- Timeline: 1 day

### With 5 Developers (Maximum Parallel)
- Developer 1: Streams A + B (5 hours)
- Developer 2: Stream C + J (3.5 hours)
- Developer 3: Streams D + E (5 hours)
- Developer 4: Stream F (3 hours)
- Developer 5: Streams G + H + I (4 hours)
- Timeline: 4-6 hours

---

## Priority Order (If Sequential)

If you must work sequentially, here's the optimal order:

1. **Stream I** - Package update (30 min) - Enables iOS 26 features
2. **Stream A** - Nav accessibility (2-3 hours) - Critical
3. **Stream B** - Form accessibility (2-3 hours) - Critical
4. **Stream C** - Dynamic Type (2 hours) - High impact
5. **Stream J** - Color validation (1.5 hours) - Quick win
6. **Stream D** - LogActionIntent (3 hours) - User-facing feature
7. **Stream E** - ProgressIntent (2 hours) - User-facing feature
8. **Stream F** - EventKit (3 hours) - Nice integration
9. **Stream G** - Model tests (2 hours) - Developer experience
10. **Stream H** - View tests (1.5 hours) - Developer experience

---

## Success Metrics

Each stream is complete when:

- [ ] Code compiles without warnings
- [ ] Existing tests still pass
- [ ] New tests added (where applicable)
- [ ] Accessibility tested with VoiceOver (Streams A & B)
- [ ] Dynamic Type tested at all sizes (Stream C)
- [ ] Siri tested with sample phrases (Streams D & E)
- [ ] Calendar events appear correctly (Stream F)
- [ ] Colors meet WCAG AA (Stream J)

---

**Generated by Claude Code on October 24, 2025**