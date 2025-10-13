"""
TUI (Text User Interface) package for Ten Week Goal App.

Provides an interactive terminal interface using the Textual framework.

Usage:
    python interfaces/tui/tui_app.py

Or with hot reload during development:
    textual run --dev interfaces/tui/tui_app.py

Written by Claude Code on 2025-10-13
"""

from .tui_app import TenWeekGoalApp, main

__all__ = ['TenWeekGoalApp', 'main']
