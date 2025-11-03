# Form Components

Reusable UI components for consistent form styling across the app.

## Purpose

Solve systematic UI inconsistencies by extracting layout logic into shared components.

## Problem Solved

**Before**: Each form reimplemented layout logic, causing:
- TextField alignment issues (ActionFormView: text pushed far right)
- Inconsistent padding (PersonalValuesFormView: centered but cramped)
- Duplicated multi-select logic
- No standard for "add/remove" sections

**After**: Components enforce consistency. Change layout once, all forms benefit.

## Components

### MeasurementInputRow
- **Purpose**: Measure picker + value input + remove button
- **Solves**: Alignment issue where picker pushes TextField too far right
- **Usage**: Actions (measurements), Goals (targets)

### MultiSelectSection
- **Purpose**: Generic multi-select with Toggle bindings
- **Solves**: Duplicated Set<UUID> ↔ Bool binding logic
- **Usage**: Goal contributions, Value alignments

### RepeatingSection
- **Purpose**: Container for dynamic add/remove sections
- **Solves**: Inconsistent "Add" button placement
- **Usage**: Measurements, Targets, any repeating input

### TimingSection
- **Purpose**: Standard when + duration fields
- **Solves**: Inconsistent duration TextField alignment
- **Usage**: Actions, any timestamped entity

## Design Principles

1. **Layout lives in components** (not forms)
2. **Styling is consistent** (font, padding, colors)
3. **Generic where possible** (works with any data type)
4. **Composable** (forms assemble components)

## Usage Pattern

```swift
public struct EntityFormView: View {
    var body: some View {
        FormScaffold(...) {
            DocumentableFields(...)  // Existing
            TimingSection(...)       // New
            RepeatingSection(...) {  // New
                MeasurementInputRow(...)  // New
            }
            MultiSelectSection(...)  // New
        }
    }
}
```

## Files to Refactor

Once components are implemented:
- `ActionFormView.swift` - Use MeasurementInputRow, TimingSection, MultiSelectSection
- `PersonalValuesFormView.swift` - Use standard spacing from components
- `TermFormView.swift` - Already good, may benefit from shared DatePicker styling

## Status

- [ ] MeasurementInputRow - Skeleton created
- [ ] MultiSelectSection - Skeleton created
- [ ] RepeatingSection - Skeleton created
- [ ] TimingSection - Skeleton created
- [ ] Refactor ActionFormView
- [ ] Refactor PersonalValuesFormView
- [ ] Create FormTemplate.swift
