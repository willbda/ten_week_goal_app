"""
REFACTORED Command-line interface for Ten Week Goal App.

This is a STUB showing proper separation of concerns.

Written by Claude Code on 2025-10-12
"""

import argparse
import sys
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from rhetorica.values_storage_service import ValuesStorageService
from rhetorica.values_orchestration_service import ValuesOrchestrationService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals
from interfaces.cli.cli_formatters import (
    render_section_header,
    render_goal_header,
    render_progress_metrics,
    render_timeline,
    render_action_list,
    render_summary_stats,
    render_value_list,
    render_value_detail
)
from interfaces.cli.cli_config import DEFAULT_DISPLAY, DEFAULT_FILTERS
from config.logging_setup import get_logger

logger = get_logger(__name__)


def show_progress(verbose: bool = False):
    """
    Display progress for all goals with matching actions.

    This command ORCHESTRATES - it doesn't implement:
    - rhetorica: Retrieves data (storage services)
    - ethica: Calculates metrics (aggregate_all_goals)
    - interfaces: Formats output (formatters module)

    Compare this to cli.py lines 27-131 (100+ lines of mixed concerns).
    This version: ~40 lines of pure orchestration.

    Args:
        verbose: If True, show detailed action listings
    """
    # Step 1: Fetch data (orchestrates rhetorica)
    try:
        goals, actions = _fetch_goals_and_actions()
    except Exception as e:
        _handle_database_error(e)
        return

    if not goals:
        print("No goals found. Add some goals first!")
        return

    # Step 2: Calculate relationships (orchestrates ethica)
    all_matches = infer_matches(
        actions,
        goals,
        require_period_match=DEFAULT_FILTERS.require_period_match
    )

    # Step 3: Calculate progress metrics (orchestrates ethica)
    all_progress = aggregate_all_goals(goals, all_matches)

    # Step 4: Display results (orchestrates formatters)
    _display_progress_report(all_progress, len(actions), len(all_matches), verbose)


def _fetch_goals_and_actions():
    """
    Fetch goals and actions from storage.

    Extracted helper for clarity and error handling.
    Returns tuple of (goals, actions).
    """
    goal_service = GoalStorageService()
    action_service = ActionStorageService()

    goals = goal_service.get_all()
    actions = action_service.get_all()

    return goals, actions


def _handle_database_error(error: Exception):
    """
    Handle database access errors gracefully.

    Extracted for testability and reuse.
    """
    print(f"Error accessing database: {error}")
    print("Make sure database is initialized. Run: from politica.database import init_db; init_db()")
    sys.exit(1)


def _display_progress_report(all_progress, total_actions, total_matches, verbose=False):
    """
    Display formatted progress report.

    Pure orchestration of formatter functions.
    No business logic, no formatting logic.

    Args:
        all_progress: List of GoalProgress objects
        total_actions: Total number of actions in database
        total_matches: Total number of action-goal matches
        verbose: Whether to show action details
    """
    # Header
    print(render_section_header("GOAL PROGRESS REPORT"))
    print(render_summary_stats(len(all_progress), total_actions, total_matches))

    # Display each goal
    for i, progress in enumerate(all_progress, 1):
        _display_single_goal(i, progress, verbose)

    # Footer
    print("=" * DEFAULT_DISPLAY.separator_width)
    print()


def _display_single_goal(goal_number, progress, verbose=False):
    """
    Display progress for a single goal.

    Pure orchestration of formatter functions.

    Args:
        goal_number: Sequential number (1, 2, 3...)
        progress: GoalProgress object with metrics
        verbose: Whether to show action details
    """
    # Header
    print(render_goal_header(goal_number, progress.goal))

    # Metrics (target, progress, bar, completion status)
    for line in render_progress_metrics(progress):
        print(line)

    # Timeline (if dates exist)
    timeline = render_timeline(progress.goal)
    if timeline:
        print(timeline)

    # Action details (if verbose mode)
    if verbose:
        action_lines = render_action_list(
            progress.matches,
            progress.unit,
            max_preview=DEFAULT_DISPLAY.preview_action_count
        )
        for line in action_lines:
            print(line)

    print()  # Blank line between goals


