//  ConversationService.swift
//  Core orchestrator for AI assistant conversations
//
//  Written by Claude Code on 2025-10-23
//
//  This actor manages the Foundation Models LanguageModelSession,
//  registers data access tools, handles conversation flow, and
//  persists chat history to the database.

import Foundation
import GRDB
import Models
import Database

#if canImport(FoundationModels)
import FoundationModels

/// Core service that manages AI conversations
///
/// ConversationService is an actor (background thread safe) that:
/// - Initializes and manages the LanguageModelSession
/// - Registers all data access tools (Goals, Actions, Terms, Values)
/// - Handles conversation flow and error recovery
/// - Persists all interactions to the conversation_history database
///
/// Example:
/// ```swift
/// let service = try await ConversationService(database: db)
/// let response = try await service.send(prompt: "What made July meaningful?")
/// print(response)  // Model's thoughtful analysis
/// ```
@available(macOS 26.0, *)
public actor ConversationService {

    // MARK: - Properties

    /// Database manager for data access and history storage
    private let database: DatabaseManager

    /// The language model session for conversations
    private var session: LanguageModelSession?

    /// Current session ID (incremented on each app launch)
    private var sessionId: Int

    /// System instructions for the AI assistant
    private let systemInstructions = """
        You are a reflective guide helping someone understand their goals, actions,
        values, and personal growth journey. You have access to their complete data
        through tools. Be encouraging but analytical. Help them discover insights
        by asking thoughtful questions.

        When they ask about specific time periods or themes (like "what made July
        meaningful?"), explore their goals and actions from that period together,
        looking for patterns and significance.


        You can access:
        - Goals (with targets, dates, and types)
        - Actions (what they've accomplished)
        - Terms (ten-week periods with themes)
        - Values (what motivates them)
        """

    // MARK: - Initialization

    /// Initialize the conversation service
    ///
    /// - Parameter database: Database manager for data access
    /// - Throws: ConversationError if initialization fails
    public init(database: DatabaseManager) async throws {
        self.database = database

        // Ensure conversation_history table exists (migration for existing DBs)
        try await database.ensureConversationHistoryTable()

        // Get the next session ID
        self.sessionId = try await Self.getNextSessionId(database: database)

        // Initialize the language model session
        try await initializeSession()
    }

    // MARK: - Public Methods

    /// Send a prompt to the AI assistant
    ///
    /// This method:
    /// 1. Sends the prompt to the language model
    /// 2. Model may call tools to access data
    /// 3. Returns the model's response
    /// 4. Saves the interaction to history
    ///
    /// - Parameter prompt: User's input text
    /// - Returns: AI assistant's response
    /// - Throws: ConversationError for various failure cases
    public func send(prompt: String) async throws -> String {
        guard let session = session else {
            throw ConversationError.sessionNotInitialized
        }

        do {
            // Send prompt to model (may trigger tool calls)
            let response = try await session.respond(to: prompt)

            // Extract the string content from the response
            let responseText = response.content

            // Save to conversation history
            var history = ConversationHistory(
                sessionId: sessionId,
                prompt: prompt,
                response: responseText
            )

            // Save and get back the record (in case DB generated values)
            let _ = try await database.saveRecord(history)

            return responseText

        } catch {
            // Handle specific Foundation Models errors
            if let generationError = error as? LanguageModelSession.GenerationError {
                throw mapGenerationError(generationError)
            } else {
                throw ConversationError.systemError(underlying: error)
            }
        }
    }

    /// Get the current session ID
    public func getCurrentSessionId() -> Int {
        return sessionId
    }

    /// Get conversation history for the current session
    public func getCurrentSessionHistory() async throws -> [ConversationHistory] {
        let sql = """
            SELECT * FROM conversation_history
            WHERE session_id = ?
            ORDER BY created_at ASC
            """
        return try await database.fetch(
            ConversationHistory.self,
            sql: sql,
            arguments: [Int64(sessionId)]
        )
    }

    /// Clear the current session and start fresh
    public func clearSession() async throws {
        try await initializeSession()
    }

    // MARK: - Private Methods

    /// Initialize the language model session with tools
    private func initializeSession() async throws {
        // Create tools
        let goalsTool = GetGoalsTool(database: database)
        let actionsTool = GetActionsTool(database: database)
        let termsTool = GetTermsTool(database: database)
        let valuesTool = GetValuesTool(database: database)

        // Create session with tools and instructions
        self.session = LanguageModelSession(
            tools: [
                goalsTool,
                actionsTool,
                termsTool,
                valuesTool
            ],
            instructions: systemInstructions
        )
    }

    /// Get the next session ID by querying the database
    private static func getNextSessionId(database: DatabaseManager) async throws -> Int {
        let sql = "SELECT MAX(session_id) as max_id FROM conversation_history"

        do {
            let result = try await database.fetch(
                MaxSessionRow.self,
                sql: sql,
                arguments: []
            )

            if let maxId = result.first?.maxId {
                return maxId + 1
            } else {
                return 1  // First session
            }
        } catch {
            // Table might not exist yet, start with session 1
            return 1
        }
    }

    /// Map Foundation Models errors to our error types
    private func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> ConversationError {
        switch error {
        case .exceededContextWindowSize(let details):
            // Extract token counts if available
            if let info = details as? [String: Any],
               let tokensUsed = info["tokensUsed"] as? Int,
               let limit = info["limit"] as? Int {
                return .contextSizeExceeded(tokensUsed: tokensUsed, limit: limit)
            } else {
                return .contextSizeExceeded(tokensUsed: 0, limit: 0)
            }

        case .guardrailViolation:
            return .guardrailViolation(message: "Content guidelines prevented this response")

        case .unsupportedLanguageOrLocale(let locale):
            return .modelUnavailable(reason: "Unsupported language: \(locale)")

        case .refusal(_, _):
            // Refusals don't have async explanation in current API
            return .guardrailViolation(message: "The model refused to generate a response")

        case .assetsUnavailable(let details):
            return .systemError(underlying: NSError(domain: "LanguageModel", code: -1, userInfo: ["details": details]))
        case .unsupportedGuide(let details):
            return .systemError(underlying: NSError(domain: "LanguageModel", code: -1, userInfo: ["details": details]))
        case .decodingFailure(let details):
            return .systemError(underlying: NSError(domain: "LanguageModel", code: -1, userInfo: ["details": details]))
        case .rateLimited(let details):
            return .systemError(underlying: NSError(domain: "LanguageModel", code: -1, userInfo: ["details": details]))
        case .concurrentRequests(let details):
            return .systemError(underlying: NSError(domain: "LanguageModel", code: -1, userInfo: ["details": details]))
        @unknown default:
            return .systemError(underlying: error)
        }
    }

    // MARK: - Helper Types

    /// Helper struct for querying max session ID
    private struct MaxSessionRow: Decodable, FetchableRecord {
        let maxId: Int?

        enum CodingKeys: String, CodingKey {
            case maxId = "max_id"
        }
    }
}

