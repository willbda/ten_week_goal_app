# Tkinter Desktop App Implementation Plan

**Goal**: Create a native desktop app using Tkinter that mirrors the web interface functionality while maintaining clean architecture principles.

**Date**: 2025-10-13
**Estimated Time**: 4-6 hours for basic implementation

---

## Architecture Alignment

### Same Pattern as CLI and Web
```
Fetch Data (rhetorica) → Calculate Progress (ethica) → Display (Tkinter widgets)
```

**Key Principle**: The Tkinter app will use the **exact same business logic** as CLI and web. Zero duplication.

---

## Web Interface → Tkinter Mapping

### Web Dashboard (`/`) → Main Window

**Web Features to Replicate:**
1. ✅ Summary stats (total goals, complete, in progress, matches)
2. ✅ Grid/list of goals with progress cards
3. ✅ Progress bars with percentage
4. ✅ Completion status indicators
5. ✅ Timeline info (start/end dates)

**Tkinter Implementation:**
```
MainWindow (tk.Tk)
├── HeaderFrame (summary stats)
│   ├── Label: "8 Goals"
│   ├── Label: "3 Complete"
│   ├── Label: "5 In Progress"
│   └── Label: "150 Matches"
│
├── GoalListFrame (scrollable list)
│   └── For each goal:
│       └── GoalCard (LabelFrame)
│           ├── Title (Label)
│           ├── Progress info (Label: "102.5 / 120.0 km")
│           ├── ProgressBar (Canvas with colored rectangle)
│           ├── Percentage (Label: "85.4%")
│           ├── Status (Label: "✓ COMPLETE" or "In Progress")
│           └── Timeline (Label: "2025-04-12 → 2025-06-21")
│
└── ButtonFrame (actions)
    ├── Refresh Button
    └── Exit Button
```

---

## File Structure

```
interfaces/
├── desktop/
│   ├── __init__.py
│   ├── desktop_app.py           # Main application entry point
│   ├── main_window.py           # Main window class
│   ├── widgets/
│   │   ├── __init__.py
│   │   ├── goal_card.py         # Custom widget for goal display
│   │   ├── progress_bar.py      # Custom progress bar widget
│   │   └── summary_panel.py     # Header summary stats
│   └── styles.py                # Color constants and styling
│
└── desktop_README.md            # Usage documentation
```

---

## Implementation Phases

### Phase 1: Basic Window & Data Loading (1 hour)

**File**: `interfaces/desktop/desktop_app.py`

```python
"""
Tkinter desktop application for Ten Week Goal App.

Uses SAME business logic as CLI and web interfaces.
Zero duplication of calculations.

Written by Claude Code on 2025-10-13
"""

import tkinter as tk
from tkinter import ttk, messagebox
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from rhetorica.storage_service import GoalStorageService, ActionStorageService
from ethica.progress_matching import infer_matches
from ethica.progress_aggregation import aggregate_all_goals, get_progress_summary
from config.logging_setup import get_logger

logger = get_logger(__name__)


class GoalTrackerApp:
    """Main application class."""

    def __init__(self, root):
        self.root = root
        self.root.title("Ten Week Goal Tracker")
        self.root.geometry("1000x700")

        # Load data using same logic as web/CLI
        self.load_data()

        # Build UI
        self.build_ui()

    def load_data(self):
        """Load and calculate progress data (same as web_app.py)."""
        try:
            # Step 1: Fetch data (rhetorica)
            goal_service = GoalStorageService()
            action_service = ActionStorageService()

            self.goals = goal_service.get_all()
            self.actions = action_service.get_all()

            # Step 2: Calculate relationships (ethica)
            self.all_matches = infer_matches(
                self.actions,
                self.goals,
                require_period_match=False
            )

            # Step 3: Calculate progress (ethica)
            self.all_progress = aggregate_all_goals(self.goals, self.all_matches)

            # Step 4: Get summary stats
            self.summary = get_progress_summary(self.all_progress)

        except Exception as e:
            logger.error(f"Error loading data: {e}")
            messagebox.showerror("Error", f"Failed to load data: {e}")
            self.root.quit()

    def build_ui(self):
        """Build the main UI."""
        # TODO: Implement in Phase 2
        pass


def main():
    """Main entry point."""
    root = tk.Tk()
    app = GoalTrackerApp(root)
    root.mainloop()


if __name__ == '__main__':
    main()
```

**Test**: Window opens, data loads successfully (even if UI is empty)

---

