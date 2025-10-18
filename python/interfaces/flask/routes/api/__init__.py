"""
API Blueprint for Ten Week Goal App.

JSON endpoints for programmatic access to goals, actions, values, and progress.

Written by Claude Code on 2025-10-14.
"""
from flask import Blueprint, render_template, current_app

# Create API blueprint
api_bp = Blueprint('api', __name__)


# API Documentation route
@api_bp.route('/')
def index():
    """API documentation - display all available routes."""
    import re
    routes = []
    for rule in current_app.url_map.iter_rules():
        if rule.endpoint != 'static':
            methods = rule.methods or set()
            # Extract parameters from URL (e.g., <id>, <int:goal_id>)
            params = re.findall(r'<(?:\w+:)?(\w+)>', rule.rule)
            routes.append({
                'endpoint': rule.endpoint,
                'url': rule.rule,
                'methods': sorted([m for m in methods if m not in ['HEAD', 'OPTIONS']]),
                'params': params
            })
    # Sort by endpoint name for readability
    routes.sort(key=lambda x: x['endpoint'])
    return render_template('api.html', routes=routes)


# Import route modules to register them with the blueprint
# These imports MUST come after api_bp is defined (side-effect imports)
from . import goals, actions, values, terms
