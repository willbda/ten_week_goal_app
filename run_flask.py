#!/usr/bin/env python
"""
Flask app runner for project root.
This allows running the Flask app from the project root directory.

Usage:
    python run_flask.py
    or
    flask run (if .flaskenv is configured)
"""

import sys
from pathlib import Path

# Add python directory to path BEFORE any imports
# This must happen before Flask tries to import anything
python_dir = Path(__file__).parent / 'python'
sys.path.insert(0, str(python_dir))

# Now we can create a function that Flask can call
def create_app():
    """Factory function that Flask CLI can use."""
    from interfaces.flask.app import create_app as flask_create_app
    return flask_create_app()

# For direct execution
if __name__ == '__main__':
    app = create_app()
    print(f"Starting Flask app from project root...")
    print(f"Visit: http://localhost:5001")
    app.run(debug=True, port=5001)