### Phase 2: Summary Header (30 minutes)

**File**: `interfaces/desktop/widgets/summary_panel.py`

```python
"""
Summary panel widget - displays statistics header.

Mirrors web dashboard summary stats.
"""

import tkinter as tk
from tkinter import ttk


class SummaryPanel(ttk.Frame):
    """
    Header panel showing summary statistics.

    Displays: Total Goals | Complete | In Progress | Total Matches
    """

    def __init__(self, parent, summary, total_actions, total_matches):
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
        """Create a stat label with value."""
        frame = ttk.Frame(parent)
        frame.grid(row=0, column=column, padx=20)

        ttk.Label(frame, text=label, font=('Arial', 10)).pack()
        ttk.Label(frame, text=str(value), font=('Arial', 14, 'bold')).pack()
```

**Integration in main_window.py:**
```python
def build_ui(self):
    # Header with summary stats
    self.summary_panel = SummaryPanel(
        self.root,
        self.summary,
        len(self.actions),
        len(self.all_matches)
    )
    self.summary_panel.pack(fill=tk.X, padx=10, pady=10)
```

**Test**: Header displays correct statistics

---

### Phase 3: Progress Bar Widget (45 minutes)

**File**: `interfaces/desktop/widgets/progress_bar.py`

```python
"""
Progress bar widget using Canvas for custom rendering.

Mirrors web progress bar with color coding.
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
    """

    def __init__(self, parent, percent, width=400, height=25):
        super().__init__(parent, width=width, height=height, bg='white')

        self.width = width
        self.height = height
        self.percent = min(percent, 100)  # Clamp to 100 for display

        self.draw_bar()

    def draw_bar(self):
        """Draw the progress bar."""
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

        # Percentage text
        self.create_text(
            self.width / 2, self.height / 2,
            text=f"{self.percent:.1f}%",
            font=('Arial', 10, 'bold')
        )

    def _get_color(self):
        """Get color based on progress percentage."""
        if self.percent >= 100:
            return '#2e7d32'  # Dark green
        elif self.percent >= 75:
            return '#66bb6a'  # Light green
        elif self.percent >= 50:
            return '#fdd835'  # Yellow
        elif self.percent >= 25:
            return '#fb8c00'  # Orange
        else:
            return '#e53935'  # Red
```

**Test**: Progress bars render with correct widths and colors

---

### Phase 4: Goal Card Widget (1 hour)

**File**: `interfaces/desktop/widgets/goal_card.py`

```python
"""
Goal card widget - displays individual goal progress.

Mirrors web goal card layout.
"""

import tkinter as tk
from tkinter import ttk
from .progress_bar import ProgressBar


class GoalCard(ttk.LabelFrame):
    """
    Widget displaying single goal's progress.

    Shows:
    - Goal description (title)
    - Target and current progress
    - Progress bar
    - Completion status
    - Timeline (if dates exist)
    """

    def __init__(self, parent, progress):
        """
        Initialize goal card.

        Args:
            parent: Parent widget
            progress: GoalProgress object from ethica/progress_aggregation.py
        """
        super().__init__(
            parent,
            text=progress.goal.description,
            font=('Arial', 11, 'bold'),
            relief=tk.RIDGE,
            borderwidth=2
        )

        self.progress = progress
        self.pack(fill=tk.X, padx=10, pady=5)

        self._build_content()

    def _build_content(self):
        """Build card content."""
        # Progress info
        if self.progress.target > 0:
            self._build_with_target()
        else:
            self._build_without_target()

        # Timeline (if exists)
        if self.progress.goal.start_date or self.progress.goal.end_date:
            self._build_timeline()

    def _build_with_target(self):
        """Build content for goal with target."""
        # Progress text: "102.5 / 120.0 km"
        progress_text = (
            f"Progress: {self.progress.total_progress:.1f} / "
            f"{self.progress.target:.1f} {self.progress.unit}"
        )
        ttk.Label(self, text=progress_text).pack(anchor=tk.W, padx=10, pady=2)

        # Remaining text: "Remaining: 17.5 km"
        remaining_text = f"Remaining: {self.progress.remaining:.1f} {self.progress.unit}"
        ttk.Label(self, text=remaining_text).pack(anchor=tk.W, padx=10, pady=2)

        # Progress bar
        bar_frame = ttk.Frame(self)
        bar_frame.pack(fill=tk.X, padx=10, pady=5)

        ProgressBar(bar_frame, self.progress.percent, width=600).pack()

        # Status indicator
        if self.progress.is_complete:
            status = "✓ COMPLETE!"
            color = 'green'
        elif self.progress.is_overachieved:
            status = "⚡ EXCEEDED TARGET!"
            color = 'blue'
        else:
            status = "In Progress"
            color = 'orange'

        status_label = ttk.Label(
            self,
            text=status,
            font=('Arial', 10, 'bold'),
            foreground=color
        )
        status_label.pack(anchor=tk.W, padx=10, pady=2)

    def _build_without_target(self):
        """Build content for goal without target."""
        ttk.Label(
            self,
            text="No specific target set"
        ).pack(anchor=tk.W, padx=10, pady=2)

        ttk.Label(
            self,
            text=f"Matching actions: {self.progress.matching_actions_count}"
        ).pack(anchor=tk.W, padx=10, pady=2)

    def _build_timeline(self):
        """Build timeline display."""
        parts = []
        if self.progress.goal.start_date:
            parts.append(self.progress.goal.start_date.strftime('%Y-%m-%d'))
        if self.progress.goal.end_date:
            if parts:
                parts.append('→')
            parts.append(self.progress.goal.end_date.strftime('%Y-%m-%d'))

        timeline_text = f"📅 {' '.join(parts)}"
        ttk.Label(
            self,
            text=timeline_text,
            foreground='gray'
        ).pack(anchor=tk.W, padx=10, pady=2)
```

