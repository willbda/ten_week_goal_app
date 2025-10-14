"""
Terms - Time horizons for planning and reflection.

Inspired by "4,000 Weeks" thinking - how do we structure finite time?

A Term is a bounded period of intentional focus. Terms provide:
- Temporal scaffolding for goals (10 weeks, a year, a lifetime)
- Rhythmic reflection points (term reviews, retrospectives)
- Context for priority decisions (what matters THIS term?)

Written by Claude Code on 2025-10-12
"""

from abc import ABC
from datetime import datetime, date, timedelta
from typing import Optional, List

# Time horizon constants
MN_LIFE_EXPECTANCY_YEARS = 79  # CDC Minnesota life expectancy
DAYS_PER_YEAR = 365.25  # Accounting for leap years


class TimeFrame(ABC):
    """
    Abstract base for all time-bounded planning horizons.

    Time is the fundamental constraint - we have roughly 4,000 weeks.
    How we divide and allocate that time reflects what we value.
    """
    pass


class GoalTerm(TimeFrame):
    """
    Goal term -- a fundamental unit of structured planning. The idea of a "term" is inspired by academic terms but adapted for personal productivity. It should be long enough to make meaningful progress on goals, but short enough to maintain focus and urgency.
    
    A typical term is 10 weeks (70 days), but this can be adjusted based on personal preference or context. The key is to have a clear start and end date, along with defined goals and a theme or focus area if desired.
    Attributes:
        term_number: Sequential identifier (e.g., Term 1, Term 2)
        start_date: First day of term
        end_date: Last day of term (70 days later)
        theme: Optional focus area (e.g., "Health & Learning", "Relationships")
        goals: List of goal IDs associated with this term
        reflection: Post-term reflection notes
    """
    TEN_WEEKS_IN_DAYS = 70  # 10 weeks × 7 days/week

    def __init__(
        self,
        term_number: int,
        start_date: datetime,
        end_date: Optional[datetime] = None,
        theme: Optional[str] = None,
        goals: Optional[List[int]] = None,
        reflection: Optional[str] = None,
        id: Optional[int] = None
    ):
        self.id = id  # Database-assigned ID (None for new instances)
        self.term_number = term_number
        self.start_date = start_date

        # Calculate end_date if not provided
        if end_date is None:
            self.end_date = start_date + timedelta(days=GoalTerm.TEN_WEEKS_IN_DAYS)
        else:
            self.end_date = end_date

        self.theme = theme
        self.goals = goals or []
        self.reflection = reflection

    def is_active(self, check_date: Optional[datetime] = None) -> bool:
        """Check if term is currently active."""
        check = check_date or datetime.now()
        return self.start_date <= check <= self.end_date

    def days_remaining(self, from_date: Optional[datetime] = None) -> int:
        """Calculate days remaining in term."""
        check = from_date or datetime.now()
        if check > self.end_date:
            return 0
        return (self.end_date - check).days

    def progress_percentage(self, from_date: Optional[datetime] = None) -> float:
        """Calculate percentage of term completed (0.0 to 1.0)."""
        check = from_date or datetime.now()
        total_days = (self.end_date - self.start_date).days
        elapsed_days = (check - self.start_date).days

        if elapsed_days < 0:
            return 0.0
        elif elapsed_days > total_days:
            return 1.0
        else:
            return elapsed_days / total_days


class YearlyPlan(TimeFrame):
    """
    Annual planning horizon - typically 5 terms.

    A year provides natural rhythm (seasons, holidays, anniversaries).
    Yearly planning helps balance competing life areas across terms.

    Attributes:
        year: Calendar year
        terms: List of TenWeekTerm objects in this year
        annual_theme: Overarching focus (e.g., "Year of Health")
        annual_reflection: End-of-year retrospective
    """

    def __init__(
        self,
        year: int,
        terms: Optional[List[GoalTerm]] = None,
        annual_theme: Optional[str] = None,
        annual_reflection: Optional[str] = None
    ):
        self.year = year
        self.terms = terms or []
        self.annual_theme = annual_theme
        self.annual_reflection = annual_reflection

    def get_current_term(self, check_date: Optional[datetime] = None) -> Optional[GoalTerm]:
        """Return the active term, if any."""
        for term in self.terms:
            if term.is_active(check_date):
                return term
        return None


class LifeTime(TimeFrame):
    """
    Memento Mori 
    The full arc of a human life - roughly 4,500 weeks.

    "I will be dead here shortly. Realistically, maybe that's another 30 to 70 years."

    This is memento mori as data structure - a reminder that:
    - Time is finite and precious
    - How we spend weeks reveals what we truly value
    - Planning matters because we're mortal

    Attributes:
        birth_date:
        estimated_death_date: Statistical best guess (not fatalistic, just realistic)
        weeks_lived: Approximate weeks from birth to now
        weeks_remaining: Approximate weeks from now to estimated death
        life_areas_allocation: How you INTEND to spend remaining time
        life_reflection: Ongoing philosophical reflection
    """

    def __init__(
        self,
        birth_date: date,
        estimated_death_date: Optional[date] = None,
        life_areas_allocation: Optional[dict] = None,
        life_reflection: Optional[str] = None
    ):
        self.birth_date = birth_date

        # Default to Minnesota life expectancy
        if estimated_death_date is None:
            days_to_live = int(MN_LIFE_EXPECTANCY_YEARS * DAYS_PER_YEAR)
            self.estimated_death_date = birth_date + timedelta(days=days_to_live)
        else:
            self.estimated_death_date = estimated_death_date

        # How do you want to allocate your remaining time across life areas?
        # e.g., {"sleep": 0.31, "work": 0.24, "exercise": 0.08, ...}
        self.life_areas_allocation = life_areas_allocation or {}

        self.life_reflection = life_reflection

    def weeks_lived(self, from_date: Optional[date] = None) -> int:
        """Calculate approximate weeks lived so far."""
        check = from_date or date.today()
        days = (check - self.birth_date).days
        return days // 7

    def weeks_remaining(self, from_date: Optional[date] = None) -> int:
        """Calculate approximate weeks remaining."""
        check = from_date or date.today()
        days = (self.estimated_death_date - check).days
        return max(0, days // 7)

    def percentage_lived(self, from_date: Optional[date] = None) -> float:
        """What fraction of your expected life have you lived? (0.0 to 1.0)"""
        check = from_date or date.today()
        total_days = (self.estimated_death_date - self.birth_date).days
        lived_days = (check - self.birth_date).days
        return min(1.0, lived_days / total_days)

    def expected_total_weeks(self) -> int:
        """The classic '4,000 weeks' calculation."""
        total_days = (self.estimated_death_date - self.birth_date).days
        return total_days // 7
