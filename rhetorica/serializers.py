"""
Entity serialization utilities.

Generic dataclass-based serialization for all domain entities.
Uses Python's native dataclass field introspection instead of manual constitutive_parts.

Written by Claude Code on 2025-10-14
Refactored to generic dataclass approach on 2025-10-16
"""

from dataclasses import fields, is_dataclass
from datetime import datetime, date
from typing import Any
import json


def serialize(entity: Any, include_type: bool = True, json_encode: bool = False) -> dict:
    """
    Serialize any dataclass entity to dict for storage or API responses.

    Uses Python's native dataclass fields() introspection - no manual field declarations needed.
    Automatically handles type-specific formatting (datetime → ISO string, etc.)

    Args:
        entity: Domain entity (must be a dataclass)
        include_type: If True, adds 'type' field with class name for polymorphism (default: True)
        json_encode: If True, converts dict/list to JSON strings for DB storage (default: False)

    Returns:
        Dict with all fields from dataclass, formatted according to their types:
        - datetime/date → ISO string
        - dict/list → kept as-is (or JSON string if json_encode=True)
        - primitives (int, str, float, bool) → as-is
        - None → None

    Raises:
        TypeError: If entity is not a dataclass

    Example:
        >>> @dataclass
        ... class Goal:
        ...     description: str
        ...     start_date: datetime
        >>> goal = Goal("Run 100km", start_date=datetime(2025, 1, 1))
        >>> serialize(goal)
        {'description': 'Run 100km', 'start_date': '2025-01-01T00:00:00', 'type': 'Goal'}
    """
    if not is_dataclass(entity):
        raise TypeError(
            f"Can only serialize dataclasses, got {type(entity).__name__}. "
            f"Add @dataclass decorator to the class definition."
        )

    result = {}

    for field in fields(entity):
        value = getattr(entity, field.name)

        if value is None:
            result[field.name] = None
            continue

        # Serialize based on detected type
        if isinstance(value, datetime):
            result[field.name] = value.isoformat()
        elif isinstance(value, date):
            result[field.name] = value.isoformat()
        elif isinstance(value, (dict, list)):
            # Keep as dict/list for in-memory use, or convert to JSON for database
            if json_encode:
                result[field.name] = json.dumps(value)
            else:
                result[field.name] = value
        else:
            # Primitive types (int, str, float, bool) - keep as-is
            result[field.name] = value

    # Add type information for polymorphism (e.g., Values hierarchy, Goal subclasses)
    if include_type:
        result['type'] = entity.__class__.__name__

    return result


def deserialize(data: dict, entity_class: type, json_decode: bool = False) -> Any:
    """
    Reconstruct entity from dict using dataclass field metadata.

    Automatically parses ISO strings to datetime, etc.
    Handles fields that may not be present in data (uses dataclass defaults).

    Args:
        data: Dict from database or API with field values
        entity_class: The dataclass to reconstruct (e.g., Goal, Action)
        json_decode: If True, parses JSON strings to dicts/lists (for DB reads, default: False)

    Returns:
        Instance of entity_class with fields populated from data

    Raises:
        TypeError: If entity_class is not a dataclass

    Example:
        >>> data = {
        ...     'description': 'Run 100km',
        ...     'start_date': '2025-01-01T00:00:00',
        ...     'measurements': '{"distance": 5.0}'
        ... }
        >>> goal = deserialize(data, Goal, json_decode=True)
        >>> goal.start_date  # datetime object
        datetime.datetime(2025, 1, 1, 0, 0)
        >>> goal.measurements  # dict object
        {'distance': 5.0}
    """
    if not is_dataclass(entity_class):
        raise TypeError(
            f"Can only deserialize to dataclasses, got {entity_class.__name__}. "
            f"Add @dataclass decorator to the class definition."
        )

    parsed = {}

    for field in fields(entity_class):
        if field.name not in data:
            # Field not in data - let dataclass default handle it
            continue

        value = data[field.name]

        if value is None:
            parsed[field.name] = None
            continue

        # Parse based on field type annotation
        field_type = field.type

        # Handle Optional[T] by extracting T
        if hasattr(field_type, '__origin__') and field_type.__origin__ is type(None) or True:
            # Get actual type from Optional[T]
            if hasattr(field_type, '__args__'):
                # Optional[T] has __args__ = (T, NoneType)
                non_none_types = [t for t in field_type.__args__ if t is not type(None)]
                if non_none_types:
                    field_type = non_none_types[0]

        # Type-specific parsing
        if field_type == datetime or field_type is datetime:
            if isinstance(value, str):
                parsed[field.name] = datetime.fromisoformat(value)
            else:
                parsed[field.name] = value  # Already datetime
        elif field_type == date or field_type is date:
            if isinstance(value, str):
                parsed[field.name] = datetime.strptime(value, '%Y-%m-%d').date()
            else:
                parsed[field.name] = value  # Already date
        elif (field_type == dict or field_type is dict) and json_decode:
            # Only parse JSON if explicitly requested (for database reads)
            if isinstance(value, str):
                parsed[field.name] = json.loads(value)
            else:
                parsed[field.name] = value  # Already dict
        elif (field_type == list or field_type is list) and json_decode:
            # Only parse JSON if explicitly requested (for database reads)
            if isinstance(value, str):
                parsed[field.name] = json.loads(value)
            else:
                parsed[field.name] = value  # Already list
        else:
            # Primitive types - keep as-is (includes dict/list if not json_decode)
            parsed[field.name] = value

    # Create instance - dataclass __init__ handles all fields
    return entity_class(**parsed)


def serialize_many(entities: list, include_type: bool = True) -> list[dict]:
    """
    Serialize a list of dataclass entities.

    Args:
        entities: List of domain entities (must be dataclasses)
        include_type: If True, adds 'type' field to each (default: True)

    Returns:
        List of dicts

    Example:
        >>> goals = [goal1, goal2, goal3]
        >>> serialize_many(goals)
        [{'description': '...', 'type': 'Goal'}, ...]
    """
    return [serialize(entity, include_type=include_type) for entity in entities]
