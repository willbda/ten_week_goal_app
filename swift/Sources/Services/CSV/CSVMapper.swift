//
// CSVMapper.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Protocol for mapping CSV rows to coordinator FormData types.
// Separates parsing (CSVEngine) from business logic (mappers).
//
// DESIGN:
// - Each entity (Action, Goal, Value) has its own mapper
// - Mappers handle field extraction and transformation
// - Validation is separate from mapping
//

import Foundation
import Models

// MARK: - CSV Mapper Protocol

/// Maps CSV row data to coordinator FormData
public protocol CSVMapper {
    associatedtype FormData

    /// Transform CSV row into FormData for coordinator
    /// - Parameters:
    ///   - row: Dictionary of field name → value
    ///   - rowNumber: Line number in CSV (for error reporting)
    /// - Returns: FormData ready for coordinator
    /// - Throws: MapError if required fields missing or invalid
    func map(row: [String: String], rowNumber: Int) throws -> FormData
}

// MARK: - Mapping Errors

public enum MapError: Error, LocalizedError {
    case missingRequired(row: Int, field: String)
    case invalidValue(row: Int, field: String, value: String, reason: String)
    case lookupFailed(row: Int, entity: String, identifier: String)

    public var errorDescription: String? {
        switch self {
        case .missingRequired(let row, let field):
            return "Row \(row): Missing required field '\(field)'"
        case .invalidValue(let row, let field, let value, let reason):
            return "Row \(row): Invalid '\(field)' value '\(value)' - \(reason)"
        case .lookupFailed(let row, let entity, let identifier):
            return "Row \(row): Could not find \(entity) with identifier '\(identifier)'"
        }
    }
}

// Note: CSVImportResult is defined in CSVImportable.swift

// MARK: - Helper Extensions

extension String {
    /// Check if string is effectively empty (nil, empty, or whitespace only)
    var isEffectivelyEmpty: Bool {
        self.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Safe optional conversion - returns nil if empty
    var nonEmpty: String? {
        isEffectivelyEmpty ? nil : self
    }
}

extension Optional where Wrapped == String {
    /// Check if optional string is effectively empty
    var isEffectivelyEmpty: Bool {
        self?.isEffectivelyEmpty ?? true
    }
}
