// ConversationViewModel.swift
// View model managing AI assistant conversation state
//
// Written by Claude Code on 2025-10-23
//
// This @MainActor @Observable class manages the conversation UI state,
// coordinates with the ConversationService actor for AI interactions,
// and handles error states gracefully.

import SwiftUI
import Foundation

import BusinessLogic
import Models

/// View model for the AI assistant chat interface
///
/// Manages conversation state, handles user input, coordinates with the
/// ConversationService for AI responses, and provides error handling.
///
/// **Swift 6.2 Concurrency Pattern**: Uses @MainActor for thread-safe UI state
/// management while ConversationService remains an actor for background work.
///
/// Example:
/// ```swift
/// @State private var viewModel = ConversationViewModel()
///
/// var body: some View {
///     AssistantChatView()
///         .task { await viewModel.initialize() }
/// }
/// ```
@MainActor
@Observable
public final class ConversationViewModel {

    // MARK: - Properties

    /// All messages in the current conversation
    public private(set) var messages: [ChatMessage] = []

    /// Current text being typed by the user
    public var currentPrompt: String = ""

    /// Whether the AI is currently processing a response
    public private(set) var isLoading: Bool = false

    /// Error message to display if something goes wrong
    public private(set) var errorMessage: String?

    /// Whether the service is initialized and ready
    public private(set) var isInitialized: Bool = false

    /// Model availability status message
    public private(set) var availabilityStatus: String = "Checking..."

    // MARK: - Private Properties

    /// The conversation service (only available on macOS 26.0+)
    private var conversationService: Any?

    /// Database manager for accessing data
    private var database: DatabaseManager?

    // MARK: - Initialization

    public init() {
        // Check initial availability
        updateAvailabilityStatus()
    }

    // MARK: - Public Methods

