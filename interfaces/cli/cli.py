"""
Command-line interface for Ten Week Goal App.

Architecture: Mirrors Flask API simplicity
- Storage services (rhetorica) for data access
- Serializers (rhetorica) for entity construction
- Formatters (interfaces/cli) for display
- Try/except error handling throughout

No orchestration layer, no result objects - just direct operations.

Written by Claude Code on 2025-10-15
"""

import argparse
import sys
import json
from pathlib import Path
from typing import Optional

# Path setup for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import (
    ActionStorageService,
    GoalStorageService,
    TermStorageService,
    ValuesStorageService
)
from rhetorica.serializers import serialize, deserialize
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, aggregate_goal_progress
from ethica.term_lifecycle import (
    get_active_term,
    get_committed_goals,
    get_term_status,
    prepare_terms_list_view
)

from categoriae.actions import Action
from categoriae.goals import Goal
from categoriae.terms import GoalTerm

from interfaces.cli.cli_utils import (
    parse_json_arg,
    parse_datetime_arg,
    confirm_action,
    format_success,
    format_error,
    format_table_row,
    format_datetime,
    format_json,
    truncate
)
from interfaces.cli.cli_formatters import (
    render_section_header,
    render_goal_header,
    render_progress_metrics,
    render_timeline,
    render_action_list,
    render_summary_stats
)

from config.logging_setup import get_logger

logger = get_logger(__name__)


# ===== ACTION COMMANDS =====

