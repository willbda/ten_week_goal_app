# Apple Data Integration Architecture
**Written by**: Claude Code on 2025-10-31
**Strategy**: Ingest → Parse → Normalize → Purge

## Executive Summary

Integrate HealthKit (sleep, exercise, mindfulness, calories) and EventKit (calendar, reminders) data into your goal tracking system using a **staged ingestion pattern**: capture raw Apple SDK data as JSON, parse into normalized measurements, then periodically purge raw data to minimize storage while maintaining re-fetch capability.

---

## Architecture Overview

### Data Flow

```
Apple SDKs (HealthKit, EventKit)
    ↓ [Ingest]
Raw Apple Data Table (JSON binary blobs)
    ↓ [Parse & Transform]
Normalized Measures (existing schema)
    ↓ [Periodic Cleanup]
Delete Raw Data (can re-fetch when needed)
```

### Key Principles

1. **Ingest Everything** - Store raw SDK responses as JSON
2. **Parse Incrementally** - Extract only what you need now
3. **Normalize Into Existing Schema** - Use `Measure` + `MeasuredAction` tables
4. **Purge Periodically** - Delete raw data after successful normalization
5. **Re-fetch on Demand** - Apple SDKs are the source of truth

---

## Database Schema

### New Table: `appledata` (Staging Area)

```sql
CREATE TABLE appledata (
    id TEXT PRIMARY KEY,
    sourceSDK TEXT NOT NULL,        -- 'HealthKit' or 'EventKit'
    dataType TEXT NOT NULL,          -- 'sleep', 'workout', 'calories', 'calendar', etc.
    fetchedAt TEXT NOT NULL,         -- When we fetched from Apple
    startDate TEXT NOT NULL,         -- Data period start
    endDate TEXT NOT NULL,           -- Data period end
    rawJSON TEXT NOT NULL,           -- Complete Apple SDK response
    parsed BOOLEAN DEFAULT 0,        -- Has this been processed?
    parsedAt TEXT,                   -- When we parsed it
    purgeAfter TEXT,                 -- Auto-delete after this date
    logTime TEXT NOT NULL            -- Record creation time
);

-- Index for finding unparsed data
CREATE INDEX idx_appledata_parsed ON appledata(parsed, sourceSDK, dataType);

-- Index for purge cleanup
CREATE INDEX idx_appledata_purge ON appledata(purgeAfter) WHERE purgeAfter IS NOT NULL;
```

**Design Rationale**:
- `rawJSON`: Complete SDK response preserves all data for future parsing evolution
- `parsed`: Boolean flag enables incremental batch processing
- `purgeAfter`: Automatic cleanup after N days (configurable, default 30 days)
- Can re-fetch historical data from Apple SDKs if needed

---

## HealthKit Integration

### Data Types to Ingest

#### 1. Sleep Analysis
**HKCategoryType**: `.sleepAnalysis`

```swift
// Raw JSON structure from HealthKit
{
  "uuid": "ABC-123",
  "startDate": "2025-10-30T23:00:00Z",
  "endDate": "2025-10-31T07:30:00Z",
  "value": "inBed",  // or "asleep", "awake", "core", "deep", "REM"
  "metadata": {
    "HKWasUserEntered": false
  }
}
```

**Parse into Measures**:
- `sleep_hours` → Duration of "asleep" segments (hours)
- `inbed_hours` → Total time in bed (hours)
- `sleep_efficiency` → asleep / inbed percentage

#### 2. Active Energy Burned
**HKQuantityType**: `.activeEnergyBurned`

```swift
{
  "uuid": "DEF-456",
  "startDate": "2025-10-31T06:00:00Z",
  "endDate": "2025-10-31T07:00:00Z",
  "quantity": {
    "value": 387.5,
    "unit": "kcal"
  },
  "sourceName": "Apple Watch"
}
```

**Parse into Measures**:
- `calories_burned` → Total active energy (kcal)

#### 3. Mindfulness Minutes
**HKCategoryType**: `.mindfulSession`

```swift
{
  "uuid": "GHI-789",
  "startDate": "2025-10-31T08:00:00Z",
  "endDate": "2025-10-31T08:15:00Z",
  "value": "notApplicable",  // Just presence/absence
  "metadata": {
    "HKWasUserEntered": true
  }
}
```

