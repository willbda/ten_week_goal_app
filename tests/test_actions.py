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

    assert action.description == "Did pushups"
    assert action.logtime is not None
    assert isinstance(action.logtime, datetime)


def test_action_has_optional_attributes():
    """Action should have optional measurement/timing attributes"""
    action = Action("Ran")

    assert action.measurements is None
    assert action.duration_minutes is None
    assert action.starttime is None


# ===== VALIDATION TESTS =====

def test_valid_action_with_measurements():
    """Valid action with positive measurements should pass validation"""
    action = Action("Ran 3 miles")
    action.measurements = {"distance_miles": 3.0, "duration_minutes": 30.0}

    assert action.is_valid() == True


def test_invalid_action_with_negative_measurement():
    """Action with negative measurements should fail validation"""
    action = Action("Ran")
    action.measurements = {"distance_miles": -5.0}

    assert action.is_valid() == False


def test_invalid_action_with_zero_measurement():
    """Action with zero measurements should fail validation"""
    action = Action("Ran")
    action.measurements = {"distance_miles": 0.0}

    assert action.is_valid() == False


def test_invalid_action_starttime_without_duration():
    """If starttime exists, duration should too"""
    action = Action("Workout")
    action.starttime = datetime.now()
    # duration_minutes is None

    assert action.is_valid() == False


def test_valid_action_with_starttime_and_duration():
    """Action with both starttime and duration should be valid"""
    action = Action("Workout")
    action.starttime = datetime.now()
    action.duration_minutes = 45.0

    assert action.is_valid() == True


# ===== EDGE CASES =====

def test_action_with_empty_description():
    """Should allow empty description (validation could catch this)"""
    action = Action("")

    assert action.description == ""
    # Note: is_valid() currently doesn't check this - design decision


def test_action_with_mixed_measurements():
    """Action can have multiple different measurements"""
    action = Action("Complex workout")
    action.measurements = {
        "weight_lbs": 150.0,
        "reps": 20.0,
        "sets": 3.0
    }

    assert action.is_valid() == True
    assert len(action.measurements) == 3


# ===== HOW TO RUN THESE TESTS =====
#
# Option 1: Install pytest
#   pip install pytest
#
# Option 2: Run from command line
#   pytest tests/test_actions.py
#   pytest tests/test_actions.py -v  (verbose)
#   pytest tests/test_actions.py::test_action_creation_with_description  (single test)
#
# Option 3: Run all tests
#   pytest tests/
#
# Option 4: Run with this file directly (quick check)
if __name__ == "__main__":
    # Simple test runner for quick checks without pytest
    import traceback

    test_functions = [
        test_action_creation_with_description,
        test_action_has_optional_attributes,
        test_valid_action_with_measurements,
        test_invalid_action_with_negative_measurement,
        test_invalid_action_with_zero_measurement,
        test_invalid_action_starttime_without_duration,
        test_valid_action_with_starttime_and_duration,
        test_action_with_empty_description,
        test_action_with_mixed_measurements,
    ]

    passed = 0
    failed = 0

    for test_func in test_functions:
        try:
            test_func()
            print(f"✓ {test_func.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"✗ {test_func.__name__}")
            traceback.print_exc()
            failed += 1
        except Exception as e:
            print(f"✗ {test_func.__name__} (ERROR)")
            traceback.print_exc()
            failed += 1

    print(f"\n{passed} passed, {failed} failed")
