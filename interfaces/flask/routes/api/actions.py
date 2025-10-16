"""
Actions API endpoints for Ten Week Goal App.

RESTful JSON API for action management and goal matching.
Pure orchestration - delegates to rhetorica (storage) and ethica (business logic).

Written by Claude Code on 2025-10-14.
"""

from flask import request, jsonify
from datetime import datetime

from . import api_bp
from rhetorica.storage_service import ActionStorageService, GoalStorageService
from rhetorica.serializers import serialize, deserialize
from ethica.progress_matching import infer_matches
from categoriae.actions import Action
from config.logging_setup import get_logger

logger = get_logger(__name__)

@api_bp.route('/actions', methods=['GET'])
def get_actions():
    """
    GET /api/actions - List all actions.

    Query parameters:
        - has_measurements: Filter for actions with measurements (true/false)
        - has_duration: Filter for actions with duration tracking (true/false)
        - start_date: Filter for actions after this date (ISO format)
        - end_date: Filter for actions before this date (ISO format)

    Returns:
        200: JSON array of action objects
        500: Server error

    Example:
        GET /api/actions
        GET /api/actions?has_measurements=true
        GET /api/actions?start_date=2025-10-01&end_date=2025-10-31
    """
    try:
        service = ActionStorageService()
        actions = service.get_all()

        # Apply filters from query params
        has_measurements = request.args.get('has_measurements', '').lower() == 'true'
        has_duration = request.args.get('has_duration', '').lower() == 'true'
        start_date_str = request.args.get('start_date')
        end_date_str = request.args.get('end_date')

        if has_measurements:
            actions = [a for a in actions if a.measurements is not None]

        if has_duration:
            actions = [a for a in actions if a.duration_minutes is not None]

        # Date range filtering
        if start_date_str:
            try:
                start_date = datetime.fromisoformat(start_date_str)
                actions = [a for a in actions if a.log_time and a.log_time >= start_date]
            except ValueError:
                return jsonify({'error': f'Invalid start_date format: {start_date_str}. Use ISO format.'}), 400

        if end_date_str:
            try:
                end_date = datetime.fromisoformat(end_date_str)
                actions = [a for a in actions if a.log_time and a.log_time <= end_date]
            except ValueError:
                return jsonify({'error': f'Invalid end_date format: {end_date_str}. Use ISO format.'}), 400

        # Serialize actions
        actions_data = [serialize(a, include_type=True) for a in actions]

        return jsonify({
            'actions': actions_data,
            'count': len(actions_data)
        }), 200

    except Exception as e:
        logger.error(f"Error fetching actions: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/actions/<int:action_id>', methods=['GET'])
def get_action(action_id: int):
    """
    GET /api/actions/<id> - Get single action by ID.

    Args:
        action_id: Action database ID

    Returns:
        200: JSON action object
        404: Action not found
        500: Server error

    Example:
        GET /api/actions/1
    """
    try:
        service = ActionStorageService()
        action = service.get_by_id(action_id)

        if not action:
            return jsonify({'error': f'Action {action_id} not found'}), 404

        return jsonify(serialize(action, include_type=True)), 200

    except Exception as e:
        logger.error(f"Error fetching action {action_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/actions', methods=['POST'])
def create_action():
    """
    POST /api/actions - Create new action.

    Request body (JSON):
        description: str (required) - Action description
        measurements: dict (optional) - Measurements dict (e.g., {"distance_km": 5.0})
        duration_minutes: float (optional) - Duration in minutes
        start_time: str (optional) - ISO datetime string
        log_time: str (optional) - ISO datetime string (defaults to now)

    Returns:
        201: Created action with ID
        400: Validation error
        500: Server error

    Example:
        POST /api/actions
        {
            "description": "Ran in the park",
            "measurements": {"distance_km": 5.2},
            "duration_minutes": 32.5,
            "start_time": "2025-10-14T07:00:00"
        }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Validate required field
        if 'description' not in data or not data['description']:
            return jsonify({'error': 'Field "description" is required'}), 400

        # Deserialize JSON → Action entity (handles datetime parsing automatically)
        action = deserialize(data, Action)

        # Save to database
        service = ActionStorageService()
        service.store_single_instance(action)

        logger.info(f"Created action {action.id}: {action.description}")

        return jsonify(serialize(action, include_type=True)), 201

    except Exception as e:
        logger.error(f"Error creating action: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/actions/<int:action_id>', methods=['PUT'])
def update_action(action_id: int):
    """
    PUT /api/actions/<id> - Update existing action.

    Args:
        action_id: Action database ID

    Request body (JSON):
        Any action field to update (description, measurements, duration_minutes, etc.)

    Returns:
        200: Updated action
        400: Validation error
        404: Action not found
        500: Server error

    Example:
        PUT /api/actions/1
        {
            "description": "Ran in the park (morning)",
            "measurements": {"distance_km": 6.0}
        }
    """
    try:
        service = ActionStorageService()
        action = service.get_by_id(action_id)

        if not action:
            return jsonify({'error': f'Action {action_id} not found'}), 404

        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Deserialize updates (handles datetime parsing, etc.)
        updates = deserialize(data, Action)

        # Apply updates to existing action
        for field in data.keys():
            if hasattr(action, field):
                setattr(action, field, getattr(updates, field))

        # Save updated action
        service.save(action, notes=f'Updated via API at {datetime.now().isoformat()}')

        logger.info(f"Updated action {action_id}")

        return jsonify(serialize(action, include_type=True)), 200

    except Exception as e:
        logger.error(f"Error updating action {action_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/actions/<int:action_id>', methods=['DELETE'])
def delete_action(action_id: int):
    """
    DELETE /api/actions/<id> - Delete action (with archiving).

    Args:
        action_id: Action database ID

    Returns:
        200: Deletion confirmation
        404: Action not found
        500: Server error

    Example:
        DELETE /api/actions/1
    """
    try:
        service = ActionStorageService()

        # Delete with archiving
        result = service.delete(
            action_id,
            notes=f'Deleted via API at {datetime.now().isoformat()}'
        )

        logger.info(f"Deleted action {action_id}")

        return jsonify({
            'message': f'Action {action_id} deleted successfully',
            'archived': result.get('archived_count', 0) > 0
        }), 200

    except ValueError as e:
        # Action not found
        return jsonify({'error': str(e)}), 404

    except Exception as e:
        logger.error(f"Error deleting action {action_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/actions/<int:action_id>/goals', methods=['GET'])
def get_action_goals(action_id: int):
    """
    GET /api/actions/<id>/goals - Get goals matched to this action.

    Infers relationships between this action and all goals using business logic.

    Args:
        action_id: Action database ID

    Returns:
        200: Action with matched goals and relationship details
        404: Action not found
        500: Server error

    Response format:
        {
            "action": {...},
            "matched_goals": [
                {
                    "goal_id": 1,
                    "goal_description": "Run 120km",
                    "contribution": 5.2,
                    "assignment_method": "unit_match",
                    "confidence": 0.95
                },
                ...
            ],
            "match_count": 3
        }
    """
    try:
        action_service = ActionStorageService()
        action = action_service.get_by_id(action_id)

        if not action:
            return jsonify({'error': f'Action {action_id} not found'}), 404

        # Fetch all goals for matching
        goal_service = GoalStorageService()
        goals = goal_service.get_all()

        # Infer matches for this action (infer_matches expects lists)
        matches = infer_matches(actions=[action], goals=goals)

        # Serialize matches (list of ActionGoalRelationship objects)
        matches_data = []
        for match in matches:
            matches_data.append({
                'goal_id': match.goal.id,
                'goal_description': match.goal.description,
                'contribution': match.contribution,
                'assignment_method': match.assignment_method,
                'confidence': match.confidence
            })

        return jsonify({
            'action': serialize(action, include_type=True),
            'matched_goals': matches_data,
            'match_count': len(matches_data)
        }), 200

    except Exception as e:
        logger.error(f"Error fetching goals for action {action_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500