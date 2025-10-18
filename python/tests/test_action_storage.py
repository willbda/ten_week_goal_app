"""
Test storage functionality using the rhetorica layer.

Tests that Actions can be saved to and retrieved from the database via ActionStorageService.

Test database: test_data/testing.db (persists for inspection after tests)
"""

from datetime import datetime
from categoriae.actions import Action
from rhetorica.storage_service import ActionStorageService


def test_action_roundtrip(test_db):
    """Test saving and retrieving actions (full roundtrip)"""
    db, db_path = test_db

    # Create and save an action
    original_action = Action('Test roundtrip action')
    original_action.measurement_units_by_amount = {'distance_km': 5.2, 'time_minutes': 30}
    original_action.duration_minutes = 30.0

    service = ActionStorageService(database=db)
    service.store_single_instance(original_action)

    # Retrieve all actions
    retrieved_actions = service.get_all()

    # Verify we got one action back
    assert len(retrieved_actions) == 1

    # Verify the retrieved action matches the original
    retrieved = retrieved_actions[0]
    assert retrieved.common_name == original_action.common_name
    assert retrieved.measurement_units_by_amount == original_action.measurement_units_by_amount
    assert retrieved.duration_minutes == original_action.duration_minutes


def test_action_id_roundtrip(test_db):
    """Test that IDs are preserved during storage roundtrip"""
    db, db_path = test_db

    # Create and save an action (no ID initially)
    action = Action('Action with ID')
    assert action.id is None  # New action has no ID

    service = ActionStorageService(database=db)
    service.store_single_instance(action)

    # Retrieve the action
    retrieved_actions = service.get_all()
    assert len(retrieved_actions) == 1

    retrieved = retrieved_actions[0]
    # Verify ID was assigned by database
    assert retrieved.id is not None
    assert isinstance(retrieved.id, int)
    assert retrieved.id > 0


def test_action_update(test_db):
    """Test updating an existing action"""
    db, db_path = test_db

    # Create and save an action
    action = Action('Original description')
    action.measurement_units_by_amount = {'distance_km': 5.0}

    service = ActionStorageService(database=db)
    service.store_single_instance(action)

    # Retrieve the action (will have ID)
    stored_actions = service.get_all()
    assert len(stored_actions) == 1

    stored_action = stored_actions[0]
    original_id = stored_action.id
    assert original_id is not None

    # Modify the action
    stored_action.common_name = 'Updated description'
    stored_action.measurement_units_by_amount = {'distance_km': 10.0}

    # Update it
    result = service.update_instance(stored_action)
    assert result['updated'] is True
    assert result['id'] == original_id

    # Retrieve again and verify changes persisted
    updated_actions = service.get_all()
    assert len(updated_actions) == 1

    updated = updated_actions[0]
    assert updated.id == original_id  # Same ID
    assert updated.common_name == 'Updated description'  # Updated field
    assert updated.measurement_units_by_amount == {'distance_km': 10.0}  # Updated field


