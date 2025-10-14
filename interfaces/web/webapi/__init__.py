"""
Web API package for Ten Week Goal App.

Organized as Flask Blueprints:
- progress: Goal progress and summary endpoints
- values: Values CRUD operations
- terms: Term management and goal assignments

Written by Claude Code on 2025-10-14
"""

from flask import Blueprint

# Import blueprints
from .progress import progress_bp
from .values import values_bp
from .terms import terms_bp

# Export all blueprints for easy registration
__all__ = ['progress_bp', 'values_bp', 'terms_bp']
