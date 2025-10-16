"""
Test values storage functionality using the rhetorica layer.

Tests that Values, MajorValues, HighestOrderValues, and LifeAreas can be saved
to the database via ValuesStorageService, and that polymorphism works correctly.

Written by Claude Code on 2025-10-11
"""

import pytest
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel
from rhetorica.storage_service import ValuesStorageService


def test_general_values_storage(test_db):
    """Test saving general values with basic fields"""
    db, _ = test_db

    # Create test values
    value1 = Values(
        common_name="Continuous Learning",
        description="Regular pursuit of knowledge and skill development",
        priority=PriorityLevel(30),
        life_domain="Personal Growth"
    )

    value2 = Values(
        common_name="Environmental Stewardship",
        description="Care for the planet through daily actions",
        priority=PriorityLevel(20)
    )

    service = ValuesStorageService(database=db)
    service.store_many_instances([value1, value2])

    # Verify records were stored
    stored_values = service.get_all()
    assert len(stored_values) == 2
    assert stored_values[0].common_name == "Continuous Learning"
    assert stored_values[1].life_domain == "General"  # Default value


def test_major_values_storage_with_dict_guidance(test_db):
    """Test saving MajorValues with alignment_guidance as dict"""
    db, _ = test_db

    # Create MajorValue with structured guidance
    mental_health = MajorValues(
        common_name="Mental Health and Longevity",
        description="My brain is a thing in the world that requires maintenance",
        priority=PriorityLevel(1),
        life_domain="Physical Health",
        alignment_guidance={
            "cardio": ["distance_km", "duration_minutes"],
            "meditation": ["sessions", "duration_minutes"],
            "therapy": ["sessions"]
        }
    )

    service = ValuesStorageService(database=db)
    service.store_single_instance(mental_health)

    # Verify stored and retrieved correctly
    stored = service.get_all()
    assert len(stored) == 1
    assert isinstance(stored[0], MajorValues)
    assert stored[0].common_name == "Mental Health and Longevity"
    assert isinstance(stored[0].alignment_guidance, dict)
    assert "cardio" in stored[0].alignment_guidance


def test_major_values_storage_with_text_guidance(test_db):
    """Test saving MajorValues with alignment_guidance as text"""
    db, _ = test_db

    companionship = MajorValues(
        common_name="Companionship with Solène",
        description="Solène has bound her lot with mine",
        priority=PriorityLevel(1),
        life_domain="Relationships",
        alignment_guidance="Quality time together, shared meals, collaborative projects"
    )

    service = ValuesStorageService(database=db)
    service.store_single_instance(companionship)

    # Verify stored and retrieved correctly
    stored = service.get_all()
    assert len(stored) == 1
    assert isinstance(stored[0], MajorValues)
    assert isinstance(stored[0].alignment_guidance, str)
    assert "Quality time" in stored[0].alignment_guidance


def test_highest_order_values_storage(test_db):
    """Test saving HighestOrderValues (philosophical, not actionable)"""
    db, _ = test_db

    highest = HighestOrderValues(
        common_name="Live Well, Die in Peace",
        description="To live well is to take and share beneficial pleasures",
        priority=PriorityLevel(1),
        life_domain="Philosophy"
    )

    service = ValuesStorageService(database=db)
    service.store_single_instance(highest)

    # Verify stored and retrieved as correct type
    stored = service.get_all()
    assert len(stored) == 1
    assert isinstance(stored[0], HighestOrderValues)
    assert stored[0].incentive_type == 'highest_order'
    assert stored[0].common_name == "Live Well, Die in Peace"


def test_life_areas_storage(test_db):
    """Test saving LifeAreas (not values, but related incentives)"""
    db, _ = test_db

    life_area = LifeAreas(
        common_name="Career",
        description="Career and professional development",
        priority=PriorityLevel(15),
        life_domain="Work"
    )

    service = ValuesStorageService(database=db)
    service.store_single_instance(life_area)

    # Verify stored and retrieved as correct type
    stored = service.get_all()
    assert len(stored) == 1
    assert isinstance(stored[0], LifeAreas)
    assert stored[0].incentive_type == 'life_area'
    assert stored[0].common_name == "Career"
    assert stored[0].description == "Career and professional development"


