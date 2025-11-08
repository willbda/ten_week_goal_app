//
// CSVExportImportView.swift
// Written by Claude Code on 2025-11-06
//
// PURPOSE:
// Simple UI for CSV export/import operations.
// Demonstrates ActionCSVService usage.
//

import SwiftUI
import SQLiteData
import Dependencies
import Services

struct CSVExportImportView: View {
    @Dependency(\.defaultDatabase) private var database
    @State private var exportResult: String = ""
    @State private var importResult: String = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var parseResult: ParseResult?
    @State private var showPreview = false

    var body: some View {
        // DESIGN: NavigationStack provides proper hierarchy with Liquid Glass navigation bar
        NavigationStack {
            // DESIGN: Form with .grouped style for iOS 18+ section styling and spacing
            Form {
                // DESIGN: Title-case section headers (not ALL CAPS) per iOS 18 guidelines
                Section("Export Options") {
                    // DESIGN: Using VStack in Form sections for proper layout
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export blank template with reference sheets")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // DESIGN: Standard bordered button
                        Button(action: exportTemplate) {
                            if isExporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Export Template", systemImage: "square.and.arrow.down")
                            }
                        }
                        .buttonStyle(.bordered) // DESIGN: Standard button style
                        .disabled(isExporting)
                        .accessibilityLabel("Export blank CSV template") // ACCESSIBILITY: VoiceOver support

                        Button(action: exportActions) {
                            if isExporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Export All Actions", systemImage: "square.and.arrow.down.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent) // DESIGN: Prominent button for primary action
                        .disabled(isExporting)
                        .accessibilityLabel("Export all actions to CSV") // ACCESSIBILITY: VoiceOver support

                        if !exportResult.isEmpty {
                            Text(exportResult)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }

                // DESIGN: Title-case section header
                Section("Import Options") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Import actions from CSV file")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button(action: { showFilePicker = true }) {
                            if isImporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Choose CSV File", systemImage: "doc.badge.arrow.up")
                            }
                        }
                        .buttonStyle(.bordered) // DESIGN: Standard button style
                        .disabled(isImporting)
                        .accessibilityLabel("Choose CSV file to import") // ACCESSIBILITY: VoiceOver support
                        .fileImporter(
                            isPresented: $showFilePicker,
                            allowedContentTypes: [.commaSeparatedText],
                            onCompletion: handleFileSelection
                        )

                        if !importResult.isEmpty {
                            // DESIGN: Semantic colors with proper styling
                            Label {
                                Text(importResult)
                                    .font(.caption)
                            } icon: {
                                Image(systemName: importResult.contains("✓") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(importResult.contains("✓") ? .green : .orange)
                            }
                            .labelStyle(.titleAndIcon)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .formStyle(.grouped) // DESIGN: Grouped form style with proper spacing
            .navigationTitle("CSV Import & Export") // DESIGN: Clear navigation hierarchy
        }
        .sheet(isPresented: $showPreview) {
            if let parseResult = parseResult {
                ImportPreviewView(
                    parseResult: parseResult,
                    onConfirm: confirmImport,
                    onCancel: {
                        showPreview = false
                        self.parseResult = nil
                    }
                )
            }
        }
    }

    // MARK: - Export Operations

    private func exportTemplate() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                // Get Downloads directory
                let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                let path = try await service.exportTemplate(to: downloadsDir)

                exportResult = """
                ✓ Exported template to Downloads:
                - \(path.lastPathComponent)
                (Includes Units and Goals reference sections)
                """
            } catch {
                exportResult = "⚠️ Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func exportActions() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                let path = try await service.exportActions(to: downloadsDir)

                exportResult = """
                ✓ Exported all actions to Downloads:
                - \(path.lastPathComponent)
                (Includes Units and Goals reference sections)
                """
            } catch {
                exportResult = "⚠️ Export failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Import Operations

    private func handleFileSelection(_ result: Result<URL, Error>) {
        Task {
            isImporting = true
            defer { isImporting = false }

            do {
                let fileURL = try result.get()

                // Grant access to security-scoped resource
                guard fileURL.startAccessingSecurityScopedResource() else {
                    importResult = "⚠️ Could not access file"
                    return
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }

                // Parse and show preview
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                let result = try await service.previewImport(from: fileURL)
                parseResult = result
                showPreview = true

            } catch {
                self.importResult = "⚠️ Parse failed: \(error.localizedDescription)"
            }
        }
    }

    private func confirmImport(_ selectedPreviews: [ActionPreview]) {
        Task {
            isImporting = true
            defer { isImporting = false }

            do {
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                let importResult = try await service.importSelected(selectedPreviews)

                self.importResult = importResult.summary

                if importResult.hasFailures {
                    self.importResult += "\n\nErrors:\n"
                    for (row, error) in importResult.failures.prefix(5) {
                        self.importResult += "Row \(row): \(error)\n"
                    }
                    if importResult.failures.count > 5 {
                        self.importResult += "... and \(importResult.failures.count - 5) more"
                    }
                }

                // Close preview
                showPreview = false
                parseResult = nil

            } catch {
                self.importResult = "⚠️ Import failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CSVExportImportView()
        .frame(width: 600, height: 500)
}
