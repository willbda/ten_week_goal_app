# Ten Week Goal Tracking Application

A personal development tracking system built with clean architecture principles. Track actions, set SMART goals, define personal values, and monitor progress over time with intelligent automatic matching.

## What This Does

- **Log Actions**: Record daily activities with optional measurements (distance, duration, reps, etc.)
- **Define Goals**: Create loose aspirations or strict SMART goals with deadlines and targets
- **Track Values**: Define personal values hierarchy (Incentives → Values → Major/Highest Order Values)
- **Automatic Matching**: Intelligent inference system matches actions to goals by time period, units, and description
- **Progress Tracking**: Calculate progress automatically with cached projections
- **Store History**: Maintain complete audit trail of all entities in SQLite with archiving
- **CLI Interface**: Command-line tool for viewing goal progress with formatted output
- **Web Dashboard**: Flask-based web UI showing progress, charts, and detailed views
- **JSON API**: RESTful endpoints for integrations and external tools

## Why This Architecture

This project aspires to **clean separation of concerns**. My background is in philosophy, and I'm exploring a mental model  to help me build better intuitions about layering concerns.


```
categoriae/   → What things ARE (entities: Action, Goal, Value, Relationships, Terms)
ethica/       → How things SHOULD behave (business rules: calculate progress, match actions to goals)
politica/     → How things ARE DONE (infrastructure: database operations, schemas)
rhetorica/    → Translation between domains (coordination layer with polymorphic storage)
```

**Key Principles:**
- Business logic has zero dependencies (no database, no framework)
- Storage layer is generic (works for any entity, not just goals/actions)
- All layers testable in isolation with real objects (no mocks needed)
- Framework dependencies only at the edges (UI layer not yet built)


## Quick Start

### Installation

```bash
# Clone and navigate to project
cd ten_week_goal_app

# Run tests to verify setup
pytest tests/ -v
```

### Usage

**CLI Interface:**
```bash
# Show progress for all goals
python interfaces/cli.py show-progress

# Show progress with detailed action listings
python interfaces/cli.py show-progress -v
```

**Web Interface:**
```bash
# Install web dependencies
pip install -r requirements_web.txt

# Start web server
python interfaces/web_app.py

# Visit http://localhost:5000
```

See [interfaces/WEB_README.md](interfaces/WEB_README.md) for detailed web UI documentation.

## Project Structure

```
ten_week_goal_app/
├── categoriae/              # Domain entities (WHAT things ARE)
│   ├── actions.py           # Action class with validation
│   ├── goals.py             # Goal hierarchy (ThingIWant → Goal → SmartGoal)
│   ├── values.py            # Values hierarchy with life areas and priorities
│   ├── relationships.py     # Derived relationships (ActionGoalRelationship, GoalValueAlignment)
│   └── terms.py             # Time period entities (TenWeekTerm, LifeTime)
│
├── ethica/                  # Business logic (HOW things RELATE)
│   ├── progress.py          # Legacy progress calculations (deprecated)
│   ├── progress_aggregation.py  # Progress metrics and aggregation (authoritative)
│   ├── progress_matching.py # Stateless matching functions (period, unit, description)
│   └── inference_service.py # Service orchestrator for batch/realtime inference
│
├── politica/                # Infrastructure (HOW it's STORED)
│   ├── database.py          # Generic SQLite operations
│   └── schemas/             # Database table definitions
│       ├── actions.sql
│       ├── goals.sql
│       ├── values.sql
│       ├── action_goal_progress.sql  # Cached relationship projections
│       ├── archive.sql
│       └── schema.sql
│
├── rhetorica/               # Translation layer (COORDINATION)
│   └── storage_service.py   # Repository pattern with polymorphic type support
│
├── interfaces/              # Presentation layer (USER INTERACTION)
│   ├── cli.py               # Command-line interface with formatted output
│   ├── cli_formatters.py    # Presentation formatting functions
│   ├── cli_config.py        # CLI configuration constants
│   ├── web_app.py           # Flask web application
│   ├── templates/           # Jinja2 HTML templates
│   │   ├── base.html        # Base layout
│   │   ├── progress.html    # Dashboard view
│   │   ├── goal_detail.html # Goal detail page
│   │   └── error.html       # Error page
│   ├── static/              # CSS and static assets
│   │   └── css/style.css
│   └── WEB_README.md        # Web UI documentation
│
├── config/                  # Configuration and setup
│   ├── config.toml          # Application settings
│   ├── settings.py          # Config loader
│   ├── logging_setup.py     # Logging configuration
│   └── testing.py           # Test-specific config
│
├── tests/                   # Test suite (82 passing tests)
│   ├── conftest.py          # Pytest fixtures
│   ├── test_actions.py      # Domain entity tests
│   ├── test_action_storage.py   # Storage integration tests
│   ├── test_goal_storage.py     # Goal persistence tests
│   ├── test_progress_aggregation.py  # Business logic tests (new)
│   ├── test_cli_formatters.py  # Presentation formatting tests (new)
│   ├── test_values.py       # Values entity tests
│   └── test_values_storage.py   # Values storage with polymorphism
│
└── .documentation/          # Architecture documentation
    ├── architecture_decision_record.md
    └── architectural_lessons_from_grant_project.md
```

