"""
Terms API endpoints.

Provides term management and goal assignment operations.

Written by Claude Code on 2025-10-14
"""

from flask import Blueprint, jsonify, request
import sys
from pathlib import Path
from datetime import datetime, timedelta

sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from rhetorica.storage_service import TermStorageService, GoalStorageService
from categoriae.terms import GoalTerm
from ethica.term_lifecycle import get_term_status, validate_goal_term_assignment
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint
terms_bp = Blueprint('terms', __name__, url_prefix='/api')


# ===== ROUTES =====

@terms_bp.route('/terms', methods=['GET'])
def api_terms_list():
    """
    GET /api/terms - List all terms with status.

    Returns:
        JSON array of terms with metadata
    """
    try:
        term_service = TermStorageService()
        all_terms = term_service.get_all()

        return jsonify({
            'terms': [
                {
                    'id': t.id,
                    'term_number': t.term_number,
                    'start_date': t.start_date.isoformat(),
                    'end_date': t.end_date.isoformat(),
                    'theme': t.theme,
                    'goal_ids': t.goals,
                    'status': get_term_status(t),
                    'is_active': t.is_active(),
                    'days_remaining': t.days_remaining() if t.is_active() else 0
                }
                for t in all_terms
            ]
        })

    except Exception as e:
        logger.error(f"Error fetching terms: {e}")
        return jsonify({'error': str(e)}), 500


@terms_bp.route('/terms', methods=['POST'])
def api_terms_create():
    """
    POST /api/terms - Create a new term.

    Request JSON:
        {
            "term_number": 1,
            "start_date": "2025-10-13",
            "end_date": "2025-12-22" (optional, calculated if omitted),
            "duration_value": 10 (optional, if end_date omitted),
            "duration_unit": "weeks" (optional: days|weeks|months),
            "theme": "Foundation Building" (optional),
            "goal_ids": [1, 3, 5] (optional)
        }

    Returns:
        JSON with created term (201) or error (400/500)
    """
    data = request.json
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    required = ['term_number', 'start_date']
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({'error': f'Missing required fields: {", ".join(missing)}'}), 400

    try:
        # Parse start date as datetime for consistency with Goals
        start_date = datetime.fromisoformat(data['start_date'])

        # Calculate end date
        if 'end_date' in data:
            end_date = datetime.fromisoformat(data['end_date'])
        elif 'duration_value' in data:
            # Calculate from duration
            duration = data['duration_value']
            unit = data.get('duration_unit', 'weeks')

            if unit == 'days':
                end_date = start_date + timedelta(days=duration)
            elif unit == 'weeks':
                end_date = start_date + timedelta(weeks=duration)
            elif unit == 'months':
                # Approximate: 30 days per month
                end_date = start_date + timedelta(days=duration * 30)
            elif unit == 'hours':
                # Convert hours to days
                end_date = start_date + timedelta(hours=duration)
            elif unit == 'minutes':
                # Convert minutes to days
                end_date = start_date + timedelta(minutes=duration)
            else:
                return jsonify({'error': f'Invalid duration_unit: {unit}'}), 400
        else:
            # Default: 10 weeks
            end_date = None  # Let GoalTerm calculate it

        # Validate goal assignments if provided
        goal_ids = data.get('goal_ids', [])
        if goal_ids:
            goal_service = GoalStorageService()
            all_goals = goal_service.get_all()

            for goal_id in goal_ids:
                goal = next((g for g in all_goals if g.id == goal_id), None)
                if not goal:
                    return jsonify({'error': f'Goal ID {goal_id} not found'}), 400

        # Create term
        term = GoalTerm(
            term_number=data['term_number'],
            start_date=start_date,
            end_date=end_date,
            theme=data.get('theme'),
            goals=goal_ids
        )

        # Save to database
        term_service = TermStorageService()
        term_service.save(term)

        logger.info(f"Created term {term.term_number}: {term.theme} (ID: {term.id})")

        return jsonify({
            'id': term.id,
            'term_number': term.term_number,
            'start_date': term.start_date.isoformat(),
            'end_date': term.end_date.isoformat(),
            'theme': term.theme,
            'goal_ids': term.goals,
            'status': get_term_status(term)
        }), 201

    except ValueError as e:
        return jsonify({'error': f'Invalid date format: {e}'}), 400
    except Exception as e:
        logger.error(f"Error creating term: {e}")
        return jsonify({'error': str(e)}), 500


