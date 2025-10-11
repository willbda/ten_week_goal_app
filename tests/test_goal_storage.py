"""
Test goal storage functionality using the rhetorica layer.

Tests that Goals and SmartGoals can be saved to the database via GoalStorageService.
"""

import pytest
from datetime import datetime, timedelta
from categoriae.goals import Goal, SmartGoal
from rhetorica.storage_service import GoalStorageService


def test_loose_goal_storage(test_db):
    """Test saving loose goals with optional fields"""
    db, _ = test_db

    # Create test goals with optional fields
    loose_goal = Goal(description="Run a marathon someday")

    partial_goal = Goal(
        description="Get better at Python",
        measurement_unit="hours_coding",
        measurement_target=100.0
    )

    service = GoalStorageService(database=db)
    service.store_many_instances([loose_goal, partial_goal])

    # Verify records were stored
    stored_goals = service.get_all()
    assert len(stored_goals) == 2
    assert stored_goals[0].description == "Run a marathon someday"
    assert stored_goals[1].measurement_unit == "hours_coding"


def test_smart_goal_storage(test_db):
    """Test saving SMART goals with all required fields"""
    db, _ = test_db

    # Create SMART goals
    smart_goal_one = SmartGoal(
        description="Run 120km total",
        measurement_unit="km_run",
        measurement_target=120.0,
        start_date=datetime.now() + timedelta(days=1),
        end_date=datetime.now() + timedelta(days=70),
        how_goal_is_relevant="Maintain fitness and stress management",
        how_goal_is_actionable="Run 3x per week, track distance in actions"
    )

    smart_goal_two = SmartGoal(
        description="Read 40 hours of technical content",
        measurement_unit="hours_reading",
        measurement_target=40.0,
        start_date=datetime.now() + timedelta(days=1),
        end_date=datetime.now() + timedelta(days=70),
        how_goal_is_relevant="Build programming skills for career growth",
        how_goal_is_actionable="Schedule 4 hours weekly, track in actions"
    )

    service = GoalStorageService(database=db)
    service.store_many_instances([smart_goal_one, smart_goal_two])

    # Verify records were stored
    stored_goals = service.get_all()
    assert len(stored_goals) == 2
    assert stored_goals[0].measurement_unit == "km_run"
    assert stored_goals[1].measurement_target == 40.0


def test_smart_goal_validation():
    """Test that SmartGoal enforces validation"""
    with pytest.raises(ValueError, match="end_date must be in the future"):
        SmartGoal(
            description="Invalid goal",
            measurement_unit="units",
            measurement_target=10.0,
            start_date=datetime(2020, 1, 1),
            end_date=datetime(2020, 2, 1),
            how_goal_is_relevant="Test",
            how_goal_is_actionable="Test"
        )


def test_goal_roundtrip(test_db):
    """Test saving and retrieving goals (full roundtrip)"""
    db, _ = test_db

    # Create and save a goal with all fields
    original_goal = Goal(
        description="Test roundtrip goal",
        measurement_unit="test_units",
        measurement_target=50.0,
        start_date=datetime.now() + timedelta(days=1),
        end_date=datetime.now() + timedelta(days=30),
        how_goal_is_relevant="For testing",
        how_goal_is_actionable="Run tests"
    )

    service = GoalStorageService(database=db)
    service.store_single_instance(original_goal)

    # Retrieve all goals
    retrieved_goals = service.get_all()

    # Verify we got one goal back
    assert len(retrieved_goals) == 1

    # Verify the retrieved goal matches the original
    retrieved = retrieved_goals[0]
    assert retrieved.description == original_goal.description
    assert retrieved.measurement_unit == original_goal.measurement_unit
    assert retrieved.measurement_target == original_goal.measurement_target
    assert retrieved.how_goal_is_relevant == original_goal.how_goal_is_relevant
