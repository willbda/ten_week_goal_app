"""
REFACTORED Command-line interface for Ten Week Goal App.

This is a STUB showing proper separation of concerns.

Written by Claude Code on 2025-10-12
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals
from interfaces.cli.cli_formatters import (
    render_section_header,
    render_goal_header,
    render_progress_metrics,
    render_timeline,
    render_action_list,
    render_summary_stats
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

    args = parser.parse_args()

    # Route to appropriate command
    if args.command == 'show-progress':
        show_progress(verbose=args.verbose)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()


# ===== ARCHITECTURAL COMPARISON =====
#
# OLD cli.py (100+ lines in show_progress):
# - Lines 82-91: Business logic (calculate totals, percentages)
# - Lines 93-101: Formatting (progress bar rendering)
# - Lines 103-116: More formatting (date ranges, completion status)
# - Lines 119-128: Yet more formatting (action lists)
# - Mixed concerns, hard to test, duplicates business rules
#
# NEW cli_refactored.py (40 lines in show_progress):
# - Pure orchestration: fetch → calculate → display
# - Business logic: ethica/progress_aggregation.py
# - Formatting: interfaces/formatters.py
# - Config: interfaces/cli_config.py
# - Each concern testable in isolation
# - Reusable across interfaces (CLI, web, API)
#
# ===== BENEFITS =====
#
# 1. **Testability**: Each layer tests independently
#    - test_progress_aggregation.py: Tests calculations
#    - test_cli_formatters.py: Tests formatting
#    - test_cli.py: Tests orchestration (future)
#
# 2. **Reusability**: Web UI can use same business logic
#    ```python
#    # In web controller:
#    from ethica.progress_aggregation import aggregate_all_goals
#    progress_data = aggregate_all_goals(goals, matches)
#    return render_template('progress.html', progress=progress_data)
#    ```
#
# 3. **Maintainability**: Change bar width in one place
#    - Edit interfaces/cli_config.py: progress_bar_width = 60
#    - All progress bars update automatically
#
# 4. **Consistency**: "Progress percentage" defined once
#    - ethica/progress_aggregation.py defines (total/target)*100
#    - CLI, web UI, API all use same definition
#    - No drift between interfaces
#
# 5. **Professional**: Follows Clean Architecture principles
#    - Entities → Use Cases → Interface Adapters → Frameworks
#    - categoriae → ethica → rhetorica/interfaces → argparse/Flask
