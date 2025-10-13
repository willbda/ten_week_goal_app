"""
Tkinter desktop application for Ten Week Goal App.

Uses SAME business logic as CLI and web interfaces.
Zero duplication of calculations.

Architecture:
- Fetch data using rhetorica/storage_service.py
- Calculate progress using ethica/progress_aggregation.py
- Display using tkinter widgets

Implementation Status:
- Phase 1: ✓ Basic window with data loading
- Phase 2: ✓ Summary panel header with statistics
- Phase 3: ✓ Progress bar widget (used in Phase 4)
- Phase 4: TODO - Goal card widgets
- Phase 5: TODO - Scrollable list and buttons

Written by Claude Code on 2025-10-13
"""

import tkinter as tk
from tkinter import messagebox
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary
from config.logging_setup import get_logger
from interfaces.desktop.widgets.summary_panel import SummaryPanel

logger = get_logger(__name__)


class GoalTrackerApp:
    """
    Main application class for Ten Week Goal Tracker desktop app.

    This follows the EXACT SAME pattern as web_app.py:
    1. Fetch data (rhetorica)
    2. Calculate relationships (ethica)
    3. Calculate progress (ethica)
    4. Display (tkinter - to be implemented in Phase 2)
    """

    def __init__(self, root):
        """
        Initialize the application.

        Args:
            root: tk.Tk root window
        """
        self.root = root
        self.root.title("Ten Week Goal Tracker")
        self.root.geometry("1000x700")

        # Initialize data attributes
        self.goals = []
        self.actions = []
        self.all_matches = []
        self.all_progress = []
        self.summary = {}

        # Load data using same logic as web/CLI
        self.load_data()

        # Build UI (placeholder for Phase 2+)
        self.build_ui()

    def load_data(self):
        """
        Load and calculate progress data.

        This is IDENTICAL to web_app.py index() route (lines 52-66).
        Uses the same business logic orchestration:
        1. Fetch data from database
        2. Infer action-goal relationships
        3. Aggregate progress metrics
        4. Calculate summary statistics
        """
        try:
            logger.info("Loading data for desktop app...")

            # Step 1: Fetch data (rhetorica)
            goal_service = GoalStorageService()
            action_service = ActionStorageService()

            self.goals = goal_service.get_all()
            self.actions = action_service.get_all()

            logger.info(f"Loaded {len(self.goals)} goals and {len(self.actions)} actions")

            # Step 2: Calculate relationships (ethica)
            self.all_matches = infer_matches(
                self.actions,
                self.goals,
                require_period_match=False
            )

            logger.info(f"Found {len(self.all_matches)} action-goal matches")

            # Step 3: Calculate progress metrics (ethica)
            self.all_progress = aggregate_all_goals(self.goals, self.all_matches)

            # Step 4: Get summary statistics
            self.summary = get_progress_summary(self.all_progress)

            logger.info("Data loading complete")
            logger.info(f"Summary: {self.summary}")

        except Exception as e:
            logger.error(f"Error loading data: {e}", exc_info=True)
            messagebox.showerror(
                "Error",
                f"Failed to load data: {e}\n\nCheck logs for details."
            )
            self.root.quit()

    def build_ui(self):
        """
        Build the main UI.

        Phase 2: Header with summary stats using SummaryPanel widget.
        Phase 3+: Will add goal cards, progress bars, scrollable list, etc.
        """
        # Header with summary stats
        self.summary_panel = SummaryPanel(
            self.root,
            self.summary,
            len(self.actions),
            len(self.all_matches)
        )
        self.summary_panel.pack(fill=tk.X, padx=10, pady=10)

        # TODO: Phase 4 - Add scrollable goal list with goal cards
        # TODO: Phase 5 - Add button bar (Refresh, Exit)


def main():
    """
    Main entry point for desktop application.

    Creates tkinter root window and application instance,
    then starts the event loop.
    """
    logger.info("=" * 70)
    logger.info("Ten Week Goal App - Desktop Interface")
    logger.info("=" * 70)

    root = tk.Tk()
    app = GoalTrackerApp(root)

    logger.info("Application window created, starting event loop")
    root.mainloop()

    logger.info("Application closed")


if __name__ == '__main__':
    main()
