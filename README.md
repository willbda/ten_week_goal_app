# Ten Week Goal Tracking Application

A personal development tracking system exploring clean architecture through a philosophical lens. Track daily actions, define goals with varying specificity, establish personal values, and monitor progress over time with automatic relationship inference.

## 🚧 Major Rearchitecture in Progress (v0.5.0)

**Current Status**: Database schema and Swift models complete (Phases 1-2), Repository layer next (Phase 3)

The Swift implementation is undergoing a complete rearchitecture to 3NF normalized database with clean break migration. See [swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md](swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md) for details.

**Key Changes**:
- JSON fields eliminated (measuresByUnit → MeasuredAction junction table)
- Unified values table (4 tables → 1 with ValueLevel enum)
- Metrics as first-class entities
- Clean separation: Models → Services → ViewModels → Views

**Breaking**: Some components intentionally broken during migration (MatchingService, ViewModels).

## Project Structure: Multi-Language Implementation

This project maintains the same architectural principles across multiple language implementations:

```
ten_week_goal_app/
├── python/         # Python implementation
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

**Python** (`python/`): 
- Flask web app with RESTful API (27 endpoints)
- CLI interface with 25 commands
- Polymorphic storage for class hierarchies
- **See:** [python/README.md](python/README.md)

**Swift** (`swift/`): Active development (v0.5.0-rearchitecture)
- 3NF normalized database with SQLiteData (CloudKit sync)
- Clean architecture: Models → Services → ViewModels → Views
- Native macOS/iOS apps with SwiftUI (functional, in rearchitecture)
- **See:** [swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md](swift/docs/REARCHITECTURE_COMPLETE_GUIDE.md)

## Core Concepts

**What This Tracks:**
- **Actions**: Daily activities linked to metrics via junction tables (distance, duration, count)
- **Goals**: Objectives with multi-metric targets and value alignments
- **Values**: Personal motivators with unified priority levels (general → major → highest order)
- **Terms**: Ten-week time periods for focused goal pursuit
- **Metrics**: First-class catalog of units (km, hours, occasions) for measurements and targets
- **Relationships**: Explicit junction tables for queryable action-goal-value connections

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

- **Python**: Effectively archived (v1.0-python tag)
- **Swift**: Active development (v0.5.0-rearchitecture)
  - ✅ Phases 1-2: Database schema & models complete
  - 🚧 Phase 3: Repository/Service layer next
  - ⏳ Phases 4-7: Protocols, ViewModels, Views, Testing
- **Database**: Complete 3NF rearchitecture (clean break migration)
- **Last Updated**: 2025-10-31

## Contributing

Personal learning project exploring architectural patterns. Feedback on separation of concerns and layer boundaries welcome.

## License

Personal project - all rights reserved.

---

*Exploring clean architecture as a foundation for sustainable personal development tracking across platforms.*