@terms_bp.route('/terms/<int:term_id>', methods=['PUT'])
def api_terms_update(term_id):
    """
    PUT /api/terms/<id> - Update existing term.

    Request JSON (partial updates supported):
        {
            "theme": "Updated theme",
            "goal_ids": [1, 2, 3],
            "reflection": "Term retrospective..."
        }

    Returns:
        JSON with updated term or 404/500 error
    """
    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            return jsonify({'error': 'Term not found'}), 404

        # Update fields
        if 'theme' in data:
            term.theme = data['theme']
        if 'goal_ids' in data:
            term.goals = data['goal_ids']
        if 'reflection' in data:
            term.reflection = data['reflection']

        # Save updates
        term_service.save(term)

        logger.info(f"Updated term {term_id}")

        return jsonify({
            'id': term.id,
            'term_number': term.term_number,
            'start_date': term.start_date.isoformat(),
            'end_date': term.end_date.isoformat(),
            'theme': term.theme,
            'goal_ids': term.goals,
            'reflection': term.reflection,
            'status': get_term_status(term)
        })

    except Exception as e:
        logger.error(f"Error updating term {term_id}: {e}")
        return jsonify({'error': str(e)}), 500


@terms_bp.route('/terms/<int:term_id>/goals', methods=['POST'])
def api_terms_add_goal(term_id):
    """
    POST /api/terms/<id>/goals - Add goal to term.

    Request JSON:
        {
            "goal_id": 5
        }

    Returns:
        JSON confirmation with validation warnings if applicable
    """
    data = request.json
    if not data or 'goal_id' not in data:
        return jsonify({'error': 'goal_id required'}), 400

    try:
        term_service = TermStorageService()
        goal_service = GoalStorageService()

        term = term_service.get_by_id(term_id)
        if not term:
            return jsonify({'error': 'Term not found'}), 404

        goal = goal_service.get_by_id(data['goal_id'])
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404

        # Validate assignment
        is_valid, warning = validate_goal_term_assignment(goal, term)

        if not is_valid:
            return jsonify({'error': warning}), 400

        # Add goal if not already assigned
        if goal.id and goal.id not in term.goals:
            term.goals.append(goal.id)
            term_service.save(term)
            logger.info(f"Added goal {goal.id} to term {term_id}")
        elif not goal.id:
            return jsonify({'error': 'Goal has no ID (not persisted)'}), 400

        return jsonify({
            'message': 'Goal added to term',
            'term_id': term_id,
            'goal_id': goal.id,
            'warning': warning
        })

    except Exception as e:
        logger.error(f"Error adding goal to term {term_id}: {e}")
        return jsonify({'error': str(e)}), 500


@terms_bp.route('/terms/<int:term_id>/goals/<int:goal_id>', methods=['DELETE'])
def api_terms_remove_goal(term_id, goal_id):
    """
    DELETE /api/terms/<id>/goals/<goal_id> - Remove goal from term.

    Returns:
        JSON confirmation or error
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            return jsonify({'error': 'Term not found'}), 404

        if goal_id in term.goals:
            term.goals.remove(goal_id)
            term_service.save(term)
            logger.info(f"Removed goal {goal_id} from term {term_id}")

            return jsonify({
                'message': 'Goal removed from term',
                'term_id': term_id,
                'goal_id': goal_id
            })
        else:
            return jsonify({'error': 'Goal not assigned to this term'}), 404

    except Exception as e:
        logger.error(f"Error removing goal from term {term_id}: {e}")
        return jsonify({'error': str(e)}), 500
