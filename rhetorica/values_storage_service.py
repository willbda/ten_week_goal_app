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

    def _to_dict(self, entity: Union[Values, MajorValues, HighestOrderValues, LifeAreas]) -> dict:
        """
        Convert any Values subclass to dict for storage.

        Uses generic serializer with json_encode for database compatibility.
        Field names match 1:1 with database columns (no renaming needed).
        """
        from rhetorica.serializers import serialize

        # Use serializer with json_encode=True for database storage
        # Field names in dataclass match DB columns exactly
        return serialize(entity, include_type=False, json_encode=True)

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
        """
        Factory method to create the appropriate Value subclass based on incentive_type.

        This keeps the interface layer free from business logic about class selection.
        The rhetorica layer handles:
        - Translation from type string to concrete class
        - Type conversion (int → PriorityLevel)
        - Default priority values per type

        Args:
            incentive_type: Type of value ('major', 'highest_order', 'life_area', 'general')
            common_name: Value name
            description: What this value means
            priority: Priority level (int or PriorityLevel). If None, uses type-specific defaults.
            life_domain: Life domain categorization (default: 'General')
            alignment_guidance: How this value shows up (MajorValues only)

        Returns:
            Appropriate Values subclass instance

        Raises:
            ValueError: If incentive_type is invalid or priority is out of range
        """

        # Handle priority conversion and defaults
        if priority is None:
            # Type-specific defaults
            defaults = {
                'major': 1,
                'highest_order': 1,
                'life_area': 40,
                'general': 50
            }
            priority = PriorityLevel(defaults.get(incentive_type, 50))
        elif isinstance(priority, int):
            # Convert int to PriorityLevel (validates range)
            priority = PriorityLevel(priority)
        # else: already a PriorityLevel, use as-is

        if incentive_type == 'major':
            return MajorValues(
                common_name=common_name,
                description=description,
                priority=priority,
                life_domain=life_domain,
                alignment_guidance=alignment_guidance
            )
        elif incentive_type == 'highest_order':
            return HighestOrderValues(
                common_name=common_name,
                description=description,
                priority=priority,
                life_domain=life_domain
            )
        elif incentive_type == 'life_area':
            return LifeAreas(
                common_name=common_name,
                description=description,
                priority=priority,
                life_domain=life_domain
            )
        elif incentive_type == 'general':
            return Values(
                common_name=common_name,
                description=description,
                priority=priority,
                life_domain=life_domain
            )
        else:
            raise ValueError(f"Invalid incentive_type: {incentive_type}. Must be one of: major, highest_order, life_area, general")
