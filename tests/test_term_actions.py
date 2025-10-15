"""
Tests for term/action date comparisons and filtering.

Validates that datetime comparisons work correctly between terms and actions,
preventing TypeErrors from mixed date/datetime types.

Written by Claude Code on 2025-10-14
"""

import pytest
from datetime import datetime, timedelta
from categoriae.terms import GoalTerm
from categoriae.actions import Action
from ethica.term_lifecycle import get_actions_in_term


def test_get_actions_in_term_basic():
    """Test that actions within term boundaries are matched."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    # Action inside term
    action_inside = Action("Did something")
    action_inside.log_time = datetime(2025, 10, 15, 14, 30, 0)

    # Action before term
    action_before = Action("Did something earlier")
    action_before.log_time = datetime(2025, 9, 15, 10, 0, 0)

    # Action after term
    action_after = Action("Did something later")
    action_after.log_time = datetime(2025, 11, 15, 16, 0, 0)

    all_actions = [action_inside, action_before, action_after]

    matched = get_actions_in_term(term, all_actions)

    assert len(matched) == 1
    assert matched[0] == action_inside


def test_get_actions_in_term_boundary_conditions():
    """Test actions exactly at term boundaries."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    # Action at exact start
    action_at_start = Action("Started right on time")
    action_at_start.log_time = term_start

    # Action at exact end
    action_at_end = Action("Finished right on time")
    action_at_end.log_time = term_end

    all_actions = [action_at_start, action_at_end]
    matched = get_actions_in_term(term, all_actions)

    assert len(matched) == 2


def test_get_actions_in_term_just_outside_boundaries():
    """Test actions just outside term boundaries are excluded."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    # Action one second before start
    action_before = Action("Too early")
    action_before.log_time = term_start - timedelta(seconds=1)

    # Action one second after end
    action_after = Action("Too late")
    action_after.log_time = term_end + timedelta(seconds=1)

    all_actions = [action_before, action_after]
    matched = get_actions_in_term(term, all_actions)

    assert len(matched) == 0


def test_get_actions_in_term_empty_list():
    """Test with no actions returns empty list."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    matched = get_actions_in_term(term, [])

    assert matched == []


def test_get_actions_in_term_no_log_time():
    """Test actions without log_time are skipped."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    action_with_time = Action("Has time")
    action_with_time.log_time = datetime(2025, 10, 15, 14, 30, 0)

    action_without_time = Action("No time")
    action_without_time.log_time = None

    all_actions = [action_with_time, action_without_time]
    matched = get_actions_in_term(term, all_actions)

    assert len(matched) == 1
    assert matched[0] == action_with_time


def test_datetime_comparison_types():
    """
    Verify all datetime comparisons use consistent types.

    This is a regression test for the bug where term dates (datetime) were
    compared with action.log_time.date() (date), causing TypeError.
    """
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 0, 0, 0)
    action_time = datetime(2025, 10, 15, 14, 30, 0)

    # This should NOT raise TypeError
    # Before fix: datetime <= date <= datetime would crash
    # After fix: datetime <= datetime <= datetime works
    assert term_start <= action_time <= term_end


def test_get_actions_in_term_with_microseconds():
    """Test that microsecond-level precision works correctly."""
    term_start = datetime(2025, 10, 1, 0, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59, 999999)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    # Action with microseconds
    action = Action("Microsecond precision")
    action.log_time = datetime(2025, 10, 15, 14, 30, 45, 123456)

    matched = get_actions_in_term(term, [action])

    assert len(matched) == 1
    assert matched[0] == action


def test_get_actions_in_term_multiple_matches():
    """Test multiple actions within term are all matched."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(term_number=1, start_date=term_start, end_date=term_end)

    actions = []
    for day in range(1, 31):  # Create 30 actions (one per day)
        action = Action(f"Day {day} action")
        action.log_time = datetime(2025, 10, day, 12, 0, 0)
        actions.append(action)

    matched = get_actions_in_term(term, actions)

    assert len(matched) == 30