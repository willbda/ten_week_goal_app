"""
Flask web application for Ten Week Goal App.

This demonstrates how the SAME business logic used by CLI
can power a web interface. No duplication of calculations!

Architecture:
- Uses ethica/progress_aggregation.py for business logic (same as CLI)
- Uses Jinja2 templates for HTML presentation
- Thin controllers - just orchestration

To run:
    python interfaces/web_app.py

Then visit: http://localhost:5000

Written by Claude Code on 2025-10-12
"""

from flask import Flask, render_template, jsonify, request
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary
from config.logging_setup import get_logger

logger = get_logger(__name__)


app = Flask(__name__,
            template_folder='templates',
            static_folder='static')


# ===== ROUTES =====

@app.route('/')
def index():
    """
    Home page - shows progress dashboard.

    This is IDENTICAL orchestration to CLI:
    1. Fetch data (rhetorica)
    2. Calculate progress (ethica)
    3. Display (Jinja2 template instead of print statements)
    """
    try:
        # Step 1: Fetch data (same as CLI)
        goal_service = GoalStorageService()
        action_service = ActionStorageService()

        goals = goal_service.get_all()
        actions = action_service.get_all()

        # Step 2: Calculate relationships (same as CLI)
        all_matches = infer_matches(actions, goals, require_period_match=False)

        # Step 3: Calculate progress metrics (same as CLI)
        all_progress = aggregate_all_goals(goals, all_matches)

        # Step 4: Get summary stats
        summary = get_progress_summary(all_progress)

        # Step 5: Render HTML template
        # Use progress_minimal.html since we commented out custom filters
        return render_template('progress_bare.html',
                             all_progress=all_progress,
                             total_actions=len(actions),
                             total_matches=len(all_matches),
                             summary=summary)

    except Exception as e:
        logger.error(f"Error loading progress: {e}")
        return render_template('error.html', error=str(e)), 500



@app.route('/goal/<int:goal_id>')
def goal_detail(goal_id):
    """Detail view - OPTIONAL: Shows single goal with action details."""
    goal_service = GoalStorageService()
    action_service = ActionStorageService()

    goal = goal_service.get_by_id(goal_id)
    if not goal:
        return "Goal not found", 404

    actions = action_service.get_all()
    all_matches = infer_matches(actions, [goal], require_period_match=False)
    progress_list = aggregate_all_goals([goal], all_matches)
    progress = progress_list[0] if progress_list else None

    return render_template('goal_detail.html', progress=progress, matches=all_matches)


@app.route('/api/progress')
def api_progress():
    """JSON API - OPTIONAL: Same data as dashboard but as JSON."""
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



if __name__ == '__main__':
    print("=" * 70)
    print("Ten Week Goal App - Web Interface")
    print("=" * 70)
    print("\nStarting server...")
    print("Visit: http://127.0.0.1:5000")
    print("\nPress Ctrl+C to stop\n")

    app.run(debug=True, host='127.0.0.1', port=5000)

