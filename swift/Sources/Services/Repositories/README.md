# Repository Layer

**Created**: 2025-11-08
**Purpose**: Read coordinators for all domain entities

## Overview

Repositories handle **read operations** (queries, existence checks, error mapping).
Coordinators handle **write operations** (create, update, delete).

This separation provides:
- ✅ Centralized query logic (DRY principle)
- ✅ Existence checks (prevent duplicates)
- ✅ User-friendly error messages (DatabaseError → ValidationError)
- ✅ Testability (mock repositories, not database)
- ✅ Clean separation (ViewModels don't access database directly)

## Repository Pattern

Each repository provides:

1. **Read Operations** - Domain-specific queries
   ```swift
   func fetchAll() async throws -> [Entity]
   func fetchByXYZ() async throws -> [Entity]
   ```

2. **Existence Checks** - Used by Coordinators before writes
   ```swift
   func existsByTitle(_ title: String) async throws -> Bool
   func exists(_ id: UUID) async throws -> Bool
   ```

3. **Error Mapping** - Translate database errors to domain errors
   ```swift
   func mapDatabaseError(_ error: Error) -> ValidationError
   ```

## Repository List

| Repository | Entity | Complexity | Priority |
|------------|--------|------------|----------|
| **GoalRepository** | Goal + Expectation + Measures + Relevances | High | 1 (solves duplicate bug) |
| **ActionRepository** | Action + MeasuredActions + Contributions | High | 2 |
| **PersonalValueRepository** | PersonalValue | Low | 3 |
| **TimePeriodRepository** | TimePeriod + GoalTerm | Medium | 4 |

## Usage Pattern

### ViewModels Use Repository for Reads

```swift
@Observable
@MainActor
public final class GoalFormViewModel {
    @ObservationIgnored
    @Dependency(\.goalRepository) var goalRepository

    func loadActiveGoals() async {
        activeGoals = try await goalRepository.fetchActiveGoals()
    }
}
```

### Coordinators Use Repository for Existence Checks

```swift
@MainActor
public final class GoalCoordinator {
    private let repository: GoalRepository

    func create(from formData: GoalFormData) async throws -> Goal {
        // Check for duplicates
        if try await repository.existsByTitle(formData.title) {
            throw ValidationError.duplicateRecord("Goal '\(formData.title)' already exists")
        }

        // Create the goal...
    }
}
```

## Implementation Status

- [ ] GoalRepository - TODO: Phase 1
- [ ] ActionRepository - TODO: Phase 2
- [ ] PersonalValueRepository - TODO: Phase 3
- [ ] TimePeriodRepository - TODO: Phase 4

## See Also

- `../Coordinators/` - Write operations
- `../Validation/` - Validation layer
- `../../App/Views/Queries/` - Query logic (will be moved here)
- `../../docs/ARCHITECTURE_AS_IS_VS_PRINCIPLED.md` - Architecture analysis
