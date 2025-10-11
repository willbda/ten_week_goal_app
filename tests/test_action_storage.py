"""
Test storage functionality using the rhetorica layer.

Tests that Actions can be saved to and retrieved from the database via ActionStorageService.

Test database: test_data/testing.db (persists for inspection after tests)
"""

from datetime import datetime
from categoriae.actions import Action
from rhetorica.storage_service import ActionStorageService


def test_action_save(test_db):
    """Test saving actions through the storage service"""
    db, db_path = test_db

    # Create test actions
    action_one = Action('Have breakfast with Solene')
    action_two = Action('call mom')
    action_three = Action('sweep neighbors porch')

    action_one.measurements = {'units': 12}
    action_two.duration_minutes = 15.0
    action_three.starttime = datetime.now()
    action_three.duration_minutes = 15.0

    test_actions = [action_one, action_two, action_three]

    # Use the rhetorica layer (ActionStorageService)
    service = ActionStorageService(database=db)
    service.store_many_instances(entities=test_actions)

    # Verify database file exists and records were stored
    assert db_path.exists()

    # Verify records were actually stored by querying
    stored_actions = service.get_all()
    assert len(stored_actions) == 3


def test_action_roundtrip(test_db):
    """Test saving and retrieving actions (full roundtrip)"""
    db, db_path = test_db

    # Create and save an action
    original_action = Action('Test roundtrip action')
    original_action.measurements = {'distance_km': 5.2, 'time_minutes': 30}
    original_action.duration_minutes = 30.0

    service = ActionStorageService(database=db)
    service.store_single_instance(original_action)

    # Retrieve all actions
    retrieved_actions = service.get_all()

    # Verify we got one action back
    assert len(retrieved_actions) == 1

    # Verify the retrieved action matches the original
    retrieved = retrieved_actions[0]
    assert retrieved.description == original_action.description
    assert retrieved.measurements == original_action.measurements
    assert retrieved.duration_minutes == original_action.duration_minutes
