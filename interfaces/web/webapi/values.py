"""
Values API endpoints.

Provides CRUD operations for Values hierarchy (MajorValues, HighestOrderValues, etc).

Written by Claude Code on 2025-10-14
"""

from flask import Blueprint, jsonify, request
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from rhetorica.values_storage_service import ValuesStorageService
from rhetorica.values_orchestration_service import ValuesOrchestrationService
from categoriae.values import MajorValues
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint
values_bp = Blueprint('values', __name__, url_prefix='/api')


# ===== HELPER FUNCTIONS =====

def _value_to_dict(value) -> dict:
    """
    Convert Values entity to JSON-friendly dict for API responses.

    NOTE: This is distinct from ValuesStorageService._to_dict() which is
    for database storage. API serialization may differ from storage format
    (e.g., different field names, filtering internal fields).

    Written by Claude Code on 2025-10-13
    """
    # Entity knows its own type
    result = {
        'id': value.id,
        'name': value.name,
        'type': value.incentive_type,  # Direct access to entity attribute
        'description': value.description,
        'domain': value.life_domain,
        'priority': int(value.priority)
    }

    # Include alignment_guidance for major values
    if isinstance(value, MajorValues):
        result['alignment_guidance'] = value.alignment_guidance

    return result


# ===== ROUTES =====

@values_bp.route('/values', methods=['GET'])
def api_values_list():
    """
    GET /api/values - List all values with optional filtering.

    Query params:
        ?type=major|highest_order|life_area|general
        ?domain=Health|Career|Relationships|etc

    Returns:
        JSON with count and list of values
    """
    try:
        # Get filters from query params
        type_filter = request.args.get('type')
        domain_filter = request.args.get('domain')

        # Use orchestration service for filtering
        orchestrator = ValuesOrchestrationService()
        all_values = orchestrator.get_all_values(
            type_filter=type_filter,
            domain_filter=domain_filter
        )

        # Convert to dicts
        values_dicts = [_value_to_dict(v) for v in all_values]

        return jsonify({
            'count': len(values_dicts),
            'values': values_dicts
        })

    except Exception as e:
        logger.error(f"Error fetching values: {e}")
        return jsonify({'error': str(e)}), 500


@values_bp.route('/values/<int:value_id>', methods=['GET'])
def api_values_get(value_id):
    """
    GET /api/values/<id> - Get single value by ID.

    Returns:
        JSON with value details or 404 if not found
    """
    try:
        values_service = ValuesStorageService()
        value = values_service.get_by_id(value_id)

        if not value:
            return jsonify({'error': 'Value not found'}), 404

        return jsonify(_value_to_dict(value))

    except Exception as e:
        logger.error(f"Error fetching value {value_id}: {e}")
        return jsonify({'error': str(e)}), 500


@values_bp.route('/values/major', methods=['POST'])
def api_create_major_value():
    """
    POST /api/values/major - Create major value using orchestration service.

    Request JSON:
        {
            "name": "Value name",
            "description": "Description",
            "domain": "Health|Career|etc" (optional, default: "General"),
            "priority": 1-100 (optional, default: 5),
            "alignment_guidance": "How this shows up in actions/goals" (required)
        }

    Returns:
        JSON with created value (201) or error (400/500)
    """
    data = request.json
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    required = ['name', 'description', 'alignment_guidance']
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({'error': f'Missing required fields: {", ".join(missing)}'}), 400

    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_major_value(
        name=data['name'],
        description=data['description'],
        priority=data.get('priority', 5),
        life_domain=data.get('domain', 'General'),
        alignment_guidance=data['alignment_guidance']
    )

    if result.success and result.value:
        logger.info(f"Created major value: {result.value.name} (ID: {result.value.id})")
        return jsonify(_value_to_dict(result.value)), 201
    else:
        status = 400 if result.error_type == 'validation' else 500
        if result.error_type != 'validation':
            logger.error(f"Error creating major value: {result.error}")
        return jsonify({'error': result.error or 'Unknown error'}), status


@values_bp.route('/values/highest-order', methods=['POST'])
def api_create_highest_order_value():
    """
    POST /api/values/highest-order - Create highest order value using orchestration service.

    Request JSON:
        {
            "name": "Value name",
            "description": "Description",
            "domain": "Philosophy|etc" (optional, default: "General"),
            "priority": 1-100 (optional, default: 1)
        }

    Returns:
        JSON with created value (201) or error (400/500)
    """
    data = request.json
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    required = ['name', 'description']
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({'error': f'Missing required fields: {", ".join(missing)}'}), 400

    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_highest_order_value(
        name=data['name'],
        description=data['description'],
        priority=data.get('priority', 1),
        life_domain=data.get('domain', 'General')
    )

    if result.success and result.value:
        logger.info(f"Created highest order value: {result.value.name} (ID: {result.value.id})")
        return jsonify(_value_to_dict(result.value)), 201
    else:
        status = 400 if result.error_type == 'validation' else 500
        if result.error_type != 'validation':
            logger.error(f"Error creating highest order value: {result.error}")
        return jsonify({'error': result.error or 'Unknown error'}), status


