//  main.swift
//  LLM Playground - Interactive prompt testing for Foundation Models
//
//  Written by Claude Code on 2025-10-24
//
//  This playground provides an interactive CLI for testing LLM prompts,
//  experimenting with tool calling, and exploring Foundation Models capabilities.

import Foundation
import Database
import BusinessLogic
import Models

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, *)
@main
struct LLMPlayground {

    static func main() async {
        print("\n🧪 LLM Playground - Foundation Models Testing Environment\n")
        print("═══════════════════════════════════════════════════════════\n")

        // Check Foundation Models availability
        guard #available(macOS 26.0, *) else {
            print("❌ This playground requires macOS 26.0 or later")
            print("   Foundation Models is not available on this system.\n")
            return
        }

        do {
            // Initialize conversation service
            print("🔧 Initializing ConversationService...")
            let service = try await ConversationService.createDefault()
            let sessionId = service.getCurrentSessionId()
            print("✅ Session \(sessionId) ready\n")

            // Run interactive loop
            await runInteractiveLoop(service: service)

        } catch {
            print("\n❌ Failed to initialize: \(error.localizedDescription)")
            print("   Please ensure the database is set up correctly.\n")
        }
    }

    // MARK: - Interactive Loop

    static func runInteractiveLoop(service: ConversationService) async {
        var isRunning = true

        while isRunning {
            printMenu()

            guard let choice = readLine()?.trimmingCharacters(in: .whitespaces) else {
                continue
            }

            switch choice {
            case "1":
                await sendCustomPrompt(service: service)
            case "2":
                await useExamplePrompt(service: service)
            case "3":
                await viewHistory(service: service)
            case "4":
                await testToolCalling(service: service)
            case "5":
                await clearSession(service: service)
            case "6":
                await benchmarkPrompts(service: service)
            case "h", "help":
                printDetailedHelp()
            case "q", "quit", "exit":
                print("\n👋 Goodbye!\n")
                isRunning = false
            default:
                print("\n⚠️  Invalid choice. Type 'h' for help.\n")
            }
        }
    }

    // MARK: - Menu & Help

    static func printMenu() {
        print("┌─────────────────────────────────────────┐")
        print("│         LLM Playground Menu             │")
        print("├─────────────────────────────────────────┤")
        print("│ 1. Send custom prompt                   │")
        print("│ 2. Use example prompt                   │")
        print("│ 3. View conversation history            │")
        print("│ 4. Test tool calling                    │")
        print("│ 5. Clear session                        │")
        print("│ 6. Benchmark example prompts            │")
        print("│ h. Show detailed help                   │")
        print("│ q. Quit                                 │")
        print("└─────────────────────────────────────────┘")
        print("\nYour choice: ", terminator: "")
    }

    static func printDetailedHelp() {
        print("\n" + String(repeating: "=", count: 60))
        print("LLM PLAYGROUND - DETAILED HELP")
        print(String(repeating: "=", count: 60))
        print("""

        📚 WHAT IS THIS?

        The LLM Playground is an interactive testing environment for
        experimenting with Foundation Models prompts and tool calling.

        🎯 FEATURES

        1. CUSTOM PROMPTS
           - Type any prompt to test model responses
           - Experiment with different phrasings
           - See how the model uses tools

        2. EXAMPLE PROMPTS
           - Pre-built prompts demonstrating various capabilities
           - Tool calling examples
           - Analytical and reflective queries

        3. CONVERSATION HISTORY
           - View all prompts and responses from current session
           - Analyze tool usage patterns
           - Track conversation flow

        4. TOOL CALLING TESTS
           - Test individual tools (GetGoals, GetActions, etc.)
           - Verify tool arguments
           - Inspect formatted results

        5. SESSION MANAGEMENT
           - Clear current session to start fresh
           - Each app launch gets a new session ID
           - History persists in database

        6. BENCHMARKING
           - Run multiple prompts sequentially
           - Measure response times
           - Compare different approaches

        💡 TIPS

        - Start with example prompts to see what's possible
        - Test tool calling to understand how the model queries data
        - Use clear, specific prompts for best results
        - Check history to see how the model uses tools

        🔧 TECHNICAL DETAILS

        - Uses Foundation Models LanguageModelSession
        - Tools: GetGoals, GetActions, GetTerms, GetValues
        - Database: GRDB with conversation_history table
        - Errors: Comprehensive error handling with recovery suggestions

        """)
        print(String(repeating: "=", count: 60) + "\n")
    }

    // MARK: - Command Implementations

    static func sendCustomPrompt(service: ConversationService) async {
        print("\n📝 Enter your prompt (or 'cancel' to go back):")
        print("   ", terminator: "")

        guard let prompt = readLine()?.trimmingCharacters(in: .whitespaces),
              !prompt.isEmpty,
              prompt.lowercased() != "cancel" else {
            print("Cancelled.\n")
            return
        }

        await sendPrompt(prompt, to: service)
    }

    static func useExamplePrompt(service: ConversationService) async {
        let examples = PromptLibrary.allExamples

        print("\n📚 Example Prompts:\n")
        for (index, example) in examples.enumerated() {
            print("  \(index + 1). \(example.category): \(example.title)")
        }
        print("\n  0. Cancel\n")
        print("Select a prompt (1-\(examples.count)): ", terminator: "")

        guard let input = readLine(),
              let choice = Int(input),
              choice >= 1 && choice <= examples.count else {
            print("Cancelled.\n")
            return
        }

        let example = examples[choice - 1]
        print("\n📋 Category: \(example.category)")
        print("📋 Title: \(example.title)")
        print("📋 Prompt: \(example.prompt)")
        print("\nSending prompt...\n")

        await sendPrompt(example.prompt, to: service)
    }

    static func viewHistory(service: ConversationService) async {
        print("\n📜 Conversation History\n")

        do {
            let history = try await service.getCurrentSessionHistory()

            if history.isEmpty {
                print("   (No messages in this session yet)\n")
                return
            }

            for (index, entry) in history.enumerated() {
                let timestamp = formatTimestamp(entry.createdAt)

                print(String(repeating: "─", count: 60))
                print("Message \(index + 1) - \(timestamp)")
                print(String(repeating: "─", count: 60))
                print("\n👤 User:")
                print("   \(entry.prompt)")
                print("\n🤖 Assistant:")
                print("   \(entry.response)")
                print()
            }

            print(String(repeating: "═", count: 60) + "\n")

        } catch {
            print("❌ Failed to load history: \(error.localizedDescription)\n")
        }
    }

    static func testToolCalling(service: ConversationService) async {
        print("\n🔧 Tool Calling Tests\n")
        print("These prompts specifically test each tool:\n")

        let toolTests = PromptLibrary.toolTests

        for (index, test) in toolTests.enumerated() {
            print("  \(index + 1). \(test.title)")
        }
        print("\n  0. Cancel\n")
        print("Select a tool test (1-\(toolTests.count)): ", terminator: "")

        guard let input = readLine(),
              let choice = Int(input),
              choice >= 1 && choice <= toolTests.count else {
            print("Cancelled.\n")
            return
        }

        let test = toolTests[choice - 1]
        print("\n🧪 Testing: \(test.title)")
        print("📋 Expected tool: \(test.expectedTool ?? "Any")")
        print("📋 Prompt: \(test.prompt)")
        print("\nSending prompt...\n")

        await sendPrompt(test.prompt, to: service)
    }

    static func clearSession(service: ConversationService) async {
        print("\n🗑️  Clear current session? (y/n): ", terminator: "")

        guard let response = readLine()?.lowercased(),
              response == "y" || response == "yes" else {
            print("Cancelled.\n")
            return
        }

        do {
            try await service.clearSession()
            print("✅ Session cleared. Starting fresh!\n")
        } catch {
            print("❌ Failed to clear session: \(error.localizedDescription)\n")
        }
    }

    static func benchmarkPrompts(service: ConversationService) async {
        print("\n⏱️  Benchmarking Example Prompts\n")
        print("This will run all example prompts and measure response times.\n")
        print("Continue? (y/n): ", terminator: "")

        guard let response = readLine()?.lowercased(),
              response == "y" || response == "yes" else {
            print("Cancelled.\n")
            return
        }

        let examples = PromptLibrary.benchmarkExamples
        var results: [(title: String, duration: TimeInterval)] = []

        print("\n" + String(repeating: "=", count: 60))
        print("Starting benchmark...")
        print(String(repeating: "=", count: 60) + "\n")

        for (index, example) in examples.enumerated() {
            print("[\(index + 1)/\(examples.count)] \(example.title)...")

            let startTime = Date()
            await sendPrompt(example.prompt, to: service, showResponse: false)
            let duration = Date().timeIntervalSince(startTime)

            results.append((title: example.title, duration: duration))
            print("   ⏱️  \(String(format: "%.2f", duration))s\n")
        }

        // Print summary
        print(String(repeating: "=", count: 60))
        print("BENCHMARK RESULTS")
        print(String(repeating: "=", count: 60) + "\n")

        for (index, result) in results.enumerated() {
            print("\(index + 1). \(result.title)")
            print("   \(String(format: "%.2f", result.duration))s")
        }

        let totalTime = results.reduce(0.0) { $0 + $1.duration }
        let avgTime = totalTime / Double(results.count)

        print("\n" + String(repeating: "─", count: 60))
        print("Total time: \(String(format: "%.2f", totalTime))s")
        print("Average:    \(String(format: "%.2f", avgTime))s")
        print(String(repeating: "═", count: 60) + "\n")
    }

    // MARK: - Helper Methods

    static func sendPrompt(_ prompt: String, to service: ConversationService, showResponse: Bool = true) async {
        do {
            let startTime = Date()
            let response = try await service.send(prompt: prompt)
            let duration = Date().timeIntervalSince(startTime)

            if showResponse {
                print("🤖 Response (\(String(format: "%.2f", duration))s):")
                print(String(repeating: "─", count: 60))
                print(response)
                print(String(repeating: "─", count: 60) + "\n")
            }

        } catch let error as ConversationError {
            print("\n❌ Conversation Error: \(error.errorDescription ?? "Unknown error")")
            if let reason = error.failureReason {
                print("   Reason: \(reason)")
            }
            if let suggestion = error.recoverySuggestion {
                print("   💡 Suggestion: \(suggestion)")
            }
            print()

        } catch {
            print("\n❌ Unexpected error: \(error.localizedDescription)\n")
        }
    }

    static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#else
// Fallback for systems without Foundation Models
@main
struct LLMPlayground {
    static func main() {
        print("\n❌ LLM Playground requires Foundation Models")
        print("   This feature is only available on macOS 26.0 or later.\n")
    }
}
#endif