def values_create_major(name: str, description: str, domain: str, priority: int, alignment_guidance: str):
    """Create a major value using orchestration service."""
    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_major_value(
        name=name,
        description=description,
        priority=priority,
        life_domain=domain,
        alignment_guidance=alignment_guidance
    )

    if result.success and result.value:
        print(f"✓ Created major value: {result.value.name} (ID: {result.value.id})")
    else:
        print(f"Error: {result.error or 'Unknown error'}")
        sys.exit(1)


def values_create_highest_order(name: str, description: str, domain: str = 'General', priority: int = 1):
    """Create a highest order value using orchestration service."""
    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_highest_order_value(
        name=name,
        description=description,
        priority=priority,
        life_domain=domain
    )

    if result.success and result.value:
        print(f"✓ Created highest order value: {result.value.name} (ID: {result.value.id})")
    else:
        print(f"Error: {result.error or 'Unknown error'}")
        sys.exit(1)


def life_areas_create(name: str, description: str, domain: str = 'General', priority: int = 40):
    """Create a life area using orchestration service."""
    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_life_area(
        name=name,
        description=description,
        priority=priority,
        life_domain=domain
    )

    if result.success and result.value:
        print(f"✓ Created life area: {result.value.name} (ID: {result.value.id})")
    else:
        print(f"Error: {result.error or 'Unknown error'}")
        sys.exit(1)


def values_create_general(name: str, description: str, domain: str = 'General', priority: int = 50):
    """Create a general value using orchestration service."""
    orchestrator = ValuesOrchestrationService()
    result = orchestrator.create_general_value(
        name=name,
        description=description,
        priority=priority,
        life_domain=domain
    )

    if result.success and result.value:
        print(f"✓ Created general value: {result.value.name} (ID: {result.value.id})")
    else:
        print(f"Error: {result.error or 'Unknown error'}")
        sys.exit(1)


def values_list(value_type: Optional[str] = None, domain: Optional[str] = None):
    """
    Display list of all personal values.

    This command ORCHESTRATES - it doesn't implement:
    - rhetorica: Retrieves and filters data (ValuesOrchestrationService)
    - interfaces: Formats output (render_value_list)

    Args:
        value_type: Optional filter by type ('general', 'major', 'highest_order', 'life_area')
        domain: Optional filter by life domain
    """
    # Fetch data with filtering at storage layer
    orchestrator = ValuesOrchestrationService()
    filtered_values = orchestrator.get_all_values(
        type_filter=value_type,
        domain_filter=domain
    )

    if not filtered_values:
        if value_type or domain:
            print(f"No values found matching filters (type={value_type}, domain={domain})")
        else:
            print("No values found. Add some values first!")
        return

    # Display results (orchestrates formatters)
    print(render_value_list(filtered_values))


def values_show(value_id: int):
    """
    Display detailed information for a single value.

    This command ORCHESTRATES - it doesn't implement:
    - rhetorica: Retrieves data (ValuesStorageService)
    - interfaces: Formats output (render_value_detail)

    Args:
        value_id: Database ID of the value to display

    Written by Claude Code on 2025-10-13
    """
    # Step 1: Fetch data (orchestrates rhetorica)
    try:
        service = ValuesStorageService()
        value = service.get_by_id(value_id)
    except Exception as e:
        _handle_database_error(e)
        return

    if not value:
        print(f"Error: Value with ID {value_id} not found")
        sys.exit(1)

    # Step 2: Display results (orchestrates formatters)
    print(render_value_detail(value))


