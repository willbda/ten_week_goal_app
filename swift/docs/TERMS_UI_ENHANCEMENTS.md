# Terms UI Enhancement Proposal
**Created**: 2025-11-05
**Status**: Proposal
**Author**: Claude Code

---

## Executive Summary

This document proposes semantic and UX enhancements to the Terms views based on user workflow patterns. The focus is on making the Term creation/viewing experience align with how users think about terms: as named planning periods with time boundaries.

---

## Current State Analysis

### TermFormView Issues
1. **Term number starts at 1** - Always defaults to 1, even when existing terms exist
2. **Title is low priority** - Buried in "Documentable Fields" section at bottom
3. **Form hierarchy misaligned** - User thinks "Spring Term (Mar-May)" not "Term 5 with some optional title"

### TermRowView Issues
1. **Badge emphasis** - "Term 5" badge more prominent than actual title
2. **Title fallback logic** - Shows "Term \(termNumber)" when no title, reinforcing number-first thinking
3. **Date range secondary** - Time boundaries less prominent than they should be

### TermsListView
- Works well, no major issues
- Could benefit from quick visual indicators (active/planned badges)

### Missing: Dashboard View
- No centralized view for active terms with progress tracking
- No daily health/fitness summary integration
- No "time remaining in current term" visualization

---

## Proposed Enhancements

### 1. Auto-Increment Term Number (Easy Win)

**Problem**: Creating a new term always starts with `termNumber = 1`, requiring manual adjustment.

**Solution**: Query existing terms and default to `max(termNumber) + 1`.

**Implementation**:
```swift
// In TermFormView.init()
public init(termToEdit: (timePeriod: TimePeriod, goalTerm: GoalTerm)? = nil) {
    self.termToEdit = termToEdit

    if let (timePeriod, goalTerm) = termToEdit {
        // Edit mode - use existing values
        _termNumber = State(initialValue: goalTerm.termNumber)
        // ... rest of edit mode
    } else {
        // Create mode - query for next term number
        let nextTermNumber = Self.calculateNextTermNumber()
        _termNumber = State(initialValue: nextTermNumber)
        // ... rest of create mode
    }
}

private static func calculateNextTermNumber() -> Int {
    // Query database for max(termNumber) + 1
    // Default to 1 if no terms exist
    // This should be a synchronous helper or use @Fetch
}
```

**Alternative approach** (cleaner):
- Add a helper to TermsQuery: `static func nextTermNumber(in db: Database) -> Int`
- Use in ViewModel or pass as parameter to view

**Files to modify**:
- [TermFormView.swift](swift/Sources/App/Views/FormViews/TermFormView.swift)
- [TermsQuery.swift](swift/Sources/App/Views/Queries/TermsQuery.swift) (add helper function)

---

### 2. Prioritize Title in Form (Medium Effort)

**Problem**: Title field is at the bottom in "DocumentableFields" section, but users think title-first.

**Solution**: Move title to top section, make it feel primary.

**Proposed form structure**:
```swift
Form {
    // Section 1: Core Identity (title + term number)
    Section("Term Identity") {
        TextField("Title", text: $title, prompt: "e.g., Spring Term, Focus Quarter")
            .font(.headline)  // Make it feel important

        Stepper("Term Number: \(termNumber)", value: $termNumber, in: 1...52)
            .accessibilityLabel("Term number")
    } footer: {
        Text("Give this term a memorable name")
            .font(.caption)
    }

    // Section 2: Time Boundaries
    Section("Duration") {
        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
        DatePicker("End Date", selection: $targetDate, displayedComponents: .date)
    } footer: {
        Text("\(daysRemaining) days")
            .font(.caption)
    }

    // Section 3: Theme (context/focus)
    Section("Theme") {
        TextField("Focus area for this term", text: $theme, axis: .vertical)
            .lineLimit(2...4)
    } footer: {
        Text("Optional: What's the main focus? (e.g., \"Health & Fitness\")")
            .font(.caption)
    }

    // Section 4: Additional Details (collapsed by default on macOS?)
    Section("Additional Details") {
        TextField("Description", text: $description, axis: .vertical)
            .lineLimit(3...6)

        TextField("Notes", text: $notes, axis: .vertical)
            .lineLimit(3...6)
    }

    // Section 5: Reflection (edit mode only)
    if isEditMode {
        Section("Reflection") {
            TextField("Post-term reflection", text: $reflection, axis: .vertical)
                .lineLimit(3...6)
        }

        Section("Status") {
            Picker("Status", selection: $status) {
                ForEach(TermStatus.allCases, id: \.self) { status in
                    Text(status.description).tag(status)
                }
            }
        }
    }
}
```

**User mental model**: "I'm creating 'Spring Term' from Mar 1 - May 10, focused on health"

**Files to modify**:
- [TermFormView.swift](swift/Sources/App/Views/FormViews/TermFormView.swift)

