"""
Translation layer between domain entities (categoriae) and storage (politica).

Written by Claude Code on 2025-10-10
Updated by Claude Code on 2025-10-11
"""

from abc import ABC, abstractmethod
import json
from typing import List, Optional
from categoriae.actions import Action
from categoriae.goals import Goal
from politica.database import Database



class StorageService(ABC):
    """
    Base class for entity storage services.

    Provides common save/load patterns for all entities.
    Subclasses must implement _to_dict() and _from_dict().
    """
    table_name: str = ''

    def __init__(self, database: Optional[Database]=None):
        """
        Initialize storage service with database connection.

        Args:
            database: Database instance. If None, creates default instance
                     with default paths from config.
        """
        self.db = database or Database()

    def store_many_instances(self, entities: List) -> None:
        """
        Store multiple entity instances to database.

        Args:
            entities: List of domain entities (Action, Goal, etc.)

        Returns:
            None - Use get_all() to retrieve stored entities if needed
        """
        formatted_entries = []

        for e in entities:
            entity_dict = self._to_dict(e)
            formatted_entries.append(entity_dict)

        self.db.insert(table=self.table_name, records=formatted_entries)

    def store_single_instance(self, entry) -> None:
        """
        Store a single entity instance to database.

        Args:
            entry: Domain entity (Action, Goal, etc.)

        Returns:
            None - Use get_all() to retrieve stored entities if needed
        """
        self.store_many_instances([entry])

    def get_all(self, filters: Optional[dict] = None) -> List:
        """
        Retrieve all entities from database, optionally filtered.

        Args:
            filters: Optional dict of column:value pairs to filter results

        Returns:
            List of domain entities (Action, Goal, etc.)
        """
        records = self.db.query(self.table_name, filters=filters)
        return [self._from_dict(record) for record in records]

    @abstractmethod
    def _to_dict(self, entity) -> dict:
        """Convert entity to dict for storage"""
    pass
    
    @abstractmethod
    def _from_dict(self, data: dict) -> Goal | Action:
        """Reconstruct entity from stored dict"""
    pass


class GoalStorageService(StorageService):
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

        Handles Optional fields gracefully - converts None to NULL in database.
        """
        goal = entity

        return {
            'description': goal.description,
            'target_value': goal.measurement_target,  # Can be None
            'unit': goal.measurement_unit,            # Can be None
            'start_date': goal.start_date.strftime('%Y-%m-%d') if goal.start_date else None,
            'end_date': goal.end_date.strftime('%Y-%m-%d') if goal.end_date else None,
            'relevance': goal.how_goal_is_relevant,   # Can be None
            'actionability': goal.how_goal_is_actionable  # Can be None
        }

    def _from_dict(self, data: dict) -> Goal:
        """
        Reconstruct Goal object from stored dict.

        Reverse of _to_dict(): Converts database columns back to Goal attributes.
        Maps database column names back to Goal attribute names:
        - unit → measurement_unit
        - target_value → measurement_target
        - ISO date strings → datetime objects
        """
        from datetime import datetime

        # Parse optional datetime fields
        start_date = None
        if data.get('start_date'):
            start_date = datetime.strptime(data['start_date'], '%Y-%m-%d')

        end_date = None
        if data.get('end_date'):
            end_date = datetime.strptime(data['end_date'], '%Y-%m-%d')

        # Reconstruct Goal with all fields
        goal = Goal(
            description=data['description'],
            measurement_unit=data.get('unit'),
            measurement_target=data.get('target_value'),
            start_date=start_date,
            end_date=end_date,
            how_goal_is_relevant=data.get('relevance'),
            how_goal_is_actionable=data.get('actionability')
        )

        return goal


class ActionStorageService(StorageService):
    """Handles translation between Action objects and database storage"""

    table_name = 'actions'

    def _to_dict(self, entity: Action) -> dict:
        """
        Convert Action object to dict for storage.

        Maps Action attributes to database column names.
        """
        action = entity

        # Convert measurements dict to JSON string
        measurements_json = json.dumps(action.measurements) if action.measurements else None

        # Convert datetime to ISO string
        log_time_str = action.logtime.isoformat() if action.logtime else None
        start_time_str = action.starttime.isoformat() if action.starttime else None

        return {
            'description': action.description,
            'log_time': log_time_str,
            'measurements': measurements_json,
            'start_time': start_time_str,
            'duration_minutes': action.duration_minutes
        }

    def _from_dict(self, data: dict) -> Action:
        """
        Reconstruct Action object from stored dict.

        Reverse of _to_dict(): Converts database columns back to Action attributes.
        """
        from datetime import datetime

        # Create action with required description
        action = Action(description=data['description'])

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
