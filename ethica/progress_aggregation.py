"""
Progress aggregation - calculate goal completion metrics from matches.

This module provides BUSINESS LOGIC for aggregating action-goal relationships
into progress metrics. Pure functions with no side effects.

## Why This Belongs in ethica/ (Business Logic Layer)

This module implements DOMAIN CALCULATIONS:
- How to sum contributions into total progress
- How to calculate percentage completion
- What "complete" means (total >= target)
- How to compute remaining work

These are business rules that should be:
1. **Reusable** across CLI, web UI, API, reports
2. **Testable** without touching presentation or storage
3. **Centralized** so the definition of "progress" is consistent

Pattern: Takes domain entities (Goal, ActionGoalRelationship) and produces
derived metrics (GoalProgress). No database, no formatting, no display logic.

Written by Claude Code on 2025-10-12
"""

from typing import List, Optional
from dataclasses import dataclass
from categoriae.goals import Goal
from categoriae.relationships import ActionGoalRelationship


@dataclass
class GoalProgress:
    """
    Aggregated progress metrics for a goal.

    This is a VALUE OBJECT - immutable data with derived properties.
    Represents the answer to: "How much progress has been made toward this goal?"

    Attributes:
        goal: The goal being measured
        matches: List of action-goal relationships contributing to this goal
        total_progress: Sum of all contributions (e.g., 102.5 km)
        target: Goal's target value (e.g., 120.0 km)
    """
    goal: Goal
    matches: List[ActionGoalRelationship]
    total_progress: float
    target: float

    @property
    def percent(self) -> float:
        """
        Progress as percentage (0.0 to potentially >100.0).

        Returns 0 if target is 0 to avoid division by zero.
        Can exceed 100% if goal is surpassed.
        """
        if self.target <= 0:
            return 0.0
        return (self.total_progress / self.target) * 100

    @property
    def remaining(self) -> float:
        """
        Amount remaining to reach target.

        Returns 0 if goal already met or exceeded (no negative remaining).
        """
        return max(0.0, self.target - self.total_progress)

    @property
    def is_complete(self) -> bool:
        """
        Whether goal has been met or exceeded.

        Business rule: A goal is "complete" when total_progress >= target.
        """
        return self.total_progress >= self.target

    @property
    def is_overachieved(self) -> bool:
        """Whether goal has been significantly exceeded (>110%)."""
        return self.percent > 110.0

    @property
    def matching_actions_count(self) -> int:
        """Number of actions contributing to this goal."""
        return len(self.matches)

    @property
    def unit(self) -> str:
        """Display unit for progress (e.g., 'km', 'hours', 'occasions')."""
        return self.goal.measurement_unit or 'units'


def aggregate_goal_progress(
    goal: Goal,
    matches: List[ActionGoalRelationship]
) -> GoalProgress:
    """
    Calculate progress metrics for a goal from matched actions.

    This is the AUTHORITATIVE calculation of goal progress. Any interface
    (CLI, web, API) should use this function to ensure consistent metrics.

    Algorithm:
    1. Sum all non-null contributions from matches
    2. Compare to goal's target
    3. Return structured GoalProgress object

    Args:
        goal: Goal to calculate progress for
        matches: List of ActionGoalRelationship objects for this goal
                (typically from InferenceService.infer_all_relationships())

    Returns:
        GoalProgress object with aggregated metrics and derived properties

    Example:
        >>> from ethica.inference_service import InferenceService
        >>> service = InferenceService()
        >>> all_matches = service.infer_all_relationships()
        >>>
        >>> # Filter matches for specific goal
        >>> goal_matches = [m for m in all_matches if m.goal.id == 5]
        >>> progress = aggregate_goal_progress(goal, goal_matches)
        >>>
        >>> print(f"Progress: {progress.percent:.1f}%")
        >>> if progress.is_complete:
        >>>     print("Goal complete!")
    """
    # Sum all contributions, treating None as 0
    total_progress = sum(
        match.contribution for match in matches
        if match.contribution is not None
    )

    # Use goal's target, default to 0 if not set
    target = goal.measurement_target if goal.measurement_target is not None else 0.0

    return GoalProgress(
        goal=goal,
        matches=matches,
        total_progress=total_progress,
        target=target
    )


def aggregate_all_goals(
    goals: List[Goal],
    all_matches: List[ActionGoalRelationship]
) -> List[GoalProgress]:
    """
    Calculate progress for multiple goals at once.

    Convenience function for batch processing. More efficient than calling
    aggregate_goal_progress() individually.

    Args:
        goals: List of goals to calculate progress for
        all_matches: All action-goal matches (will be filtered per goal)

    Returns:
        List of GoalProgress objects, one per goal (same order as input)

    Example:
        >>> all_progress = aggregate_all_goals(goals, all_matches)
        >>> complete_goals = [p for p in all_progress if p.is_complete]
        >>> print(f"{len(complete_goals)} of {len(all_progress)} goals complete")
    """
    # Group matches by goal for efficient lookup
    from collections import defaultdict
    matches_by_goal = defaultdict(list)
    for match in all_matches:
        matches_by_goal[match.goal].append(match)

    # Calculate progress for each goal
    progress_list = []
    for goal in goals:
        goal_matches = matches_by_goal.get(goal, [])
        progress = aggregate_goal_progress(goal, goal_matches)
        progress_list.append(progress)

    return progress_list


def get_progress_summary(all_progress: List[GoalProgress]) -> dict:
    """
    Calculate summary statistics across multiple goals.

    Useful for dashboard displays or reports.

    Args:
        all_progress: List of GoalProgress objects

    Returns:
        Dict with summary stats:
        {
            'total_goals': int,
            'complete_goals': int,
            'in_progress_goals': int,
            'avg_completion_percent': float,
            'total_actions_matched': int
        }
    """
    if not all_progress:
        return {
            'total_goals': 0,
            'complete_goals': 0,
            'in_progress_goals': 0,
            'avg_completion_percent': 0.0,
            'total_actions_matched': 0
        }

    complete_count = sum(1 for p in all_progress if p.is_complete)
    in_progress_count = len(all_progress) - complete_count
    avg_percent = sum(p.percent for p in all_progress) / len(all_progress)
    total_actions = sum(p.matching_actions_count for p in all_progress)

    return {
        'total_goals': len(all_progress),
        'complete_goals': complete_count,
        'in_progress_goals': in_progress_count,
        'avg_completion_percent': avg_percent,
        'total_actions_matched': total_actions
    }