// ChatMessage.swift
// Model representing a single message in the AI chat interface
//
// Written by Claude Code on 2025-10-23
//
// This lightweight model is separate from ConversationHistory (database model)
// and is optimized for SwiftUI display with Identifiable conformance.

import Foundation

/// A single message in the chat interface
///
/// Used for displaying conversation messages in the UI. This is distinct from
/// ConversationHistory which persists to the database. ChatMessage is optimized
/// for SwiftUI List/ForEach with Identifiable conformance.
///
/// Example:
/// ```swift
/// let userMessage = ChatMessage(text: "What made July meaningful?", isUser: true)
/// let aiMessage = ChatMessage(text: "Looking at your goals...", isUser: false)
/// let loadingMessage = ChatMessage(text: "", isUser: false, isLoading: true)
/// ```
public struct ChatMessage: Identifiable, Equatable, Sendable {

    // MARK: - Properties

    /// Unique identifier for SwiftUI
    public let id = UUID()

    /// The message text content
    public let text: String

    /// Whether this message is from the user (true) or AI (false)
    public let isUser: Bool

    /// Timestamp when the message was created
    public let timestamp: Date

    /// Whether this is a loading indicator message
    public let isLoading: Bool

    // MARK: - Initialization

    /// Create a new chat message
    ///
    /// - Parameters:
    ///   - text: Message content (can be empty for loading states)
    ///   - isUser: true for user messages, false for AI messages
    ///   - timestamp: When the message was created (defaults to now)
    ///   - isLoading: true to show a typing indicator instead of text
    public init(
        text: String,
        isUser: Bool,
        timestamp: Date = Date(),
        isLoading: Bool = false
    ) {
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.isLoading = isLoading
    }

    // MARK: - Computed Properties

    /// Formatted timestamp for display
    public var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: timestamp)
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Yesterday \(formatter.string(from: timestamp))"
        } else {
            formatter.timeStyle = .short
            formatter.dateStyle = .medium
            return formatter.string(from: timestamp)
        }
    }

    /// Short time string for inline display
    public var shortTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

// MARK: - Array Extensions

extension Array where Element == ChatMessage {

    /// Groups messages by date for sectioned display
    public func groupedByDate() -> [(date: Date, messages: [ChatMessage])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { message in
            calendar.startOfDay(for: message.timestamp)
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, messages: $0.value) }
    }
}