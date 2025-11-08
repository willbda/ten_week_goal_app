//
// CSVImportable.swift
// Written by Claude Code on 2025-11-07
//
// PURPOSE:
// Protocol-based abstraction for CSV import/export operations.
// Allows unified UI (CSVExportImportView) to work with any entity type.
//
// USAGE:
// Implement this protocol for each importable entity type (Actions, Goals, Values, Measures).
// The generic ImportPreviewView and CSVExportImportView can then work with any conforming type.
//

import Foundation

// MARK: - CSV Preview Protocol

/// Preview model that can be displayed in ImportPreviewView
public protocol CSVPreviewable: Identifiable, Sendable {
    var id: UUID { get }
    var rowNumber: Int { get }
    var title: String { get }
    var validationStatus: ValidationStatus { get }
    var isValid: Bool { get }
    var summary: String { get }
}

// MARK: - CSV Service Protocol

/// Service that handles CSV import/export for a specific entity type
public protocol CSVImportService {
    associatedtype PreviewType: CSVPreviewable

    /// Entity type name for UI display (e.g., "Actions", "Goals")
    var entityName: String { get }
    var entityNamePlural: String { get }

    /// Export blank template to directory
    func exportTemplate(to directory: URL) async throws -> URL

    /// Export all existing entities to directory
    func exportAll(to directory: URL) async throws -> URL

    /// Parse CSV and generate preview (does not import)
    func previewImport(from csvPath: URL) async throws -> CSVParseResult<PreviewType>

    /// Import selected previews
    func importSelected(_ previews: [PreviewType]) async throws -> CSVImportResult
}

// MARK: - Shared Result Types

/// Result of CSV parsing with previews
public struct CSVParseResult<Preview: CSVPreviewable> {
    public let previews: [Preview]
    public let errors: [String]

    public var validCount: Int {
        previews.filter { $0.isValid }.count
    }

    public var warningCount: Int {
        previews.filter {
            if case .warning = $0.validationStatus { return true }
            return false
        }.count
    }

    public var errorCount: Int {
        errors.count + previews.filter {
            if case .error = $0.validationStatus { return true }
            return false
        }.count
    }

    public init(previews: [Preview], errors: [String] = []) {
        self.previews = previews
        self.errors = errors
    }
}

/// Result of CSV import operation
public struct CSVImportResult {
    public let successes: Int
    public let failures: [(row: Int, error: String)]

    public var hasFailures: Bool {
        !failures.isEmpty
    }

    public var summary: String {
        if failures.isEmpty {
            return "✓ Successfully imported \(successes) items"
        } else {
            return "⚠️ Imported \(successes) items, \(failures.count) failed"
        }
    }

    public init(successes: Int, failures: [(row: Int, error: String)]) {
        self.successes = successes
        self.failures = failures
    }
}
