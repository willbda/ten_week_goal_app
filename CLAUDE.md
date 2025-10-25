# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ten Week Goal App - A personal goal tracking system built with layered architecture. Tracks Actions (what you do) against Goals (what you want to achieve), defines personal Values (what motivates you), and automatically infers relationships between them using SQLite storage with a clear separation between domain logic and infrastructure.

## Project Structure (Multi-Language)

```
ten_week_goal_app/
├── python/         # Python implementation
│   ├── categoriae/ # Domain entities
│   ├── ethica/     # Business logic
│   ├── rhetorica/  # Translation layer
│   ├── politica/   # Infrastructure
│   ├── interfaces/ # CLI and Flask
│   └── tests/      # Python tests
├── swift/          # Swift implementation (in development)
│   ├── Sources/    # Swift source code
│   └── Tests/      # Swift tests
├── shared/         # Shared between languages
│   └── schemas/    # Database schemas
└── .env           # Environment variables (SECRET_KEY, etc)
```

## Essential Commands

### Testing
```bash
# Navigate to Python directory first
cd python/

# Run all tests
pytest tests/

# Run specific test file
pytest tests/test_actions.py

# Verbose output
pytest tests/ -v
```

### Database Operations
```python
# From python/ directory
from politica.database import init_db
init_db()

# Database location
# python/politica/data_storage/application_data.db

# Schema files location
# shared/schemas/*.sql
```

### Running Flask App
```bash
# From project root (recommended)
python run_flask.py
# OR
flask run  # Uses .flaskenv + .env

# From python/ directory (alternative)
cd python/
python interfaces/flask/app.py
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
- `goals.py`: Goal hierarchy (ThingIWant → Goal → Milestone → SmartGoal)
  - Goal: General objective with optional measurements
  - Milestone: Point-in-time checkpoint (uses end_date as target)
  - SmartGoal: Fully validated SMART goal with all fields required
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
  - GoalStorageService: polymorphic Goal ↔ dict (Goal/Milestone/SmartGoal)
    - Uses `goal_type` field for class identification
    - CLASS_MAP pattern for dynamic instantiation
  - Pattern: store_single_instance(), store_many_instances(), save(), update_instance(), get_by_id()
  - Polymorphism: Automatically saves/retrieves correct subclass types
- `values_storage_service.py`: Values-specific storage (Phase 1)
  - ValuesStorageService: Handles Values hierarchy polymorphism
  - Type-specific factory methods: create_major_value(), create_highest_order_value(), etc.
  - Constructor registry pattern eliminates if-elif chains
  - Filtering: get_all(type_filter='major', domain_filter='Health')

### Infrastructure (politica/)
- `database.py`: Generic database operations
  - Public API: query(), insert(), archive_and_delete()
  - Private primitives: _execute_query(), _execute_write(), _delete_unsafe()
  - Safety: requires filters for deletes, automatic archiving
  - get_db_connection(): context manager for transactions
  - build_where_clause(), build_set_clause(): SQL builders
  - init_db(): loads all schemas from shared/schemas/

### Presentation Layer (interfaces/)
**CLI Interface** (`interfaces/cli/`) - **Refactored 2025-10-15**
- `cli.py`: Command-line interface (1,287 lines, 25 commands)
  - **Architecture**: Mirrors Flask API pattern (storage services → serialization → display)
  - **Action commands** (6): create, list, show, edit, delete, goals
  - **Goal commands** (6): create, list, show, edit, delete, progress
  - **Term commands** (7): create, list, show, current, edit, add-goal, remove-goal
  - **Value commands** (5): create (consolidated with --type flag), list, show, edit, delete
  - **Progress command** (1): show-progress with --verbose option
  - Pure orchestration: Uses storage services directly (no orchestration layer)
  - Try/except error handling throughout (like Flask API)
- `cli_utils.py`: CLI-specific helpers (181 lines)
  - parse_json_arg(): Parse JSON from command line arguments
  - parse_datetime_arg(): Parse ISO datetime strings
  - confirm_action(): Yes/no prompts for destructive operations
  - Formatting helpers: format_success(), format_error(), format_table_row(), truncate()
- `cli_formatters.py`: Terminal presentation formatting
  - render_progress_bar(): Unicode progress bars
  - render_progress_metrics(): Format metrics with completion status
  - render_action_list(): Format action details for verbose mode
  - render_timeline(): Format date ranges
  - render_value_list(): Table format for values display
  - render_value_detail(): Full value with alignment guidance
  - Pure presentation - no calculations

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

Tables are defined in `shared/schemas/`:
- `actions.sql`: description, log_time, measurements (JSON), start_time, duration_minutes
- `goals.sql`: description, measurement_target, measurement_unit, start_date, target_date, how_goal_is_relevant, how_goal_is_actionable, expected_term_length, created_at
- `values.sql`: Polymorphic storage with common_name, incentive_type for class hierarchy, life_domain, priority, alignment_guidance
- `terms.sql`: term_number, start_date, target_date, theme, term_goals_by_id (JSON array), reflection, created_at, updated_at
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

## CLI and API Usage

### CLI Commands ( - 25 commands)
```bash
# Actions (6 commands)
python interfaces/cli/cli.py action create "Description" [--measurements JSON] [--duration MINS]
python interfaces/cli/cli.py action list [--from DATE] [--to DATE] [--has-measurements]
python interfaces/cli/cli.py action show ID
python interfaces/cli/cli.py action edit ID [--description STR] [--measurements JSON]
python interfaces/cli/cli.py action delete ID [--force]
python interfaces/cli/cli.py action goals ID  # Show goals for action