def values_edit(value_id: int, name: Optional[str] = None, description: Optional[str] = None,
                domain: Optional[str] = None, priority: Optional[int] = None,
                alignment_guidance: Optional[str] = None):
    """
    Update an existing value's fields using orchestration service.

    Only provided fields are updated; others remain unchanged.
    Type cannot be changed (general -> major, etc.).

    Args:
        value_id: Database ID of the value to update
        name: New name (optional)
        description: New description (optional)
        domain: New life domain (optional)
        priority: New priority level 1-100 (optional)
        alignment_guidance: New alignment guidance (optional, only for MajorValues)
    """
    orchestrator = ValuesOrchestrationService()
    result = orchestrator.update_value(
        value_id=value_id,
        name=name,
        description=description,
        domain=domain,
        priority=priority,
        alignment_guidance=alignment_guidance,
        notes=f'CLI edit: Updated value {value_id}'
    )

    if result.success and result.value:
        print(f"✓ Updated value: {result.value.name} (ID: {value_id})")
    else:
        print(f"Error: {result.error or 'Unknown error'}")
        sys.exit(1)


def values_delete(value_id: int, force: bool = False):
    """
    Delete a value with confirmation prompt using orchestration service.

    Archives the value before deletion for audit trail.

    Args:
        value_id: Database ID of the value to delete
        force: If True, skip confirmation prompt
    """
    # Fetch value for confirmation prompt
    orchestrator = ValuesOrchestrationService()
    fetch_result = orchestrator.get_value_by_id(value_id)

    if not fetch_result.success or not fetch_result.value:
        print(f"Error: {fetch_result.error or f'Value with ID {value_id} not found'}")
        sys.exit(1)

    value = fetch_result.value

    # Confirmation prompt (unless --force)
    if not force:
        response = input(f"Delete '{value.name}'? [y/N]: ")
        if response.lower() not in ['y', 'yes']:
            print("Delete cancelled")
            return

    # Delete using orchestration service
    result = orchestrator.delete_value(
        value_id=value_id,
        notes=f'CLI delete: {value.name}'
    )

    if result.success:
        print(f"✓ Deleted value: {value.name} (ID: {value_id})")
    else:
        print(f"Error: {result.error or 'Unknown error'}")
        sys.exit(1)


