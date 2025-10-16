"""
Values storage service - handles translation between Values entities and database storage.

Refactored for Pythonic clarity on 2025-10-16 by Claude Code.
"""

from typing import Optional, List, Union, TYPE_CHECKING
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel

from rhetorica.storage_service import StorageService

# Module-level constant: Maps incentive_type strings to entity classes
# Used for polymorphic deserialization in _from_dict()
_CLASS_MAP = {
    'major': MajorValues,
    'highest_order': HighestOrderValues,
    'life_area': LifeAreas,
    'general': Values
}


class ValuesStorageService(StorageService):
    """
    Handles translation between Values/MajorValues/HighestOrderValues/LifeAreas and database storage.

    Manages polymorphic values hierarchy by storing incentive_type and reconstructing
    the appropriate class on retrieval using the _CLASS_MAP.
    """

    table_name = 'personal_values'

    def _from_dict(self, data: dict) -> Union[Values, MajorValues, HighestOrderValues, LifeAreas]:
        """
        Reconstruct appropriate Values subclass from stored dict.

        Uses deserialize with polymorphic class selection based on incentive_type.
        Field names match 1:1 with database columns (no renaming needed).
        """
        from rhetorica.serializers import deserialize

        # Determine which class to deserialize to based on incentive_type
        incentive_type = data.get('incentive_type', 'general')
        entity_class = _CLASS_MAP.get(incentive_type, Values)

        # Use deserialize with json_decode=True to parse alignment_guidance
        return deserialize(data, entity_class, json_decode=True)

    def get_all(
        self,
        type_filter: Optional[str] = None,
        domain_filter: Optional[str] = None
    ) -> List[Union[Values, MajorValues, HighestOrderValues, LifeAreas]]:
        """
        Get all values with optional type and domain filtering.

        Filtering at storage layer prevents presentation layers from reimplementing.

        Args:
            type_filter: Filter by class name ('Values', 'MajorValues', 'HighestOrderValues', 'LifeAreas')
            domain_filter: Filter by life_domain

        Returns:
            List of Values entities matching filters
        """
        # Build database filters
        filters = {}
        if type_filter:
            filters['type'] = type_filter  # Now uses class name, not incentive_type
        if domain_filter:
            filters['life_domain'] = domain_filter

        # Delegate to base class with filters
        return super().get_all(filters=filters if filters else None)

    @staticmethod
    def create_value(
        incentive_type: str,
        common_name: str,
        description: str,
        priority: Optional[Union[int, 'PriorityLevel']] = None,
        life_domain: str = 'General',
        alignment_guidance: Optional[str] = None
        ) -> Union[Values, MajorValues, HighestOrderValues, LifeAreas]:
        """Factory method using class registry pattern."""

        # Get the appropriate class from registry
        entity_class = _CLASS_MAP.get(incentive_type)
        if not entity_class:
            raise ValueError(f"Invalid incentive_type: {incentive_type}")

        # Convert priority if provided
        if priority is not None:
            priority = PriorityLevel(priority) if isinstance(priority, int) else priority

        # Build kwargs conditionally
        kwargs = {
            'common_name': common_name,
            'description': description,
            'life_domain': life_domain
        }
        if priority is not None:
            kwargs['priority'] = priority
        if alignment_guidance and incentive_type == 'major':
            kwargs['alignment_guidance'] = alignment_guidance

        return entity_class(**kwargs)
