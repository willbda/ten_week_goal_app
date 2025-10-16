"""
Progress matching logic - determines which actions contribute to which goals.

This is INTERPRETATION, not storage. Actions and Goals remain independent entities.
The relationships are derived based on matching criteria.

## Why This Belongs in ethica/ (Business Logic Layer)

This module implements THE CORE BUSINESS RULES for determining whether an action
contributes to a goal. These are domain-specific judgments, not just data operations.

**Key Characteristics of Business Logic (ethica):**
1. **Stateless Functions**: Takes entities in, returns derived relationships
2. **Domain Rules**: "Does this action count toward that goal?"
3. **Algorithmic Logic**: Matching strategies, confidence scoring, filtering
4. **No Side Effects**: Doesn't modify entities or persist anything

**What Makes This "Business Logic":**
- Period matching: "Is action within goal timeframe?"
- Unit matching: "Does measurement align with goal target?"
- Actionability matching: "Do keywords indicate relevance?"
- Confidence scoring: "How certain are we about this match?"
- Ambiguity filtering: "Which matches need human review?"

These are JUDGMENT CALLS based on domain knowledge, not mechanical operations.

**Why NOT categoriae?**
- categoriae defines entities (Action, Goal, ActionGoalRelationship)
- This calculates which relationships SHOULD EXIST based on rules

**Why NOT politica?**
- politica would STORE the relationships once determined
- This DETERMINES which relationships exist (no database involved)

**Why NOT rhetorica?**
- rhetorica translates data formats (entity ↔ dict for storage)
- This applies domain intelligence to create new information

**Pattern**: Business logic (ethica) operates ON entities FROM categoriae,
uses pure functions with no side effects, and can be fully tested without
touching a database. If you can test it with in-memory objects, it's business logic.

Written by Claude Code on 2025-10-11
Updated by Claude Code on 2025-10-11 - Refactored to use categoriae/relationships
Updated by Claude Code on 2025-10-12 - Added how_goal_is_actionable-based matching
"""

import json
from datetime import datetime
from typing import List, Optional, Tuple
from categoriae.actions import Action
from categoriae.goals import Goal, SmartGoal
from categoriae.relationships import ActionGoalRelationship
from config.logging_setup import get_logger

# Alias for backwards compatibility and clearer naming in this module
ActionGoalMatch = ActionGoalRelationship

logger = get_logger(__name__)


def matches_on_period(action: Action, goal: Goal) -> bool:
    """
    Check if action occurred during goal's active period.

    Args:
        action: Action with log_time
        goal: Goal with start_date/end_date (SmartGoal) or no dates (loose Goal)

    Returns:
        True if action is within goal period, or goal has no period constraint
    """
    if not action.log_time:
        return False  # Can't match without timestamp

    # Loose goals have no period - accept all actions
    if not hasattr(goal, 'start_date') or not goal.start_date:
        return True

    # SmartGoal with dates
    if isinstance(goal, SmartGoal):
        return goal.start_date <= action.log_time <= goal.end_date

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
    if not action.measurement_units_by_amount or not goal.measurement_unit:
        return (False, None, None)

    goal_unit = goal.measurement_unit.lower().replace(' ', '_')

    # Look for measurement keys that contain the goal unit
    for measurement_key, value in action.measurement_units_by_amount.items():
        if goal_unit in measurement_key.lower():
            return (True, measurement_key, value)

    return (False, None, None)


