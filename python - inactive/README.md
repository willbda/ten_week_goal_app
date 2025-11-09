# Ten Week Goal Tracking Application

A personal development tracking system built with clean architecture principles. Track actions, set SMART goals, define personal values, and monitor progress over time with intelligent automatic matching.

## Project Reorganization: Multi-Language Structure (2025-10-17)

**Python Implementation**: in `/python` directory
- Flask API with 27 RESTful endpoints
- UI for Goals, Terms, Values management
- Polymorphic storage for class hierarchies

**Swift Development**: Active development in `/swift` directory
- Maintaining same layered architecture
- Native macOS/iOS with SwiftUI planned

## What This Does

- **Log Actions**: Record daily activities with optional measurements (distance, duration, reps, etc.)
- **Define Goals**: Create Goals, Milestones, or fully-validated SmartGoals with polymorphic storage
- **Track Values**: Define personal values hierarchy (Incentives → Values → Major/Highest Order Values)
- **Progress Tracking**: Calculate progress automatically with cached projections
- **Store History**: Maintain complete audit trail of all entities in SQLite with archiving
- **Flask API**: RESTful endpoints for integrations and web UI

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

# Set up environment
cp .env.example .env  # Create .env file (or use existing)

# Navigate to Python directory
cd python/

# Run tests to verify setup
pytest tests/ -v
```

### Usage

**Flask Web App:**
```bash
# From project root (recommended)
python run_flask.py
# OR
flask run  # Uses .flaskenv configuration

# From python/ directory (alternative)
cd python/
python interfaces/flask/app.py

# Visit http://localhost:5001
# Web UI: http://localhost:5001/goals
# API endpoints: http://localhost:5001/api/
```

**API Endpoints:**
- `/api/goals` - Goals CRUD and progress tracking
- `/api/actions` - Actions CRUD and goal matching
- `/api/values` - Values CRUD with polymorphic types
- `/api/terms` - Terms CRUD and lifecycle management

## Project Structure

```
ten_week_goal_app/
├── python/                  # Python implementation
│   ├── categoriae/          # Domain entities (WHAT things ARE)
│   │   ├── actions.py       # Action class with validation
│   │   ├── goals.py         # Goal hierarchy (Goal → Milestone → SmartGoal)
│   │   ├── values.py        # Values hierarchy with life areas
│   │   ├── relationships.py # Derived relationships
│   │   └── terms.py         # Time period entities
│   │
│   ├── ethica/              # Business logic (HOW things RELATE)
│   │   ├── progress_aggregation.py  # Progress metrics
│   │   ├── progress_matching.py     # Matching functions
│   │   └── inference_service.py     # Batch/realtime inference
│   │
│   ├── politica/            # Infrastructure (HOW it's STORED)
│   │   └── database.py      # Generic SQLite operations
│   │
│   ├── rhetorica/           # Translation layer (COORDINATION)
│   │   └── storage_service.py   # Polymorphic storage
│   │
│   ├── interfaces/          # Presentation layer
│   │   └── flask/           # Flask web application
│   │       ├── app.py       # Application factory
│   │       ├── routes/      # API and UI routes
│   │       ├── templates/   # HTML templates
│   │       └── static/      # CSS, JS assets
│   │
│   └── tests/               # Test suite (90+ tests)
│   ├── conftest.py          # Pytest fixtures
│   ├── test_actions.py      # Domain entity tests (9 tests)
│   ├── test_values.py       # Values hierarchy tests (8 tests)
│   ├── test_progress_aggregation.py  # Business logic tests (12 tests)
│   ├── test_action_storage.py   # Storage roundtrip tests (3 tests)
│   ├── test_goal_storage.py     # Goal persistence test (1 test)
│   ├── test_values_storage.py   # Polymorphism test (1 test)
│   └── test_term_actions.py # Date filtering tests (2 tests)
│
├── shared/                  # Shared between languages
│   └── schemas/             # Database table definitions
│       ├── actions.sql
│       ├── goals.sql        # Includes goal_type for polymorphism
│       ├── values.sql
│       ├── terms.sql
│       └── archive.sql
│
├── swift/                   # Swift implementation (in progress)
│   ├── Package.swift        # Swift Package Manager config
│   ├── Sources/            # Swift source code
│   └── Tests/              # Swift tests
│
├── .env                     # Environment variables (SECRET_KEY, etc)
└── .documentation/          # Architecture documentation
```

## Architecture Highlights

### Domain Layer (categoriae)
```python
# Pure Python classes with zero dependencies
class Action:
    def __init__(self, description: str):
        self.description = description
        self.log_time = datetime.now()
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
- [x] Business logic (progress calculation, automatic action-goal matching with how_goal_is_actionable)
- [x] Generic storage layer with polymorphic type support
- [x] Repository pattern with save/update/get_by_id conveniences
- [x] Inference service for batch/realtime relationship detection
- [x] Import historical Actions and Goals from tabular data
- [x] CLI interface with formatted progress display
- [x] Modular Flask API with Blueprint organization
- [x] RESTful JSON API endpoints (Goals, Actions, Values, Terms)
- [x] Progress aggregation business logic
- [x] Presentation layer separation
- [x] Serialization infrastructure (rhetorica/serializers.py)
- [x] **Phase 1: Values Foundation** (NEW)
  - [x] Values CLI (create-major, create-highest-order, life-areas create, create-general)
  - [x] ValuesStorageService with polymorphic type support
  - [x] ~~ValuesOrchestrationService~~ (removed 2025-10-15 - interfaces use storage directly)
  - [x] Entity self-identification (incentive_type)
  - [x] VALUES_QUICKSTART.md documentation
- [x] Comprehensive tests (90 passing: 48 core + 17 values + 25 other)

### Next (Following [ROADMAP.md](.documentation/ROADMAP.md))
- [ ] **Phase 3**: Enter personal values using CLI (validates Phase 1)
- [ ] **Phase 2**: Action CRUD (build ethica validation, complete interfaces)
- [ ] **Phase 4**: Relationship management (expose inference review UI)
- [ ] **Phase 5**: Terms & time horizons (complete storage layer)
- [ ] **Phase 6**: Goal-Value alignment inference

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
**Current Phase**: stable - Web UI and API Complete
**Last Updated**: 2025-10-17
**Test Coverage**: 90+ tests passing (100% pass rate)
**Architecture**: Multi-language structure (Python complete, Swift in progress)
**Development Guide**: See [ROADMAP.md](ROADMAP.md) for systematic development plan

*Built with clean architecture principles as a foundation for future personal development tracking systems.*
