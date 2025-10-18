"""
Goals UI routes for Ten Week Goal App.

HTML forms and pages for managing goals through a web interface.
Delegates to rhetorica (storage) for data operations.

Written by Claude Code on 2025-10-17.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from datetime import datetime
from rhetorica.storage_service import GoalStorageService
from categoriae.goals import Goal, Milestone, SmartGoal
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint for UI routes
ui_goals_bp = Blueprint('ui_goals', __name__, url_prefix='/goals')


@ui_goals_bp.route('/')
def goals_home():
    """
    GET /goals - Goals home page with navigation.
    """
    return render_template('goals.html')


@ui_goals_bp.route('/list')
def goals_list():
    """
    GET /goals/list - List all goals with optional filtering.

    Query parameters:
        - type: Filter by goal type ('Goal', 'Milestone', 'SmartGoal')
        - has_dates: Show only time-bound goals
        - has_target: Show only measurable goals
    """
    try:
        service = GoalStorageService()

        # Get filter parameters
        type_filter = request.args.get('type')
        has_dates = request.args.get('has_dates') == 'true'
        has_target = request.args.get('has_target') == 'true'

        # Fetch goals with type filter
        goals = service.get_all(type_filter=type_filter)

        # Apply additional filters
        if has_dates:
            goals = [g for g in goals if g.is_time_bound()]
        if has_target:
            goals = [g for g in goals if g.is_measurable()]

        return render_template('goals_list.html',
                             goals=goals,
                             current_type=type_filter,
                             has_dates_filter=has_dates,
                             has_target_filter=has_target)

    except Exception as e:
        logger.error(f"Error listing goals: {e}", exc_info=True)
        return f"Error loading goals: {e}", 500


@ui_goals_bp.route('/add', methods=['GET', 'POST'])
def goals_add():
    """
    GET /goals/add - Show form to add new goal.
    POST /goals/add - Create new goal from form data.
    """
    if request.method == 'GET':
        return render_template('goals_add.html')

    # POST: Create new goal
    try:
        service = GoalStorageService()

        # Extract form data
        goal_type = request.form.get('goal_type', 'Goal')
        common_name = request.form.get('common_name')
        description = request.form.get('description')
        notes = request.form.get('notes')

        # Parse measurement fields
        measurement_unit = request.form.get('measurement_unit')
        measurement_target_str = request.form.get('measurement_target')
        measurement_target = float(measurement_target_str) if measurement_target_str else None

        # Parse date fields
        start_date_str = request.form.get('start_date')
        target_date_str = request.form.get('target_date')
        target_date_str = request.form.get('target_date')

        start_date = datetime.fromisoformat(start_date_str) if start_date_str else None
        target_date = datetime.fromisoformat(target_date_str) if target_date_str else None
        target_date = datetime.fromisoformat(target_date_str) if target_date_str else None

        # SMART-specific fields
        how_goal_is_relevant = request.form.get('how_goal_is_relevant')
        how_goal_is_actionable = request.form.get('how_goal_is_actionable')

        # Expected term length
        expected_term_length_str = request.form.get('expected_term_length')
        expected_term_length = int(expected_term_length_str) if expected_term_length_str else None

        # Build kwargs for goal construction
        goal_kwargs = {
            'common_name': common_name,
            'description': description,
            'notes': notes,
            'measurement_unit': measurement_unit,
            'measurement_target': measurement_target,
            'start_date': start_date,
            'target_date': target_date,
            'how_goal_is_relevant': how_goal_is_relevant,
            'how_goal_is_actionable': how_goal_is_actionable,
            'expected_term_length': expected_term_length
        }

        # Add target_date for Milestone
        if goal_type == 'Milestone' and target_date:
            goal_kwargs['target_date'] = target_date

        # Select appropriate class
        goal_classes = {
            'Goal': Goal,
            'Milestone': Milestone,
            'SmartGoal': SmartGoal
        }
        entity_class = goal_classes.get(goal_type, Goal)

        # Create goal instance (validation happens in __post_init__ for SmartGoal/Milestone)
        goal = entity_class(**goal_kwargs)

        # Save to database
        service.store_single_instance(goal)

        logger.info(f"Created {goal_type} {goal.id}: {goal.common_name}")
        flash(f"Successfully created {goal_type}: {goal.common_name}", "success")

        return redirect(url_for('ui_goals.goals_list'))

    except ValueError as e:
        # Validation errors (e.g., SmartGoal missing required fields)
        logger.warning(f"Validation error creating goal: {e}")
        flash(f"Validation error: {e}", "error")
        return render_template('goals_add.html'), 400

    except Exception as e:
        logger.error(f"Error creating goal: {e}", exc_info=True)
        flash(f"Error creating goal: {e}", "error")
        return render_template('goals_add.html'), 500


@ui_goals_bp.route('/edit/<int:goal_id>', methods=['GET', 'POST'])
def goals_edit(goal_id: int):
    """
    GET /goals/edit/<id> - Show form to edit existing goal.
    POST /goals/edit/<id> - Update goal from form data.
    """
    service = GoalStorageService()

    if request.method == 'GET':
        try:
            goal = service.get_by_id(goal_id)
            if not goal:
                flash(f"Goal {goal_id} not found", "error")
                return redirect(url_for('ui_goals.goals_list'))

            return render_template('goals_edit.html', goal=goal)

        except Exception as e:
            logger.error(f"Error loading goal {goal_id}: {e}", exc_info=True)
            flash(f"Error loading goal: {e}", "error")
            return redirect(url_for('ui_goals.goals_list'))

    # POST: Update goal
    try:
        goal = service.get_by_id(goal_id)
        if not goal:
            flash(f"Goal {goal_id} not found", "error")
            return redirect(url_for('ui_goals.goals_list'))

        # Update fields from form
        goal.common_name = request.form.get('common_name', goal.common_name)
        goal.description = request.form.get('description', goal.description)
        goal.notes = request.form.get('notes', goal.notes)

        # Update measurement fields
        measurement_unit = request.form.get('measurement_unit')
        if measurement_unit:
            goal.measurement_unit = measurement_unit

        measurement_target_str = request.form.get('measurement_target')
        if measurement_target_str:
            goal.measurement_target = float(measurement_target_str)

        # Update date fields
        start_date_str = request.form.get('start_date')
        if start_date_str:
            goal.start_date = datetime.fromisoformat(start_date_str)

        target_date_str = request.form.get('target_date')
        if target_date_str:
            goal.target_date = datetime.fromisoformat(target_date_str)

        # Update SMART-specific fields
        how_goal_is_relevant = request.form.get('how_goal_is_relevant')
        if how_goal_is_relevant:
            goal.how_goal_is_relevant = how_goal_is_relevant

        how_goal_is_actionable = request.form.get('how_goal_is_actionable')
        if how_goal_is_actionable:
            goal.how_goal_is_actionable = how_goal_is_actionable

        # Update expected term length
        expected_term_length_str = request.form.get('expected_term_length')
        if expected_term_length_str:
            goal.expected_term_length = int(expected_term_length_str)

        # Save updated goal
        service.save(goal, notes=f'Updated via web UI at {datetime.now().isoformat()}')

        logger.info(f"Updated goal {goal_id}: {goal.common_name}")
        flash(f"Successfully updated goal: {goal.common_name}", "success")

        return redirect(url_for('ui_goals.goals_list'))

    except Exception as e:
        logger.error(f"Error updating goal {goal_id}: {e}", exc_info=True)
        flash(f"Error updating goal: {e}", "error")
        return redirect(url_for('ui_goals.goals_edit', goal_id=goal_id))


@ui_goals_bp.route('/delete/<int:goal_id>', methods=['POST'])
def goals_delete(goal_id: int):
    """
    POST /goals/delete/<id> - Delete goal (with archiving).
    """
    try:
        service = GoalStorageService()

        # Delete with archiving
        service.delete(goal_id, notes=f'Deleted via web UI at {datetime.now().isoformat()}')

        logger.info(f"Deleted goal {goal_id}")
        flash(f"Goal deleted successfully", "success")

        return redirect(url_for('ui_goals.goals_list'))

    except ValueError as e:
        # Goal not found
        flash(str(e), "error")
        return redirect(url_for('ui_goals.goals_list'))

    except Exception as e:
        logger.error(f"Error deleting goal {goal_id}: {e}", exc_info=True)
        flash(f"Error deleting goal: {e}", "error")
        return redirect(url_for('ui_goals.goals_list'))