def test_values_polymorphism(test_db):
    """Test that different value types are stored and retrieved correctly"""
    db, _ = test_db

    # Create one of each type
    general = Values(
        common_name="Creativity",
        description="Express yourself through making",
        priority=PriorityLevel(40)
    )

    major = MajorValues(
        common_name="Equanimity",
        description="Peace and freedom from suffering",
        priority=PriorityLevel(1),
        alignment_guidance="Meditation, mindful breathing, therapy sessions"
    )

    highest = HighestOrderValues(
        common_name="Holistic Cultivation",
        description="Transform capability into beautiful performance",
        priority=PriorityLevel(1)
    )

    life_area = LifeAreas(
        common_name="Physical Fitness",
        description="Physical fitness and health",
        priority=PriorityLevel(10),
        life_domain="Health"
    )

    service = ValuesStorageService(database=db)
    service.store_many_instances([general, major, highest, life_area])

    # Verify all stored with correct types
    stored = service.get_all()
    assert len(stored) == 4

    # Check each type was preserved
    types_found = {type(v).__name__ for v in stored}
    assert 'Values' in types_found
    assert 'MajorValues' in types_found
    assert 'HighestOrderValues' in types_found
    assert 'LifeAreas' in types_found


def test_values_roundtrip(test_db):
    """Test full save/retrieve cycle preserves all fields"""
    db, _ = test_db

    original = MajorValues(
        common_name="Test Value",
        description="This is a comprehensive test",
        priority=PriorityLevel(5),
        life_domain="Testing",
        alignment_guidance={"test_activity": ["metric1", "metric2"]}
    )

    service = ValuesStorageService(database=db)
    service.store_single_instance(original)

    # Retrieve and compare
    retrieved = service.get_all()[0]

    assert isinstance(retrieved, MajorValues)
    assert retrieved.common_name == original.common_name
    assert retrieved.description == original.description
    assert retrieved.priority == original.priority
    assert retrieved.life_domain == original.life_domain
    assert retrieved.alignment_guidance == original.alignment_guidance
    assert retrieved.incentive_type == 'major'


def test_values_id_roundtrip(test_db):
    """Test that value IDs are preserved during storage roundtrip"""
    db, _ = test_db

    # Create and save a value (no ID initially)
    value = Values(
        common_name="Test Value with ID",
        description="Testing ID persistence",
        priority=PriorityLevel(25)
    )
    assert value.id is None

    service = ValuesStorageService(database=db)
    service.store_single_instance(value)

    # Retrieve the value
    retrieved_values = service.get_all()
    assert len(retrieved_values) == 1

    retrieved = retrieved_values[0]
    # Verify ID was assigned
    assert retrieved.id is not None
    assert isinstance(retrieved.id, int)
    assert retrieved.id > 0


def test_values_update(test_db):
    """Test updating an existing value"""
    db, _ = test_db

    # Create and save a value
    value = MajorValues(
        common_name="Original Value",
        description="Original description",
        priority=PriorityLevel(10),
        life_domain="Testing",
        alignment_guidance="Original guidance"
    )

    service = ValuesStorageService(database=db)
    service.store_single_instance(value)

    # Retrieve the value (will have ID)
    stored_values = service.get_all()
    stored_value = stored_values[0]
    original_id = stored_value.id

    # Modify the value
    stored_value.description = "Updated description"
    stored_value.priority = PriorityLevel(5)
    stored_value.alignment_guidance = "Updated guidance"

    # Update it
    result = service.update_instance(stored_value)
    assert result['updated'] is True
    assert result['id'] == original_id

    # Retrieve again and verify
    updated_values = service.get_all()
    updated = updated_values[0]
    assert updated.id == original_id
    assert updated.description == "Updated description"
    assert updated.priority == 5
    assert updated.alignment_guidance == "Updated guidance"

