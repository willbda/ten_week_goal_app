"""
We want to evaluate progress against goals. That's the point. So this module facilitates that.

Use classes in methods layer when:
    You have shared state across multiple methods
    You're building a service that coordinates multiple operations
    You have configuration that applies to multiple methods
Use functions when:
    Operation is stateless (just input → output)
    Each method is independent
    Starting out (simpler, easier to test)


"""

from typing import List

from dataclasses import dataclass
from categoriae.actions import Action
from categoriae.goals import Goal, SmartGoal

@dataclass
class GoalProgress:
    """Progress against SMART Goals"""
    matching_actions: List[Action]
    total_progress: float
    target: float
    
    @property
    def progress_percent(self) -> float:
        """Derived: percentage complete"""
        return (self.total_progress / self.target) * 100 if self.target > 0 else 0
    
    @property
    def remaining(self) -> float:
        """Derived: amount left to achieve"""
        return self.target - self.total_progress
    
    @property
    def is_complete(self) -> bool:
        """Derived: has goal been met?"""
        return self.total_progress >= self.target



def calculate_goal_metrics(goal: Goal, actions: List[Action]) -> GoalProgress:
    """
    Calculate progress metrics for a goal based on related actions.

    Finds actions with measurements matching the goal's unit and aggregates them.
    Returns a GoalProgress object with raw data and derived properties.
    """
    matching_actions = []
    total_progress = 0.0

    for action in actions:
        if action.measurements and goal.measurement_unit in action.measurements:
            matching_actions.append(action)
            total_progress += action.measurements[goal.measurement_unit]

    return GoalProgress(
        matching_actions=matching_actions,
        total_progress=total_progress,
        target=goal.measurement_target if goal.measurement_target is not None else 0.0
    )