# Goals (6 commands)
python interfaces/cli/cli.py goal create "Description" [--unit STR] [--target NUM] [--start-date DATE]
python interfaces/cli/cli.py goal list [--has-dates] [--has-target]
python interfaces/cli/cli.py goal show ID
python interfaces/cli/cli.py goal edit ID [--description STR] [--unit STR] [--target NUM]
python interfaces/cli/cli.py goal delete ID [--force]
python interfaces/cli/cli.py goal progress ID  # Show progress metrics

# Terms (7 commands)
python interfaces/cli/cli.py term create --number NUM --start DATE [--theme STR]
python interfaces/cli/cli.py term list [--status active|upcoming|complete]
python interfaces/cli/cli.py term show ID
python interfaces/cli/cli.py term current  # Show active term
python interfaces/cli/cli.py term edit ID [--theme STR] [--reflection STR]
python interfaces/cli/cli.py term add-goal TERM_ID GOAL_ID
python interfaces/cli/cli.py term remove-goal TERM_ID GOAL_ID

# Values (5 commands - consolidated)
python interfaces/cli/cli.py value create "Name" "Description" --type TYPE [--domain STR] [--priority NUM]
python interfaces/cli/cli.py value list [--type TYPE] [--domain STR]
python interfaces/cli/cli.py value show ID
python interfaces/cli/cli.py value edit ID [--name STR] [--description STR]
python interfaces/cli/cli.py value delete ID [--force]

# Progress Dashboard (1 command)
python interfaces/cli/cli.py progress [--verbose]
```

### Flask API ( - 27 endpoints)
```bash
# Start Flask development server
python interfaces/flask/flask_main.py

