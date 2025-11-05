# HealthKit Implementation Guide

**Written by Claude Code on 2025-11-04**

This document describes the comprehensive HealthKit integration for the Ten Week Goal App, covering workouts, sleep, and mindfulness data.

## Overview

The HealthKit integration provides read-only access to three primary data types:
1. **Workouts** - Exercise and physical activity (HKWorkout)
2. **Sleep** - Sleep analysis with stages (HKCategorySample - sleepAnalysis)
3. **Mindfulness** - Meditation and mindfulness sessions (HKCategorySample - mindfulSession)

## Architecture

### Models (`swift/Sources/Models/Basics/`)

#### HealthWorkout.swift
Display model for workout data with comprehensive activity type support.

**Key Features:**
- Supports **80+ workout activity types** including:
  - Cardio: Running, Cycling, Swimming, Hiking, Rowing, Elliptical
  - Strength: Functional Training, Weight Lifting, Core Training, HIIT
  - Mind & Body: Yoga, Pilates, Tai Chi, Barre
  - Team Sports: Soccer, Basketball, Baseball, Hockey, etc.
  - Racquet Sports: Tennis, Badminton, Pickleball, etc.
  - Winter Sports: Skiing, Snowboarding, Skating
  - Combat Sports: Boxing, Kickboxing, Martial Arts
  - And many more...

- **Computed Properties:**
  - `activityName`: User-friendly name ("Running", "HIIT", etc.)
  - `iconName`: SF Symbols icon for activity type
  - `formattedDuration`: "30:42" or "1:15:22"
  - `formattedDistance`: "5.2 km" or "3.1 mi"
  - `formattedCalories`: "387 kcal"
  - `summaryLine`: "30:42 • 5.2 km • 387 kcal"

**Usage:**
```swift
let workout = HealthWorkout(from: hkWorkout)
Text(workout.activityName)  // "Running"
Text(workout.summaryLine)   // "30:42 • 5.2 km • 387 kcal"
Image(systemName: workout.iconName)  // figure.run
```

#### HealthSleep.swift
Display model for sleep analysis data.

**Sleep Stages Supported:**
- **In Bed** - Time spent in bed (tracked by iPhone/Watch)
- **Asleep (Unspecified)** - General sleep time
- **Awake** - Brief awakenings during night
- **Core Sleep** - Light sleep stage
- **Deep Sleep** - Most restorative sleep stage
- **REM Sleep** - Rapid Eye Movement, dreaming stage

**Computed Properties:**
- `stageName`: User-friendly stage name ("Deep Sleep", "REM Sleep")
- `iconName`: SF Symbols icon for sleep stage
- `stageColor`: Color for visualization (purple for REM, indigo for deep, etc.)
- `isAsleep`: Boolean indicating actual sleep vs. in bed/awake
- `formattedDuration`: "2h 15m"
- `shortDuration`: "2:15"

**Array Extensions:**
```swift
let sleepSamples: [HealthSleep] = [...]
print(sleepSamples.totalSleepTime)        // Total sleep excluding awake/in bed
print(sleepSamples.deepSleepTime)         // Deep sleep duration
print(sleepSamples.remSleepTime)          // REM sleep duration
print(sleepSamples.formattedTotalSleep)   // "7h 45m"
```

**Usage:**
```swift
let sleep = HealthSleep(from: hkCategorySample)
Text(sleep.stageName)       // "Deep Sleep"
Text(sleep.formattedDuration)  // "2h 15m"
Image(systemName: sleep.iconName)  // moon.fill
```

#### HealthMindfulness.swift
Display model for mindfulness/meditation sessions.

**Computed Properties:**
- `sessionName`: "Mindful Session"
- `iconName`: SF Symbols icon ("brain.fill")
- `timeOfDay`: "Morning", "Afternoon", "Evening", "Night"
- `timeOfDayIcon`: Time-appropriate icon (sunrise, sun, sunset, moon)
- `durationCategory`: "Quick" (<5m), "Short" (5-15m), "Medium" (15-30m), "Long" (30m+)
- `formattedDuration`: "15 minutes" or "1 hour 15 minutes"
- `shortDuration`: "15m" or "1h 15m"
- `summaryLine`: "15m • Morning"

**Array Extensions:**
```swift
let sessions: [HealthMindfulness] = [...]
print(sessions.totalMindfulTime)           // Total mindfulness time
print(sessions.averageSessionDuration)     // Average per session
print(sessions.formattedTotalTime)         // "2h 30m"
print(sessions.sessionsByTimeOfDay)        // Grouped by time of day
print(sessions.countByDurationCategory)    // Count by Quick/Short/Medium/Long
```

**Usage:**
```swift
let session = HealthMindfulness(from: hkCategorySample)
Text(session.formattedDuration)  // "15 minutes"
Text(session.timeOfDay)          // "Morning"
Image(systemName: session.iconName)  // brain.fill
```

