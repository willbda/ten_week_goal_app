"""
Terms API endpoints for Ten Week Goal App.

RESTful JSON API for time-bounded planning periods (10-week terms).
Pure orchestration - delegates to rhetorica (storage) and ethica (business logic).

Written by Claude Code on 2025-10-14.
"""

from flask import request, jsonify
from datetime import datetime

from . import api_bp
from rhetorica.storage_service import TermStorageService, GoalStorageService, ActionStorageService
from rhetorica.serializers import serialize, deserialize
from ethica.term_lifecycle import (
    get_active_term,
    get_committed_goals,
    get_overlapping_goals,
    get_actions_in_term,
    calculate_term_progress,
    prepare_terms_list_view,
    get_term_status
)
from categoriae.terms import GoalTerm
from config.logging_setup import get_logger

logger = get_logger(__name__)


# ===== API ENDPOINTS =====

@api_bp.route('/terms', methods=['GET'])
def get_terms():
    """
    GET /api/terms - List all terms with status and metrics.

    Query parameters:
        - status: Filter by status ('active', 'upcoming', 'complete')

    Returns:
        200: JSON array of enriched term objects
        500: Server error

    Example:
        GET /api/terms
        GET /api/terms?status=active
    """
    try:
        term_service = TermStorageService()
        goal_service = GoalStorageService()

        terms = term_service.get_all()
        goals = goal_service.get_all()

        # Use business logic to enrich terms with status/metrics
        enriched_terms = prepare_terms_list_view(terms, goals)

        # Apply status filter if provided
        status_filter = request.args.get('status')
        if status_filter:
            valid_statuses = ['active', 'upcoming', 'complete']
            if status_filter not in valid_statuses:
                return jsonify({
                    'error': f'Invalid status filter. Must be one of: {", ".join(valid_statuses)}'
                }), 400

            enriched_terms = [t for t in enriched_terms if t['status'] == status_filter]

        # Serialize the term objects within enriched data
        for item in enriched_terms:
            item['term'] = serialize(item['term'], include_type=False)

        return jsonify({
            'terms': enriched_terms,
            'count': len(enriched_terms),
            'filters': {
                'status': status_filter
            }
        }), 200

    except Exception as e:
        logger.error(f"Error fetching terms: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/<int:term_id>', methods=['GET'])
def get_term(term_id: int):
    """
    GET /api/terms/<id> - Get single term with metrics.

    Args:
        term_id: Term database ID

    Returns:
        200: JSON term object with status and metrics
        404: Term not found
        500: Server error

    Example:
        GET /api/terms/3
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            return jsonify({'error': f'Term {term_id} not found'}), 404

        goal_service = GoalStorageService()
        goals = goal_service.get_all()

        # Calculate metrics using business logic
        committed = get_committed_goals(term, goals)
        overlapping = get_overlapping_goals(term, goals)
        status = get_term_status(term)
        progress = calculate_term_progress(term, committed)

        return jsonify({
            'term': serialize(term, include_type=False),
            'status': status,
            'days_elapsed': progress['days_elapsed'],
            'days_remaining': progress['days_remaining'],
            'progress_percent': round(progress['percent_time_complete'] * 100, 1),
            'committed_goal_count': len(committed),
            'overlapping_goal_count': len(overlapping)
        }), 200

    except Exception as e:
        logger.error(f"Error fetching term {term_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms', methods=['POST'])
def create_term():
    """
    POST /api/terms - Create new term.

    Request body (JSON):
        term_number: int (required) - Sequential term identifier
        start_date: str (required) - ISO datetime string
        end_date: str (optional) - ISO datetime string (calculated if omitted)
        theme: str (optional) - Focus area for this term
        term_goal_ids: list[int] (optional) - Goal IDs assigned to this term
        reflection: str (optional) - Post-term reflection notes

    Returns:
        201: Created term with ID
        400: Validation error
        500: Server error

    Example:
        POST /api/terms
        {
            "term_number": 4,
            "start_date": "2025-12-23T00:00:00",
            "theme": "New Year Focus",
            "term_goal_ids": [1, 3, 5]
        }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Validate required fields
        if 'term_number' not in data:
            return jsonify({'error': 'Field "term_number" is required'}), 400
        if 'start_date' not in data:
            return jsonify({'error': 'Field "start_date" is required'}), 400

        # Deserialize JSON → GoalTerm entity (handles datetime parsing)
        term = deserialize(data, GoalTerm)

        # Save to database
        service = TermStorageService()
        service.store_single_instance(term)

        logger.info(f"Created term {term.id} (Term #{term.term_number})")

        return jsonify(serialize(term, include_type=False)), 201

    except Exception as e:
        logger.error(f"Error creating term: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/<int:term_id>', methods=['PUT'])
def update_term(term_id: int):
    """
    PUT /api/terms/<id> - Update existing term.

    Args:
        term_id: Term database ID

    Request body (JSON):
        Any term field to update (theme, reflection, start_date, end_date, term_goal_ids)

    Returns:
        200: Updated term
        400: Validation error
        404: Term not found
        500: Server error

    Example:
        PUT /api/terms/3
        {
            "theme": "Updated Theme",
            "reflection": "Completed successfully"
        }
    """
    try:
        service = TermStorageService()
        term = service.get_by_id(term_id)

        if not term:
            return jsonify({'error': f'Term {term_id} not found'}), 404

        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Deserialize updates (handles datetime parsing)
        updates = deserialize(data, GoalTerm)

        # Apply updates to existing term
        for field in data.keys():
            if hasattr(term, field):
                setattr(term, field, getattr(updates, field))

        # Save updated term
        service.save(term, notes=f'Updated via API at {datetime.now().isoformat()}')

        logger.info(f"Updated term {term_id}")

        return jsonify(serialize(term, include_type=False)), 200

    except Exception as e:
        logger.error(f"Error updating term {term_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/<int:term_id>', methods=['DELETE'])
def delete_term(term_id: int):
    """
    DELETE /api/terms/<id> - Delete term (with archiving).

    Args:
        term_id: Term database ID

    Returns:
        200: Deletion confirmation
        404: Term not found
        500: Server error

    Example:
        DELETE /api/terms/3
    """
    try:
        service = TermStorageService()

        # Delete with archiving
        result = service.delete(
            term_id,
            notes=f'Deleted via API at {datetime.now().isoformat()}'
        )

        logger.info(f"Deleted term {term_id}")

        return jsonify({
            'message': f'Term {term_id} deleted successfully',
            'archived': result.get('archived_count', 0) > 0
        }), 200

    except ValueError as e:
        # Term not found
        return jsonify({'error': str(e)}), 404

    except Exception as e:
        logger.error(f"Error deleting term {term_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/active', methods=['GET'])
def get_active_term_endpoint():
    """
    GET /api/terms/active - Get the currently active term.

    Returns:
        200: Active term with metrics, or null if no active term
        500: Server error

    Example:
        GET /api/terms/active
    """
    try:
        term_service = TermStorageService()
        terms = term_service.get_all()

        # Use business logic to find active term
        active_term = get_active_term(terms)

        if not active_term:
            return jsonify({
                'term': None,
                'message': 'No active term found'
            }), 200

        # Get metrics for active term
        goal_service = GoalStorageService()
        goals = goal_service.get_all()

        committed = get_committed_goals(active_term, goals)
        overlapping = get_overlapping_goals(active_term, goals)
        progress = calculate_term_progress(active_term, committed)

        return jsonify({
            'term': serialize(active_term, include_type=False),
            'status': 'active',
            'days_elapsed': progress['days_elapsed'],
            'days_remaining': progress['days_remaining'],
            'progress_percent': round(progress['percent_time_complete'] * 100, 1),
            'committed_goal_count': len(committed),
            'overlapping_goal_count': len(overlapping)
        }), 200

    except Exception as e:
        logger.error(f"Error fetching active term: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/<int:term_id>/goals', methods=['POST'])
def add_goal_to_term(term_id: int):
    """
    POST /api/terms/<id>/goals - Add goal to term.

    Adds a goal ID to the term's term_goal_ids list (commitment).

    Args:
        term_id: Term database ID

    Request body (JSON):
        goal_id: int (required) - ID of goal to add to term

    Returns:
        200: Updated term
        400: Validation error or goal already assigned
        404: Term or goal not found
        500: Server error

    Example:
        POST /api/terms/3/goals
        {
            "goal_id": 7
        }
    """
    try:
        data = request.get_json()

        if not data or 'goal_id' not in data:
            return jsonify({'error': 'Field "goal_id" is required'}), 400

        goal_id = data['goal_id']

        # Verify goal exists
        goal_service = GoalStorageService()
        goal = goal_service.get_by_id(goal_id)

        if not goal:
            return jsonify({'error': f'Goal {goal_id} not found'}), 404

        # Get term
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            return jsonify({'error': f'Term {term_id} not found'}), 404

        # Check if goal already assigned
        if goal_id in term.term_goals_by_id:
            return jsonify({'error': f'Goal {goal_id} already assigned to term {term_id}'}), 400

        # Add goal to term
        term.term_goals_by_id.append(goal_id)

        # Save updated term
        term_service.save(term, notes=f'Added goal {goal_id} via API')

        logger.info(f"Added goal {goal_id} to term {term_id}")

        return jsonify({
            'message': f'Goal {goal_id} added to term {term_id}',
            'term': serialize(term, include_type=False)
        }), 200

    except Exception as e:
        logger.error(f"Error adding goal to term {term_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/<int:term_id>/goals/<int:goal_id>', methods=['DELETE'])
def remove_goal_from_term(term_id: int, goal_id: int):
    """
    DELETE /api/terms/<id>/goals/<goal_id> - Remove goal from term.

    Removes a goal ID from the term's term_goal_ids list.

    Args:
        term_id: Term database ID
        goal_id: Goal database ID

    Returns:
        200: Updated term
        404: Term not found or goal not assigned to term
        500: Server error

    Example:
        DELETE /api/terms/3/goals/7
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            return jsonify({'error': f'Term {term_id} not found'}), 404

        # Check if goal is assigned to this term
        if goal_id not in term.term_goals_by_id:
            return jsonify({'error': f'Goal {goal_id} not assigned to term {term_id}'}), 404

        # Remove goal from term
        term.term_goals_by_id.remove(goal_id)

        # Save updated term
        term_service.save(term, notes=f'Removed goal {goal_id} via API')

        logger.info(f"Removed goal {goal_id} from term {term_id}")

        return jsonify({
            'message': f'Goal {goal_id} removed from term {term_id}',
            'term': serialize(term, include_type=False)
        }), 200

    except Exception as e:
        logger.error(f"Error removing goal from term {term_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/terms/<int:term_id>/progress', methods=['GET'])
def get_term_progress_endpoint(term_id: int):
    """
    GET /api/terms/<id>/progress - Get detailed term progress metrics.

    Returns term with committed goals, overlapping goals, actions, and progress.

    Args:
        term_id: Term database ID

    Returns:
        200: Term with detailed progress breakdown
        404: Term not found
        500: Server error

    Response format:
        {
            "term": {...},
            "status": "active",
            "time_progress": {...},
            "committed_goals": [...],
            "overlapping_goals": [...],
            "actions_in_term": [...]
        }
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            return jsonify({'error': f'Term {term_id} not found'}), 404

        # Fetch goals and actions
        goal_service = GoalStorageService()
        action_service = ActionStorageService()

        goals = goal_service.get_all()
        actions = action_service.get_all()

        # Calculate using business logic
        committed = get_committed_goals(term, goals)
        overlapping = get_overlapping_goals(term, goals)
        term_actions = get_actions_in_term(term, actions)
        status = get_term_status(term)
        progress = calculate_term_progress(term, committed)

        return jsonify({
            'term': serialize(term, include_type=False),
            'status': status,
            'time_progress': {
                'days_elapsed': progress['days_elapsed'],
                'days_remaining': progress['days_remaining'],
                'percent_complete': round(progress['percent_time_complete'] * 100, 1)
            },
            'committed_goals': [serialize(g, include_type=True) for g in committed],
            'overlapping_goals': [serialize(g, include_type=True) for g in overlapping],
            'actions_in_term': [serialize(a, include_type=True) for a in term_actions],
            'counts': {
                'committed_goals': len(committed),
                'overlapping_goals': len(overlapping),
                'actions': len(term_actions)
            }
        }), 200

    except Exception as e:
        logger.error(f"Error fetching progress for term {term_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500
