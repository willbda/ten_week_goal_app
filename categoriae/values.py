"""

Values reflect a personal, intentional sense of how one's life should go.

As a piece of software, values need to be defined by the end user. They are critical to understanding how things are going, but they are also an interpretive element, and so they should always be separable from actions and goals. There may also be an emergent aspect to just what a given user values -- intelligent features downstream might be able to suggest new or alternative values based on what actions a user adds...

Values are like goals in that they provide structure and meaning. Without being part of Action objects per se, they add context which allows us to evaluate the extent to which actions are aligned with values.


"""
from typing import Optional, Union
class PriorityLevel(int):
    """Simple class to represent priority levels for values and life areas.
    Lower numbers indicate higher priority (1 = highest priority).
    """
    def __new__(cls, value):
        if not (1 <= value <= 100):
            raise ValueError("PriorityLevel must be between 1 and 100")
        return int.__new__(cls, value)

class Incentives:
    """
    Base class for Values, LifeAreas, and HighestOrderValues.
    Opportunity to practice inheritance and polymorphism.

    Each subclass declares its type as a class attribute for self-identification.
    """
    incentive_type = 'incentive'  # Class attribute: What kind of thing am I?

    # Base serializable fields with types (subclasses will extend)
    __serialize__ = {
        'id': int,
        'description': str,
        'priority': int,  # PriorityLevel is int subclass
        'life_domain': str
    }

    def __init__(self, description: str, priority: PriorityLevel = PriorityLevel(50), life_domain: str = "General", id: Optional[int] = None):
        self.id = id  # None for new incentives, int for stored incentives
        self.description = description
        self.priority = priority  # 1 = highest priority
        self.life_domain = life_domain  # e.g., Health, Career, Relationships

class Values(Incentives):
    """
    Personal incentives that align with beliefs about what is worthwhile.
    """
    incentive_type = 'general'  # General values (aspirational but not primary focus)

    # Extend parent serialization with value_name
    __serialize__ = {**Incentives.__serialize__, 'value_name': str}

    def __init__(self,
                value_name: str,
                description: str,
                priority: PriorityLevel = PriorityLevel(40),
                life_domain: str = "General",
                id: Optional[int] = None
                ):
        super().__init__(description, priority, life_domain, id)
        self.value_name = value_name

class LifeAreas(Incentives):
    """
    Domains of life that provide meaning, structure, and motivation.
    These help to explain why certain actions, goals matter without implying that they are affirmed or recognized as values. E.g., my career might be a persistent life area that guides my decision-making, and detail need not say anything about whether I value it. It does provide an incentive, and noting it may help understand why 'network five times this month' shows up as a goal...

    Importantly, LifeAreas are not values
    """
    incentive_type = 'life_area'  # Organizational domains (not values)

    # Extend parent serialization with value_name
    __serialize__ = {**Incentives.__serialize__, 'value_name': str}

    def __init__(self, value_name: str, description: str, priority: PriorityLevel = PriorityLevel(40), life_domain: str = "General", id: Optional[int] = None):
        super().__init__(description, priority, life_domain, id)
        self.value_name = value_name 
        
class MajorValues(Values):
    """
    This is a middle place between Values and HighestOrderValues. HighestOrderValues are meant to be very abstract and not actionable, whereas Values are meant to be more general and diffuse. MajorValues are meant to represent a small selection of actionable values. Actions and Goals should reflect MajorValues, and it should be a concern if MajorValues are set and not reflected in Actions or Goals. This is a way of noticing misalignment, distraction, drift, etc. That need not be the cause for Values, more generally, where one might value all sorts of things and even affirm those values, without necesserily incorporating them regularly into one's tracked actions and goals.

    Attributes:
        alignment_guidance: Optional dict or text describing how this value shows up in actions/goals.
                           Structure TBD based on future ethica layer needs.
    """
    incentive_type = 'major'  # Actionable values requiring regular tracking

    # Extend Values serialization with alignment_guidance
    __serialize__ = {**Values.__serialize__, 'alignment_guidance': str}

    def __init__(
        self,
        value_name: str,
        description: str,
        priority: PriorityLevel = PriorityLevel(1),
        life_domain: str = "General",
        alignment_guidance: Optional[Union[dict, str]] = None,
        id: Optional[int] = None
    ):
        super().__init__(value_name, description, priority, life_domain, id)
        self.alignment_guidance = alignment_guidance  # Flexible for now

class HighestOrderValues(Values):
    """
    I mean for this to be a high-level, abstract concept. I might not use the class, but in my thinking about how to set goals, it was helpful to start with a sense of my highest-order values. These largely aren't actionable in a daily or even monthly sense. They might show up if I develop dashboard features as a cute or gentle way of personalizing the application. They might be helpful if I develop features for setting more goals or identifying values. For now, it's here to flesh out the inheritance structure and cue me to think about how good design allows for extension.
    """
    incentive_type = 'highest_order'  # Abstract philosophical values

    def __init__(self, value_name: str, description: str, priority: PriorityLevel = PriorityLevel(1), life_domain: str = "General", id: Optional[int] = None):
        super().__init__(value_name, description, priority, life_domain, id)

