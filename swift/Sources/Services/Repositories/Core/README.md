# Repository Core Infrastructure

## Overview

This directory contains the shared infrastructure for the generic repository pattern, designed to reduce code duplication across repositories while maintaining flexibility for different query strategies.

## Architecture

```
Core/
├── RepositoryProtocols.swift    # Protocol hierarchy defining repository contracts
├── BaseRepository.swift         # Base class with common functionality
├── QueryStrategies.swift        # Query pattern protocols (JSON, SQL, Builder)
└── ExportSupport.swift          # Shared export utilities (date filtering, CSV/JSON)
```

## Key Concepts

### 1. Protocol Hierarchy

The system uses a protocol-based design that allows mixing capabilities:

- **Repository**: Base protocol with core operations (fetchAll, exists, fetchForExport)
- **Capability Protocols**: Add specific behaviors
  - `TitleBasedRepository`: Adds title-based existence checks
  - `DateFilterableRepository`: Adds date range queries
  - `RelationshipRepository`: Adds related entity fetching
  - `ManyToManyRepository`: Manages junction table relationships

### 2. Query Strategies

Three proven patterns are supported:

- **JSONAggregationStrategy**: For complex 1:many relationships (Goals, Actions)
- **SQLMacroStrategy**: For simple queries with #sql macro (PersonalValues)
- **QueryBuilderStrategy**: For simple JOINs (Terms)

### 3. BaseRepository

Provides shared functionality:
- Error mapping (database errors → user-friendly messages)
- Database read/write wrappers with automatic error handling
- Date parsing and formatting helpers
- Date filter WHERE clause builder

## Usage Examples

### Creating a New Repository

```swift
// 1. Define export type
public struct PersonalValueExport: Codable, Sendable {
    let id: String
    let title: String
    let priority: Int
    // ... other fields
}

// 2. Extend BaseRepository and declare strategies
public final class PersonalValueRepository:
    BaseRepository<PersonalValue, PersonalValueExport>,
    TitleBasedRepository,
    SQLMacroStrategy
{
    // 3. Override required methods
    public override func fetchAll() async throws -> [PersonalValue] {
        try await read { db in  // Uses inherited error wrapper
            try #sql(
                """
                SELECT \(PersonalValue.columns)
                FROM \(PersonalValue.self)
                ORDER BY \(PersonalValue.priority) DESC
                """,
                as: PersonalValue.self
            ).fetchAll(db)
        }
    }

    public override func exists(_ id: UUID) async throws -> Bool {
        try await read { db in
            try CommonFetchRequests.ExistsByIdRequest(
                id: id,
                tableName: "personalValues"
            ).fetch(db)
        }
    }

    public override func fetchForExport(
        from startDate: Date?,
        to endDate: Date?
    ) async throws -> [PersonalValueExport] {
        try await read { db in
            // Use inherited date filter builder
            let filter = DateFilter(startDate: startDate, endDate: endDate)
            let (whereClause, args) = filter.buildWhereClause(dateColumn: "logTime")

            let sql = """
                SELECT * FROM personalValues
                \(whereClause)
                ORDER BY priority DESC
                """

            let rows = try PersonalValue.fetchAll(db, sql: sql, arguments: args)

            // Transform to export format
            return rows.map { row in
                PersonalValueExport(
                    id: row.id.uuidString,
                    title: row.title ?? "",
                    priority: row.priority ?? 0
                )
            }
        }
    }

    // 4. Implement protocol requirements
    public func existsByTitle(_ title: String) async throws -> Bool {
        try await read { db in
            try CommonFetchRequests.ExistsByTitleRequest(
                title: title,
                tableName: "personalValues"
            ).fetch(db)
        }
    }
}
```

### Using Export Utilities

```swift
// Date filtering
let filter = DateFilter(startDate: startDate, endDate: endDate)
let (whereClause, args) = filter.buildWhereClause(dateColumn: "logTime")

// Date formatting for exports
let exportDate = ExportDateFormatter.format(entity.logTime)

// CSV escaping
let csvTitle = CSVEscaper.escape(entity.title)
let csvGoals = CSVEscaper.joinUUIDs(entity.goalIds)

// Filename generation
let filename = ExportFilename.build(prefix: "actions", format: "csv")
// Result: "actions_export_2025-11-15_103045.csv"
```

## Migration Strategy

To migrate an existing repository:

1. **Create parallel implementation**: Name it `{Entity}Repository_v2.swift`
2. **Extend BaseRepository**: Inherit common functionality
3. **Declare strategies**: Choose appropriate query patterns
4. **Override core methods**: Implement entity-specific logic
5. **Test side-by-side**: Ensure feature parity with original
6. **Benchmark performance**: Must be within 5% of original
7. **Switch ViewModels**: Update to use v2 repository
8. **Soak test**: Run for 48 hours before removing old code

## Benefits

- **Code Reduction**: ~40-50% less code per repository
- **Consistency**: Shared error handling and utilities
- **Flexibility**: Mix query strategies as needed
- **Type Safety**: Protocol-based design with compile-time checks
- **Testability**: Shared infrastructure can be tested once
- **Maintainability**: Single source of truth for common patterns

## Performance Considerations

- **BaseRepository.read()**: Adds minimal overhead (~1-2ms)
- **Error mapping**: Happens only on failure (no happy-path impact)
- **Date filtering**: SQL WHERE clause generation is negligible
- **Protocol dispatch**: Swift optimizes protocol witnesses well

## Future Extensions

- **RelationshipSupport.swift**: Advanced relationship management
- **CacheSupport.swift**: Query result caching layer
- **MetricsSupport.swift**: Performance monitoring
- **MigrationSupport.swift**: Schema migration helpers