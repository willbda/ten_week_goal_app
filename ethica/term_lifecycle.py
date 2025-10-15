"""
Term lifecycle business logic - managing time-bounded planning periods.

Terms provide temporal scaffolding for goal organization. This module implements
business rules for:
- Finding active terms
- Associating goals with terms (explicit commitment vs. date overlap)
- Filtering actions by term boundaries
- Term transition logic

## The Philosophy of Terms

Terms are more than filters - they are COMMITMENT CONTAINERS. Like academic semesters,
a term represents:

1. **Intentional focus** - "These are MY goals for THIS term"
2. **Temporal boundaries** - Clear start/end for planning and reflection
3. **Contextual grouping** - Goals that should be considered together
4. **Motivational framing** - Deadlines that prevent indefinite drift

While goals have objective timeframes (start_date/end_date for when they can be done), terms represent the subjective commitment (when I will focus on them).

A goal might span 6 months, but you commit to it for one 10-week term within that window.

Written by Claude Code on 2025-10-13
Updated by Claude Code on 2025-10-14 (added presentation helper functions)
"""

from datetime import datetime, timedelta
from typing import List, Optional, Tuple
from categoriae.terms import GoalTerm
from categoriae.goals import Goal
from categoriae.actions import Action
from config.logging_setup import get_logger

logger = get_logger(__name__)


def get_active_term(
    terms: List[GoalTerm],
    check_date: Optional[datetime] = None
) -> Optional[GoalTerm]:
    """
    Find the term that is active on a given date.

    Args:
        terms: List of all terms to search
        check_date: Date to check (defaults to today)

    Returns:
        Active term if found, None otherwise
    """
    check = check_date or datetime.now()

    for term in terms:
        if term.is_active(check):
            return term

    return None


def get_committed_goals(term: GoalTerm, all_goals: List[Goal]) -> List[Goal]:
    """
    Return goals explicitly committed to this term.

    These are the goals we choose to work on during this term - an intentional
    focus. This is the primary relationship between terms and goals.

    Args:
        term: The term to find goals for
        all_goals: All available goals

    Returns:
        List of goals explicitly assigned to this term
    """
    committed = []

    for goal in all_goals:
        # Explicit assignment (goal ID in term.term_goal_ids list)
        if hasattr(goal, 'id') and goal.id in term.term_goal_ids:
            committed.append(goal)

    return committed


def get_overlapping_goals(term: GoalTerm, all_goals: List[Goal]) -> List[Goal]:
    """
    Return goals whose date ranges overlap with this term (but weren't explicitly committed).

    These are goals that can happen to be active during the term, even if you didn't specifically plan to work on them this term. Useful for reflection: "What else was I working on?"

    Args:
        term: The term to check overlap with
        all_goals: All available goals

    Returns:
        List of goals with date overlap (excluding already-committed goals)
    """
    committed_ids = set(term.term_goal_ids)
    overlapping = []

    for goal in all_goals:
        # Skip if already committed
        if hasattr(goal, 'id') and goal.id in committed_ids:
            continue

        # Check date range overlap (for SmartGoals with dates)
        if hasattr(goal, 'start_date') and hasattr(goal, 'end_date'):
            if goal.start_date and goal.end_date:
                # Date ranges overlap if one starts before the other ends
                overlaps = (
                    goal.start_date <= term.end_date and
                    goal.end_date >= term.start_date
                )
                if overlaps:
                    overlapping.append(goal)

    return overlapping


def get_all_term_goals(term: GoalTerm, all_goals: List[Goal]) -> dict:
    """
    Get both committed and overlapping goals for a term.

    Returns a dict to preserve the semantic distinction:
    - committed: Goals you intentionally chose for this term
    - overlapping: Other goals that happened during this period

    This distinction is important for reflection and reporting.

    Args:
        term: The term to analyze
        all_goals: All available goals

    Returns:
        Dict with keys 'committed' and 'overlapping', each containing List[Goal]
    """
    return {
        'committed': get_committed_goals(term, all_goals),
        'overlapping': get_overlapping_goals(term, all_goals)
    }


def get_actions_in_term(
    term: GoalTerm,
    all_actions: List[Action]
) -> List[Action]:
    """
    Return actions that occurred during this term's time period.

    Args:
        term: The term to filter by
        all_actions: All available actions

    Returns:
        List of actions with log_time within term boundaries
    """
    matched_actions = []

    for action in all_actions:
        if action.log_time:
            # Action occurred during term
            if term.start_date <= action.log_time <= term.end_date:
                matched_actions.append(action)

    return matched_actions


