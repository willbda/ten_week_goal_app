"""
Goals are things we try to achieve within a window of time

This file contains conceptual sketches to understand entity relationships.
Written by Claude Code on 2025-10-09
Refactored to use dataclasses on 2025-10-16


"""

from abc import ABC
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Optional

from categoriae.ontology import PersistableEntity


@dataclass
class ThingIWant(PersistableEntity):
    """
    Parent class: Broadest concept - things that have a description.

    This is the required essence: all things I might want must be describable.
    """
    pass


@dataclass(unsafe_hash=True)
class Goal(ThingIWant):
    """
    A general objective that may or may not be time-bound.

    Goals can be aspirational ("run a marathon someday") or have
    loose targets. They're more flexible than SmartGoals.

    Field structure:
    - Required: description (inherited from ThingIWant)
    - Persistence: id, created_at (like PersistableEntity pattern)
    - Optional: All measurement and time-bound fields

    Note: unsafe_hash=True allows Goal objects to be used as dictionary keys
    (required by progress_aggregation.py) while remaining mutable.
    """
    # Persistence infrastructure (with defaults, like PersistableEntity)
    goal_type: str = 'Goal'  # Class identifier for polymorphic storage

    # Optional goal-specific fields
    measurement_unit: Optional[str] = None
    measurement_target: Optional[float] = 0.0
    start_date: Optional[datetime] = None
    target_date: Optional[datetime] = None  # When goal should be achieved
    how_goal_is_relevant: Optional[str] = None
    how_goal_is_actionable: Optional[str] = None
    expected_term_length: Optional[int] = None  # e.g., 10 for 10-week term



    def is_time_bound(self) -> bool:
        """Check if this goal has defined start and target dates"""
        return self.start_date is not None and self.target_date is not None

    def is_measurable(self) -> bool:
        """Check if this goal has a measurement unit and target"""
        return self.measurement_unit is not None and self.measurement_target is not None


@dataclass
class Milestone(Goal):
    """
    A significant checkpoint within a larger goal or term.

    Milestones are concrete, dated targets that mark progress toward bigger goals.
    Unlike full SmartGoals, they're more like waypoints.

    Examples:
    - "Reach 50km by week 5" (milestone toward 120km goal)
    - "Complete chapter 3 by Nov 15" (milestone toward book completion)

    This is a child of Goal: ThingIWant → Goal → Milestone
    """
    goal_type: str = 'Milestone'  # Override parent's goal_type

    def __post_init__(self):
        """
        Post-initialization to ensure milestones don't have date ranges.
        Milestones are point-in-time checkpoints, not ranges.
        """
        # Clear start_date since milestones don't have ranges
        self.start_date = None

        # Ensure target_date is set for milestones
        if self.target_date is None:
            raise ValueError("Milestone requires a target_date")


@dataclass
class SmartGoal(Goal):
    """
    SMART goal with strict validation and required fields.

    Specific, Measurable, Achievable, Relevant, Time-bound

    Enforces that all SMART criteria are met:
    - Specific: Clear description
    - Measurable: Has unit and target value
    - Achievable: Target is positive
    - Relevant: Has relevance statement
    - Time-bound: Has start and end dates in future

    Examples:
    - "Run 120km in 10 weeks starting Oct 10"
    - "Read 40 hours of technical content by Dec 19"

    This is a grandchild of ThingIWant:
    ThingIWant → Goal → SmartGoal

    Note: Fields are inherited as Optional from Goal, but validation
    in __post_init__ ensures they are provided at construction time.
    """
    goal_type: str = 'SmartGoal'  # Override parent's goal_type

    def __post_init__(self):
        """Validate SMART criteria after initialization"""
        # Validate Measurable
        if not self.measurement_unit or not self.measurement_unit.strip():
            raise ValueError("SmartGoal requires measurement_unit (Measurable)")

        # Validate Achievable - need to check for None first since Optional[float]
        if self.measurement_target is None or self.measurement_target <= 0:
            raise ValueError(f"SmartGoal target must be positive, got {self.measurement_target} (Achievable)")

        # Validate Time-bound - need to check for None first
        if self.start_date is None or self.target_date is None:
            raise ValueError("SmartGoal requires both start_date and target_date (Time-bound)")
        if self.start_date >= self.target_date:
            raise ValueError("SmartGoal start_date must be before target_date (Time-bound)")

        # Validate Relevant
        if not self.how_goal_is_relevant or not self.how_goal_is_relevant.strip():
            raise ValueError("SmartGoal requires relevance statement (Relevant)")

        # Validate Achievable (actionable)
        if not self.how_goal_is_actionable or not self.how_goal_is_actionable.strip():
            raise ValueError("SmartGoal requires how_goal_is_actionable statement (Achievable)")

    @property
    def is_smart(self) -> bool:
        """Always True - this is a SMART goal by definition"""
        return True



# ===== KEY PATTERNS =====
#
# 1. INHERITANCE: Child classes GET all parent attributes automatically
#    - SmartGoal gets 'description' without defining it
#    - dataclasses handle super().__init__() automatically
#
# 2. SIBLINGS: Classes at same level differentiate by WHAT THEY ADD or HOW THEY BEHAVE
#    - Goal vs Aspiration vs Distraction all have description
#    - Different purposes/meanings in your domain
#
# 3. DATACLASS FIELDS: Instance attributes with automatic __init__ generation
#    - No need for manual __init__ methods
#    - Use field() for default_factory and other configurations
#    - __post_init__ for validation logic that runs after initialization
