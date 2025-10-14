"""
Values storage service - handles translation between Values entities and database storage.

Extracted from storage_service.py on 2025-10-13 for better organization.
Written by Claude Code on 2025-10-13.
"""

import json
from typing import Optional, Union, List
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel
from rhetorica.storage_service import StorageService

# Type alias for Values hierarchy
ValuesType = Union[Values, MajorValues, HighestOrderValues, LifeAreas]


class ValuesStorageService(StorageService):
    """
    Handles translation between Values/MajorValues/HighestOrderValues/LifeAreas and database storage.

    Manages polymorphic values hierarchy by storing value_type and reconstructing
    the appropriate class on retrieval.
    """

    table_name = 'personal_values'  # 'values' is SQL reserved keyword

    # Constructor registry: maps type strings to constructor lambdas
    # Eliminates if-elif chain in _from_dict()
    _CONSTRUCTORS = {
        'major': lambda data, priority, alignment_guidance, value_id: MajorValues(
            name=data['name'],
            description=data['description'],
            priority=priority,
            life_domain=data.get('life_domain', 'General'),
            alignment_guidance=alignment_guidance,
            id=value_id
        ),
        'highest_order': lambda data, priority, alignment_guidance, value_id: HighestOrderValues(
            name=data['name'],
            description=data['description'],
            priority=priority,
            life_domain=data.get('life_domain', 'General'),
            id=value_id
        ),
        'life_area': lambda data, priority, alignment_guidance, value_id: LifeAreas(
            name=data['name'],
            description=data['description'],
            priority=priority,
            life_domain=data.get('life_domain', 'General'),
            id=value_id
        ),
        'general': lambda data, priority, alignment_guidance, value_id: Values(
            name=data['name'],
            description=data['description'],
            priority=priority,
            life_domain=data.get('life_domain', 'General'),
            id=value_id
        )
    }

    def _to_dict(self, entity: Union[Values, MajorValues, HighestOrderValues, LifeAreas]) -> dict:
        """
        Convert any Values subclass to dict for storage.

        Uses entity.incentive_type for type discrimination (no isinstance checks needed).
        Handles alignment_guidance flexibly (can be dict, str, or None).
        Includes ID only if present (for updates).
        """
        value = entity

        # Handle alignment_guidance - only MajorValues has this attribute
        alignment_guidance = None
        if isinstance(value, MajorValues) and value.alignment_guidance:
            if isinstance(value.alignment_guidance, dict):
                alignment_guidance = json.dumps(value.alignment_guidance)
            else:
                alignment_guidance = str(value.alignment_guidance)

        result = {
            'name': value.name,
            'description': value.description,
            'value_type': value.incentive_type,  # Entity knows its own type!
            'priority': int(value.priority),
            'life_domain': value.life_domain,
            'alignment_guidance': alignment_guidance
        }

        # Include ID only if entity has one (stored entities)
        if value.id is not None:
            result['id'] = value.id

        return result

    def _from_dict(self, data: dict) -> Union[Values, MajorValues, HighestOrderValues, LifeAreas]:
        """
        Reconstruct appropriate Values subclass from stored dict.

        Uses constructor registry to eliminate if-elif chain.
        Parses alignment_guidance from JSON if it looks like JSON, otherwise keeps as text.
        Includes ID from database.
        """
        value_type = data.get('value_type', 'general')
        priority = PriorityLevel(data.get('priority', 50))
        value_id = data.get('id')  # Extract ID from stored record

        # Parse alignment_guidance - try JSON first, fall back to text
        alignment_guidance = None
        if data.get('alignment_guidance'):
            try:
                alignment_guidance = json.loads(data['alignment_guidance'])
            except (json.JSONDecodeError, TypeError):
                alignment_guidance = data['alignment_guidance']

        # Use constructor registry for clean type dispatch
        constructor = self._CONSTRUCTORS.get(value_type, self._CONSTRUCTORS['general'])
        return constructor(data, priority, alignment_guidance, value_id)

    def get_all(
        self,
        type_filter: Optional[str] = None,
        domain_filter: Optional[str] = None
    ) -> List[ValuesType]:
        """
        Get all values with optional type and domain filtering.

        Filtering at storage layer prevents presentation layers from reimplementing.

        Args:
            type_filter: Filter by incentive_type ('major', 'highest_order', 'life_area', 'general')
            domain_filter: Filter by life_domain

        Returns:
            List of Values entities matching filters
        """
        # Build database filters
        filters = {}
        if type_filter:
            filters['value_type'] = type_filter.lower()
        if domain_filter:
            filters['life_domain'] = domain_filter

        # Delegate to base class with filters
        return super().get_all(filters=filters if filters else None)

    @staticmethod
    def create_major_value(
        name: str,
        description: str,
        priority: PriorityLevel,
        life_domain: str = 'General',
        alignment_guidance: Optional[str] = None
    ) -> MajorValues:
        """
        Create a MajorValue - actionable value requiring regular tracking.

        MajorValues are commitments that should show up in actions and goals.
        It should be a concern if MajorValues are not reflected in tracked activities.

        Args:
            name: Value name (e.g., "Health", "Family")
            description: What this value means
            priority: Priority level (1 = highest, 100 = lowest)
            life_domain: Life domain categorization (default: 'General')
            alignment_guidance: How this value shows up in actions/goals

        Returns:
            MajorValues instance

        Example:
            >>> value = ValuesStorageService.create_major_value(
            ...     name='Health',
            ...     description='Physical and mental wellbeing',
            ...     priority=PriorityLevel(5),
            ...     life_domain='Personal',
            ...     alignment_guidance='Exercise 3x/week, sleep 8hrs'
            ... )
            >>> isinstance(value, MajorValues)
            True

        Written by Claude Code on 2025-10-13.
        """
        return MajorValues(
            name=name,
            description=description,
            priority=priority,
            life_domain=life_domain,
            alignment_guidance=alignment_guidance
        )

    @staticmethod
    def create_highest_order_value(
        name: str,
        description: str,
        priority: PriorityLevel = PriorityLevel(1),
        life_domain: str = 'General'
    ) -> HighestOrderValues:
        """
        Create a HighestOrderValue - abstract philosophical value.

        HighestOrderValues are high-level concepts not actionable in a daily or
        monthly sense. They provide meaning and context but aren't tracked directly.

        Args:
            name: Value name (e.g., "Flourishing", "Excellence")
            description: What this value means
            priority: Priority level (default: 1 = highest)
            life_domain: Life domain categorization (default: 'General')

        Returns:
            HighestOrderValues instance

        Example:
            >>> value = ValuesStorageService.create_highest_order_value(
            ...     name='Flourishing',
            ...     description='Living a meaningful, excellent life',
            ...     priority=PriorityLevel(1)
            ... )
            >>> isinstance(value, HighestOrderValues)
            True

        Written by Claude Code on 2025-10-13.
        """
        return HighestOrderValues(
            name=name,
            description=description,
            priority=priority,
            life_domain=life_domain
        )

    @staticmethod
    def create_life_area(
        name: str,
        description: str,
        priority: PriorityLevel = PriorityLevel(40),
        life_domain: str = 'General'
    ) -> LifeAreas:
        """
        Create a LifeArea - organizational domain (importantly, NOT a value).

        LifeAreas help explain why certain goals matter without implying they are
        affirmed or recognized as values. They provide structure for organizing
        activities without evaluative judgment.

        Args:
            name: Area name (e.g., "Career", "Family", "Hobbies")
            description: What this area encompasses
            priority: Priority level (default: 40 = mid-range)
            life_domain: Life domain categorization (default: 'General')

        Returns:
            LifeAreas instance

        Example:
            >>> area = ValuesStorageService.create_life_area(
            ...     name='Career',
            ...     description='Professional development and work',
            ...     priority=PriorityLevel(20)
            ... )
            >>> isinstance(area, LifeAreas)
            True

        Written by Claude Code on 2025-10-13.
        """
        return LifeAreas(
            name=name,
            description=description,
            priority=priority,
            life_domain=life_domain
        )

    @staticmethod
    def create_value(
        name: str,
        description: str,
        priority: PriorityLevel = PriorityLevel(50),
        life_domain: str = 'General'
    ) -> Values:
        """
        Create a general Value - aspirational but not primary focus.

        General Values are things you value and affirm, but not necessarily
        tracked regularly in actions and goals. More diffuse than MajorValues.

        Args:
            name: Value name
            description: What this value means
            priority: Priority level (default: 50 = mid-range)
            life_domain: Life domain categorization (default: 'General')

        Returns:
            Values instance

        Example:
            >>> value = ValuesStorageService.create_value(
            ...     name='Kindness',
            ...     description='Being kind to others',
            ...     priority=PriorityLevel(30)
            ... )
            >>> isinstance(value, Values)
            True

        Written by Claude Code on 2025-10-13.
        """
        return Values(
            name=name,
            description=description,
            priority=priority,
            life_domain=life_domain
        )
