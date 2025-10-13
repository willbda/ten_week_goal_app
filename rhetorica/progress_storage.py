"""
Storage service for Action-Goal relationships (progress tracking).

Handles persistence of derived relationships between actions and goals.
Supports three assignment methods:
- auto_inferred: Calculated by matching algorithm
- user_confirmed: User verified an auto-inferred match
- manual: User explicitly created the relationship

Written by Claude Code on 2025-10-12
"""

from typing import List, Optional
from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.relationships import ActionGoalRelationship
from rhetorica.storage_service import ActionStorageService, GoalStorageService
from politica.database import Database
from config.logging_setup import get_logger

logger = get_logger(__name__)


class ActionGoalProgressStorageService:
    """
    Manages persistence of action-goal relationships.

    This service bridges domain relationships (ActionGoalRelationship objects
    with full Action/Goal entities) and storage (database rows with just IDs).

    Supports manual overrides: Users can create, confirm, or remove relationships
    independently of the automatic inference system.
    """

    table_name = 'action_goal_progress'

    def __init__(self, database: Optional[Database] = None):
        """
        Initialize with database connection and entity services.

        Args:
            database: Database instance. If None, creates default instance.
        """
        self.db = database or Database()
        self.action_service = ActionStorageService(database=self.db)
        self.goal_service = GoalStorageService(database=self.db)

    def store_relationships(self, relationships: List[ActionGoalRelationship]) -> int:
        """
        Store multiple action-goal relationships.

        Handles ID lookup transparently: if entities don't have IDs,
        looks them up by matching attributes.

        Args:
            relationships: List of ActionGoalRelationship objects

        Returns:
            int: Number of relationships successfully stored

        Raises:
            ValueError: If action or goal not found in database
        """
        stored_count = 0

        for rel in relationships:
            try:
                self._store_single_relationship(rel)
                stored_count += 1
            except ValueError as e:
                logger.warning(f"Skipping relationship: {e}")
                continue

        logger.info(f"✓ Stored {stored_count}/{len(relationships)} relationships")
        return stored_count

    def _store_single_relationship(self, rel: ActionGoalRelationship) -> None:
        """
        Store a single relationship to database.

        Args:
            rel: ActionGoalRelationship with action and goal entities

        Raises:
            ValueError: If action or goal cannot be found in database
        """
        # Get IDs (either from entities or by lookup)
        action_id = self._get_action_id(rel.action)
        goal_id = self._get_goal_id(rel.goal)

        if not action_id:
            raise ValueError(
                f"Action not found in database: {rel.action.description[:50]}"
            )
        if not goal_id:
            raise ValueError(
                f"Goal not found in database: {rel.goal.description[:50]}"
            )

        # Check if relationship already exists
        existing = self.db.query(self.table_name, filters={
            'action_id': action_id,
            'goal_id': goal_id
        })

        if existing:
            logger.debug(
                f"Relationship already exists: action_id={action_id}, "
                f"goal_id={goal_id}, skipping"
            )
            return

        # Insert new relationship
        self.db.insert(self.table_name, [{
            'action_id': action_id,
            'goal_id': goal_id,
            'contribution': rel.contribution,
            'match_method': rel.assignment_method,
            'confidence': rel.confidence,
            'matched_on': None  # Could extract from rel if we add metadata field
        }])

    def _get_action_id(self, action: Action) -> Optional[int]:
        """
        Get database ID for an action.

        If action.id is set, returns it.
        Otherwise, queries database by description + logtime.

        Args:
            action: Action entity

        Returns:
            Database ID or None if not found
        """
        if action.id is not None:
            return action.id

        # Lookup by unique attributes
        filters = {'description': action.description}
        if action.logtime:
            filters['log_time'] = action.logtime.isoformat()

        results = self.db.query('actions', filters=filters)
        return results[0]['id'] if results else None

    def _get_goal_id(self, goal: Goal) -> Optional[int]:
        """
        Get database ID for a goal.

        If goal.id is set, returns it.
        Otherwise, queries database by description + dates.

        Args:
            goal: Goal entity

        Returns:
            Database ID or None if not found
        """
        if goal.id is not None:
            return goal.id

        # Lookup by unique attributes
        filters = {'description': goal.description}
        if goal.start_date:
            filters['start_date'] = goal.start_date.strftime('%Y-%m-%d')
        if goal.end_date:
            filters['end_date'] = goal.end_date.strftime('%Y-%m-%d')

        results = self.db.query('goals', filters=filters)
        return results[0]['id'] if results else None

    def get_relationships(self,
                         action_id: Optional[int] = None,
                         goal_id: Optional[int] = None,
                         method: Optional[str] = None) -> List[ActionGoalRelationship]:
        """
        Retrieve relationships from database, reconstructed as domain objects.

        Args:
            action_id: Filter by action ID (optional)
            goal_id: Filter by goal ID (optional)
            method: Filter by assignment method: 'auto_inferred',
                   'user_confirmed', or 'manual' (optional)

        Returns:
            List of ActionGoalRelationship objects with full Action/Goal entities
        """
        filters = {}
        if action_id is not None:
            filters['action_id'] = action_id
        if goal_id is not None:
            filters['goal_id'] = goal_id
        if method is not None:
            filters['match_method'] = method

        records = self.db.query(self.table_name, filters=filters)

        relationships = []
        for record in records:
            # Fetch full entities by ID
            action = self.action_service.get_by_id(record['action_id'])
            goal = self.goal_service.get_by_id(record['goal_id'])

            if not action or not goal:
                logger.warning(
                    f"Skipping relationship record - missing entities: "
                    f"action_id={record['action_id']}, goal_id={record['goal_id']}"
                )
                continue

            # Reconstruct domain relationship
            relationships.append(ActionGoalRelationship(
                action=action,
                goal=goal,
                contribution=record['contribution'],
                assignment_method=record['match_method'],
                confidence=record.get('confidence', 1.0)
            ))

        return relationships

    def create_manual_match(self,
                           action_id: int,
                           goal_id: int,
                           contribution: float,
                           reason: str = 'user_override') -> None:
        """
        User explicitly creates a relationship.

        This REPLACES any auto-inferred match for the same action-goal pair.
        Manual matches take precedence and won't be recalculated.

        Args:
            action_id: Database ID of action
            goal_id: Database ID of goal
            contribution: Amount action contributes to goal
            reason: Optional note about why this manual match was created

        Raises:
            ValueError: If action_id or goal_id not found
        """
        # Verify entities exist
        action = self.action_service.get_by_id(action_id)
        goal = self.goal_service.get_by_id(goal_id)

        if not action:
            raise ValueError(f"Action with id={action_id} not found")
        if not goal:
            raise ValueError(f"Goal with id={goal_id} not found")

        # Remove any existing auto-inferred match
        existing_auto = self.db.query(self.table_name, filters={
            'action_id': action_id,
            'goal_id': goal_id,
            'match_method': 'auto_inferred'
        })

        if existing_auto:
            self.db.archive_and_delete(
                self.table_name,
                filters={'action_id': action_id, 'goal_id': goal_id,
                        'match_method': 'auto_inferred'},
                reason='replaced_with_manual',
                notes=reason,
                confirm=True
            )

        # Check if manual match already exists
        existing_manual = self.db.query(self.table_name, filters={
            'action_id': action_id,
            'goal_id': goal_id,
            'match_method': 'manual'
        })

        if existing_manual:
            logger.info(f"Manual match already exists for action={action_id}, goal={goal_id}")
            return

        # Insert manual relationship
        self.db.insert(self.table_name, [{
            'action_id': action_id,
            'goal_id': goal_id,
            'contribution': contribution,
            'match_method': 'manual',
            'confidence': None,  # Not applicable for manual
            'matched_on': reason
        }])

        logger.info(
            f"✓ Created manual match: action={action_id} → goal={goal_id}, "
            f"contribution={contribution}"
        )

    def confirm_auto_match(self, action_id: int, goal_id: int) -> None:
        """
        User confirms an auto-inferred match.

        Changes assignment_method from 'auto_inferred' to 'user_confirmed'.
        Confirmed matches won't be invalidated during cache refresh.

        Args:
            action_id: Database ID of action
            goal_id: Database ID of goal

        Raises:
            ValueError: If no auto-inferred match found for this pair
        """
        # Find existing auto-inferred match
        existing = self.db.query(self.table_name, filters={
            'action_id': action_id,
            'goal_id': goal_id,
            'match_method': 'auto_inferred'
        })

        if not existing:
            raise ValueError(
                f"No auto-inferred match found for action={action_id}, goal={goal_id}"
            )

        # Update to user_confirmed
        record_id = existing[0]['id']
        self.db.update(
            table=self.table_name,
            record_id=record_id,
            updates={'match_method': 'user_confirmed'},
            notes='User confirmed auto-inferred match'
        )

        logger.info(
            f"✓ Confirmed match: action={action_id} → goal={goal_id}"
        )

    def remove_match(self, action_id: int, goal_id: int) -> None:
        """
        Remove a relationship (any method type).

        User explicitly says "this action does NOT match this goal".
        Useful for correcting false positives.

        Args:
            action_id: Database ID of action
            goal_id: Database ID of goal
        """
        self.db.archive_and_delete(
            table=self.table_name,
            filters={'action_id': action_id, 'goal_id': goal_id},
            reason='user_removed',
            notes='User explicitly rejected this match',
            confirm=True
        )

        logger.info(
            f"✓ Removed match: action={action_id} → goal={goal_id}"
        )

    def invalidate_auto_inferred(self, action_id: Optional[int] = None) -> int:
        """
        Clear auto-inferred relationship cache.

        Call this when:
        - Actions/goals change
        - Matching algorithm improves
        - Goal actionability keywords updated

        Manual and user_confirmed relationships are NOT affected.

        Args:
            action_id: If provided, only invalidate for this action.
                      If None, clear ALL auto-inferred relationships.

        Returns:
            int: Number of relationships invalidated
        """
        filters = {'match_method': 'auto_inferred'}
        if action_id is not None:
            filters['action_id'] = action_id

        # Preview what will be deleted
        result = self.db.archive_and_delete(
            table=self.table_name,
            filters=filters,
            reason='invalidated_cache',
            confirm=False
        )

        count = result['count']
        if count == 0:
            logger.info("No auto-inferred relationships to invalidate")
            return 0

        # Actually delete
        self.db.archive_and_delete(
            table=self.table_name,
            filters=filters,
            reason='invalidated_cache',
            notes='Cleared stale auto-inferred cache',
            confirm=True
        )

        logger.info(f"✓ Invalidated {count} auto-inferred relationships")
        return count
