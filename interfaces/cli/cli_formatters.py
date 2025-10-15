"""
CLI output formatters - presentation logic for goal tracking.

This module contains presentation logic:
- Formatting text, numbers, dates
- Rendering progress bars, tables, headers
- Color coding (future)
- Layout and spacing

## Why This Belongs in interfaces/ (Presentation Layer)

These functions convert domain data into human-readable strings.
They have no business logic - just formatting decisions.

Pattern: Takes structured data (GoalProgress) and returns formatted strings.
Easily testable, reusable across different CLI commands.

Written by Claude Code on 2025-10-12

TODO: complete the stubs below
"""

from typing import Optional, List, Union
from datetime import datetime
from categoriae.goals import Goal
from categoriae.relationships import ActionGoalRelationship
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas
from ethica.progress_aggregation import GoalProgress
from rhetorica.values_storage_service import ValuesStorageService


# ===== CONFIGURATION =====
# Presentation constants - could be moved to config file

class FormatConfig:
    """Display configuration constants."""
    PROGRESS_BAR_WIDTH = 40
    PREVIEW_ACTION_COUNT = 5
    MAX_DESCRIPTION_LENGTH = 50
    SEPARATOR_WIDTH = 70


# ===== PROGRESS BAR RENDERING =====

def render_progress_bar(percent: float, width: int = FormatConfig.PROGRESS_BAR_WIDTH) -> str:
    """
    Render a Unicode progress bar.

    Args:
        percent: Progress percentage (0-100, can exceed 100)
        width: Width in characters (default: 40)

    Returns:
        Unicode bar like: [████████████████░░░░░░░░░░░░░░░░]

    Examples:
        >>> render_progress_bar(0)
        '[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]'

        >>> render_progress_bar(50)
        '[████████████████████░░░░░░░░░░░░░░░░░░░░]'

        >>> render_progress_bar(100)
        '[████████████████████████████████████████]'

        >>> render_progress_bar(150)  # Overachieved
        '[████████████████████████████████████████]'
    """
    # Clamp to 0-100 range for display
    clamped_percent = max(0.0, min(percent, 100.0))

    # Calculate filled portion
    filled = int(width * (clamped_percent / 100.0))
    empty = width - filled

    # Render with Unicode block characters
    return f"[{'█' * filled}{'░' * empty}]"


def render_compact_progress_bar(percent: float) -> str:
    """
    Render a compact 10-character progress bar.

    Useful for table displays where space is limited.

    Args:
        percent: Progress percentage (0-100)

    Returns:
        Compact bar like: [████░░░░░░]

    Example:
        >>> render_compact_progress_bar(50)
        '[█████░░░░░]'
    """
    return render_progress_bar(percent, width=10)


# ===== GOAL HEADER FORMATTING =====

def render_goal_header(goal_number: int, goal: Goal) -> str:
    """
    Format goal header with number and description.

    Args:
        goal_number: Sequential number for this goal (1, 2, 3...)
        goal: Goal entity

    Returns:
        Formatted header string

    Example:
        >>> render_goal_header(1, goal)
        '1. Run 120km in 10 weeks
           ──────────────────────────────────────────────────────────────────'
    """
    separator = '─' * 66
    return f"{goal_number}. {goal.description}\n   {separator}"


def render_section_header(title: str, width: int = FormatConfig.SEPARATOR_WIDTH) -> str:
    """
    Render a major section header with separators.

    Args:
        title: Section title
        width: Width of separators

    Returns:
        Formatted header block

    Example:
        >>> render_section_header("GOAL PROGRESS REPORT")
        '======================================================================
         GOAL PROGRESS REPORT
         ======================================================================'
    """
    separator = '=' * width
    return f"\n{separator}\n{title}\n{separator}\n"


# ===== PROGRESS METRICS FORMATTING =====

def render_progress_metrics(progress: GoalProgress) -> List[str]:
    """
    Format progress metrics for a goal.

    Returns list of lines (not joined) for flexibility in output.

    Args:
        progress: GoalProgress object with calculated metrics

    Returns:
        List of formatted lines

    Example:
        >>> lines = render_progress_metrics(progress)
        >>> for line in lines:
        >>>     print(line)
        Target: 120.0 km
        Progress: 102.5 / 120.0 (85.4%)
        Remaining: 17.5 km
        [██████████████████████████████████░░░░░░]
    """
    lines = []

    if progress.target > 0:
        lines.append(f"   Target: {progress.target} {progress.unit}")
        lines.append(
            f"   Progress: {progress.total_progress:.1f} / {progress.target:.1f} "
            f"({progress.percent:.1f}%)"
        )
        lines.append(f"   Remaining: {progress.remaining:.1f} {progress.unit}")
        lines.append(f"   {render_progress_bar(progress.percent)}")

        if progress.is_complete:
            lines.append("   ✓ COMPLETE!")
        if progress.is_overachieved:
            lines.append("   ⚡ EXCEEDED TARGET!")
    else:
        lines.append("   Target: Not specified")
        lines.append(f"   Matching actions: {progress.matching_actions_count}")

    return lines


