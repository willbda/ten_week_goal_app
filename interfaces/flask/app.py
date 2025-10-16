"""
Flask application factory for Ten Week Goal App.

"""

import logging
from flask import Flask, render_template

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
    from interfaces.flask.routes.ui_values import ui_values_bp

    app.register_blueprint(api_bp, url_prefix='/api')
    app.register_blueprint(ui_values_bp)

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
