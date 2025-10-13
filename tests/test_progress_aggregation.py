"""
Tests for progress aggregation business logic.

Tests the AUTHORITATIVE calculation of goal progress metrics.
These tests ensure consistent progress calculation across all interfaces.

Written by Claude Code on 2025-10-12
"""

import pytest
from datetime import datetime
from categoriae.actions import Action
from categoriae.goals import Goal, SmartGoal
from categoriae.relationships import ActionGoalRelationship
from ethica.progress_aggregation import (
    aggregate_goal_progress,
    aggregate_all_goals,
    get_progress_summary,
    GoalProgress
)


# ===== FIXTURES =====

@pytest.fixture
def sample_goal():
    """Create a standard goal for testing."""
    return Goal(
        description="Run 120km",
        measurement_unit="km",
        measurement_target=120.0,
        start_date=datetime(2025, 4, 12),
        end_date=datetime(2025, 6, 21)
    )


@pytest.fixture
def sample_actions():
    """Create sample actions with km measurements."""
    actions = []
    for distance in [5.0, 10.0, 15.0, 20.0]:
        action = Action(f"Run {distance}km")
        action.measurements = {"km": distance}
        actions.append(action)
    return actions


@pytest.fixture
def sample_matches(sample_goal, sample_actions):
    """Create ActionGoalRelationship objects for testing."""
    matches = []
    for action in sample_actions:
        match = ActionGoalRelationship(
            action=action,
            goal=sample_goal,
            contribution=action.measurements["km"],
            assignment_method="auto_inferred",
            confidence=0.9
        )
        matches.append(match)
    return matches


# ===== BASIC AGGREGATION TESTS =====

def test_aggregate_empty_matches(sample_goal):
    """Test progress calculation with no matching actions."""
    progress = aggregate_goal_progress(sample_goal, matches=[])

    assert progress.total_progress == 0.0
    assert progress.target == 120.0
    assert progress.percent == 0.0
    assert progress.remaining == 120.0
    assert progress.is_complete is False
    assert progress.matching_actions_count == 0


def test_aggregate_with_matches(sample_goal, sample_matches):
    """Test progress calculation with matching actions."""
    progress = aggregate_goal_progress(sample_goal, sample_matches)

    # 5 + 10 + 15 + 20 = 50km total
    assert progress.total_progress == 50.0
    assert progress.target == 120.0
    assert progress.percent == pytest.approx(41.67, rel=0.01)
    assert progress.remaining == 70.0
    assert progress.is_complete is False
    assert progress.matching_actions_count == 4


def test_aggregate_complete_goal(sample_goal, sample_actions):
    """Test progress when goal is exactly met."""
    # Create matches that sum to exactly 120km
    matches = []
    for i in range(4):
        action = sample_actions[i]
        action.measurements = {"km": 30.0}  # 4 × 30 = 120
        match = ActionGoalRelationship(
            action=action,
            goal=sample_goal,
            contribution=30.0,
            assignment_method="auto_inferred",
            confidence=0.9
        )
        matches.append(match)

    progress = aggregate_goal_progress(sample_goal, matches)

    assert progress.total_progress == 120.0
    assert progress.percent == 100.0
    assert progress.remaining == 0.0
    assert progress.is_complete is True


def test_aggregate_overachieved_goal(sample_goal, sample_actions):
    """Test progress when goal is exceeded."""
    # Create matches that exceed target
    matches = []
    for i in range(4):
        action = sample_actions[i]
        action.measurements = {"km": 40.0}  # 4 × 40 = 160 (>120)
        match = ActionGoalRelationship(
            action=action,
            goal=sample_goal,
            contribution=40.0,
            assignment_method="auto_inferred",
            confidence=0.9
        )
        matches.append(match)

    progress = aggregate_goal_progress(sample_goal, matches)

    assert progress.total_progress == 160.0
    assert progress.percent == pytest.approx(133.33, rel=0.01)
    assert progress.remaining == 0.0  # Remaining clamped to 0
    assert progress.is_complete is True
    assert progress.is_overachieved is True


# ===== EDGE CASE TESTS =====

def test_aggregate_goal_with_no_target():
    """Test progress for goal without measurement target."""
    goal = Goal(
        description="Do yoga regularly",
        measurement_unit="sessions",
        measurement_target=None  # No target set
    )

    action = Action("Yoga session")
    action.measurements = {"sessions": 1.0}
    match = ActionGoalRelationship(
        action=action,
        goal=goal,
        contribution=1.0,
        assignment_method="manual",
        confidence=1.0
    )

    progress = aggregate_goal_progress(goal, [match])

    assert progress.total_progress == 1.0
    assert progress.target == 0.0  # Defaults to 0
    assert progress.percent == 0.0  # Avoid division by zero
    assert progress.is_complete is True  # 1.0 >= 0.0