def render_timeline(goal: Goal) -> Optional[str]:
    """
    Format goal timeline (start/end dates).

    Args:
        goal: Goal with optional start_date and end_date

    Returns:
        Formatted timeline string, or None if no dates

    Examples:
        >>> render_timeline(goal)
        'Timeline: from 2025-04-12 to 2025-06-21'

        >>> render_timeline(goal_with_only_end)
        'Timeline: to 2025-12-31'
    """
    if not goal.start_date and not goal.end_date:
        return None

    parts = []
    if goal.start_date:
        parts.append(f"from {goal.start_date.strftime('%Y-%m-%d')}")
    if goal.end_date:
        parts.append(f"to {goal.end_date.strftime('%Y-%m-%d')}")

    return f"   Timeline: {' '.join(parts)}"


# ===== ACTION DETAIL FORMATTING =====

def render_action_summary(
    match: ActionGoalRelationship,
    unit: str,
    max_length: int = FormatConfig.MAX_DESCRIPTION_LENGTH
) -> str:
    """
    Format a single action's contribution for verbose output.

    Args:
        match: ActionGoalRelationship with action, contribution, confidence
        unit: Measurement unit for display
        max_length: Max characters for description (truncated with ...)

    Returns:
        Formatted action line

    Example:
        >>> render_action_summary(match, "km")
        '  • Movement: 5.11 km run: 5.1 km (2025-04-18, conf: 90%)'
    """
    # Truncate description if too long
    desc = match.action.description
    if len(desc) > max_length:
        desc = desc[:max_length-3] + "..."

    # Format contribution
    contribution = match.contribution if match.contribution else 0
    contrib_str = f"{contribution} {unit}"

    # Format log date
    log_date = "N/A"
    if match.action.log_time:
        log_date = match.action.log_time.strftime('%Y-%m-%d')

    # Format confidence
    confidence_str = "N/A"
    if match.confidence is not None:
        confidence_str = f"{match.confidence:.0%}"

    return f"     • {desc}: {contrib_str} ({log_date}, conf: {confidence_str})"


def render_action_list(
    matches: List[ActionGoalRelationship],
    unit: str,
    max_preview: int = FormatConfig.PREVIEW_ACTION_COUNT
) -> List[str]:
    """
    Format list of matching actions for verbose mode.

    Shows first N actions with summary, indicates if more exist.

    Args:
        matches: List of ActionGoalRelationship objects
        unit: Measurement unit for display
        max_preview: Maximum number of actions to show before truncating

    Returns:
        List of formatted lines

    Example:
        >>> lines = render_action_list(matches, "km", max_preview=3)
        ['   Matching Actions (15):',
         '     • Movement: 5.11 km run: 5.1 km (2025-04-18, conf: 90%)',
         '     • Movement: 6.02 km run: 6.0 km (2025-04-23, conf: 90%)',
         '     • Movement: 7.0 km run: 7.0 km (2025-04-29, conf: 90%)',
         '     ... and 12 more']
    """
    if not matches:
        return []

    lines = [f"\n   Matching Actions ({len(matches)}):"]

    # Show first N actions
    preview_matches = matches[:max_preview]
    for match in preview_matches:
        lines.append(render_action_summary(match, unit))

    # Indicate if more exist
    if len(matches) > max_preview:
        remaining = len(matches) - max_preview
        lines.append(f"     ... and {remaining} more")

    return lines


# ===== SUMMARY STATISTICS FORMATTING =====

def render_summary_stats(total_goals: int, total_actions: int, total_matches: int) -> str:
    """
    Format summary statistics header.

    Args:
        total_goals: Number of goals
        total_actions: Number of actions
        total_matches: Number of action-goal matches

    Returns:
        Formatted multi-line summary

    Example:
        >>> print(render_summary_stats(8, 184, 150))
        Total Goals: 8
        Total Actions: 184
        Total Matches: 150
    """
    return (
        f"Total Goals: {total_goals}\n"
        f"Total Actions: {total_actions}\n"
        f"Total Matches: {total_matches}\n"
    )


# ===== COMPLETE GOAL DISPLAY =====

