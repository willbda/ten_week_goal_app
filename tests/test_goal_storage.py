"""
Test goal storage functionality using the rhetorica layer.

Tests that Goals and SmartGoals can be saved to the database via GoalStorageService.
"""

from datetime import datetime, timedelta
from categoriae.goals import Goal, SmartGoal
from config.testing import SCHEMA_PATH, TEST_DB_PATH
from politica.database import Database
from rhetorica.storage_service import GoalStorageService


# Test loose Goal (optional fields)
loose_goal = Goal(
    description="Run a marathon someday",
    # No dates, no target - just an aspiration
)

# Test Goal with some details
partial_goal = Goal(
    description="Get better at Python",
    measurement_unit="hours_coding",
    measurement_target=100.0
    # No dates - ongoing goal
)

# Test SMART Goal (all fields required)
smart_goal_one = SmartGoal(
    description="Run 120km total",
    measurement_unit="km_run",
    measurement_target=120.0,
    start_date=datetime.now() + timedelta(days=1),  # Must be in future
    end_date=datetime.now() + timedelta(days=70),   # 10 weeks
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

def test_loose_goal_storage():
    """Test saving loose goals with optional fields"""
    # Create fresh database for each test (don't create at module level)
    db = Database(db_path=TEST_DB_PATH, schema_dir=SCHEMA_PATH)
    storage_service = GoalStorageService(database=db)
    storage_service.store_many_instances([loose_goal, partial_goal])
    print(f"✓ Successfully saved {2} loose goals (check logs for IDs)")
    assert True  # If we get here without errors, test passed


def test_smart_goal_storage():
    """Test saving SMART goals with all required fields"""
    # Create fresh database for each test
    db = Database(db_path=TEST_DB_PATH, schema_dir=SCHEMA_PATH)
    storage_service = GoalStorageService(database=db)
    storage_service.store_many_instances([smart_goal_one, smart_goal_two])
    print(f"✓ Successfully saved {2} SMART goals (check logs for IDs)")
    assert True  # If we get here without errors, test passed


def test_smart_goal_validation():
    """Test that SmartGoal enforces validation"""
    try:
        # This should fail - end_date in the past
        bad_goal = SmartGoal(
            description="Invalid goal",
            measurement_unit="units",
            measurement_target=10.0,
            start_date=datetime(2020, 1, 1),
            end_date=datetime(2020, 2, 1),  # In the past!
            how_goal_is_relevant="Test",
            how_goal_is_actionable="Test"
        )
        assert False, "Should have raised ValueError for past date"
    except ValueError as e:
        print(f"✓ Correctly rejected invalid SMART goal: {e}")
        assert True


if __name__ == "__main__":
    test_loose_goal_storage()
    test_smart_goal_storage()
    test_smart_goal_validation()
