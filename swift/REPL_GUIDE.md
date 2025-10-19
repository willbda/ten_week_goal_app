# Swift REPL Quick-Start Guide
## Your Flask-style Rapid Feedback Loop

This guide shows you how to get immediate feedback while developing Swift code, similar to how you'd spin up a Flask app or use Python's interactive shell.

## Three Ways to Explore Your Code

### 1. **Swift REPL** (Interactive Shell)
Like Python's `>>>` prompt, but with compiled Swift code.

```bash
# Start basic REPL
swift

# Now you can:
import Foundation
let date = Date()
print(date)

# Exit with
:quit
# or Ctrl+D
```

**To use your own code in REPL:**
```bash
# 1. Build your package first
swift build

# 2. Start REPL and import your module
swift
# >>> import Categoriae
# >>> let action = Action(commonName: "Test action")
# >>> action.isValid()
# true
```

### 2. **Demo App** (Visual Feedback)
Like running Flask, but with a native Mac window.

```bash
# Build and run the demo app
swift run TenWeekGoalDemo

# The app will open in a window where you can:
# - See Actions displayed
# - Add new Actions with the form
# - Watch validation in real-time
# - Delete actions by swiping
```

**Quick iteration cycle:**
1. Edit code in Categoriae/
2. `swift run TenWeekGoalDemo`
3. See changes immediately in the window
4. Repeat

### 3. **Tests** (Automated Verification)
Like pytest, but with Swift.

```bash
# Run all tests
swift test

# Run specific test
swift test --filter ActionTests

# Verbose output
swift test --verbose
```

## Your Rapid Development Workflow

This mirrors your Python/Flask workflow:

### **Python/Flask Pattern:**
```bash
# 1. Edit code
vim mymodule.py

# 2. Run Flask
python run_flask.py

# 3. Open browser, test endpoint
curl http://localhost:5001/api/actions

# 4. See results
```

### **Swift/Demo Pattern:**
```bash
# 1. Edit code
vim Sources/Categoriae/Action.swift

# 2. Run Demo
swift run TenWeekGoalDemo

# 3. Open window appears automatically
# 4. Interact with UI, see results immediately
```

## REPL Cheat Sheet

### Common REPL Commands
```swift
// Import modules
import Foundation
import Categoriae

// Create instances
let action = Action(commonName: "Morning run")
action.measurementUnitsByAmount = ["distance_miles": 3.2]

// Check values
print(action.commonName)
print(action.isValid())

// Test methods
action.durationMinutes = 25.0
print(action)

// Multi-line code (paste this whole block)
var testAction = Action(
    commonName: "Test",
    measurementUnitsByAmount: ["reps": 10.0]
)
testAction.isValid()
```

### REPL Special Commands
```
:help       - Show help
:quit       - Exit REPL
:type var   - Show type of variable
```

## When to Use Each Tool

| Tool | Best For | Example |
|------|----------|---------|
| **REPL** | Quick experiments, testing small pieces | "Does this validation work?" |
| **Demo App** | Visual feedback, UI testing | "How does this look?" |
| **Tests** | Automated verification, regression testing | "Did I break anything?" |

## Example: Adding a New Feature

Let's say you want to add a `category` field to Action:

### Step 1: REPL Exploration
```bash
swift
# >>> import Foundation
# >>> // Test what type you want
# >>> let category: String? = "Exercise"
# >>> category?.isEmpty
# false
```

### Step 2: Add to Action.swift
```swift
class Action: PersistableEntity {
    var category: String?
    // ... rest of code
}
```

### Step 3: Test in REPL
```bash
swift build
swift
# >>> import Categoriae
# >>> var action = Action(commonName: "Run")
# >>> action.category = "Exercise"
# >>> print(action.category ?? "none")
# Exercise
```

### Step 4: See in Demo
```bash
swift run TenWeekGoalDemo
# Window opens - add action with category
```

### Step 5: Write Test
```swift
func testActionWithCategory() {
    var action = Action(commonName: "Run")
    action.category = "Exercise"
    XCTAssertEqual(action.category, "Exercise")
}
```

### Step 6: Verify
```bash
swift test
```

## Pro Tips

### 1. **Keep a REPL Terminal Open**
Just like you'd keep a Flask server running, keep a terminal with REPL ready:
```bash
# Terminal 1: REPL for experiments
swift

# Terminal 2: Demo app when you need visuals
swift run TenWeekGoalDemo

# Terminal 3: Tests for verification
swift test --filter ActionTests
```

### 2. **Use Print Debugging**
In your code, add prints temporarily:
```swift
func isValid() -> Bool {
    print("DEBUG: Validating action - \(commonName)")
    // ... validation code
}
```

Then run demo or tests to see output.

### 3. **Incremental Building**
Swift only rebuilds what changed:
```bash
swift build    # First build: slow
# ... edit one file ...
swift build    # Subsequent: fast!
```

### 4. **File Watcher Pattern** (Advanced)
```bash
# Watch for changes and auto-test
# Install: brew install fswatch (if you want this)
fswatch -o Sources/ | xargs -n1 -I{} swift test
```

## Common REPL Issues & Fixes

### Problem: "No such module 'Categoriae'"
**Fix:** Build first!
```bash
swift build
swift  # Now import works
```

### Problem: Changes not showing up
**Fix:** Exit REPL, rebuild, restart
```bash
:quit
swift build
swift
```

### Problem: REPL freezes
**Fix:** Ctrl+C to interrupt, Ctrl+D to exit

## Next Steps

Once you're comfortable with this workflow, you can:

1. **Add more domain models** (Goal, Value) and test in REPL
2. **Build a CLI** (like your Python CLI) for scripting
3. **Add SQLite** and test database operations in REPL
4. **Create more sophisticated UI** in the Demo app

---

**Remember:** This is YOUR exploration environment. The REPL and Demo app are like your local Flask server—they're for rapid iteration and learning, not production. Use them liberally!
