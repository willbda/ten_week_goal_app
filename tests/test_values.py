"""
Tests for Values classes in ontology layer

Written by Claude Code on 2025-10-11

Testing philosophy:
1. Test what makes each class distinctive
2. Test the one piece of real logic (PriorityLevel validation)
3. Test that inheritance hierarchy works
4. Keep it informative, not exhaustive
"""
import pytest

from categoriae.values import (
    PriorityLevel,
    Incentives,
    Values,
    LifeAreas,
    MajorValues,
    HighestOrderValues
)


# ===== PRIORITY LEVEL - The only real logic to test =====

def test_priority_level_validates_range():
    """PriorityLevel enforces 1-100 range"""
    # Valid boundaries
    assert PriorityLevel(1) == 1
    assert PriorityLevel(100) == 100

    # Invalid values
    with pytest.raises(ValueError, match="must be between 1 and 100"):
        PriorityLevel(0)

    with pytest.raises(ValueError, match="must be between 1 and 100"):
        PriorityLevel(101)


# ===== INCENTIVES - Base class with defaults =====

def test_incentives_has_sensible_defaults():
    """Incentives provides description, priority, life_domain, and incentive_type"""
    incentive = Incentives("Be a good person")

    assert incentive.description == "Be a good person"
    assert incentive.priority == 50  # Default middle priority
    assert incentive.life_domain == "General"
    assert incentive.incentive_type == 'incentive'  # Base type


# ===== VALUES - Adds name and value flags =====

def test_values_adds_name_and_type():
    """Values adds name attribute and has incentive_type 'general'"""
    value = Values("Compassion", "Showing kindness to others")

    assert value.value_name == "Compassion"
    assert value.description == "Showing kindness to others"
    assert value.priority == 40  # Values default to 40
    assert value.incentive_type == 'general'  # General value type


# ===== LIFE AREAS - Distinct from Values despite sharing base =====

def test_life_areas_not_a_value():
    """LifeAreas inherit from Incentives but are NOT Values"""
    life_area = LifeAreas("Career", "Career success and growth")

    assert life_area.incentive_type == 'life_area'  # Life area type
    assert isinstance(life_area, Incentives)
    assert not isinstance(life_area, Values)  # LifeAreas are NOT Values


# ===== MAJOR VALUES - What makes them distinct =====

def test_major_values_distinctive_features():
    """MajorValues: priority 1, incentive_type='major', has alignment_guidance"""
    major = MajorValues(
        "Integrity",
        "Acting consistently with principles",
        alignment_guidance={"weekly_check": "Review goals vs values"}
    )

    assert major.priority == 1  # Defaults to highest priority
    assert major.incentive_type == 'major'  # Major value type
    assert isinstance(major, Values)  # Still a Value
    assert major.alignment_guidance is not None


def test_major_values_alignment_guidance_optional():
    """MajorValues work without alignment_guidance (flexible design)"""
    major = MajorValues("Courage", "Acting despite fear")

    assert major.alignment_guidance is None


# ===== HIGHEST ORDER VALUES - Abstract, priority 1 =====

def test_highest_order_values_distinctive_features():
    """HighestOrderValues: priority 1, incentive_type='highest_order'"""
    highest = HighestOrderValues("Truth", "Commitment to reality")

    assert highest.priority == 1
    assert highest.incentive_type == 'highest_order'  # Highest order type
    assert isinstance(highest, Values)  # Is a Value
    assert not isinstance(highest, MajorValues)  # Not a MajorValues subclass


# ===== INHERITANCE - Verify the hierarchy works =====

def test_type_hierarchy():
    """Verify each class knows its place in the inheritance tree"""
    value = Values("Regular", "A regular value")
    major = MajorValues("Major", "A major value")
    highest = HighestOrderValues("Highest", "Highest order")
    life_area = LifeAreas("Life Areas", "Life area description")

    # Values inherit from Incentives
    assert isinstance(value, Incentives)

    # MajorValues and HighestOrderValues inherit from Values
    assert isinstance(major, Values)
    assert isinstance(highest, Values)

    # LifeAreas inherit from Incentives but NOT Values
    assert isinstance(life_area, Incentives)
    assert not isinstance(life_area, Values)