---

### 3. Enhance Row Display (Easy)

**Problem**: Badge "Term 5" more prominent than title "Spring Term".

**Solution**: Invert the hierarchy - title first, term number as secondary badge.

**Proposed TermRowView**:
```swift
public struct TermRowView: View {
    let term: GoalTerm
    let timePeriod: TimePeriod

    // Computed property for display title
    private var displayTitle: String {
        if let title = timePeriod.title, !title.isEmpty {
            return title
        } else {
            return "Term \(term.termNumber)"
        }
    }

    // Formatted date range
    private var dateRange: String {
        let start = timePeriod.startDate.formatted(date: .abbreviated, time: .omitted)
        let end = timePeriod.endDate.formatted(date: .abbreviated, time: .omitted)
        return "\(start) - \(end)"
    }

    // Days remaining (if active)
    private var daysRemainingText: String? {
        guard term.status == .active else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: timePeriod.endDate).day ?? 0
        return days > 0 ? "\(days) days left" : "Ended"
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Primary: Title
                HStack {
                    Text(displayTitle)
                        .font(.headline)

                    // Status badge (active/planned)
                    if let status = term.status {
                        BadgeView(badge: Badge(
                            text: status.description,
                            color: badgeColor(for: status)
                        ))
                    }
                }

                // Secondary: Date range
                Text(dateRange)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Tertiary: Days remaining (if active)
                if let daysText = daysRemainingText {
                    Text(daysText)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                // Quaternary: Theme (if set)
                if let theme = term.theme, !theme.isEmpty {
                    Text(theme)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Small term number badge (subtle)
            Text("T\(term.termNumber)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private func badgeColor(for status: TermStatus) -> Color {
        switch status {
        case .active: return .green
        case .planned: return .blue
        case .completed: return .gray
        case .delayed: return .orange
        case .onHold: return .yellow
        case .cancelled: return .red
        }
    }
}
```

**Visual hierarchy**:
1. **Title** (headline) + **Status badge** (green/blue)
2. **Date range** (secondary)
3. **Days remaining** (if active, blue text)
4. **Theme** (caption, truncated)
5. **Term number** (small subtle badge, far right)

**Files to modify**:
- [TermRowView.swift](swift/Sources/App/Views/RowViews/TermRowView.swift)

---

### 4. Create Active Terms Dashboard (Medium-Large Effort)

**Problem**: No centralized view showing:
- Currently active terms
- Time remaining in each
- Progress summary
- Daily health/fitness data

**Solution**: New `ActiveTermsDashboardView` as a tab or main dashboard.

**Proposed structure**:
```swift
public struct ActiveTermsDashboardView: View {
    @Fetch(wrappedValue: [], ActiveTermsQuery())
    private var activeTerms: [TermWithPeriod]

    // Today's date
    private let today = Date()

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Section 1: Active Terms Overview
                activeTermsSection

                // Section 2: Today's Health Summary (iOS only)
                #if os(iOS)
                todayHealthSection
                #endif

                // Section 3: Quick Actions
                quickActionsSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private var activeTermsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Terms")
                .font(.title2)
                .fontWeight(.bold)

            if activeTerms.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("No Active Terms", systemImage: "calendar.badge.clock")
                } description: {
                    Text("Create a term and set it to active to see progress here")
                }
            } else {
                // Active term cards
                ForEach(activeTerms) { item in
                    ActiveTermCard(term: item.term, timePeriod: item.timePeriod)
                }
            }
        }
    }

    #if os(iOS)
    private var todayHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Activity")
                .font(.title2)
                .fontWeight(.bold)

            TodayHealthSummaryCard()
        }
    }
    #endif

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                NavigationLink {
                    ActionFormView()
                } label: {
                    Label("Log Action", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                NavigationLink {
                    GoalFormView()
                } label: {
                    Label("New Goal", systemImage: "target")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Active Term Card

struct ActiveTermCard: View {
    let term: GoalTerm
    let timePeriod: TimePeriod

    // Calculate progress
    private var daysTotal: Int {
        Calendar.current.dateComponents([.day],
            from: timePeriod.startDate,
            to: timePeriod.endDate
        ).day ?? 70
    }

    private var daysElapsed: Int {
        Calendar.current.dateComponents([.day],
            from: timePeriod.startDate,
            to: Date()
        ).day ?? 0
    }

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day],
            from: Date(),
            to: timePeriod.endDate
        ).day ?? 0
    }

    private var progressPercent: Double {
        guard daysTotal > 0 else { return 0 }
        return Double(daysElapsed) / Double(daysTotal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timePeriod.title ?? "Term \(term.termNumber)")
                        .font(.headline)

                    Text("\(timePeriod.startDate.formatted(date: .abbreviated, time: .omitted)) - \(timePeriod.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Days remaining badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(daysRemaining)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)

                    Text("days left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: progressPercent)
                    .tint(.blue)

                HStack {
                    Text("Day \(daysElapsed) of \(daysTotal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(progressPercent * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
            }

            // Theme (if set)
            if let theme = term.theme, !theme.isEmpty {
                Text(theme)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Today's Health Summary Card

#if os(iOS)
struct TodayHealthSummaryCard: View {
    private let healthManager = HealthKitManager.shared

    @State private var workouts: [HealthWorkout] = []
    @State private var isLoading = false

    // TODO: Add step count, active energy, exercise minutes

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if workouts.isEmpty {
                Text("No workouts logged today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Workout summary
                ForEach(workouts) { workout in
                    HStack {
                        Image(systemName: workout.iconName)
                            .foregroundStyle(.red)

                        Text(workout.activityName)
                            .font(.subheadline)

                        Spacer()

                        Text(workout.summaryLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // TODO: Activity rings visualization
            // TODO: Step count
            // TODO: Active energy
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .task {
            await loadTodayWorkouts()
        }
    }

    private func loadTodayWorkouts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let hkWorkouts = try await healthManager.fetchWorkouts(for: Date())
            workouts = hkWorkouts.map { HealthWorkout(from: $0) }
        } catch {
            // Silently fail - dashboard should be graceful
            print("Failed to load workouts: \(error)")
        }
    }
}
#endif
```

