"""
Flask application factory for Ten Week Goal App.

Written by Claude Code on 2025-10-14.
"""
import sys
from pathlib import Path

# Add project root to path when running as entry point
# This allows: python interfaces/flask/flask_main.py
if __name__ == '__main__':
    project_root = Path(__file__).parent.parent.parent
    sys.path.insert(0, str(project_root))

import logging
from flask import Flask

logger = logging.getLogger(__name__)


def create_app(config: dict | None = None):
    """
    Application factory pattern for Flask app.

    Args:
        config: Optional configuration dict to override defaults

    Returns:
        Configured Flask application instance
    """
    app = Flask(__name__,
                template_folder='templates',
                static_folder='static')


    # Override with provided config
    if config:
        app.config.update(config)

    # Register blueprints
    from interfaces.flask.routes.api import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    logger.info("Flask application initialized")

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, port=5001)
