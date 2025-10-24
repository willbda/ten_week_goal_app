# LLM Playground

> Interactive testing environment for Foundation Models prompt engineering and experimentation

## Overview

The LLM Playground is a command-line tool for dynamically testing LLM prompts during development. It provides an interactive environment for:

- **Prompt Engineering**: Test different phrasings and structures
- **Tool Calling**: Verify Foundation Models tool integration
- **Response Analysis**: Measure quality and performance
- **Experimentation**: Compare variations and benchmark results

## Requirements

- **macOS 26.0 or later** (Foundation Models framework)
- **Swift 6.2**
- **Apple Intelligence** enabled on your system
- **Database initialized** with sample data (optional but recommended)

## Installation

The playground is built as part of the GoalTracker package:

```bash
cd swift/
swift build
```

## Running the Playground

### Quick Start

```bash
swift run LLMPlayground
```

### From Built Executable

```bash
# Build once
swift build

# Run the executable
.build/debug/LLMPlayground
```

## Features

### 1. Send Custom Prompt

Test your own prompts interactively:

```
Your choice: 1
Enter your prompt: What made July meaningful for me?
```

The playground will:
- Send your prompt to the LLM
- Display the response with timing
- Save to conversation history
- Handle errors gracefully

### 2. Use Example Prompts

Access curated example prompts organized by category:

**Categories:**
- **Reflective**: Thoughtful analysis and patterns (4 examples)
- **Analytical**: Specific calculations and breakdowns (4 examples)
- **Exploratory**: Relationship discovery and insights (4 examples)
- **Specific**: Direct data retrieval queries (4 examples)
- **Creative**: Unconventional and narrative approaches (4 examples)

**Example:**
```
Your choice: 2
  1. Reflective: July Reflection
  2. Reflective: Values Alignment
  3. Analytical: Goal Progress Analysis
  ...
Select a prompt (1-16):
```

### 3. View Conversation History

Review all prompts and responses from your current session:

```
Your choice: 3

Message 1 - 10/24/25, 2:30 PM
────────────────────────────────
👤 User:
   What made July meaningful for me?

🤖 Assistant:
   Looking at your July data, I see three key themes...
```

### 4. Test Tool Calling

Verify that specific tools are being called correctly:

**Available Tool Tests:**
- `GetGoals` - Search, type filtering, date ranges (3 tests)
- `GetActions` - Recent actions, search, measurements (3 tests)
- `GetTerms` - Current term, all terms (2 tests)
- `GetValues` - All values, by type, by domain (3 tests)
- Multi-tool queries (1 test)

**Example:**
```
Your choice: 4
  1. GetGoals - Search
  2. GetGoals - Type Filter
  3. GetActions - Recent
  ...
Select a tool test (1-12):
```

### 5. Clear Session

Start a fresh conversation session:

```
Your choice: 5
Clear current session? (y/n): y
✅ Session cleared. Starting fresh!
```

**Note:** This clears the LLM's memory but preserves database history.

### 6. Benchmark Example Prompts

Run multiple prompts and measure performance:

```
Your choice: 6

[1/6] July Reflection...
   ⏱️  2.34s

[2/6] Goal Progress Analysis...
   ⏱️  1.89s

...

BENCHMARK RESULTS
═══════════════════════════════════
Total time: 12.45s
Average:    2.08s
```

## Example Prompts Library

### Reflective Queries

Test prompts that encourage analysis and pattern recognition:

```swift
"What made July meaningful for me?"
"Looking at my values and goals, what patterns do you see?"
"How am I doing overall?"
"Can you help me reflect on my current ten-week term?"
```

### Analytical Queries

Test prompts that require specific calculations:

```swift
"Which of my goals have I made the most progress on?"
"What patterns do you see in when I take action?"
"Show me a breakdown of my goals by type"
"What's my overall completion rate?"
```

### Tool Testing Queries

Verify tool calling behavior:

```swift
// GetGoals with search
"Show me all goals that mention 'health' or 'fitness'"

// GetActions with date filter
"Show me actions from the last 7 days"

// Multi-tool query
"Compare my health goals with my health values"
```

## Understanding Responses

### Response Format

```
🤖 Response (2.34s):
────────────────────────────────
Looking at your July data, I can see three meaningful themes...

1. Health Progress: You logged 12 running actions...
2. Learning Growth: Your reading goal shows...
3. Relationship Building: Actions related to...
────────────────────────────────
```

### Error Handling

The playground provides detailed error information:

```
❌ Conversation Error: Context size exceeded
   Reason: Token limit reached (8192/8000)
   💡 Suggestion: Try clearing the session or using a shorter prompt
```

**Common Errors:**
- **Context size exceeded**: Session too long, clear it
- **Model unavailable**: Check Apple Intelligence settings
- **Database error**: Verify database initialization
- **Tool execution failed**: Check data exists in database

