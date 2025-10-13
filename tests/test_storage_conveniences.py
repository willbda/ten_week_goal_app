"""
Test convenience methods added with ID support.

Tests the new save() method and other ID-based conveniences.

Written by Claude Code on 2025-10-12
"""

from categoriae.actions import Action
from categoriae.goals import Goal
from rhetorica.storage_service import ActionStorageService, GoalStorageService


def test_save_creates_new_entity(test_db):
    """Test that save() creates new entity when ID is None"""
    db, _ = test_db
    service = ActionStorageService(database=db)

    # Create new action (no ID)
    action = Action("Run 5km")
    assert action.id is None

    # Save should insert and return with ID
    saved_action = service.save(action)

    assert saved_action.id is not None
    assert saved_action.id > 0
    assert saved_action is action  # Same object reference

    # Verify in database
    retrieved = service.get_by_id(saved_action.id)
    assert retrieved is not None
    assert retrieved.description == "Run 5km"


def test_save_updates_existing_entity(test_db):
    """Test that save() updates entity when ID is present"""
    db, _ = test_db
    service = ActionStorageService(database=db)

    # Create and save
    action = service.save(Action("Original"))
    original_id = action.id

    # Modify and save again
    action.description = "Updated"
    action.measurements = {"distance_km": 10.0}

    updated_action = service.save(action)

    # Should have same ID
    assert updated_action.id == original_id

    # Verify changes persisted
    retrieved = service.get_by_id(original_id)
    assert retrieved.description == "Updated"
    assert retrieved.measurements == {"distance_km": 10.0}


def test_save_workflow_complete_cycle(test_db):
    """Test complete workflow: create, retrieve, modify, save"""
    db, _ = test_db
    service = GoalStorageService(database=db)

    # Create new goal
    goal = service.save(Goal(
        description="Run 100km",
        measurement_unit="km",
        measurement_target=100.0
    ))

    goal_id = goal.id
    assert goal_id is not None

    # Retrieve by ID
    retrieved_goal = service.get_by_id(goal_id)
    assert retrieved_goal is not None
    assert retrieved_goal.measurement_target == 100.0

    # Modify
    retrieved_goal.measurement_target = 150.0
    retrieved_goal.description = "Run 150km"

    # Save updates
    service.save(retrieved_goal)

    # Verify final state
    final_goal = service.get_by_id(goal_id)
    assert final_goal.measurement_target == 150.0
    assert final_goal.description == "Run 150km"


def test_get_by_id_returns_none_for_missing(test_db):
    """Test that get_by_id returns None for non-existent ID"""
    db, _ = test_db
    service = ActionStorageService(database=db)

    result = service.get_by_id(99999)
    assert result is None


def test_save_preserves_all_attributes(test_db):
    """Test that save() preserves all entity attributes through update"""
    db, _ = test_db
    service = ActionStorageService(database=db)

    # Create with all attributes
    from datetime import datetime
    action = Action("Test action")
    action.measurements = {"test": 1.0}
    action.duration_minutes = 30.0

    # Save
    action = service.save(action)
    action_id = action.id

    # Modify one attribute
    action.description = "Updated description"

    # Save again
    service.save(action)

    # Verify all attributes preserved
    retrieved = service.get_by_id(action_id)
    assert retrieved.description == "Updated description"
    assert retrieved.measurements == {"test": 1.0}
    assert retrieved.duration_minutes == 30.0
