//  ConversationError.swift
//  Typed errors for AI conversation operations
//
//  Written by Claude Code on 2025-10-23
//
//  Defines specific error cases that can occur during AI conversations,
//  with user-friendly localized descriptions for each error type.

import Foundation

/// Errors that can occur during AI conversation operations
///
/// These errors cover model availability, session management,
/// and conversation-specific issues like context size and safety.
public enum ConversationError: Error, Sendable {

    // MARK: - Error Cases

    /// The conversation session has not been initialized
    case sessionNotInitialized

    /// The language model is not available
    case modelUnavailable(reason: String)

    /// The conversation exceeded the model's context window
    case contextSizeExceeded(tokensUsed: Int, limit: Int)

    /// The model refused to respond due to safety guardrails
    case guardrailViolation(message: String?)

    /// Database operation failed
    case databaseError(underlying: Error)

    /// The model returned an unexpected response format
    case invalidResponse(details: String)

    /// Network or system error during model interaction
    case systemError(underlying: Error)

    /// Tool execution failed
    case toolExecutionFailed(toolName: String, error: String)

    /// Session creation failed
    case sessionCreationFailed(reason: String)
}

// MARK: - LocalizedError

extension ConversationError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .sessionNotInitialized:
            return "Conversation session not initialized. Please restart the chat."

        case .modelUnavailable(let reason):
            return "AI assistant unavailable: \(reason)"

        case .contextSizeExceeded(let tokensUsed, let limit):
            return "Conversation too long (used \(tokensUsed) of \(limit) tokens). Please start a new conversation."

        case .guardrailViolation(let message):
            if let message = message {
                return "Unable to respond: \(message)"
            } else {
                return "Unable to respond due to content guidelines."
            }

        case .databaseError(let error):
            return "Failed to save conversation: \(error.localizedDescription)"

        case .invalidResponse(let details):
            return "Unexpected response format: \(details)"

        case .systemError(let error):
            return "System error: \(error.localizedDescription)"

        case .toolExecutionFailed(let toolName, let error):
            return "Failed to access \(toolName): \(error)"

        case .sessionCreationFailed(let reason):
            return "Failed to start conversation: \(reason)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .sessionNotInitialized:
            return "The conversation session was not properly initialized."

        case .modelUnavailable:
            return "The on-device language model is not available on this system."

        case .contextSizeExceeded:
            return "The conversation has exceeded the maximum context window size."

        case .guardrailViolation:
            return "The model's safety systems prevented this response."

        case .databaseError:
            return "A database operation failed while saving the conversation."

        case .invalidResponse:
            return "The model returned data in an unexpected format."

        case .systemError:
            return "An underlying system error occurred."

        case .toolExecutionFailed:
            return "A tool failed to execute properly."

        case .sessionCreationFailed:
            return "Could not create a new conversation session."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .sessionNotInitialized, .sessionCreationFailed:
            return "Try restarting the chat or relaunching the app."

        case .modelUnavailable:
            return "Ensure Apple Intelligence is enabled in System Settings and your device meets requirements (M1+ Mac, macOS 15.1+)."

        case .contextSizeExceeded:
            return "Start a new conversation to continue chatting."

        case .guardrailViolation:
            return "Try rephrasing your request or asking something different."

        case .databaseError:
            return "Check disk space and permissions. The conversation may not be saved."

        case .invalidResponse, .systemError:
            return "Try your request again. If the problem persists, restart the app."

        case .toolExecutionFailed:
            return "The data access tool encountered an error. Try a different query."
        }
    }
}

// MARK: - Equatable

extension ConversationError: Equatable {
    public static func == (lhs: ConversationError, rhs: ConversationError) -> Bool {
        switch (lhs, rhs) {
        case (.sessionNotInitialized, .sessionNotInitialized):
            return true
        case let (.modelUnavailable(r1), .modelUnavailable(r2)):
            return r1 == r2
        case let (.contextSizeExceeded(t1, l1), .contextSizeExceeded(t2, l2)):
            return t1 == t2 && l1 == l2
        case let (.guardrailViolation(m1), .guardrailViolation(m2)):
            return m1 == m2
        case let (.invalidResponse(d1), .invalidResponse(d2)):
            return d1 == d2
        case let (.toolExecutionFailed(n1, e1), .toolExecutionFailed(n2, e2)):
            return n1 == n2 && e1 == e2
        case let (.sessionCreationFailed(r1), .sessionCreationFailed(r2)):
            return r1 == r2
        case (.databaseError, .databaseError),
             (.systemError, .systemError):
            // Can't compare underlying errors directly
            return false
        default:
            return false
        }
    }
}