**Query for active terms**:
```swift
// In TermsQuery.swift
public struct ActiveTermsQuery: FetchKeyRequest {
    public typealias Value = [TermWithPeriod]

    public init() {}

    public func fetch(_ db: Database) throws -> [TermWithPeriod] {
        let results = try GoalTerm.all
            .filter { $0.status.eq(.active) }
            .order { $0.termNumber.desc() }
            .join(TimePeriod.all) { $0.timePeriodId.eq($1.id) }
            .fetchAll(db)

        return results.map { (term, timePeriod) in
            TermWithPeriod(term: term, timePeriod: timePeriod)
        }
    }
}
```

**Integration**:
- Add as first tab in ContentView (before Actions)
- OR: Add as dedicated "Dashboard" tab
- OR: Replace ContentView root with this dashboard

**Files to create**:
- `swift/Sources/App/Views/Dashboard/ActiveTermsDashboardView.swift`
- `swift/Sources/App/Views/Dashboard/ActiveTermCard.swift`
- `swift/Sources/App/Views/Dashboard/TodayHealthSummaryCard.swift`

**Files to modify**:
- [TermsQuery.swift](swift/Sources/App/Views/Queries/TermsQuery.swift) (add ActiveTermsQuery)
- [ContentView.swift](swift/Sources/App/Views/ContentView.swift) (add Dashboard tab)

---

## Implementation Priority

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Auto-increment term number
2. ✅ Enhance TermRowView display hierarchy

### Phase 2: Form Improvements (2-3 hours)
3. ✅ Restructure TermFormView to prioritize title

### Phase 3: Dashboard (4-6 hours)
4. ✅ Create ActiveTermsDashboardView with term progress cards
5. ✅ Add ActiveTermsQuery
6. ✅ Integrate into ContentView

### Phase 4: Health Integration (2-4 hours)
7. ✅ Create TodayHealthSummaryCard
8. ✅ Fetch today's workouts
9. ⏳ Add activity rings visualization (future)
10. ⏳ Add steps/energy metrics (future)

---

## Design Principles

### User Mental Model
- **Primary**: "Spring Term" (named period)
- **Secondary**: "March 1 - May 10" (temporal boundaries)
- **Tertiary**: "Term 5" (sequential number)

### Visual Hierarchy
1. **Title** - Most prominent
2. **Date range** - Clear temporal context
3. **Status/Progress** - Active terms show time remaining
4. **Term number** - Subtle reference

### Information Architecture
- **Forms**: Identity → Time → Theme → Details → Reflection
- **Lists**: Title → Dates → Progress → Theme
- **Dashboard**: Active terms with progress, health summary, quick actions

---

## Open Questions

1. **Dashboard placement**: First tab, dedicated tab, or replace root?
2. **Health metrics**: Which metrics matter most (steps, active energy, rings)?
3. **Multi-term support**: Should dashboard show multiple active terms?
4. **Goal integration**: Show goals assigned to active terms on dashboard?

---

## References

- Current implementation: [TermFormView.swift](swift/Sources/App/Views/FormViews/TermFormView.swift)
- Current display: [TermRowView.swift](swift/Sources/App/Views/RowViews/TermRowView.swift)
- Data model: [Term.swift](swift/Sources/Models/Basics/Term.swift)
- Query layer: [TermsQuery.swift](swift/Sources/App/Views/Queries/TermsQuery.swift)
- Health view: [WorkoutsTestView.swift](swift/Sources/App/Views/Health/WorkoutsTestView.swift)
