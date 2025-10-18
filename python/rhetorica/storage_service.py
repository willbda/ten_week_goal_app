"""
Translation layer between domain entities (categoriae) and storage (politica).

Contents:
- StorageService: Base class for all storage services
- Simple Storage Services: Goal, Action, Term (entity_class pattern)
- PolymorphicStorageService: Base for polymorphic entities
- Values Storage: ValuesStorageService with type hierarchy


"""

from abc import ABC
from typing import List, Optional, TypeVar, Generic, Protocol, Type, Union, Any
from categoriae.actions import Action
from categoriae.goals import Goal, Milestone, SmartGoal
from categoriae.terms import GoalTerm
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel
from politica.database import Database

# Protocol for entities that can be persisted (have optional id)
class Persistable(Protocol):
    id: Optional[int]

# Generic type variable for entities that can be persisted
T = TypeVar('T', bound=Persistable)



class StorageService(ABC, Generic[T]):
    """
    Base class for entity storage services.

    Provides common save/load patterns for all entities.
    Subclasses can override _to_dict() and _from_dict() for custom behavior.
    """
    table_name: str = ''
    entity_class: Optional[Type[T]] = None  # Override in subclass for automatic _from_dict()

    def __init__(self, database: Optional[Database] = None):
        """
        Initialize storage service with database connection.

        Args:
            database: Database instance. If None, creates default instance
                     with default paths from config.
        """
        self.db = database or Database()

    def store_many_instances(self, entities: List[T]) -> List[T]:
        """
        Store multiple entity instances to database.
        Populates entity.id with database-assigned ID after insert.

        Args:
            entities: List of domain entities (Action, Goal, etc.)

        Returns:
            List[T]: The same entities, now with populated IDs
        """
        formatted_entries = []

        for e in entities:
            entity_dict = self._to_dict(e)
            formatted_entries.append(entity_dict)

        # Insert and get back list of IDs
        inserted_ids = self.db.insert(table=self.table_name, records=formatted_entries)

        # Populate entity IDs
        for entity, db_id in zip(entities, inserted_ids):
            entity.id = db_id

        return entities

    def store_single_instance(self, entry: T) -> T:
        """
        Store a single entity instance to database.
        Populates entry.id with database-assigned ID after insert.

        Args:
            entry: Domain entity (Action, Goal, etc.)

        Returns:
            T: The same entity, now with populated ID
        """
        self.store_many_instances([entry])
        return entry

    def get_all(self, filters: Optional[dict] = None) -> List[T]:
        """
        Retrieve all entities from database, optionally filtered.
        Entities will have their IDs populated from database.

        Args:
            filters: Optional dict of column:value pairs to filter results

        Returns:
            List of domain entities (Action, Goal, etc.) with IDs
        """
        records = self.db.query(self.table_name, filters=filters)
        return [self._from_dict(record) for record in records]

    def get_by_id(self, entity_id: int) -> Optional[T]:
        """
        Retrieve a single entity by its database ID.

        Args:
            entity_id: Database ID of the entity

        Returns:
            Domain entity with ID populated, or None if not found
        """
        records = self.db.query(self.table_name, filters={'id': entity_id})
        if not records:
            return None
        return self._from_dict(records[0])

    def save(self, entity: T, notes: str = '') -> T:
        """
        Intelligently save or update entity based on ID presence.

        If entity has no ID (new entity): Inserts and populates ID
        If entity has ID (existing entity): Updates with archiving

        This is a convenience method that combines store_single_instance()
        and update_instance() into a single "save" operation.

        Args:
            entity: Domain entity to save (Action, Goal, etc.)
            notes: Optional notes for archive (only used if updating)

        Returns:
            T: The entity with ID populated

        Example:
            # Create new
            action = service.save(Action("Run 5km"))  # Inserts, returns with ID

            # Modify and update
            action.description = "Run 10km"
            service.save(action)  # Updates existing record
        """
        entity_id = getattr(entity, 'id', None)

        if entity_id is None:
            # New entity - insert
            return self.store_single_instance(entity)
        else:
            # Existing entity - update
            self.update_instance(entity, notes=notes)
            return entity

    def update_instance(self, entity: T, notes: str = '') -> dict:
        """
        Update an existing entity in the database.

        The entity must have an ID (i.e., must have been retrieved from storage).
        Archives the old version before updating.

        Args:
            entity: Domain entity with ID to update
            notes: Optional notes for archive entry

        Returns:
            Result dict from Database.update()

        Raises:
            ValueError: If entity has no ID (not stored yet)

        Example:
            # Retrieve, modify, update
            action = service.get_all(filters={'description': 'Run 5km'})[0]
            action.description = 'Run 10km'
            service.update_instance(action)
        """
        # Check if entity has an ID
        entity_id = getattr(entity, 'id', None)
        if entity_id is None:
            raise ValueError(
                f"Cannot update entity without ID. Use store_single_instance() for new entities."
            )

        # Convert entity to dict (will include ID)
        entity_dict = self._to_dict(entity)
        entity_dict.pop('id')  # Remove ID from updates dict

        # Call database update
        return self.db.update(
            table=self.table_name,
            record_id=entity_id,
            updates=entity_dict,
            notes=notes
        )

    def delete(self, entity_id: int, notes: str = '') -> dict:
        """
        Delete an entity by ID with archiving.

        Archives the record before deletion for audit trail.

        Args:
            entity_id: Database ID of entity to delete
            notes: Optional notes for archive

        Returns:
            Result dict from Database.archive_and_delete()

        Raises:
            ValueError: If entity_id not found

        Example:
            service = ActionStorageService()
            result = service.delete(5, notes='User requested deletion')
        """
        # Verify entity exists first
        entity = self.get_by_id(entity_id)
        if not entity:
            raise ValueError(
                f"Cannot delete: {self.table_name} with ID {entity_id} not found"
            )

        # Archive and delete through database layer
        result = self.db.archive_and_delete(
            table=self.table_name,
            filters={'id': entity_id},
            confirm=True,  # Bypass preview mode - entity already verified
            notes=notes or f'Deleted {self.table_name} ID {entity_id}'
        )

        return result

    def _to_dict(self, entity: T) -> dict:
        """
        Convert entity to dict for storage.

        Uses generic serializer with json_encode for database compatibility.
        Override this method only if custom serialization logic is needed.

        Default implementation uses rhetorica.serializers.serialize() with
        json_encode=True to handle dataclass conversion for database storage.
        """
        from rhetorica.serializers import serialize
        return serialize(entity, include_type=False, json_encode=True)

    def _from_dict(self, data: dict) -> T:
        """
        Reconstruct entity from stored dict.

        Uses deserialize() with json_decode for standard dataclass entities.
        Override this method for polymorphic entities (like Values hierarchy).

        Requires subclass to set entity_class class attribute.
        """
        from rhetorica.serializers import deserialize

        if self.entity_class is None:
            raise NotImplementedError(
                f"{self.__class__.__name__} must either set entity_class "
                "class attribute or override _from_dict()"
            )

        return deserialize(data, self.entity_class, json_decode=True)





