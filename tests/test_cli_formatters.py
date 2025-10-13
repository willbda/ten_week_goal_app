"""
Tests for CLI formatters - presentation logic.

Tests that formatting functions produce correct output strings.
These are PRESENTATION tests, not business logic tests.

Written by Claude Code on 2025-10-12
"""

import pytest
from datetime import datetime
from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.relationships import ActionGoalRelationship
from ethica.progress_aggregation import GoalProgress
from interfaces.cli.cli_formatters import (
    render_progress_bar,
    render_compact_progress_bar,
    render_goal_header,
    render_section_header,
    render_progress_metrics,
    render_timeline,
    render_action_summary,
    render_action_list,
    render_summary_stats,
    format_date
)


# ===== PROGRESS BAR TESTS =====

def test_render_progress_bar_empty():
    """Test empty progress bar (0%)."""
    bar = render_progress_bar(0, width=10)
    assert bar == "[░░░░░░░░░░]"


def test_render_progress_bar_half():
    """Test half-filled progress bar (50%)."""
    bar = render_progress_bar(50, width=10)
    assert bar == "[█████░░░░░]"


def test_render_progress_bar_full():
    """Test full progress bar (100%)."""
    bar = render_progress_bar(100, width=10)
    assert bar == "[██████████]"


def test_render_progress_bar_overflow():
    """Test progress bar with >100% (should clamp to full)."""
    bar = render_progress_bar(150, width=10)
    assert bar == "[██████████]"


def test_render_progress_bar_custom_width():
    """Test progress bar with custom width."""
    bar = render_progress_bar(50, width=20)
    assert len(bar) == 22  # 20 characters + 2 brackets
    assert bar.count('█') == 10  # Half filled
    assert bar.count('░') == 10


def test_render_compact_progress_bar():
    """Test compact 10-character bar."""
    bar = render_compact_progress_bar(50)
    assert len(bar) == 12  # 10 + 2 brackets
    assert bar == "[█████░░░░░]"


# ===== HEADER TESTS =====

def test_render_goal_header():
    """Test goal header formatting."""
    goal = Goal(description="Run 120km")
    header = render_goal_header(1, goal)

    assert "1. Run 120km" in header
    assert "─" in header  # Contains separator


def test_render_section_header():
    """Test section header with separators."""
    header = render_section_header("TEST HEADER", width=40)

    assert "TEST HEADER" in header
    assert "=" * 40 in header
    assert header.count("\n") == 4  # Newline before, title line, separator line, after


# ===== METRICS FORMATTING TESTS =====

def test_render_progress_metrics_with_target():
    """Test metrics formatting for goal with target."""
    goal = Goal(
        description="Run 120km",
        measurement_unit="km",
        measurement_target=120.0
    )

    matches = []  # No matches for simplicity
    progress = GoalProgress(
        goal=goal,
        matches=matches,
        total_progress=50.0,
        target=120.0
    )

    lines = render_progress_metrics(progress)

    assert any("Target: 120.0 km" in line for line in lines)
    assert any("Progress: 50.0 / 120.0" in line for line in lines)
    assert any("Remaining: 70.0 km" in line for line in lines)
    assert any("[" in line and "]" in line for line in lines)  # Progress bar present


def test_render_progress_metrics_complete():
    """Test metrics when goal is complete."""
    goal = Goal(
        description="Run 120km",
        measurement_unit="km",
        measurement_target=120.0
    )

    progress = GoalProgress(
        goal=goal,
        matches=[],
        total_progress=120.0,
        target=120.0
    )

    lines = render_progress_metrics(progress)

    assert any("✓ COMPLETE!" in line for line in lines)


def test_render_progress_metrics_no_target():
    """Test metrics when goal has no target."""
    goal = Goal(
        description="Generic goal",
        measurement_unit=None,
        measurement_target=None
    )

    progress = GoalProgress(
        goal=goal,
        matches=[],
        total_progress=0.0,
        target=0.0
    )

    lines = render_progress_metrics(progress)

    assert any("Target: Not specified" in line for line in lines)


# ===== TIMELINE TESTS =====

def test_render_timeline_both_dates():
    """Test timeline with start and end dates."""
    goal = Goal(
        description="Goal",
        start_date=datetime(2025, 4, 12),
        end_date=datetime(2025, 6, 21)
    )

    timeline = render_timeline(goal)

    assert timeline is not None
    assert "from 2025-04-12" in timeline
    assert "to 2025-06-21" in timeline


