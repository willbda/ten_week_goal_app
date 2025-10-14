"""
Actions serve as the primary entity for this application. Much turns on the attributes and methods of actions.
"""

from datetime import datetime
from typing import Optional, Dict


class Action:
    """
    Base class defining what all Actions consist in.

    All actions must track when they were logged and have a description.
    Actions can optionally include measurements, timing data, etc.


    The initializer defines the object and expresses required variables that must either be set when instantiated or by default values provided in the code.

    Following the initializer, we might have additional derived or computed values, properties, or methods which don't need to be provided directly by the user but which are still instramental to the basic functioning of the class. For instance, we can add an is_valid that derives a boolean value to guarantee that the initialized goal actually manages to contain values that make sense for the class. Moreover, when it fails we can direct the error in meaningful ways by alerting the user of the problem.

    """

    # Declare serializable fields with types for translation layer (rhetorica)
    __serialize__ = {
        'id': int,
        'description': str,
        'log_time': datetime,
        'measurements': dict,  # Will be JSON string in DB
        'duration_minutes': float,
        'start_time': datetime
    }

    def __init__(self, description: str, id: Optional[int] = None):
        self.id = id  # None for new actions, int for stored actions
        self.description = description
        self.log_time = datetime.now()
        self.measurements: Optional[Dict[str, float]] = None
        self.duration_minutes: Optional[float] = None
        self.start_time: Optional[datetime] = None

    def is_valid(self) -> bool:
        """Validate that this action meets core requirements"""
        if not self.log_time:
            return False
        if self.measurements:
            # Check that all measurement values are positive
            for value in self.measurements.values():
                if value <= 0:
                    return False
        # If start_time exists, duration should too
        if self.start_time and not self.duration_minutes:
            return False
        return True