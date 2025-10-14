"""
Entity serialization utilities.

Provides clean, reusable serialization for entities that declare __serialize__.
This is the single point of serialization logic for the translation layer.

Written by Claude Code on 2025-10-14
"""

from datetime import datetime, date
from typing import Any
import json


def serialize(entity: Any, include_type: bool = True) -> dict:
    """
    Serialize any entity that declares __serialize__ attribute (dict format with types).

    Args:
        entity: Domain entity with __serialize__ dict attribute mapping field names to types
        include_type: If True, adds 'type' field with class name (default: True)

    Returns:
        Dict with all fields from entity.__serialize__, formatted according to their types:
        - datetime/date → ISO string
        - dict → JSON string
        - list → JSON string
        - primitives (int, str, float) → as-is

    Raises:
        ValueError: If entity doesn't define __serialize__ or it's not a dict

    Example:
        >>> class Goal:
        ...     __serialize__ = {'id': int, 'description': str, 'start_date': datetime}
        >>> goal = Goal("Run 100km", start_date=datetime(2025, 1, 1))
        >>> serialize(goal)
        {'id': 1, 'description': 'Run 100km', 'start_date': '2025-01-01T00:00:00', 'type': 'Goal'}
    """
    if not hasattr(entity, '__serialize__'):
        raise ValueError(
            f"{type(entity).__name__} doesn't define __serialize__ attribute. "
            "Add __serialize__ = {{'field': type, ...}} to the class."
        )

    if not isinstance(entity.__serialize__, dict):
        raise ValueError(
            f"{type(entity).__name__}.__serialize__ must be a dict mapping field names to types. "
            f"Got {type(entity.__serialize__).__name__} instead."
        )

    result = {}

    for attr, dtype in entity.__serialize__.items():
        value = getattr(entity, attr, None)

        if value is None:
            result[attr] = None
            continue

        # Serialize based on declared type
        if dtype == datetime or dtype is datetime:
            result[attr] = value.isoformat() if isinstance(value, datetime) else value
        elif dtype == date or dtype is date:
            result[attr] = value.isoformat() if isinstance(value, date) else value
        elif dtype == dict or dtype is dict:
            # Convert dict to JSON string for database storage
            result[attr] = json.dumps(value) if isinstance(value, dict) else value
        elif dtype == list or dtype is list:
            # Convert list to JSON string for database storage
            result[attr] = json.dumps(value) if isinstance(value, list) else value
        else:
            # Primitive types (int, str, float, bool) - keep as-is
            result[attr] = value

    # Add type information for polymorphism
    if include_type:
        result['type'] = entity.__class__.__name__

    return result


def deserialize(data: dict, entity_class: type) -> Any:
    """
    Reconstruct entity from dict using its __serialize__ type information.

    Args:
        data: Dict from database with field values (may have JSON strings)
        entity_class: The entity class to reconstruct (e.g., Goal, Action)

    Returns:
        Instance of entity_class with fields populated from data

    Example:
        >>> data = {
        ...     'id': 1,
        ...     'description': 'Run 100km',
        ...     'start_date': '2025-01-01',
        ...     'measurements': '{"distance": 5.0}'
        ... }
        >>> goal = deserialize(data, Goal)
        >>> goal.start_date  # datetime object
        datetime.datetime(2025, 1, 1, 0, 0)
    """
    if not hasattr(entity_class, '__serialize__'):
        raise ValueError(
            f"{entity_class.__name__} doesn't define __serialize__ attribute"
        )

    parsed = {}

    for attr, dtype in entity_class.__serialize__.items():
        if attr not in data:
            continue  # Field not in data, skip it

        value = data[attr]

        if value is None:
            parsed[attr] = None
            continue

        # Parse based on declared type
        if dtype == datetime or dtype is datetime:
            if isinstance(value, str):
                parsed[attr] = datetime.fromisoformat(value)
            else:
                parsed[attr] = value  # Already datetime
        elif dtype == date or dtype is date:
            if isinstance(value, str):
                parsed[attr] = datetime.strptime(value, '%Y-%m-%d').date()
            else:
                parsed[attr] = value  # Already date
        elif dtype == dict or dtype is dict:
            if isinstance(value, str):
                parsed[attr] = json.loads(value)  # Parse JSON string
            else:
                parsed[attr] = value  # Already dict
        elif dtype == list or dtype is list:
            if isinstance(value, str):
                parsed[attr] = json.loads(value)  # Parse JSON string
            else:
                parsed[attr] = value  # Already list
        else:
            # Primitive types - keep as-is
            parsed[attr] = value

    # Determine which fields go to constructor vs. set as attributes
    # Some entities (like Action) use minimal constructors and set fields afterward
    constructed_without = getattr(entity_class, '__constructed_without__', [])

    constructor_data = {k: v for k, v in parsed.items() if k not in constructed_without}
    attribute_data = {k: v for k, v in parsed.items() if k in constructed_without}

    # Create instance with constructor fields
    entity = entity_class(**constructor_data)

    # Set remaining attributes
    for attr, value in attribute_data.items():
        setattr(entity, attr, value)

    return entity


def serialize_many(entities: list, include_type: bool = True) -> list[dict]:
    """
    Serialize a list of entities.

    Args:
        entities: List of domain entities with __serialize__ attribute
        include_type: If True, adds 'type' field to each (default: True)

    Returns:
        List of dicts

    Example:
        >>> goals = [goal1, goal2, goal3]
        >>> serialize_many(goals)
        [{'id': 1, 'description': '...', 'type': 'Goal'}, ...]
    """
    return [serialize(entity, include_type=include_type) for entity in entities]