**Test**: Goal cards display with all information correctly

---

### Phase 5: Scrollable Goal List (45 minutes)

**File**: `interfaces/desktop/main_window.py` (updated)

```python
def build_ui(self):
    """Build the main UI."""
    # Header with summary stats
    self.summary_panel = SummaryPanel(
        self.root,
        self.summary,
        len(self.actions),
        len(self.all_matches)
    )
    self.summary_panel.pack(fill=tk.X, padx=10, pady=10)

    # Scrollable goal list
    self._build_goal_list()

    # Bottom buttons
    self._build_button_bar()

def _build_goal_list(self):
    """Build scrollable list of goal cards."""
    # Container frame
    container = ttk.Frame(self.root)
    container.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

    # Canvas for scrolling
    canvas = tk.Canvas(container)
    scrollbar = ttk.Scrollbar(container, orient=tk.VERTICAL, command=canvas.yview)
    scrollable_frame = ttk.Frame(canvas)

    scrollable_frame.bind(
        "<Configure>",
        lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
    )

    canvas.create_window((0, 0), window=scrollable_frame, anchor=tk.NW)
    canvas.configure(yscrollcommand=scrollbar.set)

    # Add goal cards
    for progress in self.all_progress:
        GoalCard(scrollable_frame, progress)

    # Pack scrolling components
    canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

def _build_button_bar(self):
    """Build bottom button bar."""
    button_frame = ttk.Frame(self.root)
    button_frame.pack(fill=tk.X, padx=10, pady=10)

    ttk.Button(
        button_frame,
        text="Refresh",
        command=self.refresh_data
    ).pack(side=tk.LEFT, padx=5)

    ttk.Button(
        button_frame,
        text="Exit",
        command=self.root.quit
    ).pack(side=tk.RIGHT, padx=5)

def refresh_data(self):
    """Reload data and rebuild UI."""
    self.load_data()
    # Rebuild UI (clear and recreate widgets)
    for widget in self.root.winfo_children():
        widget.destroy()
    self.build_ui()
```

**Test**: List scrolls, displays all goals, refresh works

---

### Phase 6: Styling & Polish (30 minutes)

**File**: `interfaces/desktop/styles.py`

```python
"""
Styling constants for Tkinter desktop app.

Keeps visual styling consistent and maintainable.
"""

# Colors
COLORS = {
    'bg_main': '#f5f5f5',
    'bg_card': '#ffffff',
    'border': '#e0e0e0',

    'text_primary': '#212121',
    'text_secondary': '#757575',

    'status_complete': '#2e7d32',
    'status_exceeded': '#1565c0',
    'status_progress': '#f57c00',

    'progress_excellent': '#2e7d32',  # 100%+
    'progress_good': '#66bb6a',       # 75-100%
    'progress_okay': '#fdd835',       # 50-75%
    'progress_behind': '#fb8c00',     # 25-50%
    'progress_minimal': '#e53935',    # <25%
}

# Fonts
FONTS = {
    'title': ('Arial', 16, 'bold'),
    'header': ('Arial', 12, 'bold'),
    'body': ('Arial', 10),
    'small': ('Arial', 9),
}

# Sizes
SIZES = {
    'padding': 10,
    'card_spacing': 5,
    'progress_bar_width': 600,
    'progress_bar_height': 25,
}
```

