"""
Relationship definitions - describe connections between domain entities.

These are NOT source entities - they represent derived/computed relationships.
The definitions (data shape) live here in categoriae.
The logic (how to compute them) lives in ethica.
"""

from dataclasses import dataclass


from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.ontology import DerivedEntity
from categoriae.values import MajorValues

@dataclass
class ActionGoalRelationship(DerivedEntity):
    """
    Represents a discovered or assigned relationship between an action and a goal.

    This defines WHAT the relationship looks like (the data shape).
    The HOW (matching logic, inference rules) lives in ethica/progress_matching.py.

    Attributes:
        action: The action that contributes to the goal
        goal: The goal being contributed to
        contribution: Amount contributed (e.g., 5.0 km toward 50 km goal)
        match_method: How this relationship was determined
            - 'auto_inferred': Computed by matching algorithm
            - 'user_confirmed': User confirmed an auto-inferred suggestion
            - 'manual': User explicitly created this relationship
        confidence: Confidence score for the relationship (0.0-1.0)
            - 1.0 for manual/confirmed matches
            - Variable for auto-inferred matches based on match quality
    """
    action: Action
    goal: Goal
    contribution: float
    assignment_method: str  # 'auto_inferred', 'user_confirmed', 'manual'
    confidence: float = 1.0


@dataclass
class MajorValueAlignment(DerivedEntity):
    """
    Represents alignment between a goal and a personal value.

    Goals should reflect MajorValues - this relationship tracks which goals
    serve which values. Used to ensure actions/goals align with what matters.

    This defines WHAT the alignment looks like (the data shape).
    The HOW (alignment detection, matching logic) would live in ethica/value_alignment.py (future).

    Attributes:
        goal: The goal being aligned
        value: The MajorValue this goal serves
        alignment_strength: How strongly aligned (0.0-1.0)
            - 1.0 = Perfect alignment (e.g., life_domain match + keyword overlap)
            - 0.5-0.9 = Partial alignment (some indicators present)
            - <0.5 = Weak/speculative alignment
        assignment_method: How this alignment was determined
            - 'auto_inferred': Detected via life_domain/keyword matching
            - 'user_confirmed': User confirmed a suggestion
            - 'manual': User explicitly declared this alignment
        confidence: Confidence in the alignment assessment (0.0-1.0)
            - 1.0 for manual/confirmed alignments
            - Variable for auto-inferred based on signal strength
    """
    goal: Goal
    value: MajorValues
    alignment_strength: float  # 0.0-1.0, distinct from confidence
    assignment_method: str  # 'auto_inferred', 'user_confirmed', 'manual'
    confidence: float = 1.0
