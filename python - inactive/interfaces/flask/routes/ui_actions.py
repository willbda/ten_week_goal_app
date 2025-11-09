"""
Actions UI routes for Ten Week Goal App.

HTML forms and pages for managing actions through a web interface.
Delegates to rhetorica (storage) for data operations.

Written by Claude Code on 2025-10-16.
"""

import json
from flask import Blueprint, render_template, request, redirect, url_for
from datetime import datetime
from rhetorica.storage_service import ActionStorageService, GoalStorageService
from categoriae.actions import Action
from ethica.inference_service import ActionGoalInferenceService
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint for UI routes
ui_actions_bp = Blueprint('ui_actions', __name__, url_prefix='/actions')


@ui_actions_bp.route('/')
def actions_home():
    """
    GET /actions - Actions home page with navigation.
    """
    return render_template('actions.html')


@ui_actions_bp.route('/list')
def actions_list():
    """
    GET /actions/list - List all actions with optional filtering.

    Query parameters:
        - from_date: Filter actions from this date onwards
        - to_date: Filter actions up to this date
        - has_measurements: Show only actions with measurements
        - has_duration: Show only actions with duration
    """
    try:
        service = ActionStorageService()

        # Get all actions
        actions = service.get_all()

        # Apply filters
        from_date_str = request.args.get('from_date')
        to_date_str = request.args.get('to_date')
        has_measurements = request.args.get('has_measurements')
        has_duration = request.args.get('has_duration')

        # Date filtering
        if from_date_str:
            from_date = datetime.fromisoformat(from_date_str)
            actions = [a for a in actions if a.log_time >= from_date]

        if to_date_str:
            to_date = datetime.fromisoformat(to_date_str)
            actions = [a for a in actions if a.log_time <= to_date]

        # Feature filtering
        if has_measurements == 'true':
            actions = [a for a in actions if a.measurement_units_by_amount]
        elif has_measurements == 'false':
            actions = [a for a in actions if not a.measurement_units_by_amount]

        if has_duration == 'true':
            actions = [a for a in actions if a.duration_minutes is not None]
        elif has_duration == 'false':
            actions = [a for a in actions if a.duration_minutes is None]

        # Sort by log_time descending (most recent first)
        actions = sorted(actions, key=lambda a: a.log_time, reverse=True)

        return render_template('actions_list.html',
                             actions=actions,
                             from_date=from_date_str,
                             to_date=to_date_str,
                             has_measurements=has_measurements,
                             has_duration=has_duration)

    except Exception as e:
        logger.error(f"Error listing actions: {e}", exc_info=True)
        return f"Error loading actions: {e}", 500


@ui_actions_bp.route('/add', methods=['GET', 'POST'])
def actions_add():
    """
    GET /actions/add - Show form to add new action.
    POST /actions/add - Create new action from form data.
    """
    if request.method == 'GET':
        # Default log_time to now for convenience
        default_time = datetime.now().strftime('%Y-%m-%dT%H:%M')
        return render_template('actions_add.html', default_time=default_time)

    # POST: Create new action
    try:
        service = ActionStorageService()

        # Extract required fields
        description = request.form.get('description')
        log_time_str = request.form.get('log_time')

        # Parse log_time
        log_time = datetime.fromisoformat(log_time_str)

        # Create action
        action = Action(
            title=description,
            log_time=log_time
        )

        # Handle optional start_time
        start_time_str = request.form.get('start_time')
        if start_time_str:
            action.start_time = datetime.fromisoformat(start_time_str)

        # Handle optional duration
        duration_str = request.form.get('duration_minutes')
        if duration_str:
            action.duration_minutes = float(duration_str)

        # Handle optional measurements (JSON)
        measurements_json = request.form.get('measurements')
        if measurements_json and measurements_json.strip():
            try:
                measurements = json.loads(measurements_json)
                # Validate it's a dict with numeric values
                if isinstance(measurements, dict):
                    action.measurement_units_by_amount = {
                        k: float(v) for k, v in measurements.items()
                    }
            except (json.JSONDecodeError, ValueError) as e:
                logger.warning(f"Invalid measurements JSON: {e}")
                return f"Invalid measurements format. Please use valid JSON like: {{\"distance_km\": 5.0}}", 400

        # Validate and save
        if not action.is_valid():
            return "Invalid action data. Check that measurements are positive and start_time has duration.", 400

        service.store_single_instance(action)

        logger.info(f"Created action {action.id}: {action.description}")

        return redirect(url_for('ui_actions.actions_list'))

    except Exception as e:
        logger.error(f"Error creating action: {e}", exc_info=True)
        return f"Error creating action: {e}", 500


