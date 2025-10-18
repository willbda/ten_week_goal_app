"""
Goals API endpoints for Ten Week Goal App.

RESTful JSON API for goal management and progress tracking.
Pure orchestration - delegates to rhetorica (storage) and ethica (business logic).

Written by Claude Code on 2025-10-14.
"""

from flask import request, jsonify
from datetime import datetime

from . import api_bp
from rhetorica.storage_service import GoalStorageService, ActionStorageService
from rhetorica.serializers import serialize, deserialize
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_goal_progress
from categoriae.goals import Goal, Milestone, SmartGoal
from config.logging_setup import get_logger

logger = get_logger(__name__)

@api_bp.route('/goals', methods=['GET'])
def get_goals():
    """
    GET /api/goals - List all goals.

    Query parameters:
        - has_dates: Filter for time-bound goals (true/false)
        - has_target: Filter for measurable goals (true/false)
        - type: Filter by goal type (Goal, Milestone, SmartGoal)

    Returns:
        200: JSON array of goal objects with type information
        500: Server error

    Example:
        GET /api/goals
        GET /api/goals?has_dates=true
        GET /api/goals?type=SmartGoal
    """
    try:
        service = GoalStorageService()

        # Get type filter from query params
        type_filter = request.args.get('type')
        goals = service.get_all(type_filter=type_filter)

        # Apply additional filters from query params
        has_dates = request.args.get('has_dates', '').lower() == 'true'
        has_target = request.args.get('has_target', '').lower() == 'true'

        if has_dates:
            goals = [g for g in goals if g.is_time_bound()]

        if has_target:
            goals = [g for g in goals if g.is_measurable()]

        # Serialize goals (include_type=True adds 'type' field with class name)
        goals_data = [serialize(g, include_type=True) for g in goals]

        return jsonify({
            'goals': goals_data,
            'count': len(goals_data)
        }), 200

    except Exception as e:
        logger.error(f"Error fetching goals: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/goals/<int:goal_id>', methods=['GET'])
def get_goal(goal_id: int):
    """
    GET /api/goals/<id> - Get single goal by ID.

    Args:
        goal_id: Goal database ID

    Returns:
        200: JSON goal object
        404: Goal not found
        500: Server error

    Example:
        GET /api/goals/1
    """
    try:
        service = GoalStorageService()
        goal = service.get_by_id(goal_id)

        if not goal:
            return jsonify({'error': f'Goal {goal_id} not found'}), 404

        return jsonify(serialize(goal, include_type=True)), 200

    except Exception as e:
        logger.error(f"Error fetching goal {goal_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/goals', methods=['POST'])
def create_goal():
    """
    POST /api/goals - Create new goal.

    Request body (JSON):
        goal_type: str (optional) - Type of goal: "Goal", "Milestone", or "SmartGoal" (default: "Goal")
        description: str (required) - Goal description
        measurement_unit: str (optional) - Unit of measurement
        measurement_target: float (optional) - Target value
        start_date: str (optional) - ISO datetime string (for date ranges)
        target_date: str (optional) - ISO datetime string (target completion date)
        how_goal_is_relevant: str (optional) - Relevance statement
        how_goal_is_actionable: str (optional) - Actionability statement
        expected_term_length: int (optional) - Expected duration in weeks

    Returns:
        201: Created goal with ID and type
        400: Validation error
        500: Server error

    Example (SmartGoal):
        POST /api/goals
        {
            "goal_type": "SmartGoal",
            "description": "Run 120km",
            "measurement_unit": "km",
            "measurement_target": 120.0,
            "start_date": "2025-10-10T00:00:00",
            "target_date": "2025-12-19T00:00:00",
            "how_goal_is_relevant": "Improve fitness",
            "how_goal_is_actionable": "Run 3x per week"
        }

    Example (Milestone):
        POST /api/goals
        {
            "goal_type": "Milestone",
            "description": "Reach 50km by week 5",
            "measurement_unit": "km",
            "measurement_target": 50.0,
            "target_date": "2025-11-15T00:00:00"
        }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Validate required field
        if 'description' not in data or not data['description']:
            return jsonify({'error': 'Field "description" is required'}), 400

        # Determine goal type and select appropriate class
        goal_type = data.get('goal_type', 'Goal')
        goal_classes = {
            'Goal': Goal,
            'Milestone': Milestone,
            'SmartGoal': SmartGoal
        }

        entity_class = goal_classes.get(goal_type, Goal)

        # Deserialize JSON → Goal entity (handles datetime parsing automatically)
        # This will raise ValueError if SmartGoal validation fails
        goal = deserialize(data, entity_class)

        # Save to database
        service = GoalStorageService()
        service.store_single_instance(goal)

        logger.info(f"Created {goal_type} {goal.id}: {goal.description}")

        return jsonify(serialize(goal, include_type=True)), 201

    except ValueError as e:
        # Validation errors (e.g., SmartGoal missing required fields)
        logger.warning(f"Validation error creating goal: {e}")
        return jsonify({'error': str(e)}), 400

    except Exception as e:
        logger.error(f"Error creating goal: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/goals/<int:goal_id>', methods=['PUT'])
def update_goal(goal_id: int):
    """
    PUT /api/goals/<id> - Update existing goal.

    Args:
        goal_id: Goal database ID

    Request body (JSON):
        Any goal field to update (description, measurement_unit, etc.)

    Returns:
        200: Updated goal
        400: Validation error
        404: Goal not found
        500: Server error

    Example:
        PUT /api/goals/1
        {
            "description": "Run 150km",
            "measurement_target": 150.0
        }
    """
    try:
        service = GoalStorageService()
        goal = service.get_by_id(goal_id)

        if not goal:
            return jsonify({'error': f'Goal {goal_id} not found'}), 404

        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Deserialize updates (handles datetime parsing, etc.)
        updates = deserialize(data, Goal)

        # Apply updates to existing goal
        for field in data.keys():
            if hasattr(goal, field):
                setattr(goal, field, getattr(updates, field))

        # Save updated goal
        service.save(goal, notes=f'Updated via API at {datetime.now().isoformat()}')

        logger.info(f"Updated goal {goal_id}")

        return jsonify(serialize(goal, include_type=True)), 200

    except Exception as e:
        logger.error(f"Error updating goal {goal_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/goals/<int:goal_id>', methods=['DELETE'])
def delete_goal(goal_id: int):
    """
    DELETE /api/goals/<id> - Delete goal (with archiving).

    Args:
        goal_id: Goal database ID

    Returns:
        200: Deletion confirmation
        404: Goal not found
        500: Server error

    Example:
        DELETE /api/goals/1
    """
    try:
        service = GoalStorageService()

        # Delete with archiving
        result = service.delete(
            goal_id,
            notes=f'Deleted via API at {datetime.now().isoformat()}'
        )

        logger.info(f"Deleted goal {goal_id}")

        return jsonify({
            'message': f'Goal {goal_id} deleted successfully',
            'archived': result.get('archived_count', 0) > 0
        }), 200

    except ValueError as e:
        # Goal not found
        return jsonify({'error': str(e)}), 404

    except Exception as e:
        logger.error(f"Error deleting goal {goal_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/goals/<int:goal_id>/progress', methods=['GET'])
def get_goal_progress(goal_id: int):
    """
    GET /api/goals/<id>/progress - Get goal with detailed progress metrics.

    Calculates progress by matching actions to this goal and aggregating contributions.

    Args:
        goal_id: Goal database ID

    Returns:
        200: Goal with progress metrics and matching actions
        404: Goal not found
        500: Server error

    Response format:
        {
            "goal": {...},
            "progress": {
                "total_progress": 102.5,
                "target": 120.0,
                "percent": 85.4,
                "remaining": 17.5,
                "is_complete": false,
                "is_overachieved": false,
                "matching_actions_count": 23,
                "unit": "km"
            },
            "matches": [...]
        }
    """
    try:
        goal_service = GoalStorageService()
        goal = goal_service.get_by_id(goal_id)

        if not goal:
            return jsonify({'error': f'Goal {goal_id} not found'}), 404

        # Fetch all actions for matching
        action_service = ActionStorageService()
        actions = action_service.get_all()

        # Infer matches for this goal
        all_matches = infer_matches(actions, [goal])

        # Calculate progress metrics
        progress = aggregate_goal_progress(goal, all_matches)

        # Serialize matches (list of ActionGoalRelationship objects)
        matches_data = []
        for match in all_matches:
            matches_data.append({
                'action_id': match.action.id,
                'action_description': match.action.common_name,
                'contribution': match.contribution,
                'assignment_method': match.assignment_method,
                'confidence': match.confidence
            })

        return jsonify({
            'goal': serialize(goal, include_type=True),
            'progress': {
                'total_progress': progress.total_progress,
                'target': progress.target,
                'percent': round(progress.percent, 1),
                'remaining': progress.remaining,
                'is_complete': progress.is_complete,
                'is_overachieved': progress.is_overachieved,
                'matching_actions_count': progress.matching_actions_count,
                'unit': progress.unit
            },
            'matches': matches_data
        }), 200

    except Exception as e:
        logger.error(f"Error fetching progress for goal {goal_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500