    /// Initialize the conversation service
    ///
    /// Sets up the ConversationService if the model is available.
    /// Should be called when the view appears.
    public func initialize() async {
        guard !isInitialized else { return }

        // Check if AI is available
        guard AIAssistantAvailability.shared.isAvailable else {
            availabilityStatus = AIAssistantAvailability.shared.statusMessage
            errorMessage = "AI Assistant is not available. \(availabilityStatus)"
            return
        }

        do {
            // Initialize database
            database = try await DatabaseManager()

            // Initialize conversation service with availability check
            if #available(macOS 26.0, *) {
                guard let db = database else { return }
                let service = try await ConversationService(database: db)
                conversationService = service

                // Load any existing history for this session
                await loadSessionHistory()

                isInitialized = true
                availabilityStatus = "Ready"
                errorMessage = nil

                // Add welcome message if no history
                if messages.isEmpty {
                    messages.append(ChatMessage(
                        text: "Hello! I'm here to help you reflect on your goals, actions, and personal growth journey. What would you like to explore today?",
                        isUser: false
                    ))
                }
            } else {
                errorMessage = "Requires macOS 26.0 or later"
                availabilityStatus = "OS version too old"
                isInitialized = false
            }
        } catch {
            errorMessage = "Failed to initialize: \(error.localizedDescription)"
            availabilityStatus = "Error"
            isInitialized = false
        }
    }

    /// Send a message to the AI assistant
    ///
    /// Sends the current prompt to the ConversationService and updates the UI
    /// with the response.
    @MainActor
    public func sendMessage() async {
        let prompt = currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        guard isInitialized else {
            errorMessage = "Service not initialized"
            return
        }

        // Add user message to UI
        messages.append(ChatMessage(text: prompt, isUser: true))

        // Clear the input field
        currentPrompt = ""
        errorMessage = nil

        // Add loading indicator
        let loadingMessage = ChatMessage(text: "", isUser: false, isLoading: true)
        messages.append(loadingMessage)
        isLoading = true

        do {
            if #available(macOS 26.0, *) {
                guard let service = conversationService as? ConversationService else {
                    throw ConversationError.sessionNotInitialized
                }

                // Get AI response
                let response = try await service.send(prompt: prompt)

                // Remove loading indicator
                messages.removeAll { $0.isLoading }

                // Add AI response
                messages.append(ChatMessage(text: response, isUser: false))
            } else {
                // Remove loading indicator
                messages.removeAll { $0.isLoading }

                messages.append(ChatMessage(
                    text: "This feature requires macOS 26.0 or later",
                    isUser: false
                ))
            }
        } catch {
            // Remove loading indicator
            messages.removeAll { $0.isLoading }

            // Handle specific error types
            if let convError = error as? ConversationError {
                handleConversationError(convError)
            } else {
                errorMessage = "Error: \(error.localizedDescription)"
                messages.append(ChatMessage(
                    text: "I encountered an error: \(error.localizedDescription)",
                    isUser: false
                ))
            }
        }

        isLoading = false
    }

    /// Clear the current conversation
    ///
    /// Resets the session and clears all messages.
    public func clearConversation() async {
        messages.removeAll()
        currentPrompt = ""
        errorMessage = nil

        if #available(macOS 26.0, *) {
            guard let service = conversationService as? ConversationService else { return }
            do {
                try await service.clearSession()
                messages.append(ChatMessage(
                    text: "Conversation cleared. How can I help you today?",
                    isUser: false
                ))
            } catch {
                errorMessage = "Failed to clear session: \(error.localizedDescription)"
            }
        } else {
            messages.append(ChatMessage(
                text: "Conversation cleared. How can I help you today?",
                isUser: false
            ))
        }
    }

    /// Check if the send button should be enabled
    public var canSendMessage: Bool {
        !currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading &&
        isInitialized
    }

    // MARK: - Private Methods

    /// Update availability status from the checker
    private func updateAvailabilityStatus() {
        availabilityStatus = AIAssistantAvailability.shared.statusMessage
    }

    /// Load existing conversation history for the current session
    private func loadSessionHistory() async {
        if #available(macOS 26.0, *) {
            guard let service = conversationService as? ConversationService else { return }

            do {
                let history = try await service.getCurrentSessionHistory()

                // Convert history to ChatMessages
                for entry in history {
                    // Add user message
                    messages.append(ChatMessage(
                        text: entry.prompt,
                        isUser: true,
                        timestamp: entry.createdAt
                    ))

                    // Add AI response
                    messages.append(ChatMessage(
                        text: entry.response,
                        isUser: false,
                        timestamp: entry.createdAt
                    ))
                }
            } catch {
                // Silently fail - not critical if we can't load history
                print("Failed to load conversation history: \(error)")
            }
        }
    }

    /// Handle specific conversation errors with appropriate UI feedback
    private func handleConversationError(_ error: ConversationError) {
        switch error {
        case .modelUnavailable(let reason):
            errorMessage = "Model unavailable: \(reason)"
            messages.append(ChatMessage(
                text: "The AI model is currently unavailable. Please try again later.",
                isUser: false
            ))

        case .contextSizeExceeded(let tokensUsed, let limit):
            errorMessage = "Context limit reached (\(tokensUsed)/\(limit) tokens)"
            messages.append(ChatMessage(
                text: "Our conversation has become too long. Please start a new conversation to continue.",
                isUser: false
            ))

        case .guardrailViolation(let message):
            let details = message ?? "Content guidelines prevented this response"
            errorMessage = "Content guidelines: \(details)"
            messages.append(ChatMessage(
                text: "I'm unable to respond to that request. \(details)",
                isUser: false
            ))

        case .sessionNotInitialized:
            errorMessage = "Session not initialized"
            Task { await initialize() }

        case .sessionCreationFailed(let reason):
            errorMessage = "Failed to create session: \(reason)"
            messages.append(ChatMessage(
                text: "I'm having trouble starting our conversation. Please try again.",
                isUser: false
            ))

        case .toolExecutionFailed(let toolName, let reason):
            errorMessage = "Tool error: \(toolName)"
            messages.append(ChatMessage(
                text: "I had trouble accessing your \(toolName) data. Error: \(reason)",
                isUser: false
            ))

        case .systemError(let underlying):
            errorMessage = "System error: \(underlying.localizedDescription)"
            messages.append(ChatMessage(
                text: "A system error occurred. Please try again.",
                isUser: false
            ))

        case .databaseError(let underlying):
            errorMessage = "Database error: \(underlying.localizedDescription)"
            messages.append(ChatMessage(
                text: "I'm having trouble accessing the database. Please try again.",
                isUser: false
            ))

        case .invalidResponse(let details):
            errorMessage = "Invalid response: \(details)"
            messages.append(ChatMessage(
                text: "I received an invalid response. \(details)",
                isUser: false
            ))
        }
    }
}
