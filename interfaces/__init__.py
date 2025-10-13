"""
Interfaces layer - User-facing ways to interact with the application.

This layer sits above all others and provides various interfaces:
- CLI (command-line interface)
- Future: Web API, GUI, etc.

Interfaces know about:
- rhetorica (storage services)
- ethica (business logic)
- categoriae (domain entities)

Interfaces do NOT contain business logic - they orchestrate and present.

Written by Claude Code on 2025-10-12
"""
