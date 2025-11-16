//
// CSVEngine.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Robust CSV parsing engine with no business logic.
// Handles encoding detection, line endings, quoted fields, column mismatches.
//
// DESIGN:
// - Pure parsing → clean data structures
// - No entity knowledge → just strings and arrays
// - Graceful handling of real-world CSV issues
//

import Foundation

// MARK: - CSV Engine

public struct CSVEngine {

    // MARK: - ParsedData (DataFrame-like)

    /// Clean parsed CSV data structure
    public struct ParsedData {
        public let headers: [String]
        public let rows: [[String]]  // Parallel arrays with headers

        /// Get all values for a column by name
        public func column(_ name: String) -> [String]? {
            guard let idx = headers.firstIndex(of: name) else { return nil }
            return rows.map { row in
                row.indices.contains(idx) ? row[idx] : ""
            }
        }

        /// Get dictionary representation of a row
        public func row(_ index: Int) -> [String: String] {
            guard rows.indices.contains(index) else { return [:] }
            let values = rows[index]

            // Gracefully handle column count mismatches
            var dict: [String: String] = [:]
            for (idx, header) in headers.enumerated() {
                dict[header] = values.indices.contains(idx) ? values[idx] : ""
            }
            return dict
        }

        /// Number of data rows
        public var count: Int { rows.count }

        /// Check if empty
        public var isEmpty: Bool { rows.isEmpty }
    }

    // MARK: - Parsing

    /// Parse CSV file with robust error handling
    /// - Parameter fileURL: Path to CSV file
    /// - Returns: Parsed data structure
    /// - Throws: CSVError if file cannot be read or parsed
    public static func parse(fileURL: URL) throws -> ParsedData {
        // 1. Read file with encoding fallback
        let content = try readWithEncodingFallback(fileURL)

        // 2. Handle all line ending types
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !lines.isEmpty else {
            throw CSVError.invalidFormat("CSV file is empty")
        }

        // 3. Check for IMPORT section marker (special template format)
        let importSectionIndex: Int?
        if let idx = lines.firstIndex(where: { $0.contains("IMPORT") }) {
            importSectionIndex = idx
        } else {
            importSectionIndex = nil
        }

        // 4. Determine where data starts
        let headerLineIndex: Int
        let dataStartIndex: Int

        if let importIdx = importSectionIndex {
            // Template format: IMPORT marker, then Fields row, then Optionality, then Sample, then data
            // Line 0: ",IMPORT,..."
            // Line 1: "Fields,title,description,..."
            // Line 2: "Optionality,REQUIRED,..."
            // Line 3: "Sample,Morning run,..."
            // Line 4+: Data rows
            guard importIdx + 1 < lines.count else {
                throw CSVError.invalidFormat("IMPORT section found but no Fields row")
            }
            headerLineIndex = importIdx + 1
            dataStartIndex = importIdx + 4  // Skip IMPORT, Fields, Optionality, Sample
        } else {
            // Standard CSV format: header is first line, data starts at line 1
            headerLineIndex = 0
            dataStartIndex = 1
        }

        // 5. Parse header - clean up field names
        let headerFields = parseCSVLine(lines[headerLineIndex])
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }  // Remove empty trailing fields from commas

        guard !headerFields.isEmpty else {
            throw CSVError.invalidFormat("Header row has no valid fields")
        }

        // 6. Parse data rows
        var dataRows: [[String]] = []
        guard dataStartIndex < lines.count else {
            // No data rows - return empty dataset with headers
            return ParsedData(headers: headerFields, rows: [])
        }

        for line in lines[dataStartIndex...] {
            let values = parseCSVLine(line)

            // Skip completely empty rows
            if values.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                continue
            }

            // Skip numbered placeholder rows (e.g., "1,,,,,,,")
            let firstValue = values.first?.trimmingCharacters(in: .whitespaces) ?? ""
            if Int(firstValue) != nil && values.dropFirst().allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                continue
            }

            // Store raw values - let ParsedData.row() handle column mismatches
            dataRows.append(values)
        }

        return ParsedData(headers: headerFields, rows: dataRows)
    }

    // MARK: - Encoding Detection

    /// Read file with automatic encoding fallback
    private static func readWithEncodingFallback(_ url: URL) throws -> String {
        // Try UTF-8 first (most common)
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }

        // Try Mac Roman (legacy Mac CSV exports)
        if let content = try? String(contentsOf: url, encoding: .macOSRoman) {
            return content
        }

        // Try ISO Latin-1 (Windows fallback)
        if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
            return content
        }

        // Last resort: ASCII
        return try String(contentsOf: url, encoding: .ascii)
    }

    // MARK: - CSV Line Parsing

    /// Parse a single CSV line respecting quoted fields
    /// Handles:
    /// - Quoted fields with commas: `"field with, comma",other`
    /// - Escaped quotes: `"field with ""quotes"""`
    /// - Mixed quoted/unquoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousChar: Character? = nil

        for char in line {
            if char == "\"" {
                if insideQuotes && previousChar == "\"" {
                    // Escaped quote ("") → append single quote
                    currentField.append(char)
                    previousChar = nil
                    continue
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                // Field delimiter (outside quotes)
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            previousChar = char
        }

        // Add last field
        fields.append(currentField)

        return fields
    }
}

// Note: CSVError is defined in CSVImportable.swift
