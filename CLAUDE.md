# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ten Week Goal App - A personal goal tracking system built with layered architecture. Tracks Actions (what you do) against Goals (what you want to achieve), defines personal Values (what motivates you), and automatically infers relationships between them using SQLite storage with a clear separation between domain logic and infrastructure.

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
from politica.database import init_db
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
interfaces/    - Presentation Layer ("How users INTERACT")
config/        - Configuration and logging
tests/         - Test suite
```

### Layer Responsibilities & Dependencies

| Layer | Responsibility | Knows About | Does NOT Know |
|-------|---------------|-------------|---------------|
| **categoriae/** | Define entities (Action, Goal, Value, Relationships, Terms) | Its own structure only | Storage, other entities, business rules |
| **ethica/** | Business rules, calculations, validation, inference | categoriae entities | Storage implementation, how data is fetched |
| **rhetorica/** | Translation between layers, polymorphic storage | categoriae + politica | SQL details, connection management |
| **politica/** | Infrastructure: DB ops, connections, schemas | Generic dicts/SQL only | Domain entities (Action, Goal, Value) |
| **interfaces/** | Presentation: CLI, Web, API | ethica + rhetorica | Business logic implementation, SQL |
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
- `values.py`: Values hierarchy (Incentive → Value → MajorValue → HighestOrderValue)
  - LifeArea: Life domains (distinct from values)
  - PriorityLevel: Validated 1-100 priority scoring
- `relationships.py`: Derived relationship entities
  - ActionGoalRelationship: Links actions to goals with match strength
  - GoalValueAlignment: Links goals to values (future)
- `terms.py`: Time period entities (TenWeekTerm, LifeTime)

### Business Logic (ethica/)
- `progress.py`: Legacy progress calculations (deprecated, use progress_aggregation.py)
- `progress_aggregation.py`: **AUTHORITATIVE** progress calculations
  - aggregate_goal_progress(): Calculate metrics for single goal
  - aggregate_all_goals(): Batch processing for multiple goals
  - get_progress_summary(): Summary statistics
  - Returns GoalProgress dataclass with derived properties (@property methods)
- `progress_matching.py`: Stateless matching functions
  - match_by_time_period(): Checks if action falls within goal timeframe
  - match_by_unit(): Verifies unit compatibility between action and goal
  - match_by_description(): Fuzzy string matching for descriptions
- `inference_service.py`: Service orchestrator for relationship detection
  - infer_all_relationships(): Batch processing of all actions × goals
  - infer_for_action(): Realtime matching for single action
  - Returns ActionGoalRelationship objects with match scores

### Translation Layer (rhetorica/)
- `storage_service.py`: StorageService base class with polymorphic support
  - ActionStorageService: translates Action ↔ dict
  - GoalStorageService: translates Goal ↔ dict
  - Pattern: store_single_instance(), store_many_instances(), save(), update_instance(), get_by_id()
  - Polymorphism: Automatically saves/retrieves correct subclass types
- `values_storage_service.py`: Values-specific storage (Phase 1)
  - ValuesStorageService: Handles Values hierarchy polymorphism
  - Type-specific factory methods: create_major_value(), create_highest_order_value(), etc.
  - Constructor registry pattern eliminates if-elif chains
  - Filtering: get_all(type_filter='major', domain_filter='Health')
- `values_orchestration_service.py`: Business operations coordinator (Phase 1)
  - Wraps storage with result objects pattern
  - Returns ValueOperationResult instead of raising exceptions
  - Allows interfaces to handle errors appropriately
  - Domain validation happens inline (PriorityLevel constructor)

### Infrastructure (politica/)
- `database.py`: Generic database operations
  - Public API: query(), insert(), archive_and_delete()
  - Private primitives: _execute_query(), _execute_write(), _delete_unsafe()
  - Safety: requires filters for deletes, automatic archiving
  - get_db_connection(): context manager for transactions
  - build_where_clause(), build_set_clause(): SQL builders
  - init_db(): loads all schemas from politica/schemas/

### Presentation Layer (interfaces/)
**CLI Interface** (`interfaces/cli/`)
- `cli.py`: Command-line interface (orchestrator only)
  - show_progress(): Display goal progress dashboard
  - **values commands (Phase 1)**: Type-specific value management
    - values create-major: Create actionable major value with alignment guidance
    - values create-highest-order: Create philosophical highest order value
    - life-areas create: Create organizational life area (not a value)
    - values create-general: Create aspirational general value
    - values list [--type] [--domain]: List/filter values
    - values show <id>: Display value details
    - values edit <id>: Update value properties
    - values delete <id>: Remove value
  - Pure orchestration: fetch → calculate → display
  - No business logic, no formatting logic
- `cli_formatters.py`: Presentation formatting functions
  - render_progress_bar(): Unicode progress bars
  - render_progress_metrics(): Format metrics with completion status
  - render_action_list(): Format action details for verbose mode
  - render_timeline(): Format date ranges
  - render_value_list(): Table format for values display
  - render_value_detail(): Full value with alignment guidance
  - Pure presentation - no calculations
- `cli_config.py`: CLI configuration constants
  - DisplayConfig: Bar widths, truncation limits, symbols
  - FilterConfig: Default filter settings
  - ColorConfig: Color scheme (stub for future)

**Flask API** (`interfaces/flask/`)
- `flask_main.py`: Application factory pattern
  - create_app(): Factory function with blueprint registration
  - Entry point: `python interfaces/flask/flask_main.py`
  - Serves API on http://localhost:5001
- `routes/api/__init__.py`: API blueprint registration
- `routes/api/goals.py`: Goals CRUD + progress endpoints
  - GET /api/goals - List with filters (has_dates, has_target)
  - GET /api/goals/<id> - Single goal detail
  - POST /api/goals - Create new goal
  - PUT /api/goals/<id> - Update goal
  - DELETE /api/goals/<id> - Delete with archiving
  - GET /api/goals/<id>/progress - Detailed progress metrics
- `routes/api/actions.py`: Actions CRUD + matching endpoints
  - GET /api/actions - List with filters (has_measurements, date range)
  - GET /api/actions/<id> - Single action detail
  - POST /api/actions - Create new action
  - PUT /api/actions/<id> - Update action
  - DELETE /api/actions/<id> - Delete with archiving
  - GET /api/actions/<id>/goals - Goals matched to action
- `routes/api/values.py`: Values CRUD with polymorphism
  - GET /api/values - List with filters (type, domain)
  - GET /api/values/<id> - Single value detail
  - POST /api/values - Create with type-specific handling
  - PUT /api/values/<id> - Update value
  - DELETE /api/values/<id> - Delete with archiving
- `routes/api/terms.py`: Terms CRUD + lifecycle management
  - GET /api/terms - List with status filters
  - GET /api/terms/<id> - Single term with metrics
  - GET /api/terms/active - Current active term
  - POST /api/terms - Create new term
  - PUT /api/terms/<id> - Update term
  - DELETE /api/terms/<id> - Delete with archiving
  - POST /api/terms/<id>/goals - Add goal to term
  - DELETE /api/terms/<id>/goals/<goal_id> - Remove goal from term
  - GET /api/terms/<id>/progress - Detailed term progress
- `templates/api_reference.html`: API documentation page

**Documentation**
- **docs/VALUES_QUICKSTART.md**: Values CLI usage guide (Phase 1)
  - Comprehensive examples for each value type
  - Copy-paste commands ready to use
  - Explains Values vs Life Areas distinction
  - Priority guidance (1-100 scale)

### Configuration
- `config/config.toml`: Paths for storage, schemas, logs
- `config/settings.py`: Loads TOML, exposes constants
- `config/logging_setup.py`: Centralized logging configuration

## Database Schema

Tables are defined in `politica/schemas/`:
- `actions.sql`: description, log_time, measurements (JSON), start_time, duration_minutes
- `goals.sql`: description, measurement_target, measurement_unit, start_date, end_date, how_goal_is_relevant, how_goal_is_actionable, expected_term_length, created_at
- `values.sql`: Polymorphic storage with value_name, value_type for class hierarchy, life_domain, priority, alignment_guidance
- `terms.sql`: term_number, start_date, end_date, theme, term_goal_ids (JSON array), reflection, created_at, updated_at
- `action_goal_progress.sql`: Cached relationship projections (action_id, goal_id, match_strength, match_reasons JSON)
- `archive.sql`: Stores deleted/updated records for audit trail
- `schema.sql`: Main schema file

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

## CLI and Web Usage

### CLI Commands
```bash
# Show progress for all goals
python interfaces/cli.py show-progress

