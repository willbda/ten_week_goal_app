"""
Values API endpoints for Ten Week Goal App.

RESTful JSON API for personal values management.
Pure orchestration - delegates to rhetorica (storage).

Written by Claude Code on 2025-10-14.
"""

from flask import request, jsonify
from datetime import datetime

from . import api_bp
from rhetorica.storage_service import ValuesStorageService
from rhetorica.serializers import serialize
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel
from config.logging_setup import get_logger

logger = get_logger(__name__)


# ===== API ENDPOINTS =====

@api_bp.route('/values', methods=['GET'])
def get_values():
    """
    GET /api/values - List all values.

    Query parameters:
        - type: Filter by value type ('major', 'highest_order', 'life_area', 'general')
        - domain: Filter by life domain

    Returns:
        200: JSON array of value objects
        500: Server error

    Example:
        GET /api/values
        GET /api/values?type=major
        GET /api/values?domain=Health
        GET /api/values?type=major&domain=Health
    """
    try:
        service = ValuesStorageService()

        # Apply filters from query params
        type_filter = request.args.get('type')
        domain_filter = request.args.get('domain')

        # Validate type_filter if provided
        valid_types = ['major', 'highest_order', 'life_area', 'general']
        if type_filter and type_filter not in valid_types:
            return jsonify({
                'error': f'Invalid type filter. Must be one of: {", ".join(valid_types)}'
            }), 400

        # Get filtered values
        values = service.get_all(type_filter=type_filter, domain_filter=domain_filter)

        # Serialize values
        values_data = [serialize(v, include_type=True) for v in values]

        return jsonify({
            'values': values_data,
            'count': len(values_data),
            'filters': {
                'type': type_filter,
                'domain': domain_filter
            }
        }), 200

    except Exception as e:
        logger.error(f"Error fetching values: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/values/<int:value_id>', methods=['GET'])
def get_value(value_id: int):
    """
    GET /api/values/<id> - Get single value by ID.

    Args:
        value_id: Value database ID

    Returns:
        200: JSON value object
        404: Value not found
        500: Server error

    Example:
        GET /api/values/1
    """
    try:
        service = ValuesStorageService()
        value = service.get_by_id(value_id)

        if not value:
            return jsonify({'error': f'Value {value_id} not found'}), 404

        return jsonify(serialize(value, include_type=True)), 200

    except Exception as e:
        logger.error(f"Error fetching value {value_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/values', methods=['POST'])
def create_value():
    """
    POST /api/values - Create new value.

    Request body (JSON):
        incentive_type: str (required) - Type of value ('major', 'highest_order', 'life_area', 'general')
        title: str (required) - Name of the value
        description: str (required) - Description of what this value means
        priority: int (optional) - Priority level 1-100 (default varies by type)
        life_domain: str (optional) - Life domain (default: 'General')
        alignment_guidance: str (optional) - How this value shows up (MajorValues only)

    Returns:
        201: Created value with ID
        400: Validation error
        500: Server error

    Example:
        POST /api/values
        {
            "incentive_type": "major",
            "title": "Health",
            "description": "Physical and mental wellbeing",
            "priority": 5,
            "life_domain": "Personal",
            "alignment_guidance": "Exercise 3x/week, sleep 8hrs"
        }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Validate required fields
        if 'incentive_type' not in data:
            return jsonify({'error': 'Field "incentive_type" is required'}), 400
        if 'title' not in data or not data['title']:
            return jsonify({'error': 'Field "title" is required'}), 400
        if 'description' not in data or not data['description']:
            return jsonify({'error': 'Field "description" is required'}), 400

        incentive_type = data['incentive_type'].lower()
        valid_types = ['major', 'highest_order', 'life_area', 'general']

        if incentive_type not in valid_types:
            return jsonify({
                'error': f'Invalid incentive_type. Must be one of: {", ".join(valid_types)}'
            }), 400

        # Extract priority (rhetorica will handle conversion and defaults)
        priority = data.get('priority')  # May be None, int, or string
        if priority is not None:
            try:
                priority = int(priority)  # Convert to int if string
            except (ValueError, TypeError) as e:
                return jsonify({'error': f'Invalid priority: {e}'}), 400

        # Create value (rhetorica handles type conversion, defaults, and class selection)
        service = ValuesStorageService()

        value = service.create_value(
            incentive_type=incentive_type,
            title=data['title'],
            description=data['description'],
            priority=priority,  # Pass None or int - rhetorica handles it
            life_domain=data.get('life_domain', 'General'),
            alignment_guidance=data.get('alignment_guidance')
        )

        # Save to database
        service.store_single_instance(value)

        logger.info(f"Created {incentive_type} value {value.id}: {value.title}")

        return jsonify(serialize(value, include_type=True)), 201

    except Exception as e:
        logger.error(f"Error creating value: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/values/<int:value_id>', methods=['PUT'])
def update_value(value_id: int):
    """
    PUT /api/values/<id> - Update existing value.

    Args:
        value_id: Value database ID

    Request body (JSON):
        Any value field to update (title, description, priority, life_domain, alignment_guidance)

    Returns:
        200: Updated value
        400: Validation error
        404: Value not found
        500: Server error

    Example:
        PUT /api/values/1
        {
            "description": "Updated description",
            "priority": 10
        }
    """
    try:
        service = ValuesStorageService()
        value = service.get_by_id(value_id)

        if not value:
            return jsonify({'error': f'Value {value_id} not found'}), 404

        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400

        # Update value fields
        for field, new_value in data.items():
            if field == 'priority':
                # Validate priority
                try:
                    value.priority = PriorityLevel(int(new_value))
                except (ValueError, TypeError) as e:
                    return jsonify({'error': f'Invalid priority: {e}'}), 400
            elif hasattr(value, field):
                setattr(value, field, new_value)

        # Save updated value
        service.save(value, notes=f'Updated via API at {datetime.now().isoformat()}')

        logger.info(f"Updated value {value_id}")

        return jsonify(serialize(value, include_type=True)), 200

    except Exception as e:
        logger.error(f"Error updating value {value_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@api_bp.route('/values/<int:value_id>', methods=['DELETE'])
def delete_value(value_id: int):
    """
    DELETE /api/values/<id> - Delete value (with archiving).

    Args:
        value_id: Value database ID

    Returns:
        200: Deletion confirmation
        404: Value not found
        500: Server error

    Example:
        DELETE /api/values/1
    """
    try:
        service = ValuesStorageService()

        # Delete with archiving
        result = service.delete(
            value_id,
            notes=f'Deleted via API at {datetime.now().isoformat()}'
        )

        logger.info(f"Deleted value {value_id}")

        return jsonify({
            'message': f'Value {value_id} deleted successfully',
            'archived': result.get('archived_count', 0) > 0
        }), 200

    except ValueError as e:
        # Value not found
        return jsonify({'error': str(e)}), 404

    except Exception as e:
        logger.error(f"Error deleting value {value_id}: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500