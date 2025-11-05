# Feature: Add Apple Health Workout Viewer to App

**Labels**: `enhancement`, `healthkit`, `multi-stage`

## Overview
Add HealthKit integration to display workout data from Apple Health with a simple date-based interface. This will enable users to view their exercise history directly in the app.

---

## Multi-Stage Implementation Plan

### Stage 1: Foundation & Setup
**Goal**: Establish HealthKit access and basic infrastructure

- [ ] Add HealthKit capability to `GoalTracker.entitlements`
- [ ] Update `Info.plist` with privacy usage descriptions
  - `NSHealthShareUsageDescription`: "We need access to your workout data to display your exercise history"
  - `NSHealthUpdateUsageDescription` (if writing data later)
- [ ] Link HealthKit framework in `Package.swift` or Xcode project
- [ ] Verify iOS-only build configuration (HealthKit unavailable on macOS)

**Deliverable**: App can request HealthKit permissions

---

### Stage 2: HealthKit Service Layer
**Goal**: Create reusable service for querying workout data

**Tasks**:
- [ ] Create `Sources/App/Services/HealthKitManager.swift`
  - Authorization request methods
  - Query workouts by date range
  - Handle permission states (authorized/denied/not determined)
  - Error handling for HealthKit unavailability
- [ ] Make service `@Observable` for SwiftUI reactivity
- [ ] Add authorization status checking

**Code Structure**:
```swift
@Observable
class HealthKitManager {
    private let healthStore = HKHealthStore()
    var authorizationStatus: HKAuthorizationStatus = .notDetermined

    func requestAuthorization() async throws
    func fetchWorkouts(for date: Date) async throws -> [HKWorkout]
}
```

**Deliverable**: Functional service that can query HealthKit

---

### Stage 3: Data Models
**Goal**: Map HealthKit data to app-friendly structures

**Tasks**:
- [ ] Create `Sources/Models/Kinds/Workout.swift`
  - Map from `HKWorkout` to simple display model
  - Properties: id (UUID), date, activityType, duration, distance, calories
  - Helper for activity type display names ("Running", "Cycling")
- [ ] Add computed properties for formatting (pace, duration string)

**Model Structure**:
```swift
struct Workout: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let activityType: HKWorkoutActivityType
    let duration: TimeInterval
    let totalDistance: Double?  // meters
    let totalEnergyBurned: Double?  // kcal

    var activityName: String
    var formattedDuration: String
    var formattedDistance: String
}
```

**Deliverable**: Clean workout model for UI consumption

---

### Stage 4: Basic UI (Simple View)
**Goal**: Display workouts for a selected date

**Tasks**:
- [ ] Create `Sources/App/Views/Workouts/WorkoutsListView.swift`
  - Date picker at top
  - List of workouts for selected date
  - Loading/empty states
  - Authorization request UI
- [ ] Create `Sources/App/Views/Workouts/WorkoutRowView.swift`
  - Display: activity icon, name, duration, distance
  - Simple card-based layout matching existing app style
- [ ] Handle HealthKit authorization flow in UI

**UI Components**:
```
┌─────────────────────────────┐
│  📅 Date Picker             │
├─────────────────────────────┤
│  🏃 Morning Run             │
│  30:42 • 5.2 km • 387 kcal  │
├─────────────────────────────┤
│  🚴 Evening Ride            │
│  1:15:22 • 25.8 km          │
└─────────────────────────────┘
```

**Deliverable**: Working view that displays workouts

---

### Stage 5: Navigation Integration
**Goal**: Wire into existing app navigation

**Tasks**:
- [ ] Add `.workouts` case to `ContentView.Section` enum
- [ ] Add icon (`"figure.run"`), title ("Workouts"), subtitle ("From Apple Health")
- [ ] Add sidebar navigation link with accent color
- [ ] Wire detail pane to `WorkoutsListView`
- [ ] Add keyboard shortcut (⌘6)
- [ ] Update README with HealthKit feature

**Integration Points**:
- `ContentView.swift` - Add section enum case
- Sidebar - Add navigation link
- Detail pane - Route to WorkoutsListView

**Deliverable**: Workouts accessible from main navigation

---

### Stage 6: Polish & Testing
**Goal**: Ensure production quality

**Tasks**:
- [ ] Test with various workout types (runs, bike rides, strength, yoga, etc.)
- [ ] Test empty states (no workouts for date, no permission granted)
- [ ] Test date selection edge cases (today, past dates, future dates)
- [ ] Add loading indicators during async queries
- [ ] Error handling for query failures
- [ ] Add SwiftUI preview support with mock data
- [ ] Test on physical iOS device with real Health data
- [ ] Verify iOS version compatibility (iOS 17+ for latest APIs)

**Test Scenarios**:
1. First launch - authorization flow
2. Permission denied - show helpful message
3. No workouts for selected date - empty state
4. Multiple workouts in one day - proper sorting
5. Long workout names - text truncation
6. Missing data (no distance/calories) - graceful handling

**Deliverable**: Polished, tested feature ready for daily use

---

## Future Enhancements (Out of Scope for Initial Implementation)

