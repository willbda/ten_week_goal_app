# Ten Week Goal App - Web Interface

A Flask-based web UI for the Ten Week Goal App, demonstrating how the **same business logic** used by the CLI can power a web interface.

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements_web.txt
```

### 2. Run the Web Server

```bash
python interfaces/web_app.py
```

### 3. Open Browser

Visit: **http://localhost:5000**

---

## Features

### Dashboard View (`/`)
- Progress overview for all goals
- Color-coded progress bars (red → yellow → green)
- Completion status indicators
- Summary statistics
- Timeline information

### Goal Detail View (`/goal/<id>`)
- Large circular progress indicator
- Detailed statistics (current, target, remaining)
- Complete list of matching actions
- Contribution amounts and confidence scores

### JSON API (`/api/progress`)
- Machine-readable progress data
- Useful for integrations or scripting
- Same calculations as dashboard

---

## Architecture Highlights

### Same Business Logic as CLI

Both interfaces use **identical** business logic:

**CLI** (cli.py):
```python
all_progress = aggregate_all_goals(goals, all_matches)
_display_progress_report(all_progress, verbose)
```

**Web** (web_app.py):
```python
all_progress = aggregate_all_goals(goals, all_matches)
return render_template('progress.html', all_progress=all_progress)
```

### Layer Separation

```
┌─────────────────────────────────────┐
│  Presentation Layer                 │
│  - CLI: formatters.py               │
│  - Web: Jinja2 templates + CSS      │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Business Logic (ethica/)           │
│  - progress_aggregation.py          │
│  - progress_matching.py             │
│  (Same for CLI and Web)             │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Storage Layer (rhetorica/)         │
│  - GoalStorageService               │
│  - ActionStorageService             │
│  (Same for CLI and Web)             │
└─────────────────────────────────────┘
```

### Benefits

1. **No Duplication**: Progress calculations defined once
2. **Consistency**: CLI and web always show same results
3. **Testability**: Business logic tested independently
4. **Maintainability**: Change calculation in one place

---

## File Structure

```
interfaces/
├── web_app.py                 # Flask application
├── cli.py                     # CLI application (uses same logic)
│
├── templates/                 # Jinja2 HTML templates
│   ├── base.html             # Base layout
│   ├── progress.html         # Dashboard view
│   ├── goal_detail.html      # Detail view
│   └── error.html            # Error page
│
└── static/
    └── css/
        └── style.css         # Styling
```

---

## Routes

| Route | Method | Description |
|-------|--------|-------------|
| `/` | GET | Dashboard - shows all goals |
| `/goal/<id>` | GET | Detail view for specific goal |
| `/api/progress` | GET | JSON API - all progress data |

---

## Development

### Debug Mode

The server runs in debug mode by default:
- Auto-reloads on code changes
- Detailed error pages
- Interactive debugger

### Production Deployment

For production, use a WSGI server like Gunicorn:

```bash
pip install gunicorn
gunicorn interfaces.web_app:app -b 0.0.0.0:8000
```

---

## Customization

### Change Port

Edit `web_app.py`:
```python
app.run(debug=True, port=8080)  # Use port 8080
```

### Add New Route

```python
@app.route('/my-route')
def my_view():
    # Use same business logic
    goals, actions = _fetch_goals_and_actions()
    all_matches = infer_matches(actions, goals)
    all_progress = aggregate_all_goals(goals, all_matches)

    # Return custom template
    return render_template('my_template.html', progress=all_progress)
```

### Customize Styling

Edit `static/css/style.css`:
```css
:root {
    --primary: #4CAF50;  /* Change primary color */
    --secondary: #2196F3;
}
```

---

## API Usage

### Get Progress Data as JSON

```bash
curl http://localhost:5000/api/progress
```

Response:
```json
{
  "summary": {
    "total_goals": 8,
    "complete_goals": 3,
    "in_progress_goals": 5,
    "avg_completion_percent": 67.5,
    "total_actions_matched": 150
  },
  "goals": [
    {
      "id": 1,
      "description": "Run 120km",
      "total_progress": 102.5,
      "target": 120.0,
      "percent": 85.4,
      "is_complete": false,
      "matching_actions_count": 15,
      "unit": "km"
    }
  ]
}
```

---

## Key Insight: Reusability

This web interface demonstrates **why** separation of concerns matters:

**Without SOC** (old approach):
- CLI calculates progress inline
- Web UI duplicates calculation logic
- Two definitions of "progress" → drift and bugs

**With SOC** (current approach):
- Business logic in `ethica/progress_aggregation.py`
- CLI uses it
- Web UI uses it
- API uses it
- **One definition, zero drift**

---

## Next Steps

1. **Add Authentication**: User login/sessions
2. **Add Forms**: Create/edit goals through web UI
3. **Add Charts**: Visualize progress over time
4. **Add Filters**: Filter by complete/incomplete, date range
5. **Add Export**: Download progress as PDF/CSV

---

## Troubleshooting

### Port Already in Use
```bash
# Change port in web_app.py or kill existing process
lsof -ti:5000 | xargs kill
```

### Template Not Found
```bash
# Verify templates directory exists
ls interfaces/templates/
```

### Static Files Not Loading
```bash
# Verify static directory exists
ls interfaces/static/css/
```

---

**Built with clean architecture principles**
Same business logic powers CLI, web UI, and API.
