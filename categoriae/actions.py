"""
Actions serve as the primary entity for this application. Much turns on the attributes and methods of actions.

Refactored to use dataclasses on 2025-10-16
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, Dict

from categoriae.ontology import PersistableEntity


@dataclass
class Action(PersistableEntity):
    """
    An action taken at a point in time.
    """

    measurement_units_by_amount: Optional[Dict[str, float]] = None
    duration_minutes: Optional[float] = None
    start_time: Optional[datetime] = None

    def is_valid(self) -> bool:
        """Validate that this action meets core requirements"""
        if not self.log_time:
            return False
        if self.measurement_units_by_amount:
            # Check that all measurement values are positive
            for value in self.measurement_units_by_amount.values():
                if value <= 0:
                    return False
        # If start_time exists, duration should too
        if self.start_time and not self.duration_minutes:
            return False
        return True
