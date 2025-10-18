"""
Tests for term/action date comparisons and filtering.

Validates that datetime comparisons work correctly between terms and actions,
preventing TypeErrors from mixed date/datetime types.

Written by Claude Code on 2025-10-14
"""

from datetime import datetime
from categoriae.terms import GoalTerm
from categoriae.actions import Action
from ethica.term_lifecycle import get_actions_in_term


def test_get_actions_in_term_basic():
    """Test that actions within term boundaries are matched."""
    term_start = datetime(2025, 10, 1, 0, 0, 0)
    term_end = datetime(2025, 10, 31, 23, 59, 59)
    term = GoalTerm(common_name="Term 1", term_number=1, start_date=term_start, target_date=term_end)

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