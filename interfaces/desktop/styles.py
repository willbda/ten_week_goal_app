"""
Styling constants for Tkinter desktop app.

Now loads from centralized theme system (config/theme.py).
This ensures consistency across desktop, web, and CLI interfaces.

Written by Claude Code on 2025-10-13
Updated by Claude Code on 2025-10-13 to use theme system
"""

from config.theme import get_theme

# Load theme
_theme = get_theme()

# Export as dictionaries for backward compatibility
COLORS = _theme.to_tkinter_colors()
FONTS = _theme.to_tkinter_fonts()
SIZES = _theme.to_tkinter_sizes()

# Note: These are now loaded from config/themes/default.toml
# To change colors/fonts/sizes, edit that file instead of this one.
