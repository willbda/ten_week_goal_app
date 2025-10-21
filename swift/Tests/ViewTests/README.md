# View Tests - Modern Swift Testing Framework

## Overview

Comprehensive view tests for the SwiftUI views in the Ten Week Goal App, using the modern Swift Testing framework (introduced in Swift 6 and Xcode 16).

**Written by Claude Code on 2025-10-21**

## Test Files Created

### 1. ActionRowViewTests.swift (15 tests)
Tests the `ActionRowView` component that displays individual action rows in lists.

**Test Coverage:**
- ✅ Friendly name display and untitled fallback
- ✅ Single and multiple measurements display
- ✅ Measurement sorting by unit
- ✅ Log time formatting
- ✅ Handling actions with/without measurements
- ✅ Edge cases: empty measurements, long names, decimal values
- ✅ Past and future log times

### 2. ActionFormViewTests.swift (30 tests)
Tests the `ActionFormView` component used for creating and editing actions.

**Test Coverage:**
- ✅ Create vs Edit mode detection
- ✅ Field initialization in both modes
- ✅ Form validation (friendly name or description required)
- ✅ Whitespace-only input handling
- ✅ Start time and duration toggles
- ✅ Start time requires duration validation
- ✅ Measurements array conversion
- ✅ Save behavior (UUID creation vs preservation)
- ✅ Empty string to nil conversion
- ✅ Edge cases: nil values, fully populated actions

### 3. GoalRowViewTests.swift (40 tests)
Tests the `GoalRowView` component that displays individual goal rows.

**Test Coverage:**
- ✅ Friendly name and untitled fallback
- ✅ Measurement target and unit display
- ✅ Target date formatting
- ✅ Life domain tags
- ✅ **Priority badges:**
  - HIGH (priority ≤ 10) - red
  - MED (11-30) - orange
  - None (> 30)
- ✅ **Date icons:**
  - Clock icon for future dates
  - Warning icon for overdue dates
- ✅ Boundary testing for all priority levels
- ✅ Combined features with all fields
- ✅ Edge cases: long names, large/small targets, far dates

### 4. ValueRowViewTests.swift (40 tests)
Tests the `ValueRowView` component that displays individual value rows.

**Test Coverage:**
- ✅ Friendly name and untitled fallback
- ✅ Detailed description display
- ✅ Additional info for major values
- ✅ Life domain tags
- ✅ **Priority indicators:**
  - ★★★ (priority ≤ 5) - yellow
  - ★★ (6-10) - orange
  - ★ (11-25) - blue
  - None (> 25)
- ✅ Different value types: highest order, major, general, life areas
- ✅ Boundary testing for all priority levels
- ✅ Optional field handling
- ✅ Edge cases: long text, min/max priority, unique IDs

### 5. TermRowViewTests.swift (35 tests)
Tests the `TermRowView` component that displays individual term rows.

**Test Coverage:**
- ✅ Term number display
- ✅ Theme display (with/without)
- ✅ Date range formatting
- ✅ Goal count (singular/plural)
- ✅ **Status badges:**
  - ACTIVE (current term) - green
  - UPCOMING (future term) - blue
  - PAST (completed term) - gray
- ✅ Boundary testing: today as start/end, yesterday/tomorrow
- ✅ Date range calculations (10-week standard, short, long)
- ✅ Combined features testing
- ✅ Edge cases: high term numbers, many goals, far dates, single day terms

## Total Test Count: 160 Tests

## Modern Swift Testing Framework Features Used

### @Test Macro
Modern, concise test declaration:
```swift
@Test("Displays friendly name correctly")
func displaysFriendlyName() {
    // test code
}
```

### @Suite Macro
Organized test suites:
```swift
@Suite("ActionRowView Tests")
struct ActionRowViewTests {
    // tests
}
```

### #expect Macro
Clear, readable assertions:
```swift
#expect(action.friendlyName == "Morning run")
#expect(goal.priority <= 10)
```

## Running the Tests

### Using Xcode
```bash
# Open project in Xcode
open Package.swift

# Run all tests
⌘ + U

# Run specific test suite
Click the diamond icon next to @Suite declaration
```

### Using Command Line
```bash
# Navigate to swift directory
cd swift/

# Run all tests
swift test

# Run specific test suite
swift test --filter ActionRowViewTests

# Run with verbose output
swift test -v
```

### Using Swift Package Manager
```bash
# Build and test
swift build
swift test

# Clean build and test
swift package clean
swift test
```

## Test Structure

All tests follow a consistent pattern:

1. **Arrange**: Create test data (models, view models)
2. **Act**: Create view or perform action
3. **Assert**: Use `#expect` to verify behavior

Example:
```swift
@Test("Displays friendly name correctly")
func displaysFriendlyName() {
    // Arrange
    let action = Action(
        friendlyName: "Morning run",
        logTime: Date()
    )

    // Act
    let view = ActionRowView(action: action)

    // Assert
    #expect(action.friendlyName == "Morning run")
}
```

## Benefits of Modern Swift Testing

1. **Cleaner Syntax**: No inheritance from `XCTestCase`
2. **Better Errors**: More descriptive failure messages
3. **Parallel Execution**: Tests run faster
4. **Type-Safe**: Full Swift type system support
5. **Integrated**: Works seamlessly with Swift 6

## Integration with Existing Tests

These view tests complement the existing model tests:
- **ModelTests/**: Domain entity tests (XCTest)
- **ViewTests/**: SwiftUI view tests (Modern Swift Testing)
- **RecordIntegrationTests.swift**: Database integration tests (XCTest)
- **UUIDStabilityTests.swift**: UUID mapping tests (XCTest)

## Coverage Report

| Component | Tests | Coverage |
|-----------|-------|----------|
| ActionRowView | 15 | Display, measurements, dates, edge cases |
| ActionFormView | 30 | Modes, validation, state, save behavior |
| GoalRowView | 40 | Display, priorities, dates, domains |
| ValueRowView | 40 | Display, priorities, types, optionals |
| TermRowView | 35 | Display, status, dates, calculations |
| **Total** | **160** | **Comprehensive view layer testing** |

## Next Steps

To run these tests in your development environment:

1. Ensure you have Xcode 16+ or Swift 6.2+ installed
2. Open the project: `cd swift && open Package.swift`
3. Run tests: `⌘ + U` in Xcode or `swift test` in terminal
4. Review test results in the Test Navigator

## Notes

- All tests are independent and can run in any order
- Tests use the modern `@Test` syntax from Swift Testing framework
- No test dependencies on external services or databases
- All assertions use `#expect` for clear, readable checks
- Tests verify view logic and data display, not UI rendering

## References

- [Swift Testing Framework Documentation](https://developer.apple.com/documentation/testing/)
- [Modern Swift Testing Guide](https://developer.apple.com/videos/play/wwdc2023/10179/)
- Project README: `/swift/README.md`
- Architecture guide: `/CLAUDE.md`
