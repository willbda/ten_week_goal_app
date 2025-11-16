# Context

## problem



### Example 1
```
🤖 GoalCoachViewModel: Starting conversation...
🛠️  Registered 8 tools:
   - getGoals: Fetch the user's goals with full details including measures and value alignments
   - getValues: Fetch the user's personal values and life areas to understand what matters most to them
   - createGoal: Create a new goal after validating it doesn't duplicate existing goals
   - checkDuplicateGoal: Check if a goal title would duplicate an existing goal using semantic similarity
   - getMeasures: Fetch available measurement types that can be used for tracking goals and actions
   - getRecentActions: Fetch recent actions the user has taken, including measurements and goal 
contributions
   - getProgress: Analyze progress toward goals including completion percentages, trends, and velocity
   - analyzeAlignment: Analyze how well goals align with personal values, identify gaps, and detect 
conflicts
📝 System prompt: ~116 words (~232 tokens estimated)
✅ LLM session created successfully
💬 Assistant: 👋 Hi! I'm your goal coach. I can help you create meaningful goals that align with your 
values. What would you like to work on today?
It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.  If you are 
implementing the view's -layout method, you can call -[super layout] instead.  Break on void 
_NSDetectedLayoutRecursion(void) to debug.  This will be logged only once.  This may break in the future.
Unable to obtain a task name port right for pid 1016: (os/kern) failure (0x5)

================================================================================
📨 USER MESSAGE #2
================================================================================
could you tell me about my last goal
================================================================================
📊 Context estimate: 2 messages, ~42 tokens
🔄 Sending to LLM...
ViewBridge to RemoteViewService Terminated: Error Domain=com.apple.ViewBridge Code=18 "(null)" 
UserInfo={com.apple.ViewBridge.error.hint=this process disconnected remote view controller -- benign 
unless unexpected, com.apple.ViewBridge.error.description=NSViewBridgeErrorCanceled}

================================================================================
🤖 LLM RESPONSE
================================================================================
Content (140 chars):
Sure! Could you please provide me with the specific goal you'd like to review? If you'd prefer, I can 
analyze all your active goals for you.

Response type: Response<String>
Mirror dump:
▿ FoundationModels.LanguageModelSession.Response<Swift.String>
  - userPrompt: "could you tell me about my last goal"
  - duration: 4.109193541
  - feedbackAttachment: nil
  - content: "Sure! Could you please provide me with the specific goal you\'d like to review? If you\'d 
prefer, I can analyze all your active goals for you."
  ▿ rawContent: "Sure! Could you please provide me with the specific goal you'd like to review? If you'd 
prefer, I can analyze all your active goals for you."
    ▹ value: FoundationModels.GeneratedJSON
    - id: nil
  ▿ transcriptEntries: 1 element
    ▹ (Response) Sure! Could you please provide me with the specific goal you'd like to review? If you'd 
prefer, I can analyze all your active goals for you.
================================================================================


================================================================================
📨 USER MESSAGE #4
================================================================================
sure!
================================================================================
📊 Context estimate: 4 messages, ~78 tokens
🔄 Sending to LLM...

================================================================================
🤖 LLM RESPONSE
================================================================================
Content (521 chars):
Here's a summary of your last goal:

Goal Title: Introduction to Programming with JavaScript

Description: Spend 40 hours reading, watching instructional videos, and writing JS; avg 4 hours per week

Start Date: January 6, 2025

Target Date: March 17, 2025

Importance: 5

Urgency: 5

Metric Target: Hours with a target value of 40 hours

Value Alignment: Holistic Cultivation of Capacities with an alignment strength of 8

Let me know if there's anything specific you'd like to discuss or if you need further assistance!

Response type: Response<String>
Mirror dump:
▿ FoundationModels.LanguageModelSession.Response<Swift.String>
  - userPrompt: "sure!"
  - duration: 3.720594125
  - feedbackAttachment: nil
  - content: "Here\'s a summary of your last goal:\n\nGoal Title: Introduction to Programming with 
JavaScript\n\nDescription: Spend 40 hours reading, watching instructional videos, and writing JS; avg 4 
hours per week\n\nStart Date: January 6, 2025\n\nTarget Date: March 17, 2025\n\nImportance: 5\n\nUrgency:
 5\n\nMetric Target: Hours with a target value of 40 hours\n\nValue Alignment: Holistic Cultivation of 
Capacities with an alignment strength of 8\n\nLet me know if there\'s anything specific you\'d like to 
discuss or if you need further assistance!"
  ▿ rawContent: "Here's a summary of your last goal:\n\nGoal Title: Introduction to Programming with 
JavaScript\n\nDescription: Spend 40 hours reading, watching instructional videos, and writing JS; avg 4 
hours per week\n\nStart Date: January 6, 2025\n\nTarget Date: March 17, 2025\n\nImportance: 5\n\nUrgency:
 5\n\nMetric Target: Hours with a target value of 40 hours\n\nValue Alignment: Holistic Cultivation of 
Capacities with an alignment strength of 8\n\nLet me know if there's anything specific you'd like to 
discuss or if you need further assistance!"
    ▹ value: FoundationModels.GeneratedJSON
    - id: nil
  ▿ transcriptEntries: 4 elements
    ▹ (Response) null
    ▹ (ToolCalls) getGoals: {"limit": 1, "includeArchived": true}
    ▹ (ToolOutput getGoals) {"goals": [{"id": "198E669F-E946-409A-A794-DDC003440171", "title": 
"Introduction to Programming with JavaScript", "description": "spend 40 hours reading, watching 
instructional videos, and writing JS; avg 4 hours per week", "startDate": "2025-01-06T00:00:00Z", 
"targetDate": "2025-03-17T00:00:00Z", "importance": 5, "urgency": 5, "metricTargets": [{"measureName": 
"Hours", "targetValue": 40, "unit": "hours"}], "alignedValues": [{"valueName": "Holistic Cultivation of 
Capacities", "alignmentStrength": 8}]}], "totalCount": 1}
    ▹ (Response) Here's a summary of your last goal:

Goal Title: Introduction to Programming with JavaScript

Description: Spend 40 hours reading, watching instructional videos, and writing JS; avg 4 hours per week

Start Date: January 6, 2025

Target Date: March 17, 2025

Importance: 5

Urgency: 5

Metric Target: Hours with a target value of 40 hours

Value Alignment: Holistic Cultivation of Capacities with an alignment strength of 8

Let me know if there's anything specific you'd like to discuss or if you need further assistance!
================================================================================

SQLiteData (shared.db) willFetchChanges
SQLiteData (private.db) willFetchChanges
SQLiteData (shared.db) stateUpdate
SQLiteData (shared.db) didFetchChanges
SQLiteData (private.db) stateUpdate
SQLiteData (private.db) didFetchChanges

================================================================================
📨 USER MESSAGE #6
================================================================================
how many goals have I set?
================================================================================
📊 Context estimate: 6 messages, ~215 tokens
🔄 Sending to LLM...
Passing along InferenceError::inferenceFailed::Failed to run inference: Context length of 4096 was 
exceeded during singleExtend.. in response to ExecuteRequest

================================================================================
❌ ERROR
================================================================================
exceededContextWindowSize(FoundationModels.LanguageModelSession.GenerationError.Context(debugDescription:
 "Content contains 4650 tokens, which exceeds the maximum allowed context size of 4096.", 
underlyingErrors: [Provided 4,650 tokens, but the maximum allowed is 4,096.]))
``` 

### Discussion 1

⏺ Looking at this interaction, I can see several issues:

  Main Problem: Context Window Overflow

  The critical error at the end shows:
  exceededContextWindowSize(...)
  Content contains 4650 tokens, which exceeds the maximum allowed context size of 4096.

  After only 3 user messages, you've exceeded the 4096 token limit. Let's trace why:

⏺ Read(swift/Sources/App/ViewModels/GoalCoachViewModel.swift)
  ⎿  Read 239 lines

⏺ Search(pattern: "**/LLM/**/*.swift")
  ⎿  Found 13 files (ctrl+o to expand)

⏺ Now let me check the GetGoalsTool to see what's being returned:

⏺ Read(swift/Sources/Logic/LLM/Tools/GetGoalsTool.swift)
  ⎿  Read 166 lines