**Parse into Measures**:
- `mindfulness_minutes` → Session duration (minutes)
- `mindfulness_sessions` → Count of sessions (occasions)

#### 4. Exercise Minutes
**HKQuantityType**: `.appleExerciseTime`

```swift
{
  "uuid": "JKL-012",
  "startDate": "2025-10-31T06:00:00Z",
  "endDate": "2025-10-31T06:45:00Z",
  "quantity": {
    "value": 45.0,
    "unit": "min"
  }
}
```

**Parse into Measures**:
- `exercise_minutes` → Total exercise time (minutes)

### HealthKit Query Patterns

```swift
// Service method to fetch and ingest
class HealthKitIngestionService {
    func ingestSleepData(for date: Date) async throws {
        // 1. Query HealthKit
        let sleepSamples = try await querySleep(for: date)

        // 2. Store raw JSON
        let rawJSON = try JSONEncoder().encode(sleepSamples)
        try await storeRawData(
            sourceSDK: "HealthKit",
            dataType: "sleep",
            startDate: date,
            endDate: date,
            rawJSON: String(data: rawJSON, encoding: .utf8)!
        )

        // 3. Parse immediately (or defer to batch job)
        try await parseSleepData(from: rawJSON)
    }

    private func querySleep(for date: Date) async throws -> [HKCategorySample] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: date),
            end: Calendar.current.date(byAdding: .day, value: 1, to: date)!
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}
```

---

## EventKit Integration

### Data Types to Ingest

#### 1. Calendar Events
**EKEvent**: Scheduled calendar items

```swift
{
  "eventIdentifier": "EVENT-123",
  "title": "Team Meeting",
  "startDate": "2025-10-31T14:00:00Z",
  "endDate": "2025-10-31T15:00:00Z",
  "isAllDay": false,
  "calendar": {
    "title": "Work",
    "color": "blue"
  },
  "attendees": [
    {"name": "Alice", "status": "accepted"}
  ]
}
```

**Parse into Measures**:
- `meeting_hours` → Duration of meeting events (hours)
- `meeting_count` → Number of meetings (occasions)
- Can filter by calendar (work vs personal)

#### 2. Reminders
**EKReminder**: To-do items with completion

```swift
{
  "calendarItemIdentifier": "REM-456",
  "title": "Submit report",
  "dueDate": "2025-10-31T17:00:00Z",
  "completed": true,
  "completionDate": "2025-10-31T16:45:00Z",
  "priority": 1,  // High priority
  "calendar": {
    "title": "Work Tasks"
  }
}
```

**Parse into Measures**:
- `tasks_completed` → Count of completed reminders (occasions)
- `high_priority_completed` → Count of high-priority completions

### EventKit Query Patterns

```swift
class EventKitIngestionService {
    private let eventStore = EKEventStore()

    func ingestCalendarEvents(for date: Date) async throws {
        // 1. Request permission
        try await eventStore.requestFullAccessToEvents()

        // 2. Query events
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        // 3. Store raw JSON
        let rawJSON = try JSONEncoder().encode(events.map { EventDTO(from: $0) })
        try await storeRawData(
            sourceSDK: "EventKit",
            dataType: "calendar",
            startDate: startOfDay,
            endDate: endOfDay,
            rawJSON: String(data: rawJSON, encoding: .utf8)!
        )

        // 4. Parse
        try await parseCalendarEvents(from: rawJSON)
    }

    // DTO to make EKEvent encodable
    struct EventDTO: Codable {
        let title: String?
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let calendarTitle: String?

        init(from event: EKEvent) {
            self.title = event.title
            self.startDate = event.startDate
            self.endDate = event.endDate
            self.isAllDay = event.isAllDay
            self.calendarTitle = event.calendar?.title
        }
    }
}
```

---

## Parsing & Normalization Strategy

### 1. Create Measures Catalog (One-Time)

