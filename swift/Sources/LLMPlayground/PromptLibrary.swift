//  PromptLibrary.swift
//  Curated example prompts for testing Foundation Models
//
//  Written by Claude Code on 2025-10-24
//
//  This library contains pre-built prompts organized by category,
//  making it easy to test different aspects of the LLM's capabilities.

import Foundation

// MARK: - Prompt Example Models

/// A single example prompt with metadata
struct PromptExample {
    let category: String
    let title: String
    let prompt: String
    let expectedTool: String?

    init(category: String, title: String, prompt: String, expectedTool: String? = nil) {
        self.category = category
        self.title = title
        self.prompt = prompt
        self.expectedTool = expectedTool
    }
}

// MARK: - Prompt Library

/// Collection of curated example prompts for testing
struct PromptLibrary {

    // MARK: - All Examples

    static var allExamples: [PromptExample] {
        return reflectiveQueries + analyticalQueries + exploratoryQueries + specificQueries
    }

    // MARK: - Reflective Queries

    /// Prompts that encourage thoughtful analysis and reflection
    static let reflectiveQueries: [PromptExample] = [
        PromptExample(
            category: "Reflective",
            title: "July Reflection",
            prompt: "What made July meaningful for me? Help me understand what I accomplished and what patterns you notice.",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Reflective",
            title: "Values Alignment",
            prompt: "Looking at my values and goals, what patterns do you see? Are my actions aligned with what matters most to me?",
            expectedTool: "getValues, getGoals, getActions"
        ),
        PromptExample(
            category: "Reflective",
            title: "Progress Check",
            prompt: "How am I doing overall? What's going well and where might I need to adjust my focus?",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Reflective",
            title: "Term Review",
            prompt: "Can you help me reflect on my current ten-week term? What themes are emerging?",
            expectedTool: "getTerms, getGoals, getActions"
        )
    ]

    // MARK: - Analytical Queries

    /// Prompts that request specific analysis and calculations
    static let analyticalQueries: [PromptExample] = [
        PromptExample(
            category: "Analytical",
            title: "Goal Progress Analysis",
            prompt: "Which of my goals have I made the most progress on? Show me the numbers.",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Analytical",
            title: "Time Pattern Analysis",
            prompt: "What patterns do you see in when I take action? Are there certain days or times when I'm most productive?",
            expectedTool: "getActions"
        ),
        PromptExample(
            category: "Analytical",
            title: "Goal Type Breakdown",
            prompt: "Show me a breakdown of my goals by type. How many SmartGoals vs regular goals vs milestones do I have?",
            expectedTool: "getGoals"
        ),
        PromptExample(
            category: "Analytical",
            title: "Completion Rate",
            prompt: "What's my overall completion rate? Which goals am I on track to finish and which need more attention?",
            expectedTool: "getGoals, getActions"
        )
    ]

    // MARK: - Exploratory Queries

    /// Prompts that explore relationships and insights
    static let exploratoryQueries: [PromptExample] = [
        PromptExample(
            category: "Exploratory",
            title: "Unlinked Actions",
            prompt: "Are there actions I've taken that don't clearly connect to any of my goals? What might that tell us?",
            expectedTool: "getActions, getGoals"
        ),
        PromptExample(
            category: "Exploratory",
            title: "Neglected Goals",
            prompt: "Which goals have I set but not taken action on yet? Help me understand why that might be.",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Exploratory",
            title: "Value Gaps",
            prompt: "Looking at my values and my actual goals, are there any values I say matter to me but haven't set goals around?",
            expectedTool: "getValues, getGoals"
        ),
        PromptExample(
            category: "Exploratory",
            title: "Momentum Check",
            prompt: "Where do I have momentum right now? What areas are moving forward versus stagnant?",
            expectedTool: "getActions, getGoals"
        )
    ]

    // MARK: - Specific Queries

    /// Prompts that test specific data retrieval
    static let specificQueries: [PromptExample] = [
        PromptExample(
            category: "Specific",
            title: "Recent Actions",
            prompt: "What have I accomplished in the last week?",
            expectedTool: "getActions"
        ),
        PromptExample(
            category: "Specific",
            title: "Upcoming Milestones",
            prompt: "What milestones are coming up soon? Are there any deadlines I should be aware of?",
            expectedTool: "getGoals"
        ),
        PromptExample(
            category: "Specific",
            title: "Current Term Goals",
            prompt: "What goals am I working on in my current term?",
            expectedTool: "getTerms, getGoals"
        ),
        PromptExample(
            category: "Specific",
            title: "Top Values",
            prompt: "What are my highest priority values? What do I say matters most to me?",
            expectedTool: "getValues"
        )
    ]