## Architecture Highlights

### Domain Layer (categoriae)
```python
# Pure Python classes with zero dependencies
class Action:
    def __init__(self, description: str):
        self.description = description
        self.logtime = datetime.now()
        self.measurements: Optional[Dict[str, float]] = None
```

### Business Logic (ethica)
```python
# Pure functions that work with entities
def calculate_goal_metrics(goal: SmartGoal, actions: List[Action]) -> GoalProgress:
    # No database, no framework - just domain logic
    matching_actions = [a for a in actions if matches_goal(a, goal)]
    return GoalProgress(...)

# Automatic inference matching
from ethica.progress_matching import match_by_time_period, match_by_unit, match_by_description

# Batch processing service
from ethica.inference_service import InferenceService
service = InferenceService()
relationships = service.infer_all_relationships()  # Returns ActionGoalRelationship objects
```

### Infrastructure (politica)
```python
# Generic database operations - no entity knowledge
class Database:
    def insert(self, table: str, records: List[dict]):
        # Works for actions, goals, or any entity
```

### Translation (rhetorica)
```python
# Coordinates domains, handles serialization with polymorphism
class ActionStorageService:
    def _to_dict(self, action: Action) -> dict:
        # Entity → storage format

    def _from_dict(self, data: dict) -> Action:
        # Storage → entity

# Polymorphic storage for class hierarchies
class ValuesStorageService:
    def store_single_instance(self, value_instance):
        # Automatically saves type info for correct retrieval
        # Works with Incentive, Value, MajorValue, HighestOrderValue
```


## Configuration

Edit `config/config.toml` to customize:

```toml
[storage]
data_dir = "politica/data_storage"
db_name = "application_data.db"
schema_dir = "politica/schemas"

[logging]
level = "INFO"
```

Test configuration is separate in `config/testing.py` to keep test data isolated.

## Development Roadmap

### Complete ✅
- [x] Domain entities (Action, Goal, SmartGoal, Values hierarchy, Relationships, Terms)
- [x] Business logic (progress calculation, automatic action-goal matching with actionability)
- [x] Generic storage layer with polymorphic type support
- [x] Repository pattern with save/update/get_by_id conveniences
- [x] Inference service for batch/realtime relationship detection
- [x] Import historical Actions and Goals from tabular data
- [x] CLI interface with formatted progress display (NEW)
- [x] Web dashboard with Flask (NEW)
- [x] JSON API endpoints (NEW)
- [x] Progress aggregation business logic (NEW)
- [x] Presentation layer separation (NEW)
- [x] Comprehensive tests (82 passing, +34 new tests)

### Next
- [ ] Add tests for Terms module (calculation methods)
- [ ] Add GoalValueAlignment inference (connect goals to values)
- [ ] Add Milestones(Event?) class for tracking steps towards goal
- [ ] Add authentication to web UI
- [ ] Add goal creation/editing through web interface

### Later
- [ ] Create simple users to practice data separation and protected access
- [ ] Export functionality (CSV, JSON)
- [ ] Charts and visualizations for progress over time
- [ ] Mobile-responsive web design improvements

## Key Differences from Previous Projects

**Grant Writing Dashboard** (previous project):
- Services know about storage implementation
- Storage returns pandas DataFrames (coupled to pandas)
- Business logic mixed with presentation logic
- 835 lines of coupled code for core functionality

**This Project**:
- Clean layer separation with zero coupling violations
- Storage returns simple dicts (no framework coupling)
- Business logic is pure functions (easily testable)
- Polymorphic storage with automatic type preservation
- Intelligent inference system for automatic relationship detection


## Design Decisions

**Why Aristotelian naming?**
- Provides intuitive mental hooks for layer responsibilities
- "What IS this?" → categoriae
- "What SHOULD happen?" → ethica
- "How is it DONE?" → politica
- Enforces separation through conceptual boundaries

**Why no framework dependencies in core?**
- Business logic works in notebooks, CLI, web, mobile
- Can swap Flask → FastAPI → anything without rewriting logic
- Tests run fast (no framework overhead)

**Why generic storage layer?**
- Database.insert() works for any entity
- Don't need ActionStorage, GoalStorage, HabitStorage
- Just need entity-specific translation in rhetorica

## Contributing

This is a personal learning project, but architectural feedback is welcome. If you spot violations of the separation of concerns, please open an issue.

## License

Personal project - all rights reserved.

---

**Project Status**: Active Development
**Last Updated**: 2025-10-13
**New This Week**: CLI interface, Web dashboard, API endpoints, separation of presentation layer

*Built with clean architecture principles as a foundation for future personal development tracking systems.*