```sql
-- Add new measures for Apple data
INSERT INTO measures (id, unit, measureType, title, detailedDescription, logTime)
VALUES
  -- Sleep
  (uuid(), 'hours', 'time', 'Sleep Hours', 'Total hours asleep', datetime('now')),
  (uuid(), 'hours', 'time', 'Time in Bed', 'Total hours in bed', datetime('now')),
  (uuid(), 'percent', 'ratio', 'Sleep Efficiency', 'Sleep hours / time in bed', datetime('now')),

  -- Calories
  (uuid(), 'kcal', 'energy', 'Active Calories', 'Active energy burned', datetime('now')),
  (uuid(), 'kcal', 'energy', 'Total Calories', 'Total energy burned', datetime('now')),

  -- Mindfulness
  (uuid(), 'minutes', 'time', 'Mindfulness Minutes', 'Time spent in mindfulness', datetime('now')),
  (uuid(), 'occasions', 'count', 'Mindfulness Sessions', 'Number of mindfulness sessions', datetime('now')),

  -- Exercise
  (uuid(), 'minutes', 'time', 'Exercise Minutes', 'Total exercise time', datetime('now')),

  -- Calendar
  (uuid(), 'hours', 'time', 'Meeting Hours', 'Time spent in meetings', datetime('now')),
  (uuid(), 'occasions', 'count', 'Meetings', 'Number of meetings', datetime('now')),
  (uuid(), 'occasions', 'count', 'Tasks Completed', 'Completed reminders', datetime('now'));
```

### 2. Parse Sleep Data Example

```swift
struct SleepParser {
    func parse(appleDataId: String, rawJSON: String) async throws {
        // 1. Decode Apple SDK response
        let sleepSamples = try JSONDecoder().decode([SleepSampleDTO].self, from: rawJSON.data(using: .utf8)!)

        // 2. Calculate aggregates
        let sleepPeriods = sleepSamples.filter { $0.value == "asleep" }
        let totalSleepSeconds = sleepPeriods.reduce(0.0) { total, sample in
            return total + sample.endDate.timeIntervalSince(sample.startDate)
        }
        let sleepHours = totalSleepSeconds / 3600.0

        // 3. Create automatic Action for the day
        let sleepDate = Calendar.current.startOfDay(for: sleepSamples.first!.startDate)
        let action = Action(
            title: "Sleep",
            detailedDescription: "Automatically tracked from Apple Health",
            logTime: sleepDate
        )
        try await actionRepo.insert(action)

        // 4. Create MeasuredAction
        let sleepMeasure = try await measureRepo.findByUnit("hours", type: "time", title: "Sleep Hours")
        let measured = MeasuredAction(
            actionId: action.id,
            measureId: sleepMeasure.id,
            value: sleepHours,
            createdAt: Date()
        )
        try await measuredActionRepo.insert(measured)

        // 5. Mark appledata as parsed
        try await markParsed(appleDataId: appleDataId)
    }
}
```

### 3. Auto-Create Daily Actions

**Strategy**: For each day's Apple data, create ONE `Action` with multiple `MeasuredAction` records:

```
Action: "Daily Apple Health Summary - Oct 31"
  ├─ MeasuredAction: sleep_hours = 7.5
  ├─ MeasuredAction: calories_burned = 2850
  ├─ MeasuredAction: exercise_minutes = 45
  ├─ MeasuredAction: mindfulness_minutes = 15
  └─ MeasuredAction: meeting_hours = 3.5
```

**Benefits**:
- Single action per day (not cluttered with 20 mini-actions)
- All Apple data grouped logically
- Easy to query: "Show me my sleep patterns" → Filter MeasuredActions by measureId

---

## Purge Strategy

### Automatic Cleanup

```sql
-- Run daily (cron job or app background task)
DELETE FROM appledata
WHERE purgeAfter < datetime('now')
  AND parsed = 1;  -- Only delete if successfully parsed
```

### Purge Policy

| Data Type | Purge After | Rationale |
|-----------|-------------|-----------|
| Sleep | 7 days | Can re-fetch from HealthKit easily |
| Calories | 7 days | High-frequency data, low storage value |
| Exercise | 14 days | Might want to review details |
| Mindfulness | 14 days | Infrequent, nice to keep longer |
| Calendar | 30 days | Harder to re-fetch (events might be deleted) |
| Reminders | 30 days | Completion history might change |

**Override**: User can manually trigger purge or extend retention.

---

## Implementation Phases

### Phase 1: Infrastructure (Week 1)
**Goal**: Set up raw data ingestion

