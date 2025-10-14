"""
Progress API endpoints.

Provides JSON endpoints for goal progress data.

Written by Claude Code on 2025-10-14
"""

from flask import Blueprint, jsonify
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint
progress_bp = Blueprint('progress', __name__, url_prefix='/api')


@progress_bp.route('/progress')
def api_progress():
    """
    GET /api/progress - JSON API for progress data.

    Returns same data as dashboard but as JSON for integrations.

    Returns:
        JSON with summary stats and per-goal progress
    """
    try:
        goal_service = GoalStorageService()
        action_service = ActionStorageService()

        goals = goal_service.get_all()
        actions = action_service.get_all()

        all_matches = infer_matches(actions, goals, require_period_match=False)
        all_progress = aggregate_all_goals(goals, all_matches)
        summary = get_progress_summary(all_progress)

        return jsonify({
            'summary': summary,
            'goals': [
                {
                    'id': p.goal.id,
                    'description': p.goal.description,
                    'total_progress': p.total_progress,
                    'target': p.target,
                    'percent': p.percent,
                    'is_complete': p.is_complete,
                    'matching_actions_count': p.matching_actions_count,
                    'unit': p.unit
                }
                for p in all_progress
            ]
        })

    except Exception as e:
        logger.error(f"Error fetching progress: {e}")
        return jsonify({'error': str(e)}), 500
