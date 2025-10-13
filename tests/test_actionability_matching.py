"""
Tests for actionability-based matching logic.

Tests the matching functions that use structured actionability hints
to prevent false positives in action-goal matching.

Written by Claude Code on 2025-10-12
Updated by Claude Code on 2025-10-12 - Simplified after inlining parser
"""

import pytest
from datetime import datetime

from categoriae.actions import Action
from categoriae.goals import SmartGoal
from ethica.progress_matching import (
    matches_with_actionability,
    infer_matches
)


# ===== Integration Tests =====
# These tests validate the complete matching behavior with real Action/Goal objects

def test_matches_with_actionability_success():
    """Test successful match with actionability (unit + keyword)"""
    action = Action("Yoga with Jessica")
    action.measurements = {"minutes": 30.0}

    goal = SmartGoal(
        description="90 minutes weekly of yoga",
        measurement_unit="minutes",
        measurement_target=900.0,
        start_date=datetime(2025, 7, 13),
        end_date=datetime(2025, 9, 28),
        how_goal_is_relevant="Health",
        how_goal_is_actionable='{"units": ["minutes"], "keywords": ["yoga", "pilates", "core", "strength"]}',
        expected_term_length=11
    )

    matched, contribution = matches_with_actionability(action, goal)
    assert matched is True
    assert contribution == 30.0


def test_matches_with_actionability_wrong_keyword():
    """Test failed match due to wrong keyword (unit matches but keyword doesn't)"""
    # Yoga action trying to match writing goal
    action = Action("Yoga with Jessica")
    action.measurements = {"minutes": 30.0}

    goal = SmartGoal(
        description="Write 3x30 minutes weekly",
        measurement_unit="minutes",
        measurement_target=900.0,
        start_date=datetime(2025, 7, 13),
        end_date=datetime(2025, 9, 28),
        how_goal_is_relevant="Mental health",
        how_goal_is_actionable='{"units": ["minutes"], "keywords": ["write", "revise", "edit", "review"]}',
        expected_term_length=11
    )

    matched, contribution = matches_with_actionability(action, goal)
    assert matched is False
    assert contribution is None


def test_matches_with_actionability_wrong_unit():
    """Test failed match due to wrong unit"""
    action = Action("Movement: 5km run")
    action.measurements = {"km": 5.0}

    goal = SmartGoal(
        description="Spend 30 hours learning",
        measurement_unit="hours",
        measurement_target=30.0,
        start_date=datetime(2025, 7, 13),
        end_date=datetime(2025, 9, 28),
        how_goal_is_relevant="Learning",
        how_goal_is_actionable='{"units": ["hours"], "keywords": ["reading", "watching", "coding"]}',
        expected_term_length=11
    )

    matched, contribution = matches_with_actionability(action, goal)
    assert matched is False
    assert contribution is None


def test_matches_with_actionability_multiple_units():
    """Test matching with multiple allowed units"""
    action = Action("Movement: 3.1 miles run")
    action.measurements = {"miles": 3.1}

    goal = SmartGoal(
        description="Run 120km",
        measurement_unit="km",
        measurement_target=120.0,
        start_date=datetime(2025, 4, 12),
        end_date=datetime(2025, 6, 21),
        how_goal_is_relevant="Fitness",
        how_goal_is_actionable='{"units": ["km", "miles"], "keywords": ["run", "ran", "jog"]}',
        expected_term_length=10
    )

    matched, contribution = matches_with_actionability(action, goal)
    assert matched is True
    assert contribution == 3.1


def test_infer_matches_prevents_false_positives():
    """
    Integration test: Ensure yoga doesn't match writing goal.

    This is the core use case - two goals with same unit (minutes)
    should not cross-match based on actionability keywords.
    """
    # Create actions
    yoga_action = Action("Yoga with Jessica")
    yoga_action.measurements = {"minutes": 30.0}
    yoga_action.logtime = datetime(2025, 7, 15)

    # Use "write" explicitly to match the keyword
    writing_action = Action("write about my goals and revise earlier drafts")
    writing_action.measurements = {"minutes": 30.0}
    writing_action.logtime = datetime(2025, 7, 16)

    # Create goals
    movement_goal = SmartGoal(
        description="90 minutes weekly of yoga, pilates, core",
        measurement_unit="minutes",
        measurement_target=900.0,
        start_date=datetime(2025, 7, 13),
        end_date=datetime(2025, 9, 28),
        how_goal_is_relevant="Physical health",
        how_goal_is_actionable='{"units": ["minutes"], "keywords": ["yoga", "pilates", "core", "strength", "weights"]}',
        expected_term_length=11
    )

    writing_goal = SmartGoal(
        description="write, revise 3x30 minutes weekly",
        measurement_unit="minutes",
        measurement_target=900.0,
        start_date=datetime(2025, 7, 13),
        end_date=datetime(2025, 9, 28),
        how_goal_is_relevant="Mental health",
        how_goal_is_actionable='{"units": ["minutes"], "keywords": ["write", "revise", "edit", "review", "essay"]}',
        expected_term_length=11
    )

    # Run inference
    actions = [yoga_action, writing_action]
    goals = [movement_goal, writing_goal]
    matches = infer_matches(actions, goals)

    # Extract what matched what
    yoga_matches = [m for m in matches if m.action == yoga_action]
    writing_matches = [m for m in matches if m.action == writing_action]

    # Yoga should only match movement goal
    assert len(yoga_matches) == 1
    assert yoga_matches[0].goal == movement_goal

    # Writing action should only match writing goal
    assert len(writing_matches) == 1
    assert writing_matches[0].goal == writing_goal


def test_running_vs_walking_distinction():
    """
    Test that walking actions don't match running goals.

    Both have km measurements, but keywords should distinguish them.
    """
    running_action = Action("Movement: 5km run")
    running_action.measurements = {"km": 5.0}
    running_action.logtime = datetime(2025, 4, 15)

    walking_action = Action("Walked 3km to the store")
    walking_action.measurements = {"km": 3.0}
    walking_action.logtime = datetime(2025, 4, 16)

    running_goal = SmartGoal(
        description="Run 120km in 10 weeks",
        measurement_unit="km",
        measurement_target=120.0,
        start_date=datetime(2025, 4, 12),
        end_date=datetime(2025, 6, 21),
        how_goal_is_relevant="Fitness",
        how_goal_is_actionable='{"units": ["km", "miles"], "keywords": ["run", "ran", "jog", "running"]}',
        expected_term_length=10
    )

    matches = infer_matches([running_action, walking_action], [running_goal])

    # Only running action should match
    assert len(matches) == 1
    assert matches[0].action == running_action
    assert matches[0].contribution == 5.0


def test_fallback_to_unit_matching_without_actionability():
    """Test that matching falls back to simple unit matching if no actionability"""
    from categoriae.goals import Goal

    action = Action("Some activity")
    action.measurements = {"hours": 2.0}
    action.logtime = datetime(2025, 7, 15)

    # Use base Goal class which allows empty actionability
    goal = Goal(
        description="Generic goal",
        measurement_unit="hours",
        measurement_target=10.0,
        start_date=datetime(2025, 7, 13),
        end_date=datetime(2025, 9, 28),
        how_goal_is_relevant="Test",
        how_goal_is_actionable=None  # No actionability
    )

    matched, contribution = matches_with_actionability(action, goal)
    # Should fall back to unit matching
    assert matched is True
    assert contribution == 2.0
