"""
Flask web application for Ten Week Goal App.

This demonstrates how the SAME business logic used by CLI
can power a web interface. No duplication of calculations!

Architecture:
- Uses ethica/progress_aggregation.py for business logic (same as CLI)
- Uses Jinja2 templates for HTML presentation
- Thin controllers - just orchestration
- API routes organized as Flask Blueprints in webapi/

To run:
    python interfaces/web_app.py

Then visit: http://localhost:5000

Written by Claude Code on 2025-10-12
Updated by Claude Code on 2025-10-14 (API reorganization)
"""

from flask import Flask, render_template
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService, TermStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary
from ethica.term_lifecycle import (
    get_active_term, get_committed_goals, get_term_status, get_unassigned_goals
)
from config.logging_setup import get_logger
from datetime import date, timedelta

# Import API blueprints
from interfaces.web.webapi import progress_bp, values_bp, terms_bp

logger = get_logger(__name__)


app = Flask(__name__,
            template_folder='templates',
            static_folder='static')

# Register API blueprints
app.register_blueprint(progress_bp)
app.register_blueprint(values_bp)
app.register_blueprint(terms_bp)


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


# ===== NOTE: API ROUTES MOVED TO webapi/ DIRECTORY =====
# All /api/* routes are now organized as Flask Blueprints:
# - webapi/progress.py - Progress and goal data
# - webapi/values.py - Values CRUD operations
# - webapi/terms.py - Term management and assignments


# ===== TERM MANAGEMENT ROUTES =====
# Written by Claude Code on 2025-10-13

@app.route('/terms')
def terms_list():
    """
    Terms management page - list all terms with status.

    Shows:
    - Active term (if any)
    - Upcoming terms
    - Completed terms
    - Unassigned goals
    """
    try:
        term_service = TermStorageService()
        goal_service = GoalStorageService()

        all_terms = term_service.get_all()
        all_goals = goal_service.get_all()

        # Get active term
        active_term = get_active_term(all_terms)

        # Get unassigned goals
        unassigned = get_unassigned_goals(all_goals, all_terms)

        # Enrich terms with status and goal counts
        terms_with_status = []
        for term in all_terms:
            committed = get_committed_goals(term, all_goals)
            terms_with_status.append({
                'term': term,
                'status': get_term_status(term),
                'committed_goal_count': len(committed),
                'days_remaining': term.days_remaining() if term.is_active() else None,
                'progress_percent': term.progress_percentage() * 100 if term.is_active() else None
            })

        # Sort: active first, then by term number (descending)
        terms_with_status.sort(key=lambda x: (
            x['status'] != 'active',
            -x['term'].term_number
        ))

        return render_template('terms/list.html',
                             terms_with_status=terms_with_status,
                             active_term=active_term,
                             unassigned_goals=unassigned,
                             today=date.today())

    except Exception as e:
        logger.error(f"Error loading terms: {e}")
        return render_template('error.html', error=str(e)), 500


@app.route('/terms/new')
def terms_new():
    """
    Form to create a new term.

    Provides:
    - Date pickers for start/end dates
    - Duration calculator with unit selector
    - Goal assignment interface
    """
    try:
        goal_service = GoalStorageService()
        term_service = TermStorageService()

        all_goals = goal_service.get_all()
        all_terms = term_service.get_all()

        # Get next term number
        max_term_num = max([t.term_number for t in all_terms], default=0)
        next_term_num = max_term_num + 1

        # Get unassigned goals
        unassigned = get_unassigned_goals(all_goals, all_terms)

        # Default dates: start today, end in 10 weeks
        default_start = date.today()
        default_end = default_start + timedelta(days=70)

        return render_template('terms/new.html',
                             next_term_num=next_term_num,
                             default_start=default_start,
                             default_end=default_end,
                             unassigned_goals=unassigned,
                             all_goals=all_goals)

    except Exception as e:
        logger.error(f"Error loading term creation form: {e}")
        return render_template('error.html', error=str(e)), 500


@app.route('/terms/<int:term_id>')
def term_detail(term_id):
    """
    Detail view for a single term.

    Shows:
    - Term metadata (number, dates, theme, status)
    - Committed goals with progress
    - Overlapping goals (non-committed but active during term)
    - Actions taken during term
    """
    try:
        term_service = TermStorageService()
        goal_service = GoalStorageService()
        action_service = ActionStorageService()

        term = term_service.get_by_id(term_id)
        if not term:
            return "Term not found", 404

        all_goals = goal_service.get_all()
        all_actions = action_service.get_all()

        # Get committed goals with progress
        committed = get_committed_goals(term, all_goals)
        committed_matches = infer_matches(all_actions, committed, require_period_match=False)
        committed_progress = aggregate_all_goals(committed, committed_matches)

        # Calculate term statistics
        status = get_term_status(term)

        return render_template('terms/detail.html',
                             term=term,
                             status=status,
                             committed_progress=committed_progress,
                             committed_goal_count=len(committed))

    except Exception as e:
        logger.error(f"Error loading term {term_id}: {e}")
        return render_template('error.html', error=str(e)), 500




if __name__ == '__main__':
    print("=" * 70)
    print("Ten Week Goal App - Web Interface")
    print("=" * 70)
    print("\nStarting server...")
    print("Visit: http://127.0.0.1:5000")
    print("\nPress Ctrl+C to stop\n")

    app.run(debug=True, host='127.0.0.1', port=5000)

