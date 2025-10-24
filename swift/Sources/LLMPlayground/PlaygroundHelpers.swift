//  PlaygroundHelpers.swift
//  Utility functions for LLM prompt engineering and experimentation
//
//  Written by Claude Code on 2025-10-24
//
//  This file provides helper functions for testing prompts, analyzing responses,
//  and experimenting with different prompt engineering techniques.

import Foundation

// MARK: - Prompt Engineering Templates

/// Templates for different prompt engineering techniques
struct PromptTemplates {

    // MARK: - Chain of Thought

    /// Add chain-of-thought reasoning to a prompt
    static func chainOfThought(_ basePrompt: String) -> String {
        """
        \(basePrompt)

        Please think through this step by step and explain your reasoning.
        """
    }

    // MARK: - Few-Shot Examples

    /// Add few-shot examples to a prompt
    static func fewShot(_ basePrompt: String, examples: [(input: String, output: String)]) -> String {
        var prompt = "Here are some examples:\n\n"

        for (index, example) in examples.enumerated() {
            prompt += "Example \(index + 1):\n"
            prompt += "Input: \(example.input)\n"
            prompt += "Output: \(example.output)\n\n"
        }

        prompt += "Now, please answer:\n\(basePrompt)"
        return prompt
    }

    // MARK: - Role Prompting

    /// Add a specific role to the prompt
    static func withRole(_ basePrompt: String, role: String) -> String {
        """
        You are \(role).

        \(basePrompt)
        """
    }

    // MARK: - Constrained Output

    /// Request output in a specific format
    static func constrainedOutput(_ basePrompt: String, format: OutputFormat) -> String {
        switch format {
        case .bullet_list:
            return """
            \(basePrompt)

            Please provide your answer as a bullet list.
            """
        case .numbered_list:
            return """
            \(basePrompt)

            Please provide your answer as a numbered list.
            """
        case .json:
            return """
            \(basePrompt)

            Please provide your answer in JSON format.
            """
        case .table:
            return """
            \(basePrompt)

            Please provide your answer as a formatted table.
            """
        case .paragraph:
            return """
            \(basePrompt)

            Please provide your answer as a single paragraph.
            """
        }
    }

    // MARK: - Clarification Prompts

    /// Ask for clarification on ambiguous input
    static func clarify(_ ambiguousInput: String) -> String {
        """
        I need to understand better what you're looking for. Could you clarify:

        \(ambiguousInput)

        Please be more specific about:
        - What time period are you interested in?
        - What specific aspect do you want to explore?
        - What kind of insights are you hoping to discover?
        """
    }

    // MARK: - Meta Prompts

    /// Prompt to analyze the quality of a previous response
    static func analyzeResponse(_ originalPrompt: String, response: String) -> String {
        """
        I asked: "\(originalPrompt)"

        And received this response:
        "\(response)"

        Please analyze:
        1. Did this fully answer the question?
        2. What additional insights could be provided?
        3. What follow-up questions would deepen understanding?
        """
    }
}

// MARK: - Output Format Enum

enum OutputFormat {
    case bullet_list
    case numbered_list
    case json
    case table
    case paragraph
}

// MARK: - Response Analysis

/// Tools for analyzing LLM responses
struct ResponseAnalyzer {

    // MARK: - Tool Usage Detection

    /// Detect which tools were likely used based on response content
    static func detectToolUsage(in response: String) -> [String] {
        var detectedTools: [String] = []

        // Check for goal-related keywords
        if response.contains("goal") || response.contains("Goal") ||
           response.contains("target") || response.contains("milestone") {
            detectedTools.append("getGoals")
        }

        // Check for action-related keywords
        if response.contains("action") || response.contains("Action") ||
           response.contains("accomplished") || response.contains("did") {
            detectedTools.append("getActions")
        }

        // Check for term-related keywords
        if response.contains("term") || response.contains("Term") ||
           response.contains("ten-week") || response.contains("theme") {
            detectedTools.append("getTerms")
        }

        // Check for value-related keywords
        if response.contains("value") || response.contains("Value") ||
           response.contains("priority") || response.contains("matters") {
            detectedTools.append("getValues")
        }

        return detectedTools
    }

    // MARK: - Response Quality Metrics

    /// Calculate basic quality metrics for a response
    static func analyzeQuality(of response: String) -> QualityMetrics {
        let wordCount = response.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count

        let sentenceCount = response.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count

        let avgWordsPerSentence = sentenceCount > 0 ? Double(wordCount) / Double(sentenceCount) : 0

        let hasNumbers = response.rangeOfCharacter(from: .decimalDigits) != nil
        let hasBulletPoints = response.contains("•") || response.contains("-")
        let hasQuestions = response.contains("?")

        return QualityMetrics(
            wordCount: wordCount,
            sentenceCount: sentenceCount,
            avgWordsPerSentence: avgWordsPerSentence,
            containsNumbers: hasNumbers,
            containsBulletPoints: hasBulletPoints,
            containsQuestions: hasQuestions
        )
    }

    // MARK: - Sentiment Analysis (Basic)

    /// Perform basic sentiment analysis on response
    static func analyzeSentiment(of response: String) -> Sentiment {
        let lowercased = response.lowercased()

        let positiveWords = ["great", "good", "excellent", "progress", "success",
                            "achieved", "accomplished", "wonderful", "amazing",
                            "fantastic", "well done", "congratulations"]

        let neutralWords = ["consider", "might", "could", "perhaps", "maybe",
                           "notice", "observe", "see", "find", "show"]

        let concernWords = ["need", "should", "must", "require", "missing",
                           "gap", "challenge", "difficult", "struggle", "behind"]

        let positiveCount = positiveWords.filter { lowercased.contains($0) }.count
        let neutralCount = neutralWords.filter { lowercased.contains($0) }.count
        let concernCount = concernWords.filter { lowercased.contains($0) }.count

        if positiveCount > concernCount && positiveCount > neutralCount {
            return .positive
        } else if concernCount > positiveCount && concernCount > neutralCount {
            return .constructive
        } else {
            return .neutral
        }
    }
}

