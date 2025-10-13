#!/usr/bin/env python3
"""
Command-line interface for Ten Week Goal App.

This interface layer orchestrates rhetorica (storage) and ethica (business logic)
to provide a user-facing CLI for goal tracking.

Written by Claude Code on 2025-10-12
Updated by Claude Code on 2025-10-12 - Fixed to use inference system
"""

import argparse
import sys
from pathlib import Path
from collections import defaultdict

# Standard path setup for project modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from config.logging_setup import get_logger

logger = get_logger(__name__)


def show_progress(verbose: bool = False):
    """
    Display progress for all goals with matching actions.

    This command orchestrates:
    - rhetorica: Retrieves goals and actions from storage
    - ethica: Uses inference system to match actions to goals (with actionability filtering)
    - Presentation: Formats and displays results

    Args:
        verbose: If True, show detailed action listings
    """
    try:
        # Initialize storage services
        goal_service = GoalStorageService()
        action_service = ActionStorageService()

        # Retrieve all goals and actions from storage
        goals = goal_service.get_all()
        actions = action_service.get_all()

    except Exception as e:
        print(f"Error accessing database: {e}")
        print("Make sure database is initialized. Run: from politica.database import init_db; init_db()")
        sys.exit(1)

    if not goals:
        print("No goals found. Add some goals first!")
        return

    # Use inference system to match actions to goals
    # This respects actionability hints and prevents false positives
    all_matches = infer_matches(actions, goals, require_period_match=False)

    # Group matches by goal
    matches_by_goal = defaultdict(list)
    for match in all_matches:
        matches_by_goal[match.goal].append(match)

    # Header
    print(f"\n{'='*70}")
    print(f"GOAL PROGRESS REPORT")
    print(f"{'='*70}\n")
    print(f"Total Goals: {len(goals)}")
    print(f"Total Actions: {len(actions)}")
    print(f"Total Matches: {len(all_matches)}\n")

    # Display progress for each goal
    for i, goal in enumerate(goals, 1):
        print(f"{i}. {goal.description}")
        print(f"   {'─'*66}")

        # Get matches for this goal
        goal_matches = matches_by_goal.get(goal, [])

        # Calculate total progress from matched contributions
        total_progress = sum(m.contribution for m in goal_matches if m.contribution)
        matching_actions = [m.action for m in goal_matches]

        # Display target and progress if measurable
        if goal.measurement_target is not None:
            target = goal.measurement_target
            progress_percent = (total_progress / target * 100) if target > 0 else 0
            remaining = target - total_progress
            is_complete = total_progress >= target

            print(f"   Target: {target} {goal.measurement_unit or 'units'}")
            print(f"   Progress: {total_progress:.1f} / {target:.1f} ({progress_percent:.1f}%)")
            print(f"   Remaining: {remaining:.1f} {goal.measurement_unit or 'units'}")

            # Visual progress bar
            bar_width = 40
            filled = int(bar_width * min(progress_percent / 100, 1.0))
            bar = '█' * filled + '░' * (bar_width - filled)
            print(f"   [{bar}]")

            if is_complete:
                print(f"   ✓ COMPLETE!")
        else:
            print(f"   Target: Not specified")
            print(f"   Matching actions: {len(matching_actions)}")

        # Show date range if exists
        if goal.start_date or goal.end_date:
            date_range = []
            if goal.start_date:
                date_range.append(f"from {goal.start_date.strftime('%Y-%m-%d')}")
            if goal.end_date:
                date_range.append(f"to {goal.end_date.strftime('%Y-%m-%d')}")
            print(f"   Timeline: {' '.join(date_range)}")

        # Verbose mode: show matching actions with their contributions
        if verbose and goal_matches:
            print(f"\n   Matching Actions ({len(goal_matches)}):")
            for match in goal_matches[:5]:  # Show first 5
                contribution = match.contribution if match.contribution else 0
                log_date = match.action.logtime.strftime('%Y-%m-%d') if match.action.logtime else 'N/A'
                confidence = f"{match.confidence:.0%}" if match.confidence else "N/A"
                print(f"     • {match.action.description[:50]}: {contribution} {goal.measurement_unit or 'units'} ({log_date}, conf: {confidence})")

            if len(goal_matches) > 5:
                print(f"     ... and {len(goal_matches) - 5} more")

        print()  # Blank line between goals

    print(f"{'='*70}\n")


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
