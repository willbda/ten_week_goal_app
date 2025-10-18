"""
Tests for Action class in ontology layer

Written by Claude Code on 2025-10-09

Testing philosophy:
1. Test what the class SHOULD do, not implementation details
2. Test edge cases (empty values, negative numbers, None)
3. Test validation logic
4. Keep tests simple and readable
"""
from datetime import datetime

from categoriae.actions import Action


# ===== BASIC CREATION TESTS =====

def test_action_creation_with_description():
    """Action should be created with just a description"""
    action = Action("Did pushups")

    assert action.common_name == "Did pushups"
    assert action.log_time is not None
    assert isinstance(action.log_time, datetime)


def test_action_has_optional_attributes():
    """Action should have optional measurement/timing attributes"""
    action = Action("Ran")

    assert action.measurement_units_by_amount is None
    assert action.duration_minutes is None
    assert action.start_time is None


# ===== VALIDATION TESTS =====

def test_valid_action_with_measurements():
    """Valid action with positive measurements should pass validation"""
    action = Action("Ran 3 miles")
    action.measurement_units_by_amount = {"distance_miles": 3.0, "duration_minutes": 30.0}

    assert action.is_valid()


def test_invalid_action_with_negative_measurement():
    """Action with negative measurements should fail validation"""
    action = Action("Ran")
    action.measurement_units_by_amount = {"distance_miles": -5.0}

    assert not action.is_valid()


def test_invalid_action_with_zero_measurement():
    """Action with zero measurements should fail validation"""
    action = Action("Ran")
    action.measurement_units_by_amount = {"distance_miles": 0.0}

    assert not action.is_valid()


def test_invalid_action_start_time_without_duration():
    """If start_time exists, duration should too"""
    action = Action("Workout")
    action.start_time = datetime.now()
    # duration_minutes is None

    assert not action.is_valid()


def test_valid_action_with_start_time_and_duration():
    """Action with both start_time and duration should be valid"""
    action = Action("Workout")
    action.start_time = datetime.now()
    action.duration_minutes = 45.0

    assert action.is_valid()


# ===== EDGE CASES =====

def test_action_with_empty_description():
    """Should allow empty description (validation could catch this)"""
    action = Action("")

    assert action.common_name == ""
    # Note: is_valid() currently doesn't check this - design decision


def test_action_with_mixed_measurements():
    """Action can have multiple different measurements"""
    action = Action("Complex workout")
    action.measurement_units_by_amount = {
        "weight_lbs": 150.0,
        "reps": 20.0,
        "sets": 3.0
    }

    assert action.is_valid()
    assert len(action.measurement_units_by_amount) == 3