// MARK: - Supporting Types

struct QualityMetrics {
    let wordCount: Int
    let sentenceCount: Int
    let avgWordsPerSentence: Double
    let containsNumbers: Bool
    let containsBulletPoints: Bool
    let containsQuestions: Bool

    var summary: String {
        """
        📊 Response Quality Metrics:
        - Words: \(wordCount)
        - Sentences: \(sentenceCount)
        - Avg words/sentence: \(String(format: "%.1f", avgWordsPerSentence))
        - Contains numbers: \(containsNumbers ? "✓" : "✗")
        - Contains bullet points: \(containsBulletPoints ? "✓" : "✗")
        - Contains questions: \(containsQuestions ? "✓" : "✗")
        """
    }
}

enum Sentiment: String {
    case positive = "Positive & Encouraging"
    case neutral = "Neutral & Informative"
    case constructive = "Constructive & Analytical"
}

// MARK: - Prompt Experimentation

/// Tools for experimenting with prompt variations
struct PromptExperimenter {

    // MARK: - Prompt Variations

    /// Generate variations of a base prompt
    static func variations(of basePrompt: String) -> [String] {
        return [
            // Original
            basePrompt,

            // Add specificity
            "Specifically, \(basePrompt.lowercased())",

            // Add time constraint
            "\(basePrompt) Focus on the last 30 days.",

            // Add analytical angle
            "\(basePrompt) What patterns or trends do you notice?",

            // Add reflective angle
            "\(basePrompt) Help me understand what this means for my journey.",

            // Add comparative angle
            "\(basePrompt) How does this compare to previous periods?"
        ]
    }

    // MARK: - A/B Testing Framework

    /// Compare two prompts for the same intent
    static func comparePrompts(
        promptA: String,
        promptB: String,
        intent: String
    ) -> PromptComparison {
        return PromptComparison(
            promptA: promptA,
            promptB: promptB,
            intent: intent,
            promptALength: promptA.count,
            promptBLength: promptB.count,
            promptAWords: promptA.components(separatedBy: .whitespacesAndNewlines).count,
            promptBWords: promptB.components(separatedBy: .whitespacesAndNewlines).count
        )
    }
}

struct PromptComparison {
    let promptA: String
    let promptB: String
    let intent: String
    let promptALength: Int
    let promptBLength: Int
    let promptAWords: Int
    let promptBWords: Int

    var summary: String {
        """
        🔬 Prompt Comparison
        Intent: \(intent)

        Prompt A:
        - Length: \(promptALength) chars
        - Words: \(promptAWords)
        - Text: \(promptA)

        Prompt B:
        - Length: \(promptBLength) chars
        - Words: \(promptBWords)
        - Text: \(promptB)
        """
    }
}

// MARK: - Performance Tracking

/// Track performance metrics for prompt testing
struct PerformanceTracker {
    private var measurements: [(prompt: String, duration: TimeInterval, timestamp: Date)] = []

    mutating func record(prompt: String, duration: TimeInterval) {
        measurements.append((prompt: prompt, duration: duration, timestamp: Date()))
    }

    func averageDuration() -> TimeInterval {
        guard !measurements.isEmpty else { return 0 }
        let total = measurements.reduce(0.0) { $0 + $1.duration }
        return total / Double(measurements.count)
    }

    func fastestPrompt() -> (prompt: String, duration: TimeInterval)? {
        return measurements.min(by: { $0.duration < $1.duration })
            .map { ($0.prompt, $0.duration) }
    }

    func slowestPrompt() -> (prompt: String, duration: TimeInterval)? {
        return measurements.max(by: { $0.duration < $1.duration })
            .map { ($0.prompt, $0.duration) }
    }

    func summary() -> String {
        guard !measurements.isEmpty else {
            return "No measurements recorded yet."
        }

        let avg = averageDuration()
        let fastest = fastestPrompt()
        let slowest = slowestPrompt()

        return """
        ⏱️  Performance Summary:
        - Total prompts tested: \(measurements.count)
        - Average response time: \(String(format: "%.2f", avg))s
        - Fastest: \(String(format: "%.2f", fastest?.duration ?? 0))s
        - Slowest: \(String(format: "%.2f", slowest?.duration ?? 0))s
        """
    }
}

// MARK: - Console Formatting

/// Helpers for pretty console output
struct ConsoleFormatter {

    static func box(_ content: String, width: Int = 60) -> String {
        let lines = content.components(separatedBy: .newlines)
        var result = "┌" + String(repeating: "─", count: width - 2) + "┐\n"

        for line in lines {
            let padding = max(0, width - 4 - line.count)
            result += "│ \(line)\(String(repeating: " ", count: padding)) │\n"
        }

        result += "└" + String(repeating: "─", count: width - 2) + "┘"
        return result
    }

    static func section(_ title: String) -> String {
        """

        \(String(repeating: "═", count: 60))
        \(title.uppercased())
        \(String(repeating: "═", count: 60))

        """
    }

    static func subsection(_ title: String) -> String {
        """

        \(String(repeating: "─", count: 60))
        \(title)
        \(String(repeating: "─", count: 60))

        """
    }

    static func progress(current: Int, total: Int, label: String = "") -> String {
        let percentage = Double(current) / Double(total) * 100
        let filled = Int(percentage / 5)  // 20 total bars
        let empty = 20 - filled

        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        return "[\(bar)] \(String(format: "%.0f", percentage))% \(label)"
    }
}