// MARK: - Public Factory Method

@available(macOS 26.0, *)
extension ConversationService {

    /// Create a conversation service with the default database
    ///
    /// - Returns: Initialized conversation service
    /// - Throws: ConversationError if initialization fails
    public static func createDefault() async throws -> ConversationService {
        let database = try await DatabaseManager()
        return try await ConversationService(database: database)
    }
}

#endif // canImport(FoundationModels)

// MARK: - Interactive Foundation Models Testing

#if canImport(Playgrounds) && canImport(FoundationModels)
import Playgrounds

// MARK: - Playground Examples
//
// These inline playgrounds let you test Foundation Models interactively in Xcode 16+.
// Open this file in Xcode, show the canvas (Editor > Canvas), and click Resume.
//
// Note: Requires macOS 26.0+ with Foundation Models framework.

@available(macOS 26.0, *)
#Playground {
    // Test: Initialize ConversationService and send a prompt
    Task {
        do {
            let db = try await DatabaseManager(configuration: .default)
            let service = try await ConversationService(database: db)

            let response = try await service.send(prompt: "What are my current goals?")
            print("🤖 Response:")
            print(response)
        } catch {
            print("❌ Error: \(error)")
        }
    }
}

@available(macOS 26.0, *)
#Playground {
    // Test: Try a reflective question
    Task {
        do {
            let db = try await DatabaseManager(configuration: .default)
            let service = try await ConversationService(database: db)

            let response = try await service.send(
                prompt: "What patterns do you see in my recent actions?"
            )
            print("🤖 Analysis:")
            print(response)
        } catch {
            print("❌ Error: \(error)")
        }
    }
}

@available(macOS 26.0, *)
#Playground {
    // Test: Check conversation history
    Task {
        do {
            let db = try await DatabaseManager(configuration: .default)
            let service = try await ConversationService(database: db)

            // Send a test message
            _ = try await service.send(prompt: "Hello!")

            // Get history
            let history = try await service.getCurrentSessionHistory()
            print("📜 Conversation history (\(history.count) messages):")
            for entry in history {
                print("User: \(entry.prompt)")
                print("AI: \(entry.response)")
                print("---")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
}

#endif
