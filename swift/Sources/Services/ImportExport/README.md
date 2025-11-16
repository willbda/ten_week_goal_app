# CSV Import/Export Service

## Overview

Simple CSV import/export for Actions with reference sheets for measures and goals.

## User Workflow

### 1. Export Template

```swift
let service = ActionCSVService(database: db, coordinator: coordinator)
let result = try await service.exportTemplate(to: downloadsDirectory)
```

**Creates 3 files**:
- `actions_template.csv` - Blank form with example row
- `available_measures.csv` - All valid units (km, minutes, occasions, etc.)
- `available_goals.csv` - All current goals with targets

### 2. Fill Template

Open `actions_template.csv` in Excel/Numbers:

```csv
title,description,notes,duration_minutes,start_time,measure_1_unit,measure_1_value,measure_2_unit,measure_2_value,measure_3_unit,measure_3_value,goal_1_title,goal_2_title,goal_3_title
REQUIRED,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional
Morning run,Beautiful weather today,Saw three deer,28,2025-11-06T07:00:00Z,km,5.2,minutes,28,,,Spring into Running,,
```

Check reference sheets for valid values:

**available_measures.csv**:
```csv
unit,type,description
km,distance,Distance in kilometers
minutes,time,Duration in minutes
occasions,count,Number of occurrences
```

**available_goals.csv**:
```csv
title,target,unit,description
Spring into Running,120,km,Run 120km this term
Build Guitar Skills,50,hours,Practice guitar 50 hours
```

Add your data (copy-paste units/titles from reference sheets to avoid typos):

```csv
title,description,notes,duration_minutes,start_time,measure_1_unit,measure_1_value,measure_2_unit,measure_2_value,measure_3_unit,measure_3_value,goal_1_title,goal_2_title,goal_3_title
REQUIRED,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional,optional
Morning run,Beautiful weather today,Saw three deer,28,2025-11-06T07:00:00Z,km,5.2,minutes,28,,,Spring into Running,,
Evening run,Tired legs,,32,2025-11-06T18:30:00Z,km,4.1,minutes,32,,,Spring into Running,,
Guitar practice,Scales and chords,,45,2025-11-06T20:00:00Z,minutes,45,,,,Build Guitar Skills,,
```

### 3. Import CSV

```swift
let result = try await service.importActions(from: csvURL)
print(result.summary)  // "✓ Successfully imported 3 actions"

if result.hasFailures {
    for (row, error) in result.failures {
        print("Row \(row): \(error)")
    }
}
```

## CSV Structure

### Required Fields
- `title` - Name of the action (REQUIRED)

### Optional Fields
- `description` - Detailed description
- `notes` - Free-form notes
- `duration_minutes` - How long the action took (0 = not tracked)
- `start_time` - When it occurred (ISO 8601 format: `2025-11-06T07:00:00Z`)
  - **Empty = auto-assigned to current time**

### Measurements (up to 3)
- `measure_1_unit`, `measure_1_value`
- `measure_2_unit`, `measure_2_value`
- `measure_3_unit`, `measure_3_value`

**Units must match exactly** (check `available_measures.csv`)

### Goal Contributions (up to 3)
- `goal_1_title`
- `goal_2_title`
- `goal_3_title`

**Titles must match exactly** (check `available_goals.csv`)

## Date Format

**ISO 8601**: `2025-11-06T07:00:00Z`

Generate in Excel: `=TEXT(A2,"YYYY-MM-DD")&"T"&TEXT(A2,"HH:MM:SS")&"Z"`

Or leave empty to auto-assign current date/time.

## Error Handling

### Common Errors

**Missing title**:
```
Row 5: Missing required field 'title'
```

**Invalid unit**:
```
Row 7: Measure 'kilometers' not found. Available: km, miles, m, minutes, hours
```

**Invalid goal title**:
```
Row 9: Goal 'Spring into Runing' not found. Did you mean 'Spring into Running'?
```

**Invalid date**:
```
Row 12: Invalid date '2025/11/06'. Use ISO 8601: 2025-11-06T07:00:00Z
```

## Duplicate Detection

If multiple rows have identical data (including empty dates), you'll see:

```
⚠️ Warning: Detected 3 potential duplicate groups
```

**Current behavior**: Imports all rows as separate actions.

**Future enhancement**: Prompt user to choose "Add all" or "Add one per unique set"

## Export Existing Actions

```swift
let result = try await service.exportActions(to: downloadsDirectory)
```

**Creates**:
- `actions_export.csv` - All existing actions formatted as CSV
- `available_measures.csv` - Reference sheet
- `available_goals.csv` - Reference sheet

Use this for:
- Backup
- Data analysis
- Bulk editing (export → edit → import)

## Limitations

- Maximum 3 measurements per action
- Maximum 3 goal contributions per action
- Goal lookup by title (ambiguous if duplicate titles exist)
- No fuzzy matching (exact string match only)

## Future Enhancements

- [ ] Support unlimited measurements (multi-row CSV or JSON column)
- [ ] Duplicate handling with user confirmation
- [ ] Fuzzy matching with suggestions
- [ ] Validate before import (dry-run mode)
- [ ] Progress reporting for large imports
- [ ] Export filled template (all existing actions)