    // MARK: - Tool Testing

    /// Prompts specifically designed to test individual tools
    static let toolTests: [PromptExample] = [
        PromptExample(
            category: "Tool Test",
            title: "GetGoals - Search",
            prompt: "Show me all goals that mention 'health' or 'fitness'",
            expectedTool: "getGoals"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetGoals - Type Filter",
            prompt: "List all my SmartGoals",
            expectedTool: "getGoals"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetGoals - Date Range",
            prompt: "What goals are active in July 2025?",
            expectedTool: "getGoals"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetActions - Recent",
            prompt: "Show me actions from the last 7 days",
            expectedTool: "getActions"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetActions - Search",
            prompt: "Find all actions related to running or exercise",
            expectedTool: "getActions"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetActions - With Measurements",
            prompt: "Show me actions that have measurements recorded",
            expectedTool: "getActions"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetTerms - Current",
            prompt: "What's my current ten-week term?",
            expectedTool: "getTerms"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetTerms - All",
            prompt: "List all my terms and their themes",
            expectedTool: "getTerms"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetValues - All",
            prompt: "Show me all my values",
            expectedTool: "getValues"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetValues - By Type",
            prompt: "What are my major values?",
            expectedTool: "getValues"
        ),
        PromptExample(
            category: "Tool Test",
            title: "GetValues - By Domain",
            prompt: "Show me values in the Health domain",
            expectedTool: "getValues"
        ),
        PromptExample(
            category: "Tool Test",
            title: "Multi-Tool Query",
            prompt: "Compare my health-related goals with my health-related values. Are they aligned?",
            expectedTool: "getGoals, getValues"
        )
    ]

    // MARK: - Benchmarking

    /// Subset of prompts suitable for benchmarking response times
    static let benchmarkExamples: [PromptExample] = [
        reflectiveQueries[0],    // July Reflection
        analyticalQueries[0],    // Goal Progress Analysis
        exploratoryQueries[0],   // Unlinked Actions
        specificQueries[0],      // Recent Actions
        toolTests[0],            // GetGoals - Search
        toolTests[3],            // GetActions - Recent
    ]

    // MARK: - Edge Cases

    /// Prompts that test error handling and edge cases
    static let edgeCases: [PromptExample] = [
        PromptExample(
            category: "Edge Case",
            title: "Empty Results",
            prompt: "Show me all goals from the year 1900",
            expectedTool: "getGoals"
        ),
        PromptExample(
            category: "Edge Case",
            title: "Complex Date Range",
            prompt: "What actions did I take between January 1st and January 2nd of 2025?",
            expectedTool: "getActions"
        ),
        PromptExample(
            category: "Edge Case",
            title: "Ambiguous Query",
            prompt: "Tell me about my stuff",
            expectedTool: nil
        ),
        PromptExample(
            category: "Edge Case",
            title: "No Tools Needed",
            prompt: "What's the weather like?",
            expectedTool: nil
        )
    ]

    // MARK: - Creative Queries

    /// Prompts that test creative and unconventional uses
    static let creativeQueries: [PromptExample] = [
        PromptExample(
            category: "Creative",
            title: "Story of Progress",
            prompt: "Tell me the story of my progress this month as if you were writing a short narrative.",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Creative",
            title: "Metaphor for Journey",
            prompt: "If my goal journey was a hiking trip, where would I be on the trail right now?",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Creative",
            title: "Weekly Report",
            prompt: "Create a weekly progress report for me, like a coach would write.",
            expectedTool: "getGoals, getActions"
        ),
        PromptExample(
            category: "Creative",
            title: "Celebration Moments",
            prompt: "What wins should I be celebrating? Help me see what I might be overlooking.",
            expectedTool: "getActions, getGoals"
        )
    ]

    // MARK: - Helper Methods

    /// Get all prompts from a specific category
    static func prompts(inCategory category: String) -> [PromptExample] {
        return allExamples.filter { $0.category == category }
    }

    /// Get all unique categories
    static var categories: [String] {
        let allCategories = allExamples.map { $0.category }
        return Array(Set(allCategories)).sorted()
    }

    /// Get a random prompt
    static var random: PromptExample {
        return allExamples.randomElement()!
    }

    /// Get a random prompt from a specific category
    static func random(fromCategory category: String) -> PromptExample? {
        let filtered = prompts(inCategory: category)
        return filtered.randomElement()
    }
}

// MARK: - Convenience Extensions

extension PromptExample: CustomStringConvertible {
    var description: String {
        """
        [\(category)] \(title)
        Prompt: \(prompt)
        Expected Tool: \(expectedTool ?? "Any")
        """
    }
}
