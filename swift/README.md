# Ten Week Goal App - Swift Implementation

This is the Swift port of the Ten Week Goal App, maintaining the same layered architecture as the Python version.

## Architecture Layers

Following the Aristotelian naming convention:

- **Categoriae/** - Domain entities (what things ARE)
  - Action, Goal, Value, Term structs/classes

- **Ethica/** - Business logic (what SHOULD happen)
  - Progress calculations, matching algorithms

- **Rhetorica/** - Translation layer (how to communicate)
  - Storage services, serialization

- **Politica/** - Infrastructure (how things are DONE)
  - SQLite operations, database management

## Compatibility

The Swift implementation reads and writes the same SQLite database format as the Python version, ensuring data compatibility between implementations.

## Status

🚧 Under Development (Started: 2025-10-17)

Next steps:
1. Port domain models (Categoriae)
2. Implement SQLite infrastructure (Politica)
3. Port business logic (Ethica)
4. Build SwiftUI interface