- [ ] Create `appledata` table
- [ ] Create `AppleDataRepository` (CRUD for appledata table)
- [ ] Create `HealthKitIngestionService`
- [ ] Create `EventKitIngestionService`
- [ ] Add new measures to catalog
- [ ] Test: Ingest 1 sleep sample, verify JSON stored

### Phase 2: Parsing (Week 2)
**Goal**: Transform raw data into measures

- [ ] Create `SleepParser`
- [ ] Create `CaloriesParser`
- [ ] Create `MindfulnessParser`
- [ ] Create `CalendarParser`
- [ ] Auto-create daily Action records
- [ ] Test: Parse sleep → verify MeasuredAction created

### Phase 3: Background Sync (Week 3)
**Goal**: Automate data refresh

- [ ] Create `BackgroundSyncService`
- [ ] Schedule daily HealthKit sync (morning)
- [ ] Schedule daily EventKit sync (evening)
- [ ] Handle authorization states
- [ ] Error handling and retry logic
- [ ] Test: Run for 7 days, verify continuous sync

### Phase 4: UI & Visualization (Week 4)
**Goal**: Show Apple data in app

- [ ] Add "Apple Health" section to sidebar
- [ ] Show sleep trends (last 7 days)
- [ ] Show calories burned chart
- [ ] Show meeting time breakdown
- [ ] Test: Verify UI updates with new data

### Phase 5: Purge & Maintenance (Week 5)
**Goal**: Clean up old raw data

- [ ] Implement purge logic
- [ ] Add background task for daily cleanup
- [ ] Add manual "Purge Now" button (settings)
- [ ] Add "Re-fetch from Apple" option
- [ ] Test: Verify old data deleted, can re-fetch

---

## Service Architecture

```
Sources/
├── Services/
│   ├── HealthKitManager.swift          (✅ Exists - basic workout queries)
│   ├── HealthKitIngestionService.swift (NEW - ingest sleep, calories, etc.)
│   ├── EventKitIngestionService.swift  (NEW - ingest calendar/reminders)
│   ├── AppleDataParser.swift           (NEW - parse JSON → measures)
│   ├── BackgroundSyncService.swift     (NEW - orchestrate daily sync)
│   └── PurgeService.swift              (NEW - cleanup old raw data)
│
├── Repositories/
│   └── AppleDataRepository.swift       (NEW - CRUD for appledata table)
│
└── Models/
    └── Composits/
        └── AppleData.swift              (NEW - appledata table model)
```

---

## Privacy & Permissions

### HealthKit Permissions

```xml
<!-- Info.plist -->
<key>NSHealthShareUsageDescription</key>
<string>We use your sleep, exercise, and calorie data to track your wellness goals.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>We don't write data to Apple Health.</string>
```

**Request in app**:
```swift
let types = Set([
    HKCategoryType(.sleepAnalysis),
    HKQuantityType(.activeEnergyBurned),
    HKQuantityType(.appleExerciseTime),
    HKCategoryType(.mindfulSession)
])

try await healthStore.requestAuthorization(toShare: [], read: types)
```

### EventKit Permissions

```xml
<key>NSCalendarsUsageDescription</key>
<string>We analyze your calendar to understand meeting patterns and time usage.</string>

<key>NSRemindersUsageDescription</key>
<string>We track completed reminders to measure task accomplishment.</string>
```

**Request in app**:
```swift
try await eventStore.requestFullAccessToEvents()
try await eventStore.requestFullAccessToReminders()
```

---

## Data Governance

### User Control

**Settings Panel** → Apple Data Integration:
- ✅ Sync Sleep Data (toggle)
- ✅ Sync Calories (toggle)
- ✅ Sync Mindfulness (toggle)
- ✅ Sync Calendar Events (toggle)
- ✅ Sync Reminders (toggle)
- 🔁 Manual Sync Now (button)
- 🗑️ Purge Raw Data (button with confirmation)
- ⏱️ Auto-Purge After: [7 days ▼]

### Data Transparency

**Show user**:
- Last sync: "3 hours ago"
- Raw data size: "2.4 MB"
- Parsed records: "381 measurements"
- Next purge: "In 4 days"

---

## Performance Considerations

### Batch Processing

