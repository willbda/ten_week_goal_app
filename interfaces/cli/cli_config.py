"""
CLI configuration - presentation settings and user preferences.

This module contains CONFIGURATION for the CLI interface:
- Display widths, colors, formatting preferences
- User customizable settings
- No business logic, just presentation constants

Pattern: Simple constants and configuration dataclasses.
Could be extended to load from user config file (~/.ten_week_goal/config.toml)

Written by Claude Code on 2025-10-12
"""

from dataclasses import dataclass
from enum import Enum


class OutputStyle(Enum):
    """Output style preferences."""
    COMPACT = "compact"      # Minimal output
    NORMAL = "normal"        # Standard output
    VERBOSE = "verbose"      # Detailed output
    JSON = "json"           # Machine-readable JSON


@dataclass
class DisplayConfig:
    """
    Display formatting configuration.

    These constants control how information is presented in the CLI.
    Users could eventually customize these in a config file.
    """
    # Progress bar settings
    progress_bar_width: int = 40
    compact_bar_width: int = 10

    # Text truncation
    max_description_length: int = 50
    max_goal_title_length: int = 80

    # List previews
    preview_action_count: int = 5
    preview_goal_count: int = 10

    # Layout widths
    separator_width: int = 70
    indent_size: int = 3

    # Decimal precision
    progress_decimal_places: int = 1
    percent_decimal_places: int = 1

    # Unicode symbols
    complete_symbol: str = "✓"
    incomplete_symbol: str = "○"
    overachieved_symbol: str = "⚡"
    progress_filled: str = "█"
    progress_empty: str = "░"


@dataclass
class ColorConfig:
    """
    Color scheme configuration (future enhancement).

    Would enable colored output for terminals that support it.
    """
    enabled: bool = False  # Stub: not yet implemented

    # Status colors
    complete_color: str = "green"
    in_progress_color: str = "yellow"
    not_started_color: str = "red"

    # Accent colors
    header_color: str = "cyan"
    metric_color: str = "blue"
    warning_color: str = "yellow"


@dataclass
class FilterConfig:
    """
    Default filters for CLI commands.

    Users could set preferences like "always hide complete goals"
    or "only show goals from current term".
    """
    # Goal filters
    show_complete: bool = True
    show_incomplete: bool = True
    show_no_target: bool = True

    # Action filters
    require_period_match: bool = False  # Match actions outside goal dates?

    # Match confidence thresholds
    min_confidence: float = 0.0  # 0.0 = show all matches


# ===== DEFAULT CONFIGURATIONS =====

# Main configuration instance used by CLI
DEFAULT_DISPLAY = DisplayConfig()
DEFAULT_COLORS = ColorConfig()
DEFAULT_FILTERS = FilterConfig()


# ===== CONFIGURATION LOADING (Future Enhancement) =====

def load_user_config() -> DisplayConfig:
    """
    Load user's custom configuration from file.

    Future: Would read from ~/.ten_week_goal/cli_config.toml
    and merge with defaults.

    Returns:
        DisplayConfig with user preferences applied
    """
    # Stub: would implement TOML loading
    return DEFAULT_DISPLAY


def save_user_config(config: DisplayConfig) -> None:
    """
    Save user's configuration to file.

    Future: Would write to ~/.ten_week_goal/cli_config.toml

    Args:
        config: DisplayConfig to persist
    """
    # Stub: would implement TOML writing
    pass


# ===== VALIDATION =====

def validate_display_config(config: DisplayConfig) -> bool:
    """
    Validate display configuration values are reasonable.

    Args:
        config: DisplayConfig to validate

    Returns:
        True if valid, False otherwise

    Example:
        >>> config = DisplayConfig(progress_bar_width=-5)  # Invalid
        >>> validate_display_config(config)
        False
    """
    if config.progress_bar_width < 10 or config.progress_bar_width > 100:
        return False

    if config.max_description_length < 10:
        return False

    if config.preview_action_count < 0:
        return False

    return True
