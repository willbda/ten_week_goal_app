# HealthKit Live Tracking Implementation
**Created**: 2025-11-08
**Author**: Claude Code
**Status**: ✅ Service + ViewModel Complete, UI Test View Ready

---

## Overview

Implementation of real-time HealthKit monitoring using Apple's `HKAnchoredObjectQuery` with `updateHandler` for continuous metric tracking.

### What Was Built

1. **HealthKitLiveTrackingService** - Infrastructure layer for live HealthKit queries
2. **HealthDashboardViewModel** - @Observable ViewModel following app patterns
3. **HealthDashboardTestView** - Minimal test UI to verify integration

---

## Architecture

### File Locations

```
swift/Sources/
├── Services/
│   └── HealthKitLiveTrackingService.swift       # NEW - Live tracking service
├── App/
│   ├── ViewModels/
│   │   └── HealthDashboardViewModel.swift       # NEW - Dashboard ViewModel
│   └── Views/
│       └── Health/
│           └── HealthDashboardTestView.swift    # NEW - Test UI
```

### Design Decisions

| Decision | Rationale | Apple Doc Reference |
|----------|-----------|---------------------|
| Use `HKAnchoredObjectQuery` | Apple's recommended approach for continuous monitoring | [HKAnchoredObjectQuery](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery) |
| Use `updateHandler` property | Enables real-time updates when new samples added | [Executing Observer Queries](https://developer.apple.com/documentation/healthkit/executing-observer-queries) |
| NOT `HKObserverQuery` | Observer is for background notifications, not live data | Apple docs: "Observer requires completion handler for background delivery" |
| Return query IDs | Allows selective query cancellation | Best practice for resource management |
| Sum samples in handler | Cumulative total needed (not just increments) | TODO: Optimize with anchor tracking |

---

## API Reference

### HealthKitLiveTrackingService

**Purpose**: Infrastructure service for HKAnchoredObjectQuery lifecycle management

```swift
let service = HealthKitLiveTrackingService()

// Start tracking
let stepQueryID = service.startStepTracking { steps in
    print("Current steps: \(steps)")
}

let distanceQueryID = service.startDistanceTracking { km in
    print("Current distance: \(km) km")
}

let energyQueryID = service.startActiveEnergyTracking { kcal in
    print("Current energy: \(kcal) kcal")
}

// Stop specific query
service.stopTracking(queryID: stepQueryID)

// Stop all queries (on view disappear)
service.stopAllTracking()
```

**Key Features**:
- ✅ Returns query UUID for selective cancellation
- ✅ Automatic main actor dispatch (safe for UI updates)
- ✅ Error logging with descriptive messages
- ✅ macOS stub for cross-platform development
- ✅ Predicate for today only (resets at midnight)

**Future Enhancements**:
- [ ] Add midnight observer to restart queries for new day
- [ ] Optimize with anchor tracking (avoid re-summing all samples)
- [ ] Add heart rate, sleep, mindfulness tracking
- [ ] Add background delivery support (requires completion handler)

### HealthDashboardViewModel

**Purpose**: @Observable ViewModel coordinating live tracking and UI state

```swift
@State private var viewModel = HealthDashboardViewModel()

var body: some View {
    Text("\(viewModel.dailySteps) steps")
        .task {
            await viewModel.requestAuthorizationAndStart()
        }
        .onDisappear {
            viewModel.stopLiveTracking()
        }
}
```

**Published State** (automatically observable):
- `dailySteps: Int` - Cumulative step count for today
- `dailyDistance: Double` - Cumulative distance in km
- `activeEnergy: Double` - Cumulative active energy in kcal
- `stepGoal: Int` - User's daily step goal (default: 10,000)
- `isTracking: Bool` - Whether live tracking is active
- `lastUpdated: Date` - Last metric update timestamp
- `authorizationStatus` - HealthKit permission state
- `errorMessage: String?` - User-facing error message

**Computed Properties**:
- `stepProgressPercentage: Double` - Progress toward goal (0.0 to 1.0+)
- `hasReachedStepGoal: Bool` - Whether goal achieved
- `formattedDistance: String` - "5.2 km"
- `formattedActiveEnergy: String` - "387 kcal"
- `formattedLastUpdated: String` - "3:42 PM"
- `formattedDailySteps: String` - "8,537" (with thousands separator)
- `formattedStepGoal: String` - "10,000" (with thousands separator)

**Methods**:
- `requestAuthorizationAndStart() async` - Request HealthKit permission + start tracking
- `checkExistingAuthorization() -> Bool` - Check without prompting
- `startLiveTracking()` - Start HKAnchoredObjectQuery monitors
- `stopLiveTracking()` - Stop all queries (call on disappear)
- `updateStepGoal(_ goal: Int)` - Change daily step target
- `refreshMetrics() async` - Manual one-time refresh (TODO)

---

## Testing Instructions

### 1. Add Test View to Navigation

In your main `ContentView.swift` or navigation menu:

```swift
NavigationLink("Health Dashboard Test") {
    HealthDashboardTestView()
}
```

### 2. Test on iOS Simulator

**Step-by-step**:

1. **Run app on iOS Simulator**
   ```bash
   cd swift/
   swift build
   # Or run from Xcode: Cmd+R
   ```

2. **Navigate to Health Dashboard Test**
   - Tap "Health Dashboard Test" in navigation

3. **Authorize HealthKit**
   - Tap "Enable" button
   - System will show HealthKit authorization dialog
   - Tap "Allow" for all requested data types

4. **Add sample data in Health app**
   - Open **Health** app on simulator
   - Tap **Browse** → **Activity** → **Steps**
   - Tap **Add Data** button (top-right)
   - Enter step count (e.g., 5000)
   - Tap **Add**

5. **Verify live update**
   - Switch back to your app
   - **Within 2-3 seconds**, the step count should update automatically
   - "LIVE" indicator should be pulsing red
   - "Last updated" timestamp should change

6. **Add more data to test real-time updates**
   - Go back to Health app
   - Add another step sample (e.g., 1000 steps)
   - Return to your app → should update automatically

**Expected behavior**:
- ✅ Step count increases immediately (within 2-3 seconds)
- ✅ "LIVE" indicator pulses
- ✅ Progress bar animates smoothly
- ✅ Last updated time changes
- ✅ If you reach goal (≥10,000 steps), "Goal reached!" appears

### 3. Test on Physical iOS Device

**Requirements**:
- iOS 26+ device
- Xcode with provisioning profile
- Real HealthKit data (walking, workouts)

**Steps**:
1. Connect device via USB or network
2. Select device as build target in Xcode
3. Run app (Cmd+R)
4. Authorize HealthKit when prompted
5. **Walk around** or **do a workout** → metrics update automatically

**Testing tips**:
- Open Health app → Activity → Steps to see raw data
- Compare app's step count with Health app (should match)
- Try adding manual workout in Health app → distance/energy should update

### 4. Test Authorization States

**Test denied state**:
1. Go to **Settings** → **Health** → **Data Access & Devices**
2. Find your app → disable all permissions
3. Relaunch app → should show "Denied" status with instructions

**Test re-authorization**:
1. From denied state, go back to Settings → Health → enable permissions
2. Close app completely (swipe up in app switcher)
3. Relaunch → should detect authorization and start tracking

---

## Known Limitations

### Current Implementation

1. **No midnight rollover** - Queries use `predicateForToday()` which doesn't update at midnight
   - **Impact**: After midnight, metrics still show previous day until app restarted
   - **Fix**: Add `NotificationCenter` observer for `.NSCalendarDayChanged` notification

2. **Re-summing all samples** - Each update re-calculates total from beginning of day
   - **Impact**: Slight inefficiency (negligible for daily data)
   - **Fix**: Track anchor, only add incremental samples to running total

3. **No background delivery** - Queries stop when app backgrounded
   - **Impact**: Metrics don't update in background
   - **Fix**: Implement `HKObserverQuery` with background delivery + completion handler

4. **No persistence** - Metrics reset when ViewModel deallocates
   - **Impact**: State lost when navigating away
   - **Fix**: Save to UserDefaults or database

5. **No goal customization UI** - Step goal hardcoded to 10,000
   - **Impact**: Can't change goal without code change
   - **Fix**: Add settings screen with `updateStepGoal()` method

### Platform Limitations

- **macOS**: HealthKit not available (stubs provided)
- **Simulator**: Can't test workouts (only manual data entry)
- **Real device required** for: GPS workouts, heart rate, automatic step counting

---

## Integration with Existing Code

### Extend HealthKitImportService

You already have `HealthKitImportService` that converts workouts → Actions. To auto-import today's activity:

```swift
// In HealthDashboardViewModel or new coordinator

/// Automatically create Action from today's metrics
func importTodayAsAction() async throws {
    // Create HealthWorkout from live metrics
    let workout = HealthWorkout(
        id: UUID(),
        startDate: Calendar.current.startOfDay(for: .now),
        endDate: .now,
        activityType: .walking,  // Generic
        duration: 0,  // Not tracked in live metrics
        totalDistance: dailyDistance * 1000,  // km → meters
        totalEnergyBurned: activeEnergy
    )

    // Import using existing service
    let importService = HealthKitImportService()
    let action = try await importService.importWorkout(workout)

    print("✅ Imported today's activity as Action: \(action.id)")
}
```

### Add to Measure Catalog

Your `Measure` model already supports steps, but you may want to add an explicit entry:

```swift
// In database seed or initial setup
extension Measure {
    public static let steps = Measure(
        unit: "steps",
        measureType: "count",
        title: "Steps",
        detailedDescription: "Number of steps taken",
        canonicalUnit: "steps",
        conversionFactor: 1.0
    )
}
```

### Use in Dashboard Views

When you build the full Liquid Glass UI in Phase 7:

```swift
// App/Views/Health/HealthDashboardView.swift (future)

struct HealthDashboardView: View {
    @State private var viewModel = HealthDashboardViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                StepMetricCard(
                    steps: viewModel.dailySteps,
                    goal: viewModel.stepGoal,
                    percentage: viewModel.stepProgressPercentage,
                    lastUpdated: viewModel.lastUpdated,
                    isLive: viewModel.isTracking
                )

                DistanceMetricCard(
                    distance: viewModel.dailyDistance,
                    isLive: viewModel.isTracking
                )

                EnergyMetricCard(
                    energy: viewModel.activeEnergy,
                    isLive: viewModel.isTracking
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.requestAuthorizationAndStart()
        }
        .onDisappear {
            viewModel.stopLiveTracking()
        }
    }
}
```

---

## Next Steps

### Phase 4 (Current): Validation Layer
**Defer full UI until Phase 7** - Focus on validation infrastructure first

### Phase 6 (ViewModels): Enhance HealthDashboardViewModel
- [ ] Add goal customization with persistence
- [ ] Add manual refresh capability
- [ ] Add yesterday's metrics comparison
- [ ] Add weekly averages/trends

### Phase 7 (Views): Build Liquid Glass UI
- [ ] Create `HealthDashboardView.swift` with Liquid Glass cards
- [ ] Create `StepMetricCard.swift` with `.regularMaterial`
- [ ] Create `DistanceMetricCard.swift`
- [ ] Create `EnergyMetricCard.swift`
- [ ] Create `ProgressRing.swift` (circular progress indicator)
- [ ] Add animations with `.contentTransition(.numericText())`
- [ ] Add achievement badges (Withings-style)

### Future Enhancements
- [ ] Heart rate monitoring (HKQuantityTypeIdentifier.heartRate)
- [ ] Sleep tracking integration
- [ ] Mindfulness session tracking
- [ ] Workout history timeline
- [ ] Automatic Action creation from daily activity
- [ ] Export to CSV for goal tracking
- [ ] Apple Watch complications

---

## Troubleshooting

### Metrics Not Updating

**Symptom**: Step count shows 0 or doesn't change when adding data

**Checks**:
1. Verify authorization granted: `viewModel.authorizationStatus == .authorized`
2. Check console for error messages: Look for "❌" prefixed logs
3. Verify data added to Health app: Open Health → Activity → Steps
4. Ensure data is for **today** (queries filter by date)
5. Check "LIVE" indicator is pulsing (confirms tracking active)

**Solution**:
```swift
// Check if tracking started
print("Is tracking: \(viewModel.isTracking)")

// Manually stop and restart
viewModel.stopLiveTracking()
viewModel.startLiveTracking()
```

### Authorization Denied

**Symptom**: Status shows "Denied" after tapping "Enable"

**Cause**: User tapped "Don't Allow" in authorization dialog

**Fix**:
1. Go to **Settings** → **Health** → **Data Access & Devices**
2. Find your app in the list
3. Enable all requested permissions (Steps, Distance, Active Energy)
4. Relaunch app

### Queries Stop After Background

**Symptom**: Metrics freeze when app goes to background

**Expected**: This is normal - `HKAnchoredObjectQuery` requires app in foreground

**Fix** (future): Implement background delivery:
```swift
// In HealthKitManager.requestAuthorization()
healthStore.enableBackgroundDelivery(
    for: stepType,
    frequency: .immediate
) { success, error in
    // Handle background delivery setup
}
```

### High Battery Drain

**Symptom**: Battery draining faster than expected

**Cause**: Active HealthKit queries run continuously while app in foreground

**Fix**: Ensure `stopLiveTracking()` called on view disappear:
```swift
.onDisappear {
    viewModel.stopLiveTracking()
}
```

**Verify**: Check console for "⏹️ Stopped all live tracking" message

---

## References

### Apple Documentation (Fetched via doc-fetcher)

1. **HKAnchoredObjectQuery**
   - URL: developer.apple.com/documentation/healthkit/hkanchoredobjectquery
   - Key: "Update handler for continuous monitoring"

2. **Executing Observer Queries**
   - URL: developer.apple.com/documentation/healthkit/executing-observer-queries
   - Key: "Background delivery requires completion handler"

3. **Liquid Glass**
   - URL: developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
   - Key: "Use .regularMaterial for Liquid Glass effect"

### Project Documentation

- [REARCHITECTURE_COMPLETE_GUIDE.md](./REARCHITECTURE_COMPLETE_GUIDE.md) - Phase roadmap
- [CLAUDE.md](../CLAUDE.md) - Architecture patterns and conventions
- [HealthKitManager.swift](../Sources/Services/HealthKitManager.swift) - Existing authorization/queries
- [HealthKitImportService.swift](../Sources/Services/HealthKitImportService.swift) - Workout import logic

---

## Summary

**What you now have**:
- ✅ Real-time HealthKit monitoring service (Apple-verified APIs)
- ✅ @Observable ViewModel following app patterns
- ✅ Test view for immediate verification
- ✅ Cross-platform support (macOS stubs)
- ✅ Proper query lifecycle management
- ✅ Integration points documented

**What's next** (Phase 7):
- Build Liquid Glass UI components
- Add metric cards with animations
- Implement progress rings and badges
- Create full dashboard view

**Estimated time to full Liquid Glass UI**: 1-2 hours (after Phase 4-6 complete)