@ui_actions_bp.route('/edit/<int:action_id>', methods=['GET', 'POST'])
def actions_edit(action_id: int):
    """
    GET /actions/edit/<id> - Show form to edit action.
    POST /actions/edit/<id> - Update action from form data.
    """
    service = ActionStorageService()

    if request.method == 'GET':
        try:
            action = service.get_by_id(action_id)

            if not action:
                return f"Action {action_id} not found", 404

            # Format dates for HTML inputs
            log_time_str = action.log_time.strftime('%Y-%m-%dT%H:%M')
            start_time_str = action.start_time.strftime('%Y-%m-%dT%H:%M') if action.start_time else ''

            # Format measurements as JSON
            measurements_json = json.dumps(action.measurement_units_by_amount, indent=2) if action.measurement_units_by_amount else ''

            return render_template('actions_edit.html',
                                 action=action,
                                 log_time_str=log_time_str,
                                 start_time_str=start_time_str,
                                 measurements_json=measurements_json)

        except Exception as e:
            logger.error(f"Error loading action {action_id}: {e}", exc_info=True)
            return f"Error loading action: {e}", 500

    # POST: Update action
    try:
        action = service.get_by_id(action_id)

        if not action:
            return f"Action {action_id} not found", 404

        # Update fields from form
        action.title = request.form.get('description')

        # Update log_time
        log_time_str = request.form.get('log_time')
        action.log_time = datetime.fromisoformat(log_time_str)

        # Update optional start_time
        start_time_str = request.form.get('start_time')
        if start_time_str:
            action.start_time = datetime.fromisoformat(start_time_str)
        else:
            action.start_time = None

        # Update optional duration
        duration_str = request.form.get('duration_minutes')
        if duration_str:
            action.duration_minutes = float(duration_str)
        else:
            action.duration_minutes = None

        # Update optional measurements
        measurements_json = request.form.get('measurements')
        if measurements_json and measurements_json.strip():
            try:
                measurements = json.loads(measurements_json)
                if isinstance(measurements, dict):
                    action.measurement_units_by_amount = {
                        k: float(v) for k, v in measurements.items()
                    }
            except (json.JSONDecodeError, ValueError) as e:
                logger.warning(f"Invalid measurements JSON: {e}")
                return f"Invalid measurements format. Please use valid JSON.", 400
        else:
            action.measurement_units_by_amount = None

        # Validate and save
        if not action.is_valid():
            return "Invalid action data. Check that measurements are positive and start_time has duration.", 400

        service.save(action, notes='Updated via UI')

        logger.info(f"Updated action {action_id}")

        return redirect(url_for('ui_actions.actions_list'))

    except Exception as e:
        logger.error(f"Error updating action {action_id}: {e}", exc_info=True)
        return f"Error updating action: {e}", 500


@ui_actions_bp.route('/delete/<int:action_id>', methods=['POST'])
def actions_delete(action_id: int):
    """
    POST /actions/delete/<id> - Delete action (with archiving).
    """
    try:
        service = ActionStorageService()

        # Delete with archiving
        result = service.delete(action_id, notes='Deleted via UI')

        logger.info(f"Deleted action {action_id}")

        return redirect(url_for('ui_actions.actions_list'))

    except ValueError as e:
        logger.error(f"Action {action_id} not found: {e}")
        return f"Action not found: {e}", 404

    except Exception as e:
        logger.error(f"Error deleting action {action_id}: {e}", exc_info=True)
        return f"Error deleting action: {e}", 500


@ui_actions_bp.route('/<int:action_id>/goals')
def actions_goals(action_id: int):
    """
    GET /actions/<id>/goals - Show goals matched to this action.
    """
    try:
        action_service = ActionStorageService()
        goal_service = GoalStorageService()

        # Get the action
        action = action_service.get_by_id(action_id)
        if not action:
            return f"Action {action_id} not found", 404

        # Get all goals
        all_goals = goal_service.get_all()

        # Use inference service to find matches
        inference = ActionGoalInferenceService(action_service, goal_service)
        matches = inference.infer_for_new_action(action, all_goals)

        # Sort by match strength
        matches = sorted(matches, key=lambda m: m.match_strength, reverse=True)

        return render_template('actions_goals.html',
                             action=action,
                             matches=matches)

    except Exception as e:
        logger.error(f"Error finding goals for action {action_id}: {e}", exc_info=True)
        return f"Error finding goals: {e}", 500