### Phase 2: Advanced Features
- Local SQLite database caching of workouts
- CloudKit sync of workout data across devices
- Workout detail view with full statistics
- Route visualization (GPS tracks on map)
- Associated samples (heart rate graphs, pace splits)

### Phase 3: Data Creation
- Workout creation/editing within app
- Manual workout entry
- Integration with workout builder API

### Phase 4: Analytics
- Weekly/monthly statistics and trends
- Personal records tracking
- Multi-day calendar view with workout heatmap
- Goal tracking integration (link workouts to goals)

---

## Technical Reference

### HealthKit Data Structure
```swift
// Available properties from HKWorkout
class HKWorkout: HKSample {
    var uuid: UUID                      // Unique identifier
    var startDate: Date                 // Workout start time
    var endDate: Date                   // Workout end time
    var duration: TimeInterval          // Actual duration (excludes pauses)
    var workoutActivityType: HKWorkoutActivityType  // .running, .cycling, etc.
    var totalDistance: HKQuantity?      // Distance in meters
    var totalEnergyBurned: HKQuantity?  // Active calories in kcal
    var totalFlightsClimbed: HKQuantity? // Stairs
    var metadata: [String: Any]?        // Additional app-specific data
    var device: HKDevice?               // Recording device (Apple Watch, iPhone)
    var sourceRevision: HKSourceRevision // App that created workout
    var workoutEvents: [HKWorkoutEvent]  // Pause/resume/lap events
    var workoutActivities: [HKWorkoutActivity] // For multisport workouts
}
```

### Common Activity Types
- `.running` - Outdoor/indoor running
- `.cycling` - Cycling/biking
- `.walking` - Walking
- `.swimming` - Pool/open water swimming
- `.yoga` - Yoga sessions
- `.functionalStrengthTraining` - Strength/resistance training
- `.hiking` - Hiking
- `.traditionalStrengthTraining` - Weight lifting
- 80+ total activity types available

### Platform Constraints
- **iOS only**: HealthKit not available on macOS
- **Real device preferred**: Simulator has limited Health data
- **Privacy**: Users can deny permission or grant partial access per data type
- **Minimum iOS version**: iOS 8+ for basic HealthKit, iOS 17+ for latest query APIs

### Query Pattern
```swift
// Query workouts for a specific date
let calendar = Calendar.current
let startOfDay = calendar.startOfDay(for: selectedDate)
let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

let predicate = HKQuery.predicateForSamples(
    withStart: startOfDay,
    end: endOfDay,
    options: [.strictStartDate]
)

let query = HKSampleQuery(
    sampleType: HKObjectType.workoutType(),
    predicate: predicate,
    limit: HKObjectQueryNoLimit,
    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
) { query, samples, error in
    // Process workouts
}
```

---

## Architecture Pattern

Follow existing app conventions:

### Service Layer
```
Sources/App/Services/
├── HealthKitManager.swift  (new - manages HealthKit access)
```

### Models
```
Sources/Models/Kinds/
├── Workout.swift  (new - workout display model)
```

### Views
```
Sources/App/Views/Workouts/  (new directory)
├── WorkoutsListView.swift   (main view)
├── WorkoutRowView.swift     (row component)
└── WorkoutsViewModel.swift  (state management - optional)
```

### Integration
- Update `ContentView.swift` with new section
- Follow existing pattern: Actions, Goals, Values, Terms, **Workouts**

---

## Resources & Documentation

### Apple Documentation
- [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [HKWorkout Reference](https://developer.apple.com/documentation/healthkit/hkworkout)
- [Reading Data from HealthKit](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [HealthKit Authorization](https://developer.apple.com/documentation/healthkit/setting-up-healthkit)
- [HIG - HealthKit](https://developer.apple.com/design/human-interface-guidelines/healthkit)

### Code Examples
- [Apple HealthKit Samples](https://developer.apple.com/documentation/healthkit/samples)
- [Creating Workout Routes](https://developer.apple.com/documentation/healthkit/creating-a-workout-route)

---

## Success Criteria

✅ **Stage 1**: App can request and receive HealthKit authorization
✅ **Stage 2**: Service successfully queries workouts from Health app
✅ **Stage 3**: Workout data properly mapped to display models
✅ **Stage 4**: UI displays workouts with date selection
✅ **Stage 5**: Feature integrated into main app navigation
✅ **Stage 6**: Feature tested and production-ready

---

## Notes for Implementation

### Systematic Approach
Build incrementally:
1. Get authorization working first
2. Query one workout successfully
3. Display that workout in UI
4. Expand to multiple workouts
5. Add date selection
6. Polish UI/UX

### Testing Strategy
- Use Simulator for development (add sample workouts via Health app)
- Test on real device with actual workout data
- Create SwiftUI previews with mock data
- Test edge cases (empty data, denied permissions)

### Privacy Considerations
- Be transparent about what data you're reading
- Only request necessary permissions (read workouts only)
- Respect user's choice to deny access
- Provide value even without HealthKit data

---

**Repository**: https://github.com/willbda/ten_week_goal_app
**Created**: 2025-10-27
