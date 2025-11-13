# Foundation Models Implementation Guide
## On-Device LLM Integration for Ten Week Goal App

**Written by Claude Code on 2025-11-11**
**Research Source:** Apple Developer Documentation - Foundation Models Framework
**Target Platforms:** iOS 26+, iPadOS 26+, macOS 26+, visionOS 26+

---

## Table of Contents

1. [Overview](#overview)
2. [Use Cases for Ten Week Goal App](#use-cases-for-ten-week-goal-app)
3. [Core Architecture](#core-architecture)
4. [Tool Protocol Implementation](#tool-protocol-implementation)
5. [Guided Generation with @Generable Macro](#guided-generation-with-generable-macro)
6. [Safety & Privacy Considerations](#safety--privacy-considerations)
7. [Implementation Patterns for Goal Setting](#implementation-patterns-for-goal-setting)
8. [Context Window Management](#context-window-management)
9. [References](#references)

---

## Overview

The Foundation Models framework provides access to Apple's on-device large language model that powers Apple Intelligence. The framework specializes in:

- **Language understanding and text generation**
- **Structured output via guided generation** (@Generable macro)
- **Tool calling** (function calling pattern for dynamic data access)

> "The Foundation Models framework provides access to Apple's on-device large language model that powers Apple Intelligence to help you perform intelligent tasks specific to your use case. The text-based on-device model identifies patterns that allow for generating new text that's appropriate for the request you make, and it can make decisions to call code you write to perform specialized tasks."
>
> — [Foundation Models Overview](https://developer.apple.com/documentation/foundationmodels)

### Key Benefits for Goal Setting Apps

1. **Privacy-First**: All processing happens on-device, user data never leaves the device
2. **Type-Safe Output**: Use Swift structs instead of parsing raw strings
3. **Dynamic Context**: Tools can query user's existing goals, values, and progress
4. **Natural Conversation**: Multi-turn dialogues with session state management

### Platform Availability

**Framework Availability:**
- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+
- visionOS 26.0+

**Device Requirements:**

The Foundation Models framework requires Apple Intelligence-compatible devices:

- **iPhone:** iPhone 15 Pro or later, iPhone 16 or later
- **iPad:** All iPads with M-series Apple silicon chips (iPad Pro M1+, iPad Air M1+)
- **Mac:** All Macs with M-series Apple silicon chips (M1, M2, M3, M4)
- **Vision Pro:** Apple Vision Pro with visionOS 2.4+ (Apple Intelligence introduced March 31, 2025)

**User Requirements:**
- Apple Intelligence must be enabled in System Settings
- ~7 GB of on-device storage required for the language model
- No network connection required (fully offline capable)

**Availability Checking:**

```swift
let model = SystemLanguageModel.default

switch model.availability {
case .available:
    // Foundation Models ready to use
    break
case .unavailable(.deviceNotEligible):
    // Device doesn't support Apple Intelligence (e.g., Intel Mac, older iPhone)
    showFallbackExperience()
case .unavailable(.appleIntelligenceNotEnabled):
    // Device supports it but user hasn't enabled Apple Intelligence
    promptUserToEnableAppleIntelligence()
case .unavailable(.modelNotReady):
    // Model is downloading or system reasons
    showLoadingState()
case .unavailable(let other):
    // Unknown reason
    handleUnknownUnavailability(other)
}
```

> **Note:** The Foundation Models framework is "tightly integrated with Swift" and provides "free of cost" AI inference. The 3 billion parameter on-device model operates entirely locally, ensuring user privacy and offline functionality.
>
> — [Apple Newsroom: Foundation Models Framework](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)

---

## Use Cases for Ten Week Goal App

### 1. Facilitated Goal Setting (Primary Use Case)

**Scenario:** User wants to create a new goal but isn't sure how to structure it.

**LLM Capabilities:**
- Conversational goal refinement ("What do you want to achieve?")
- Suggest measurable targets based on user's PersonalValues
- Recommend reasonable timelines (10-week term structure)
- Generate actionable ExpectationMeasures

**Example Flow:**
```
User: "I want to get better at writing"
LLM: [calls GetUserValuesToolâ†'["creativity", "professional_development"]]
LLM: "I see you value creativity and professional development. Let's make this measurable.
     Would you like to track:
     - Words written per week?
     - Writing sessions completed?
     - Projects finished?"
User: "Words written"
LLM: [generates GoalFormData with targetValue: 5000 words/week]
```

### 2. Values Alignment & Guidance

**Scenario:** User reflects on their goals and needs encouragement aligned with their values.

**LLM Capabilities:**
- Query user's PersonalValues hierarchy
- Analyze action history for patterns
- Generate personalized encouragement messages
- Suggest adjustments to improve value alignment

**Example:**
```swift
struct AlignmentCoachTool: Tool {
    let name = "analyzeValueAlignment"
    let description = "Analyze how user's recent actions align with their stated values"

    @Generable
    struct Arguments {
        @Guide(description: "The value ID to analyze alignment with")
        var valueId: UUID

        @Guide(description: "Number of days to look back", .range(1...30))
        var daysBack: Int
    }

    func call(arguments: Arguments) async throws -> String {
        // Query database for actions related to this value
        let actions = try await fetchRecentActions(
            valueId: arguments.valueId,
            days: arguments.daysBack
        )

        return """
        Found \(actions.count) actions in last \(arguments.daysBack) days
        aligned with value '\(value.title)'.
        Total time invested: \(totalMinutes) minutes.
        """
    }
}
```

### 3. Weekly/Daily Reflection Prompts

**Scenario:** Generate contextual reflection questions based on user's progress.

**LLM Capabilities:**
- Review current term goals
- Check progress on measurements
- Generate specific, personalized reflection questions

---

## Core Architecture

### Foundation Models Components

```swift
// 1. System Language Model (singleton for app)
let model = SystemLanguageModel.default

// 2. Language Model Session (one per conversation)
let session = LanguageModelSession(
    model: model,
    instructions: "You are a supportive goal-setting coach...",
    tools: [GetUserGoalsTool(), CreateGoalTool(), GetPersonalValuesTool()]
)

// 3. Prompts (user messages)
let prompt = Prompt("Help me set a goal for improving my health")

// 4. Response (model output)
let response = try await session.respond(to: prompt)
```

### Session Lifecycle

> "A session is a single context that you use to generate content with, and maintains state between requests. You can reuse the existing instance or create a new one each time you call the model."
>
> — [LanguageModelSession Documentation](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)

**Pattern for Goal Setting Conversation:**

```swift
@Observable
@MainActor
final class GoalSettingCoachViewModel {
    private var session: LanguageModelSession?
    var messages: [ConversationMessage] = []

    func startConversation() {
        // Create new session for fresh goal-setting conversation
        session = LanguageModelSession(
            model: .default,
            instructions: GoalCoachInstructions.goalSetting,
            tools: createGoalSettingTools()
        )
    }

    func sendMessage(_ userInput: String) async throws {
        guard let session = session else { return }

        let prompt = Prompt(userInput)
        messages.append(.user(userInput))

        let response = try await session.respond(to: prompt)
        messages.append(.assistant(response.content))
    }

    func endConversation() {
        // Session is automatically cleaned up
        session = nil
    }
}
```

---

## Tool Protocol Implementation

### Tool Protocol Signature

```swift
protocol Tool<Arguments, Output> : Sendable
```

> "A tool that a model can call to gather information at runtime or perform side effects."
>
> — [Tool Protocol Documentation](https://developer.apple.com/documentation/foundationmodels/tool)

### Required Protocol Members

```swift
protocol Tool {
    associatedtype Arguments: ConvertibleFromGeneratedContent
    associatedtype Output: PromptRepresentable

    var name: String { get }
    var description: String { get }

    func call(arguments: Arguments) async throws -> Output
}
```

### Sendable Requirement

> "Tools must conform to Sendable so the framework can run them concurrently. If the model needs to pass the output of one tool as the input to another, it executes back-to-back tool calls."
>
> — [Tool Protocol Documentation](https://developer.apple.com/documentation/foundationmodels/tool)

**Why Sendable Matters:**
- Tools run concurrently for parallel operations
- Model can execute multiple tool calls at once (e.g., fetch multiple goals simultaneously)
- Must be safe to share across concurrency domains

### Complete Tool Example: Fetching User Goals

```swift
/// Tool for retrieving user's active goals with filtering
struct GetActiveGoalsTool: Tool {
    let name = "getActiveGoals"
    let description = """
        Retrieve the user's active goals, optionally filtered by term or value alignment. \
        Use this to understand what the user is currently working on.
        """

    // Arguments must be @Generable for type-safe generation
    @Generable
    struct Arguments {
        @Guide(description: "Optional term ID to filter goals by specific term")
        var termId: UUID?

        @Guide(description: "Optional value ID to find goals aligned with specific value")
        var valueId: UUID?

        @Guide(description: "Maximum number of goals to return", .range(1...10))
        var limit: Int = 5
    }

    // Output should be PromptRepresentable (String, GeneratedContent, or Encodable)
    struct GoalSummary: Encodable {
        var id: UUID
        var title: String
        var targetDate: Date
        var alignedValues: [String]
        var currentProgress: String?
    }

    // Dependency injection (passed during tool creation)
    private let database: any DatabaseReader

    init(database: any DatabaseReader) {
        self.database = database
    }

    func call(arguments: Arguments) async throws -> [GoalSummary] {
        return try await database.read { db in
            var query = Goal
                .join(Expectation.all) { $0.expectationId.eq($1.id) }
                .limit(arguments.limit)

            // Apply filters if provided
            if let termId = arguments.termId {
                query = query
                    .join(TermGoalAssignment.all) { $0.id.eq($1.goalId) }
                    .where { $0[TermGoalAssignment.self].termId.eq(termId) }
            }

            if let valueId = arguments.valueId {
                query = query
                    .join(GoalRelevance.all) { $0.id.eq($1.goalId) }
                    .where { $0[GoalRelevance.self].valueId.eq(valueId) }
            }

            let goals = try query.fetchAll(db)

            return goals.map { goal in
                GoalSummary(
                    id: goal.id,
                    title: goal.expectation.title ?? "Untitled Goal",
                    targetDate: goal.targetDate ?? Date(),
                    alignedValues: [], // Fetch from GoalRelevance
                    currentProgress: calculateProgress(for: goal, in: db)
                )
            }
        }
    }

    private func calculateProgress(for goal: Goal, in db: Database) -> String? {
        // Calculate progress based on ActionGoalContributions
        // Return formatted string like "3 of 5 actions completed"
        return nil // Simplified for example
    }
}
```

### Tool Descriptions Best Practices

> "When you provide descriptions to generable properties, you help the model understand the semantics of the arguments. Keep descriptions as short as possible because long descriptions take up context size and can introduce latency."
>
> — [Expanding Generation with Tool Calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling)

**Guidelines:**
- ✅ **Be concise**: "Filter by term ID" not "This optional parameter allows filtering..."
- ✅ **Explain when to use**: "Use this when user asks about specific goals"
- ✅ **Describe semantics**: "aligned values" not just "values"
- ❌ **Avoid redundancy**: Don't repeat what the parameter name says

### Error Handling in Tools

```swift
enum GoalToolError: Error {
    case databaseUnavailable
    case invalidGoalId(UUID)
    case accessDenied
}

func call(arguments: Arguments) async throws -> [GoalSummary] {
    guard isDatabaseReady else {
        throw GoalToolError.databaseUnavailable
    }

    // Or return a descriptive string for the model to interpret
    guard isDatabaseReady else {
        return "Cannot access goals database. Please try again later."
    }

    // Tool execution continues...
}
```

> "You can throw errors from your tools to escape calls when you detect something is wrong, like when the person using your app doesn't allow access to the required data or a network call is taking longer than expected. Alternatively, your tool can return a string that briefly tells the model what didn't work, like 'Cannot access the database.'"
>
> — [Expanding Generation with Tool Calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling)

**Catching Tool Errors:**

```swift
do {
    let response = try await session.respond(to: prompt)
} catch let error as LanguageModelSession.ToolCallError {
    print("Tool '\(error.tool.name)' failed")

    if case GoalToolError.databaseUnavailable = error.underlyingError {
        // Show specific UI message
        showAlert("Database temporarily unavailable")
    }
}
```

---

## Guided Generation with @Generable Macro

### What is Guided Generation?

> "When you perform a request, the model returns a raw string in its natural language format. Raw strings require you to manually parse the details you want. Instead of working with raw strings, the framework provides guided generation, which gives strong guarantees that the response is in a format you expect."
>
> — [Generating Swift Data Structures](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation)

**Key Concept:** The framework uses **constrained sampling** to prevent malformed output.

### @Generable Macro Usage

```swift
@Generable(description: "A complete goal with measurable targets")
struct GoalCreationData {
    @Guide(description: "Clear, specific title for the goal")
    var title: String

    @Guide(description: "Detailed description of what success looks like")
    var detailedDescription: String?

    @Guide(description: "Target completion date")
    var targetDate: Date

    @Guide(description: "List of specific, measurable targets", .count(1...5))
    var measures: [MeasureTarget]

    @Guide(description: "Values this goal aligns with", .count(1...3))
    var alignedValueIds: [UUID]
}

@Generable(description: "A measurable target for tracking goal progress")
struct MeasureTarget {
    @Guide(description: "What to measure (e.g., 'words written', 'workouts completed')")
    var measureName: String

    @Guide(description: "Target numeric value", .range(1...1000))
    var targetValue: Double

    @Guide(description: "Unit of measurement (e.g., 'words', 'sessions', 'hours')")
    var unit: String
}
```

### @Guide Constraints

**Available Constraints:**

| Constraint | Usage | Example |
|------------|-------|---------|
| `.range(_:)` | Numeric bounds | `.range(1...100)` |
| `.count(_:)` | Array/String length | `.count(3...10)` |
| `.maximumCount(_:)` | Max array length | `.maximumCount(5)` |

**Example from Documentation:**

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    var name: String

    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int

    @Guide(description: "A one sentence profile about the cat's personality")
    var profile: String
}
```

### Requesting Structured Output

```swift
let session = LanguageModelSession(
    instructions: "You are a goal-setting coach",
    tools: [GetPersonalValuesTool(), GetCurrentTermTool()]
)

let prompt = Prompt("""
    The user said: 'I want to write more consistently'.
    Create a structured goal with 2-3 measurable targets.
    """)

// Model returns GoalCreationData, NOT a raw string
let goalData = try await session.respond(
    to: prompt,
    generating: GoalCreationData.self
)

// Use type-safe properties directly
print(goalData.title) // "Write consistently for 10 weeks"
print(goalData.measures.count) // 2 (constrained by .count(1...5))
```

### Nesting Generable Types

> "You can nest custom Generable types inside other Generable types, and mark enumerations with associated values as Generable. The Generable macro ensures that all associated and nested values are themselves generable."
>
> — [Generating Swift Data Structures](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation)

**Complex Example:**

```swift
@Generable
struct CompleteTerm {
    var termNumber: Int
    var theme: String?
    var goals: [GoalCreationData] // Nested @Generable
}

@Generable
enum GoalPriority {
    case high(reason: String)
    case medium
    case low
}

@Generable
struct PrioritizedGoal {
    var goal: GoalCreationData
    var priority: GoalPriority // Enum with associated values
}
```

### Dynamic Schemas (Runtime Flexibility)

Use `DynamicGenerationSchema` when output structure isn't known until runtime:

```swift
// User has custom measures in their database
let userMeasures = try await fetchUserMeasures(from: database)

let measureSchema = DynamicGenerationSchema(
    name: "SelectedMeasure",
    anyOf: userMeasures.map { $0.title } // ["Words Written", "Pages Read", etc.]
)

let goalSchema = DynamicGenerationSchema(
    name: "GoalWithUserMeasure",
    properties: [
        DynamicGenerationSchema.Property(
            name: "selectedMeasure",
            schema: measureSchema
        ),
        DynamicGenerationSchema.Property(
            name: "targetValue",
            schema: DynamicGenerationSchema(type: .number)
        )
    ]
)

let schema = try GenerationSchema(root: goalSchema, dependencies: [])
let response = try await session.respond(to: prompt, schema: schema)

// Decode at runtime
let selectedMeasure = try response.value(String.self, forProperty: "selectedMeasure")
let targetValue = try response.value(Double.self, forProperty: "targetValue")
```

---

## Safety & Privacy Considerations

### Built-In Safety Layers

> "The Foundation Models framework has two base layers of safety, where the framework uses:
> 1. Pre-training safety mitigations from Apple's model training
> 2. SystemLanguageModel.Guardrails that check inputs and outputs"
>
> — [Improving the Safety of Generative Model Output](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output)

### Guardrail Violations

```swift
do {
    let response = try await session.respond(to: userPrompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
    // System safety triggered
    showMessage("This request cannot be processed. Please rephrase.")
}
```

### Model Refusals

**String Response Refusal:**
> "When you generate a string response, and the model refuses a request, it generates a message that begins with a refusal like 'Sorry, I can't help with'."

**Structured Output Refusal:**

```swift
do {
    let goalData = try await session.respond(
        to: prompt,
        generating: GoalCreationData.self
    )
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
    // Get explanation asynchronously
    if let explanation = try? await refusal.explanation {
        showAlert("Cannot create goal: \(explanation)")
    }
}
```

### Safety Design Patterns for Goal Setting

#### 1. Bounded Input (Most Safe)

```swift
enum GoalTopicCategory: String, CaseIterable {
    case health = "Health & Fitness"
    case career = "Career & Professional"
    case creative = "Creative & Artistic"
    case relationships = "Relationships & Social"
    case learning = "Learning & Education"
}

// User picks from list, no free-form input
let selectedTopic = GoalTopicCategory.career
let prompt = "Suggest a \(selectedTopic.rawValue) goal for a 10-week term"
```

#### 2. Guided Instructions (Recommended)

> "Consider adding detailed session Instructions that tell the model how to handle sensitive content. The language model prioritizes following its instructions over any prompt, so instructions are an effective tool for improving safety."
>
> — [Improving the Safety of Generative Model Output](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output)

```swift
let instructions = """
    You are a supportive goal-setting coach for a personal development app.

    ALWAYS respond in a respectful, encouraging way.

    If the user's goal involves sensitive topics (health conditions, relationships, finances),
    you MUST acknowledge their goal respectfully but suggest they consult appropriate
    professionals for detailed guidance.

    Focus on helping users create SMART goals:
    - Specific: Clear and well-defined
    - Measurable: Can be tracked with numbers
    - Achievable: Realistic within 10 weeks
    - Relevant: Aligned with their stated values
    - Time-bound: Fits within their current term

    Keep responses concise (2-3 sentences unless asking clarifying questions).
    """
```

#### 3. Prompt Templates (Wrap User Input)

```swift
let userInput = "I want to improve my life" // Open-ended

let prompt = Prompt("""
    A user wants to set a goal and said: "\(userInput)"

    Ask 2-3 specific questions to help them clarify what measurable outcomes
    they want to achieve in the next 10 weeks.
    """)
```

#### 4. Output Constraints (Enum-Based Safety)

```swift
@Generable
enum GoalAssessment {
    case appropriate(reasoning: String)
    case needsRefinement(suggestions: String)
    case outsideScope(professionalGuidance: String)
}

// Model is constrained to these three outcomes
let assessment = try await session.respond(
    to: "Assess if this goal is appropriate: \(userGoalDescription)",
    generating: GoalAssessment.self
)

switch assessment {
case .appropriate(let reasoning):
    proceedWithGoalCreation()
case .needsRefinement(let suggestions):
    showRefinementPrompt(suggestions)
case .outsideScope(let guidance):
    showProfessionalGuidanceMessage(guidance)
}
```

### Privacy Considerations

**All Processing is On-Device:**
- No user data sent to servers
- No network calls required
- User data never leaves their device

**Best Practices:**
- ✅ Always query database with user permissions
- ✅ Show transparency about what data the LLM accesses
- ✅ Allow users to review generated content before saving
- ✅ Respect user's PersonalValues privacy settings

---

## Implementation Patterns for Goal Setting

### Pattern 1: Conversational Goal Builder

```swift
@Observable
@MainActor
final class ConversationalGoalBuilderViewModel {
    private var session: LanguageModelSession?
    private var conversationState: GoalBuildingState = .initial

    var messages: [Message] = []
    var isSaving: Bool = false

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    enum GoalBuildingState {
        case initial
        case gatheringDetails
        case proposingMeasures
        case confirmingValues
        case complete(GoalCreationData)
    }

    func startGoalConversation() {
        let tools = [
            GetPersonalValuesTool(database: database),
            GetCurrentTermTool(database: database),
            GetExistingMeasuresTool(database: database)
        ]

        session = LanguageModelSession(
            model: .default,
            instructions: GoalCoachInstructions.conversationalGoalBuilder,
            tools: tools
        )

        // Initial prompt from system
        Task {
            let greeting = try await session?.respond(
                to: Prompt("Greet the user and ask what they'd like to achieve")
            )
            if let content = greeting?.content {
                messages.append(.assistant(content))
            }
        }
    }

    func sendUserMessage(_ text: String) async throws {
        guard let session = session else { return }

        messages.append(.user(text))

        // Check if we have enough info to generate structured data
        if conversationState == .confirmingValues {
            // Request structured output
            let goalData = try await session.respond(
                to: Prompt("""
                    Generate a complete GoalCreationData structure based on our conversation.
                    """),
                generating: GoalCreationData.self
            )

            conversationState = .complete(goalData)
            messages.append(.structuredGoal(goalData))
        } else {
            // Continue conversation
            let response = try await session.respond(to: Prompt(text))
            messages.append(.assistant(response.content))

            // Update state based on response content
            updateConversationState(from: response.content)
        }
    }

    func createGoalFromData(_ goalData: GoalCreationData) async throws {
        isSaving = true
        defer { isSaving = false }

        // Convert LLM output to FormData
        let formData = try await convertToFormData(goalData)

        // Use existing coordinator
        let coordinator = GoalCoordinator(database: database)
        let goal = try await coordinator.create(from: formData)

        // Reset conversation
        session = nil
        conversationState = .initial
    }
}
```

### Pattern 2: Values Alignment Coach

```swift
@Observable
@MainActor
final class ValuesAlignmentCoachViewModel {
    private var session: LanguageModelSession?

    var analysisReport: String?
    var suggestions: [AlignmentSuggestion] = []

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @Generable
    struct AlignmentSuggestion {
        @Guide(description: "The personal value this suggestion relates to")
        var valueName: String

        @Guide(description: "Current alignment strength", .range(1...10))
        var currentAlignment: Int

        @Guide(description: "Specific, actionable suggestion to improve alignment")
        var suggestion: String

        @Guide(description: "Expected time investment in hours per week", .range(1...20))
        var timeCommitment: Int
    }

    func analyzeAlignment(for userId: UUID) async throws {
        let tools = [
            GetUserValuesTool(database: database),
            GetRecentActionsTool(database: database, daysBack: 30),
            GetActiveGoalsTool(database: database)
        ]

        session = LanguageModelSession(
            model: .default,
            instructions: ValuesCoachInstructions.alignmentAnalysis,
            tools: tools
        )

        // Request structured analysis
        let analysis = try await session?.respond(
            to: Prompt("""
                Analyze the user's recent actions and current goals.
                Identify their top 3 personal values and provide alignment suggestions.
                """),
            generating: [AlignmentSuggestion].self
        )

        self.suggestions = analysis ?? []

        // Generate narrative report
        let report = try await session?.respond(
            to: Prompt("""
                Write a brief, encouraging summary (3-4 sentences) of the user's
                overall values alignment based on the suggestions you just provided.
                """)
        )

        self.analysisReport = report?.content
    }
}
```

### Pattern 3: Weekly Reflection Generator

```swift
struct WeeklyReflectionTool: Tool {
    let name = "generateReflectionPrompts"
    let description = "Generate personalized reflection questions based on user's weekly progress"

    @Generable
    struct Arguments {
        @Guide(description: "Term ID to reflect on")
        var termId: UUID

        @Guide(description: "Week number within the term", .range(1...10))
        var weekNumber: Int
    }

    @Generable
    struct ReflectionPrompts {
        @Guide(description: "Progress reflection question")
        var progressQuestion: String

        @Guide(description: "Values alignment question")
        var valuesQuestion: String

        @Guide(description: "Forward-looking planning question")
        var planningQuestion: String

        @Guide(description: "Celebration prompt for wins this week")
        var celebrationPrompt: String
    }

    private let database: any DatabaseReader

    func call(arguments: Arguments) async throws -> ReflectionPrompts {
        let session = LanguageModelSession(
            instructions: """
                Generate thoughtful, specific reflection questions based on the user's
                actual progress and goals. Make questions encouraging but honest.
                """,
            tools: [
                GetTermGoalsTool(database: database),
                GetWeeklyActionsTool(database: database)
            ]
        )

        let prompts = try await session.respond(
            to: Prompt("""
                Generate reflection prompts for term \(arguments.termId), week \(arguments.weekNumber).
                Use the tools to see what goals they have and what actions they took this week.
                """),
            generating: ReflectionPrompts.self
        )

        return prompts
    }
}
```

---

## Context Window Management

### Understanding Token Limits

> "Like other Large Language Models (LLMs), Apple's on-device foundation model processes text in units called tokens. A token corresponds to roughly three to four characters in Latin alphabet languages."
>
> — [TN3193: Managing Context Window](https://developer.apple.com/documentation/Technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)

**What Consumes Tokens:**
1. Session instructions
2. All prompts in the conversation
3. All model responses
4. Tool schemas (name, description, parameters)
5. Tool inputs and outputs
6. Generable type schemas (JSON schema representation)

### Exceeding Context Window

```swift
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.exceededContextWindowSize(let details) {
    print("Context window exceeded: \(details)")

    // Solution: Start a new session
    startNewSession()
}
```

### Optimization Strategies

#### 1. Keep Tool Descriptions Concise

```swift
// ❌ Too verbose
let description = """
    This tool is used to retrieve the user's currently active goals from the database.
    It can optionally filter these goals by a specific term identifier if provided,
    or by a value identifier to find goals that are aligned with that particular value.
    """

// ✅ Concise and clear
let description = """
    Retrieve active goals, optionally filtered by term or aligned value.
    """
```

#### 2. Minimize Generable Complexity

```swift
// ❌ Too complex (large schema)
@Generable
struct DetailedGoal {
    var id: UUID
    var title: String
    var description: String
    var createdAt: Date
    var updatedAt: Date
    var expectation: ExpectationData
    var measures: [MeasureData]
    var values: [ValueData]
    var actions: [ActionData]
    var milestones: [MilestoneData]
}

// ✅ Simplified (smaller schema)
@Generable
struct GoalSummary {
    var title: String
    var targetDate: Date
    var measureCount: Int
    var primaryValue: String
}
```

#### 3. Break Long Conversations into New Sessions

```swift
func handleLongConversation() {
    if messages.count > 10 {
        // Summarize conversation so far
        let summary = try await session?.respond(
            to: Prompt("Summarize our conversation in 2-3 sentences")
        )

        // Start new session with summary as context
        session = LanguageModelSession(
            instructions: """
                Previous conversation summary: \(summary?.content ?? "")
                Continue helping the user refine their goal.
                """
        )
    }
}
```

#### 4. Use Tool Calls Across Sessions

> "When you encounter the context window limit, consider breaking up tool calls across new LanguageModelSession instances."
>
> — [Tool Documentation](https://developer.apple.com/documentation/foundationmodels/tool)

```swift
// Session 1: Gather data
let dataSession = LanguageModelSession(tools: [GetDataTool()])
let data = try await dataSession.respond(to: "Get user's goals")

// Session 2: Generate recommendations (fresh context)
let recommendSession = LanguageModelSession(
    instructions: "Based on this data: \(data), provide recommendations"
)
let recommendations = try await recommendSession.respond(to: prompt)
```

---

## References

### Apple Developer Documentation

1. **Foundation Models Framework Overview**
   https://developer.apple.com/documentation/foundationmodels

   > "Perform tasks with the on-device model that specializes in language understanding, structured output, and tool calling."

2. **Generating Content and Performing Tasks**
   https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

   > "To call the model with a prompt, call respond(to:options:) on your session."

3. **Tool Protocol**
   https://developer.apple.com/documentation/foundationmodels/tool

   > "A tool that a model can call to gather information at runtime or perform side effects."

4. **Expanding Generation with Tool Calling**
   https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

   > "Tool calling gives the model the ability to call your code to incorporate up-to-date information like recent events and data from your app."

5. **Generating Swift Data Structures with Guided Generation**
   https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

   > "The framework uses constrained sampling when generating output, which defines the rules on what the model can generate."

6. **Improving the Safety of Generative Model Output**
   https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

   > "The Foundation Models framework has two base layers of safety, where the framework uses pre-training safety mitigations and SystemLanguageModel.Guardrails."

7. **TN3193: Managing the On-Device Foundation Model's Context Window**
   https://developer.apple.com/documentation/Technotes/tn3193-managing-the-on-device-foundation-model-s-context-window

   > "With the Foundation Models framework, you interact with the model using instructions, prompts, tool calling, and Generable types."

### Code Examples Sources

All code examples in this document are either:
- Direct quotes from Apple Developer Documentation (cited above)
- Adaptations of Apple's examples for the Ten Week Goal App domain
- Original implementations following Apple's documented patterns

### Next Steps for Implementation

1. **Phase 1 - Basic Integration**
   - [ ] Create `GoalSettingCoachViewModel` with simple conversation flow
   - [ ] Implement 3-5 basic tools (`GetGoalsTool`, `GetValuesTool`, `GetCurrentTermTool`)
   - [ ] Test model availability checking (`SystemLanguageModel.availability`)

2. **Phase 2 - Structured Output**
   - [ ] Define `@Generable` types for goal creation (`GoalCreationData`)
   - [ ] Implement guided generation for measurable targets
   - [ ] Add safety guardrails and error handling

3. **Phase 3 - Advanced Features**
   - [ ] Weekly reflection prompt generation
   - [ ] Values alignment analysis
   - [ ] Dynamic schema for user's custom measures

4. **Phase 4 - UI/UX**
   - [ ] Conversational UI with message bubbles
   - [ ] Real-time typing indicators
   - [ ] Review/edit screen for generated goals before saving

---

## Platform-Specific Considerations

### Cross-Platform Development Notes

The Foundation Models framework APIs are **identical across iOS, iPadOS, macOS, and visionOS**. No platform-specific code is required for basic functionality.

**Unified API:**
```swift
// Same code works on all platforms
let model = SystemLanguageModel.default
let session = LanguageModelSession(model: model)
let response = try await session.respond(to: prompt)
```

**Platform Differences:**

1. **UI Presentation:**
   - iOS/iPadOS: Consider bottom sheet or modal presentation for AI coach
   - macOS: Native window or inspector panel for conversations
   - visionOS: Spatial placement of conversation UI, immersive experiences

2. **Storage Requirements:**
   - All platforms require ~7 GB for the language model
   - Mac users with limited storage may need to manage space
   - Vision Pro has ample storage but check availability anyway

3. **Input Methods:**
   - iOS/iPadOS: Touch keyboard, voice dictation
   - macOS: Physical keyboard, more conducive to longer conversations
   - visionOS: Eye tracking + hand gestures, voice input

4. **Performance Characteristics:**
   - M-series Macs (especially M3/M4): Fastest inference
   - iPhone 15 Pro/16: Good performance, watch battery impact
   - Vision Pro: Optimized for spatial computing, good performance

**Recommendation:** Build UI using SwiftUI with platform-adaptive layouts. The AI functionality itself requires no platform-specific code.

---

**Document Version:** 1.0
**Last Updated:** 2025-11-11
**Target Platforms:** iOS 26+, iPadOS 26+, macOS 26+, visionOS 26+, Swift 6.2
**Framework Version:** Foundation Models 1.0 (iOS/iPadOS/macOS/visionOS 26.0+)
