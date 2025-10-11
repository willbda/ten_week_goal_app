# Ten Week Goal Tracking Application

A personal development tracking system built with clean architecture principles. Track actions, set SMART goals, and monitor progress over time.

## What This Does

- **Log Actions**: Record daily activities with optional measurements (distance, duration, reps, etc.)
- **Define Goals**: Create loose aspirations or strict SMART goals with deadlines and targets
- **Track Progress**: Calculate progress automatically by matching actions to goal metrics
- **Store History**: Maintain complete audit trail of all actions and goals in SQLite

## Why This Architecture

This project aspires to **clean separation of concerns**. My background is in philosophy, and I'm exploring a mental model  to help me build better intuitions about layering concerns.


```
categoriae/   → What things ARE (entities: Action, Goal)
ethica/       → How things SHOULD behave (business rules: calculate progress)
politica/     → How things ARE DONE (infrastructure: database operations)
rhetorica/    → Translation between domains (coordination layer)
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

## Project Structure

```
ten_week_goal_app/
├── categoriae/              # Domain entities (WHAT things ARE)
│   ├── actions.py           # Action class with validation
│   └── goals.py             # Goal and SmartGoal classes
│
├── ethica/                  # Business logic (HOW things RELATE)
│   └── progress.py          # Progress calculations and rules
│
├── politica/                # Infrastructure (HOW it's STORED)
│   ├── database.py          # Generic SQLite operations
│   └── schemas/             # Database table definitions
│       ├── actions.sql
│       ├── goals.sql
│       └── archive.sql
│
├── rhetorica/               # Translation layer (COORDINATION)
│   └── storage_service.py   # Repository pattern for entities
│
├── config/                  # Configuration and setup
│   ├── config.toml          # Application settings
│   ├── settings.py          # Config loader
│   ├── logging_setup.py     # Logging configuration
│   └── testing.py           # Test-specific config
│
├── tests/                   # Test suite
│   ├── conftest.py          # Pytest fixtures
│   ├── test_actions.py      # Domain entity tests
│   ├── test_action_storage.py   # Storage integration tests
│   ├── test_goal_storage.py     # Goal persistence tests
│   └── test_progress.py     # Business logic tests
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
# Coordinates domains, handles serialization
class ActionStorageService:
    def _to_dict(self, action: Action) -> dict:
        # Entity → storage format

    def _from_dict(self, data: dict) -> Action:
        # Storage → entity
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

### Current (Phase 1) ✅
- [x] Domain entities (Action, Goal, SmartGoal)
- [x] Business logic (progress calculation)
- [x] Generic storage layer
- [x] Repository pattern
- [x] Comprehensive tests

### Next (Phase 2) 🔄
- [ ] Import Actions and Goals in bulk from tabular data
- [ ] Add Values class
- [ ] Practice CLI - based interface with simple APIs
- [ ] Add UI layer (Flask/FastAPI)
- [ ] Add Milestones(Event?) class for tracking steps towards goal
- [ ] Dashboard visualization

### Future (Phase 3) 📋
- [ ] Create simple users to practice data separation and protected access
- [ ] Export functionality (CSV, JSON)

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
- 717 lines of well-separated code with more features

See [Architectural Lessons](.documentation/architectural_lessons_from_grant_project.md) for detailed comparison.

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
**Last Updated**: 2025-10-11
**Test Coverage**: 14/14 tests passing

*Built with clean architecture principles as a foundation for future personal development tracking systems.*
