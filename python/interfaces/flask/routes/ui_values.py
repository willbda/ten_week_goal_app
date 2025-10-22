"""
Values UI routes for Ten Week Goal App.

HTML forms and pages for managing values through a web interface.
Delegates to rhetorica (storage) for data operations.

Written by Claude Code on 2025-10-15.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash
from rhetorica.storage_service import ValuesStorageService
from categoriae.values import PriorityLevel
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint for UI routes
ui_values_bp = Blueprint('ui_values', __name__, url_prefix='/values')


@ui_values_bp.route('/')
def values_home():
    """
    GET /values - Values home page with navigation.
    """
    return render_template('values.html')


@ui_values_bp.route('/list')
def values_list():
    """
    GET /values/list - List all values with optional filtering.

    Query parameters:
        - type: Filter by value type ('major', 'highest_order', 'life_area', 'general')
        - domain: Filter by life domain
    """
    try:
        service = ValuesStorageService()

        # Get filter parameters
        type_filter = request.args.get('type')
        domain_filter = request.args.get('domain')

        # Fetch values with filters
        values = service.get_all(type_filter=type_filter, domain_filter=domain_filter)

        return render_template('values_list.html',
                             values=values,
                             current_type=type_filter,
                             current_domain=domain_filter)

    except Exception as e:
        logger.error(f"Error listing values: {e}", exc_info=True)
        return f"Error loading values: {e}", 500


@ui_values_bp.route('/add', methods=['GET', 'POST'])
def values_add():
    """
    GET /values/add - Show form to add new value.
    POST /values/add - Create new value from form data.
    """
    if request.method == 'GET':
        return render_template('values_add.html')

    # POST: Create new value
    try:
        service = ValuesStorageService()

        # Extract form data
        incentive_type = request.form.get('incentive_type')
        title = request.form.get('title')
        description = request.form.get('description')
        life_domain = request.form.get('life_domain', 'General')
        alignment_guidance = request.form.get('alignment_guidance')

        # Parse priority (convert to int if provided, else None for defaults)
        priority_str = request.form.get('priority')
        priority = int(priority_str) if priority_str else None

        # Create value (rhetorica handles type conversion, defaults, and class selection)
        value = service.create_value(
            incentive_type=incentive_type,
            title=title,
            description=description,
            priority=priority,  # Pass None or int - rhetorica handles it
            life_domain=life_domain,
            alignment_guidance=alignment_guidance
        )

        # Save to database
        service.store_single_instance(value)

        logger.info(f"Created {incentive_type} value {value.id}: {value.title}")

        return redirect(url_for('ui_values.values_list'))

    except Exception as e:
        logger.error(f"Error creating value: {e}", exc_info=True)
        return f"Error creating value: {e}", 500


@ui_values_bp.route('/edit/<int:value_id>', methods=['GET', 'POST'])
def values_edit(value_id: int):
    """
    GET /values/edit/<id> - Show form to edit value.
    POST /values/edit/<id> - Update value from form data.
    """
    service = ValuesStorageService()

    if request.method == 'GET':
        try:
            value = service.get_by_id(value_id)

            if not value:
                return f"Value {value_id} not found", 404

            return render_template('values_edit.html', value=value)

        except Exception as e:
            logger.error(f"Error loading value {value_id}: {e}", exc_info=True)
            return f"Error loading value: {e}", 500

    # POST: Update value
    try:
        value = service.get_by_id(value_id)

        if not value:
            return f"Value {value_id} not found", 404

        # Update fields from form
        value.title = request.form.get('title')
        value.description = request.form.get('description')
        value.life_domain = request.form.get('life_domain', 'General')

        # Update priority
        priority_str = request.form.get('priority')
        if priority_str:
            value.priority = PriorityLevel(int(priority_str))

        # Update alignment_guidance if present
        alignment_guidance = request.form.get('alignment_guidance')
        if hasattr(value, 'alignment_guidance'):
            value.alignment_guidance = alignment_guidance

        # Note: Type changes not currently supported (would require recreating object)
        # The form shows type but doesn't allow changing it without complex logic

        # Save updated value
        service.save(value, notes=f'Updated via UI')

        logger.info(f"Updated value {value_id}")

        return redirect(url_for('ui_values.values_list'))

    except Exception as e:
        logger.error(f"Error updating value {value_id}: {e}", exc_info=True)
        return f"Error updating value: {e}", 500


@ui_values_bp.route('/delete/<int:value_id>', methods=['POST'])
def values_delete(value_id: int):
    """
    POST /values/delete/<id> - Delete value (with archiving).
    """
    try:
        service = ValuesStorageService()

        # Delete with archiving
        result = service.delete(value_id, notes='Deleted via UI')

        logger.info(f"Deleted value {value_id}")

        return redirect(url_for('ui_values.values_list'))

    except ValueError as e:
        logger.error(f"Value {value_id} not found: {e}")
        return f"Value not found: {e}", 404

    except Exception as e:
        logger.error(f"Error deleting value {value_id}: {e}", exc_info=True)
        return f"Error deleting value: {e}", 500
