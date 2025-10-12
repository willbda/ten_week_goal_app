"""
Progress matching logic - determines which actions contribute to which goals.

This is INTERPRETATION, not storage. Actions and Goals remain independent entities.
The relationships are derived based on matching criteria.

Written by Claude Code on 2025-10-11
Updated by Claude Code on 2025-10-11 - Refactored to use categoriae/relationships
"""

from datetime import datetime
from typing import List, Optional, Tuple
from categoriae.actions import Action
from categoriae.goals import Goal, SmartGoal
from categoriae.relationships import ActionGoalRelationship

# Alias for backwards compatibility and clearer naming in this module
ActionGoalMatch = ActionGoalRelationship


def matches_on_period(action: Action, goal: Goal) -> bool:
    """
    Check if action occurred during goal's active period.

    Args:
        action: Action with logtime
        goal: Goal with start_date/end_date (SmartGoal) or no dates (loose Goal)

    Returns:
        True if action is within goal period, or goal has no period constraint
    """
    if not action.logtime:
        return False  # Can't match without timestamp

    # Loose goals have no period - accept all actions
    if not hasattr(goal, 'start_date') or not goal.start_date:
        return True

    # SmartGoal with dates
    if isinstance(goal, SmartGoal):
        return goal.start_date <= action.logtime <= goal.end_date

    return True


def matches_on_unit(action: Action, goal: Goal) -> Tuple[bool, Optional[str], Optional[float]]:
    """
    Check if action has measurements compatible with goal's target unit.

    Args:
        action: Action with optional measurements dict
        goal: Goal with measurement_unit

    Returns:
        Tuple of (matched, matched_key, value):
        - matched: True if action has compatible measurement
        - matched_key: The measurement key that matched (e.g., "distance_km")
        - value: The measurement value (e.g., 5.0)
    """
    if not action.measurements or not goal.measurement_unit:
        return (False, None, None)

    goal_unit = goal.measurement_unit.lower().replace(' ', '_')

    # Look for measurement keys that contain the goal unit
    for measurement_key, value in action.measurements.items():
        if goal_unit in measurement_key.lower():
            return (True, measurement_key, value)

    return (False, None, None)


def matches_on_description(action: Action, goal: Goal) -> float:
    """
    Check if action description suggests it's related to goal.

    Uses simple keyword matching on actionability hints or description.
    Returns confidence score 0.0-1.0.

    Args:
        action: Action with description
        goal: Goal with description and optional how_goal_is_actionable

    Returns:
        Confidence score (0.0 = no match, 1.0 = strong match)
    """
    if not action.description or not goal.description:
        return 0.0

    action_desc = action.description.lower()
    goal_desc = goal.description.lower()

    # Check if key terms from goal appear in action
    # Simple heuristic for now - can be refined
    goal_keywords = set(goal_desc.split())

    # Add actionability keywords if available
    if hasattr(goal, 'how_goal_is_actionable') and goal.how_goal_is_actionable:
        actionability_keywords = set(goal.how_goal_is_actionable.lower().split())
        goal_keywords.update(actionability_keywords)

    # Remove common words
    stopwords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for'}
    goal_keywords = {w for w in goal_keywords if w not in stopwords and len(w) > 2}

    if not goal_keywords:
        return 0.0

    # Count keyword overlap
    action_words = set(action_desc.split())
    overlap = len(goal_keywords & action_words)

    if overlap == 0:
        return 0.0

    # Confidence based on proportion of keywords found
    confidence = min(overlap / len(goal_keywords), 1.0)
    return confidence


def infer_matches(
    actions: List[Action],
    goals: List[Goal],
    require_period_match: bool = True,
    min_confidence: float = 0.5
) -> List[ActionGoalMatch]:
    """
    Automatically infer which actions contribute to which goals.

    Matching strategy (all criteria must pass):
    1. Period: Action during goal timeframe (if goal has dates)
    2. Unit: Action has measurement matching goal's unit
    3. Description: Optional confidence boost

    Args:
        actions: List of actions to match
        goals: List of active goals
        require_period_match: If True, only match actions within goal period
        min_confidence: Minimum confidence threshold for description matching

    Returns:
        List of ActionGoalMatch objects with auto-inferred relationships
    """
    matches = []

    for action in actions:
        for goal in goals:
            # Criterion 1: Period match
            period_match = matches_on_period(action, goal)
            if require_period_match and not period_match:
                continue

            # Criterion 2: Unit match (required)
            unit_match, matched_key, contribution = matches_on_unit(action, goal)
            if not unit_match:
                continue

            # Criterion 3: Description confidence (optional boost)
            description_confidence = matches_on_description(action, goal)

            # Base confidence from unit match
            confidence = 0.8  # High confidence for period + unit match

            # Boost confidence if description also matches
            if description_confidence > min_confidence:
                confidence = min(confidence + (description_confidence * 0.2), 1.0)

            matches.append(ActionGoalMatch(
                action=action,
                goal=goal,
                contribution=contribution,
                assignment_method='auto_inferred',
                confidence=confidence
            ))

    return matches


def filter_ambiguous_matches(
    matches: List[ActionGoalMatch],
    confidence_threshold: float = 0.7
) -> Tuple[List[ActionGoalMatch], List[ActionGoalMatch]]:
    """
    Separate high-confidence matches from ambiguous ones needing user confirmation.

    Args:
        matches: List of all inferred matches
        confidence_threshold: Confidence level above which matches are accepted

    Returns:
        Tuple of (confident_matches, ambiguous_matches)
    """
    confident = [m for m in matches if m.confidence >= confidence_threshold]
    ambiguous = [m for m in matches if m.confidence < confidence_threshold]

    return confident, ambiguous


def create_manual_match(
    action: Action,
    goal: Goal,
    contribution: Optional[float] = None
) -> ActionGoalMatch:
    """
    Create a manual match when user explicitly assigns action to goal.

    Args:
        action: The action to assign
        goal: The goal to assign it to
        contribution: Optional override for contribution amount
                     (if None, infers from measurements)

    Returns:
        ActionGoalMatch with method='manual' and confidence=1.0
    """
    # Infer contribution if not provided
    if contribution is None:
        _, _, contrib = matches_on_unit(action, goal)
        contribution = contrib if contrib is not None else 0.0

    return ActionGoalMatch(
        action=action,
        goal=goal,
        contribution=contribution,
        assignment_method='manual',
        confidence=1.0
    )


def confirm_suggested_match(match: ActionGoalMatch) -> ActionGoalMatch:
    """
    Convert an auto-inferred match to user-confirmed.

    Args:
        match: Auto-inferred match to confirm

    Returns:
        New ActionGoalMatch with method='user_confirmed' and confidence=1.0
    """
    return ActionGoalMatch(
        action=match.action,
        goal=match.goal,
        contribution=match.contribution,
        assignment_method='user_confirmed',
        confidence=1.0
    )