### Manager (`swift/Sources/Services/HealthKitManager.swift`)

Singleton service for HealthKit authorization and queries.

#### Authorization

**Request Authorization:**
```swift
let manager = HealthKitManager.shared
try await manager.requestAuthorization()
```

This requests read permission for:
- HKWorkoutType (workouts)
- HKCategoryTypeIdentifier.sleepAnalysis (sleep data)
- HKCategoryTypeIdentifier.mindfulSession (mindfulness sessions)

**Check Status:**
```swift
let isAuthorized = manager.checkAuthorizationStatus()
print(manager.authorizationStatus)  // .notDetermined, .authorized, .denied, .unavailable
```

#### Workout Queries

**Fetch workouts for a specific date:**
```swift
let workouts = try await manager.fetchWorkouts(for: Date())
// Returns: [HKWorkout]

// Convert to display models
let displayWorkouts = workouts.map { HealthWorkout(from: $0) }
```

**Fetch workouts for a date range:**
```swift
let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
let workouts = try await manager.fetchWorkouts(from: startDate, to: Date())
```

#### Sleep Queries

**Fetch sleep data for a specific date:**
```swift
let sleepSamples = try await manager.fetchSleep(for: Date())
// Returns: [HKCategorySample]

// Convert to display models
let sleepData = sleepSamples.compactMap { HealthSleep(from: $0) }

// Use array extensions
print(sleepData.formattedTotalSleep)  // "7h 45m"
print(sleepData.deepSleepTime)        // TimeInterval
```

**Fetch sleep for a date range:**
```swift
let samples = try await manager.fetchSleep(from: startDate, to: endDate)
```

#### Mindfulness Queries

**Fetch mindfulness sessions for a specific date:**
```swift
let sessions = try await manager.fetchMindfulness(for: Date())
// Returns: [HKCategorySample]

// Convert to display models
let mindfulSessions = sessions.compactMap { HealthMindfulness(from: $0) }

// Use array extensions
print(mindfulSessions.formattedTotalTime)  // "2h 30m"
print(mindfulSessions.sessionsByTimeOfDay) // Dictionary grouped by time
```

**Fetch mindfulness for a date range:**
```swift
let sessions = try await manager.fetchMindfulness(from: startDate, to: endDate)
```

## Error Handling

All query methods can throw:
- `HealthKitError.notAvailable` - HealthKit unavailable on device
- `HealthKitError.notAuthorized` - User hasn't granted permission
- `HealthKitError.invalidDate` - Date calculation failed
- Standard HealthKit errors from query execution

**Example with error handling:**
```swift
do {
    let workouts = try await manager.fetchWorkouts(for: Date())
    // Process workouts
} catch HealthKitManager.HealthKitError.notAuthorized {
    // Show permission prompt
} catch {
    // Handle other errors
    print("Error fetching workouts: \(error)")
}
```

## Platform Support

All HealthKit code is wrapped in `#if os(iOS)` blocks:
- **iOS**: Full HealthKit functionality
- **macOS**: Stub implementations (HealthKit not available)

The macOS stubs provide the same API surface but return empty/placeholder data.

## Data Privacy

**Important Notes:**
- This implementation is **read-only** - no writing to HealthKit
- User must explicitly grant permission via system dialog
- Authorization status is tracked per data type
- Queries respect user's privacy settings

## Future Enhancements

Potential additions:
- **Heart Rate Data** - HKQuantityType.heartRate
- **Steps** - HKQuantityType.stepCount
- **Active Energy** - HKQuantityType.activeEnergyBurned
- **Nutrition** - HKQuantityType nutrition types
- **Batch Queries** - Background updates and observers
- **Statistical Queries** - Aggregate data over time periods

## References

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [HKWorkoutActivityType Reference](https://developer.apple.com/documentation/healthkit/hkworkoutactivitytype)
- [HKCategoryValueSleepAnalysis Reference](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)
- [Building workout apps (WWDC)](https://developer.apple.com/videos/play/wwdc2021/10009/)

## Implementation Status

✅ **Complete** (2025-11-04):
- Comprehensive workout support (80+ activity types)
- Full sleep stage tracking (6 stages)
- Mindfulness session tracking
- Authorization flow for all three data types
- Display models with rich computed properties
- Array extensions for aggregate calculations
- Complete documentation

## Testing

Since Swift compiler is not available in the development environment, code should be tested on:
1. **iOS Simulator** - Basic functionality testing
2. **Physical iOS Device** - Full HealthKit testing with real data
3. **Unit Tests** - Using mock HKSample data

**Test Coverage Needed:**
- [ ] Authorization flow
- [ ] Workout queries with various activity types
- [ ] Sleep queries with all stage types
- [ ] Mindfulness queries
- [ ] Date range queries
- [ ] Error handling paths
- [ ] Display model computed properties
- [ ] Array extension calculations