## Prompt Engineering Tips

### 1. Be Specific

❌ "Tell me about my stuff"
✅ "What goals did I make progress on in July?"

### 2. Use Time Ranges

❌ "Show me my actions"
✅ "Show me actions from the last 7 days"

### 3. Ask for Analysis

❌ "List my goals"
✅ "Which goals have I made the most progress on?"

### 4. Test Tool Calling

Start with simple queries that test one tool at a time, then build up to multi-tool queries.

### 5. Experiment with Phrasing

Use the benchmark feature to test different phrasings of the same intent:

```swift
// Option A: Direct
"What are my health goals?"

// Option B: Analytical
"Show me a breakdown of my health-related goals and my progress on each"

// Option C: Reflective
"Looking at my health goals, what patterns do you notice in my progress?"
```

## Advanced Usage

### Custom System Instructions

Modify `ConversationService.swift:47-69` to change the AI's personality and behavior.

### Adding New Example Prompts

Edit `PromptLibrary.swift` to add your own curated examples:

```swift
static let myCustomExamples: [PromptExample] = [
    PromptExample(
        category: "Custom",
        title: "My Test Prompt",
        prompt: "Your prompt text here",
        expectedTool: "getGoals"
    )
]
```

### Performance Tracking

The benchmark feature records:
- Response time per prompt
- Average response time
- Fastest/slowest queries

Use this to optimize prompt phrasing and identify bottlenecks.

## Architecture

### Components

```
LLMPlayground/
├── main.swift                  # Interactive CLI loop
├── PromptLibrary.swift         # Curated example prompts
├── PlaygroundHelpers.swift     # Utilities and analysis tools
└── README.md                   # This file
```

### Dependencies

```swift
import Foundation           // Swift standard library
import Database            // DatabaseManager
import BusinessLogic       // ConversationService, Tools
import Models              // Domain entities
```

### Flow

```
User Input → LLMPlayground
           → ConversationService
           → LanguageModelSession
           → Tool Calling (GetGoals, etc.)
           → Database Query
           → Response Formatting
           → Database History Save
           → Display to User
```

## Troubleshooting

### "Foundation Models is not available"

**Cause:** Running on macOS < 26.0 or Apple Intelligence not enabled

**Solution:**
1. Verify macOS version: System Settings → General → About
2. Enable Apple Intelligence: System Settings → Apple Intelligence & Siri
3. Restart your Mac after enabling

### "Failed to initialize: Database error"

**Cause:** Database not set up or schema missing

**Solution:**
```bash
# Initialize database
cd swift/
swift run GoalTrackerCLI

# Or from Swift:
let db = try await DatabaseManager()
```

### "No data returned from tools"

**Cause:** Database is empty (no goals, actions, etc.)

**Solution:** Add sample data:
```bash
# Using Python CLI (has more mature CRUD)
cd python/
python interfaces/cli/cli.py goal create "Test Goal" --target 100 --unit "pages"
python interfaces/cli/cli.py action create "Read 20 pages" --measurements '{"pages": 20}'
```

### Responses are slow (> 5 seconds)

**Causes:**
- Large conversation history (context size)
- Complex multi-tool queries
- Network issues (if using cloud models)

**Solutions:**
- Clear session regularly (option 5)
- Use specific queries instead of broad ones
- Check network connection

## Best Practices

### 1. Start Fresh for Each Test Session

Clear the session between major testing phases to avoid context pollution.

### 2. Test One Thing at a Time

When debugging tool calling, isolate one tool per test.

### 3. Keep Examples Organized

Add new prompts to the appropriate category in PromptLibrary.

### 4. Document Interesting Results

Use the conversation history feature to review successful prompts.

### 5. Benchmark Before Optimization

Run benchmarks before and after prompt changes to measure improvement.

## Future Enhancements

Potential additions to the playground:

- [ ] Export conversation history to JSON/Markdown
- [ ] Side-by-side prompt comparison
- [ ] Automatic tool detection and verification
- [ ] Response quality scoring
- [ ] Prompt template system
- [ ] Multi-session comparison
- [ ] Streaming response display
- [ ] Custom tool registration

## Contributing

To add new features to the playground:

1. Add new menu option in `main.swift:printMenu()`
2. Implement handler function (e.g., `myNewFeature()`)
3. Add switch case in `runInteractiveLoop()`
4. Update this README with documentation

## Related Documentation

- **ConversationService**: `/swift/Sources/BusinessLogic/LLM/ConversationService.swift`
- **Tools**: `/swift/Sources/BusinessLogic/LLM/Tools/`
- **Swift Roadmap**: `/swift/SWIFTROADMAP.md`
- **Architecture Guide**: `/swift/SWIFT_ARCHITECTURE_AND_ROADMAP.md`

## License

Part of the Ten Week Goal App project.

---

**Written by Claude Code on 2025-10-24**