def is_term_complete(term: GoalTerm, check_date: Optional[datetime] = None) -> bool:
    """
    Check if a term has ended.

    Args:
        term: Term to check
        check_date: Date to check against (defaults to today)

    Returns:
        True if term's end_date has passed
    """
    check = check_date or datetime.now()
    return check > term.end_date


def is_term_upcoming(term: GoalTerm, check_date: Optional[datetime] = None) -> bool:
    """
    Check if a term hasn't started yet.

    Args:
        term: Term to check
        check_date: Date to check against (defaults to today)

    Returns:
        True if term's start_date is in the future
    """
    check = check_date or datetime.now()
    return check < term.start_date


def get_term_status(term: GoalTerm, check_date: Optional[datetime] = None) -> str:
    """
    Get human-readable status of a term.

    Args:
        term: Term to check
        check_date: Date to check against (defaults to today)

    Returns:
        One of: 'upcoming', 'active', 'complete'
    """
    if is_term_upcoming(term, check_date):
        return 'upcoming'
    elif term.is_active(check_date):
        return 'active'
    else:
        return 'complete'


def calculate_term_progress(
    term: GoalTerm,
    term_goals: List[Goal],
    check_date: Optional[datetime] = None
) -> dict:
    """
    Calculate aggregate progress statistics for a term.

    This provides a summary view of how the term is progressing based on
    its associated goals. Detailed goal progress should be calculated using
    ethica.progress_aggregation.

    Args:
        term: The term to analyze
        term_goals: Goals associated with this term
        check_date: Date to calculate from (defaults to today)

    Returns:
        Dict with keys:
        - term_number: int
        - days_elapsed: int
        - days_remaining: int
        - percent_time_complete: float (0.0 to 1.0)
        - total_goals: int
        - status: str ('upcoming', 'active', 'complete')
    """
    check = check_date or datetime.now()

    return {
        'term_number': term.term_number,
        'days_elapsed': (check - term.start_date).days if check >= term.start_date else 0,
        'days_remaining': term.days_remaining(check),
        'percent_time_complete': term.progress_percentage(check),
        'total_goals': len(term_goals),
        'status': get_term_status(term, check)
    }


def find_term_by_number(
    terms: List[GoalTerm],
    term_number: int
) -> Optional[GoalTerm]:
    """
    Find a term by its sequential number.

    Args:
        terms: List of all terms
        term_number: The term number to find

    Returns:
        Term if found, None otherwise
    """
    for term in terms:
        if term.term_number == term_number:
            return term
    return None


def get_terms_by_status(
    terms: List[GoalTerm],
    status: str,
    check_date: Optional[datetime] = None
) -> List[GoalTerm]:
    """
    Filter terms by status.

    Args:
        terms: List of all terms
        status: One of 'upcoming', 'active', 'complete'
        check_date: Date to check against (defaults to today)

    Returns:
        List of terms with matching status
    """
    return [
        term for term in terms
        if get_term_status(term, check_date) == status
    ]


def get_unassigned_goals(all_goals: List[Goal], all_terms: List[GoalTerm]) -> List[Goal]:
    """
    Find goals that aren't committed to any term.

    These are "floating" goals that may linger indefinitely without the forcing
    function of term boundaries. Useful for:
    - Identifying goals that need term assignment
    - Finding goals that might need re-evaluation
    - Detecting goals that have drifted out of active planning

    Args:
        all_goals: All goals in the system
        all_terms: All terms (past, present, future)

    Returns:
        List of goals not assigned to any term
    """
    # Collect all goal IDs that are assigned to any term
    assigned_ids = set()
    for term in all_terms:
        assigned_ids.update(term.term_goal_ids)

    # Return goals whose IDs are not in the assigned set
    unassigned = []
    for goal in all_goals:
        if hasattr(goal, 'id') and goal.id not in assigned_ids:
            unassigned.append(goal)

    return unassigned


def validate_goal_term_assignment(
    goal: Goal,
    term: GoalTerm
) -> tuple[bool, Optional[str]]:
    """
    Validate whether a goal can be meaningfully assigned to a term.

    Checks for logical consistency:
    - Goal dates (if present) should overlap with term dates
    - Warns if goal extends significantly beyond term boundaries

    Args:
        goal: Goal to validate
        term: Term to assign to

    Returns:
        Tuple of (is_valid, warning_message)
        - is_valid: True if assignment makes sense
        - warning_message: None if valid, explanation if questionable
    """
    # If goal has no dates, assignment is always valid
    if (not hasattr(goal, 'start_date') or not goal.start_date ) or (not hasattr(goal, 'end_date') or not goal.end_date):
        return (True, None)

    # Check if goal dates overlap with term dates
    overlaps = (
        goal.start_date <= term.end_date and
        goal.end_date >= term.start_date
    )

    if not overlaps:
        return (
            False,
            f"Goal dates ({goal.start_date} to {goal.end_date}) don't overlap "
            f"with term dates ({term.start_date} to {term.end_date})"
        )

    # Warn if goal extends significantly beyond term
    goal_duration = (goal.end_date - goal.start_date).days
    term_duration = (term.end_date - term.start_date).days

    if goal_duration > term_duration * 1.5:  # Goal is 50% longer than term
        return (
            True,
            f"Goal duration ({goal_duration} days) extends significantly beyond "
            f"term duration ({term_duration} days). Consider splitting into "
            f"term-sized chunks or assigning to multiple terms."
        )

    return (True, None)


