"""
CLI utility functions - helpers for argument parsing and user interaction.

Provides CLI-specific functionality like JSON parsing, datetime handling,
and confirmation prompts. Keeps main CLI file clean.

Written by Claude Code on 2025-10-15
"""

import json
import sys
from datetime import datetime
from typing import Optional, Dict, Any


def parse_json_arg(json_str: Optional[str], field_name: str = "argument") -> Optional[Dict]:
    """
    Parse JSON string from CLI argument.

    Args:
        json_str: JSON string from command line argument
        field_name: Name of field for error messages

    Returns:
        Parsed dict, or None if json_str is None

    Raises:
        SystemExit: If JSON parsing fails (prints error and exits)

    Example:
        measurements = parse_json_arg('{"distance_km": 5.0}', "measurements")
    """
    if json_str is None:
        return None

    try:
        parsed = json.loads(json_str)
        if not isinstance(parsed, dict):
            print(f"Error: {field_name} must be a JSON object, got {type(parsed).__name__}")
            sys.exit(1)
        return parsed
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {field_name}: {e}")
        sys.exit(1)


def parse_datetime_arg(date_str: Optional[str], field_name: str = "date") -> Optional[datetime]:
    """
    Parse datetime string from CLI argument.

    Accepts ISO format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS

    Args:
        date_str: ISO datetime string from command line
        field_name: Name of field for error messages

    Returns:
        Parsed datetime, or None if date_str is None

    Raises:
        SystemExit: If datetime parsing fails (prints error and exits)

    Example:
        start_date = parse_datetime_arg('2025-10-15', "start_date")
        start_time = parse_datetime_arg('2025-10-15T07:00:00', "start_time")
    """
    if date_str is None:
        return None

    try:
        return datetime.fromisoformat(date_str)
    except ValueError as e:
        print(f"Error: Invalid {field_name} format '{date_str}'. Use ISO format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS")
        sys.exit(1)


def confirm_action(prompt: str, default_no: bool = True) -> bool:
    """
    Prompt user for yes/no confirmation.

    Used for destructive operations like delete.

    Args:
        prompt: Question to ask user
        default_no: If True, default is No (requires explicit yes)

    Returns:
        True if user confirmed, False otherwise

    Example:
        if confirm_action(f"Delete '{entity.name}'?"):
            service.delete(entity.id)
    """
    suffix = " [y/N]: " if default_no else " [Y/n]: "
    response = input(prompt + suffix).strip().lower()

    if default_no:
        return response in ['y', 'yes']
    else:
        return response not in ['n', 'no']


def format_success(message: str) -> str:
    """Format success message with checkmark."""
    return f"✓ {message}"


def format_error(message: str) -> str:
    """Format error message with cross mark."""
    return f"✗ {message}"


def format_table_row(columns: list, widths: list) -> str:
    """
    Format a row for table display.

    Args:
        columns: List of column values (will be converted to strings)
        widths: List of column widths for padding

    Returns:
        Formatted row string

    Example:
        print(format_table_row(['ID', 'Name', 'Status'], [5, 20, 10]))
        # "    1  Running 5km         Active    "
    """
    formatted = []
    for col, width in zip(columns, widths):
        col_str = str(col) if col is not None else ""
        formatted.append(col_str.ljust(width)[:width])
    return "  ".join(formatted)


def truncate(text: Optional[str], max_length: int = 50, suffix: str = "...") -> str:
    """
    Truncate long text for display.

    Args:
        text: Text to truncate
        max_length: Maximum length before truncation
        suffix: String to append when truncated

    Returns:
        Truncated string

    Example:
        truncate("Very long description here", 15)  # "Very long de..."
    """
    if text is None:
        return ""

    if len(text) <= max_length:
        return text

    return text[:max_length - len(suffix)] + suffix


def format_datetime(dt: Optional[datetime], show_time: bool = False) -> str:
    """
    Format datetime for display.

    Args:
        dt: Datetime to format
        show_time: If True, include time component

    Returns:
        Formatted string (YYYY-MM-DD or YYYY-MM-DD HH:MM)

    Example:
        format_datetime(datetime(2025, 10, 15, 7, 30))  # "2025-10-15"
        format_datetime(datetime(2025, 10, 15, 7, 30), show_time=True)  # "2025-10-15 07:30"
    """
    if dt is None:
        return ""

    if show_time:
        return dt.strftime("%Y-%m-%d %H:%M")
    else:
        return dt.strftime("%Y-%m-%d")


def format_json(data: Optional[Dict], max_width: int = 40) -> str:
    """
    Format JSON dict for compact display.

    Args:
        data: Dict to format
        max_width: Maximum width before truncation

    Returns:
        Compact JSON string

    Example:
        format_json({"distance_km": 5.0, "duration": 30})  # '{"distance_km": 5.0, "duration": 30}'
    """
    if data is None:
        return ""

    json_str = json.dumps(data, separators=(',', ':'))
    return truncate(json_str, max_width)