**Apply styles**: Update widgets to use color/font constants

**Test**: UI looks polished and consistent

---

## Testing Strategy

### Unit Tests (Optional but Recommended)

**File**: `tests/test_desktop_widgets.py`

```python
"""
Tests for Tkinter desktop widgets.

These tests verify widget creation but don't test visual appearance.
"""

import pytest
import tkinter as tk
from interfaces.desktop.widgets.progress_bar import ProgressBar
from interfaces.desktop.widgets.goal_card import GoalCard
from categoriae.goals import Goal
from ethica.progress_aggregation import GoalProgress


def test_progress_bar_creation():
    """Test progress bar widget creates without error."""
    root = tk.Tk()
    bar = ProgressBar(root, percent=50)
    assert bar.percent == 50
    root.destroy()


def test_goal_card_with_target():
    """Test goal card displays goal with target."""
    root = tk.Tk()

    goal = Goal(
        description="Test Goal",
        measurement_unit="km",
        measurement_target=100.0
    )

    progress = GoalProgress(
        goal=goal,
        matches=[],
        total_progress=50.0,
        target=100.0
    )

    card = GoalCard(root, progress)
    assert card.progress.percent == 50.0

    root.destroy()
```

### Manual Testing Checklist

- [ ] Window opens at correct size (1000x700)
- [ ] Summary stats display correctly
- [ ] All goals appear in list
- [ ] Progress bars render with correct widths
- [ ] Progress bars show correct colors
- [ ] Completion status indicators appear
- [ ] Timeline dates display (when present)
- [ ] List scrolls when goals exceed window height
- [ ] Refresh button reloads data
- [ ] Exit button closes application
- [ ] No crashes with empty database
- [ ] No crashes with goals without targets

---

## Comparison: Web vs Desktop

| Feature | Web (Flask) | Desktop (Tkinter) |
|---------|-------------|-------------------|
| Summary stats | ✅ Jinja template | ✅ SummaryPanel widget |
| Goal list | ✅ HTML grid | ✅ Scrollable Frame |
| Progress bars | ✅ CSS styled div | ✅ Canvas drawing |
| Status indicators | ✅ HTML spans | ✅ Colored Labels |
| Timeline | ✅ Template filter | ✅ strftime formatting |
| Refresh | ✅ Page reload | ✅ Refresh button |
| **Business Logic** | ✅ ethica/ | ✅ **SAME ethica/** |

---

## Future Enhancements (Not in Initial Scope)

### Phase 7+: Advanced Features
- [ ] Goal detail window (double-click goal card)
- [ ] Action list view in detail window
- [ ] Menu bar (File, View, Help)
- [ ] Keyboard shortcuts
- [ ] Export to PDF
- [ ] Settings/preferences
- [ ] System tray icon
- [ ] Auto-refresh timer

---

## Success Criteria

✅ **Minimal Viable Product:**
1. Shows all goals with progress
2. Progress bars render correctly
3. Uses same business logic as web/CLI
4. Can refresh data
5. Runs on Mac, Windows, Linux (Tkinter is cross-platform)

✅ **Architecture Compliance:**
1. No business logic in UI code
2. All calculations in ethica/
3. All data fetching in rhetorica/
4. UI code only creates widgets and displays data

✅ **Code Quality:**
1. Docstrings on all classes/methods
2. Clear separation into widget files
3. Consistent styling via constants
4. Error handling for data loading

---

## Time Estimates

| Phase | Task | Time |
|-------|------|------|
| 1 | Basic window & data loading | 1 hour |
| 2 | Summary header | 30 min |
| 3 | Progress bar widget | 45 min |
| 4 | Goal card widget | 1 hour |
| 5 | Scrollable list | 45 min |
| 6 | Styling & polish | 30 min |
| **Total** | | **~4.5 hours** |

**With testing and debugging: 5-6 hours**

---

## Next Steps

1. **Review this plan** - Does this match your vision?
2. **Decide on implementation approach**:
   - Build all phases sequentially
   - Build Phase 1-2 first to validate approach
   - Prototype just the progress bar widget first
3. **Start coding** - I can implement this plan step-by-step

What would you like to do? Start with Phase 1, or adjust the plan first?
