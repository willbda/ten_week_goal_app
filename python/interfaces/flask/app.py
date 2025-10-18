"""
Flask application factory for Ten Week Goal App.

"""

import os
import sys
from pathlib import Path

import logging
from flask import Flask, render_template
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

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

    # Set secret key from environment (required for sessions/flash messages)
    app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', 'dev-fallback-key')

    # Override with provided config
    if config:
        app.config.update(config)

    # Register blueprints
    from interfaces.flask.routes.api import api_bp
    from interfaces.flask.routes.ui_values import ui_values_bp
    from interfaces.flask.routes.ui_terms import ui_terms_bp
    from interfaces.flask.routes.ui_actions import ui_actions_bp
    from interfaces.flask.routes.ui_goals import ui_goals_bp

    app.register_blueprint(api_bp, url_prefix='/api')
    app.register_blueprint(ui_values_bp)
    app.register_blueprint(ui_terms_bp)
    app.register_blueprint(ui_actions_bp)
    app.register_blueprint(ui_goals_bp)

    # Home route
    @app.route('/')
    def home():
        """Home page route."""
        return render_template('home.html')

    logger.info("Flask application initialized")

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, port=5001)
