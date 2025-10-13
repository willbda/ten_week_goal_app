"""
Progress bar widget using Canvas for custom rendering.

Mirrors web progress bar with color coding.

Written by Claude Code on 2025-10-13
"""

import tkinter as tk


class ProgressBar(tk.Canvas):
    """
    Custom progress bar widget.

    Color-coded based on progress percentage:
    - < 25%: Red
    - 25-50%: Orange
    - 50-75%: Yellow
    - 75-100%: Light green
    - 100%+: Dark green

    Uses Canvas drawing primitives to render a filled rectangle
    with percentage text overlay.
    """

    def __init__(self, parent, percent, width=400, height=25):
        """
        Initialize progress bar.

        Args:
            parent: Parent widget
            percent: Progress percentage (0-100+, values >100 are clamped for display)
            width: Bar width in pixels (default 400)
            height: Bar height in pixels (default 25)
        """
        super().__init__(parent, width=width, height=height, bg='white')

        self.width = width
        self.height = height
        self.actual_percent = percent  # Store actual value (may be >100)
        self.percent = min(percent, 100)  # Clamp to 100 for display

        self.draw_bar()

    def draw_bar(self):
        """Draw the progress bar with background, fill, and text."""
        # Background (empty portion)
        self.create_rectangle(
            0, 0, self.width, self.height,
            fill='#f0f0f0',
            outline='#ccc'
        )

        # Filled portion
        filled_width = int(self.width * (self.percent / 100))

        if filled_width > 0:
            fill_color = self._get_color()
            self.create_rectangle(
                0, 0, filled_width, self.height,
                fill=fill_color,
                outline=''
            )

        # Percentage text (centered)
        # Show actual percentage even if >100
        display_text = f"{self.actual_percent:.1f}%"
        self.create_text(
            self.width / 2, self.height / 2,
            text=display_text,
            font=('Arial', 10, 'bold')
        )

    def _get_color(self):
        """
        Get color based on progress percentage.

        Returns:
            str: Hex color code
        """
        if self.actual_percent >= 100:
            return '#2e7d32'  # Dark green
        elif self.actual_percent >= 75:
            return '#66bb6a'  # Light green
        elif self.actual_percent >= 50:
            return '#fdd835'  # Yellow
        elif self.actual_percent >= 25:
            return '#fb8c00'  # Orange
        else:
            return '#e53935'  # Red