def test_render_timeline_only_end_date():
    """Test timeline with only end date."""
    goal = Goal(
        description="Goal",
        start_date=None,
        end_date=datetime(2025, 12, 31)
    )

    timeline = render_timeline(goal)

    assert timeline is not None
    assert "to 2025-12-31" in timeline
    assert "from" not in timeline


def test_render_timeline_no_dates():
    """Test timeline with no dates."""
    goal = Goal(
        description="Goal",
        start_date=None,
        end_date=None
    )

    timeline = render_timeline(goal)

    assert timeline is None


# ===== ACTION DETAIL TESTS =====

def test_render_action_summary():
    """Test formatting of single action."""
    action = Action("Run 5km")
    action.logtime = datetime(2025, 4, 15)
    action.measurements = {"km": 5.0}

    goal = Goal(description="Run 120km", measurement_unit="km")

    match = ActionGoalRelationship(
        action=action,
        goal=goal,
        contribution=5.0,
        assignment_method="auto_inferred",
        confidence=0.9
    )

    summary = render_action_summary(match, unit="km")

    assert "Run 5km" in summary
    assert "5.0 km" in summary
    assert "2025-04-15" in summary
    assert "90%" in summary  # Confidence


def test_render_action_summary_truncates_long_description():
    """Test that long descriptions are truncated."""
    action = Action("A" * 100)  # Very long description
    action.logtime = datetime(2025, 4, 15)

    goal = Goal(description="Goal", measurement_unit="units")

    match = ActionGoalRelationship(
        action=action,
        goal=goal,
        contribution=1.0,
        assignment_method="manual",
        confidence=1.0
    )

    summary = render_action_summary(match, unit="units", max_length=50)

    assert len(summary) < 150  # Reasonable length
    assert "..." in summary  # Truncation indicator


def test_render_action_list():
    """Test rendering list of actions."""
    actions = [Action(f"Action {i}") for i in range(10)]
    for action in actions:
        action.measurements = {"units": 1.0}
        action.logtime = datetime(2025, 4, 15)

    goal = Goal(description="Goal", measurement_unit="units")

    matches = [
        ActionGoalRelationship(
            action=action,
            goal=goal,
            contribution=1.0,
            assignment_method="auto_inferred",
            confidence=0.9
        )
        for action in actions
    ]

    lines = render_action_list(matches, unit="units", max_preview=3)

    assert any("Matching Actions (10):" in line for line in lines)
    assert any("Action 0" in line for line in lines)  # First shown
    assert any("Action 2" in line for line in lines)  # Third shown
    assert not any("Action 9" in line for line in lines)  # Not shown (>3)
    assert any("... and 7 more" in line for line in lines)  # Truncation message


def test_render_action_list_empty():
    """Test rendering empty action list."""
    lines = render_action_list([], unit="units")

    assert lines == []


# ===== SUMMARY STATS TESTS =====

def test_render_summary_stats():
    """Test summary statistics formatting."""
    summary = render_summary_stats(
        total_goals=8,
        total_actions=184,
        total_matches=150
    )

    assert "Total Goals: 8" in summary
    assert "Total Actions: 184" in summary
    assert "Total Matches: 150" in summary


# ===== DATE FORMATTING TESTS =====

def test_format_date_default():
    """Test default date formatting."""
    dt = datetime(2025, 4, 12, 15, 30)
    formatted = format_date(dt)

    assert formatted == "2025-04-12"


def test_format_date_custom_format():
    """Test custom date format."""
    dt = datetime(2025, 4, 12)
    formatted = format_date(dt, format_str='%m/%d/%Y')

    assert formatted == "04/12/2025"


# ===== INTEGRATION TESTS =====

def test_complete_goal_rendering_workflow():
    """
    Integration test: Format complete goal display.

    Tests that all formatting pieces work together.
    """
    # Create goal with matches
    goal = Goal(
        description="Run 120km",
        measurement_unit="km",
        measurement_target=120.0,
        start_date=datetime(2025, 4, 12),
        end_date=datetime(2025, 6, 21)
    )

    action = Action("Run 5km")
    action.measurements = {"km": 5.0}
    action.logtime = datetime(2025, 4, 15)

    match = ActionGoalRelationship(
        action=action,
        goal=goal,
        contribution=5.0,
        assignment_method="auto_inferred",
        confidence=0.9
    )

    progress = GoalProgress(
        goal=goal,
        matches=[match],
        total_progress=5.0,
        target=120.0
    )

    # Test each component renders without errors
    header = render_goal_header(1, goal)
    assert header is not None

    metrics = render_progress_metrics(progress)
    assert len(metrics) > 0

    timeline = render_timeline(goal)
    assert timeline is not None

    action_list = render_action_list([match], unit="km")
    assert len(action_list) > 0