⏺ Diagnosis

  Your LLM is blowing through the 4096 token context window because of verbose transcript accumulation.
  Here's what's happening:

  Token Breakdown (from your logs)

  1. System prompt: ~232 tokens (one-time)
  2. Message #1 (assistant welcome): ~40 tokens
  3. Message #2 (user): "could you tell me about my last goal" (~10 tokens)
  4. Message #3 (assistant): Response asking for clarification (~30 tokens)
  5. Message #4 (user): "sure!" (~2 tokens)
  6. Message #5 (LLM tool call + tool output + response):
    - Tool call: getGoals with args (~20 tokens)
    - Tool output: Full GoalsResponse JSON (~500+ tokens)
    - Assistant response summarizing the goal (~150 tokens)

  Total after 3 exchanges: ~1000 tokens

  But the transcript entries accumulate in the LanguageModelSession:
  - Each tool call is logged
  - Each tool response is logged
  - Each assistant response is logged

  By message #6 ("how many goals have I set?"), the transcript contains:
  - All previous messages
  - All previous tool calls
  - All previous tool outputs (including verbose JSON)

  This compounds quickly because tool outputs are very verbose.

  Why It Failed So Fast

  Looking at the transcript dump from your logs:

  transcriptEntries: 4 elements
    ▹ (Response) null
    ▹ (ToolCalls) getGoals: {"limit": 1, "includeArchived": true}
    ▹ (ToolOutput getGoals) {"goals": [{"id": "198E669F...", "title": "Introduction to Programming with
  JavaScript", "description": "spend 40 hours...", ...}]}
    ▹ (Response) Here's a summary of your last goal: ...

  Each tool output contains the full JSON response, which for goals includes:
  - Goal ID (UUID string)
  - Title
  - Description (can be long)
  - Dates
  - Metric targets (nested objects)
  - Aligned values (nested objects)

  Multiply this by multiple tool calls, and you're easily at 4000+ tokens.

  ---
  Solutions

  1. Immediate Fix: Reduce Tool Output Verbosity

  The @Generable responses are too detailed for the transcript. You need to return minimal data, not full
   objects.

  Current (verbose):
  GoalSummary(
      id: "198E669F-E946-409A-A794-DDC003440171",  // 36 chars
      title: "Introduction to Programming with JavaScript",
      description: "spend 40 hours reading, watching instructional videos...",  // Can be 500+ chars
      startDate: "2025-01-06T00:00:00Z",
      targetDate: "2025-03-17T00:00:00Z",
      importance: 5,
      urgency: 5,
      metricTargets: [...],  // Nested objects
      alignedValues: [...]   // Nested objects
  )

  Proposed (minimal):
  // Only return what the LLM needs for conversation
  GoalSummary(
      id: goal.goal.id.uuidString,
      title: goal.expectation.title ?? "Untitled",
      // Skip description unless requested
      importance: goal.expectation.expectationImportance,
      urgency: goal.expectation.expectationUrgency,
      targetDate: goal.goal.targetDate?.ISO8601Format(),
      // Summarize targets/values as counts, not full arrays
      metricCount: goal.metricTargets.count,
      valueCount: goal.valueAlignments.count
  )

  2. Medium Fix: Implement Conversation Summarization

  You need to implement the session management pattern from your schema:

  // swift/Sources/Database/Schemas/schema_current.sql:363
  -- Session management (for context window overflow handling)
  sessionNumber INTEGER NOT NULL DEFAULT 1,

  Pattern:
  1. After 10-15 messages, detect context window pressure
  2. Summarize old messages into a single system message
  3. Archive old llmMessages (set isArchived = 1)
  4. Increment sessionNumber
  5. Continue with fresh context window

  Example:
  // In GoalCoachViewModel.swift

  private func checkContextWindow() async {
      let estimatedTokens = messages.count * 100  // Rough estimate

      if estimatedTokens > 3000 {  // Leave 1000 token buffer
          await summarizeAndArchive()
      }
  }

  private func summarizeAndArchive() async {
      // Create summary of old messages
      let summary = """
      Previous conversation summary:
      - User asked about last goal (JavaScript learning, 40 hours)
      - User has 1 active goal
      """

      // Archive old messages
      let oldMessages = messages.dropLast(5)  // Keep last 5 messages
      // Store in database with isArchived = 1

      // Replace with summary
      messages = [
          ChatMessage(role: .system, content: summary)
      ] + messages.suffix(5)

      // Recreate LLM session with fresh transcript
      llmSession = LanguageModelSession(
          tools: tools,
          instructions: systemPrompt
      )
  }

  3. Long-term Fix: Database-Backed Conversation Storage

  You already have the schema for this (llmConversations + llmMessages). Implement it to:
  - Store messages in database instead of memory
  - Load only recent messages into active context
  - Generate summaries when needed

  ---
  Recommended Action Plan

  Phase 1: Quick Win (Today)
  1. Reduce GoalSummary and other tool responses to minimal data
  2. Skip description fields unless explicitly needed
  3. Return counts instead of full arrays for nested data

  Phase 2: Medium-term (This Week)
  1. Implement context window monitoring
  2. Add automatic summarization after 10 messages
  3. Recreate session with summarized history

  Phase 3: Production-ready (Later)
  1. Implement database-backed conversation storage
  2. Persist conversations across app restarts
  3. Allow users to review/export conversation history

  ---
  Specific Code Changes

  Would you like me to:
  1. Refactor the tool responses to be more concise?
  2. Add context window monitoring to GoalCoachViewModel?
  3. Implement conversation summarization with session management?

  Let me know which approach you'd like to tackle first!

### Example 2

🤖 GoalCoachViewModel: Starting conversation...
🛠️  Registered 8 tools:
   - getGoals: Fetch the user's goals with full details including measures and value alignments
   - getValues: Fetch the user's personal values and life areas to understand what matters most to them
   - createGoal: Create a new goal after validating it doesn't duplicate existing goals
   - checkDuplicateGoal: Check if a goal title would duplicate an existing goal using semantic similarity
   - getMeasures: Fetch available measurement types that can be used for tracking goals and actions
   - getRecentActions: Fetch recent actions the user has taken, including measurements and goal 
contributions
   - getProgress: Analyze progress toward goals including completion percentages, trends, and velocity
   - analyzeAlignment: Analyze how well goals align with personal values, identify gaps, and detect 
conflicts
📝 System prompt: ~116 words (~232 tokens estimated)
✅ LLM session created successfully
💬 Assistant: 👋 Hi! I'm your goal coach. I can help you create meaningful goals that align with your 
values. What would you like to work on today?
SQLiteData (shared.db) willFetchChanges
SQLiteData (private.db) willFetchChanges
SQLiteData (shared.db) stateUpdate
SQLiteData (shared.db) didFetchChanges
SQLiteData (private.db) stateUpdate
SQLiteData (private.db) didFetchChanges


📨 USER MESSAGE #2

tell me about my last three goals

📊 Context estimate: 2 messages, ~41 tokens
🔄 Sending to LLM...


🤖 LLM RESPONSE

Content (928 chars):
Here are your last three goals:

1. **Goal Title:** Introduction to Programming with JavaScript
  * **Description:** Spend 40 hours reading, watching instructional videos, and writing JS; aim for an 
average of 4 hours per week.
  * **Metric Target:** 40 hours
  * **Aligned Values:** Holistic Cultivation of Capacities (alignment strength: 8)

2. **Goal Title:** Building Friendships
  * **Description:** Spend purposeful time with people who aren't colleagues on seven different 
occasions.
  * **Metric Target:** 7 occasions
  * **Aligned Values:** Mental Health and Longevity (alignment strength: 6), Live Well (alignment 
strength: 8)

3. **Goal Title:** Spring into Running
  * **Description:** Run 120km, averaging 12km per week.
  * **Metric Target:** 120km
  * **Aligned Values:** Physical Health and Longevity (alignment strength: 9), Live Well (alignment 
strength: 7), Mental Health and Longevity (alignment strength: 8)

Response type: Response<String>
Mirror dump:
▿ FoundationModels.LanguageModelSession.Response<Swift.String>
  - userPrompt: "tell me about my last three goals"
  - duration: 6.987204291
  - feedbackAttachment: nil
  - content: "Here are your last three goals:\n\n1. **Goal Title:** Introduction to Programming with 
JavaScript\n  * **Description:** Spend 40 hours reading, watching instructional videos, and writing JS; 
aim for an average of 4 hours per week.\n  * **Metric Target:** 40 hours\n  * **Aligned Values:** 
Holistic Cultivation of Capacities (alignment strength: 8)\n\n2. **Goal Title:** Building Friendships\n  
* **Description:** Spend purposeful time with people who aren\'t colleagues on seven different 
occasions.\n  * **Metric Target:** 7 occasions\n  * **Aligned Values:** Mental Health and Longevity 
(alignment strength: 6), Live Well (alignment strength: 8)\n\n3. **Goal Title:** Spring into Running\n  *
 **Description:** Run 120km, averaging 12km per week.\n  * **Metric Target:** 120km\n  * **Aligned 
Values:** Physical Health and Longevity (alignment strength: 9), Live Well (alignment strength: 7), 
Mental Health and Longevity (alignment strength: 8)"
  ▿ rawContent: "Here are your last three goals:\n\n1. **Goal Title:** Introduction to Programming with 
JavaScript\n  * **Description:** Spend 40 hours reading, watching instructional videos, and writing JS; 
aim for an average of 4 hours per week.\n  * **Metric Target:** 40 hours\n  * **Aligned Values:** 
Holistic Cultivation of Capacities (alignment strength: 8)\n\n2. **Goal Title:** Building Friendships\n  
* **Description:** Spend purposeful time with people who aren't colleagues on seven different 
occasions.\n  * **Metric Target:** 7 occasions\n  * **Aligned Values:** Mental Health and Longevity 
(alignment strength: 6), Live Well (alignment strength: 8)\n\n3. **Goal Title:** Spring into Running\n  *
 **Description:** Run 120km, averaging 12km per week.\n  * **Metric Target:** 120km\n  * **Aligned 
Values:** Physical Health and Longevity (alignment strength: 9), Live Well (alignment strength: 7), 
Mental Health and Longevity (alignment strength: 8)"
    ▹ value: FoundationModels.GeneratedJSON
    - id: nil
  ▿ transcriptEntries: 4 elements
    ▹ (Response) null
    ▹ (ToolCalls) getGoals: {"limit": 3, "includeArchived": true}
    ▹ (ToolOutput getGoals) {"goals": [{"id": "198E669F-E946-409A-A794-DDC003440171", "title": 
"Introduction to Programming with JavaScript", "description": "spend 40 hours reading, watching 
instructional videos, and writing JS; avg 4 hours per week", "startDate": "2025-01-06T00:00:00Z", 
"targetDate": "2025-03-17T00:00:00Z", "importance": 5, "urgency": 5, "metricTargets": [{"measureName": 
"Hours", "targetValue": 40, "unit": "hours"}], "alignedValues": [{"valueName": "Holistic Cultivation of 
Capacities", "alignmentStrength": 8}]}, {"id": "CE23369E-FDBC-4A0A-838D-0B607D70981E", "title": "Building
 Friendships", "description": "on seven different occasions, spend purposeful time with people who aren't
 colleagues", "startDate": "2025-01-06T00:00:00Z", "targetDate": "2025-03-17T00:00:00Z", "importance": 5,
 "urgency": 5, "metricTargets": [{"measureName": "Occasions", "targetValue": 7, "unit": "occasions"}], 
"alignedValues": [{"valueName": "Mental Health and Longevity", "alignmentStrength": 6}, {"valueName": 
"Live Well", "alignmentStrength": 8}]}, {"id": "C105EF73-EAAF-4799-9F6A-C8A7967A0ACA", "title": "Spring 
into Running", "description": "run 120km, averaging 12km per week", "startDate": "2025-01-06T00:00:00Z", 
"targetDate": "2025-03-17T00:00:00Z", "importance": 7, "urgency": 4, "metricTargets": [{"measureName": 
"Km", "targetValue": 120, "unit": "km"}], "alignedValues": [{"valueName": "Physical Health and 
Longevity", "alignmentStrength": 9}, {"valueName": "Live Well", "alignmentStrength": 7}, {"valueName": 
"Mental Health and Longevity", "alignmentStrength": 8}]}], "totalCount": 3}
    ▹ (Response) Here are your last three goals:

1. **Goal Title:** Introduction to Programming with JavaScript
  * **Description:** Spend 40 hours reading, watching instructional videos, and writing JS; aim for an 
average of 4 hours per week.
  * **Metric Target:** 40 hours
  * **Aligned Values:** Holistic Cultivation of Capacities (alignment strength: 8)

2. **Goal Title:** Building Friendships
  * **Description:** Spend purposeful time with people who aren't colleagues on seven different 
occasions.
  * **Metric Target:** 7 occasions
  * **Aligned Values:** Mental Health and Longevity (alignment strength: 6), Live Well (alignment 
strength: 8)

3. **Goal Title:** Spring into Running
  * **Description:** Run 120km, averaging 12km per week.
  * **Metric Target:** 120km
  * **Aligned Values:** Physical Health and Longevity (alignment strength: 9), Live Well (alignment 
strength: 7), Mental Health and Longevity (alignment strength: 8)
====================

### References 

https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models 
https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation 
https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling 
https://developer.apple.com/documentation/Technotes/tn3193-managing-the-on-device-foundation-model-s-context-window 

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py fetch
      "https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-…)
  ⎿  ✓ Crawl complete!                                                                      
       Pages fetched: 11
       Pages skipped: 5
     … +119 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py fetch
      "https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with…)
  ⎿  ✓ Crawl complete!                                                                      
       Pages fetched: 0
       Pages skipped: 1
     … +12 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py fetch
      "https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-callin…)
  ⎿  ✓ Crawl complete!                                                                      
       Pages fetched: 0
       Pages skipped: 1
     … +11 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py fetch
      "https://developer.apple.com/documentation/Technotes/tn3193-managing-the-on-device-foundation-mod…)
  ⎿  ✓ Crawl complete!                                                                      
       Pages fetched: 0
       Pages skipped: 1
     … +12 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Good - most pages were already indexed. Let me now search for the key information about context window
  management:

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py search "context window management transcript"
       --limit 5)
  ⎿  ================================================================================       
     Search Results: context window management transcript
     ================================================================================
     … +62 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py search "tool output verbosity @Generable"
      --limit 5)
  ⎿  ================================================================================       
     Search Results: tool output verbosity @Generable
     ================================================================================
     … +59 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py search "LanguageModelSession transcript
      entries" --limit 5)
  ⎿  ================================================================================       
     Search Results: LanguageModelSession transcript entries
     ================================================================================
     … +84 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Perfect! Now let me read the full TN3193 document:

⏺ Bash(cd ~/.claude/skills/doc-fetcher && python doc_fetcher.py read
      "https://developer.apple.com/documentation/Technotes/tn3193-managing-the-on-device-foundation-mode…)
  ⎿  Error: usage: doc_fetcher.py [-h] {fetch,search,approve-domain,stats,build-xref} ...
     doc_fetcher.py: error: argument command: invalid choice: 'read' (choose from fetch, search, 
     approve-domain, stats, build-xref)

⏺ Read(~/Coding/REFERENCE/documents/appleDeveloper/foundationmodels/foundation-models.md)
  ⎿  Read 50 lines

⏺ Let me search the doc-fetcher database for the full technote content:

⏺ Bash(cd ~/.claude/skills/doc-fetcher && sqlite3 data/docs.db "SELECT content FROM documents WHERE url =
      'https://developer.apple.com/documentation/Technotes/tn3193-m…)
  ⎿  Error: in prepare, no such column: content                                             
       SELECT content FROM documents WHERE url = 'https://developer.apple.com/documen
              ^--- error here
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && sqlite3 data/docs.db ".schema documents")
  ⎿  CREATE TABLE IF NOT EXISTS "documents" (                                               
         id INTEGER PRIMARY KEY AUTOINCREMENT,
         domain_id INTEGER NOT NULL,
     … +22 lines (ctrl+o to expand)
  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Bash(cd ~/.claude/skills/doc-fetcher && sqlite3 data/docs.db "SELECT content_clean FROM documents WHERE url
       LIKE '%tn3193%' LIMIT 1;")
  ⎿ ArticleTN3193: Managing the on-device foundation model’s context windowLearn how to budget for the c
    ontext window limit of Apple’s on-device foundation model and handle the error when reaching the lim
    it.
    … +136 lines (ctrl+o to expand)


  ⎿  Shell cwd was reset to /Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app

⏺ Perfect! Now I have the complete picture. Let me analyze what you're doing vs Apple's recommendations:

⏺ Analysis: Your Implementation vs Apple's Best Practices

  Based on TN3193 and your transcript logs, here's what I found:

  What You're Doing Right ✅

  1. Catching the error properly - Your code handles exceededContextWindowSize correctly
  2. Using tools appropriately - Your 8 tools are well-designed
  3. Session-based architecture - You have LanguageModelSession set up correctly

  What's Causing the Problem ❌

  Looking at your transcript entries from the logs:

  transcriptEntries: 4 elements
    ▹ (Response) null
    ▹ (ToolCalls) getGoals: {"limit": 3, "includeArchived": true}
    ▹ (ToolOutput getGoals) {"goals": [{"id": "198E669F-...", "title": "...", "description": "...",
  "startDate": "...", ...}], "totalCount": 3}
    ▹ (Response) Here are your last three goals: ...

  The tool output alone is ~1500+ characters (for 3 goals). Let's estimate:
  - Each goal has: id (36 chars), title (50), description (100), dates (40), importance/urgency (4),
  metricTargets array (100), alignedValues array (150)
  - Total per goal: ~480 characters = ~120 tokens
  - For 3 goals: ~360 tokens
  - Plus JSON overhead: ~400-500 tokens

  After just ONE tool call with 3 goals, you've consumed ~500 tokens!

  What Apple Recommends (from TN3193)

  "Look for opportunities to save tokens by skipping tool calling entirely. Use a tool only when you need
   the model to decide if it needs the tool. In the cases where the model should always have information 
  from a tool, run the tool directly before you call the model and integrate the tool's output to the 
  prompt directly."

  and

  "Keep your tool description and @Guide descriptions to a short phrase each."
  "Give the model a maximum of 3–5 tools to choose from."

  and critically:

  "When the model calls a tool, the framework returns the tool's output back to the model for further 
  processing, which consumes additional tokens."

  Key Insight from Your Logs

  Looking at the second example transcript:

  (ToolOutput getGoals) {"goals": [
    {"id": "198E669F-E946-409A-A794-DDC003440171", "title": "Introduction to Programming with
  JavaScript", "description": "spend 40 hours...", ...},
    {"id": "CE23369E-FDBC-4A0A-838D-0B607D70981E", "title": "Building Friendships", ...},
    {"id": "C105EF73-EAAF-4799-9F6A-C8A7967A0ACA", "title": "Spring into Running", ...}
  ], "totalCount": 3}

  The entire tool output is being added to the transcript. This is the smoking gun.

  ---
  The Problem: Tool Outputs Are Too Verbose

  Token Budget Breakdown

  For the 4096 token context window:

  | Component                    | Tokens (Est.) | Percentage |
  |------------------------------|---------------|------------|
  | System prompt + instructions | ~230          | 6%         |
  | Tool definitions (8 tools)   | ~400-600      | 12-15%     |
  | Available for conversation   | ~3400         | ~83%       |

  But after ONE exchange with getGoals(limit: 3):

  | Component                                 | Tokens      |
  |-------------------------------------------|-------------|
  | User: "tell me about my last three goals" | ~10         |
  | Tool call args                            | ~20         |
  | Tool output (3 goals with full details)   | ~500        |
  | Assistant response                        | ~150        |
  | Total this turn                           | ~680 tokens |

  By message #6, you've accumulated:
  - 3 user messages (~30 tokens)
  - 2 assistant responses (~200 tokens)
  - 1 tool call + output (~520 tokens)
  - Total: ~750 tokens just for messages

  BUT: The transcript also retains:
  - All tool definitions (repeated each time? Need to verify)
  - All previous tool outputs
  - System prompt

  This compounds rapidly!

  ---
  Recommended Fixes (Prioritized)

  1. Immediate: Reduce Tool Output Verbosity (High Impact)

  Apple's guidance: "Reduce the size and complexity of your type."

  Current GoalSummary:
  @Generable
  public struct GoalSummary: Codable {
      public let id: String                      // 36 chars
      public let title: String                   // ~50 chars
      public let description: String?            // ~100-500 chars ⚠️
      public let startDate: String?              // 25 chars
      public let targetDate: String?             // 25 chars
      public let importance: Int                 // 1 char
      public let urgency: Int                    // 1 char
      public let metricTargets: [MetricTarget]   // ~100-200 chars ⚠️
      public let alignedValues: [AlignedValue]   // ~150-300 chars ⚠️
  }

  Proposed minimal version:
  @Generable
  public struct GoalSummary: Codable {
      public let id: String                      // Keep (needed for CreateGoalTool)
      public let title: String                   // Keep (essential)
      public let importance: Int                 // Keep (for prioritization)
      public let urgency: Int                    // Keep (for prioritization)
      public let targetDate: String?             // Keep (for timing)

      // REMOVE or make optional/lazy:
      // - description (verbose, not needed for listing)
      // - startDate (less important than targetDate)
      // - metricTargets (summarize as count instead)
      // - alignedValues (summarize as count instead)

      // ADD summary fields:
      public let metricCount: Int                // "This goal has 2 metrics"
      public let valueCount: Int                 // "Aligned with 3 values"
  }

  Token savings: ~350 tokens per 3 goals → ~120 tokens per 3 goals (65% reduction)

  2. Medium: Use @Guide to Limit Array Sizes (Medium Impact)

  From TN3193:
  "Add a @Guide to any Generable arrays and specify the max count using maximumCount(_:)."

  In GetGoalsTool.Arguments:
  @Generable
  public struct Arguments: Codable {
      @Guide(description: "Maximum number of goals to return", .maximumCount(10))  // ✅ Add this
      let limit: Int

      // ...
  }

  This prevents runaway responses.

  3. Long-term: Implement Transcript Management (High Impact for Multi-turn)

  From TN3193:
  "Pick some important entries from the original session's transcript, and use them to create a new 
  session."

  Your current approach keeps the entire transcript in memory. Apple recommends:

  // After 10-15 messages, condense the transcript
  func newContextualSession(with originalSession: LanguageModelSession) -> LanguageModelSession {
      let allEntries = originalSession.transcript

      // Keep only first (context) and last 5 entries
      let condensedEntries = [allEntries.first].compactMap { $0 } + allEntries.suffix(5)
      let condensedTranscript = Transcript(entries: condensedEntries)

      var newSession = LanguageModelSession(transcript: condensedTranscript)
      newSession.prewarm()  // ⚠️ Important for performance
      return newSession
  }

  4. Strategic: Skip Tool Calling When Possible (Medium Impact)

  From TN3193:
  "Look for opportunities to save tokens by skipping tool calling entirely."

  For queries like "tell me about my last goal", you could:
  1. Option A: Load goals directly in ViewModel before starting conversation
  2. Option B: Use a simpler tool output format
  3. Option C: Use system message with pre-loaded context instead of tool calling

  Example:
  // In startConversation(), pre-load goals
  let repository = GoalRepository(database: database)
  let recentGoals = try await repository.fetchAll().prefix(5)

  // Add to system prompt instead of using tool
  let systemPrompt = """
  You are a goal coach. The user currently has \(recentGoals.count) active goals:
  \(recentGoals.map { "- \($0.expectation.title ?? "Untitled")" }.joined(separator: "\n"))

  Use this context to answer questions about their goals.
  """

  This eliminates tool calling tokens entirely for simple queries!

  ---
  Concrete Action Plan

⏺ Summary

  Root cause: Tool outputs are adding 400-500 tokens per call to the transcript, and the session retains
  ALL previous tool outputs. After 6-8 tool calls, you've exhausted the 4096 token budget.

  Fixes (in order of impact):
  1. ✅ Reduce tool output verbosity (~65% token savings) - Remove description, nested arrays
  2. ✅ Add .maximumCount() guides to prevent runaway arrays
  3. ✅ Implement transcript condensation for multi-turn conversations
  4. ⚠️ Consider pre-loading context instead of tool calling for simple queries


## Reframing

> an additional thought is to have two sessions or maybe three like I had originally thought a few days 
ago. the user experience is about the appearance of continuity, natural language, etc. the llm and the 
user don't need sql statememnts or full json. The user might ask something silly like 'tell me what to 
do' and the llm has to translate that into something the tools can address ... okay, let's see if the 
user has goals, let's see their progress on their goals, oh maybe this goal has no progress and the 
deadline is soon, okay here;s what to do. By the time the llm has done all that it's spent the tokens and
 there's no more exchange. So we can add another model session that is an intermediary between the coach 
and the tools. The coach can take the user input and express it in something closer to what the tools 
expose and ask the other llm to call the tools and condense the output. Those should probably be single 
interaction sessions. But then a third llm could be managing the conversation space by starting new 
sessions, summarizing the content of old sesssions, etc 

⏺ This is a brilliant architectural insight that aligns perfectly with Apple's guidance and modern LLM
  system design. You're essentially describing a multi-agent orchestration pattern with specialized
  models for different tasks.

  Let me map out this architecture based on your thinking:

  Three-Session Architecture

  ┌─────────────────────────────────────────────────────────────┐
  │                    USER INTERFACE                           │
  └──────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  SESSION 1: CONVERSATION COACH (Long-lived)                 │
  │  - Natural language with user                               │
  │  - Maintains conversation context                           │
  │  - NO tools, NO database access                             │
  │  - Delegates to Orchestrator when needs data                │
  │  - Budget: ~3000 tokens for multi-turn conversation         │
  └──────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  SESSION 2: DATA ORCHESTRATOR (Single-turn)                │
  │  - Receives structured queries from Coach                   │
  │  - HAS all 8 tools available                                │
  │  - Calls tools, condenses output                            │
  │  - Returns minimal summary to Coach                         │
  │  - Budget: 4096 tokens (fresh per query)                    │
  │  - Destroyed after each use                                 │
  └──────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  SESSION 3: MEMORY MANAGER (Single-turn)                   │
  │  - Monitors Coach's transcript size                         │
  │  - Summarizes old conversations                             │
  │  - Creates new Coach sessions with condensed history        │
  │  - Budget: 4096 tokens (fresh per summary task)             │
  │  - Destroyed after each use                                 │
  └──────────────────────┬──────────────────────────────────────┘
                         │
                         ▼
                    Database / Storage

  ---
  Why This Works Better

  Token Efficiency

  | Session        | Token Budget    | Lifetime                     | Contents
        |
  |----------------|-----------------|------------------------------|------------------------------------
  ------|
  | Coach          | ~3000 available | Multi-turn (10-20 exchanges) | User messages + assistant responses
   only |
  | Orchestrator   | ~4096           | Single-turn                  | Tool calls + verbose JSON outputs
        |
  | Memory Manager | ~4096           | Single-turn                  | Full transcript + summarization
        |

  Key insight: Tool outputs never pollute the Coach's transcript!

  Separation of Concerns

  // USER: "tell me what to do"

  // COACH (Session 1): Natural language understanding
  "The user wants guidance. I need to check their goals and progress.
  Let me ask the Orchestrator for this information."
  → Sends to Orchestrator: "Get user's goals and progress summary"

  // ORCHESTRATOR (Session 2): Data retrieval
  → Calls getGoals(limit: 5)  // 500 tokens
  → Calls getProgress()       // 400 tokens
  → Condenses: "User has 3 goals. JavaScript learning: 60% complete, deadline in 2 weeks. 
                Running: 20% complete, deadline in 1 week (urgent!). Friendships: 0% complete."
  → Returns to Coach: ~50 tokens

  // COACH (Session 1): Receives summary, responds
  "Based on your progress, I'd focus on the Running goal since it's 
  urgent and behind schedule. You need 12km/week but haven't started yet.
  Would you like help breaking this into daily runs?"
  → Only ~50 tokens added to Coach transcript, not ~900!

  ---
  Implementation Design

⏺ Session 1: Conversation Coach

  /// Long-lived session for natural conversation
  /// NO tools, delegates data queries to Orchestrator
  @available(iOS 26.0, macOS 26.0, *)
  public final class ConversationCoachSession {
      private var llmSession: LanguageModelSession?
      private let orchestrator: DataOrchestratorSession
      private let memoryManager: MemoryManagerSession

      // Threshold for triggering summarization
      private let maxTranscriptEntries = 15

      public init(database: any DatabaseWriter) {
          self.orchestrator = DataOrchestratorSession(database: database)
          self.memoryManager = MemoryManagerSession()
      }

      public func start() async throws {
          let instructions = """
          You are a thoughtful goal-setting coach helping users create meaningful, achievable goals.
          
          IMPORTANT: You do NOT have direct access to the user's data. When you need information:
          1. Request it from the Orchestrator using structured queries
          2. Wait for the condensed summary
          3. Use the summary to respond naturally to the user
          
          Your approach:
          - Ask clarifying questions to understand what truly matters
          - Be encouraging but realistic
          - Keep responses conversational and concise (2-3 sentences)
          
          When you need data, respond with a JSON query like:
          {"action": "getData", "query": "goals with progress", "filters": {"urgent": true}}
          
          The Orchestrator will handle tool calling and return a brief summary.
          """

          llmSession = LanguageModelSession(instructions: instructions)
      }

      public func respond(to userMessage: String) async throws -> String {
          guard let session = llmSession else {
              throw ConversationError.sessionNotStarted
          }

          // Check if we need to summarize before responding
          if session.transcript.count >= maxTranscriptEntries {
              try await summarizeAndReset()
          }

          // Get response from Coach
          let response = try await session.respond(to: userMessage)

          // Check if Coach is requesting data
          if let dataRequest = parseDataRequest(from: response.content) {
              // Delegate to Orchestrator
              let summary = try await orchestrator.fetchData(query: dataRequest)

              // Feed summary back to Coach (much smaller than raw tool output!)
              let followUp = "Data summary: \(summary)"
              let finalResponse = try await session.respond(to: followUp)
              return finalResponse.content
          }

          return response.content
      }

      private func summarizeAndReset() async throws {
          guard let session = llmSession else { return }

          // Use Memory Manager to create summary
          let summary = try await memoryManager.summarize(transcript: session.transcript)

          // Create new session with summary as context
          let instructions = """
          You are a goal-setting coach. Here's what we've discussed so far:
          
          \(summary)
          
          Continue the conversation naturally from here.
          """

          llmSession = LanguageModelSession(instructions: instructions)
          llmSession?.prewarm()  // Apple's recommendation for performance
      }
  }

  Session 2: Data Orchestrator

  /// Single-turn session for data retrieval
  /// HAS all tools, condenses output before returning
  @available(iOS 26.0, macOS 26.0, *)
  public final class DataOrchestratorSession {
      private let database: any DatabaseWriter

      public init(database: any DatabaseWriter) {
          self.database = database
      }

      /// Fetch data and return condensed summary
      /// Creates fresh session each time (no transcript pollution)
      public func fetchData(query: DataQuery) async throws -> String {
          // Create fresh session with tools
          let tools: [any Tool] = [
              GetGoalsTool(database: database),
              GetValuesTool(database: database),
              GetProgressTool(database: database),
              GetRecentActionsTool(database: database),
              // ... other tools
          ]

          let instructions = """
          You are a data retrieval assistant. Your job is to:
          1. Call the appropriate tools based on the query
          2. CONDENSE the results into a brief summary (2-3 sentences max)
          3. Return ONLY the summary, not the raw tool output
          
          Example:
          Query: "goals with progress"
          Tool output: [verbose JSON with 3 goals]
          Your response: "User has 3 active goals. JavaScript learning is 60% complete. 
                         Running goal is urgent (20% complete, deadline in 1 week)."
          
          Be concise. Focus on what's actionable.
          """

          let session = LanguageModelSession(
              tools: tools,
              instructions: instructions
          )

          // Single interaction
          let prompt = formatQuery(query)
          let response = try await session.respond(to: prompt)

          // Session will be destroyed when this function returns
          // Tool outputs don't pollute the Coach's transcript!
          return response.content
      }

      private func formatQuery(_ query: DataQuery) -> String {
          // Convert structured query to prompt
          switch query.type {
          case .goals:
              return "Get the user's goals\(query.includeProgress ? " with progress" : "")"
          case .values:
              return "Get the user's personal values"
          case .actions:
              return "Get recent actions from the last \(query.daysBack ?? 7) days"
          }
      }
  }

  public struct DataQuery {
      enum QueryType {
          case goals
          case values
          case actions
      }
      let type: QueryType
      let includeProgress: Bool
      let daysBack: Int?
      // ... other filters
  }

  Session 3: Memory Manager

  /// Single-turn session for summarizing conversation history
  @available(iOS 26.0, macOS 26.0, *)
  public final class MemoryManagerSession {

      /// Summarize a transcript into concise context
      public func summarize(transcript: [Transcript.Entry]) async throws -> String {
          let instructions = """
          You are a conversation summarizer. Given a transcript of a coaching conversation:
          1. Identify the main topics discussed
          2. Note any goals created or progress made
          3. Capture the user's current focus or next steps
          4. Keep summary to 3-5 sentences maximum
          
          Format:
          "User discussed [topic]. They created [goals]. Current focus: [next steps]."
          """

          let session = LanguageModelSession(instructions: instructions)

          // Convert transcript to readable format
          let transcriptText = formatTranscript(transcript)

          let prompt = "Summarize this conversation:\n\n\(transcriptText)"
          let response = try await session.respond(to: prompt)

          // Session destroyed after this
          return response.content
      }

      private func formatTranscript(_ entries: [Transcript.Entry]) -> String {
          entries.enumerated().map { index, entry in
              switch entry {
              case .prompt(let prompt):
                  return "User: \(prompt.content)"
              case .response(let response):
                  return "Coach: \(response)"
              default:
                  return ""  // Skip tool calls in summary
              }
          }.joined(separator: "\n")
      }
  }

  ---
  Key Benefits of This Architecture

  1. Token Efficiency

  - Coach transcript: Only user messages + coach responses (~100 tokens per exchange)
  - Orchestrator: Destroyed after each use (tools outputs never accumulate)
  - Memory Manager: Destroyed after each use (summarization is ephemeral)

  Before: 6 exchanges = ~4000 tokens (failure)
  After: 20+ exchanges possible in Coach session

  2. Separation of Concerns

  - Coach: Natural language, personality, guidance
  - Orchestrator: SQL, JSON, data transformation
  - Memory Manager: Context compression, history management

  3. Scalability

  - Can add more specialized Orchestrators (e.g., ActionOrchestrator, AnalyticsOrchestrator)
  - Can implement RAG in Orchestrator without affecting Coach
  - Can swap LLM providers for different sessions (e.g., smaller model for Orchestrator)

  4. User Experience

  - Appears seamless: User sees continuous conversation
  - Actually efficient: Behind the scenes, sessions are created/destroyed strategically
  - Natural language: Coach never exposes technical details (no "calling getGoals...")

  ---
  Database Integration

  This maps perfectly to your schema:

  // swift/Sources/Database/Schemas/schema_current.sql:363
  CREATE TABLE llmConversations (
      id TEXT PRIMARY KEY,
      conversationType TEXT NOT NULL CHECK(conversationType IN (
          'goal_setting',      // ← ConversationCoachSession
          'reflection',
          'values_alignment',
          'general'
      )),
      sessionNumber INTEGER NOT NULL DEFAULT 1,  // ← Increments after summarization
      // ...
  );

  CREATE TABLE llmMessages (
      id TEXT PRIMARY KEY,
      conversationId TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN (
          'user',           // ← User messages
          'assistant',      // ← Coach responses
          'system',         // ← Summaries from Memory Manager
          'tool_call',      // ← NOT stored (ephemeral Orchestrator sessions)
          'tool_response'   // ← NOT stored (ephemeral)
      )),
      sessionNumber INTEGER NOT NULL DEFAULT 1,
      isArchived INTEGER NOT NULL DEFAULT 0,  // ← Set when Memory Manager summarizes
      // ...
  );

  Key insight: Tool calls and responses are never persisted because they happen in ephemeral Orchestrator
   sessions!

  ---
  Next Steps

  Would you like me to:

  1. Implement the three-session architecture with the classes above?
  2. Refactor GoalCoachViewModel to use ConversationCoachSession?
  3. Add transcript monitoring that auto-triggers Memory Manager?
  4. Create minimal tool responses (still valuable even with Orchestrator pattern)?

  This is a really elegant solution that solves both the token problem AND creates a more maintainable
  architecture. The user gets natural conversation, the LLM gets efficient token usage, and you get clean
   separation of concerns.

> great. for now let's skech out the architecture a bit more. Please outline the files, structs, classes,
 etc. and map them to the other parts of the app. Thinking broadly here, we can also reframe what the 
coach and orchestrator are. Why be specific to tools for instance? The coach needs to be an agent focused
 on meeting the user where they are and getting them to the next step. The orchestrator needs to know 
about everything the application can do, she needs to have a dictionary, a catalogue, a framework for all
 the data and the tools and how to get out what's needed. The user asks the coach a question and the 
coach refines the question into something the orchestrator can work with. The orchestrator gets that 
informatin back to the coach who gives it to the user (or maybe the orchestrator gives it directly to the
 user if there's nothing more the coach needs to do) The memory manager mediates. I'm not sure, but maybe
 this means all the other sessions are nested inside a memory manager session? 

⏺ Excellent reframing! You're absolutely right - this is about agent roles and capabilities, not just
  "tool calling". Let me sketch out a more generalized architecture:

# Proposal

Conceptual Model: Three-Agent System

  ┌─────────────────────────────────────────────────────────────────┐
  │                    MEMORY MANAGER                               │
  │  "The Mediator" - Lifecycle & Context Management               │
  │                                                                 │
  │  Responsibilities:                                              │
  │  - Creates and destroys Coach/Orchestrator sessions            │
  │  - Monitors token usage across all sessions                    │
  │  - Triggers summarization when needed                          │
  │  - Manages conversation persistence to database                │
  │  - Routes messages between Coach and Orchestrator              │
  │                                                                 │
  │  Contains:                                                      │
  │  ├─ CoachSession (long-lived, user-facing)                     │
  │  └─ OrchestratorSession (ephemeral, data-facing)               │
  └─────────────────────────────────────────────────────────────────┘
                            │
             ┌──────────────┴──────────────┐
             ▼                             ▼
  ┌──────────────────────┐      ┌──────────────────────────┐
  │   COACH SESSION      │      │  ORCHESTRATOR SESSION    │
  │  "The Guide"         │      │  "The Librarian"         │
  │                      │      │                          │
  │  Focus: Human needs  │      │  Focus: App capabilities │
  │  Language: Natural   │      │  Language: Structured    │
  │  Lifetime: Multi-turn│      │  Lifetime: Single-turn   │
  │                      │      │                          │
  │  Does:               │      │  Has:                    │
  │  - Understand intent │      │  - Capability Catalog    │
  │  - Provide guidance  │      │  - Tool Registry         │
  │  - Build rapport     │      │  - Data Schema Map       │
  │  - Translate queries │      │  - Query Templates       │
  │                      │      │                          │
  │  Does NOT:           │      │  Does:                   │
  │  - Call tools        │      │  - Call tools            │
  │  - Access database   │      │  - Transform data        │
  │  - Know schema       │      │  - Format responses      │
  │                      │      │  - Validate queries      │
  └──────────────────────┘      └──────────────────────────┘

  ---
  File Structure

  swift/Sources/
  ├── Logic/
  │   └── LLM/
  │       ├── Sessions/                          # NEW: Core session management
  │       │   ├── MemoryManager.swift            # Top-level mediator
  │       │   ├── CoachSession.swift             # User-facing agent
  │       │   └── OrchestratorSession.swift      # Data-facing agent
  │       │
  │       ├── Capabilities/                      # NEW: Orchestrator's knowledge base
  │       │   ├── CapabilityCatalog.swift        # Registry of what app can do
  │       │   ├── DataCapabilities.swift         # Read operations (goals, values, etc.)
  │       │   ├── ActionCapabilities.swift       # Write operations (create, update, etc.)
  │       │   ├── AnalyticsCapabilities.swift    # Computed insights (progress, alignment)
  │       │   └── CapabilityDescriptor.swift     # Protocol for capability metadata
  │       │
  │       ├── Communication/                     # NEW: Inter-session messaging
  │       │   ├── SessionMessage.swift           # Base message protocol
  │       │   ├── CoachToOrchestratorQuery.swift # Structured queries from Coach
  │       │   ├── OrchestratorResponse.swift     # Data summaries to Coach
  │       │   └── MemorySnapshot.swift           # Context preservation
  │       │
  │       ├── Tools/                             # EXISTING: Unchanged
  │       │   ├── GetGoalsTool.swift             # Used BY Orchestrator
  │       │   ├── CreateGoalTool.swift
  │       │   └── ... (all existing tools)
  │       │
  │       ├── Services/                          # EXISTING: Moved from Logic root
  │       │   └── GoalCoachService.swift         # DEPRECATED → use MemoryManager
  │       │
  │       └── Support/                           # EXISTING
  │           ├── ConversationHistory.swift
  │           ├── ConversationError.swift
  │           └── ModelAvailability.swift
  │
  ├── App/
  │   └── ViewModels/
  │       └── GoalCoachViewModel.swift           # REFACTORED: now wraps MemoryManager
  │
  └── Database/
      └── Repositories/
          └── ConversationRepository.swift       # NEW: Persist conversations

  ---
  Core Architecture Components

  1. MemoryManager.swift - The Mediator (Top Level)

  //
  //  MemoryManager.swift
  //  ten-week-goal-app
  //
  //  PURPOSE: Orchestrate multi-session conversations with lifecycle management
  //  PATTERN: Mediator pattern - coordinates Coach and Orchestrator sessions
  //

  import Foundation
  import FoundationModels
  import SQLiteData
  import Dependencies

  /// Manages the lifecycle and coordination of Coach and Orchestrator sessions
  /// This is the top-level entry point for LLM conversations
  @available(iOS 26.0, macOS 26.0, *)
  public final class MemoryManager {

      // MARK: - Session State

      /// Current conversation ID (persisted to database)
      private var conversationId: UUID?

      /// Current session number (increments after summarization)
      private var sessionNumber: Int = 1

      /// Active coach session (long-lived, user-facing)
      private var coachSession: CoachSession?

      /// Capability catalog (shared with Orchestrator)
      private let capabilityCatalog: CapabilityCatalog

      /// Database access (for persistence and Orchestrator)
      private let database: any DatabaseWriter

      // MARK: - Configuration

      /// Maximum transcript entries before triggering summarization
      private let maxTranscriptEntries = 15

      /// Token budget thresholds
      private struct TokenBudget {
          static let coachMaximum = 3000      // Leave buffer for summarization
          static let orchestratorMaximum = 4096  // Fresh session each time
          static let summaryMaximum = 4096    // Fresh session for summarization
      }

      // MARK: - Initialization

      public init(database: any DatabaseWriter) {
          self.database = database
          self.capabilityCatalog = CapabilityCatalog(database: database)
      }

      // MARK: - Public Interface

      /// Start a new conversation or resume existing one
      public func startConversation(
          type: ConversationType = .goalSetting,
          resumeFrom conversationId: UUID? = nil
      ) async throws {
          if let existingId = conversationId {
              // Resume existing conversation
              try await resumeConversation(existingId)
          } else {
              // Create new conversation
              self.conversationId = UUID()
              self.sessionNumber = 1

              // Create coach session
              self.coachSession = try await CoachSession(
                  conversationType: type,
                  capabilityCatalog: capabilityCatalog,
                  onDataRequest: handleDataRequest  // Callback for Orchestrator queries
              )

              // Persist conversation start to database
              try await persistConversationStart(type: type)
          }
      }

      /// Process user message through the system
      public func processMessage(_ userMessage: String) async throws -> String {
          guard let coach = coachSession else {
              throw ConversationError.sessionNotStarted
          }

          // Check if we need to summarize before processing
          if shouldSummarize(coach.transcriptSize) {
              try await summarizeAndReset()
          }

          // Coach processes message
          // If Coach needs data, it will call handleDataRequest via callback
          let response = try await coach.respond(to: userMessage)

          // Persist exchange to database
          try await persistExchange(user: userMessage, assistant: response)

          return response
      }

      // MARK: - Orchestrator Integration

      /// Handle data requests from Coach
      /// This is where Coach → Orchestrator communication happens
      private func handleDataRequest(_ query: CoachQuery) async throws -> String {
          // Create ephemeral Orchestrator session
          let orchestrator = OrchestratorSession(
              capabilityCatalog: capabilityCatalog,
              database: database
          )

          // Orchestrator processes query (may call multiple tools)
          let response = try await orchestrator.execute(query: query)

          // Orchestrator session is destroyed when this function returns
          // Tool outputs never pollute Coach's transcript!

          return response.summary  // Condensed, not raw tool output
      }

      // MARK: - Summarization

      /// Check if summarization is needed
      private func shouldSummarize(_ transcriptSize: Int) -> Bool {
          return transcriptSize >= maxTranscriptEntries
      }

      /// Summarize current conversation and create fresh session
      private func summarizeAndReset() async throws {
          guard let coach = coachSession else { return }

          print("🧠 MemoryManager: Summarizing conversation (session \(sessionNumber))")

          // Create ephemeral summarization session
          let summary = try await createSummary(from: coach.transcript)

          // Archive old messages in database
          try await archiveCurrentSession()

          // Increment session number
          sessionNumber += 1

          // Create new coach session with summary as context
          self.coachSession = try await CoachSession(
              conversationType: coach.conversationType,
              capabilityCatalog: capabilityCatalog,
              onDataRequest: handleDataRequest,
              priorContext: summary  // Condensed history
          )

          // Persist summarization event
          try await persistSummarization(summary: summary)

          print("✅ MemoryManager: New session \(sessionNumber) started")
      }

      /// Create summary using fresh LLM session
      private func createSummary(from transcript: [Transcript.Entry]) async throws -> String {
          let instructions = """
          Summarize this coaching conversation in 3-5 sentences.
          Focus on: goals discussed, progress made, user's current focus, next steps.
          Format: "User discussed [topic]. Created [goals]. Current focus: [next]."
          """

          let session = LanguageModelSession(instructions: instructions)

          let transcriptText = formatTranscriptForSummary(transcript)
          let response = try await session.respond(to: "Summarize:\n\n\(transcriptText)")

          // Session destroyed when function returns
          return response.content
      }

      // MARK: - Database Persistence

      private func persistConversationStart(type: ConversationType) async throws {
          // Use ConversationRepository to insert llmConversations record
          // conversationId, conversationType, sessionNumber, startedAt, etc.
      }

      private func persistExchange(user: String, assistant: String) async throws {
          // Use ConversationRepository to insert llmMessages records
          // Two records: one for user, one for assistant
      }

      private func archiveCurrentSession() async throws {
          // Update llmMessages: set isArchived = 1 for current session
      }

      private func persistSummarization(summary: String) async throws {
          // Insert system message with summary
          // Increment sessionNumber in llmConversations
      }
  }

  2. CoachSession.swift - The Guide (User-Facing Agent)

  //
  //  CoachSession.swift
  //  ten-week-goal-app
  //
  //  PURPOSE: Natural language agent focused on user guidance and intent understanding
  //  PATTERN: Agent with callback for data requests (no direct tools)
  //

  import Foundation
  import FoundationModels

  /// User-facing coaching agent
  /// - Natural language conversation
  /// - NO direct tool access
  /// - Delegates data queries to Orchestrator via callback
  @available(iOS 26.0, macOS 26.0, *)
  public final class CoachSession {

      // MARK: - Configuration

      public enum CoachingStyle {
          case goalSetting      // Focus on creating and planning goals
          case reflection       // Focus on reviewing progress and insights
          case valuesAlignment  // Focus on connecting actions to values
          case general          // Open-ended coaching
      }

      public let conversationType: ConversationType
      private let style: CoachingStyle

      // MARK: - LLM Session

      private var llmSession: LanguageModelSession

      /// Callback to request data from Orchestrator
      /// Coach doesn't call tools directly - delegates to MemoryManager
      private let onDataRequest: (CoachQuery) async throws -> String

      // MARK: - State

      public var transcript: [Transcript.Entry] {
          llmSession.transcript
      }

      public var transcriptSize: Int {
          llmSession.transcript.count
      }

      // MARK: - Initialization

      public init(
          conversationType: ConversationType,
          capabilityCatalog: CapabilityCatalog,
          onDataRequest: @escaping (CoachQuery) async throws -> String,
          priorContext: String? = nil
      ) async throws {
          self.conversationType = conversationType
          self.style = Self.styleForType(conversationType)
          self.onDataRequest = onDataRequest

          // Build instructions based on style and capabilities
          let instructions = Self.buildInstructions(
              style: style,
              capabilities: capabilityCatalog.availableCapabilities,
              priorContext: priorContext
          )

          self.llmSession = LanguageModelSession(instructions: instructions)
          self.llmSession.prewarm()  // Apple's recommendation
      }

      // MARK: - Conversation

      public func respond(to userMessage: String) async throws -> String {
          // Send message to Coach LLM
          let response = try await llmSession.respond(to: userMessage)

          // Check if Coach is requesting data
          if let query = parseDataRequest(from: response.content) {
              print("📊 Coach → Orchestrator: \(query.intent)")

              // Delegate to Orchestrator via callback
              let dataSummary = try await onDataRequest(query)

              print("📊 Orchestrator → Coach: \(dataSummary.prefix(100))...")

              // Feed summary back to Coach
              // Coach will use this to formulate final response
              let followUp = "Data retrieved: \(dataSummary)"
              let finalResponse = try await llmSession.respond(to: followUp)
              return finalResponse.content
          }

          // Direct response (no data needed)
          return response.content
      }

      // MARK: - Instructions Builder

      private static func buildInstructions(
          style: CoachingStyle,
          capabilities: [CapabilityDescriptor],
          priorContext: String?
      ) -> String {
          var instructions = ""

          // Add prior context if resuming
          if let context = priorContext {
              instructions += """
              Previous conversation summary:
              \(context)
              
              Continue naturally from here.
              
              """
          }

          // Add role and personality
          instructions += """
          You are a thoughtful goal-setting coach helping users create meaningful goals.
          
          Your personality:
          - Warm and encouraging, but realistic
          - Ask clarifying questions to understand intent
          - Keep responses concise (2-3 sentences)
          - Use natural, conversational language
          
          """

          // Add style-specific guidance
          switch style {
          case .goalSetting:
              instructions += """
              Your focus: Help users create specific, achievable goals aligned with their values.
              
              """
          case .reflection:
              instructions += """
              Your focus: Help users reflect on progress and derive insights from their actions.
              
              """
          case .valuesAlignment:
              instructions += """
              Your focus: Help users understand how their goals connect to what matters most.
              
              """
          case .general:
              instructions += """
              Your focus: Provide guidance on whatever the user needs.
              
              """
          }

          // Add capability awareness (NOT raw tool definitions)
          instructions += """
          IMPORTANT: You do NOT have direct access to the user's data.
          
          When you need information, request it from the Orchestrator by responding with:
          {{DATA_REQUEST: <what you need>}}
          
          Available information:
          \(capabilities.map { "- \($0.userFacingDescription)" }.joined(separator: "\n"))
          
          The Orchestrator will provide a brief summary, which you'll use to respond naturally.
          
          Example:
          User: "What goals do I have?"
          You: {{DATA_REQUEST: List user's active goals with urgency}}
          [Orchestrator provides summary]
          You: "You have 3 active goals. The most urgent is your Running goal..."
          """

          return instructions
      }

      // MARK: - Query Parsing

      /// Parse Coach's response for data requests
      private func parseDataRequest(from response: String) -> CoachQuery? {
          // Look for {{DATA_REQUEST: ...}} pattern
          guard let range = response.range(of: #"\{\{DATA_REQUEST: (.+?)\}\}"#, options:
  .regularExpression) else {
              return nil
          }

          let requestText = String(response[range])
              .replacingOccurrences(of: "{{DATA_REQUEST: ", with: "")
              .replacingOccurrences(of: "}}", with: "")

          return CoachQuery(intent: requestText)
      }
  }

  3. OrchestratorSession.swift - The Librarian (Data-Facing Agent)

  //
  //  OrchestratorSession.swift
  //  ten-week-goal-app
  //
  //  PURPOSE: Data retrieval and transformation agent with full app knowledge
  //  PATTERN: Single-turn ephemeral session with tool access
  //

  import Foundation
  import FoundationModels
  import SQLiteData

  /// Data orchestration agent
  /// - Understands app's full data schema and capabilities
  /// - HAS access to all tools
  /// - Condenses tool outputs into summaries
  /// - Destroyed after each query (ephemeral)
  @available(iOS 26.0, macOS 26.0, *)
  public final class OrchestratorSession {

      private let capabilityCatalog: CapabilityCatalog
      private let database: any DatabaseWriter

      public init(
          capabilityCatalog: CapabilityCatalog,
          database: any DatabaseWriter
      ) {
          self.capabilityCatalog = capabilityCatalog
          self.database = database
      }

      /// Execute a query from Coach
      /// Creates fresh LLM session with tools, returns condensed response
      public func execute(query: CoachQuery) async throws -> OrchestratorResponse {
          // Get relevant tools for this query
          let tools = capabilityCatalog.toolsForIntent(query.intent)

          // Create fresh session with tools
          let instructions = """
          You are a data retrieval specialist. Your job:
          1. Understand the requested information
          2. Call the appropriate tools to gather data
          3. CONDENSE the results into a brief summary (2-3 sentences max)
          4. Return ONLY the summary, not raw tool outputs
          
          Focus on what's actionable and important.
          
          Available tools:
          \(tools.map { "- \($0.name): \($0.description)" }.joined(separator: "\n"))
          
          Example:
          Request: "List user's active goals with urgency"
          [You call getGoals tool, receive verbose JSON]
          Your response: "User has 3 active goals. Running (urgent, deadline in 1 week). 
                         JavaScript learning (moderate, deadline in 2 weeks). 
                         Friendships (low urgency, deadline in 3 weeks)."
          """

          let session = LanguageModelSession(
              tools: tools,
              instructions: instructions
          )

          // Single interaction
          let response = try await session.respond(to: query.intent)

          // Session will be destroyed when this function returns
          // Tool outputs don't persist!

          return OrchestratorResponse(
              summary: response.content,
              toolsCalled: extractToolNames(from: response.transcript),
              tokenCount: estimateTokens(response.transcript)
          )
      }

      private func extractToolNames(from transcript: [Transcript.Entry]) -> [String] {
          transcript.compactMap { entry in
              if case .toolCalls(let calls) = entry {
                  return calls.map { $0.name }
              }
              return nil
          }.flatMap { $0 }
      }

      private func estimateTokens(_ transcript: [Transcript.Entry]) -> Int {
          // Rough estimate for monitoring
          transcript.reduce(0) { count, entry in
              count + (String(describing: entry).count / 4)
          }
      }
  }

  4. CapabilityCatalog.swift - The Knowledge Base

  //
  //  CapabilityCatalog.swift
  //  ten-week-goal-app
  //
  //  PURPOSE: Registry of what the application can do (for Orchestrator)
  //  PATTERN: Catalog pattern with capability descriptors
  //

  import Foundation
  import FoundationModels
  import SQLiteData

  /// Central registry of app capabilities
  /// Provides Orchestrator with structured knowledge about available operations
  @available(iOS 26.0, macOS 26.0, *)
  public final class CapabilityCatalog {

      private let database: any DatabaseWriter

      // MARK: - Capability Registry

      private lazy var dataCapabilities: [DataCapability] = [
          .goals,
          .values,
          .actions,
          .measures,
          .terms
      ]

      private lazy var actionCapabilities: [ActionCapability] = [
          .createGoal,
          .checkDuplicate,
          .logAction
      ]

      private lazy var analyticsCapabilities: [AnalyticsCapability] = [
          .progress,
          .alignment,
          .trends
      ]

      // MARK: - Initialization

      public init(database: any DatabaseWriter) {
          self.database = database
      }

      // MARK: - Public Interface

      /// All available capabilities (for Coach's awareness)
      public var availableCapabilities: [CapabilityDescriptor] {
          return dataCapabilities.map { $0 as CapabilityDescriptor }
              + actionCapabilities.map { $0 as CapabilityDescriptor }
              + analyticsCapabilities.map { $0 as CapabilityDescriptor }
      }

      /// Get tools for a specific intent
      /// This is where we map Coach's natural language requests to actual tools
      public func toolsForIntent(_ intent: String) -> [any Tool] {
          let normalizedIntent = intent.lowercased()
          var tools: [any Tool] = []

          // Intent matching (could be more sophisticated with embeddings)
          if normalizedIntent.contains("goal") {
              tools.append(GetGoalsTool(database: database))
              if normalizedIntent.contains("create") || normalizedIntent.contains("new") {
                  tools.append(CreateGoalTool(database: database))
                  tools.append(CheckDuplicateGoalTool(database: database))
              }
          }

          if normalizedIntent.contains("value") {
              tools.append(GetValuesTool(database: database))
          }

          if normalizedIntent.contains("action") || normalizedIntent.contains("done") {
              tools.append(GetRecentActionsTool(database: database))
          }

          if normalizedIntent.contains("progress") || normalizedIntent.contains("how much") {
              tools.append(GetProgressTool(database: database))
          }

          if normalizedIntent.contains("align") || normalizedIntent.contains("connect") {
              tools.append(AnalyzeAlignmentTool(database: database))
          }

          if normalizedIntent.contains("measure") || normalizedIntent.contains("metric") {
              tools.append(GetMeasuresTool(database: database))
          }

          return tools
      }
  }

  // MARK: - Capability Descriptors

  /// Protocol for describing a capability
  public protocol CapabilityDescriptor {
      var name: String { get }
      var userFacingDescription: String { get }
      var category: CapabilityCategory { get }
  }

  public enum CapabilityCategory {
      case data        // Read operations
      case action      // Write operations
      case analytics   // Computed insights
  }

  // MARK: - Capability Enums

  /// Data retrieval capabilities
  public enum DataCapability: CapabilityDescriptor {
      case goals
      case values
      case actions
      case measures
      case terms

      public var name: String {
          switch self {
          case .goals: return "goals"
          case .values: return "values"
          case .actions: return "actions"
          case .measures: return "measures"
          case .terms: return "terms"
          }
      }

      public var userFacingDescription: String {
          switch self {
          case .goals:
              return "View your goals (active, completed, or on hold)"
          case .values:
              return "View your personal values and what matters most to you"
          case .actions:
              return "View actions you've taken recently"
          case .measures:
              return "View available metrics for tracking progress"
          case .terms:
              return "View your planning periods (terms)"
          }
      }

      public var category: CapabilityCategory { .data }
  }

  /// Action capabilities
  public enum ActionCapability: CapabilityDescriptor {
      case createGoal
      case checkDuplicate
      case logAction

      public var name: String {
          switch self {
          case .createGoal: return "createGoal"
          case .checkDuplicate: return "checkDuplicate"
          case .logAction: return "logAction"
          }
      }

      public var userFacingDescription: String {
          switch self {
          case .createGoal:
              return "Create a new goal with metrics and value alignment"
          case .checkDuplicate:
              return "Check if a goal already exists before creating"
          case .logAction:
              return "Log an action you've completed"
          }
      }

      public var category: CapabilityCategory { .action }
  }

  /// Analytics capabilities
  public enum AnalyticsCapability: CapabilityDescriptor {
      case progress
      case alignment
      case trends

      public var name: String {
          switch self {
          case .progress: return "progress"
          case .alignment: return "alignment"
          case .trends: return "trends"
          }
      }

      public var userFacingDescription: String {
          switch self {
          case .progress:
              return "Analyze progress toward your goals"
          case .alignment:
              return "Check how goals align with your values"
          case .trends:
              return "View trends in your actions and progress"
          }
      }

      public var category: CapabilityCategory { .analytics }
  }

  5. Communication Protocols

  //
  //  SessionMessage.swift
  //  ten-week-goal-app
  //
  //  PURPOSE: Communication protocols between Coach and Orchestrator
  //

  import Foundation

  /// Query from Coach to Orchestrator
  public struct CoachQuery {
      /// Natural language description of what's needed
      let intent: String

      /// Optional structured filters
      let filters: [String: Any]?

      /// Response format preference
      let preferredFormat: ResponseFormat

      public init(
          intent: String,
          filters: [String: Any]? = nil,
          preferredFormat: ResponseFormat = .summary
      ) {
          self.intent = intent
          self.filters = filters
          self.preferredFormat = preferredFormat
      }

      public enum ResponseFormat {
          case summary      // 2-3 sentences (default)
          case bullet       // Bulleted list
          case detailed     // Longer explanation
      }
  }

  /// Response from Orchestrator to Coach
  public struct OrchestratorResponse {
      /// Condensed summary of results
      let summary: String

      /// Tools that were called (for debugging)
      let toolsCalled: [String]

      /// Token count estimate (for monitoring)
      let tokenCount: Int

      /// Optional structured data (if Coach needs to reason about it)
      let structuredData: [String: Any]?

      public init(
          summary: String,
          toolsCalled: [String] = [],
          tokenCount: Int = 0,
          structuredData: [String: Any]? = nil
      ) {
          self.summary = summary
          self.toolsCalled = toolsCalled
          self.tokenCount = tokenCount
          self.structuredData = structuredData
      }
  }

  /// Snapshot of conversation state (for summarization)
  public struct MemorySnapshot {
      let conversationId: UUID
      let sessionNumber: Int
      let summary: String
      let keyPoints: [String]
      let userFocus: String?
      let createdAt: Date
  }

  ---
  Integration with Existing App

  GoalCoachViewModel (Refactored)

  //
  //  GoalCoachViewModel.swift
  //  ten-week-goal-app
  //
  //  REFACTORED: Now wraps MemoryManager instead of managing LLM directly
  //

  import Foundation
  import Dependencies
  import SQLiteData

  @Observable
  @MainActor
  public final class GoalCoachViewModel {

      // MARK: - Observable State (for UI)

      var messages: [ChatMessage] = []
      var inputText: String = ""
      var isThinking: Bool = false
      var errorMessage: String?
      var hasError: Bool { errorMessage != nil }

      // MARK: - Dependencies

      @ObservationIgnored
      @Dependency(\.defaultDatabase) private var database

      // MARK: - Memory Manager (NEW)

      @ObservationIgnored
      private lazy var memoryManager: MemoryManager = {
          MemoryManager(database: database)
      }()

      // MARK: - Initialization

      public init() {}

      // MARK: - Public Interface

      /// Start new conversation
      public func startConversation() async {
          isThinking = true
          errorMessage = nil

          do {
              // MemoryManager handles all session creation
              try await memoryManager.startConversation(type: .goalSetting)

              // Add welcome message
              let welcome = "👋 Hi! I'm your goal coach. What would you like to work on?"
              messages.append(ChatMessage(role: .assistant, content: welcome))

          } catch {
              errorMessage = "Failed to start: \(error.localizedDescription)"
          }

          isThinking = false
      }

      /// Send message to Coach
      public func sendMessage() async {
          guard !inputText.isEmpty else { return }

          let userMessage = inputText
          inputText = ""  // Clear immediately

          // Add to UI
          messages.append(ChatMessage(role: .user, content: userMessage))

          isThinking = true
          errorMessage = nil

          do {
              // MemoryManager handles Coach → Orchestrator → Coach flow
              let response = try await memoryManager.processMessage(userMessage)

              // Add response to UI
              messages.append(ChatMessage(role: .assistant, content: response))

          } catch {
              errorMessage = "Failed: \(error.localizedDescription)"
          }

          isThinking = false
      }

      /// Restart conversation (with summarization)
      public func restartConversation() async {
          messages.removeAll()
          await startConversation()
      }
  }

  ---
  Summary of Architecture

  Hierarchy

  MemoryManager (owns lifecycle)
    ├─ CoachSession (long-lived, user-facing)
    │    └─ Callbacks to MemoryManager for data requests
    │
    └─ Creates ephemeral OrchestratorSessions
         └─ Has tools, returns summaries, then destroyed

  Key Properties

  | Component           | Lifetime                    | Has Tools? | Token Budget | Purpose
         |
  |---------------------|-----------------------------|------------|--------------|----------------------
  -------|
  | MemoryManager       | Application lifetime        | No         | N/A          | Mediator, lifecycle
  manager |
  | CoachSession        | Multi-turn (10-20 messages) | No         | ~3000        | Natural conversation
         |
  | OrchestratorSession | Single-turn (ephemeral)     | Yes        | ~4096        | Data retrieval
         |

  Communication Flow

  User: "What should I work on?"
    ↓
  ViewModel → MemoryManager.processMessage()
    ↓
  MemoryManager → CoachSession.respond()
    ↓
  CoachSession (LLM): "I need to see their goals and progress"
  CoachSession emits: {{DATA_REQUEST: goals with urgency and progress}}
    ↓
  MemoryManager.handleDataRequest() creates OrchestratorSession
    ↓
  OrchestratorSession calls GetGoalsTool, GetProgressTool
  OrchestratorSession receives verbose JSON (500+ tokens)
  OrchestratorSession condenses: "3 goals. Running urgent (20% done)..."
    ↓
  OrchestratorSession destroyed ← Tool outputs gone!
    ↓
  MemoryManager returns summary to CoachSession
    ↓
  CoachSession (LLM): "Focus on your Running goal - it's urgent and behind schedule"
    ↓
  MemoryManager → ViewModel → User

  ---

⏺ This architecture gives you:

  1. ✅ Token efficiency - Tool outputs are ephemeral
  2. ✅ Clean separation - Each agent has a clear role
  3. ✅ Scalability - Easy to add new capabilities
  4. ✅ Natural UX - User sees seamless conversation
  5. ✅ Database integration - Maps to your schema
  6. ✅ Extensibility - Can add more specialized agents (e.g., ReflectionCoach, AnalyticsOrchestrator)

  What do you think? Should we refine anything before implementation?