def main():
    """
    Main CLI entry point.

    Handles argument parsing and command routing.
    """
    parser = argparse.ArgumentParser(
        description='Ten Week Goal App - Track actions against goals',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s show-progress           # Show all goal progress
  %(prog)s show-progress -v        # Show progress with action details
        """
    )

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # show-progress command
    progress_parser = subparsers.add_parser(
        'show-progress',
        help='Display progress for all goals'
    )
    progress_parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed action listings'
    )

    # values command group
    values_parser = subparsers.add_parser(
        'values',
        help='Manage personal values'
    )
    values_subparsers = values_parser.add_subparsers(dest='values_command', help='Values commands')

    # values create-major command
    create_major_parser = values_subparsers.add_parser(
        'create-major',
        help='Create a major value (actionable, tracked regularly)'
    )
    create_major_parser.add_argument('name', help='Value name')
    create_major_parser.add_argument('description', help='What this value means')
    create_major_parser.add_argument('--domain', default='General', help='Life domain')
    create_major_parser.add_argument('--priority', type=int, default=5, help='Priority 1-100 (default: 5)')
    create_major_parser.add_argument('--guidance', required=True, help='How this value shows up in actions/goals')

    # values create-highest-order command
    create_highest_parser = values_subparsers.add_parser(
        'create-highest-order',
        help='Create a highest order value (philosophical, abstract)'
    )
    create_highest_parser.add_argument('name', help='Value name')
    create_highest_parser.add_argument('description', help='What this value means')
    create_highest_parser.add_argument('--domain', default='General', help='Life domain')
    create_highest_parser.add_argument('--priority', type=int, default=1, help='Priority 1-100 (default: 1)')

    # values create-general command
    create_general_parser = values_subparsers.add_parser(
        'create-general',
        help='Create a general value (aspirational)'
    )
    create_general_parser.add_argument('name', help='Value name')
    create_general_parser.add_argument('description', help='What this value means')
    create_general_parser.add_argument('--domain', default='General', help='Life domain')
    create_general_parser.add_argument('--priority', type=int, default=50, help='Priority 1-100 (default: 50)')

    # life-areas command group
    life_areas_parser = subparsers.add_parser(
        'life-areas',
        help='Manage life areas (organizational domains)'
    )
    life_areas_subparsers = life_areas_parser.add_subparsers(dest='life_areas_command', help='Life areas commands')

    # life-areas create command
    create_area_parser = life_areas_subparsers.add_parser(
        'create',
        help='Create a life area (organizational, not a value)'
    )
    create_area_parser.add_argument('name', help='Area name')
    create_area_parser.add_argument('description', help='What this area encompasses')
    create_area_parser.add_argument('--domain', default='General', help='Life domain')
    create_area_parser.add_argument('--priority', type=int, default=40, help='Priority 1-100 (default: 40)')

    # values list command
    list_parser = values_subparsers.add_parser(
        'list',
        help='List all personal values'
    )
    list_parser.add_argument(
        '--type',
        choices=['general', 'major', 'highest_order', 'life_area'],
        help='Filter by value type'
    )
    list_parser.add_argument(
        '--domain',
        help='Filter by life domain'
    )

    # values show command
    show_parser = values_subparsers.add_parser(
        'show',
        help='Show detailed information for a single value'
    )
    show_parser.add_argument(
        'id',
        type=int,
        help='Database ID of the value to display'
    )

    # values edit command
    edit_parser = values_subparsers.add_parser(
        'edit',
        help='Update an existing value'
    )
    edit_parser.add_argument(
        'id',
        type=int,
        help='Database ID of the value to update'
    )
    edit_parser.add_argument(
        '--name',
        help='New name for the value'
    )
    edit_parser.add_argument(
        '--description',
        help='New description'
    )
    edit_parser.add_argument(
        '--domain',
        help='New life domain'
    )
    edit_parser.add_argument(
        '--priority',
        type=int,
        help='New priority level (1-100)'
    )
    edit_parser.add_argument(
        '--alignment-guidance',
        help='New alignment guidance (only for MajorValues)'
    )

    # values delete command
    delete_parser = values_subparsers.add_parser(
        'delete',
        help='Delete a value with confirmation'
    )
    delete_parser.add_argument(
        'id',
        type=int,
        help='Database ID of the value to delete'
    )
    delete_parser.add_argument(
        '--force',
        action='store_true',
        help='Skip confirmation prompt'
    )

    args = parser.parse_args()

    # Route to appropriate command
    if args.command == 'show-progress':
        show_progress(verbose=args.verbose)
    elif args.command == 'values':
        if args.values_command == 'create-major':
            values_create_major(
                name=args.name,
                description=args.description,
                domain=args.domain,
                priority=args.priority,
                alignment_guidance=args.guidance
            )
        elif args.values_command == 'create-highest-order':
            values_create_highest_order(
                name=args.name,
                description=args.description,
                domain=args.domain,
                priority=args.priority
            )
        elif args.values_command == 'create-general':
            values_create_general(
                name=args.name,
                description=args.description,
                domain=args.domain,
                priority=args.priority
            )
        elif args.values_command == 'list':
            values_list(
                value_type=args.type if hasattr(args, 'type') else None,
                domain=args.domain if hasattr(args, 'domain') else None
            )
        elif args.values_command == 'show':
            values_show(value_id=args.id)
        elif args.values_command == 'edit':
            values_edit(
                value_id=args.id,
                name=args.name if hasattr(args, 'name') else None,
                description=args.description if hasattr(args, 'description') else None,
                domain=args.domain if hasattr(args, 'domain') else None,
                priority=args.priority if hasattr(args, 'priority') else None,
                alignment_guidance=args.alignment_guidance if hasattr(args, 'alignment_guidance') else None
            )
        elif args.values_command == 'delete':
            values_delete(value_id=args.id, force=args.force)
        else:
            values_parser.print_help()
            sys.exit(1)
    elif args.command == 'life-areas':
        if args.life_areas_command == 'create':
            life_areas_create(
                name=args.name,
                description=args.description,
                domain=args.domain,
                priority=args.priority
            )
        else:
            life_areas_parser.print_help()
            sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()


