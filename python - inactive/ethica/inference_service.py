"""
Inference Service - Orchestrates action-goal matching across the application.

This service coordinates between:
- ethica matching logic (pure functions)
- rhetorica storage services (entity retrieval)
- Optional persistence of derived relationships

Pattern: This is a COORDINATOR, not a storage service. It uses storage services
but doesn't inherit from them.

## Why This Belongs in ethica/ (Business Logic Layer)

This is a SERVICE that orchestrates business logic operations. It's the "use case"
layer that combines lower-level business rules into higher-level workflows.

**Service Pattern Characteristics:**
1. **Orchestration**: Coordinates multiple operations (fetch → match → filter → organize)
2. **No Direct Storage**: Uses storage services but doesn't inherit from StorageService
3. **Business Workflows**: Implements use cases like "infer all matches for a term"
4. **Stateful Coordination**: Has state (injected services) but logic is pure

**What Makes This ethica (not another layer):**
- **Uses business logic**: Calls progress_matching functions (also in ethica)
- **Implements use cases**: "Find matches for period", "Suggest matches for new action"
- **Domain coordination**: Knows about Actions, Goals, but not about SQL or dicts
- **Cross-cutting concerns**: Filtering, organization, summary stats

**Why NOT categoriae?**
- categoriae has entities (Action, Goal) but no operations
- This performs operations ON those entities

**Why NOT politica?**
- politica deals with storage primitives (SQL, connections, schemas)
- This deals with domain workflows (inference, filtering, reporting)

**Why NOT rhetorica?**
- rhetorica translates formats (entity ↔ storage dict)
- This orchestrates workflows using translated entities

**Pattern**: Services in ethica coordinate business logic. They may have injected
dependencies (storage services, other services) but the logic itself is domain-focused
and testable with mocked dependencies. Think: "This is what the application DOES
with the data" rather than "This is HOW the data is stored/retrieved."

Written by Claude Code on 2025-10-11
"""

from datetime import datetime
from typing import List, Optional, Tuple
from dataclasses import dataclass

from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.relationships import ActionGoalRelationship
from ethica.progress_matching import (
    infer_matches,
    filter_ambiguous_matches,
    create_manual_match,
    confirm_suggested_match
)

# Alias for clearer naming in this service
ActionGoalMatch = ActionGoalRelationship


@dataclass
class InferenceSession:
    """
    Results from a single inference run.

    Captures what was analyzed and what was found for review/confirmation.
    """
    actions_analyzed: int
    goals_analyzed: int
    confident_matches: List[ActionGoalMatch]
    ambiguous_matches: List[ActionGoalMatch]
    unmatched_actions: List[Action]
    run_timestamp: datetime


