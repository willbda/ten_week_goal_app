"""
Translation layer between domain entities (categoriae) and storage (politica).

Written by Claude Code on 2025-10-10
Updated by Claude Code on 2025-10-11
"""

from abc import ABC, abstractmethod
import json
from typing import List, Optional, Union, TypeVar, Generic, Protocol
from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel
from politica.database import Database

# Protocol for entities that can be persisted (have optional id)
class Persistable(Protocol):
    id: Optional[int]

# Generic type variable for entities that can be persisted
T = TypeVar('T', bound=Persistable)

# Type alias for Values hierarchy
ValuesType = Union[Values, MajorValues, HighestOrderValues, LifeAreas]



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
    """

    table_name = 'goals'

    def _to_dict(self, entity: Goal) -> dict:
        """
        Convert Goal or SmartGoal object to dict for storage.

        Maps Goal attributes to database column names:
        - measurement_unit → unit
        - measurement_target → target_value
        - start_date/end_date → ISO strings (YYYY-MM-DD)
        - created_at → ISO timestamp string

        Handles Optional fields gracefully - converts None to NULL in database.
        Includes ID only if present (for updates).
        """
        goal = entity

        result = {
            'description': goal.description,
            'target_value': goal.measurement_target,  # Can be None
            'unit': goal.measurement_unit,            # Can be None
            'start_date': goal.start_date.strftime('%Y-%m-%d') if goal.start_date else None,
            'end_date': goal.end_date.strftime('%Y-%m-%d') if goal.end_date else None,
            'relevance': goal.how_goal_is_relevant,   # Can be None
            'actionability': goal.how_goal_is_actionable,  # Can be None
            'expected_term_length': goal.expected_term_length,  # Can be None
            'created_at': goal.created_at.isoformat() if goal.created_at else None
        }

        # Include ID only if entity has one (stored entities)
        if goal.id is not None:
            result['id'] = goal.id

        return result

    def _from_dict(self, data: dict) -> Goal:
        """
        Reconstruct Goal object from stored dict.

        Reverse of _to_dict(): Converts database columns back to Goal attributes.
        Maps database column names back to Goal attribute names:
        - unit → measurement_unit
        - target_value → measurement_target
        - ISO date strings → datetime objects
        - ISO timestamp string → created_at datetime
        Includes ID from database.
        """
        from datetime import datetime

        # Parse optional datetime fields
        start_date = None
        if data.get('start_date'):
            start_date = datetime.strptime(data['start_date'], '%Y-%m-%d')

        end_date = None
        if data.get('end_date'):
            end_date = datetime.strptime(data['end_date'], '%Y-%m-%d')

        created_at = None
        if data.get('created_at'):
            created_at = datetime.fromisoformat(data['created_at'])

        # Reconstruct Goal with all fields including ID
        goal = Goal(
            description=data['description'],
            measurement_unit=data.get('unit'),
            measurement_target=data.get('target_value'),
            start_date=start_date,
            end_date=end_date,
            how_goal_is_relevant=data.get('relevance'),
            how_goal_is_actionable=data.get('actionability'),
            expected_term_length=data.get('expected_term_length'),
            created_at=created_at,
            id=data.get('id')  # Extract ID from stored record
        )

        return goal


class ActionStorageService(StorageService[Action]):
    """Handles translation between Action objects and database storage"""

    table_name = 'actions'

    def _to_dict(self, entity: Action) -> dict:
        """
        Convert Action object to dict for storage.

        Maps Action attributes to database column names.
        Includes ID only if present (for updates).
        """
        action = entity

        # Convert measurements dict to JSON string
        measurements_json = json.dumps(action.measurements) if action.measurements else None

        # Convert datetime to ISO string
        log_time_str = action.logtime.isoformat() if action.logtime else None
        start_time_str = action.starttime.isoformat() if action.starttime else None

        result = {
            'description': action.description,
            'log_time': log_time_str,
            'measurements': measurements_json,
            'start_time': start_time_str,
            'duration_minutes': action.duration_minutes
        }

        # Include ID only if entity has one (stored entities)
        if action.id is not None:
            result['id'] = action.id

        return result

    def _from_dict(self, data: dict) -> Action:
        """
        Reconstruct Action object from stored dict.

        Reverse of _to_dict(): Converts database columns back to Action attributes.
        Includes ID from database.
        """
        from datetime import datetime

        # Create action with required description and ID
        action = Action(
            description=data['description'],
            id=data.get('id')  # Extract ID from stored record
        )

        # Reconstruct optional datetime fields
        if data.get('log_time'):
            action.logtime = datetime.fromisoformat(data['log_time'])

        if data.get('start_time'):
            action.starttime = datetime.fromisoformat(data['start_time'])

        # Reconstruct measurements from JSON string
        if data.get('measurements'):
            action.measurements = json.loads(data['measurements'])

        # Reconstruct duration
        if data.get('duration_minutes'):
            action.duration_minutes = data['duration_minutes']

        return action


class ValuesStorageService(StorageService):
    """
    Handles translation between Values/MajorValues/HighestOrderValues objects and database storage.

    Manages polymorphic values hierarchy by storing value_type and reconstructing
    the appropriate class on retrieval.
    """

    table_name = 'personal_values'  # 'values' is SQL reserved keyword

    def _to_dict(self, entity: Union[Values, MajorValues, HighestOrderValues, LifeAreas]) -> dict:
        """
        Convert any Values subclass to dict for storage.

        Determines value_type from class:
        - MajorValues → 'major'
        - HighestOrderValues → 'highest_order'
        - LifeAreas → 'life_area'
        - Values (base) → 'general'

        Handles alignment_guidance flexibly (can be dict, str, or None).
        Includes ID only if present (for updates).
        """
        value = entity

        # Determine value_type from class
        if isinstance(value, MajorValues):
            value_type = 'major'
        elif isinstance(value, HighestOrderValues):
            value_type = 'highest_order'
        elif isinstance(value, LifeAreas):
            value_type = 'life_area'
        else:
            value_type = 'general'

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
            'value_type': value_type,
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

        Reads value_type to determine which class to instantiate:
        - 'major' → MajorValues
        - 'highest_order' → HighestOrderValues
        - 'life_area' → LifeAreas
        - 'general' → Values

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

        # Reconstruct appropriate class based on value_type
        if value_type == 'major':
            return MajorValues(
                name=data['name'],
                description=data['description'],
                priority=priority,
                life_domain=data.get('life_domain', 'General'),
                alignment_guidance=alignment_guidance,
                id=value_id
            )
        elif value_type == 'highest_order':
            return HighestOrderValues(
                name=data['name'],
                description=data['description'],
                priority=priority,
                life_domain=data.get('life_domain', 'General'),
                id=value_id
            )
        elif value_type == 'life_area':
            return LifeAreas(
                name=data['name'],
                description=data['description'],
                priority=priority,
                life_domain=data.get('life_domain', 'General'),
                id=value_id
            )
        else:  # 'general'
            return Values(
                name=data['name'],
                description=data['description'],
                priority=priority,
                life_domain=data.get('life_domain', 'General'),
                id=value_id
            )