def render_goal_complete(progress: GoalProgress, verbose: bool = False) -> str:
    """
    Render complete display for a single goal.

    Combines header, metrics, timeline, and optional action details.

    Args:
        progress: GoalProgress object with all metrics
        verbose: If True, include detailed action listings

    Returns:
        Complete formatted output for this goal

    Example:
        >>> output = render_goal_complete(progress, verbose=True)
        >>> print(output)
        1. Run 120km in 10 weeks
           ──────────────────────────────────────────────────────────────────
           Target: 120.0 km
           Progress: 102.5 / 120.0 (85.4%)
           ...
    """
    lines = []

    # Always include in full implementation
    # For stub: indicate where each piece would go
    lines.append("# Header rendered here")
    lines.append("# Metrics rendered here")
    lines.append("# Timeline rendered here")

    if verbose:
        lines.append("# Verbose action details rendered here")

    return '\n'.join(lines)


# ===== DATE FORMATTING =====

def format_date(dt: datetime, format_str: str = '%Y-%m-%d') -> str:
    """
    Format datetime consistently across CLI.

    Args:
        dt: Datetime to format
        format_str: strftime format string

    Returns:
        Formatted date string

    Example:
        >>> format_date(datetime(2025, 4, 12))
        '2025-04-12'
    """
    return dt.strftime(format_str)


def format_date_relative(dt: datetime) -> str:
    """
    Format date with relative description if recent.

    Future enhancement for "3 days ago" style formatting.

    Args:
        dt: Datetime to format

    Returns:
        Formatted string like "2025-04-12" or "3 days ago"
    """
    # Stub: would implement relative date logic
    return format_date(dt)


# ===== VALUES LIST FORMATTING =====

def render_value_list(values: List) -> str:
    """
    Format list of values as plain text table.

    Args:
        values: List of Values/MajorValues/HighestOrderValues/LifeAreas entities

    Returns:
        Formatted multi-line string with fixed-width columns

    Example:
        >>> print(render_value_list(values))
        VALUES
        ======

        ID  Name                    Type            Domain          Priority
        1   Health & Vitality       major           Health          5
        2   Continuous Learning     general         Personal        30
        3   Environmental Care      life_area       General         20

        Total: 3 values
    """
    if not values:
        return "No values found."

    lines = []
    lines.append("\nVALUES")
    lines.append("=" * 6)
    lines.append("")

    # Header row
    header = f"{'ID':<4}{'Name':<24}{'Type':<16}{'Domain':<16}{'Priority':<8}"
    lines.append(header)

    # Data rows
    for value in values:
        # Get type string from rhetorica (eliminates hasattr logic)
        type_str = value.incentive_type

        # Truncate name if too long
        name = value.value_name[:21] + "..." if len(value.value_name) > 24 else value.value_name

        # Format row
        value_id = value.id if value.id else "N/A"
        row = f"{str(value_id):<4}{name:<24}{type_str:<16}{value.life_domain:<16}{int(value.priority):<8}"
        lines.append(row)

    # Footer
    lines.append("")
    lines.append(f"Total: {len(values)} values")

    return '\n'.join(lines)


# ===== VALUE DETAIL FORMATTING =====

def render_value_detail(value: Union[Values, MajorValues, HighestOrderValues, LifeAreas]) -> str:
    """
    Format detailed information for a single value.

    Args:
        value: Values entity (any subclass)

    Returns:
        Formatted multi-line string with all value attributes

    Example:
        >>> print(render_value_detail(value))
        VALUE DETAILS
        =============

        ID:          5
        Name:        Health & Vitality
        Type:        major
        Description: Physical and mental wellness
        Domain:      Health
        Priority:    5
        Alignment:   Daily exercise, nutrition tracking, sleep hygiene
    """
    lines = []
    lines.append("\nVALUE DETAILS")
    lines.append("=" * 13)
    lines.append("")

    # Get type string from rhetorica
    value_type = value.incentive_type

    # Format fields
    value_id = value.id if value.id else "N/A"
    lines.append(f"ID:          {value_id}")
    lines.append(f"Name:        {value.value_name}")
    lines.append(f"Type:        {value_type}")
    lines.append(f"Description: {value.description}")
    lines.append(f"Domain:      {value.life_domain}")
    lines.append(f"Priority:    {int(value.priority)}")

    # Show alignment guidance for major values (matches Flask API pattern)
    from categoriae.values import MajorValues
    if isinstance(value, MajorValues) and value.alignment_guidance:
        if isinstance(value.alignment_guidance, dict):
            # Format dict nicely
            import json
            guidance_str = json.dumps(value.alignment_guidance, indent=2)
        else:
            guidance_str = str(value.alignment_guidance)
        lines.append(f"Alignment:   {guidance_str}")

    lines.append("")
    return '\n'.join(lines)
