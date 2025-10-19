// ValidationError.swift
// Simple, extensible validation errors for domain models
//
// Written by Claude Code on 2025-10-19
// Ported from Python implementation validation patterns

import Foundation

/// Validation errors for domain model constraints
///
/// Two core error types:
/// - invalidValue: For range/format violations (priority out of range, negative values)
/// - missingRequiredField: For nil fields that must be provided
///
/// Example usage:
/// ```
/// throw ValidationError.invalidValue(
///     field: "priority",
///     value: 150,
///     reason: "Priority must be between 1 and 100"
/// )
/// ```
public enum ValidationError: Error, LocalizedError, Sendable {

    // MARK: - Error Cases

    /// A field has an invalid value (out of range, wrong format, etc.)
    case invalidValue(
        field: String,
        value: String,  // Using String for Sendable conformance
        reason: String
    )

    /// A required field is missing or nil
    case missingRequiredField(
        field: String,
        context: String
    )

    // MARK: - LocalizedError Conformance

    /// User-friendly error description
    public var errorDescription: String? {
        switch self {
        case .invalidValue(let field, let value, let reason):
            return "Invalid \(field): \(value). \(reason)"
        case .missingRequiredField(let field, let context):
            return "Required field '\(field)' is missing (\(context))"
        }
    }

    /// Recovery suggestion (optional)
    public var recoverySuggestion: String? {
        switch self {
        case .invalidValue:
            return "Please provide a value that meets the validation criteria."
        case .missingRequiredField:
            return "Please provide a value for the required field."
        }
    }
}
