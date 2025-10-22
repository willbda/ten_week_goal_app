"""
Test values storage polymorphism using the rhetorica layer.

Tests that Values hierarchy polymorphism works correctly - that MajorValues and
HighestOrderValues are saved and retrieved as the correct subclass types.

Written by Claude Code on 2025-10-11
"""

from categoriae.values import Values, MajorValues, HighestOrderValues, PriorityLevel
from rhetorica.storage_service import ValuesStorageService


def test_values_polymorphic_roundtrip(test_db):
    """Test that different value types are saved and retrieved as correct subclasses"""
    db, _ = test_db
    service = ValuesStorageService(database=db)

    # Create one of each type
    general_value = Values(
        title="Continuous Learning",
        description="Regular pursuit of knowledge",
        priority=PriorityLevel(30)
    )

    major_value = MajorValues(
        title="Mental Health",
        description="Brain maintenance",
        priority=PriorityLevel(1),
        alignment_guidance="go to therapy, sleep regularly"
    )

    highest_value = HighestOrderValues(
        title="Truth",
        description="Seek understanding",
        priority=PriorityLevel(1)
    )

    # Store all three
    service.store_many_instances([general_value, major_value, highest_value])

    # Retrieve and verify correct types
    stored = service.get_all()
    assert len(stored) == 3

    # Find each by name and verify type
    for value in stored:
        if value.title == "Continuous Learning":
            assert type(value) == Values  # Base class, not subclass
            assert value.incentive_type == 'general'
        elif value.title == "Mental Health":
            assert isinstance(value, MajorValues)
            assert value.incentive_type == 'major'
            assert value.alignment_guidance is not None
        elif value.title == "Truth":
            assert isinstance(value, HighestOrderValues)
            assert value.incentive_type == 'highest_order'