def action_create(description: str, measurements: Optional[str] = None,
                 duration: Optional[float] = None, start_time: Optional[str] = None):
    """
    Create new action.

    Matches: POST /api/actions
    """
    try:
        # Build entity
        action = Action(common_name=description)

        if measurements:
            action.measurement_units_by_amount = parse_json_arg(measurements, "measurements")
        if duration:
            action.duration_minutes = duration
        if start_time:
            action.start_time = parse_datetime_arg(start_time, "start_time")

        # Save
        service = ActionStorageService()
        service.store_single_instance(action)

        print(format_success(f"Created action {action.id}: {action.common_name}"))

    except Exception as e:
        logger.error(f"Error creating action: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def action_list(start_date: Optional[str] = None, end_date: Optional[str] = None,
               has_measurements: bool = False, has_duration: bool = False):
    """
    List all actions with optional filters.

    Matches: GET /api/actions
    """
    try:
        service = ActionStorageService()
        actions = service.get_all()

        # Apply filters
        if has_measurements:
            actions = [a for a in actions if a.measurement_units_by_amount is not None]
        if has_duration:
            actions = [a for a in actions if a.duration_minutes is not None]
        if start_date:
            start_dt = parse_datetime_arg(start_date, "start_date")
            actions = [a for a in actions if a.log_time and a.log_time >= start_dt]
        if end_date:
            end_dt = parse_datetime_arg(end_date, "end_date")
            actions = [a for a in actions if a.log_time and a.log_time <= end_dt]

        # Display
        if not actions:
            print("No actions found.")
            return

        print(render_section_header(f"ACTIONS ({len(actions)})"))
        print(format_table_row(["ID", "Description", "Date", "Measurements"], [5, 50, 12, 30]))
        print("-" * 100)

        for action in actions:
            print(format_table_row([
                action.id,
                truncate(action.common_name, 50),
                format_datetime(action.log_time),
                format_json(action.measurement_units_by_amount, 30)
            ], [5, 50, 12, 30]))

        print(f"\nTotal: {len(actions)} actions")

    except Exception as e:
        logger.error(f"Error listing actions: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def action_show(action_id: int):
    """
    Show detailed information for single action.

    Matches: GET /api/actions/<id>
    """
    try:
        service = ActionStorageService()
        action = service.get_by_id(action_id)

        if not action:
            print(format_error(f"Action {action_id} not found"))
            sys.exit(1)

        # Display details
        print(render_section_header(f"ACTION #{action_id}"))
        print(f"Description:      {action.common_name}")
        print(f"Logged:           {format_datetime(action.log_time, show_time=True)}")

        if action.measurement_units_by_amount:
            print(f"Measurements:     {json.dumps(action.measurement_units_by_amount, indent=2)}")
        if action.duration_minutes:
            print(f"Duration:         {action.duration_minutes} minutes")
        if action.start_time:
            print(f"Start Time:       {format_datetime(action.start_time, show_time=True)}")

    except Exception as e:
        logger.error(f"Error showing action {action_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def action_edit(action_id: int, description: Optional[str] = None,
               measurements: Optional[str] = None, duration: Optional[float] = None):
    """
    Update existing action.

    Matches: PUT /api/actions/<id>
    """
    try:
        service = ActionStorageService()
        action = service.get_by_id(action_id)

        if not action:
            print(format_error(f"Action {action_id} not found"))
            sys.exit(1)

        # Apply updates
        if description:
            action.common_name = description
        if measurements:
            action.measurement_units_by_amount = parse_json_arg(measurements, "measurements")
        if duration:
            action.duration_minutes = duration

        # Save
        service.save(action, notes=f'CLI edit: Updated action {action_id}')

        print(format_success(f"Updated action {action_id}"))

    except Exception as e:
        logger.error(f"Error editing action {action_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def action_delete(action_id: int, force: bool = False):
    """
    Delete action with confirmation.

    Matches: DELETE /api/actions/<id>
    """
    try:
        service = ActionStorageService()
        action = service.get_by_id(action_id)

        if not action:
            print(format_error(f"Action {action_id} not found"))
            sys.exit(1)

        # Confirm unless --force
        if not force and not confirm_action(f"Delete '{action.common_name}'?"):
            print("Delete cancelled")
            return

        # Delete with archiving
        service.delete(action_id, notes=f'CLI delete: {action.common_name}')

        print(format_success(f"Deleted action {action_id}"))

    except Exception as e:
        logger.error(f"Error deleting action {action_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def action_goals(action_id: int):
    """
    Show goals this action contributes to.

    Matches: GET /api/actions/<id>/goals
    """
    try:
        action_service = ActionStorageService()
        action = action_service.get_by_id(action_id)

        if not action:
            print(format_error(f"Action {action_id} not found"))
            sys.exit(1)

        # Fetch goals and infer matches
        goal_service = GoalStorageService()
        goals = goal_service.get_all()

        matches = infer_matches(actions=[action], goals=goals)

        # Display
        print(render_section_header(f"GOALS FOR ACTION #{action_id}"))
        print(f"Action: {action.common_name}\n")

        if not matches:
            print("No matching goals found.")
            return

        print(format_table_row(["Goal ID", "Description", "Contribution", "Method"], [8, 50, 15, 15]))
        print("-" * 90)

        for match in matches:
            print(format_table_row([
                match.goal.id,
                truncate(match.goal.common_name, 50),
                f"{match.contribution} {match.goal.measurement_unit or ''}",
                match.assignment_method
            ], [8, 50, 15, 15]))

        print(f"\nTotal: {len(matches)} matching goals")

    except Exception as e:
        logger.error(f"Error fetching goals for action {action_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


# ===== GOAL COMMANDS =====

def goal_create(description: str, unit: Optional[str] = None, target: Optional[float] = None,
               start_date: Optional[str] = None, end_date: Optional[str] = None,
               relevant: Optional[str] = None, actionable: Optional[str] = None):
    """
    Create new goal.

    Matches: POST /api/goals
    """
    try:
        # Build entity
        goal = Goal(
            common_name=description,
            measurement_unit=unit,
            measurement_target=target,
            start_date=parse_datetime_arg(start_date, "start_date"),
            end_date=parse_datetime_arg(end_date, "end_date"),
            how_goal_is_relevant=relevant,
            how_goal_is_actionable=actionable
        )

        # Save
        service = GoalStorageService()
        service.store_single_instance(goal)

        print(format_success(f"Created goal {goal.id}: {goal.common_name}"))

    except Exception as e:
        logger.error(f"Error creating goal: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def goal_list(has_dates: bool = False, has_target: bool = False):
    """
    List all goals with optional filters.

    Matches: GET /api/goals
    """
    try:
        service = GoalStorageService()
        goals = service.get_all()

        # Apply filters
        if has_dates:
            goals = [g for g in goals if g.is_time_bound()]
        if has_target:
            goals = [g for g in goals if g.is_measurable()]

        # Display
        if not goals:
            print("No goals found.")
            return

        print(render_section_header(f"GOALS ({len(goals)})"))
        print(format_table_row(["ID", "Description", "Target", "Dates"], [5, 50, 20, 25]))
        print("-" * 102)

        for goal in goals:
            target_str = f"{goal.measurement_target} {goal.measurement_unit}" if goal.is_measurable() else ""
            dates_str = ""
            if goal.start_date and goal.end_date:
                dates_str = f"{format_datetime(goal.start_date)} → {format_datetime(goal.end_date)}"

            print(format_table_row([
                goal.id,
                truncate(goal.common_name, 50),
                target_str,
                dates_str
            ], [5, 50, 20, 25]))

        print(f"\nTotal: {len(goals)} goals")

    except Exception as e:
        logger.error(f"Error listing goals: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def goal_show(goal_id: int):
    """
    Show detailed information for single goal.

    Matches: GET /api/goals/<id>
    """
    try:
        service = GoalStorageService()
        goal = service.get_by_id(goal_id)

        if not goal:
            print(format_error(f"Goal {goal_id} not found"))
            sys.exit(1)

        # Display details
        print(render_section_header(f"GOAL #{goal_id}"))
        print(f"Description:      {goal.common_name}")

        if goal.is_measurable():
            print(f"Target:           {goal.measurement_target} {goal.measurement_unit}")
        if goal.is_time_bound():
            print(f"Start Date:       {format_datetime(goal.start_date)}")
            print(f"End Date:         {format_datetime(goal.end_date)}")
        if goal.how_goal_is_relevant:
            print(f"Relevant:         {goal.how_goal_is_relevant}")
        if goal.how_goal_is_actionable:
            print(f"Actionable:       {goal.how_goal_is_actionable}")

        print(f"Created:          {format_datetime(goal.log_time, show_time=True)}")

    except Exception as e:
        logger.error(f"Error showing goal {goal_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def goal_edit(goal_id: int, description: Optional[str] = None, unit: Optional[str] = None,
             target: Optional[float] = None, start_date: Optional[str] = None,
             end_date: Optional[str] = None):
    """
    Update existing goal.

    Matches: PUT /api/goals/<id>
    """
    try:
        service = GoalStorageService()
        goal = service.get_by_id(goal_id)

        if not goal:
            print(format_error(f"Goal {goal_id} not found"))
            sys.exit(1)

        # Apply updates
        if description:
            goal.common_name = description
        if unit:
            goal.measurement_unit = unit
        if target:
            goal.measurement_target = target
        if start_date:
            goal.start_date = parse_datetime_arg(start_date, "start_date")
        if end_date:
            goal.end_date = parse_datetime_arg(end_date, "end_date")

        # Save
        service.save(goal, notes=f'CLI edit: Updated goal {goal_id}')

        print(format_success(f"Updated goal {goal_id}"))

    except Exception as e:
        logger.error(f"Error editing goal {goal_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def goal_delete(goal_id: int, force: bool = False):
    """
    Delete goal with confirmation.

    Matches: DELETE /api/goals/<id>
    """
    try:
        service = GoalStorageService()
        goal = service.get_by_id(goal_id)

        if not goal:
            print(format_error(f"Goal {goal_id} not found"))
            sys.exit(1)

        # Confirm unless --force
        if not force and not confirm_action(f"Delete '{goal.common_name}'?"):
            print("Delete cancelled")
            return

        # Delete with archiving
        service.delete(goal_id, notes=f'CLI delete: {goal.common_name}')

        print(format_success(f"Deleted goal {goal_id}"))

    except Exception as e:
        logger.error(f"Error deleting goal {goal_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def goal_progress(goal_id: int):
    """
    Show detailed progress metrics for goal.

    Matches: GET /api/goals/<id>/progress
    """
    try:
        goal_service = GoalStorageService()
        goal = goal_service.get_by_id(goal_id)

        if not goal:
            print(format_error(f"Goal {goal_id} not found"))
            sys.exit(1)

        # Fetch actions and calculate progress
        action_service = ActionStorageService()
        actions = action_service.get_all()

        matches = infer_matches(actions, [goal])
        progress = aggregate_goal_progress(goal, matches)

        # Display using formatter
        print(render_goal_header(1, goal))
        for line in render_progress_metrics(progress):
            print(line)

        timeline = render_timeline(goal)
        if timeline:
            print(timeline)

        # Show matching actions
        if matches:
            print("\nMatching Actions:")
            for line in render_action_list(matches, progress.unit, max_preview=10):
                print(line)

    except Exception as e:
        logger.error(f"Error showing progress for goal {goal_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


# ===== TERM COMMANDS =====

def term_create(term_number: int, start_date: str, theme: Optional[str] = None,
               goal_ids: Optional[str] = None):
    """
    Create new term.

    Matches: POST /api/terms
    """
    try:
        # Parse goal_ids if provided (comma-separated or JSON array)
        term_goal_ids = []
        if goal_ids:
            try:
                # Try JSON array first
                term_goal_ids = json.loads(goal_ids)
            except json.JSONDecodeError:
                # Fall back to comma-separated
                term_goal_ids = [int(gid.strip()) for gid in goal_ids.split(',')]

        # Build entity
        term = GoalTerm(
            term_number=term_number,
            start_date=parse_datetime_arg(start_date, "start_date"),
            description=theme,
            term_goals_by_id=term_goal_ids
        )

        # Save
        service = TermStorageService()
        service.store_single_instance(term)

        print(format_success(f"Created term {term.id} (Term #{term.term_number})"))

    except Exception as e:
        logger.error(f"Error creating term: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def term_list(status_filter: Optional[str] = None):
    """
    List all terms with status.

    Matches: GET /api/terms
    """
    try:
        term_service = TermStorageService()
        goal_service = GoalStorageService()

        terms = term_service.get_all()
        goals = goal_service.get_all()

        # Enrich with status
        enriched = prepare_terms_list_view(terms, goals)

        # Apply status filter
        if status_filter:
            enriched = [t for t in enriched if t['status'] == status_filter]

        # Display
        if not enriched:
            print("No terms found.")
            return

        print(render_section_header(f"TERMS ({len(enriched)})"))
        print(format_table_row(["#", "Start Date", "Theme", "Goals", "Status"], [5, 12, 30, 8, 10]))
        print("-" * 68)

        for item in enriched:
            term = item['term']
            print(format_table_row([
                term.term_number,
                format_datetime(term.start_date),
                truncate(term.theme or "", 30),
                item['committed_goal_count'],
                item['status']
            ], [5, 12, 30, 8, 10]))

        print(f"\nTotal: {len(enriched)} terms")

    except Exception as e:
        logger.error(f"Error listing terms: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def term_show(term_id: int):
    """
    Show detailed information for single term.

    Matches: GET /api/terms/<id>
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            print(format_error(f"Term {term_id} not found"))
            sys.exit(1)

        goal_service = GoalStorageService()
        goals = goal_service.get_all()

        committed = get_committed_goals(term, goals)
        status = get_term_status(term)

        # Display details
        print(render_section_header(f"TERM #{term.term_number} (ID: {term.id})"))
        print(f"Start Date:       {format_datetime(term.start_date)}")
        print(f"End Date:         {format_datetime(term.end_date)}")
        print(f"Status:           {status}")
        if term.description:
            print(f"Theme:            {term.description}")
        if term.reflection:
            print(f"Reflection:       {term.reflection}")

        print(f"\nCommitted Goals:  {len(committed)}")
        if committed:
            for goal in committed:
                print(f"  - {goal.id}: {truncate(goal.common_name, 60)}")

    except Exception as e:
        logger.error(f"Error showing term {term_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def term_current():
    """
    Show currently active term.

    Matches: GET /api/terms/active
    """
    try:
        service = TermStorageService()
        terms = service.get_all()

        active_term = get_active_term(terms)

        if not active_term:
            print("No active term found.")
            return

        # Show details for active term
        term_show(active_term.id)

    except Exception as e:
        logger.error(f"Error fetching active term: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def term_edit(term_id: int, theme: Optional[str] = None, reflection: Optional[str] = None):
    """
    Update existing term.

    Matches: PUT /api/terms/<id>
    """
    try:
        service = TermStorageService()
        term = service.get_by_id(term_id)

        if not term:
            print(format_error(f"Term {term_id} not found"))
            sys.exit(1)

        # Apply updates
        if theme:
            term.description = theme
        if reflection:
            term.reflection = reflection

        # Save
        service.save(term, notes=f'CLI edit: Updated term {term_id}')

        print(format_success(f"Updated term {term_id}"))

    except Exception as e:
        logger.error(f"Error editing term {term_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def term_add_goal(term_id: int, goal_id: int):
    """
    Add goal to term.

    Matches: POST /api/terms/<id>/goals
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            print(format_error(f"Term {term_id} not found"))
            sys.exit(1)

        goal_service = GoalStorageService()
        goal = goal_service.get_by_id(goal_id)

        if not goal:
            print(format_error(f"Goal {goal_id} not found"))
            sys.exit(1)

        # Check if already assigned
        if goal_id in term.term_goals_by_id:
            print(format_error(f"Goal {goal_id} already assigned to term {term_id}"))
            sys.exit(1)

        # Add goal
        term.term_goals_by_id.append(goal_id)
        term_service.save(term, notes=f'CLI: Added goal {goal_id}')

        print(format_success(f"Added goal {goal_id} to term {term_id}"))

    except Exception as e:
        logger.error(f"Error adding goal to term: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def term_remove_goal(term_id: int, goal_id: int):
    """
    Remove goal from term.

    Matches: DELETE /api/terms/<id>/goals/<goal_id>
    """
    try:
        term_service = TermStorageService()
        term = term_service.get_by_id(term_id)

        if not term:
            print(format_error(f"Term {term_id} not found"))
            sys.exit(1)

        # Check if goal is assigned
        if goal_id not in term.term_goals_by_id:
            print(format_error(f"Goal {goal_id} not assigned to term {term_id}"))
            sys.exit(1)

        # Remove goal
        term.term_goals_by_id.remove(goal_id)
        term_service.save(term, notes=f'CLI: Removed goal {goal_id}')

        print(format_success(f"Removed goal {goal_id} from term {term_id}"))

    except Exception as e:
        logger.error(f"Error removing goal from term: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


# ===== VALUE COMMANDS =====

def value_create(name: str, description: str, incentive_type: str, domain: str = "General",
                priority: int = 50, guidance: Optional[str] = None):
    """
    Create new value (consolidated command for all types).

    Matches: POST /api/values
    """
    try:
        # Validate major value requirements
        if incentive_type == "major" and not guidance:
            print(format_error("Major values require --guidance"))
            sys.exit(1)

        # Create and save value (rhetorica handles type conversion and class selection)
        service = ValuesStorageService()

        value = service.create_value(
            incentive_type=incentive_type,
            common_name=name,
            description=description,
            priority=priority,  # Pass raw int - rhetorica will convert
            life_domain=domain,
            alignment_guidance=guidance
        )

        service.store_single_instance(value)

        print(format_success(f"Created {incentive_type} value {value.id}: {value.common_name}"))

    except Exception as e:
        logger.error(f"Error creating value: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def value_list(incentive_type: Optional[str] = None, domain: Optional[str] = None):
    """
    List all values with optional filters.

    Matches: GET /api/values
    """
    try:
        service = ValuesStorageService()

        # Get filtered values
        values = service.get_all(type_filter=incentive_type, domain_filter=domain)

        # Display
        if not values:
            print("No values found.")
            return

        print(render_section_header(f"VALUES ({len(values)})"))
        print(format_table_row(["ID", "Name", "Type", "Domain", "Priority"], [5, 30, 15, 15, 10]))
        print("-" * 78)

        for value in values:
            print(format_table_row([
                value.id,
                truncate(value.common_name, 30),
                value.incentive_type,
                value.life_domain,
                value.priority
            ], [5, 30, 15, 15, 10]))

        print(f"\nTotal: {len(values)} values")

    except Exception as e:
        logger.error(f"Error listing values: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def value_show(value_id: int):
    """
    Show detailed information for single value.

    Matches: GET /api/values/<id>
    """
    try:
        service = ValuesStorageService()
        value = service.get_by_id(value_id)

        if not value:
            print(format_error(f"Value {value_id} not found"))
            sys.exit(1)

        # Display details
        print(render_section_header(f"VALUE #{value_id}"))
        print(f"Name:             {value.common_name}")
        print(f"Type:             {value.incentive_type}")
        print(f"Description:      {value.description}")
        print(f"Life Domain:      {value.life_domain}")
        print(f"Priority:         {value.priority}")

        if hasattr(value, 'alignment_guidance') and value.alignment_guidance:
            print(f"Guidance:         {value.alignment_guidance}")

    except Exception as e:
        logger.error(f"Error showing value {value_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def value_edit(value_id: int, name: Optional[str] = None, description: Optional[str] = None,
              domain: Optional[str] = None, priority: Optional[int] = None,
              guidance: Optional[str] = None):
    """
    Update existing value.

    Matches: PUT /api/values/<id>
    """
    try:
        service = ValuesStorageService()
        value = service.get_by_id(value_id)

        if not value:
            print(format_error(f"Value {value_id} not found"))
            sys.exit(1)

        # Apply updates
        if name:
            value.common_name = name
        if description:
            value.description = description
        if domain:
            value.life_domain = domain
        if priority:
            value.priority = priority
        if guidance and hasattr(value, 'alignment_guidance'):
            value.alignment_guidance = guidance

        # Save
        service.save(value, notes=f'CLI edit: Updated value {value_id}')

        print(format_success(f"Updated value {value_id}"))

    except Exception as e:
        logger.error(f"Error editing value {value_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


def value_delete(value_id: int, force: bool = False):
    """
    Delete value with confirmation.

    Matches: DELETE /api/values/<id>
    """
    try:
        service = ValuesStorageService()
        value = service.get_by_id(value_id)

        if not value:
            print(format_error(f"Value {value_id} not found"))
            sys.exit(1)

        # Confirm unless --force
        if not force and not confirm_action(f"Delete '{value.common_name}'?"):
            print("Delete cancelled")
            return

        # Delete with archiving
        service.delete(value_id, notes=f'CLI delete: {value.common_name}')

        print(format_success(f"Deleted value {value_id}"))

    except Exception as e:
        logger.error(f"Error deleting value {value_id}: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


# ===== PROGRESS COMMAND =====

def show_progress(verbose: bool = False):
    """
    Display progress for all goals with matching actions.

    Original command - shows progress dashboard.
    """
    try:
        goal_service = GoalStorageService()
        action_service = ActionStorageService()

        goals = goal_service.get_all()
        actions = action_service.get_all()

        if not goals:
            print("No goals found. Add some goals first!")
            return

        # Calculate relationships and progress
        all_matches = infer_matches(actions, goals)
        all_progress = aggregate_all_goals(goals, all_matches)

        # Display report
        print(render_section_header("GOAL PROGRESS REPORT"))
        print(render_summary_stats(len(all_progress), len(actions), len(all_matches)))

        # Display each goal
        for i, progress in enumerate(all_progress, 1):
            print(render_goal_header(i, progress.goal))

            # Metrics
            for line in render_progress_metrics(progress):
                print(line)

            # Timeline
            timeline = render_timeline(progress.goal)
            if timeline:
                print(timeline)

            # Action details (if verbose mode)
            if verbose:
                action_lines = render_action_list(progress.matches, progress.unit, max_preview=5)
                for line in action_lines:
                    print(line)

            print()  # Blank line between goals

        print("=" * 80)
        print()

    except Exception as e:
        logger.error(f"Error showing progress: {e}", exc_info=True)
        print(format_error(f"Error: {e}"))
        sys.exit(1)


# ===== MAIN CLI ENTRY POINT =====

def main():
    """
    Main CLI entry point with argparse routing.

    Handles argument parsing and command dispatch.
    """
    parser = argparse.ArgumentParser(
        description='Ten Week Goal App - Track actions against goals',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s action create "Ran 5km" --measurements '{"distance_km": 5.0}'
  %(prog)s action list --from 2025-10-01 --to 2025-10-31
  %(prog)s goal create "Run 120km" --unit km --target 120
  %(prog)s goal progress 5
  %(prog)s term create --number 4 --start 2025-12-23 --theme "New Year"
  %(prog)s value create "Health" "Stay fit" --type major --guidance "Exercise 3x/week"
  %(prog)s progress --verbose
        """
    )

    subparsers = parser.add_subparsers(dest='command', help='Available commands', required=True)

    # ===== ACTION COMMANDS =====
    action_parser = subparsers.add_parser('action', help='Manage actions')
    action_subparsers = action_parser.add_subparsers(dest='action_command', required=True)

    # action create
    action_create_parser = action_subparsers.add_parser('create', help='Create new action')
    action_create_parser.add_argument('description', help='Action description')
    action_create_parser.add_argument('--measurements', help='JSON dict of measurements')
    action_create_parser.add_argument('--duration', type=float, help='Duration in minutes')
    action_create_parser.add_argument('--start-time', help='Start time (ISO format)')

    # action list
    action_list_parser = action_subparsers.add_parser('list', help='List all actions')
    action_list_parser.add_argument('--from', dest='start_date', help='Start date (ISO format)')
    action_list_parser.add_argument('--to', dest='end_date', help='End date (ISO format)')
    action_list_parser.add_argument('--has-measurements', action='store_true')
    action_list_parser.add_argument('--has-duration', action='store_true')

    # action show
    action_show_parser = action_subparsers.add_parser('show', help='Show action details')
    action_show_parser.add_argument('id', type=int, help='Action ID')

    # action edit
    action_edit_parser = action_subparsers.add_parser('edit', help='Edit action')
    action_edit_parser.add_argument('id', type=int, help='Action ID')
    action_edit_parser.add_argument('--description', help='New description')
    action_edit_parser.add_argument('--measurements', help='New measurements (JSON)')
    action_edit_parser.add_argument('--duration', type=float, help='New duration')

    # action delete
    action_delete_parser = action_subparsers.add_parser('delete', help='Delete action')
    action_delete_parser.add_argument('id', type=int, help='Action ID')
    action_delete_parser.add_argument('--force', action='store_true', help='Skip confirmation')

    # action goals
    action_goals_parser = action_subparsers.add_parser('goals', help='Show goals for action')
    action_goals_parser.add_argument('id', type=int, help='Action ID')

    # ===== GOAL COMMANDS =====
    goal_parser = subparsers.add_parser('goal', help='Manage goals')
    goal_subparsers = goal_parser.add_subparsers(dest='goal_command', required=True)

    # goal create
    goal_create_parser = goal_subparsers.add_parser('create', help='Create new goal')
    goal_create_parser.add_argument('description', help='Goal description')
    goal_create_parser.add_argument('--unit', help='Measurement unit')
    goal_create_parser.add_argument('--target', type=float, help='Target value')
    goal_create_parser.add_argument('--start-date', help='Start date (ISO format)')
    goal_create_parser.add_argument('--end-date', help='End date (ISO format)')
    goal_create_parser.add_argument('--relevant', help='How goal is relevant')
    goal_create_parser.add_argument('--actionable', help='How goal is actionable')

    # goal list
    goal_list_parser = goal_subparsers.add_parser('list', help='List all goals')
    goal_list_parser.add_argument('--has-dates', action='store_true')
    goal_list_parser.add_argument('--has-target', action='store_true')

    # goal show
    goal_show_parser = goal_subparsers.add_parser('show', help='Show goal details')
    goal_show_parser.add_argument('id', type=int, help='Goal ID')

    # goal edit
    goal_edit_parser = goal_subparsers.add_parser('edit', help='Edit goal')
    goal_edit_parser.add_argument('id', type=int, help='Goal ID')
    goal_edit_parser.add_argument('--description', help='New description')
    goal_edit_parser.add_argument('--unit', help='New measurement unit')
    goal_edit_parser.add_argument('--target', type=float, help='New target value')
    goal_edit_parser.add_argument('--start-date', help='New start date')
    goal_edit_parser.add_argument('--end-date', help='New end date')

    # goal delete
    goal_delete_parser = goal_subparsers.add_parser('delete', help='Delete goal')
    goal_delete_parser.add_argument('id', type=int, help='Goal ID')
    goal_delete_parser.add_argument('--force', action='store_true', help='Skip confirmation')

    # goal progress
    goal_progress_parser = goal_subparsers.add_parser('progress', help='Show goal progress')
    goal_progress_parser.add_argument('id', type=int, help='Goal ID')

    # ===== TERM COMMANDS =====
    term_parser = subparsers.add_parser('term', help='Manage terms')
    term_subparsers = term_parser.add_subparsers(dest='term_command', required=True)

    # term create
    term_create_parser = term_subparsers.add_parser('create', help='Create new term')
    term_create_parser.add_argument('--number', type=int, required=True, help='Term number')
    term_create_parser.add_argument('--start', required=True, help='Start date (ISO format)')
    term_create_parser.add_argument('--theme', help='Term theme')
    term_create_parser.add_argument('--goal-ids', help='Goal IDs (comma-separated or JSON array)')

    # term list
    term_list_parser = term_subparsers.add_parser('list', help='List all terms')
    term_list_parser.add_argument('--status', choices=['active', 'upcoming', 'complete'])

    # term show
    term_show_parser = term_subparsers.add_parser('show', help='Show term details')
    term_show_parser.add_argument('id', type=int, help='Term ID')

    # term current
    term_current_parser = term_subparsers.add_parser('current', help='Show active term')

    # term edit
    term_edit_parser = term_subparsers.add_parser('edit', help='Edit term')
    term_edit_parser.add_argument('id', type=int, help='Term ID')
    term_edit_parser.add_argument('--theme', help='New theme')
    term_edit_parser.add_argument('--reflection', help='Term reflection')

    # term add-goal
    term_add_goal_parser = term_subparsers.add_parser('add-goal', help='Add goal to term')
    term_add_goal_parser.add_argument('term_id', type=int, help='Term ID')
    term_add_goal_parser.add_argument('goal_id', type=int, help='Goal ID')

    # term remove-goal
    term_remove_goal_parser = term_subparsers.add_parser('remove-goal', help='Remove goal from term')
    term_remove_goal_parser.add_argument('term_id', type=int, help='Term ID')
    term_remove_goal_parser.add_argument('goal_id', type=int, help='Goal ID')

    # ===== VALUE COMMANDS =====
    value_parser = subparsers.add_parser('value', help='Manage values')
    value_subparsers = value_parser.add_subparsers(dest='value_command', required=True)

    # value create
    value_create_parser = value_subparsers.add_parser('create', help='Create new value')
    value_create_parser.add_argument('name', help='Value name')
    value_create_parser.add_argument('description', help='Value description')
    value_create_parser.add_argument('--type', required=True,
                                      choices=['general', 'major', 'highest_order', 'life_area'],
                                      help='Value type')
    value_create_parser.add_argument('--domain', default='General', help='Life domain')
    value_create_parser.add_argument('--priority', type=int, default=50, help='Priority (1-100)')
    value_create_parser.add_argument('--guidance', help='Alignment guidance (required for major values)')

    # value list
    value_list_parser = value_subparsers.add_parser('list', help='List all values')
    value_list_parser.add_argument('--type', choices=['general', 'major', 'highest_order', 'life_area'])
    value_list_parser.add_argument('--domain', help='Filter by domain')

    # value show
    value_show_parser = value_subparsers.add_parser('show', help='Show value details')
    value_show_parser.add_argument('id', type=int, help='Value ID')

    # value edit
    value_edit_parser = value_subparsers.add_parser('edit', help='Edit value')
    value_edit_parser.add_argument('id', type=int, help='Value ID')
    value_edit_parser.add_argument('--name', help='New name')
    value_edit_parser.add_argument('--description', help='New description')
    value_edit_parser.add_argument('--domain', help='New domain')
    value_edit_parser.add_argument('--priority', type=int, help='New priority')
    value_edit_parser.add_argument('--guidance', help='New guidance')

    # value delete
    value_delete_parser = value_subparsers.add_parser('delete', help='Delete value')
    value_delete_parser.add_argument('id', type=int, help='Value ID')
    value_delete_parser.add_argument('--force', action='store_true', help='Skip confirmation')

    # ===== PROGRESS COMMAND =====
    progress_parser = subparsers.add_parser('progress', help='Show progress dashboard')
    progress_parser.add_argument('-v', '--verbose', action='store_true',
                                 help='Show detailed action listings')

    # Parse and route
    args = parser.parse_args()

    # Dispatch to command handlers
    try:
        if args.command == 'action':
            if args.action_command == 'create':
                action_create(args.description, args.measurements, args.duration, args.start_time)
            elif args.action_command == 'list':
                action_list(args.start_date, args.end_date, args.has_measurements, args.has_duration)
            elif args.action_command == 'show':
                action_show(args.id)
            elif args.action_command == 'edit':
                action_edit(args.id, args.description, args.measurements, args.duration)
            elif args.action_command == 'delete':
                action_delete(args.id, args.force)
            elif args.action_command == 'goals':
                action_goals(args.id)

        elif args.command == 'goal':
            if args.goal_command == 'create':
                goal_create(args.description, args.unit, args.target, args.start_date,
                           args.end_date, args.relevant, args.actionable)
            elif args.goal_command == 'list':
                goal_list(args.has_dates, args.has_target)
            elif args.goal_command == 'show':
                goal_show(args.id)
            elif args.goal_command == 'edit':
                goal_edit(args.id, args.description, args.unit, args.target,
                         args.start_date, args.end_date)
            elif args.goal_command == 'delete':
                goal_delete(args.id, args.force)
            elif args.goal_command == 'progress':
                goal_progress(args.id)

        elif args.command == 'term':
            if args.term_command == 'create':
                term_create(args.number, args.start, args.theme, args.goal_ids)
            elif args.term_command == 'list':
                term_list(args.status)
            elif args.term_command == 'show':
                term_show(args.id)
            elif args.term_command == 'current':
                term_current()
            elif args.term_command == 'edit':
                term_edit(args.id, args.theme, args.reflection)
            elif args.term_command == 'add-goal':
                term_add_goal(args.term_id, args.goal_id)
            elif args.term_command == 'remove-goal':
                term_remove_goal(args.term_id, args.goal_id)

        elif args.command == 'value':
            if args.value_command == 'create':
                value_create(args.name, args.description, args.type, args.domain,
                           args.priority, args.guidance)
            elif args.value_command == 'list':
                value_list(args.type, args.domain)
            elif args.value_command == 'show':
                value_show(args.id)
            elif args.value_command == 'edit':
                value_edit(args.id, args.name, args.description, args.domain,
                          args.priority, args.guidance)
            elif args.value_command == 'delete':
                value_delete(args.id, args.force)

        elif args.command == 'progress':
            show_progress(args.verbose)

    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(130)


if __name__ == '__main__':
    main()