# ===== PRESENTATION HELPER FUNCTIONS =====
# These functions prepare data for presentation layers (web, CLI).
# They implement business rules about defaults, calculations, and view preparation.


def calculate_next_term_number(terms: List[GoalTerm]) -> int:
    """
    Calculate the next available term number.

    Business rule: Term numbers are sequential integers starting at 1.
    Next number is always max(existing_numbers) + 1.

    Args:
        terms: All existing terms

    Returns:
        Next term number (1 if no terms exist)
    """
    if not terms:
        return 1

    return max([t.term_number for t in terms]) + 1


def get_default_term_dates() -> Tuple[datetime, datetime]:
    """
    Get default start and end dates for a new term.

    Business rule: New terms default to starting today (at midnight) and ending
    in 10 weeks (70 days).

    Returns:
        Tuple of (start_date, end_date) as datetime objects
    """
    start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=GoalTerm.TEN_WEEKS_IN_DAYS)
    return start, end


def calculate_end_date_from_duration(
    start_date: datetime,
    duration_value: int,
    duration_unit: str
) -> datetime:
    """
    Calculate end date from start date and duration.

    Business rules for unit conversion:
    - days: Direct conversion
    - weeks: 7 days per week
    - months: 30 days per month (approximation)
    - hours: Direct timedelta conversion
    - minutes: Direct timedelta conversion

    Args:
        start_date: Starting datetime
        duration_value: Numeric duration
        duration_unit: One of 'days', 'weeks', 'months', 'hours', 'minutes'

    Returns:
        Calculated end datetime

    Raises:
        ValueError: If duration_unit is not recognized
    """
    if duration_unit == 'days':
        return start_date + timedelta(days=duration_value)
    elif duration_unit == 'weeks':
        return start_date + timedelta(weeks=duration_value)
    elif duration_unit == 'months':
        # Approximate: 30 days per month
        return start_date + timedelta(days=duration_value * 30)
    elif duration_unit == 'hours':
        return start_date + timedelta(hours=duration_value)
    elif duration_unit == 'minutes':
        return start_date + timedelta(minutes=duration_value)
    else:
        raise ValueError(f"Invalid duration_unit: {duration_unit}. "
                        f"Must be one of: days, weeks, months, hours, minutes")


def prepare_terms_list_view(
    all_terms: List[GoalTerm],
    all_goals: List[Goal],
    check_date: Optional[datetime] = None
) -> List[dict]:
    """
    Prepare enriched term data for list view presentation.

    This function implements the business logic for how terms should be
    displayed in a list view:
    - Enriches each term with status, goal counts, and progress metrics
    - Sorts by priority: active terms first, then by term number descending

    Args:
        all_terms: All terms to display
        all_goals: All goals (needed to count committed goals)
        check_date: Datetime to calculate status from (defaults to now)

    Returns:
        List of enriched term dicts, sorted appropriately for display.
        Each dict contains:
        - term: GoalTerm object
        - status: str ('upcoming', 'active', 'complete')
        - committed_goal_count: int
        - days_remaining: int or None
        - progress_percent: float or None (0-100 scale)
    """
    check = check_date or datetime.now()

    # Enrich terms with display data
    terms_with_status = []
    for term in all_terms:
        committed = get_committed_goals(term, all_goals)
        status = get_term_status(term, check)

        terms_with_status.append({
            'term': term,
            'status': status,
            'committed_goal_count': len(committed),
            'days_remaining': term.days_remaining(check) if term.is_active(check) else None,
            'progress_percent': term.progress_percentage(check) * 100 if term.is_active(check) else None
        })

    # Sort: active first, then by term number (descending)
    terms_with_status.sort(key=lambda x: (
        x['status'] != 'active',  # Active terms sort to top (False < True)
        -x['term'].term_number    # Then reverse chronological
    ))

    return terms_with_status