def matches_with_how_goal_is_actionable(action: Action, goal: Goal) -> Tuple[bool, Optional[float]]:
    """
    Check if action matches goal using structured how_goal_is_actionable hints.

    Parses goal's how_goal_is_actionable JSON (format: {"units": [...], "keywords": [...]})
    and checks BOTH:
    1. Action has measurement matching allowed units
    2. Action description contains required keywords

    This prevents false positives like:
    - Yoga actions matching writing goals (both use minutes)
    - Walking actions matching running goals (both use km)

    Args:
        action: Action with measurements and description
        goal: Goal with how_goal_is_actionable JSON field

    Returns:
        Tuple of (matched, contribution):
        - matched: True if both unit and keyword match
        - contribution: Measurement value if matched, None otherwise

    Examples:
        Goal how_goal_is_actionable: {"units": ["minutes"], "keywords": ["yoga", "pilates"]}
        Action: "Yoga class" with {"minutes": 30}
        → (True, 30.0)

        Goal how_goal_is_actionable: {"units": ["minutes"], "keywords": ["write", "revise"]}
        Action: "Yoga class" with {"minutes": 30}
        → (False, None)  # Wrong keywords
    """
    # If no how_goal_is_actionable hints, fall back to simple unit matching
    if not hasattr(goal, 'how_goal_is_actionable') or not goal.how_goal_is_actionable:
        unit_match, _, contribution = matches_on_unit(action, goal)
        return (unit_match, contribution)

    # Parse JSON how_goal_is_actionable
    try:
        data = json.loads(goal.how_goal_is_actionable)
        # Normalize to lowercase and strip wildcards
        allowed_units = [u.lower().strip() for u in data.get('units', [])]
        required_keywords = [k.lower().strip().replace('*', '').strip()
                           for k in data.get('keywords', []) if k.strip()]
    except (json.JSONDecodeError, AttributeError, TypeError) as e:
        # Malformed JSON - log warning and fall back to unit matching
        logger.warning(
            f"Malformed how_goal_is_actionable JSON for goal '{goal.common_name[:50]}...': {e}. "
            f"Value was: {goal.how_goal_is_actionable!r}. Falling back to simple unit matching."
        )
        unit_match, _, contribution = matches_on_unit(action, goal)
        return (unit_match, contribution)

    if not allowed_units or not required_keywords:
        # Empty how_goal_is_actionable hints - log and fall back to unit matching
        logger.debug(
            f"Empty how_goal_is_actionable hints for goal '{goal.common_name[:50]}...'. "
            f"Units: {allowed_units}, Keywords: {required_keywords}. "
            f"Falling back to simple unit matching."
        )
        unit_match, _, contribution = matches_on_unit(action, goal)
        return (unit_match, contribution)

    # Check 1: Does action have measurement matching allowed units?
    if not action.measurement_units_by_amount:
        return (False, None)

    # Check for exact unit match (case-insensitive)
    contribution = None
    for key, value in action.measurement_units_by_amount.items():
        if key.lower() in allowed_units:
            contribution = value
            break

    if contribution is None:
        return (False, None)

    # Check 2: Does action description contain required keywords?
    if not action.common_name:
        return (False, None)

    # Check if any keyword appears in description (substring, case-insensitive)
    action_lower = action.common_name.lower()
    keyword_matched = any(kw in action_lower for kw in required_keywords)

    if not keyword_matched:
        return (False, None)

    # Both checks passed!
    return (True, contribution)


def infer_matches(
    actions: List[Action],
    goals: List[Goal],
    require_period_match: bool = True
) -> List[ActionGoalMatch]:
    """
    Automatically infer which actions contribute to which goals.

    Matching strategy (all criteria must pass):
    1. Period: Action during goal timeframe (if goal has dates)
    2. Actionability: Action has correct unit AND description contains required keywords

    Uses structured how_goal_is_actionable JSON to prevent false positives.

    Args:
        actions: List of actions to match
        goals: List of active goals
        require_period_match: If True, only match actions within goal period

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

            # Criterion 2: Actionability match (unit + keywords)
            how_goal_is_actionable_match, contribution = matches_with_how_goal_is_actionable(action, goal)
            if not how_goal_is_actionable_match:
                continue

            # High confidence for period + how_goal_is_actionable match
            # Actionability already validates both unit and keyword requirements
            confidence = 0.9

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