class ActionStorageService(StorageService[Action]):
    """
    Handles translation between Action objects and database storage.

    Uses generic dataclass serialization via rhetorica.serializers.
    """

    table_name = 'actions'
    entity_class = Action


class TermStorageService(StorageService[GoalTerm]):
    """
    Handles translation between GoalTerm objects and database storage.

    Terms are commitment containers that organize goals into temporal planning periods.
    This service manages the translation of:
    - Date fields (start_date, target_date)
    - Goal ID lists (stored as JSON array)
    - Optional theme and reflection text

    Written by Claude Code on 2025-10-13
    """

    table_name = 'terms'
    entity_class = GoalTerm


# ============================================================================
# POLYMORPHIC STORAGE SERVICES
# ============================================================================
# For entities with type hierarchies that require dynamic class selection
# during deserialization (e.g., Values → MajorValues → HighestOrderValues)
# ============================================================================


class PolymorphicStorageService(StorageService):
    """
    Base class for storage services handling polymorphic entities.

    Provides common patterns for storing and retrieving entities with type hierarchies.
    Subclasses should define CLASS_MAP to map type identifiers to classes.
    """

    CLASS_MAP: dict = {}


class ValuesStorageService(PolymorphicStorageService):
    """
    Handles translation between Values/MajorValues/HighestOrderValues/LifeAreas and database storage.

    Manages polymorphic values hierarchy by storing incentive_type and reconstructing
    the appropriate class on retrieval using the CLASS_MAP.
    """

    CLASS_MAP = {
        'major': MajorValues,
        'highest_order': HighestOrderValues,
        'life_area': LifeAreas,
        'general': Values
    }

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
        entity_class = self.CLASS_MAP.get(incentive_type, Values)

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

    def create_value(
        self,
        incentive_type: str,
        common_name: str,
        description: str,
        priority: Optional[int] = None,
        life_domain: str = 'General',
        alignment_guidance: Optional[str] = None
    ) -> Union[Values, MajorValues, HighestOrderValues, LifeAreas]:
        """Factory method using class registry pattern."""

        # Get the appropriate class from registry
        entity_class = self.CLASS_MAP.get(incentive_type)
        if not entity_class:
            raise ValueError(f"Invalid incentive_type: {incentive_type}")

        # Build kwargs conditionally (using Any to avoid type checker issues with Union types)
        kwargs: dict[str, Any] = {
            'common_name': common_name,
            'description': description,
            'life_domain': life_domain
        }

        # Convert priority if provided (input is int, entities expect PriorityLevel)
        if priority is not None:
            kwargs['priority'] = PriorityLevel(priority)

        if alignment_guidance and incentive_type == 'major':
            kwargs['alignment_guidance'] = alignment_guidance

        return entity_class(**kwargs)