Don't parse synchronously during fetch:
```swift
// ❌ BAD: Blocking
func ingestSleep() async throws {
    let samples = try await fetchSleep()
    try await parseSleep(samples)  // Blocks until done
}

// ✅ GOOD: Deferred
func ingestSleep() async throws {
    let samples = try await fetchSleep()
    try await storeRawData(samples)
    // Parse later in background task
}
```

### Query Optimization

```swift
// Parse in batches
let unparsedRecords = try await appleDataRepo.fetchUnparsed(limit: 100)
for record in unparsedRecords {
    try await parse(record)
}
```

---

## Edge Cases & Error Handling

### 1. Apple Health Unavailable
**Scenario**: User deletes Health app or restricts access

**Handling**:
- Show "Apple Health Unavailable" message
- Disable sync
- Keep existing parsed data

### 2. Duplicate Data
**Scenario**: User manually re-syncs same date

**Handling**:
```sql
-- Upsert pattern
INSERT INTO appledata (...) VALUES (...)
ON CONFLICT (sourceSDK, dataType, startDate)
DO UPDATE SET rawJSON = excluded.rawJSON, fetchedAt = excluded.fetchedAt;
```

### 3. Calendar Changed Retroactively
**Scenario**: User edits past calendar event

**Handling**:
- Don't re-sync historical data automatically
- Provide manual "Re-fetch This Week" button
- Or: Query Apple for "last modified" and sync changed events only

### 4. Parsing Fails
**Scenario**: Apple changes JSON schema, parsing breaks

**Handling**:
- Keep raw data (don't purge failed parses)
- Log parsing error with record ID
- Alert user: "3 records failed to parse. Update app to fix."
- Can fix parser and re-parse later

---

## Comparison: Raw Storage vs Direct Parsing

### With Raw Storage (Proposed)
**Pros**:
- ✅ Can fix parsing bugs without re-fetching
- ✅ Can add new measure types retroactively
- ✅ Full audit trail of Apple data
- ✅ Can experiment with different normalization approaches

**Cons**:
- Storage overhead (mitigated by purge)
- Extra complexity (staging table + parser)

### Direct Parsing (Simpler)
**Pros**:
- Simpler architecture
- Lower storage

**Cons**:
- ❌ Can't retroactively fix parsing bugs
- ❌ Can't add new measures for old data
- ❌ No audit trail of raw Apple responses
- ❌ Must re-fetch if normalization changes

**Verdict**: Raw storage wins for data archaeology and flexibility.

---

## Future Enhancements

### Phase 6: Advanced Parsing
- Heart rate variability (HRV)
- Stand hours
- Step count
- Flights climbed
- Nutrition data

### Phase 7: Predictive Analysis
- Correlate sleep quality with next-day calories
- Identify meeting patterns (too many meetings → lower exercise)
- Suggest optimal mindfulness times based on calendar

### Phase 8: Goal Integration
- Auto-create goals: "Sleep 8 hours nightly"
- Track progress: "30 days of 10K steps"
- Link calendar time to goal categories

---

## Success Criteria

✅ **Phase 1**: Raw Apple data ingested and stored as JSON
✅ **Phase 2**: Sleep, calories, exercise, mindfulness parsed into MeasuredActions
✅ **Phase 3**: Daily background sync runs automatically
✅ **Phase 4**: UI shows Apple Health trends
✅ **Phase 5**: Old raw data purged after 7-30 days
✅ **Phase 6**: User can re-fetch data on demand

---

## References

### Apple Documentation
- [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [HKHealthStore](https://developer.apple.com/documentation/healthkit/hkhealthstore)
- [HKSampleQuery](https://developer.apple.com/documentation/healthkit/hksamplequery)
- [EventKit Framework](https://developer.apple.com/documentation/eventkit)
- [EKEventStore](https://developer.apple.com/documentation/eventkit/ekeventstore)

### Code Patterns
- [Reading HealthKit Data](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [Querying Sleep Data](https://developer.apple.com/documentation/healthkit/about-the-healthkit-framework)
- [EventKit Best Practices](https://developer.apple.com/documentation/eventkit)

---

**Conclusion**: This architecture balances **flexibility** (raw data retention for re-parsing) with **efficiency** (periodic purge to limit storage). The staged approach (ingest → parse → normalize → purge) gives you maximum data archaeology capability while keeping the production database clean and query-performant.
