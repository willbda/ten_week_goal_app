"""
Goals are things we try to achieve within a window of time

This file contains conceptual sketches to understand entity relationships.
Written by Claude Code on 2025-10-09



"""

from abc import ABC
from datetime import datetime
from typing import Optional



class ThingIWant(ABC):
    """
    Parent class: Broadest concept
    All things I might want share a description
    """
    def __init__(self, description: str):
        self.description = description
        
    def is_valid(self, status: bool = True):
        if not self.description.strip():
            status=False
            return status

class Goal(ThingIWant):
    """
    A general objective that may or may not be time-bound.

    Goals can be aspirational ("run a marathon someday") or have
    loose targets. They're more flexible than SmartGoals.

    Optional attributes allow for varying levels of specificity.
    """
    def __init__(self,
                 description: str,
                 measurement_unit: Optional[str] = None,
                 measurement_target: Optional[float] = 0.0,
                 start_date: Optional[datetime] = None,
                 end_date: Optional[datetime] = None,
                 how_goal_is_relevant: Optional[str] = None,
                 how_goal_is_actionable: Optional[str] = None
                ):
        super().__init__(description)
        self.measurement_unit = measurement_unit
        self.measurement_target = measurement_target
        self.start_date = start_date
        self.end_date = end_date
        self.how_goal_is_relevant = how_goal_is_relevant
        self.how_goal_is_actionable = how_goal_is_actionable

    def extend_deadline(self, days: int):
        """Convenience method to extend the goal deadline"""
        if self.end_date is None:
            raise ValueError("Cannot extend deadline - goal has no end_date")
        from datetime import timedelta
        self.end_date = self.end_date + timedelta(days=days)

    def is_time_bound(self) -> bool:
        """Check if this goal has defined start and end dates"""
        return self.start_date is not None and self.end_date is not None

    def is_measurable(self) -> bool:
        """Check if this goal has a measurement unit and target"""
        return self.measurement_unit is not None and self.measurement_target is not None



class Aspiration(ThingIWant):
    """
    Sibling 2: Vague, ongoing wants
    Example: "I want to be healthy" (no deadline, no metric)
    Different from Goal because it's NOT specific or time-bound
    """
    pass  # Just inherits description, stays vague


class Distraction(ThingIWant):
    """
    Sibling 3: Things that compete for attention
    Example: "I want to scroll social media"

    Question to explore: Should this even be under ThingIWant?
    Maybe it's a ThingToAvoid? Design tension here.
    """
    pass  # Placeholder - note the `raise warning` won't work here


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
    """
    def __init__(self,
                 description: str,
                 measurement_unit: str,
                 measurement_target: float,
                 start_date: datetime,
                 end_date: datetime,
                 how_goal_is_relevant: str,
                 how_goal_is_actionable: str):

        # Validate BEFORE initializing
        if not description or not description.strip():
            raise ValueError("SmartGoal requires a clear description (Specific)")

        if not measurement_unit or not measurement_unit.strip():
            raise ValueError("SmartGoal requires measurement_unit (Measurable)")

        if measurement_target <= 0:
            raise ValueError(f"SmartGoal target must be positive, got {measurement_target} (Achievable)")

        if start_date >= end_date:
            raise ValueError("SmartGoal start_date must be before end_date (Time-bound)")

        if end_date <= datetime.now():
            raise ValueError("SmartGoal end_date must be in the future (Time-bound)")

        if not how_goal_is_relevant or not how_goal_is_relevant.strip():
            raise ValueError("SmartGoal requires relevance statement (Relevant)")

        if not how_goal_is_actionable or not how_goal_is_actionable.strip():
            raise ValueError("SmartGoal requires actionability statement (Achievable)")

        # All validation passed - call parent with all required fields
        super().__init__(
            description=description,
            measurement_unit=measurement_unit,
            measurement_target=measurement_target,
            start_date=start_date,
            end_date=end_date,
            how_goal_is_relevant=how_goal_is_relevant,
            how_goal_is_actionable=how_goal_is_actionable
        )



    @property
    def is_smart(self) -> bool:
        """Always True - this is a SMART goal by definition"""
        return True
        


# ===== KEY PATTERNS YOU'RE SEEING =====
#
# 1. INHERITANCE: Child classes GET all parent attributes automatically
#    - SmartGoal gets 'description' without defining it
#    - Must call super().__init__() to initialize parent's attributes
#
# 2. SIBLINGS: Classes at same level differentiate by WHAT THEY ADD or HOW THEY BEHAVE
#    - Goal vs Aspiration vs Distraction all have description
#    - Different purposes/meanings in your domain
#
# 3. ATTRIBUTES IN __INIT__: Instance attributes (unique per object)
#    - measurement_unit: str at class level = wrong
#    - NOT as class attributes (would be shared by all instances)
#    - self.measurement_unit in __init__ = right
