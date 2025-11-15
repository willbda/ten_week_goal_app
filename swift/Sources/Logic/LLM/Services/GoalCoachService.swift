//
//  GoalCoachService.swift
//  ten-week-goal-app
//
//  Written by Claude Code on 2025-11-14
//
//  PURPOSE: Core service for LLM-based goal coaching using Apple's Foundation Models
//  PATTERN: Sendable service wrapping LanguageModel with conversation persistence
//
//  RESPONSIBILITIES:
//  - Create and manage LanguageModel sessions
//  - Persist conversations to database
//  - Provide goal coaching through natural language
//  - Integrate with app's data through tools
//

import Foundation
import FoundationModels
import SQLiteData
import Services

/// Service for AI-powered goal coaching using Foundation Models
/// Provides conversational interface for goal setting and reflection
@available(iOS 26.0, macOS 26.0, *)
public final class GoalCoachService: Sendable {
    // MARK: - Properties

    private let conversationRepository: ConversationRepository
    private let database: any DatabaseWriter

    // MARK: - Initialization

    public init(
        conversationRepository: ConversationRepository,
        database: any DatabaseWriter
    ) {
        self.conversationRepository = conversationRepository
        self.database = database
    }

    // MARK: - Session Management

    /// Start a new goal coaching conversation
    public func startConversation(
        type: ConversationType = .goalSetting,
        userId: String = "default"
    ) async throws -> ConversationSession {
        // Create conversation in database
        let header = try await conversationRepository.createConversation(
            userId: userId,
            conversationType: type
        )

        // Create language model session
        let session = try await createModelSession(
            conversationId: header.id,
            conversationType: type
        )

        return ConversationSession(
            header: header,
            session: session,
            repository: conversationRepository
        )
    }

    /// Resume an existing conversation
    public func resumeConversation(_ conversationId: UUID) async throws -> ConversationSession? {
        // Fetch conversation header
        guard let header = try await conversationRepository.fetchConversation(conversationId) else {
            return nil
        }

        // Fetch messages
        let messages = try await conversationRepository.fetchActiveMessages(conversationId)

        // Create language model session with history
        let session = try await createModelSession(
            conversationId: conversationId,
            conversationType: header.conversationType,
            existingMessages: messages
        )

        return ConversationSession(
            header: header,
            session: session,
            repository: conversationRepository
        )
    }

    // MARK: - Private Methods

    /// Create a new LanguageModel session with appropriate tools and instructions
    private func createModelSession(
        conversationId: UUID,
        conversationType: ConversationType,
        existingMessages: [ConversationMessage] = []
    ) async throws -> LanguageModelSession {
        // Get system language model
        let model = SystemLanguageModel.default

        // Check availability
        switch model.availability {
        case .available:
            break // Continue with model usage
        case .unavailable:
            throw LLMError.modelUnavailable
        }

        // Create instructions based on conversation type
        let instructions = createInstructions(for: conversationType)

        // Create transcript from existing messages
        _ = createTranscript(from: existingMessages, instructions: instructions)

        // Create tools based on conversation type
        _ = createTools(for: conversationType)

        // Create session with model only
        // Note: FoundationModels LanguageModelSession takes only the model
        // Instructions are passed as the first message in the transcript
        let session = LanguageModelSession(model: model)

        // TODO: Apply transcript and tools after initialization
        // The API for setting tools and loading transcript needs research
        // For now, return basic session - tools/transcript will be added in future iteration

        return session
    }

    /// Create system instructions for the conversation type
    private func createInstructions(for type: ConversationType) -> Instructions {
        switch type {
        case .goalSetting:
            return Instructions("""
                You are a thoughtful goal-setting coach helping the user create meaningful, achievable goals.

                Your approach:
                1. Ask clarifying questions to understand the user's motivation
                2. Connect goals to their personal values
                3. Help them define measurable targets
                4. Ensure goals are realistic yet challenging
                5. Create action plans with clear next steps

                Use the available tools to:
                - Fetch the user's existing goals and values
                - Check for duplicate goals before creating new ones
                - Create goals with proper structure and relationships

                Be encouraging but honest. If a goal seems unrealistic or poorly defined,
                gently guide the user toward a better formulation.
                """)

        case .reflection:
            return Instructions("""
                You are a reflective coach helping the user review their progress and learn from their experiences.

                Your approach:
                1. Ask about recent accomplishments and challenges
                2. Help identify patterns in their behavior
                3. Celebrate successes, no matter how small
                4. Reframe setbacks as learning opportunities
                5. Adjust goals based on new insights

                Use the available tools to:
                - Review recent actions and measurements
                - Analyze progress toward goals
                - Identify which values are being honored

                Be supportive and non-judgmental. Focus on growth and learning.
                """)

        case .valuesAlignment:
            return Instructions("""
                You are a values alignment coach helping the user ensure their goals and actions align with what matters most to them.

                Your approach:
                1. Explore what truly matters to the user
                2. Identify conflicts between stated values and current goals
                3. Help prioritize when values compete
                4. Connect daily actions to deeper purpose
                5. Refine value definitions for clarity

                Use the available tools to:
                - Review the user's personal values
                - Analyze goal-value alignments
                - Identify gaps or conflicts

                Be philosophical but practical. Help the user move from abstract values to concrete actions.
                """)

        case .general:
            return Instructions("""
                You are a supportive coach helping the user with their personal development journey.

                Be helpful, encouraging, and practical. Use the available tools to access
                the user's goals, actions, values, and progress data as needed.

                Focus on helping the user make progress toward their goals while maintaining
                balance and well-being.
                """)
        }
    }