@values_bp.route('/life-areas', methods=['POST'])
def api_create_life_area():
    """
    POST /api/life-areas - Create life area using orchestration service.

    Request JSON:
        {
            "name": "Area name",
            "description": "Description",
            "domain": "Work|etc" (optional, default: "General"),
            "priority": 1-100 (optional, default: 40)
        }

    Returns:
        JSON with created area (201) or error (400/500)
    """
    data = request.json
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    required = ['name', 'description']
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({'error': f'Missing required fields: {", ".join(missing)}'}), 400

    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_life_area(
        name=data['name'],
        description=data['description'],
        priority=data.get('priority', 40),
        life_domain=data.get('domain', 'General')
    )

    if result.success and result.value:
        logger.info(f"Created life area: {result.value.name} (ID: {result.value.id})")
        return jsonify(_value_to_dict(result.value)), 201
    else:
        status = 400 if result.error_type == 'validation' else 500
        if result.error_type != 'validation':
            logger.error(f"Error creating life area: {result.error}")
        return jsonify({'error': result.error or 'Unknown error'}), status


@values_bp.route('/values/general', methods=['POST'])
def api_create_general_value():
    """
    POST /api/values/general - Create general value using orchestration service.

    Request JSON:
        {
            "name": "Value name",
            "description": "Description",
            "domain": "Personal|etc" (optional, default: "General"),
            "priority": 1-100 (optional, default: 50)
        }

    Returns:
        JSON with created value (201) or error (400/500)
    """
    data = request.json
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    required = ['name', 'description']
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({'error': f'Missing required fields: {", ".join(missing)}'}), 400

    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_general_value(
        name=data['name'],
        description=data['description'],
        priority=data.get('priority', 50),
        life_domain=data.get('domain', 'General')
    )

    if result.success and result.value:
        logger.info(f"Created general value: {result.value.name} (ID: {result.value.id})")
        return jsonify(_value_to_dict(result.value)), 201
    else:
        status = 400 if result.error_type == 'validation' else 500
        if result.error_type != 'validation':
            logger.error(f"Error creating general value: {result.error}")
        return jsonify({'error': result.error or 'Unknown error'}), status


@values_bp.route('/values/<int:value_id>', methods=['PUT'])
def api_values_update(value_id):
    """
    PUT /api/values/<id> - Update existing value using orchestration service.

    Request JSON (partial updates supported):
        {
            "name": "Updated name",
            "priority": 15,
            ...
        }

    Returns:
        JSON with updated value or 404/400/500 error
    """
    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    orchestrator = ValuesOrchestrationService()
    result = orchestrator.update_value(
        value_id=value_id,
        name=data.get('name'),
        description=data.get('description'),
        domain=data.get('domain'),
        priority=data.get('priority'),
        alignment_guidance=data.get('alignment_guidance'),
        notes='Updated via API'
    )

    if result.success and result.value:
        logger.info(f"Updated value: {result.value.name} (ID: {value_id})")
        return jsonify(_value_to_dict(result.value))
    else:
        if result.error_type == 'not_found':
            return jsonify({'error': result.error}), 404
        elif result.error_type == 'validation':
            return jsonify({'error': result.error}), 400
        else:
            logger.error(f"Error updating value {value_id}: {result.error}")
            return jsonify({'error': 'Internal server error'}), 500


@values_bp.route('/values/<int:value_id>', methods=['DELETE'])
def api_values_delete(value_id):
    """
    DELETE /api/values/<id> - Delete value using orchestration service.

    Returns:
        JSON confirmation (200) or 404/500 error
    """
    orchestrator = ValuesOrchestrationService()
    result = orchestrator.delete_value(value_id, notes='Deleted via API')

    if result.success:
        return jsonify({
            'message': 'Value deleted',
            'id': value_id
        }), 200
    else:
        if result.error_type == 'not_found':
            return jsonify({'error': result.error}), 404
        else:
            logger.error(f"Error deleting value {value_id}: {result.error}")
            return jsonify({'error': 'Internal server error'}), 500
