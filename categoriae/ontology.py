"""
Base entity classes for domain model.

Provides shared infrastructure (id, timestamps) that all entities inherit.
Children differentiate by adding required fields that define their essence.

Written by Claude Code on 2025-10-16
"""

from abc import ABC
from dataclasses import dataclass, field
from typing import Optional
from datetime import datetime

@dataclass
class IndependentEntity(ABC):
    common_name: str
    description: Optional[str] = None  # Optional elaboration
    notes: Optional[str] = None  # Freeform notes about the goal



@dataclass
class PersistableEntity(IndependentEntity):
    """
    Base infrastructure for entities that can be stored in database.

    Provides common persistence fields with defaults, allowing child classes
    to add required fields first while maintaining proper field ordering.

    Pattern: Children add required fields → inherit these defaulted fields → add optional fields
    """
    log_time: datetime = field(default_factory=datetime.now)
    id: Optional[int] = None


@dataclass
class DerivedEntity(ABC):
    """
    Base class for relationships computed from existing entities.

    These are NOT source of truth - they can be recalculated from base entities.
    Persisting them is purely for performance optimization and auditability.

    Examples:
        - An action contributing to a goal
        - A goal aligned with a value
        - An action reflecting a value
    """
    pass