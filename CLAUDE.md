# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ten Week Goal App - A personal goal tracking system built with layered architecture. Tracks Actions (what you do) against Goals (what you want to achieve) using SQLite storage with a clear separation between domain logic and infrastructure.

## Essential Commands

### Testing
```bash
# Run all tests
pytest tests/

# Run specific test file
pytest tests/test_actions.py

# Run single test
pytest tests/test_actions.py::test_action_creation_with_description

# Verbose output
pytest tests/ -v
```

### Database Operations
```python
# Initialize database (creates all tables from schemas)
from politica.sqlite_connection import init_db
init_db()

# Database location
# politica/data_storage/application_data.db

# Schema files location
# politica/schemas/*.sql
```


## Architecture: Aristotelian Layers

The codebase uses a philosophical naming convention with strict separation of concerns:

```
categoriae/    - Domain Entities ("What things ARE")
ethica/        - Business Logic ("What SHOULD happen")
rhetorica/     - Translation Layer ("How to communicate between layers")
politica/      - Infrastructure ("How things are DONE")
config/        - Configuration and logging
tests/         - Test suite
```

### Layer Responsibilities & Dependencies

| Layer | Responsibility | Knows About | Does NOT Know |
|-------|---------------|-------------|---------------|
| **categoriae/** | Define entities (Action, Goal, SmartGoal) | Its own structure only | Storage, other entities, business rules |
| **ethica/** | Business rules, calculations, validation | categoriae entities | Storage implementation, how data is fetched |
| **rhetorica/** | Translation between layers | categoriae + politica | SQL details, connection management |
| **politica/** | Infrastructure: DB ops, connections | Generic dicts/SQL only | Domain entities (Action, Goal) |
| **config/** | Paths, logging, settings | TOML config file | Application logic |

### Critical Architecture Rules

1. **politica/** MUST NOT import from categoriae/ or ethica/
   - Works only with generic dicts, List[dict], primitives
   - All SQL and database logic stays here

2. **rhetorica/** is the ONLY layer that imports from both categoriae and politica
   - Translates between domain objects and storage dicts
   - Implements _to_dict() and _from_dict() methods

3. **categoriae/** entities are pure domain models
   - No database knowledge
   - Can have is_valid() methods for self-validation
   - Should read like dictionary definitions

4. **ethica/** contains stateless business logic functions
   - Takes domain entities as input
   - Returns calculated values or validation results
   - Works same whether data from DB, API, or tests

## Key Files & Patterns

### Domain Entities (categoriae/)
- `actions.py`: Action class with optional measurements, timing
- `goals.py`: Goal hierarchy (ThingIWant → Goal → SmartGoal)

### Business Logic (ethica/)
- `progress.py`: calculate_goal_metrics() - aggregates actions against goals
  - Returns GoalProgress dataclass with derived properties

### Translation Layer (rhetorica/)
- `storage_service.py`: StorageService base class
  - ActionStorageService: translates Action ↔ dict
  - GoalStorageService: translates Goal ↔ dict
  - Pattern: store_single_instance(), store_many_instances()

### Infrastructure (politica/)
- `storage.py`: Generic database operations
  - Public API: query(), insert(), archive_and_delete()
  - Private primitives: _execute_query(), _execute_write(), _delete_unsafe()
  - Safety: requires filters for deletes, automatic archiving

- `sqlite_connection.py`: Connection management
  - get_db_connection(): context manager for transactions
  - build_where_clause(), build_set_clause(): SQL builders
  - init_db(): loads all schemas from politica/schemas/

### Configuration
- `config/config.toml`: Paths for storage, schemas, logs
- `config/settings.py`: Loads TOML, exposes constants
- `config/logging_setup.py`: Centralized logging configuration

## Database Schema

Tables are defined in `politica/schemas/`:
- `actions.sql`: description, log_time, measurements (JSON), start_time, duration_minutes
- `goals.sql`: description, target_value, unit, start_date, end_date, relevance, actionability
- `archive.sql`: Stores deleted/updated records for audit trail

## Testing Philosophy

Follow Test-Driven Development (TDD):
1. Write test first (it should fail)
2. Write minimal code to pass test
3. Refactor while tests pass
4. Repeat

**Test Structure:** One test file per source file
- Tests go through correct layer (use StorageService, not raw politica)
- Use pytest fixtures for test isolation
- Test edge cases, validation logic, calculations

## Common Patterns

### Adding a New Entity Type

1. **Define entity** in categoriae/:
```python
class MyEntity:
    def __init__(self, required_field: str):
        self.required_field = required_field

    def is_valid(self) -> bool:
        return bool(self.required_field)
```

2. **Create schema** in politica/schemas/my_entity.sql
3. **Create StorageService** in rhetorica/:
```python
class MyEntityStorageService(StorageService):
    table_name = 'my_entities'

    def _to_dict(self, entity: MyEntity) -> dict:
        return {'required_field': entity.required_field}

    def _from_dict(self, data: dict) -> MyEntity:
        return MyEntity(required_field=data['required_field'])
```

4. **Write tests** in tests/test_my_entity.py

### Working with Storage

```python
# Save entities
from rhetorica.storage_service import ActionStorageService
from categoriae.actions import Action

action = Action("Ran 5km")
action.measurements = {"distance_km": 5.0}

service = ActionStorageService()
service.store_single_instance(action)

# Query database (generic dict-based)
from politica.storage import query

results = query('actions', filters={'description': 'Ran 5km'})
# Returns: List[dict]
```

### Error Handling & Logging

All modules use centralized logging:
```python
from config.logging_setup import get_logger
logger = get_logger(__name__)

logger.debug("Detailed info for debugging")
logger.info("Normal operation messages")
logger.warning("Something unexpected but handled")
logger.error("Error that needs attention")
```

Logs are written to `logs/` directory (configured in config.toml)

## Development Workflow

1. **Check database exists**: Look for `politica/data_storage/application_data.db`
2. **If missing, initialize**: Call `init_db()` from sqlite_connection.py
3. **Make changes**: Follow layer boundaries strictly
4. **Run tests**: `pytest tests/` before committing
5. **Check git status**: Before creating commits

## Important Notes for AI Collaboration

- **Author new code**: Add "Written by Claude Code on {date}" in docstrings
- **Large data processing**: Write to log files, not stdout
- **Progress indicators**: Use progress bars or periodic status updates for long operations
- **Jupyter notebooks**: Check cell order when working with .ipynb files
- **Layer violations**: If you catch yourself importing from categoriae in politica, STOP and refactor

## Future Extensions (Not Yet Implemented)

- `_from_dict()` methods in StorageService subclasses (for retrieval)
- CLI interface for goal tracking
- Web UI/API layer (would go in interfaces/)
- Update/replace operations in storage.py

## References

- Architecture decisions: `.documentation/architecture_decisions.md`
- Testing workflow: `.documentation/testing_workflow.md`
- Initial reflections: `.documentation/initial_reflections.md`