class GoalStorageService(PolymorphicStorageService):
    """
    Handles translation between Goal/Milestone/SmartGoal objects and database storage.

    Manages polymorphic goals hierarchy by storing goal_type and reconstructing
    the appropriate class on retrieval using the CLASS_MAP.

    Works with:
    - Goal: General objectives (optional fields)
    - Milestone: Date-bound checkpoints with target_date
    - SmartGoal: Fully validated SMART goals (all required fields)

    Written by Claude Code on 2025-10-17
    """

    CLASS_MAP = {
        'Goal': Goal,
        'Milestone': Milestone,
        'SmartGoal': SmartGoal
    }

    table_name = 'goals'

    def _from_dict(self, data: dict) -> Union[Goal, Milestone, SmartGoal]:
        """
        Reconstruct appropriate Goal subclass from stored dict.

        Uses deserialize with polymorphic class selection based on goal_type.
        Updated to use target_date field consistently.
        """
        from rhetorica.serializers import deserialize

        # Determine which class to deserialize to based on goal_type
        goal_type = data.get('goal_type', 'Goal')
        entity_class = self.CLASS_MAP.get(goal_type, Goal)

        # Use deserialize with json_decode=True for any JSON fields
        return deserialize(data, entity_class, json_decode=True)

    def get_all(
        self,
        type_filter: Optional[str] = None,
        filters: Optional[dict] = None
    ) -> List[Union[Goal, Milestone, SmartGoal]]:
        """
        Get all goals with optional type filtering.

        Filtering at storage layer prevents presentation layers from reimplementing.

        Args:
            type_filter: Filter by class name ('Goal', 'Milestone', 'SmartGoal')
            filters: Additional database filters (dict of column:value pairs)

        Returns:
            List of Goal entities matching filters
        """
        # Build database filters
        db_filters = filters.copy() if filters else {}

        if type_filter:
            db_filters['goal_type'] = type_filter

        # Delegate to base class with filters
        return super().get_all(filters=db_filters if db_filters else None)