# API available at http://localhost:5001
# Documentation at http://localhost:5001/api
```

**Endpoints:**
- Actions API: 6 endpoints (CRUD + goal matching)
- Goals API: 6 endpoints (CRUD + progress calculation)
- Terms API: 10 endpoints (CRUD + goal assignment + lifecycle)
- Values API: 5 endpoints (CRUD with type filtering)

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

2. **Create schema** in shared/schemas/my_entity.sql
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
4. **Run tests**: `pytest tests/` before committing (currently 90/90 passing)
5. **Check git status**: Before creating commits

## Important Notes for AI Collaboration

- **Author new code**: Add "Written by Claude Code on {date}" in docstrings
- **Large data processing**: Write to log files, not stdout
- **Progress indicators**: Use progress bars or periodic status updates for long operations
- **Jupyter notebooks**: Check cell order when working with .ipynb files
- **Layer violations**: If you catch yourself importing from categoriae in politica, STOP and refactor

## Recent Additions

**2025-10-18: Documentation Reorganization** 📚
- ✅ README structure updated for multi-language project
- ✅ Root README.md: General project overview (architecture philosophy, multi-language structure)
- ✅ python/README.md: Python-specific implementation details
- ✅ Clear documentation hierarchy referencing language-specific guides

**2025-10-17: Goal Hierarchy Polymorphism + Project Reorganization** 🎨
- ✅ Full polymorphic support for Goal → Milestone → SmartGoal hierarchy
- ✅ Web UI for Goals management (5 templates, dynamic forms)
- ✅ Flask session configuration with secure SECRET_KEY in .env
- ✅ Project reorganized: python/, swift/, shared/ directories
- ✅ Migrated from .flaskenv to .env (with python-dotenv)
- ✅ Goal API supports type filtering: GET /api/goals?type=SmartGoal
- ✅ Database schema updated with goal_type column

**2025-10-15: CLI Refactor + Cleanup Complete -  System** 🎉
- ✅ Complete CLI rebuild matching Flask API architecture (1,287 lines)
- ✅ 25 commands covering all CRUD operations (Actions, Goals, Terms, Values, Progress)
- ✅ Removed ValuesOrchestrationService layer (uses storage services directly like Flask API)
- ✅ Deleted unused values_orchestration_service.py (259 lines removed)
- ✅ Consolidated value creation (single `create` command with `--type` flag)
- ✅ Consistent try/except error handling throughout (matches Flask API pattern)
- ✅ CLI utilities: JSON parsing, datetime parsing, confirmation prompts (cli_utils.py)
- ✅ **System Status**: Backend (90 tests) + Flask API (27 endpoints) + CLI (25 commands) = 

**2025-10-14: Flask API Migration**
- ✅ Modular Flask API with Blueprint organization
- ✅ RESTful endpoints for Goals, Actions, Values, Terms
- ✅ Application factory pattern (flask_main.py)
- ✅ Serialization infrastructure (rhetorica/serializers.py)
- ✅ Field name standardization (logtime → log_time, name → common_name)
- ✅ Clean imports (removed unnecessary sys.path manipulation)
- ✅ 8 new term-action filtering tests (90 total passing)

**2025-10-13: Phase 1 Complete**
- ✅ CLI interface with formatted progress display
- ✅ Values system with polymorphic storage
- ✅ JSON API endpoints for integrations
- ✅ Progress aggregation business logic (ethica/progress_aggregation.py)
- ✅ Presentation layer separation (interfaces/ directory)

## Future Extensions (Not Yet Implemented)

### Value-Goal-Action Alignment System

See **[swift/docs/VALUE_ALIGNMENT_MATCHING.md](swift/docs/VALUE_ALIGNMENT_MATCHING.md)** for comprehensive design proposals.

**Proposed Matching Functions** (informative and encouraging):
1. **Value Fulfillment Score** - Weekly metric showing how much you're honoring each value
2. **Cross-Domain Action Detection** - Highlight actions serving multiple values simultaneously
3. **Value Neglect Alert** - Gentle prompts for values that haven't been activated recently
4. **Goal-Value Alignment Verification** - Ensure current goals serve stated values
5. **Value Momentum Tracker** - Show trends over time (growing/declining/steady)
6. **Action-Value Attribution** - Real-time feedback showing which values each action serves

**Migration Required**: Populate `goal_value_alignment` table from existing JSON in `goals.how_goal_is_relevant`

**Status**: Design complete, not yet implemented

### Other Extensions

- Flask API integration tests
- Web UI frontend (HTML/JS consuming Flask API)
- Authentication for API
- Bulk import from CSV/JSON
- Export functionality (PDF, CSV)
- Charts and visualizations for progress over time

## References

- **README.md**: General project overview (multi-language structure, architecture philosophy)
- **python/README.md**: Python-specific implementation details and usage
- **swift/SWIFTROADMAP.md**: Swift implementation roadmap and progress
- Architecture decisions: `.documentation/architecture_decisions.md`
- Testing workflow: `.documentation/testing_workflow.md`
- Initial reflections: `.documentation/initial_reflections.md`
