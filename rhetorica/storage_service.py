"""
Translation layer between domain entities (categoriae) and storage (politica).

Written by Claude Code on 2025-10-10
Updated by Claude Code on 2025-10-11
"""

from abc import ABC, abstractmethod
from typing import List, Optional, TypeVar, Generic, Protocol
from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.terms import GoalTerm
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
    Subclasses must implement _to_dict() and _from_dict().
    """
    table_name: str = ''

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

    @abstractmethod
    def _to_dict(self, entity: T) -> dict:
        """Convert entity to dict for storage"""
        pass

    @abstractmethod
    def _from_dict(self, data: dict) -> T:
        """Reconstruct entity from stored dict"""
        pass


class GoalStorageService(StorageService[Goal]):
    """
    Handles translation between Goal/SmartGoal objects and database storage.

    Works with both loose Goals (optional fields) and strict SmartGoals (all required).
    Uses generic dataclass serialization via rhetorica.serializers.
    """

    table_name = 'goals'

    def _to_dict(self, entity: Goal) -> dict:
        """
        Convert Goal or SmartGoal object to dict for storage.

        Uses serialize() with dataclass field introspection to handle formatting.
        No manual field mapping needed - entity fields match DB columns.
        """
        from rhetorica.serializers import serialize

        # Use serialize with json_encode=True for database storage (exclude 'type')
        return serialize(entity, include_type=False, json_encode=True)

    def _from_dict(self, data: dict) -> Goal:
        """
        Reconstruct Goal object from stored dict.

        Uses deserialize() to automatically parse all fields based on
        dataclass field type annotations.
        """
        from rhetorica.serializers import deserialize
        return deserialize(data, Goal, json_decode=True)


class ActionStorageService(StorageService[Action]):
    """
    Handles translation between Action objects and database storage.

    Uses generic dataclass serialization via rhetorica.serializers.
    """

    table_name = 'actions'

    def _to_dict(self, entity: Action) -> dict:
        """
        Convert Action object to dict for storage.

        Uses serialize() - measurements dict is automatically converted to JSON string
        based on dataclass field type annotations.
        """
        from rhetorica.serializers import serialize
        return serialize(entity, include_type=False, json_encode=True)

    def _from_dict(self, data: dict) -> Action:
        """
        Reconstruct Action object from stored dict.

        Uses deserialize() to automatically parse all fields based on
        dataclass field type annotations.
        """
        from rhetorica.serializers import deserialize
        return deserialize(data, Action, json_decode=True)


class TermStorageService(StorageService[GoalTerm]):
    """
    Handles translation between GoalTerm objects and database storage.

    Terms are commitment containers that organize goals into temporal planning periods.
    This service manages the translation of:
    - Date fields (start_date, end_date)
    - Goal ID lists (stored as JSON array)
    - Optional theme and reflection text

    Written by Claude Code on 2025-10-13
    """

    table_name = 'terms'

    def _to_dict(self, entity: GoalTerm) -> dict:
        """
        Convert GoalTerm object to dict for storage.

        Uses serialize() - term_goal_ids list is automatically converted to JSON string
        based on dataclass field type annotations.
        """
        from rhetorica.serializers import serialize
        return serialize(entity, include_type=False, json_encode=True)

    def _from_dict(self, data: dict) -> GoalTerm:
        """
        Reconstruct GoalTerm object from stored dict.

        Uses deserialize() to automatically parse all fields based on
        dataclass field type annotations.
        """
        from rhetorica.serializers import deserialize
        return deserialize(data, GoalTerm, json_decode=True)