    /// Create a transcript from existing messages
    /// Note: Currently simplified - FoundationModels Transcript API needs research
    private func createTranscript(
        from messages: [ConversationMessage],
        instructions: Instructions
    ) -> Transcript {
        // TODO: Implement proper transcript construction once we understand the API
        // For now, return empty transcript - messages will be added through respond() calls
        return Transcript()
    }

    /// Create tools for the conversation type
    private func createTools(for type: ConversationType) -> [any Tool] {
        // Common tools for all conversation types
        var tools: [any Tool] = [
            GetGoalsTool(database: database),
            GetValuesTool(database: database),
            GetMeasuresTool(database: database)
        ]

        // Add type-specific tools
        switch type {
        case .goalSetting:
            tools.append(CreateGoalTool(database: database))
            tools.append(CheckDuplicateGoalTool(database: database))

        case .reflection:
            tools.append(GetRecentActionsTool(database: database))
            tools.append(GetProgressTool(database: database))

        case .valuesAlignment:
            tools.append(AnalyzeAlignmentTool(database: database))

        case .general:
            // Include all tools for general conversations
            tools.append(CreateGoalTool(database: database))
            tools.append(GetRecentActionsTool(database: database))
        }

        return tools
    }
}

// MARK: - ConversationSession

/// Active conversation session with language model
@available(iOS 26.0, macOS 26.0, *)
public final class ConversationSession: Sendable {
    // MARK: - Properties

    public let header: ConversationHeader
    private let session: LanguageModelSession
    private let repository: ConversationRepository

    // MARK: - Initialization

    init(
        header: ConversationHeader,
        session: LanguageModelSession,
        repository: ConversationRepository
    ) {
        self.header = header
        self.session = session
        self.repository = repository
    }

    // MARK: - Conversation Methods

    /// Send a message and get a response
    public func sendMessage(_ message: String) async throws -> String {
        // Save user message
        _ = try await repository.addMessage(
            conversationId: header.id,
            role: .user,
            content: message,
            sessionNumber: header.sessionNumber
        )

        // Get response from language model
        // respond(to:generating:) returns Response<String> wrapper
        let response = try await session.respond(to: message, generating: String.self)
        // Extract the actual string value from the response
        let responseText = response.content

        // Save assistant response
        _ = try await repository.addMessage(
            conversationId: header.id,
            role: .assistant,
            content: responseText,
            sessionNumber: header.sessionNumber
        )

        return responseText
    }

    /// Stream a response for real-time updates
    /// Note: LanguageModelSession doesn't expose streaming API yet
    /// This is a placeholder that uses non-streaming respond()
    public func streamMessage(_ message: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Save user message
                    _ = try await repository.addMessage(
                        conversationId: header.id,
                        role: .user,
                        content: message,
                        sessionNumber: header.sessionNumber
                    )

                    // TODO: Replace with streaming API when available
                    // For now, use non-streaming respond() and yield complete response
                    let response = try await session.respond(to: message, generating: String.self)
                    let fullResponse = response.content

                    // Yield complete response (not truly streaming yet)
                    continuation.yield(fullResponse)

                    // Save complete assistant response
                    _ = try await repository.addMessage(
                        conversationId: header.id,
                        role: .assistant,
                        content: fullResponse,
                        sessionNumber: header.sessionNumber
                    )

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Check if context window is nearly full
    public func isContextWindowNearLimit() async -> Bool {
        // Foundation Models handle this internally, but we can check message count
        do {
            let messageCount = try await repository.countMessages(
                conversationId: header.id,
                archived: false
            )
            // Typical context window is ~15-20 messages for mobile
            return messageCount > 15
        } catch {
            return false
        }
    }

    /// Handle context window overflow by archiving old messages
    public func handleContextWindowOverflow() async throws {
        // Increment session number
        let newSession = try await repository.incrementSessionNumber(header.id)

        // Archive messages from previous sessions
        _ = try await repository.archiveMessagesBeforeSession(
            conversationId: header.id,
            sessionNumber: newSession
        )

        // Generate summary of archived messages
        if let summary = try await repository.generateConversationSummary(header.id) {
            // Add summary as system message for context
            _ = try await repository.addMessage(
                conversationId: header.id,
                role: .system,
                content: summary,
                sessionNumber: newSession
            )
        }
    }
}

// MARK: - Error Types

public enum LLMError: LocalizedError {
    case modelUnavailable
    case conversationNotFound
    case contextWindowExceeded
    case toolExecutionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "AI model is not available on this device"
        case .conversationNotFound:
            return "Conversation not found"
        case .contextWindowExceeded:
            return "Conversation is too long, please start a new session"
        case .toolExecutionFailed(let reason):
            return "Tool execution failed: \(reason)"
        }
    }
}