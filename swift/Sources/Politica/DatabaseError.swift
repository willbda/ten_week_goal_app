//  DatabaseError.swift
//  Typed error handling for database operations
//
//  Written by Claude Code on 2025-10-18
//
//  Provides structured error types for database failures, making error handling
//  type-safe and descriptive throughout the application.

import Foundation

/// Errors that can occur during database operations
///
/// All database errors are Sendable for use across concurrency boundaries.
/// Use these typed errors for better error handling and debugging.
public enum DatabaseError: Error, Sendable, CustomStringConvertible {

    // MARK: - Connection Errors

    case connectionFailed(reason: String)

    case schemaInitializationFailed(schemaFile: String, error: Error)

    // MARK: - Query Errors
    
    case queryFailed(sql: String, error: Error)

    case writeFailed(operation: String, table: String, error: Error)

    // MARK: - Validation Errors

    case validationFailed(reason: String)

    case filtersRequired(operation: String)

    case recordNotFound(table: String, id: UUID)

    case multipleRecordsFound(table: String, count: Int)

    // MARK: - Archive Errors

    case archiveRequired(table: String, recordID: UUID)

    case archiveFailed(reason: String)

    // MARK: - Serialization Errors

    case serializationFailed(entityType: String, reason: String)

    case deserializationFailed(entityType: String, reason: String)

    case unknownType(typeIdentifier: String, validTypes: [String])

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .connectionFailed(let reason):
            return "Database connection failed: \(reason)"

        case .schemaInitializationFailed(let schemaFile, let error):
            return "Failed to initialize schema '\(schemaFile)': \(error.localizedDescription)"

        case .queryFailed(let sql, let error):
            return "Query failed: \(sql)\nError: \(error.localizedDescription)"

        case .writeFailed(let operation, let table, let error):
            return "\(operation) failed on table '\(table)': \(error.localizedDescription)"

        case .validationFailed(let reason):
            return "Validation failed: \(reason)"

        case .filtersRequired(let operation):
            return "\(operation) operation requires filters to prevent accidental bulk operations"

        case .recordNotFound(let table, let id):
            return "Record not found in '\(table)' with ID: \(id.uuidString)"

        case .multipleRecordsFound(let table, let count):
            return "Multiple records found in '\(table)': found \(count) records when expecting one"

        case .archiveRequired(let table, let recordID):
            return "Archive required for '\(table)' record ID: \(recordID.uuidString)"

        case .archiveFailed(let reason):
            return "Archive operation failed: \(reason)"

        case .serializationFailed(let entityType, let reason):
            return "Failed to serialize \(entityType): \(reason)"

        case .deserializationFailed(let entityType, let reason):
            return "Failed to deserialize \(entityType): \(reason)"

        case .unknownType(let typeIdentifier, let validTypes):
            return "Unknown type '\(typeIdentifier)'. Valid types: \(validTypes.joined(separator: ", "))"
        }
    }
}

// MARK: - LocalizedError Extension

extension DatabaseError: LocalizedError {
    /// User-facing error description
    public var errorDescription: String? {
        return description
    }

    /// Recovery suggestion (if applicable)
    public var recoverySuggestion: String? {
        switch self {
        case .connectionFailed:
            return "Check database file permissions and path configuration."

        case .schemaInitializationFailed:
            return "Verify schema files exist in shared/schemas/ directory."

        case .queryFailed, .writeFailed:
            return "Check SQL syntax and database schema compatibility."

        case .validationFailed:
            return "Ensure entity fields meet validation requirements."

        case .filtersRequired:
            return "Add filters to specify which records to affect."

        case .recordNotFound:
            return "Verify the record ID is correct and hasn't been deleted."

        case .multipleRecordsFound:
            return "Add more specific filters to identify a single record."

        case .archiveRequired, .archiveFailed:
            return "Check archive table exists and has proper schema."

        case .serializationFailed, .deserializationFailed:
            return "Verify entity matches database schema and all required fields are present."

        case .unknownType:
            return "Use one of the recognized type identifiers for polymorphic storage."
        }
    }
}
