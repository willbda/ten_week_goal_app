//  ConversationHistory.swift
//  Represents a single AI assistant conversation exchange
//
//  Written by Claude Code on 2025-10-23
//
//  This model stores prompt-response pairs from interactions with the
//  on-device Foundation Models LLM, organized by session_id for grouping
//  conversations from the same app session.

import Foundation
import SQLiteData

/// A single prompt-response exchange with the AI assistant
///
/// Each conversation history entry captures:
/// - User's prompt (input)
/// - AI's response (output)
/// - Session grouping (session_id)
/// - Timestamp (created_at)
///
/// Sessions are incremented on each app launch, allowing conversations
/// to be grouped by time period and analyzed later.
///
/// Example:
/// ```swift
/// var history = ConversationHistory(
///     sessionId: 42,
///     prompt: "What made July meaningful?",
///     response: "In July, you completed 3 major goals..."
/// )
/// try await database.save(&history)
/// ```
@Table
public struct ConversationHistory: Codable, Sendable {

    // MARK: - Properties

    /// Unique identifier (UUID)
    public var id: UUID

    /// Session identifier (groups conversations from same app session)
    public var sessionId: Int

    /// User's input prompt
    public var prompt: String

    /// AI assistant's response
    public var response: String

    /// Timestamp of this interaction
    public var createdAt: Date

    /// Optional user notes about this conversation
    public var freeformNotes: String?

    // MARK: - Initialization

    /// Create a new conversation history entry
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided)
    ///   - sessionId: Session grouping identifier
    ///   - prompt: User's input text
    ///   - response: AI's output text
    ///   - createdAt: Timestamp (defaults to now)
    ///   - freeformNotes: Optional notes (not typically used)
    public init(
        id: UUID = UUID(),
        sessionId: Int,
        prompt: String,
        response: String,
        createdAt: Date = Date(),
        freeformNotes: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.prompt = prompt
        self.response = response
        self.createdAt = createdAt
        self.freeformNotes = freeformNotes
    }

    // MARK: - Validation

    /// Validates conversation history entry
    ///
    /// Requirements:
    /// - sessionId must be positive
    /// - prompt must not be empty
    /// - response must not be empty
    ///
    /// - Returns: true if valid, false otherwise
    public func isValid() -> Bool {
        return sessionId > 0 &&
               !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Identifiable

extension ConversationHistory: Identifiable {}

// MARK: - Equatable

extension ConversationHistory: Equatable {
    public static func == (lhs: ConversationHistory, rhs: ConversationHistory) -> Bool {
        return lhs.id == rhs.id &&
               lhs.sessionId == rhs.sessionId &&
               lhs.prompt == rhs.prompt &&
               lhs.response == rhs.response
        // Note: createdAt intentionally excluded from equality
    }
}
