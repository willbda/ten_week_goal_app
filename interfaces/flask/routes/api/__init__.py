"""
API Blueprint for Ten Week Goal App.

JSON endpoints for programmatic access to goals, actions, values, and progress.

Written by Claude Code on 2025-10-14.
"""
from flask import Blueprint, render_template

# Create API blueprint
api_bp = Blueprint('api', __name__)


# API Documentation route
@api_bp.route('/', methods=['GET'])
@api_bp.route('/docs', methods=['GET'])
def api_documentation():
    """
    GET /api or /api/docs - Interactive API reference documentation.

    Serves a comprehensive HTML page documenting all available endpoints
    with examples, schemas, and error handling information.
    """
    return render_template('api_reference.html')


# Import routes to register them with blueprint (imports trigger route registration)
from interfaces.flask.routes.api import goals, values, actions, terms  # noqa: F401
