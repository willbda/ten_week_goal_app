"""
Test goal storage functionality using the rhetorica layer.

Tests that Goals can be saved to and retrieved from the database via GoalStorageService.
This is the essential roundtrip test for the Swift port reference.
"""

from datetime import datetime, timedelta
from categoriae.goals import Goal
from rhetorica.storage_service import GoalStorageService


def test_goal_roundtrip(test_db):
    """Test saving and retrieving goals (full roundtrip)"""
    db, _ = test_db

    # Create and save a goal with all fields
    original_goal = Goal(
        common_name="Test roundtrip goal",
        measurement_unit="test_units",
        measurement_target=50.0,
        start_date=datetime.now() + timedelta(days=1),
        target_date=datetime.now() + timedelta(days=30),
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
    assert retrieved.common_name == original_goal.common_name
    assert retrieved.measurement_unit == original_goal.measurement_unit
    assert retrieved.measurement_target == original_goal.measurement_target
    assert retrieved.how_goal_is_relevant == original_goal.how_goal_is_relevant
    # ID should be assigned
    assert retrieved.id is not None
    assert isinstance(retrieved.id, int)