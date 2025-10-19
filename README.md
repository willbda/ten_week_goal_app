# Ten Week Goal Tracking Application

A personal development tracking system exploring clean architecture through a philosophical lens. Track daily actions, define goals with varying specificity, establish personal values, and monitor progress over time with automatic relationship inference.

## Project Structure: Multi-Language Implementation

This project maintains the same architectural principles across multiple language implementations:

```
ten_week_goal_app/
├── python/         # Python implementation (production ready)
│   ├── categoriae/ # Domain entities
│   ├── ethica/     # Business logic
│   ├── rhetorica/  # Translation layer
│   ├── politica/   # Infrastructure
│   ├── interfaces/ # CLI and Flask web app
│   └── tests/      # 90+ passing tests
│
├── swift/          # Swift implementation (active development)
│   ├── Sources/    # Swift source code
│   └── Tests/      # Swift tests
│
└── shared/         # Shared resources
    └── schemas/    # SQLite table definitions
```

### Implementation Status

**Python** (`python/`): Production ready
- 90+ passing tests with full test coverage
- Flask web app with RESTful API (27 endpoints)
- CLI interface with 25 commands
- Polymorphic storage for class hierarchies
- **See:** [python/README.md](python/README.md)

**Swift** (`swift/`): Active development
- Protocol-oriented architecture matching Python layers
- SQLite integration with GRDB.swift
- Native macOS/iOS planned with SwiftUI
- **See:** [swift/SWIFTROADMAP.md](swift/SWIFTROADMAP.md)

## Core Concepts

**What This Tracks:**
- **Actions**: Daily activities with optional measurements (distance, duration, reps, etc.)
- **Goals**: Objectives with varying specificity (Goal → Milestone → SmartGoal)
- **Values**: Personal motivators organized by hierarchy and life domains
- **Terms**: Ten-week time periods for focused goal pursuit
- **Relationships**: Automatic inference connecting actions to relevant goals

**Why This Architecture:**

This project explores clean separation of concerns using an Aristotelian mental model:

```
categoriae/   → "What things ARE"
                Domain entities with zero dependencies

ethica/       → "What SHOULD happen"
                Business rules and validation logic

politica/     → "How things ARE DONE"
                Infrastructure and persistence

rhetorica/    → "Translation between domains"
                Coordination and serialization
```

**Key Principles:**
- Business logic has zero framework dependencies
- Each layer testable in isolation with real objects
- Polymorphic storage preserves type information
- Same architecture across all implementations
- Framework dependencies only at the edges

## Quick Start

Choose your implementation:

### Python
```bash
cd python/
pytest tests/ -v              # Run tests
python run_flask.py           # Start web app (http://localhost:5001)
python interfaces/cli/cli.py  # CLI interface
```

Full Python documentation: [python/README.md](python/README.md)

### Swift
```bash
cd swift/
swift build                   # Build project
swift test                    # Run tests
```

Full Swift roadmap: [swift/SWIFTROADMAP.md](swift/SWIFTROADMAP.md)

## Architectural Philosophy

**Why Aristotelian naming?**

The philosophical layer names provide intuitive mental hooks for separation of concerns:
- "What IS this thing?" → categoriae (domain entities)
- "What SHOULD happen with it?" → ethica (business rules)
- "How is it DONE?" → politica (infrastructure)
- "How do we communicate between domains?" → rhetorica (translation)

This conceptual framework enforces boundaries more effectively than technical terms like "services" or "repositories" by grounding each layer in a distinct philosophical question.

**Why zero dependencies in core?**

Business logic that works anywhere:
- Same code runs in notebooks, CLI, web apps, mobile apps
- Can swap Flask → FastAPI → anything without touching logic
- Tests run fast (no framework overhead)
- Port to new languages by replicating layer boundaries

**Why generic infrastructure?**

The storage layer (`politica/`) knows nothing about specific entities:
- `Database.insert()` works for Actions, Goals, Values, any entity
- Translation happens in `rhetorica/` with entity-specific services
- Polymorphic storage automatically preserves type information
- Add new entities without modifying infrastructure

## Design Trade-offs

**Complexity for Flexibility:**
- More layers = more indirection
- Payoff: Change databases, frameworks, languages without rewriting logic

**Philosophical Naming:**
- Unfamiliar terms require learning
- Payoff: Stronger conceptual boundaries than generic "services"

**Zero Framework Dependencies:**
- Manual coordination between layers
- Payoff: Business logic portable across any environment

## Development Philosophy

**Truth-Seeking:** Challenge assumptions, validate approaches against practical constraints

**Simplicity First:** Seek straightforward solutions before adding complexity

**Comment-Driven:** Code should explain its purpose through comments and descriptive naming

**Repository Hygiene:** Clean commits, logical structure, consistent patterns

## Project Status

- **Python**: Production ready (v1.0)
- **Swift**: Active development (protocol-oriented refactor complete)
- **Shared**: Database schemas stable
- **Last Updated**: 2025-10-18

## Contributing

Personal learning project exploring architectural patterns. Feedback on separation of concerns and layer boundaries welcome.

## License

Personal project - all rights reserved.

---

*Exploring clean architecture as a foundation for sustainable personal development tracking across platforms.*