class ActionGoalInferenceService:
    """
    Coordinates automatic and manual matching between actions and goals.

    This service:
    1. Fetches entities from storage
    2. Runs matching logic
    3. Organizes results for review
    4. (Future) Persists matches

    Does NOT inherit from StorageService - it USES storage services.
    """

    def __init__(self, action_service, goal_service, progress_service=None):
        """
        Initialize inference service.

        Args:
            action_service: ActionStorageService for fetching actions
            goal_service: GoalStorageService for fetching goals
            progress_service: Optional ProgressTrackingService for persistence
        """
        self.action_service = action_service
        self.goal_service = goal_service
        self.progress_service = progress_service

    def infer_for_period(
        self,
        start_date: datetime,
        target_date: datetime,
        confidence_threshold: float = 0.7
    ) -> InferenceSession:
        """
        Run inference for all actions/goals in a time period.

        This is the main "batch processing" entry point - analyze a term's worth
        of data and return organized results.

        Args:
            start_date: Start of period to analyze
            target_date: End of period to analyze
            confidence_threshold: Min confidence for auto-acceptance

        Returns:
            InferenceSession with all results organized for review
        """
        # Fetch all actions in period
        all_actions = self.action_service.get_all()
        period_actions = [
            a for a in all_actions
            if a.log_time and start_date <= a.log_time <= target_date
        ]

        # Fetch all goals that overlap with period
        all_goals = self.goal_service.get_all()
        period_goals = [
            g for g in all_goals
            if self._goal_overlaps_period(g, start_date, target_date)
        ]

        # Run inference
        all_matches = infer_matches(
            actions=period_actions,
            goals=period_goals,
            require_period_match=True
        )

        # Separate by confidence
        confident, ambiguous = filter_ambiguous_matches(
            all_matches,
            confidence_threshold=confidence_threshold
        )

        # Find unmatched actions
        matched_action_ids = {id(m.action) for m in all_matches}
        unmatched = [a for a in period_actions if id(a) not in matched_action_ids]

        return InferenceSession(
            actions_analyzed=len(period_actions),
            goals_analyzed=len(period_goals),
            confident_matches=confident,
            ambiguous_matches=ambiguous,
            unmatched_actions=unmatched,
            run_timestamp=datetime.now()
        )

    def infer_for_new_action(
        self,
        action: Action,
        active_goals: Optional[List[Goal]] = None
    ) -> List[ActionGoalMatch]:
        """
        Real-time inference for a single newly-logged action.

        Useful for UI: "You just logged a run - does this count toward your 120km goal?"

        Args:
            action: Newly created action
            active_goals: Optional list of goals to check (if None, fetches active goals)

        Returns:
            List of possible matches, sorted by confidence
        """
        if active_goals is None:
            # Fetch currently active goals
            all_goals = self.goal_service.get_all()
            active_goals = [
                g for g in all_goals
                if hasattr(g, 'target_date') and g.target_date and g.target_date >= datetime.now()
            ]

        # Run inference for just this action
        matches = infer_matches(
            actions=[action],
            goals=active_goals,
            require_period_match=True
        )

        # Sort by confidence descending
        matches.sort(key=lambda m: m.confidence, reverse=True)

        return matches

    def infer_for_goal(
        self,
        goal: Goal,
        start_date: Optional[datetime] = None,
        target_date: Optional[datetime] = None
    ) -> List[ActionGoalMatch]:
        """
        Find all actions that contribute to a specific goal.

        Useful for progress reports: "Show me everything that counted toward 120km goal"

        Args:
            goal: Goal to find matches for
            start_date: Optional override for period start (uses goal.start_date if None)
            target_date: Optional override for period end (uses goal.target_date if None)

        Returns:
            List of matching actions
        """
        # Determine time window
        if start_date is None and hasattr(goal, 'start_date'):
            start_date = goal.start_date
        if target_date is None and hasattr(goal, 'target_date'):
            target_date = goal.target_date

        # Fetch relevant actions
        all_actions = self.action_service.get_all()

        if start_date and target_date:
            relevant_actions = [
                a for a in all_actions
                if a.log_time and start_date <= a.log_time <= target_date
            ]
        else:
            relevant_actions = all_actions

        # Run inference
        matches = infer_matches(
            actions=relevant_actions,
            goals=[goal],
            require_period_match=bool(start_date and target_date)
        )

        return matches

    def manual_assignment(
        self,
        action: Action,
        goal: Goal,
        contribution: Optional[float] = None
    ) -> ActionGoalMatch:
        """
        User manually assigns an action to a goal.

        Args:
            action: The action to assign
            goal: The goal to assign it to
            contribution: Optional override for contribution amount

        Returns:
            ActionGoalMatch with method='manual'
        """
        match = create_manual_match(action, goal, contribution)

        # Optionally persist
        if self.progress_service:
            self.progress_service.store_matches([match])

        return match

    def confirm_match(self, suggested_match: ActionGoalMatch) -> ActionGoalMatch:
        """
        User confirms an auto-inferred match.

        Args:
            suggested_match: An auto-inferred match to confirm

        Returns:
            New match with method='user_confirmed'
        """
        confirmed = confirm_suggested_match(suggested_match)

        # Optionally persist
        if self.progress_service:
            self.progress_service.store_matches([confirmed])

        return confirmed

    def get_summary_stats(self, session: InferenceSession) -> dict:
        """
        Generate summary statistics from an inference session.

        Useful for displaying results: "Found 45 confident matches, 12 need review"

        Args:
            session: InferenceSession to summarize

        Returns:
            Dict of summary statistics
        """
        total_matches = len(session.confident_matches) + len(session.ambiguous_matches)
        match_rate = total_matches / session.actions_analyzed if session.actions_analyzed > 0 else 0

        return {
            'actions_analyzed': session.actions_analyzed,
            'goals_analyzed': session.goals_analyzed,
            'total_matches_found': total_matches,
            'confident_matches': len(session.confident_matches),
            'ambiguous_matches': len(session.ambiguous_matches),
            'unmatched_actions': len(session.unmatched_actions),
            'match_rate': f"{match_rate:.0%}",
            'run_timestamp': session.run_timestamp.isoformat()
        }

    def _goal_overlaps_period(
        self,
        goal: Goal,
        start_date: datetime,
        target_date: datetime
    ) -> bool:
        """
        Check if goal's active period overlaps with given date range.

        Args:
            goal: Goal to check
            start_date: Period start
            target_date: Period end

        Returns:
            True if goal is active during any part of the period
        """
        # Loose goals (no dates) are always active
        if not hasattr(goal, 'start_date') or not goal.start_date:
            return True

        # Check for overlap: goal.start <= period.end AND goal.target >= period.start
        return goal.start_date <= target_date and goal.target_date >= start_date


# Convenience function for quick one-off inference
def quick_infer(actions: List[Action], goals: List[Goal]) -> List[ActionGoalMatch]:
    """
    Simple wrapper for one-off inference without full service setup.

    Useful for testing or simple scripts.

    Args:
        actions: List of actions
        goals: List of goals

    Returns:
        List of confident matches only (>= 0.7 confidence)
    """
    all_matches = infer_matches(actions, goals)
    confident, _ = filter_ambiguous_matches(all_matches, confidence_threshold=0.7)
    return confident