# Show progress with detailed action listings
python interfaces/cli.py show-progress -v
```

### Web Interface
```bash
# Install web dependencies
pip install -r requirements_web.txt

# Start Flask development server
python interfaces/web_app.py

# Visit http://localhost:5000
```

See [interfaces/WEB_README.md](interfaces/WEB_README.md) for detailed web documentation.

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
from rhetorica.storage_service import ActionStorageService, ValuesStorageService
from categoriae.actions import Action
from categoriae.values import MajorValue, LifeArea, PriorityLevel

action = Action("Ran 5km")
action.measurements = {"distance_km": 5.0}

service = ActionStorageService()
service.store_single_instance(action)

# Polymorphic storage preserves types
value = MajorValue(
    description="Health and vitality",
    life_area=LifeArea.HEALTH,
    priority=PriorityLevel(85)
)
values_service = ValuesStorageService()
values_service.store_single_instance(value)
# Retrieves as MajorValue, not base Value class

# Query database (generic dict-based)
from politica.database import query

results = query('actions', filters={'description': 'Ran 5km'})
# Returns: List[dict]
```

### Running Inference and Progress Calculation

```python
# Automatic action-goal matching
from ethica.inference_service import InferenceService
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary

# Get all goals and actions
from rhetorica.storage_service import GoalStorageService, ActionStorageService
goals = GoalStorageService().get_all()
actions = ActionStorageService().get_all()

# Infer relationships
service = InferenceService()
all_matches = service.infer_all_relationships()
# Returns: List[ActionGoalRelationship]

# Calculate progress (AUTHORITATIVE method)
all_progress = aggregate_all_goals(goals, all_matches)
# Returns: List[GoalProgress] with derived properties

# Get summary statistics
summary = get_progress_summary(all_progress)
# Returns: dict with total_goals, complete_goals, avg_completion_percent, etc.

# Access derived properties
for progress in all_progress:
    print(f"{progress.goal.description}: {progress.percent:.1f}%")
    if progress.is_complete:
        print("  ✓ Complete!")
    print(f"  Remaining: {progress.remaining} {progress.unit}")
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
2. **If missing, initialize**: Call `init_db()` from politica.database
3. **Make changes**: Follow layer boundaries strictly
4. **Run tests**: `pytest tests/` before committing (currently 65/65 passing: 48 core + 17 values)
5. **Check git status**: Before creating commits

## Important Notes for AI Collaboration

- **Author new code**: Add "Written by Claude Code on {date}" in docstrings
- **Large data processing**: Write to log files, not stdout
- **Progress indicators**: Use progress bars or periodic status updates for long operations
- **Jupyter notebooks**: Check cell order when working with .ipynb files
- **Layer violations**: If you catch yourself importing from categoriae in politica, STOP and refactor

## Recent Additions

**2025-10-14: Flask API Migration**
- ✅ Modular Flask API with Blueprint organization
- ✅ RESTful endpoints for Goals, Actions, Values, Terms
- ✅ Application factory pattern (flask_main.py)
- ✅ Serialization infrastructure (rhetorica/serializers.py)
- ✅ Field name standardization (logtime → log_time, name → value_name)
- ✅ Clean imports (removed unnecessary sys.path manipulation)
- ✅ 8 new term-action filtering tests (90 total passing)

**2025-10-13: Phase 1 Complete**
- ✅ CLI interface with formatted progress display
- ✅ Values system with polymorphic storage
- ✅ JSON API endpoints for integrations
- ✅ Progress aggregation business logic (ethica/progress_aggregation.py)
- ✅ Presentation layer separation (interfaces/ directory)

## Future Extensions (Not Yet Implemented)

- GoalValueAlignment inference (connecting goals to values)
- Flask API integration tests
- Web UI frontend (HTML/JS consuming Flask API)
- Authentication for API
- Bulk import from CSV/JSON
- Export functionality (PDF, CSV)
- Charts and visualizations for progress over time

## References

- Architecture decisions: `.documentation/architecture_decisions.md`
- Testing workflow: `.documentation/testing_workflow.md`
- Initial reflections: `.documentation/initial_reflections.md`