def test_aggregate_matches_with_none_contributions(sample_goal):
    """Test handling of matches with None contributions."""
    action1 = Action("Some action")
    action2 = Action("Another action")

    matches = [
        ActionGoalRelationship(
            action=action1,
            goal=sample_goal,
            contribution=10.0,
            assignment_method="manual",
            confidence=1.0
        ),
        ActionGoalRelationship(
            action=action2,
            goal=sample_goal,
            contribution=None,  # Should be treated as 0
            assignment_method="manual",
            confidence=1.0
        )
    ]

    progress = aggregate_goal_progress(sample_goal, matches)

    assert progress.total_progress == 10.0  # Only counts first match
    assert progress.matching_actions_count == 2  # But counts both matches


# ===== DERIVED PROPERTY TESTS =====

def test_goal_progress_properties(sample_goal, sample_matches):
    """Test all derived properties of GoalProgress."""
    progress = aggregate_goal_progress(sample_goal, sample_matches)

    # Unit property
    assert progress.unit == "km"

    # Percent property
    expected_percent = (50.0 / 120.0) * 100
    assert progress.percent == pytest.approx(expected_percent, rel=0.01)

    # Remaining property
    assert progress.remaining == 70.0

    # Completion flags
    assert progress.is_complete is False
    assert progress.is_overachieved is False


def test_unit_property_defaults_to_units():
    """Test unit property when goal has no measurement_unit."""
    goal = Goal(
        description="Generic goal",
        measurement_unit=None,
        measurement_target=10.0
    )

    progress = aggregate_goal_progress(goal, matches=[])

    assert progress.unit == "units"  # Default


# ===== BATCH PROCESSING TESTS =====

def test_aggregate_all_goals():
    """Test batch processing of multiple goals."""
    goal1 = Goal(description="Goal 1", measurement_unit="km", measurement_target=100.0)
    goal2 = Goal(description="Goal 2", measurement_unit="hours", measurement_target=50.0)

    action1 = Action("Action 1")
    action1.measurements = {"km": 30.0}

    action2 = Action("Action 2")
    action2.measurements = {"hours": 10.0}

    matches = [
        ActionGoalRelationship(action=action1, goal=goal1, contribution=30.0,
                             assignment_method="auto_inferred", confidence=0.9),
        ActionGoalRelationship(action=action2, goal=goal2, contribution=10.0,
                             assignment_method="auto_inferred", confidence=0.9)
    ]

    progress_list = aggregate_all_goals([goal1, goal2], matches)

    assert len(progress_list) == 2
    assert progress_list[0].total_progress == 30.0
    assert progress_list[1].total_progress == 10.0


def test_aggregate_all_goals_with_no_matches():
    """Test batch processing when some goals have no matches."""
    goal1 = Goal(description="Goal 1", measurement_unit="km", measurement_target=100.0)
    goal2 = Goal(description="Goal 2", measurement_unit="hours", measurement_target=50.0)

    # Only match for goal1
    action = Action("Action")
    action.measurements = {"km": 30.0}
    matches = [
        ActionGoalRelationship(action=action, goal=goal1, contribution=30.0,
                             assignment_method="auto_inferred", confidence=0.9)
    ]

    progress_list = aggregate_all_goals([goal1, goal2], matches)

    assert len(progress_list) == 2
    assert progress_list[0].total_progress == 30.0
    assert progress_list[1].total_progress == 0.0  # No matches


# ===== SUMMARY STATISTICS TESTS =====

def test_get_progress_summary_empty():
    """Test summary statistics with no progress data."""
    summary = get_progress_summary([])

    assert summary['total_goals'] == 0
    assert summary['complete_goals'] == 0
    assert summary['in_progress_goals'] == 0
    assert summary['avg_completion_percent'] == 0.0
    assert summary['total_actions_matched'] == 0


def test_get_progress_summary_with_data(sample_goal, sample_matches):
    """Test summary statistics calculation."""
    # Create mix of complete and incomplete goals
    goal1 = sample_goal
    goal2 = Goal(description="Goal 2", measurement_unit="hours", measurement_target=50.0)

    progress1 = aggregate_goal_progress(goal1, sample_matches)  # 41.67%
    progress2 = aggregate_goal_progress(goal2, [])  # 0%

    summary = get_progress_summary([progress1, progress2])

    assert summary['total_goals'] == 2
    assert summary['complete_goals'] == 0
    assert summary['in_progress_goals'] == 2
    assert summary['avg_completion_percent'] == pytest.approx(20.83, rel=0.01)  # (41.67 + 0) / 2
    assert summary['total_actions_matched'] == 4
