"""
Summary panel widget - displays statistics header.

Mirrors web dashboard summary stats.

Written by Claude Code on 2025-10-13
"""

import tkinter as tk
from tkinter import ttk


class SummaryPanel(ttk.Frame):
    """
    Header panel showing summary statistics.

    Displays: Total Goals | Complete | In Progress | Total Matches

    This mirrors the summary section from the web dashboard,
    showing key metrics at a glance.
    """

    def __init__(self, parent, summary, total_actions, total_matches):
        """
        Initialize summary panel.

        Args:
            parent: Parent widget
            summary: dict from get_progress_summary() with keys:
                     total_goals, complete_goals, in_progress_goals, etc.
            total_actions: Total number of actions (len(actions))
            total_matches: Total number of action-goal matches (len(all_matches))
        """
        super().__init__(parent, relief=tk.RIDGE, borderwidth=2)

        # Title
        title = ttk.Label(
            self,
            text="GOAL PROGRESS DASHBOARD",
            font=('Arial', 16, 'bold')
        )
        title.pack(pady=10)

        # Stats row
        stats_frame = ttk.Frame(self)
        stats_frame.pack(pady=5)

        # Create stat labels
        self._create_stat(stats_frame, "📊 Goals", summary['total_goals'], 0)
        self._create_stat(stats_frame, "✅ Complete", summary['complete_goals'], 1)
        self._create_stat(stats_frame, "🔄 In Progress", summary['in_progress_goals'], 2)
        self._create_stat(stats_frame, "📈 Matches", total_matches, 3)

    def _create_stat(self, parent, label, value, column):
        """
        Create a stat label with value.

        Args:
            parent: Parent frame
            label: Label text (e.g., "📊 Goals")
            value: Numeric value to display
            column: Grid column position
        """
        frame = ttk.Frame(parent)
        frame.grid(row=0, column=column, padx=20)

        ttk.Label(frame, text=label, font=('Arial', 10)).pack()
        ttk.Label(frame, text=str(value), font=('Arial', 14, 'bold')).pack()
