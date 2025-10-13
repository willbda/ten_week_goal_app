"""
Text User Interface (TUI) for Ten Week Goal App.

This demonstrates how the SAME business logic used by CLI and Web
can power a terminal-based interactive interface using Textual.

Architecture:
- Uses ethica/progress_aggregation.py for business logic (same as CLI/Web)
- Uses Textual framework for interactive terminal UI
- Thin controllers - just orchestration

To run:
    python interfaces/tui/tui_app.py

Or with textual dev mode (hot reload):
    textual run --dev interfaces/tui/tui_app.py

Written by Claude Code on 2025-10-13
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from textual.app import App, ComposeResult
from textual.containers import Container, ScrollableContainer
from textual.widgets import Header, Footer, Static, DataTable
from textual.binding import Binding

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary
from config.logging_setup import get_logger

logger = get_logger(__name__)


class ProgressDisplay(Static):
    """Widget to display goal progress summary statistics."""

    def __init__(self, summary: dict, total_actions: int, total_matches: int):
        """
        Initialize progress display widget.

        Args:
            summary: Summary statistics from get_progress_summary()
            total_actions: Total number of actions in database
            total_matches: Total number of action-goal matches
        """
        self.summary = summary
        self.total_actions = total_actions
        self.total_matches = total_matches
        super().__init__()

    def compose(self) -> ComposeResult:
        """Create child widgets."""
        yield Static(self._render_summary(), classes="summary-box")

    def _render_summary(self) -> str:
        """
        Render summary statistics as formatted text.

        Returns:
            Formatted summary string
        """
        complete = self.summary.get('complete_goals', 0)
        total = self.summary.get('total_goals', 0)
        avg_completion = self.summary.get('avg_completion_percent', 0)

        return f"""[b]Summary Statistics[/b]

Total Goals: {total}
Complete Goals: {complete}
Average Completion: {avg_completion:.1f}%

Total Actions: {self.total_actions}
Total Matches: {self.total_matches}
"""


class GoalsTable(Static):
    """Widget to display goals in a table format."""

    def __init__(self, progress_data):
        """
        Initialize goals table widget.

        Args:
            progress_data: List of GoalProgress objects
        """
        self.progress_data = progress_data
        super().__init__()

    def compose(self) -> ComposeResult:
        """Create the data table."""
        table = DataTable()
        table.add_column("ID", width=6)
        table.add_column("Goal", width=40)
        table.add_column("Progress", width=15)
        table.add_column("Percent", width=10)
        table.add_column("Status", width=10)

        # Populate table rows
        for progress in self.progress_data:
            goal_id = str(progress.goal.id) if progress.goal.id else "N/A"
            description = progress.goal.description[:37] + "..." if len(progress.goal.description) > 40 else progress.goal.description

            # Format progress
            if progress.target > 0:
                progress_str = f"{progress.total_progress:.1f}/{progress.target:.1f} {progress.unit}"
                percent_str = f"{progress.percent:.1f}%"
            else:
                progress_str = f"{progress.matching_actions_count} actions"
                percent_str = "N/A"

            # Status indicator
            if progress.is_complete:
                status = "✓ Done"
            elif progress.is_overachieved:
                status = "⚡ Over"
            else:
                status = "Active"

            table.add_row(goal_id, description, progress_str, percent_str, status)

        yield table


class TenWeekGoalApp(App):
    """
    Textual TUI application for Ten Week Goal tracking.

    This is IDENTICAL orchestration to CLI and Web:
    1. Fetch data (rhetorica)
    2. Calculate progress (ethica)
    3. Display (Textual widgets instead of print/HTML)
    """

    CSS = """
    Screen {
        background: $surface;
    }

    .summary-box {
        background: $panel;
        border: solid $primary;
        padding: 1 2;
        margin: 1 2;
    }

    DataTable {
        margin: 1 2;
        height: auto;
    }

    DataTable > .datatable--header {
        background: $primary;
        color: $text;
    }

    DataTable > .datatable--cursor {
        background: $secondary;
    }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit", show=True),
        Binding("r", "refresh", "Refresh", show=True),
    ]

    TITLE = "Ten Week Goal App - Progress Dashboard"

    def __init__(self):
        """Initialize the TUI application."""
        super().__init__()
        self.progress_data = []
        self.summary = {}
        self.total_actions = 0
        self.total_matches = 0

    def compose(self) -> ComposeResult:
        """
        Create child widgets.

        This is called once when app starts.
        """
        yield Header()
        yield Container(
            ProgressDisplay(self.summary, self.total_actions, self.total_matches),
            GoalsTable(self.progress_data),
            id="main-container"
        )
        yield Footer()

    def on_mount(self) -> None:
        """
        Called when app is mounted (after compose).

        This is where we load data - same pattern as CLI/Web.
        """
        self.load_data()

    def load_data(self):
        """
        Load and calculate goal progress data.

        This is IDENTICAL logic to CLI show_progress() and web index():
        1. Fetch data (rhetorica)
        2. Calculate relationships (ethica)
        3. Calculate progress metrics (ethica)
        4. Display (Textual widgets)
        """
        try:
            # Step 1: Fetch data (same as CLI/Web)
            goal_service = GoalStorageService()
            action_service = ActionStorageService()

            goals = goal_service.get_all()
            actions = action_service.get_all()

            if not goals:
                self.notify("No goals found. Add some goals first!", severity="warning")
                return

            # Step 2: Calculate relationships (same as CLI/Web)
            all_matches = infer_matches(actions, goals, require_period_match=False)

            # Step 3: Calculate progress metrics (same as CLI/Web)
            self.progress_data = aggregate_all_goals(goals, all_matches)

            # Step 4: Get summary stats
            self.summary = get_progress_summary(self.progress_data)
            self.total_actions = len(actions)
            self.total_matches = len(all_matches)

            # Refresh the display if already mounted
            if self.is_mounted:
                self.refresh_display()

        except Exception as e:
            logger.error(f"Error loading progress: {e}")
            self.notify(f"Error loading data: {e}", severity="error")

    def refresh_display(self):
        """Refresh the display with current data by replacing widgets."""
        try:
            # Query the container
            container = self.query_one("#main-container", Container)

            # Remove all children
            container.remove_children()

            # Mount new widgets
            container.mount(
                ProgressDisplay(self.summary, self.total_actions, self.total_matches),
                GoalsTable(self.progress_data)
            )
        except Exception as e:
            logger.error(f"Error refreshing display: {e}")
            # If container doesn't exist yet (initial mount), just return
            pass

    def action_refresh(self) -> None:
        """Action handler for refresh keybinding."""
        self.notify("Refreshing data...", severity="information")
        self.load_data()

    def action_quit(self) -> None:
        """Action handler for quit keybinding."""
        self.exit()


def main():
    """Entry point for TUI application."""
    app = TenWeekGoalApp()
    app.run()


if __name__ == '__main__':
    print("=" * 70)
    print("Ten Week Goal App - Text User Interface (TUI)")
    print("=" * 70)
    print("\nStarting TUI...")
    print("Controls:")
    print("  q: Quit")
    print("  r: Refresh data")
    print("\n")

    main()
